use std/util "path add"
path add "/home/linuxbrew/.linuxbrew/bin/"
path add "/home/linuxbrew/.linuxbrew/sbin/"
path add "~/.local/bin/"
path add "/mnt/c/Users/<your name>/AppData/Local/Programs/Microsoft VS Code/bin/"
path add "/mnt/c/Users/<your name>/scoop/apps/cursor/cursor/resources/app/bin/"

const NU_LIB_DIRS = [
  "~/.config/nushell/scripts"
]

# const NU_PLUGIN_DIRS = [
#   ($nu.current-exe | path dirname)
#   ...$NU_PLUGIN_DIRS
# ]

$env.config.show_banner = false
$env.config.buffer_editor = "vim"

# 实验性剪贴板功能可以不再特殊配置字符集了 https://www.nushell.sh/blog/2026-02-28-nushell_v0_111_0.html#experimental-native-clipboard
# 终端使用 utf-8 字符集
# do { ^chcp 65001 } | ignore

# 自动激活 Python venv 的函数
$env.config = ($env.config | upsert hooks.env_change.PWD [
  {
    # 进入包含 .venv 的目录时激活
    condition: {|_, after|
      let has_venv = ($after | default "" | path join ".venv/bin/activate.nu" | path exists)
      let active = (overlay list | where name == "activate" and active == true | length) > 0
      $has_venv and not $active
    }
    code: "overlay use .venv/bin/activate.nu"
  }

  {
    # 离开包含 .venv 的目录时退出
    condition: {|before, after|
      let was_in_venv = ($before | default "" | path join ".venv/bin/activate.nu" | path exists)
      let now_in_venv = ($after  | default "" | path join ".venv/bin/activate.nu" | path exists)
      let active = (overlay list | where name == "activate" and active == true | length) > 0
      $was_in_venv and not $now_in_venv and $active
    }
    code: "overlay hide activate --keep-env [ PWD ]"
  }
])
# 外部补全器
$env.CARAPACE_LENIENT = 1
let carapace_completer = {|spans|
  load-env {
    CARAPACE_SHELL_BUILTINS: (help commands | where category != "" | get name | each { split row " " | first } | uniq | str join "\n")
    CARAPACE_SHELL_FUNCTIONS: (help commands | where category == "" | get name | each { split row " " | first } | uniq | str join "\n")
  }

  carapace $spans.0 nushell ...$spans | from json | reject -o style
}

let external_completer = {|spans|
  # 展开 alias 以修复 nushell 的 alias 补全 bug
  let expanded_alias = scope aliases
    | where name == $spans.0
    | get -o 0.expansion

  let spans = if $expanded_alias != null {
    $spans | skip 1 | prepend ($expanded_alias | split row ' ' | take 1)
  } else { $spans }

  $carapace_completer | do $in $spans
}

$env.config = ($env.config | merge {
  completions: {
    external: {
      enable: true
      completer: $external_completer
    }
  }
})


# note: alias 应该在 complete 之后，否则补全不会应用与 alias 的命令

use history *
use git *
use str *

use completions/git/git_zh.nu *
use completions/pytest/pytest_zh.nu *
use completions/uv/uv_zh.nu *
# use completions/docker/docker_zh.nu *

alias cs = ^cursor
alias oc = ^opencode
alias cl = ^claude
alias 'to string' = to json
# 重启 nushell
alias reload = exec nu
# 创建并进入文件夹
def mc --env [folder: string] : nothing -> nothing { mkdir $folder; cd $folder }
def time [] : nothing -> string { date now | format date "%Y%m%d%H%M%S" }
def today [] : nothing -> string { date now | format date "%Y%m%d" }
