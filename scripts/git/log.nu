use complete.nu *

def cmpl-grep [] : nothing -> list<string> {
  [feat fix docs style refactor perf test build ci revert chore misc]
}

def git-log-core [
  parser: record # 解析对象，格式为{key: value}，key为nushell变量名，value为git标识名
  ...revision_range: string  # 区间范围，如 HEAD~10..HEAD、HEAD~2..、main（默认为HEAD）
  --author: string  # 作者名称或邮箱
  --count: int  # 最多显示的提交数量
  --skip: int  # 跳过前 N 个提交
  --grep: string  # 在提交消息中搜索
  --files: list<string>  # 只显示包含指定文件或目录的提交，支持通配符（如*.md）
  --reverse  # 逆序显示提交（从旧到新）
  --date: string='iso' # 日期格式，默认为iso
] {
  let pt = $parser | transpose key value
  let sep1 = "\u{1f}" # 使用ASCII unit separator，极低概率出现在git内容中（一个ref的内容分隔符）
  let sep2 = "\u{1e}" # 使用ASCII record separator，极低概率出现在git内容中（多个refs的分隔符）

  mut args = [
    '--no-color'
    $'--date=($date)'
    $'--pretty=format:(($pt | get value | str join $sep1) + $sep2)'
  ]

  if ($author | is-not-empty) { $args ++= ['--author', $author] }
  if ($count | is-not-empty) { $args ++= ['--max-count', $count] }
  if ($skip | is-not-empty) { $args ++= ['--skip', $skip] }
  if ($grep | is-not-empty) { $args ++= ['--grep', $grep] }
  if $reverse { $args ++= ['--reverse'] }

  $args ++= $revision_range
  if ($files | is-not-empty) { $args ++= ['--', $files] }

  ^git log ...$args
  | split row $sep2
  | str trim
  | compact --empty
  | parse ($pt | get key | each {|it| "{" + $it + "}" } | str join $sep1)
}

# 查询指定区间内的提交信息
export def git-log [
  ...revision_range: string@cmpl-git-branches  # 区间范围，如 HEAD~10..HEAD、HEAD~2..、main（默认为HEAD）
  --author: string@cmpl-git-authors # 作者名称
  --email: string@cmpl-git-emails # 作者邮箱
  --count(-n): int  # 最多显示的提交数量
  --skip(-s): int  # 跳过前 N 个提交
  --grep(-g): string@cmpl-grep  # 在提交消息中搜索
  --files(-f): list<string>  # 只显示包含指定文件或目录的提交，支持通配符（如*.md）
  --reverse(-r)  # 逆序显示提交（从旧到新）
  --long(-l)  # 显示详细信息
] {
  let author = if ($email | is-not-empty) { $email } else { $author }
  if $long {
    let parser = {
      hash: '%H',
      refs: '%D',
      parents: '%P',
      author_name: '%aN',
      author_email: '%aE',
      author_date: '%ad',
      committer_name: '%cN',
      committer_email: '%cE',
      committer_date: '%cd',
      message_contents: '%B',
      message_subject: '%s',
      message_body: '%b',
      message_trailers: '%(trailers:only,unfold=true)'
    }
    git-log-core $parser ...$revision_range --author $author --count $count --skip $skip --grep $grep --files $files --reverse=$reverse
    | each {|it|
      {
        hash: $it.hash,
        parents: ($it.parents | split row ' '),
        refs: ($it.refs | str trim | if ($in | is-empty) { null } else { split row ', ' } ),
        author: {
          name: $it.author_name,
          email: $it.author_email,
          date: ($it.author_date | into datetime)
        },
        committer: {
          name: $it.committer_name,
          email: $it.committer_email,
          date: ($it.committer_date | into datetime)
        },
        message: {
          contents: ($it.message_contents | str trim)
          subject: ($it.message_subject | str trim)
          body: ($it.message_body | str trim)
          trailers: ($it.message_trailers | str trim)
        }
      }
    }
  } else {
    let parser = {
      hash: '%h',
      author_name: '%aN',
      author_email: '%aE',
      author_date: '%ad',
      message_contents: '%B',
    }
    git-log-core $parser ...$revision_range --author $author --count $count --skip $skip --grep $grep --files $files --reverse=$reverse
    | each {|it|
      {
        hash: $it.hash,
        name: $it.author_name
        email: $it.author_email
        date: ($it.author_date | into datetime)
        message: ($it.message_contents | str trim)
      }
    }
  }
}
