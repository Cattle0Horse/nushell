# Rime 模型更新核心逻辑模块

use const.nu *
use weasel.nu *
use download.nu *
use utils.nu *

# 获取模型更新时间记录键
def get-model-update-time-key [release_tag: string] {
  return $"($release_tag)_gram_update_time"
}

# 获取模型文件路径
def get-model-file-path [target_dir: string] {
  return ($target_dir | path join $GRAM_MODEL_FILENAME)
}

# 检查是否需要更新模型
def should-update-model [
  local_time: any,
  remote_time: datetime,
  model_file_path: string,
  asset_info: record
] {
  # 比较时间戳
  if (compare-update-time $local_time $remote_time) {
    return true
  }

  # 如果时间戳相同，检查文件是否存在和大小
  if ($model_file_path | path exists) {
    # GitHub源检查文件大小（基本验证）
    if ($asset_info.size? | is-not-empty) {
      let expected_size = $asset_info.size
      let file_info = (ls $model_file_path | first)
      let actual_size = ($file_info | get size | into int)
      if $expected_size != $actual_size {
        print $"(ansi red)文件大小不匹配，需要更新(ansi reset)"
        print $"期望大小: ($expected_size) 字节，实际大小: ($actual_size) 字节"
        return true
      }
    }
    return false
  } else {
    print $"(ansi red)模型文件不存在，需要下载(ansi reset)"
    return true
  }
}

# 执行模型更新
def update-model-file [
  asset_info: record,
  target_dir: string,
  update_time_key: string,
  remote_time: datetime,
  force: bool = false
] {
  try {
    # 下载模型文件到缓存
    print $"(ansi green)正在获取模型文件...(ansi reset)"
    let cache_file = if $force {
      download-to-cache $asset_info --force
    } else {
      download-to-cache $asset_info
    }
    if ($cache_file | is-empty) {
      print $"(ansi red)错误：模型文件获取失败(ansi reset)"
      return false
    }

    # 停止小狼毫服务
    if not (stop-weasel-server) {
      print $"(ansi yellow)警告：停止小狼毫服务失败，继续执行文件复制(ansi reset)"
    }

    # 等待1秒确保服务完全停止
    sleep 1sec

    # 复制文件到目标目录
    print $"(ansi green)正在复制模型文件...(ansi reset)"
    let target_file = (get-model-file-path $target_dir)

    if not (safe-copy-file $cache_file $target_file) {
      print $"(ansi red)错误：模型文件复制失败(ansi reset)"
      return false
    }

    # 保存时间记录
    try {
      save-time-record $update_time_key $remote_time
    } catch { |err|
      print $"(ansi yellow)警告：保存时间记录失败: ($err.msg)(ansi reset)"
    }

    print $"(ansi green)✓ 模型更新完成(ansi reset)"
    return true

  } catch { |err|
    print $"(ansi red)错误：模型更新过程中发生异常: ($err.msg)(ansi reset)"
    return false
  }
}

