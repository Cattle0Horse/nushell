# 小狼毫路径模块

use const.nu [WEASEL_USER_DIR_REG_PATH, WEASEL_USER_DIR_REG_KEY, DEFAULT_RIME_USER_DIR]
use const.nu [WEASEL_INSTALL_DIR_REG_PATH, WEASEL_INSTALL_DIR_REG_KEY]
use const.nu [WEASEL_SERVER_EXE_NAME, WEASEL_DEPLOY_EXE_NAME]

use utils.nu get-registry-value

# 获取小狼毫用户目录路径
export def get-weasel-user-dir [] : [
  nothing -> path
] {
  let user_dir = (get-registry-value $WEASEL_USER_DIR_REG_PATH $WEASEL_USER_DIR_REG_KEY)
  if ($user_dir | is-not-empty) {
    return $user_dir
  } else {
    return $DEFAULT_RIME_USER_DIR
  }
}

# 获取小狼毫安装目录路径
export def get-weasel-install-dir [] : [
  nothing -> nothing
  nothing -> path
] {
  let install_dir = (get-registry-value $WEASEL_INSTALL_DIR_REG_PATH $WEASEL_INSTALL_DIR_REG_KEY)
  if ($install_dir | is-not-empty) {
    return $install_dir
  } else {
    return null
  }
}

# 获取小狼毫服务端可执行程序路径
export def get-weasel-server-exe [] : [
  nothing -> nothing
  nothing -> path
] {
  let install_dir = (get-weasel-install-dir)
  if ($install_dir | is-empty) {
    return null
  }
  let server_exe = ([$install_dir, $WEASEL_SERVER_EXE_NAME] | path join)
  if ($server_exe | path exists) {
    return $server_exe
  } else {
    return null
  }
}

# 获取小狼毫部署可执行程序路径
export def get-weasel-deploy-exe [] : [
  nothing -> nothing
  nothing -> path
] {
  let install_dir = (get-weasel-install-dir)
  if ($install_dir | is-empty) {
    return null
  }
  let server_exe = ([$install_dir, $WEASEL_DEPLOY_EXE_NAME] | path join)
  if ($server_exe | path exists) {
    return $server_exe
  } else {
    return null
  }
}
