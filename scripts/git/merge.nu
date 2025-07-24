# Gitlab 式的压缩合并，保留合并动作
export def git-squash-and-merge [
  from: string
  to?: string  # 目标分支，默认为当前分支
  --squash(-s): string  # 压缩信息（第一个）
  --no_all_commit # 不包含squash的所有提交信息
  --merge(-m): string  # 合并信息（第二个）
  --delete(-d) # 合并后删除分支
  --no_delete # 合并后不删除分支
] : nothing -> nothing {
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

  if ($no_all_commit) {
    print $"(ansi green)使用简洁提交信息: ($squash)(ansi reset)"
    ^git commit --quiet --message $squash
  } else {
    print $"(ansi green)正在构造完整的 squash 提交信息...（包含所有提交）(ansi reset)"
    let msg = "Squashed commit of the following:\n\n" + (^git log --reverse --date=iso $'($ancestor_sha)..($from)' --pretty=format:"commit %H%nAuthor: %an <%ae>%nDate: %ad%n%n%B")
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
