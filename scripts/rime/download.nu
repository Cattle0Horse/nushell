# HTTP下载和API操作模块

use const.nu *

# 初始化缓存目录
def init-cache-dir [] {
  if not ($RIME_CACHE_DIR | path exists) {
    mkdir $RIME_CACHE_DIR
    print $"(ansi cyan)创建缓存目录: ($RIME_CACHE_DIR)(ansi reset)"
  }
}

# 获取缓存元数据
def get-cache-metadata [] {
  let metadata_file = ($RIME_CACHE_DIR | path join $CACHE_METADATA_FILE)
  if ($metadata_file | path exists) {
    try {
      return (open $metadata_file)
    } catch {
      return {}
    }
  } else {
    return {}
  }
}

# 保存缓存元数据
def save-cache-metadata [metadata: record] {
  let metadata_file = ($RIME_CACHE_DIR | path join $CACHE_METADATA_FILE)
  $metadata | to json | save --force $metadata_file
}

# 检查缓存中是否存在文件，支持更新时间检查
export def check-cache [
  asset_info: record
  --check-update(-u)  # 是否检查更新时间
] {
  init-cache-dir
  let cache_filename = (get-cache-filename $asset_info)
  let cache_path = ($RIME_CACHE_DIR | path join $cache_filename)

  if ($cache_path | path exists) {
    # 验证文件大小
    if ($asset_info.size? | is-not-empty) {
      let expected_size = $asset_info.size
      let file_info = (ls $cache_path | first)
      let actual_size = ($file_info | get size | into int)
      if $expected_size != $actual_size {
        print $"(ansi yellow)缓存文件大小不匹配，将重新下载(ansi reset)"
        print $"期望: ($expected_size) 字节，实际: ($actual_size) 字节"
        rm $cache_path
        return null
      }
    }

    # 如果需要检查更新时间
    if $check_update {
      let metadata = (get-cache-metadata)
      if ($cache_filename in $metadata) {
        let cached_metadata = ($metadata | get $cache_filename)
        let cached_time = ($cached_metadata.updated_at | into datetime)
        let remote_time = ($asset_info.updated_at | into datetime)

        if $remote_time > $cached_time {
          print $"(ansi yellow)发现新版本，缓存已过期，将重新下载(ansi reset)"
          print $"缓存时间: ($cached_time)"
          print $"远程时间: ($remote_time)"
          rm $cache_path
          return null
        }
      } else {
        print $"(ansi yellow)缓存元数据缺失，将重新下载(ansi reset)"
        rm $cache_path
        return null
      }
    }

    print $"(ansi green)✓ 找到有效缓存文件: ($cache_filename)(ansi reset)"
    return $cache_path
  }

  return null
}

# 下载到缓存目录，支持更新检查
export def download-to-cache [
  asset_info: record
  --force(-f)  # 强制重新下载，忽略缓存
] {
  init-cache-dir
  let cache_filename = (get-cache-filename $asset_info)
  let cache_path = ($RIME_CACHE_DIR | path join $cache_filename)

  # 如果不是强制模式，检查缓存是否存在且需要更新
  if not $force {
    let existing_cache = (check-cache $asset_info --check-update)
    if ($existing_cache | is-not-empty) {
      return $existing_cache
    }
  } else {
    print $"(ansi yellow)强制重新下载模式(ansi reset)"
    # 强制模式下，删除现有缓存文件
    if ($cache_path | path exists) {
      rm $cache_path
      print $"(ansi yellow)已删除现有缓存文件(ansi reset)"
    }
  }

  # 下载到缓存
  if (download-asset $asset_info $cache_path) {
    # 更新缓存元数据
    let metadata = (get-cache-metadata)
    let file_metadata = {
      name: $asset_info.name,
      size: $asset_info.size,
      updated_at: $asset_info.updated_at,
      download_time: (date now | format date "%Y-%m-%d %H:%M:%S"),
      cache_filename: $cache_filename
    }
    let updated_metadata = ($metadata | insert $cache_filename $file_metadata)
    save-cache-metadata $updated_metadata

    print $"(ansi green)✓ 文件已缓存: ($cache_filename)(ansi reset)"
    return $cache_path
  } else {
    return null
  }
}

