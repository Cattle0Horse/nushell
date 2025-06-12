# 获取当前仓库的根目录
export def git-root [] : nothing -> string {
  ^git rev-parse --show-toplevel
}

export def git-current-branch [] : nothing -> string {
  ^git branch --no-color --show-current
  # ^git rev-parse --abbrev-ref HEAD
}

# 查询暂存区是否有未提交的更改
export def git-has-changed-in-staging [] : nothing -> bool {
  (^git diff --cached --quiet | complete).exit_code == 1
}

# 列出未暂存的文件
export def git-unstaged-changes [] : nothing -> list<string> {
  ^git ls-files --modified --others --exclude-standard | lines --skip-empty
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
  ^git for-each-ref --no-color --format='%(refname:short)' refs/heads/
  # ^git branch --no-color | lines | each { |line| $line | str replace '* ' "" | str replace '+ ' ""  | str trim }
}

# 获取远程分支
export def git-remote-branches [] : nothing -> list<string> {
  ^git branch --no-color -r | lines | str trim | where {|x| not ($x | str starts-with 'origin/HEAD') }
}

# 获取远程仓库
export def git-remotes [] : nothing -> list<string> {
  ^git remote | lines | each { |line| $line | str trim }
}

# 获取默认分支名称
export def git-main-branch [
  remote?: string="origin"
  --network # 通过网络从远程获取（由于网络原因会很慢，非必要不使用）
] : [
  nothing -> string
  nothing -> nothing
] {
  if $network {
    ^git remote show $remote
      | lines
      | str trim
      | find --regex 'HEAD .*?[：: ].+'
      | first
      | str replace --regex 'HEAD .*?[：: ](.+)' '$1'
  } else {
    ^git symbolic-ref --short $'refs/remotes/($remote)/HEAD' | split row '/' -n 2 | last
  }
}

# 获取所有提交的作者
export def git-authors [] : nothing -> list<string> {
  ^git log --format='%aN' | lines | str trim | uniq
}

# 对于b的已合并的分支是指那些最后提交节点在b之前或当前的分支，即b是他们的延申

# 获取所有已合并到branch的本地分支
export def git-merged-local-branches [
  --exclude: list<string> # 要保留的模式列表（如["release/*"]）
] : string -> list<string> {
  if ($in | is-empty) {
    return []
  }
  let branch = $in
  let exclude = $exclude | append [ $branch ]
  ^git for-each-ref --format='%(refname:short)' refs/heads/ --no-color --merged $branch
    | lines
    | where {|b|
      $exclude | all {|pattern| $b !~ $pattern }
    }
}

# 获取所有已合并到branch的远程分支
# export def git-merged-remote-branches [
#   upstream: string   # 上游仓库
#   branch: string     # 分支
#   --exclude: list<string> # 要保留的模式列表。默认会添加默认分支和 HEAD
# ] : nothing -> list<string> {
#   let args = [ "--list" "--merged" $"($upstream)/($branch)" ] ++ if $remote {
#       [ '--format' '%(refname:lstrip=3)' '--remote' ]
#     } else {
#       [ '--format' '%(refname:lstrip=2)' ]
#     }

#   let keep = ( $keep | append [ "HEAD" $branch ])

#   ^git branch ...$args | lines | where {|branch|
#     $keep | all {|pattern| $branch !~ $pattern }
#   }
# }

# 获取所有本地分支引用信息
export def git-all-local-refs []: nothing -> table<ref: string, obj: string, upstream: record<remote: string, branch: string>, commit: record<hash: string, author: string, date: datetime, subject: string, body: string>> {
  ^git for-each-ref --format '%(refname:short)%09%(objectname:short)%09%(upstream:remotename)%09%(upstream:short)%09%(objectname)%09%(authorname)%09%(authoremail)%09%(authordate:iso8601)%09%(contents:subject)%09%(contents:body)' refs/heads
    | lines
    | parse "{ref}\t{obj}\t{upstream_remote}\t{upstream_branch}\t{hash}\t{author_name}\t{author_email}\t{author_date}\t{commit_subject}\t{commit_body}"
    | each {|it|
      {
        ref: $it.ref
        obj: $it.obj
        upstream: {
          remote: $it.upstream_remote
          branch: $it.upstream_branch
        }
        commit: {
          hash: $it.hash
          author: $it.author_name
          email: ($it.author_email | parse '<{value}>' | get 0.value)
          date: ($it.author_date | into datetime)
          subject: $it.commit_subject
          body: $it.commit_body
        }
      }
    }
}

# 获取所有远程分支引用信息
export def git-all-remote-refs []: nothing -> table<ref: string, obj: string, commit: record<hash: string, author: string, date: datetime, subject: string, body: string>> {
  ^git for-each-ref --format '%(refname:short)%09%(objectname:short)%09%%09%(objectname)%09%(authorname)%09%(authoremail)%09%(authordate:iso8601)%09%(contents:subject)%09%(contents:body)' refs/remotes
    | lines
    | parse "{ref}\t{obj}\t{hash}\t{author_name}\t{author_email}\t{author_date}\t{commit_subject}\t{commit_body}"
    | each {|it|
      {
        ref: $it.ref
        obj: $it.obj
        commit: {
          hash: $it.hash
          author: $it.author_name
          email: ($it.author_email | parse '<{value}>' | get 0.value)
          date: ($it.author_date | into datetime)
          subject: $it.commit_subject
          body: $it.commit_body
        }
      }
    }
}

# git diff --name-only # 已跟踪未暂存的文件
# git ls-files --others --exclude-standard # 未跟踪的文件
# git ls-files --modified --others --exclude-standard # 未暂存的文件（上面两个的和）
