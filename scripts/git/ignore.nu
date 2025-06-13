# 自动根据文件情况执行相应命令
# export def "git ignore" [] {
#   # todo:
# }

const IGNORE_INIT_CONTENT = '# Ignore everything in this directory
*
# Except this file
!.gitignore
'

# 添加忽略方案到.gitignore
export def "git ignore add" [
  object: string # 忽略方案
] : nothing -> nothing {
  let f = ignore-path
  let s: string = if ($f | path exists) {
    let content = open $f
    if (not ($content | is-empty) and not ($content | str ends-with (char newline))) {
      (char newline)
    } else {
      ''
    }
  } else {
    ''
  }
  ($s + $object + (char newline)) | save -a $f
}

# 初始化.gitignore
export def "git ignore init" [
  path?: path # 指定路径，如果没有则会使用仓库根目录
  --force(-f) # 若已经存在则覆盖
] : nothing -> nothing {
  if ($path | is-empty) {
    $IGNORE_INIT_CONTENT | save --force=$force (ignore-path)
  } else {
    $IGNORE_INIT_CONTENT | save --force=$force ([$path '.gitignore'] | path join)
  }
}

# 编辑.gitignore
export def "git ignore edit" [
  path?: path # 指定路径，如果没有则会使用仓库根目录
  --global
] {
  if ($path | is-empty) {
    ^($env.config.buffer_editor) (ignore-path --global=$global)
  } else {
    ^($env.config.buffer_editor) ([$path '.gitignore'] | path join)
  }
}

# 获取.gitignore文件路径(可能不存在)
def ignore-path [--global] : nothing -> path {
  if $global {
    # '~/.gitignore'
    [$nu.home-path .config git ignore] | path join
  } else {
    $"(^git rev-parse --show-toplevel)/.gitignore"
  }
}
