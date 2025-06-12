use internal.nu *
use complete.nu *

export-env {
  if 'GIT_BRANCH_CLEANUP_KEEP' not-in $env {
    $env.GIT_BRANCH_CLEANUP_KEEP = ['release/.*']
  }
}

# 删除本地（和远程）已合并的分支
export def "git branch-cleanup" [
  upstream: string@cmpl-git-remotes = "origin" # 上游远程仓库
] : nothing -> nothing {
  let current_branch = git-current-branch
  let default_branch = git-main-branch $upstream
  let keep = $env.GIT_BRANCH_CLEANUP_KEEP

  # 切换到默认分支
  ^git switch --quiet --no-guess $default_branch

  # 确保我们使用的是默认分支的最新版本
  ^git fetch

  # 修剪过时的远程跟踪分支。这些是曾经跟踪但现在远程已删除的分支
  ^git remote prune $upstream

  # todo: 提示用户是否删除不再位于远程仓库中的本地分支

  # 删除已完全合并到默认分支的本地分支
  list_merged $upstream $default_branch --keep $keep | each {|branch|
    ^git branch --delete $branch
  }

  # 再次处理远程分支
  let merged_on_remote = list_merged $upstream $default_branch --remote --keep $keep

  if ( $merged_on_remote | is-not-empty ) {
    # print "以下远程分支已完全合并，选择你要删除的远程分支"
    $merged_on_remote | input list -d '以下远程分支已完全合并，选择你要删除的远程分支' --multi | each {|branch|
      ^git push --quiet --delete $upstream $branch
    }

    # print "以下远程分支已完全合并，将被删除："
    # $merged_on_remote | each {|| print $"\t($in)" }

    # if ( input --default 'N' "\n继续(y/N)? " | str trim ) == 'y' {
    #   $merged_on_remote | each {|branch|
    #     # 删除一个远程分支
    #     ^git push --quiet --delete $upstream $branch
    #   }
    # }
  }

  ^git switch --quiet --no-guess $current_branch
}

# 对于b的已合并的分支是指那些最后提交节点在b之前或当前的分支，即b是他们的延申

# 获取所有已合并到branch的本地分支（可以使用远程默认分支以防止本地默认分支过时）
def list_merged [
  upstream: string   # 上游仓库
  branch: string     # 分支
  --remote # 列出远程分支（默认本地）
  --keep: list<string> # 要保留的模式列表。默认会添加默认分支和 HEAD
] {
  let args = [ "--list" "--merged" $"($upstream)/($branch)" ] ++ if $remote {
      [ '--format' '%(refname:lstrip=3)' '--remote' ]
    } else {
      [ '--format' '%(refname:lstrip=2)' ]
    }

  let keep = ( $keep | append [ "HEAD" $branch ])

  ^git branch ...$args | lines | where {|branch|
    $keep | all {|pattern| $branch !~ $pattern }
  }
}
