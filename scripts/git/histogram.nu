# ^git shortlog -s --no-merges --all --group=format:'|%aN|%aE|' | lines | str trim | parse "{number}\t{value}"
# git shortlog [<options>] [<revision-range>] [[--] <path>...]
# revision-range 表示查询范围，如 `main..dev` ，默认为 HEAD，表示从当前分支的初始提交到最新提交
# path 表示指定文件或目录，如 README.md

# todo: 增加按时间过滤

# 核心处理函数
def git-histogram-core [
  group: record  # 分组字段配置
  --branch(-b): string # 指定范围如（main、main..dev）若不指定则默认使用HEAD
  --files(-f): list<string> # 指定文件或目录，支持通配符（如*.md）
  --all(-a) # 遍历 refs/
  --merges(-m) # 仅统计合并提交
  --no-merges(-n) # 仅统计非合并提交
  --date-format(-d): string # 日期格式
] : nothing -> table {
  let sep = '»¦«'
  mut args = ['-s' '--no-color']

  if $merges { $args ++= ['--merges'] }
  if $no_merges { $args ++= ['--no-merges'] }
  if $all { $args ++= ['--all'] }
  if ($date_format | is-not-empty) { $args ++= [$'--date=($date_format)'] }

  let group = $group | transpose key value
  $args ++= [$'--group=format:($group | get value | str join $sep)']

  if ($branch | is-not-empty) { $args ++= [$branch] }
  if ($files | is-not-empty) { $args ++= ['--' ...$files] }

  ^git shortlog ...$args
  | lines
  | str trim
  | parse "{number}\t{value}"
  | each {|it|
    $it.value
    | split column $sep ...($group | get key)
    | upsert number ($it.number | into int)
    | get 0
  }
}

# 一个项目的提交活动统计
export def "git histogram project" [
  branch?: string # 指定范围如（main、main..dev）若不指定则默认使用HEAD
  --files: list<string> # 指定文件或目录，支持通配符（如*.md）
  --all(-a) # 遍历 refs/
  --email(-e) # 按邮箱分组（默认按作者分组）
  --merges   # 仅统计合并提交
  --no-merges # 仅统计非合并提交
] : nothing -> table {
  mut group = {
    author: "%aN"
  }
  if $email { $group = $group | insert email '%aE' }

  git-histogram-core $group --branch=$branch --files=$files --all=$all --merges=$merges --no-merges=$no_merges
}

# 一个作者的提交活动统计（将会按日期分，不会显示邮箱）
export def "git histogram author" [
  branch?: string # 指定范围如（main、main..dev）若不指定则默认使用HEAD
  --files: list<string> # 指定文件或目录，支持通配符（如*.md）
  --all(-a) # 遍历 refs/
  --merges   # 仅统计合并提交
  --no-merges # 仅统计非合并提交
] : nothing -> table {
  let group = {
    author: "%aN",
    date: "%ad"
  }

  git-histogram-core $group --branch=$branch --files=$files --all=$all --merges=$merges --no-merges=$no_merges --date-format='short'
}

# 一个作者的提交活动统计（将会按日期分）
export def "git histogram email" [
  branch?: string # 指定范围如（main、main..dev）若不指定则默认使用HEAD
  --files: list<string> # 指定文件或目录，支持通配符（如*.md）
  --all(-a) # 遍历 refs/
  --merges   # 仅统计合并提交
  --no-merges # 仅统计非合并提交
] : nothing -> table {
  let group = {
    author: "%aN",
    email: "%aE",
    date: "%ad"
  }

  git-histogram-core $group --branch=$branch --files=$files --all=$all --merges=$merges --no-merges=$no_merges --date-format='short'
}
