export-env {
  if ('GIT_MAIN_BRANCH_LIST' not-in $env) {
    $env.GIT_MAIN_BRANCH_LIST = ['main' 'master']
  }
}

# 获取当前仓库的根目录
export def git-root [] : nothing -> string {
  ^git rev-parse --show-toplevel
}

export def git-current-branch [] : nothing -> string {
  ^git rev-parse --abbrev-ref HEAD
}

# 查询暂存区是否有未提交的更改
export def git-has-changed-in-staging [] : nothing -> bool {
  (^git diff --cached --quiet | complete).exit_code == 1
}

# 列出未暂存的文件
export def git-ls-unstaged-changes [] : nothing -> string {
  ^git ls-files --modified --others --exclude-standard
}

# 获取当前分支的上游（远程跟踪）分支
export def git-upstream-branch []: [
  nothing -> string
  nothing -> nothing
] {
  let result = ^git rev-parse --abbrev-ref @{u} | complete
  if $result.exit_code != 0 {
    return null
  }
  return $result.stdout
}

# 查询是否有未推送的更改
export def git-has-unpushed-changes [] : nothing -> bool {
  ((^git rev-list @{u}.. | complete).stdout | split row "\n" | length) - 1 != 0
}

# 判断是当前目录是否在git仓库中
export def git-is-in-git-repo [] : nothing -> bool {
  (^git rev-parse --is-inside-work-tree | complete).exit_code == 0
}

export def git-local-branches [] : nothing -> list<string> {
  ^git branch --no-color | lines | each { |line| $line | str replace '* ' "" | str replace '+ ' ""  | str trim }
}

# 获取远程分支
export def git-remote-branches [] : nothing -> list<string> {
  ^git branch  --no-color -r | lines | str trim | where {|x| not ($x | str starts-with 'origin/HEAD') }
}

# 获取远程仓库
export def git-remotes [] : nothing -> list<string> {
  ^git remote | lines | each { |line| $line | str trim }
}

# 获取默认分支名称（默认从本地猜测main、master）
export def git-main-branch [
  --remote # 从远程获取（由于网络原因会很慢，非必要不使用）
] : [
  nothing -> string
  nothing -> nothing
] {
  if $remote {
    return (^git remote show origin
      | lines
      | str trim
      | find --regex 'HEAD .*?[：: ].+'
      | first
      | str replace --regex 'HEAD .*?[：: ](.+)' '$1')
  }
  let main_branch_list = $env.GIT_MAIN_BRANCH_LIST
  let guess = git-local-branches | where {|it| $it in $main_branch_list }
  if ($guess | is-empty) {
    print $"(ansi red)Can't guess main branch, you can set GIT_MAIN_BRANCH_LIST in env(ansi reset)"
    return null
  }
  if ($guess | length) == 1 {
    return ($guess).0
  }
  return ($guess | input list "choose main branch:")
}

# 获取所有提交的作者
export def git-authors [] : nothing -> list<string> {
  ^git log --format='%aN' | lines | str trim | uniq
}

# git diff --name-only # 已跟踪未暂存的文件
# git ls-files --others --exclude-standard # 未跟踪的文件
# git ls-files --modified --others --exclude-standard # 未暂存的文件（上面两个的和）
