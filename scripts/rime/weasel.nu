# 小狼毫输入法服务管理模块

use const.nu [WEASEL_SERVER_EXE_NAME, WEASEL_DEPLOY_EXE_NAME]
use path.nu [get-weasel-install-dir, get-weasel-user-dir, get-weasel-server-exe, get-weasel-deploy-exe]

# 停止小狼毫服务
export def stop-weasel-server [] {
  let server_exe = (get-weasel-server-exe)

  if ($server_exe | is-empty) {
    print $"(ansi red)错误：无法获取 ($WEASEL_SERVER_EXE_NAME)(ansi reset)"
    return false
  }

  try {
    ^$server_exe /q
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
  let server_exe = (get-weasel-server-exe)

  if ($server_exe | is-empty) {
    print $"(ansi red)错误：无法获取 ($WEASEL_SERVER_EXE_NAME)(ansi reset)"
    return false
  }

  try {
    # 后台启动小狼毫服务，因为它是阻塞的
    job spawn --description "启动小狼毫服务" { ^$server_exe }
    print $"(ansi green)✓ 小狼毫服务已启动(ansi reset)"
    return true
  } catch {
    print $"(ansi red)错误：启动小狼毫服务失败(ansi reset)"
    return false
  }
}

# 触发小狼毫重新部署
export def redeploy-weasel [] {
  let deploy_exe = (get-weasel-deploy-exe)

  if ($deploy_exe | is-empty) {
    print $"(ansi red)错误：无法获取 ($WEASEL_DEPLOY_EXE_NAME)(ansi reset)"
    return false
  }

  try {
    # 阻塞等待其部署好
    ^$deploy_exe /deploy
    print $"(ansi green)✓ 小狼毫服务已重新部署(ansi reset)"
    return true
  } catch {
    print $"(ansi red)错误：触发重新部署失败(ansi reset)"
    return false
  }
}

# 用户资料同步
export def sync-user-data-weasel [] : [] {
  let deploy_exe = (get-weasel-deploy-exe)

  if ($deploy_exe | is-empty) {
    print $"(ansi red)错误：无法获取 ($WEASEL_DEPLOY_EXE_NAME)(ansi reset)"
    return false
  }

  try {
    ^$deploy_exe /sync
    print $"(ansi green)✓ 已同步用户资料(ansi reset)"
    return true
  } catch {
    print $"(ansi red)错误：触发重新部署失败(ansi reset)"
    return false
  }
}

# 验证小狼毫安装
export def verify-weasel-installation [] : nothing -> bool {
  let user_dir = (get-weasel-user-dir)
  let install_dir = (get-weasel-install-dir)
  let server_exe = (get-weasel-server-exe)
  let deploy_exe = (get-weasel-deploy-exe)

  print $"(ansi cyan)小狼毫安装验证：(ansi reset)"
  print $"用户目录: ($user_dir)"
  print $"安装目录: ($install_dir)"
  print $"服务程序: ($server_exe)"
  print $"部署程序: ($deploy_exe)"

  if ($user_dir | is-not-empty) and ($install_dir | is-not-empty) and ($server_exe | is-not-empty) and ($deploy_exe | is-not-empty) {
    return true
  } else {
    return false
  }
}
