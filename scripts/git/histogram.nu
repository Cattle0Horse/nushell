use complete.nu *
# ^git shortlog -s --no-merges --all --group=format:'|%aN|%aE|' | lines | str trim | parse "{number}\t{value}"
# git shortlog [<options>] [<revision-range>] [[--] <path>...]
# revision-range 表示查询范围，如 `main..dev` ，默认为 HEAD，表示从当前分支的初始提交到最新提交
# path 表示指定文件或目录，如 README.md

# todo: 增加统计一个时间区间内的提交

def interval-to-date-format [] : string -> string {
  match $in {
    'hour' => '%Y-%m-%d %H'
    'day' => '%Y-%m-%d'
    'month' => '%Y-%m'
    'year' => '%Y'
    _ => '%Y-%m-%d'
  }
}

def precent [] {
  ($in * 10000 | math round) / 100
}

def frequency [--width(-w): int] {
  let o = $in
  '' | fill -c '*' -w ($o * $width | math round)
}

# 按指定列作为数据，生成百分比及直方图
def histogram-column [
  column: string     # 指定列名
  --len(-l):int = 50 # 直方图最大宽度
] {
  let o = $in
  let total = $o | get $column | math sum
  let max = $o | get $column | math max | ($in / $total)
  $o | each {|x|
    let c = $x | get $column | $in / $total
    $x
    | insert precent $"($c | precent)%"
    | insert frequency ($c / $max | frequency --width $len)
  }
}

# 核心处理函数
def git-histogram-core [
  group: record         # 分组字段配置
  --range: string       # 指定范围如（main、main..dev）若不指定则默认使用HEAD
  --author: string      # 筛选指定作者名
  --email: string       # 筛选指定邮箱
  --date-format: string # 日期格式
  --interval: string    # 按周期统计（将会覆盖--date-format）
  --files: list<string> # 统计指定的文件或目录，支持通配符（如*.md）
  --merges              # 仅统计合并提交
  --no-merges           # 仅统计非合并提交
  --all                 # 遍历 refs/
] : nothing -> table {
  let sep = '»¦«'

  mut args = ['--summary' '--no-color']
  if $merges { $args ++= ['--merges'] }
  if $no_merges { $args ++= ['--no-merges'] }
  if $all { $args ++= ['--all'] }
  if ($author | is-not-empty) { $args ++= [$'--author=($author)'] }
  if ($email | is-not-empty) { $args ++= [$'--author=<($email)>'] }

  let date_format = if ($interval | is-not-empty) {
    $'format:($interval | interval-to-date-format)'
  } else if ($date_format | is-not-empty) {
    $date_format
  } else {
    null
  }

  let group: record = if ($date_format | is-not-empty) {
    $args ++= [$'--date=($date_format)']
    $group | insert 'date' '%ad'
  } else {
    $group
  }

  if ($group | is-empty) {
    print $'(ansi reset)至少指定一个分组字段(ansi reset)'
    return
  }

  let group: table = $group | transpose key value
  $args ++= [$'--group=format:($group | get value | str join $sep)']

  if ($range | is-not-empty) { $args ++= [$range] }
  if ($files | is-not-empty) { $args ++= ['--' ...$files] }

  ^git shortlog ...$args
  | lines
  | str trim
  | parse "{count}\t{value}"
  | each {|it|
    $it.value
    | split column $sep ...($group | get key)
    | upsert count ($it.count | into int)
    | first
  }
  | histogram-column count
}

# 分组活动统计，持按email、author、interval、自定义日期及其任意组合分组
export def "git-histogram" [
  ...files: string                      # 统计指定的文件或目录，支持通配符（如*.md）
  --range(-r): string@cmpl-git-branches # 指定范围如（main、main..dev）若不指定则默认使用HEAD
  --author(-a)                          # 作者名
  --email(-e)                           # 邮箱
  --date-format(-d): string             # 日期格式
  --interval(-i): string@cmpl-interval  # 按周期统计（将会覆盖--date-format）
  --merges(-m)                          # 仅统计合并提交
  --no-merges(-M)                       # 仅统计非合并提交
  --all                                 # 遍历 refs/
] : nothing -> table {
  mut group: record = {}
  if $author { $group = $group | insert 'author' '%aN' }
  if $email { $group = $group | insert 'email' '%aE' }
  git-histogram-core $group --files=$files --range=$range --date-format=$date_format --interval=$interval --merges=$merges --no-merges=$no_merges --all=$all
}

