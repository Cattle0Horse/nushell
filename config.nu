const NU_LIB_DIRS = [
  "~/.config/nushell/scripts"
]

# const NU_PLUGIN_DIRS = [
#   ($nu.current-exe | path dirname)
#   ...$NU_PLUGIN_DIRS
# ]

$env.config.show_banner = false
$env.config.buffer_editor = "code"

# 终端使用 utf-8 字符集
do { ^chcp 65001 } | ignore

# alias
alias cc = code
def mc --env [folder: string] : nothing -> nothing { mkdir $folder; cd $folder }


# using
use git *
use backup *
use filesystem *

use bilibili
use bilibili/alias.nu *
use kimi
use link
use chcp

use completions/scoop/scoop_zh.nu *
use completions/git/git_zh.nu *
use completions/docker/docker_zh.nu *

# use completions/eza/eza_zh.nu *
# use eza
