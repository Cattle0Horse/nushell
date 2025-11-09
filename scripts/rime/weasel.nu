# 小狼毫输入法服务管理模块

use const.nu *

# 从注册表获取值
def get-registry-value [reg_path: string, reg_key: string] {
  try {
    let result = (^reg query $reg_path /v $reg_key | complete)
    if $result.exit_code == 0 {
      let lines = ($result.stdout | lines)
      let value_line = ($lines | where {|line| $line | str contains $reg_key} | first)
      if ($value_line | is-not-empty) {
        # 解析注册表输出格式: "  RimeUserDir  REG_SZ  C:\Users\..."
        let parts = ($value_line | str trim | split row -r '\s+')
        if ($parts | length) >= 3 {
          return ($parts | skip 2 | str join " ")
        }
      }
    }
    return null
  } catch {
    return null
  }
}

# 获取小狼毫用户目录路径
export def get-weasel-user-dir [] {
  let user_dir = (get-registry-value $WEASEL_USER_DIR_REG_PATH $WEASEL_USER_DIR_REG_KEY)
  if ($user_dir | is-not-empty) {
    return $user_dir
  } else {
    print $"(ansi yellow)警告：未找到Weasel用户目录，使用默认路径(ansi reset)"
    return $DEFAULT_RIME_USER_DIR
  }
}

# 获取小狼毫安装目录路径
export def get-weasel-install-dir [] {
  let install_dir = (get-registry-value $WEASEL_INSTALL_DIR_REG_PATH $WEASEL_INSTALL_DIR_REG_KEY)
  if ($install_dir | is-not-empty) {
    return $install_dir
  } else {
    print $"(ansi red)错误：未找到Weasel安装目录，请确保已正确安装小狼毫输入法(ansi reset)"
    return null
  }
}

# 获取小狼毫服务端可执行程序路径
export def get-weasel-server-executable [] {
  let server_exe = (get-registry-value $WEASEL_INSTALL_DIR_REG_PATH $WEASEL_SERVER_EXECUTABLE_REG_KEY)
  if ($server_exe | is-not-empty) {
    return $server_exe
  } else {
    print $"(ansi red)错误：未找到Weasel服务端可执行程序，请确保已正确安装小狼毫输入法(ansi reset)"
    return null
  }
}

# 停止小狼毫服务
export def stop-weasel-server [] {
  let install_dir = (get-weasel-install-dir)
  let server_exe = (get-weasel-server-executable)

  if ($install_dir | is-empty) or ($server_exe | is-empty) {
    print $"(ansi red)错误：无法获取小狼毫路径信息(ansi reset)"
    return false
  }

  try {
    let server_path = ($install_dir | path join $server_exe)
    ^$server_path /q
    sleep 1sec
    print $"(ansi green)✓ 小狼毫服务已停止(ansi reset)"
    return true
  } catch {
    print $"(ansi red)错误：停止小狼毫服务失败(ansi reset)"
    return false
  }
}

# 启动小狼毫服务
export def start-weasel-server [] {
  let install_dir = (get-weasel-install-dir)
  let server_exe = (get-weasel-server-executable)

  if ($install_dir | is-empty) or ($server_exe | is-empty) {
    print $"(ansi red)错误：无法获取小狼毫路径信息(ansi reset)"
    return false
  }

  try {
    let server_path = ($install_dir | path join $server_exe)
    # 使用 start 命令确保进程完全分离
    ^cmd /c start "" $server_path
    sleep 1sec
    print $"(ansi green)✓ 小狼毫服务已启动(ansi reset)"
    return true
  } catch {
    print $"(ansi red)错误：启动小狼毫服务失败(ansi reset)"
    return false
  }
}

# 触发小狼毫重新部署
export def redeploy-weasel [] {
  let default_shortcut = "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\小狼毫输入法\\【小狼毫】重新部署.lnk"
  let backup_shortcut = "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Weasel\\Weasel Deploy.lnk"

  try {
    if ($default_shortcut | path exists) {
      print $"(ansi green)找到默认【小狼毫】重新部署快捷方式，正在执行...(ansi reset)"
      ^cmd /c start "" $default_shortcut
      return true
    } else if ($backup_shortcut | path exists) {
      print $"(ansi green)找到备用【小狼毫】重新部署快捷方式，正在执行...(ansi reset)"
      ^cmd /c start "" $backup_shortcut
      return true
    } else {
      print $"(ansi yellow)未找到【小狼毫】重新部署快捷方式，跳过重新部署(ansi reset)"
      return false
    }
  } catch {
    print $"(ansi red)错误：触发重新部署失败(ansi reset)"
    return false
  }
}

# 验证小狼毫安装
export def verify-weasel-installation [] {
  let user_dir = (get-weasel-user-dir)
  let install_dir = (get-weasel-install-dir)
  let server_exe = (get-weasel-server-executable)

  print $"(ansi cyan)小狼毫安装验证：(ansi reset)"
  print $"用户目录: ($user_dir)"
  print $"安装目录: ($install_dir)"
  print $"服务程序: ($server_exe)"

  if ($user_dir | is-not-empty) and ($install_dir | is-not-empty) and ($server_exe | is-not-empty) {
    print $"(ansi green)✓ 小狼毫安装验证通过(ansi reset)"
    return true
  } else {
    print $"(ansi red)✗ 小狼毫安装验证失败(ansi reset)"
    return false
  }
}
