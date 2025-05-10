# 在本地设置 branch-cleanup.keep 为要保留的分支模式的空格分隔列表
# git config --local --add branch-cleanup.keep 'releases/.*'

# 删除本地（和远程）已合并的分支
export def "git branch-cleanup" [
  upstream: string@remotes = "origin" # 上游远程仓库
] {
  let current_branch = current_branch
  let default_branch = get_default_branch $"refs/remotes/($upstream)/HEAD"
  let keep = get_keep

  # 切换到默认分支
  switch_branch $default_branch

  # 确保我们使用的是默认分支的最新版本
  ^git fetch

  # 修剪过时的远程跟踪分支。这些是曾经跟踪但现在远程已删除的分支
  ^git remote prune $upstream

  # 删除已完全合并到默认分支的本地分支
  list_merged $upstream $default_branch $keep
  | each {|branch|
    delete_local $branch
  }

  # 再次处理远程分支
  let merged_on_remote = list_merged --remote $upstream $default_branch $keep

  if ( $merged_on_remote | is-not-empty ) {
    print "以下远程分支已完全合并，将被删除："

    $merged_on_remote | each {||
      print $"\t($in)"
    }

    print ""

    if ( input --suppress-output "继续(y/N)? " | str trim ) == "y" {
      $merged_on_remote | each {|branch|
        delete_remote $upstream $branch
      }
    }
  }

  switch_branch $current_branch
}

# 当前分支名称
def current_branch [] {
  ^git branch --show-current |
    into string |
    str trim
}

# 删除一个本地分支
def delete_local [
  branch: string # 待删除分支
] {
  ^git branch --delete $branch
}

# 删除一个远程分支
def delete_remote [
  upstream: string # 目标仓库
  branch: string   # 待删除分支
] {
  ^git push --quiet --delete $upstream $branch
}

# 获取默认分支名称
def get_default_branch [
  upstream: string # 目标仓库
] {
  ^git symbolic-ref --short $upstream |
    str trim |
    path basename
}

# 获取本地需保留的分支列表
def get_keep [] {
  let keep = ^git config get --local --default='' branch-cleanup.keep

  if ( $keep | is-empty ) {
    return []
  }

  $keep |
    str trim |
    split column " " |
    get column1
}

# 获取所有已合并到默认分支的本地分支（使用远程默认分支以防止本地默认分支过时）
def list_merged [
  --remote # 列出远程分支（默认本地）
  upstream: string   # 上游仓库
  branch: string     # 默认分支
  keep: list<string> # 要保留的模式列表。默认会添加默认分支和 HEAD
] {
  mut args = [
    "--list"
    "--merged" $"($upstream)/($branch)"
  ]

  if $remote {
    $args = ( $args | append [
      "--format" "%(refname:lstrip=3)"
      "--remote"
    ])
  } else {
    $args = ( $args | append [
      "--format" "%(refname:lstrip=2)"
    ])
  }

  let args = $args

  let keep = ( $keep | append [
      "HEAD",
      $branch,
    ])

  ^git branch ...$args | lines | filter {|branch|
      $keep | all {|pattern| $branch !~ $'\A($pattern)\z' }
  }
}

def remotes [] {
  ^git remote -v |
    parse "{value}\t{description} ({operation})" |
    select value description |
    uniq |
    sort
}

# 切换到不同分支
def switch_branch [
  branch: string
] {
  ^git switch --quiet --no-guess $branch
}
