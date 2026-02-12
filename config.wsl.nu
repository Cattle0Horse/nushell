const NU_LIB_DIRS = [
  "~/.config/nushell/scripts"
]

# const NU_PLUGIN_DIRS = [
#   ($nu.current-exe | path dirname)
#   ...$NU_PLUGIN_DIRS
# ]

$env.config.show_banner = false
$env.config.buffer_editor = "vim"

# alias 应该在 complete 之后，否则补全不会应用与 alias 的命令

use git *
use str *

use completions/git/git_zh.nu *
use completions/pytest/pytest_zh.nu *
use completions/uv/uv_zh.nu *
# use completions/docker/docker_zh.nu *

alias cs = ^cursor
alias oc = ^opencode
alias 'to string' = to json
# 重启 nushell
alias reload = exec nu
# 创建并进入文件夹
def mc --env [folder: string] : nothing -> nothing { mkdir $folder; cd $folder }
def time [] : nothing -> string { date now | format date "%Y%m%d%H%M%S" }
def today [] : nothing -> string { date now | format date "%Y%m%d" }
