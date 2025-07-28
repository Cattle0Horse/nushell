export-env {
  if 'GIT_MERGE_SQUASH_COMMIT_MESSAGE_TYPE' not-in $env {
    $env.GIT_MERGE_SQUASH_COMMIT_MESSAGE_TYPE = 'all_commit' # all_commit, no_all_commit, simple_commit
  }
}

# Gitlab 式的压缩合并，保留合并动作
export def git-squash-and-merge [
  from: string
  to?: string  # 目标分支，默认为当前分支
  --squash(-s): string  # 压缩信息（第一个）
  --all_commit # 包含squash的所有提交信息
  --no_all_commit # 不包含squash的所有提交信息
  --simple_commit # squash使用简洁的提交信息

  --merge(-m): string  # 合并信息（第二个）
  --delete(-d) # 合并后删除分支
  --no_delete # 合并后不删除分支
] : nothing -> nothing {
  if $env.GIT_MERGE_SQUASH_COMMIT_MESSAGE_TYPE not-in ['all_commit' 'no_all_commit' 'simple_commit'] {
    print $'(ansi red)错误：GIT_MERGE_SQUASH_COMMIT_MESSAGE_TYPE 只能是 all_commit, no_all_commit, simple_commit 三者之一(ansi reset)'
    return
  }
  if ($squash | is-empty) {
    print $'(ansi red)错误：必须提供压缩提交的信息 (--squash/-s)(ansi reset)'
    return
  }

  let to = if ($to | is-empty) {
    let current_branch = (^git branch --no-color --show-current)
    print $"(ansi cyan)未指定目标分支，默认使用当前分支: ($current_branch)(ansi reset)"
    $current_branch
  } else {
    $to
  }

  let ancestor_sha = (^git merge-base $from $to)
  ^git checkout --quiet $ancestor_sha

  ^git merge --squash --ff --quiet $from | ignore

  let squash_commit_message_type = if ($all_commit) {
    'all_commit'
  } else if ($no_all_commit) {
    'no_all_commit'
  } else if ($simple_commit) {
    'simple_commit'
  } else {
    $env.GIT_MERGE_SQUASH_COMMIT_MESSAGE_TYPE
  }

  if ($squash_commit_message_type == 'all_commit') {
    print $"(ansi green)正在构造完整的 squash 提交信息...(ansi reset)"
    let msg = "Squashed commit of the following:\n\n" + (^git log --reverse --date=iso $'($ancestor_sha)..($from)' --pretty=format:"commit %H%nAuthor: %an <%ae>%nDate: %ad%n%n%B")
    ^git commit --quiet --message $"($squash)\n\n($msg)"
  } else if ($squash_commit_message_type == 'no_all_commit') {
    print $"(ansi green)不包含被 squash 的任何信息: ($squash)(ansi reset)"
    ^git commit --quiet --message $squash
  } else {
    print $"(ansi green)正在构造简洁的 squash 提交信息...（只包含 subject 和 body）(ansi reset)"
    let msg = "Squashed commit of the following:\n\n" + (^git log --reverse --date=iso $'($ancestor_sha)..($from)' --pretty=format:"%b")
    ^git commit --quiet --message $"($squash)\n\n($msg)"
  }

  let source_sha = (^git rev-parse HEAD)

  ^git switch --quiet $to

  let subject = $"Merge branch '($from)' into '($to)'"
  let body = if ($merge | is-not-empty) {
      $merge
    } else if ($squash | is-not-empty) {
      $squash
    } else {
      null
    }

  let msg = if ($body | is-not-empty) {
    [$subject $body $'See commit ($source_sha)']
  } else {
    [$subject $'See commit ($source_sha)']
  } | str join $'(char newline)(char newline)'

  ^git merge --quiet --message $msg --no-ff $source_sha
  print $"(ansi green)✅ 分支 '$from' 已成功 squash 合并到 '$to'(ansi reset)"

  if ((not $no_delete) and ($delete or (([No Yes] | input list "\n是否要删除分支") == 'Yes'))) {
    print $"(ansi red)正在删除分支: ($from)(ansi reset)"
    ^git branch --quiet -D $from
  }
}
