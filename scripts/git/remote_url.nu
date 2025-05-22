# git/remote_url.nu
# 获取远程仓库的 URL
export def "git remote-url" [] : nothing -> string {
  # 获取远程 URL
  let result = do {git remote get-url origin} | complete
  if $result.exit_code != 0 {
    print $"(ansi red) ($result.stderr) (ansi reset)"
    return
  }

  let remote_url = $result.stdout | str trim

  # 判断 URL 类型
  let url_type = if $remote_url =~ "https://" { "https" } else if $remote_url =~ "git@" { "ssh" } else { "unknown" }

  # 转换为 HTTP 格式
  let http_url = if $url_type == "https" {
    $remote_url | str replace -r '\.git$' ''
  } else if $url_type == "ssh" {
    ('https://' + ($remote_url | str substring ('git@' | str length).. | str replace ':' '/' | str replace -r '\.git$' ''))
  } else {
    "Unsupported URL type"
  }

  $http_url
}
