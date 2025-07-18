use complete.nu *

export-env {
  if 'GIT_BRANCH_CLEANUP_KEEP' not-in $env {
    # 每个仓库的要求不一样，可以写入仓库等级的 gitconfig 中，但仍应提供一个默认值，当仓库没有配置时，使用该默认值，并提示用户是否写入gitconfig
    $env.GIT_REMOTE_BRANCH_CLEANUP_KEEP = ['release/*']
    $env.GIT_LOCAL_BRANCH_CLEANUP_KEEP = []
  }
}

# 修剪远程分支（即 $'refs/remotes/($upstream)' 下的引用）
export def git-remote-branch-cleanup [
  upstream: string@cmpl-git-remotes = "origin" # 上游远程仓库
  --merge: string@cmpl-git-remote-branches # 修剪已完全merge的分支
  # --keep: list<string> # 要保留的模式列表。若不指定，则使用 git config 中的值
] : nothing -> nothing {
  if ($merge | is-not-empty) and not ($merge starts-with $upstream) {
    print $'(ansi red)远程分支名必须以 $upstream 开头，当前应为 ($upstream)(ansi reset)'
    return
  }

  ^git fetch --prune $upstream

  if ($merge | is-empty) {
    return
  }

  let merged_branches = do { ^git for-each-ref --no-color --format='%(refname:short)' --exclude $'refs/remotes/($upstream)/HEAD' --exclude $'refs/remotes/($merge)' --merged $'refs/remotes/origin/HEAD' $'refs/remotes/($upstream)/' }
  | complete
  | if ($in.exit_code != 0) {
      print $'(ansi red)($in.stderr)(ansi reset)'
      return
    } else {
      $in.stdout
    }
  | lines
  | if ($in | is-empty) {
      print '没有已完全合并的远程分支'
      return
    } else {
      $in
    }
  | input list --multi $'以下远程分支已完全合并至($merge)，选择你要删除的远程分支'

  if ($merged_branches | is-empty) {
      print '没有修剪任何远程分支'
      return
  }

  do { ^git push $upstream --delete ...($in | str replace $'($upstream)/' '') }
  | complete
  | if ($in.exit_code != 0) {
      print $'(ansi red)($in.stderr)(ansi reset)'
    } else {
      print $'(ansi green)已修剪远程分支：(char newline)($in.stdout)(ansi reset)'
    }
}

# 修剪本地分支（即 $'refs/heads' 下的引用）
export def git-local-branch-cleanup [
  upstream: string@cmpl-git-remotes = "origin" # 上游远程仓库
  --fetch # 是否更新本地的远程分支
  --push # 是否将修剪的本地分支（即 `refs/heads`）推送到远端（若启用该选项，则会同时启用 --fetch）
  --merge: string@cmpl-git-local-branches # 修剪已完全merge的分支
  # --keep: list<string> # 要保留的模式列表。若不指定，则使用 git config 中的值
] : nothing -> nothing {
  if $fetch or $push {
    ^git fetch --prune $upstream
  }

  if ($merge | is-empty) {
    print $'(ansi red)请使用 --merge 参数指定要基于哪个本地分支进行修剪(ansi reset)'
    return
  }

  # 获取已合并到指定分支的本地分支列表
  let merged_branches = do { ^git for-each-ref --no-color --format='%(refname:short)' --exclude $'refs/heads/($merge)' --merged $'refs/heads/($merge)' 'refs/heads/' }
  | complete
  | if ($in.exit_code != 0) {
      print $'(ansi red)($in.stderr)(ansi reset)'
      return
    } else {
      $in.stdout
    }
  | lines
  | if ($in | is-empty) {
      print '没有已完全合并的本地分支'
      return
    } else {
      $in
    }
  | input list --multi $'以下本地分支已完全合并至($merge)，选择你要删除的本地分支'

  if ($merged_branches | is-empty) {
    print '没有修剪任何本地分支'
    return
  }

  # 删除本地分支
  do { ^git branch --delete ...$merged_branches }
  | complete
  | if ($in.exit_code != 0) {
      print $'(ansi red)($in.stderr)(ansi reset)'
      return
    } else {
      print $'(ansi green)已修剪本地分支：(char newline)($in.stdout)(ansi reset)'
    }

  if $push {
    # 如果启用了push选项，先删除远程分支
    do { ^git push $upstream --delete ...$merged_branches }
    | complete
    | if ($in.exit_code != 0) {
        print $'(ansi red)($in.stderr)(ansi reset)'
      } else {
        print $'(ansi green)已修剪远程分支：(char newline)($in.stdout)(ansi reset)'
      }
  }
}
