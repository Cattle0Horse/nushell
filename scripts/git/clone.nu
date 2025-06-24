use url.nu *

export-env {
  if 'GIT_CLONE_PROTOCOL' not-in $env {
    $env.GIT_CLONE_PROTOCOL = 'ssh' # ssh or https
  }
}

# 克隆仓库，无参数则使用 $env.GIT_CLONE_PROTOCOL 协议
export def git-clone [
  url: string # 仓库地址
  --domain(-d): string # 仓库域名，如github.com，如果不提供则从url中解析，若url中无法解析，则报错
  --ssh(-s)   # 强制使用ssh协议
  --https(-t) # 强制使用https协议
  --auto(-a) # 自动推断协议，若无法推断协议则使用默认设置
] : nothing -> nothing {
  let url_obj = $url | git-url-parse
  if ($url_obj | is-empty) {
    print $'(ansi red)Invalid URL: ($url)(ansi reset)'
    return
  }
  let domain = if ($domain | is-empty) {
    if ($url_obj.parser.domain | is-empty) {
      print $'(ansi red)Cannot parse domain from URL: ($url)(ansi reset)'
      return
    }
    $url_obj.parser.domain
  } else {
    $domain
  }

  let protocol = if $auto {
    $url_obj.parser.protocol | default $env.GIT_CLONE_PROTOCOL
  } else if $https {
    'https'
  } else if $ssh {
    'ssh'
  } else {
    $env.GIT_CLONE_PROTOCOL
  }

  let clone_url = if $protocol == 'ssh' {
    $"git@($domain):($url_obj.owner)/($url_obj.repo).git"
  } else {
    $"https://($domain)/($url_obj.owner)/($url_obj.repo).git"
  }

  ^git clone $clone_url
}
