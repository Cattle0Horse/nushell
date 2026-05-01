export-env {
  if ('KB_HOME' not-in $env) {
    $env.KB_HOME = ($nu.home-dir | path join '.kb')
  }
}

# 将字符串处理成可用作路径片段的 slug
def sanitize [] : string -> string {
  $in
  | str trim
  | str replace --all --regex '[/\\:*?"<>|]' '-'
  | str replace --all --regex '\s+' ' '
  | str trim
}

# 从 URL 推导一个兜底文件名（无扩展名）
def url-slug [url: string]: nothing -> string {
  let path = ($url | url parse | get path | str trim --char '/')
  let tail = if ($path | is-empty) {
    ''
  } else {
    $path | path basename | split row '.' | first | default ''
  }
  if ($tail | is-not-empty) {
    $tail | sanitize
  } else {
    $url | hash sha256 | str substring 0..7
  }
}

# 从 URL 抓取并保存 markdown 到 $env.KB_HOME/<domain>/<author>/<title>.md
@example "保存一篇文章到知识库" { kb url "https://example.com/post" }
@example "已存在时覆盖" { kb url "https://example.com/post" --force }
export def "kb url" [
  url: string # 目标文章 URL
  --force(-f) # 若目标文件存在则覆盖
] : nothing -> path {
  let result = (^mdtk read --json $url | from json)

  let domain = ($result.source.domain? | default '' | sanitize)
  if ($domain | is-empty) {
    error make { msg: $"mdtk 返回的 source.domain 为空：($url)" }
  }

  let author_raw = ($result.article.author? | default '' | sanitize)
  let author = if ($author_raw | is-empty) { '_unknown' } else { $author_raw }

  let title_raw = ($result.article.title? | default '' | sanitize)
  let title = if ($title_raw | is-not-empty) { $title_raw } else { url-slug $url }

  let dir = ($env.KB_HOME | path join $domain $author)
  let file = ($dir | path join $"($title).md")

  if (($file | path exists) and (not $force)) {
    error make { msg: $"文件已存在：($file)。使用 --force 覆盖。" }
  }

  mkdir $dir
  $result.markdown | save --force $file
  print $"已保存：($file)"
  $file
}
