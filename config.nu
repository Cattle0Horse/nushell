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

# alias 应该在 complete 之后，否则补全不会应用与 alias 的命令

use git *
# use backup *
use filesystem *
use str *
use os/windows *
use rime *
# use subtitle *

# use bilibili
# use bilibili/alias.nu *
# use kimi
use link
use chcp

use completions/scoop/scoop_zh.nu *
use completions/git/git_zh.nu *
use completions/mvn/mvn_zh.nu *
use completions/pytest/pytest_zh.nu *
use completions/uv/uv_zh.nu *
# use completions/docker/docker_zh.nu *

alias cc = code
alias cs = cursor
alias docker = podman
alias 'to string' = to json
# 重启 nushell
alias reload = exec nu
# 创建并进入文件夹
def mc --env [folder: string] : nothing -> nothing { mkdir $folder; cd $folder }
def time [] : nothing -> string { date now | format date "%Y%m%d%H%M%S" }
def today [] : nothing -> string { date now | format date "%Y%m%d" }