# 统计指定作者的提交
export def "git-histogram-author" [
  author: string@cmpl-git-authors       # 作者名称
  ...files: string                      # 指定文件或目录，支持通配符（如*.md）
  --range(-r): string@cmpl-git-branches # 指定范围如（main、main..dev）若不指定则默认使用HEAD
  --date-format(-d): string             # 日期格式
  --interval(-i): string@cmpl-interval  # 按统计周期（将会覆盖--date-format）
  --merges(-m)                          # 仅统计合并提交
  --no-merges(-M)                       # 仅统计非合并提交
  --all                                 # 遍历 refs/
] : nothing -> table {
  let group = { author: "%aN" }
  git-histogram-core $group --author=$author --files=$files --range=$range --date-format=$date_format --interval=$interval --merges=$merges --no-merges=$no_merges --all=$all
}

# 统计指定邮箱的活动
export def "git-histogram-email" [
  email: string@cmpl-git-emails         # 作者邮箱
  ...files: string                      # 指定文件或目录，支持通配符（如*.md）
  --range(-r): string@cmpl-git-branches # 指定范围如（main、main..dev）若不指定则默认使用HEAD
  --date-format(-d): string             # 日期格式
  --interval(-i): string@cmpl-interval  # 按统计周期（将会覆盖--date-format）
  --merges(-m)                          # 仅统计合并提交
  --no-merges(-M)                       # 仅统计非合并提交
  --all                                 # 遍历 refs/
] : nothing -> table {
  let group = { email: "%aE" }
  git-histogram-core $group --email=$email --files=$files --range=$range --date-format=$date_format --interval=$interval --merges=$merges --no-merges=$no_merges --all=$all
}

# %a：星期的缩写。 Abbreviated weekday name
#
# %A：星期的全名。 Full weekday name
#
# %b：月份的缩写。 Abbreviated month name
#
# %B：月份的全称。 Full month name
#
# %c：适用于区域设置的日期和时间表示 。Date and time representation appropriate for locale
#
# %d：月中的天作为十进制数字（01 – 31）。 Day of month as decimal number (01  – 31)
#
# %H：24小时制的小时（00 – 23）。   Hour in 24-hour format (00  – 23)
#
# %I：12小时格式的小时（01 – 12）。Hour in 12-hour format (01  – 12)
#
# %j：一年中的天作为十进制数字（001 – 366）。Day of year as decimal number (001  – 366)
#
# %m：以十进制数字表示的月份（01 – 12）。Month as decimal number (01  – 12)
#
# %M：分钟以十进制数字表示（00 – 59）。Minute as decimal number (00  – 59)
#
# %p：当前语言环境的"上午/下午"，12小时制的指示器。Current locale's A.M./P.M. indicator for 12-hour clock
#
# %S：秒作为十进制数字（00 – 59）。Second as decimal number (00  – 59)
#
# %U：一年中的周为十进制数字，周日为一周的第一天（00 – 53）。Week of year as decimal number, with Sunday as first day of week (00  – 53)
#
# %w：工作日为十进制数字（0 – 6；星期日为0）。Weekday as decimal number (0  –  6; Sunday is 0)
#
# %W：一年中的星期作为十进制数字，星期一作为星期的第一天（00 – 53）。Week of year as decimal number, with Monday as first day of week (00  – 53)
#
# %x：当前语言环境的日期表示。Date representation for current locale
#
# %X：当前语言环境的时间表示。 Time representation for current locale
#
# %y：无世纪的年份，为十进制数字（00 – 99），也就是年份没有前两位。
#
# %Y：带世纪的年份，以十进制数表示。
#
# %z，%Z：时区名称或时区缩写，取决于注册表设置； 如果时区未知，则没有字符。
#
# %%：表示百分号。
#
