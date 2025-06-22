def git-show-core [
  parser: record # 解析对象，格式为{key: value}，key为nushell变量名，value为git标识名
  ...objects: string # 要显示的对象名称（默认为HEAD）或范围（如：HEAD~5..HEAD）
  --date: string='iso' # 日期格式，默认为iso
] {
  let pt = $parser | transpose key value
  let sep1 = "\u{1f}" # 使用ASCII unit separator，极低概率出现在git内容中（一个ref的内容分隔符）
  let sep2 = "\u{1e}" # 使用ASCII record separator，极低概率出现在git内容中（多个refs的分隔符）

  let args = [
    '--no-color'
    '--no-patch'
    '--no-notes'
    $'--date=($date)'
    $'--pretty=format:(($pt | get value | str join $sep1) + $sep2)'
  ]

  ^git show ...$args ...$objects
  | split row $sep2
  | str trim
  | compact --empty
  | parse ($pt | get key | each {|it| "{" + $it + "}" } | str join $sep1)
}

# 查询指定提交的详细信息
export def git-show [
  ...objects: string # 要显示的对象名称（默认为HEAD）或范围（如：HEAD~5..HEAD）
  --long(-l) # 显示详细信息
] {
  if $long {
    let parser = {
      refs: '%D',
      hash: '%H',
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
    git-show-core $parser ...$objects
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
    git-show-core $parser ...$objects
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
  | if ($in | length) == 1 {
    first
  } else {
    $in
  }
}
