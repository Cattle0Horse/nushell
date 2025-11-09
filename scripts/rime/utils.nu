# Rime 通用工具函数模块

use const.nu *

# 比较本地和远程更新时间
export def compare-update-time [local_time: any, remote_time: datetime] {
  if ($local_time | is-empty) {
    print $"(ansi yellow)本地时间记录不存在，将创建新的时间记录(ansi reset)"
    return true
  }

  try {
    let local_datetime = ($local_time | into datetime)

    if $remote_time > $local_datetime {
      print $"(ansi yellow)发现新版本，准备更新(ansi reset)"
      return true
    } else {
      print $"(ansi green)当前已是最新版本(ansi reset)"
      return false
    }
  } catch { |err|
    print $"(ansi yellow)本地时间记录格式错误，将重新创建: ($err.msg)(ansi reset)"
    return true
  }
}

# 初始化数据目录
def init-data-dir [] {
  if not ($RIME_DATA_DIR | path exists) {
    try {
      mkdir $RIME_DATA_DIR
      print $"(ansi cyan)创建数据目录: ($RIME_DATA_DIR)(ansi reset)"
    } catch { |err|
      print $"(ansi red)错误：无法创建数据目录 ($RIME_DATA_DIR): ($err.msg)(ansi reset)"
    }
  }
}

# 获取时间记录文件路径
export def get-time-record-file-path [] {
  init-data-dir
  return ($RIME_DATA_DIR | path join $RELEASE_TIME_RECORD_FILE)
}

# 保存时间记录到JSON文件
export def save-time-record [key: string, value: datetime] {
  let file_path = (get-time-record-file-path)

  let time_data = if ($file_path | path exists) {
    try {
      open $file_path
    } catch { |err|
      print $"(ansi yellow)警告：无法读取时间记录文件，将创建新的记录: ($err.msg)(ansi reset)"
      {}
    }
  } else {
    {}
  }

  let updated_data = ($time_data | upsert $key $value)

  try {
    $updated_data | to json | save --force $file_path
    print $"(ansi green)✓ 时间记录已保存(ansi reset)"
  } catch { |err|
    print $"(ansi red)错误：无法保存时间记录: ($err.msg)(ansi reset)"
  }
}

# 从JSON文件获取时间记录
export def get-time-record [key: string] : nothing -> datetime {
  let file_path = (get-time-record-file-path)

  if not ($file_path | path exists) {
    return null
  }

  try {
    let time_data = (open --raw $file_path | from json)
    if ($key in $time_data) {
      return ($time_data | get $key | into datetime)
    } else {
      return null
    }
  } catch { |err|
    print $"(ansi yellow)警告：无法读取时间记录文件: ($err.msg)(ansi reset)"
    return null
  }
}

# 读取并解析时间记录文件的所有键
export def read-all-time-records [] {
  let file_path = (get-time-record-file-path)
  if not ($file_path | path exists) {
    print $"(ansi yellow)警告：时间记录文件不存在(ansi reset)"
    return {}
  }

  try {
    return (open $file_path)
  } catch {
    print $"(ansi red)错误：无法解析时间记录文件(ansi reset)"
    return {}
  }
}

# 格式化文件大小
export def format-file-size [size: int] {
  if $size < 1024 {
    return $"($size) B"
  } else if $size < (1024 * 1024) {
    let kb = ($size / 1024 | math round --precision 1)
    return $"($kb) KB"
  } else if $size < (1024 * 1024 * 1024) {
    let mb = ($size / (1024 * 1024) | math round --precision 1)
    return $"($mb) MB"
  } else {
    let gb = ($size / (1024 * 1024 * 1024) | math round --precision 1)
    return $"($gb) GB"
  }
}

# 创建临时文件路径
export def create-temp-file-path [filename: string] {
  return ($env.TEMP | path join $filename)
}

