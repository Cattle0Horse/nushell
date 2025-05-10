
export-env {
  $env.PACKAGE_MANAGER = ($env.DOTFILES | path join PackageManager)
}

export use scoop.nu *
export use vscode.nu *
export use winget.nu *