# 主要的模型更新函数
export def update-rime-model [
  --force(-f)           # 强制更新
  --target-dir(-t): string    # 指定目标目录
] {
  print $"(ansi cyan)=== Rime 模型更新工具 ===(ansi reset)"

  # 验证小狼毫安装
  if not (verify-weasel-installation) {
    print $"(ansi red)错误：小狼毫安装验证失败，无法继续(ansi reset)"
    return false
  }

  # 确定目标目录
  let target_directory = if ($target_dir | is-not-empty) {
    $target_dir
  } else {
    get-weasel-user-dir
  }

  if ($target_directory | is-empty) {
    print $"(ansi red)错误：无法确定目标目录(ansi reset)"
    return false
  }

  print $"目标目录: ($target_directory)"

  # 确保目标目录存在
  if not ($target_directory | path exists) {
    print $"(ansi cyan)创建目标目录: ($target_directory)(ansi reset)"
    mkdir $target_directory
  }

  # 设置GitHub源参数
  let owner = $SCHEMA_OWNER
  let repo = $GRAM_REPO
  let release_tag = $GRAM_RELEASE_TAG

  print $"使用源: GitHub"

  # 获取发布信息
  let releases = (get-release-info $owner $repo)
  if ($releases | is-empty) {
    print $"(ansi red)错误：无法获取发布信息(ansi reset)"
    return false
  }

  # 选择模型发布
  let selected_release = (select-gram-release $releases $release_tag)
  if ($selected_release | is-empty) {
    print $"(ansi red)错误：未找到符合条件的模型发布(ansi reset)"
    return false
  }

  # 获取模型资源信息
  let asset_info = (get-expected-asset-info $selected_release $GRAM_KEY_TABLE ($GRAM_FILE_TABLE_INDEX | into string))
  if ($asset_info | is-empty) {
    print $"(ansi red)错误：未找到模型文件资源(ansi reset)"
    return false
  }

  print $"找到模型文件: ($asset_info.name)"

  # 获取远程更新时间
  let remote_time = ($asset_info.updated_at | into datetime)
  print $"远程更新时间: ($remote_time)"

  # 检查本地时间记录
  let update_time_key = (get-model-update-time-key $release_tag)
  let local_time = (get-time-record $update_time_key)

  print $"本地记录时间: ($local_time)"

  # 检查是否需要更新
  let model_file_path = (get-model-file-path $target_directory)
  let needs_update = if $force {
    print $"(ansi yellow)强制更新模式(ansi reset)"
    true
  } else {
    should-update-model $local_time $remote_time $model_file_path $asset_info
  }

  if not $needs_update {
    print $"(ansi green)✓ 模型已是最新版本，无需更新(ansi reset)"
    return true
  }

  # 执行更新
  print $"(ansi yellow)开始更新模型...(ansi reset)"
  let update_success = (update-model-file $asset_info $target_directory $update_time_key $remote_time $force)

  if $update_success {
    # 启动小狼毫服务
    if not (start-weasel-server) {
      print $"(ansi yellow)警告：启动小狼毫服务失败，请手动启动(ansi reset)"
    }

    # 触发重新部署
    sleep 1sec
    print $"(ansi cyan)正在触发重新部署...(ansi reset)"
    if not (redeploy-weasel) {
      print $"(ansi yellow)警告：触发重新部署失败，请手动重新部署(ansi reset)"
    }

    print $"(ansi green)🎉 模型更新成功完成！(ansi reset)"
    return true
  } else {
    print $"(ansi red)❌ 模型更新失败(ansi reset)"
    return false
  }
}

# 检查模型状态
export def check-rime-model-status [
  --target-dir(-t): string    # 指定目标目录
] {
  print $"(ansi cyan)=== Rime 模型状态检查 ===(ansi reset)"

  # 确定目标目录
  let target_directory = if ($target_dir | is-not-empty) {
    $target_dir
  } else {
    get-weasel-user-dir
  }

  print $"目标目录: ($target_directory)"

  # 检查本地模型文件
  let model_file_path = (get-model-file-path $target_directory)
  if ($model_file_path | path exists) {
    let file_info = (ls $model_file_path | first)
    print $"(ansi green)✓ 本地模型文件存在(ansi reset)"
    print $"  文件路径: ($model_file_path)"
    print $"  文件大小: ($file_info.size) 字节"
    print $"  修改时间: ($file_info.modified)"
  } else {
    print $"(ansi red)✗ 本地模型文件不存在(ansi reset)"
    print $"  期望路径: ($model_file_path)"
  }

  # 检查时间记录
  let release_tag = $GRAM_RELEASE_TAG
  let update_time_key = (get-model-update-time-key $release_tag)
  let local_time = (get-time-record $update_time_key)

  if ($local_time | is-not-empty) {
    print $"(ansi green)✓ 本地时间记录存在(ansi reset)"
    print $"  记录时间: ($local_time)"
  } else {
    print $"(ansi yellow)⚠ 本地时间记录不存在(ansi reset)"
  }
}
