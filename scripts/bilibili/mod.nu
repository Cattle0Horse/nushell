# todo: 处理响应失败的情况
# todo: 自动获取 cookie 功能
# todo: 缓存（BVID作为键）
# todo: 当 cookie 失效时告知用户
# todo: logic split
# https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/docs/login/cookie_refresh.md
# https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/docs/login/login_action/QR.md

use internal.nu *

export-env {
  if ($BILIBILI_COOKIE_PATH | path exists) {
    $env.BILIBILI_COOKIE = open $BILIBILI_COOKIE_PATH --raw | str trim
  }
}

# 从环境指定的文件中读取 cookie
export def get-cookie [] : [nothing -> string] {
  # todo: 自动获取 cookie
  $env.BILIBILI_COOKIE
}

# 保存 cookie 到环境变量指定的文件中
export def save-cookie [] : [string -> nothing] {
  $in | save -f $BILIBILI_COOKIE_PATH
}

# 获取字幕（默认为纯文本，便于ai合成）
export def subtitle [
  bvid?: string
  --cookie: string
  --srt # 转化为srt字幕
  --json # 返回json格式
] : [
  nothing -> string
  string -> string
] {
  let bvid: string = if $in != null { $in } else if $bvid != null { $bvid } else { print $"(ansi red)缺少bvid(ansi reset)"; return }
  let bvid: string = $bvid | extract-bvid
  if ($bvid | is-empty) {
    print $"(ansi red)缺少bvid(ansi reset)"
    return
  }
  let cookie: string = if ($cookie | is-empty) { get-cookie }
  if ($cookie | is-empty) {
    print $"(ansi red)缺少cookie(ansi reset)"
    return
  }

  let cookie: string = $cookie | str trim

  let video_info = get-video-info-by-web $bvid $cookie
  let subtitles = get-subtitle-list $bvid $video_info.aid $video_info.cid $cookie

  if ($subtitles | is-empty) {
    print $"(ansi yellow)该视频没有可用字幕或cookie失效(ansi reset)"
    return
  }

  let selected = $subtitles | select subtitle_url lan_doc
  let index = if (($selected | length) > 1) {
    $selected | get lan_doc | input list --index "存在多条字幕，请选择一条"
  } else {
    0
  }
  let url = ($selected | get $index | get subtitle_url)

  let resp: string = (http get -H (gen-headers $bvid $cookie) $"https:($url)" --raw)

  if $json {
    return $resp
  }
  if $srt {
    return ($resp | convert-json-to-srt)
  }
  return ($resp | convert-json-to-text)
}

# 解析bvid
export def extract-bvid [] : [
  string -> string
  string -> nothing
] {
  $in | parse -r '(BV[\dA-Za-z]{10})' | get capture0.0?
}


# 解析字幕JSON转SRT格式
export def convert-json-to-srt [] : [string -> string] {
  $in | from json | get body | enumerate | reduce --fold '' {|it, acc|
    let start: string = $it.item.from | float-to-srt
    let stop: string = $it.item.to | float-to-srt

    let num: int = $it.index + 1
    let time_line: string = $"($start) --> ($stop)"
    let content: string = $it.item.content

    $acc + ([$num $time_line $content] | str join (char newline)) + (char newline) + (char newline)
  }
}

# 解析字幕JSON转纯文本字幕
export def convert-json-to-text [] : [string -> string] {
  $in | from json | get body | get content | str join (char newline)
}
