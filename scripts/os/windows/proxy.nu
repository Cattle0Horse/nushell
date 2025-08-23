export-env {
  if ($env.PROXY? | is-empty) {
    $env.PROXY = 'http://localhost:7890'
  }
}

export def --env toggle-proxy [proxy?:string] {
  let has_set = ($env.https_proxy? | is-not-empty)
  let no_val = ($proxy | is-empty)
  let proxy = if $has_set and $no_val {
    print 'hide proxy'
    null
  } else {
    let p = if ($proxy | is-empty) { $env.PROXY } else { $proxy }
    print $'set proxy ($p)'
    $p
  }
  $env.http_proxy = $proxy
  $env.https_proxy = $proxy
}