# 列出缓存文件
export def list-cache [] {
  init-cache-dir
  let metadata = (get-cache-metadata)

  if ($metadata | is-empty) {
    print $"(ansi yellow)缓存目录为空(ansi reset)"
    return
  }

  print $"(ansi cyan)=== Rime 缓存文件列表 ===(ansi reset)"
  print $"缓存目录: ($RIME_CACHE_DIR)"
  print ""

  for file_key in ($metadata | columns) {
    let file_info = ($metadata | get $file_key)
    let cache_path = ($RIME_CACHE_DIR | path join $file_key)
    let file_exists = ($cache_path | path exists)
    let size_info = if $file_exists {
      let file_info = (ls $cache_path | first)
      let actual_size = ($file_info | get size | into int)
      $"($actual_size) 字节"
    } else {
      "(文件不存在)"
    }

    print $"文件名: ($file_info.name)"
    print $"缓存文件: ($file_key)"
    print $"文件大小: ($size_info)"
    print $"更新时间: ($file_info.updated_at)"
    print $"下载时间: ($file_info.download_time)"
    print $"状态: (if $file_exists { '✓ 存在' } else { '✗ 缺失' })"
    print ""
  }
}

# 清除缓存
export def clear-cache [
  --all(-a)           # 清除所有缓存
  --pattern(-p): string  # 按模式清除缓存
] {
  init-cache-dir

  if $all {
    print $"(ansi yellow)正在清除所有缓存文件...(ansi reset)"
    try {
      rm -rf $RIME_CACHE_DIR
      mkdir $RIME_CACHE_DIR
      print $"(ansi green)✓ 所有缓存已清除(ansi reset)"
    } catch {
      print $"(ansi red)错误：清除缓存失败(ansi reset)"
    }
    return
  }

  let metadata = (get-cache-metadata)
  if ($metadata | is-empty) {
    print $"(ansi yellow)缓存目录为空，无需清除(ansi reset)"
    return
  }

  let files_to_remove = if ($pattern | is-not-empty) {
    $metadata | columns | where {|key| $key | str contains $pattern}
  } else {
    # 如果没有指定模式，列出文件让用户选择
    print $"(ansi cyan)请选择要清除的缓存文件：(ansi reset)"
    list-cache
    print $"(ansi yellow)使用 --all 清除所有缓存，或使用 --pattern 指定模式(ansi reset)"
    return
  }

  if ($files_to_remove | is-empty) {
    print $"(ansi yellow)未找到匹配的缓存文件(ansi reset)"
    return
  }

  print $"(ansi yellow)正在清除匹配的缓存文件...(ansi reset)"
  mut updated_metadata = $metadata

  for file_key in $files_to_remove {
    let cache_path = ($RIME_CACHE_DIR | path join $file_key)
    if ($cache_path | path exists) {
      try {
        rm $cache_path
        print $"(ansi green)✓ 已删除: ($file_key)(ansi reset)"
      } catch {
        print $"(ansi red)✗ 删除失败: ($file_key)(ansi reset)"
      }
    }
    $updated_metadata = ($updated_metadata | reject $file_key)
  }

  # 更新元数据
  save-cache-metadata $updated_metadata
  print $"(ansi green)✓ 缓存清除完成(ansi reset)"
}

# 获取缓存统计信息
export def cache-stats [] {
  init-cache-dir
  let metadata = (get-cache-metadata)

  if ($metadata | is-empty) {
    print $"(ansi cyan)=== Rime 缓存统计 ===(ansi reset)"
    print "缓存文件数量: 0"
    print "总大小: 0 字节"
    return
  }

  let file_count = ($metadata | columns | length)
  let total_size = ($metadata | columns | reduce -f 0 {|key, acc|
    let cache_path = ($RIME_CACHE_DIR | path join $key)
    if ($cache_path | path exists) {
      let file_info = (ls $cache_path | first)
      $acc + ($file_info | get size | into int)
    } else {
      $acc
    }
  })

  print $"(ansi cyan)=== Rime 缓存统计 ===(ansi reset)"
  print $"缓存目录: ($RIME_CACHE_DIR)"
  print $"缓存文件数量: ($file_count)"
  print $"总大小: ($total_size) 字节"
}

