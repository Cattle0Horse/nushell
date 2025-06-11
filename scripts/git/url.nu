use internal.nu *

export-env {
  if ('GIT_URL_PARSE_PATTERNS' not-in $env) {
    # 默认提供一些简单解析方式
    $env.GIT_URL_PARSE_PATTERNS = [
      {
        name: "github-https"
        pattern: '(?:https://github\.com/)([^/]+)/([^/]+?)(?:\.git|/.*)?$'
      }
      {
        name: "github-ssh"
        pattern: '(?:git@github\.com:)([^/]+)/([^/]+?)(?:\.git)?$'
      }
      {
        name: "short"
        pattern: '^([^/]+)/([^/]+?)(?:\.git)?$'
      }
    ]
  }
}

# 解析url中的git仓库
@example "Parse a GitHub URL with blob path" { "https://github.com/nushell/nushell/blob/main/crates/nu-std/std/iter/mod.nu" | git url parse } --result { owner: "nushell", repo: "nushell", source: "github-https" }
@example "Parse a GitHub URL with .git extension" { "https://github.com/nushell/nushell.git" | git url parse } --result { owner: "nushell", repo: "nushell", source: "github-https" }
@example "Parse a GitHub URL with SSH format" { "git@github.com:nushell/nushell.git" | git url parse } --result { owner: "nushell", repo: "nushell", source: "github-ssh" }
@example "Parse a GitHub URL without protocol" { "nushell/nushell" | git url parse } --result { owner: "nushell", repo: "nushell", source: "short" }
@example "Invalid URL" { "invalid-url" | git url parse } --result null
export def "git url parse" [] : [
  string -> record<owner: string, repo: string, source: string>
  string -> nothing
] {
  # Try each pattern until we find a match
  let s: string = $in
  use std/iter
  let regex = $env.GIT_URL_PARSE_PATTERNS | iter find {|p| $s =~ $p.pattern }

  if ($regex | is-empty) {
    return null
  }

  let parse_capture = $s | parse --regex $regex.pattern

  return {
    owner: ($parse_capture | get capture0.0)
    repo: ($parse_capture | get capture1.0)
    source: $regex.name
  }
}

# 获取追踪的远程仓库的 URL
@example "Get remote URL" { git url remote } --result "https://github.com/nushell/nushell"
export def "git url remote" [
  repo: string@git-remotes = "origin"
] : nothing -> string {
  # 获取远程 URL
  let result = do {^git remote get-url $repo} | complete
  if $result.exit_code != 0 {
    print $"(ansi red)($result.stderr)(ansi reset)"
    return
  }

  let remote_url = $result.stdout | str trim

  if ($remote_url =~ "https://") {
    $remote_url | str replace -r '\.git$' ''
  } else if ($remote_url =~ "git@") {
    ('https://' + ($remote_url | str substring ('git@' | str length).. | str replace ':' '/' | str replace -r '\.git$' ''))
  } else {
    "Unsupported URL type"
  }
}
