
#获取仓库位置（远程仓库或本地仓库）
export def --env "git path" [
  --local # 获取本地仓库位置
  --remote:string="origin" # 获取远程仓库位置
] : nothing -> string {
  if $local {
    return (^git rev-parse --show-toplevel)
  }

  # 获取远程 URL
  let result = do {^git remote get-url $remote} | complete
  if $result.exit_code != 0 {
    print $"(ansi red)($result.stderr)(ansi reset)"
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