# 获取GitHub发布信息
export def get-release-info [owner: string, repo: string] {
  let api_url = $"https://api.github.com/repos/($owner)/($repo)/releases"

  try {
    print $"(ansi cyan)正在从GitHub获取发布信息: ($api_url)(ansi reset)"

    let headers = $GITHUB_API_HEADERS
    # 如果设置了GitHub Token，添加到请求头
    let headers = if ($env.GITHUB_TOKEN? | is-not-empty) {
      $headers | insert "Authorization" $"token ($env.GITHUB_TOKEN)"
    } else {
      $headers
    }

    let response = (http get $api_url --headers $headers)

    if ($response | is-empty) {
      print $"(ansi red)错误：GitHub API返回空响应(ansi reset)"
      return null
    }

    print $"(ansi green)成功获取GitHub发布信息(ansi reset)"
    return $response
  } catch {
    print $"(ansi red)错误：获取GitHub发布信息失败: ($api_url)(ansi reset)"
    return null
  }
}

# 从发布信息中选择模型发布
export def select-gram-release [releases: list, release_tag: string] {
  for release in $releases {
    let tag_name = $release.tag_name

    if ($tag_name | str contains $release_tag) {
      return $release
    }
  }
  return null
}

# 从发布中获取期望的资源信息
export def get-expected-asset-info [release: record, key_table: record, index: string] {
  if ($release.assets? | is-empty) {
    print $"(ansi red)错误：发布中没有资源文件(ansi reset)"
    return null
  }

  let expected_pattern = ($key_table | get $index)

  for asset in $release.assets {
    if ($asset.name | str contains $expected_pattern) {
      return $asset
    }
  }

  print $"(ansi red)错误：未找到匹配的资源文件，期望模式: ($expected_pattern)(ansi reset)"
  return null
}

# 验证文件SHA256
def verify-file-sha256 [file_path: string, expected_sha256: string] {
  if not ($file_path | path exists) {
    print $"(ansi red)错误：文件不存在: ($file_path)(ansi reset)"
    return false
  }

  try {
    let actual_hash = (open $file_path | hash sha256)
    if ($actual_hash | str downcase) == ($expected_sha256 | str downcase) {
      print $"(ansi green)✓ SHA256校验通过(ansi reset)"
      return true
    } else {
      print $"(ansi red)✗ SHA256校验失败(ansi reset)"
      print $"期望: ($expected_sha256)"
      print $"实际: ($actual_hash)"
      return false
    }
  } catch {
    print $"(ansi red)错误：计算SHA256失败(ansi reset)"
    return false
  }
}

# 下载文件
export def download-asset [asset_info: record, output_path: string] {
  let download_url = $asset_info.browser_download_url

  print $"(ansi green)正在下载文件: ($asset_info.name)...(ansi reset)"
  print $"下载地址: ($download_url)"

  try {
    # 确保输出目录存在
    let output_dir = ($output_path | path dirname)
    if not ($output_dir | path exists) {
      mkdir $output_dir
    }

    # 下载文件
    http get $download_url | save --force $output_path

    print $"(ansi green)✓ 下载完成(ansi reset)"

    # GitHub源不提供SHA256校验，跳过文件完整性验证
    # 可以通过文件大小进行基本验证
    if ($asset_info.size? | is-not-empty) {
      let expected_size = $asset_info.size
      let file_info = (ls $output_path | first)
      let actual_size = ($file_info | get size | into int)
      if $expected_size != $actual_size {
        print $"(ansi yellow)警告：文件大小不匹配(ansi reset)"
        print $"期望: ($expected_size) 字节，实际: ($actual_size) 字节"
      } else {
        print $"(ansi green)✓ 文件大小验证通过(ansi reset)"
      }
    }

    return true
  } catch {
    print $"(ansi red)错误：下载失败: ($download_url)(ansi reset)"
    if ($output_path | path exists) {
      rm $output_path
    }
    return false
  }
}