# 确保目录存在
export def ensure-directory-exists [dir_path: string] {
  if not ($dir_path | path exists) {
    try {
      mkdir $dir_path
      print $"(ansi green)✓ 创建目录: ($dir_path)(ansi reset)"
      return true
    } catch {
      print $"(ansi red)错误：无法创建目录: ($dir_path)(ansi reset)"
      return false
    }
  }
  return true
}

# 安全删除文件
export def safe-remove-file [file_path: string] {
  if ($file_path | path exists) {
    try {
      rm $file_path
      print $"(ansi green)✓ 删除文件: ($file_path)(ansi reset)"
      return true
    } catch {
      print $"(ansi yellow)警告：无法删除文件: ($file_path)(ansi reset)"
      return false
    }
  }
  return true
}

# 验证文件路径和权限
export def validate-target-directory [dir_path: string] {
  # 检查目录是否存在
  if not ($dir_path | path exists) {
    print $"(ansi red)错误：目标目录不存在: ($dir_path)(ansi reset)"
    return false
  }

  # 检查是否为目录
  let path_type = (ls $dir_path | get type | first)
  if $path_type != "dir" {
    print $"(ansi red)错误：指定路径不是目录: ($dir_path)(ansi reset)"
    return false
  }

  # 检查写权限（尝试创建临时文件）
  let test_file = ($dir_path | path join $".rime_perm_test_(random uuid).tmp")
  try {
    "" | save $test_file
    rm $test_file
    print $"(ansi green)✓ 目录权限验证通过: ($dir_path)(ansi reset)"
    return true
  } catch {
    print $"(ansi red)错误：没有对目标目录的写入权限: ($dir_path)(ansi reset)"
    return false
  }
}

# 显示进度信息
export def show-progress [current: int, total: int, message: string] {
  let percentage = ($current * 100 / $total | math round)
  print $"(ansi cyan)[($current)/($total)] (($percentage)%) ($message)(ansi reset)"
}

# 等待用户确认
export def wait-for-confirmation [message: string] {
  print $"($message) (y/N): " --no-newline
  let response = (input)
  return (($response | str downcase) in ["y", "yes", "是"])
}

# 显示错误并退出
export def error-exit [message: string, exit_code: int = 1] {
  print $"(ansi red)错误：($message)(ansi reset)"
  exit $exit_code
}

# 显示成功信息
export def success-message [message: string] {
  print $"(ansi green)✓ ($message)(ansi reset)"
}

# 显示警告信息
export def warning-message [message: string] {
  print $"(ansi yellow)⚠ ($message)(ansi reset)"
}

# 显示信息
export def info-message [message: string] {
  print $"(ansi cyan)ℹ ($message)(ansi reset)"
}

# 安全复制文件（处理文件锁定）
export def safe-copy-file [source: string, destination: string] {
  # 确保目标目录存在
  let dest_dir = ($destination | path dirname)
  if not ($dest_dir | path exists) {
    mkdir $dest_dir
  }

  # 如果目标文件存在，尝试删除
  if ($destination | path exists) {
    try {
      rm $destination
      print $"(ansi green)✓ 已删除旧文件(ansi reset)"
    } catch {
      print $"(ansi yellow)警告：无法删除旧文件，将尝试覆盖(ansi reset)"
    }

    # 等待一下确保文件句柄释放
    sleep 500ms
  }

  # 尝试复制文件，如果失败则重试
  let max_retries = 3

  for retry_count in 0..<$max_retries {
    let result = try {
      cp $source $destination
      print $"(ansi green)✓ 文件复制成功(ansi reset)"
      true
    } catch {
      false
    }

    if $result {
      return true
    } else {
      let current_retry = $retry_count + 1
      if $current_retry < $max_retries {
        print $"(ansi yellow)复制失败，等待重试... (($current_retry)/($max_retries))(ansi reset)"
        sleep 2sec
      } else {
        print $"(ansi red)错误：文件复制失败，已重试 ($max_retries) 次(ansi reset)"
        print $"源文件: ($source)"
        print $"目标文件: ($destination)"
        return false
      }
    }
  }

  return false
}
