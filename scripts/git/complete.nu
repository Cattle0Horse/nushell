export def cmpl-git-log [] {
  ^git log -n 32 --pretty=%h»¦«%s
  | lines
  | split column "»¦«" value description
  #| each { $"($in.value) # ($in.description)"}
  | where { completions: $in, options: { sort: false } }
}

export def cmpl-git-log-all [] {
  ^git log --all -n 32 --pretty=%h»¦«%d»¦«%s
  | lines
  | split column "»¦«" value branch description
  | each {|x| $x | update description $"($x.branch) ($x.description)" }
  | where { completions: $in, options: { sort: false } }
}

export def cmpl-git-branch-files [context: string, offset:int] {
  let token = $context | split row ' '
  let branch = $token | get 1
  let files = $token | skip 2
  ^git ls-tree -r --name-only $branch | lines | where {|x| not ($x in $files)}
}

# 获取本地分支
export def cmpl-git-local-branches [] : nothing -> list<string> {
  ^git for-each-ref --no-color --format='%(refname:short)' 'refs/heads/'
}

# 获取本地分支（不包含当前分支）
export def cmpl-git-local-branches-no-current [] : nothing -> list<string> {
  ^git branch --no-color | lines | str trim | where {|x| not ($x | str starts-with '*') }
}

# 获取远程分支
export def cmpl-git-remote-branches [] : nothing -> list<string> {
  ^git for-each-ref --no-color --format='%(refname:short)' 'refs/remotes/' | lines | str trim
}

# 获取所有分支（本地和远程）
export def cmpl-git-branches [] : nothing -> list<string> {
  ^git for-each-ref --no-color --format='%(refname:short)' 'refs/heads/' 'refs/remotes/' | lines | str trim
}

# 获取所有分支（本地和远程）
export def cmpl-git-short-refs [] : nothing -> list<string> {
  ^git for-each-ref --no-color --format='%(refname:short)' 'refs/' | lines | str trim
}

export def cmpl-git-full-refs [] : nothing -> list<string> {
  ^git for-each-ref --no-color --format='%(refname)' 'refs/' | lines | str trim
}

# 获取远程仓库
export def cmpl-git-remotes [] : nothing -> table<value: string, description: string> {
  ^git remote -v
  | parse "{value}\t{description} ({operation})"
  | select value description
  | uniq
  | sort
}

# 获取远程仓库
# export def cmpl-git-remotes [] : nothing -> list<string> {
#   ^git remote | lines | each { |line| $line | str trim }
# }

# 获取所有提交的作者
export def cmpl-git-authors [] : nothing -> list<string> {
  ^git log --format='%aN' | lines | str trim | uniq
}

# 获取所有提交的邮箱
export def cmpl-git-emails [] : nothing -> list<string> {
  ^git log --format='%aE' | lines | str trim | uniq
}
