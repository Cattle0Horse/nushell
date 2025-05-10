# todo: 处理响应失败的情况
# todo: 自动获取 cookie 功能
# todo: 缓存（BVID作为键）
# todo: 当 cookie 失效时告知用户
# todo: logic split
# https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/docs/login/cookie_refresh.md
# https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/docs/login/login_action/QR.md

const DATA_DIR = ($nu.data-dir | path join data bilibili)

const HEADERS: record = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0',
  'Accept': 'application/json, text/plain, */*',
  'Accept-Language': 'en-US,en;q=0.5',
  # 'Accept-Encoding': 'gzip, deflate, br',
  # 'Referer': 'https://www.bilibili.com/video/{bvid}/?p=1',
  'Origin': 'https://www.bilibili.com',
  'Connection': 'keep-alive',
  'Sec-Fetch-Dest': 'empty',
  'Sec-Fetch-Mode': 'cors',
  'Sec-Fetch-Site': 'same-site',
}

const BILIBILI_COOKIE_PATH = ($DATA_DIR | path join cookie)

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

# 获取视频信息 (web接口)
def get-video-info-by-web [bvid: string, cookie: string] : [nothing -> record] {
  let api_url = $"https://api.bilibili.com/x/web-interface/view?bvid=($bvid)"
  http get -H (gen-headers $bvid $cookie) $api_url | get data
}

# 获取字幕列表
def get-subtitle-list [bvid: string, aid: int, cid: int, cookie: string] {
  let api_url = $"https://api.bilibili.com/x/player/wbi/v2?aid=($aid)&cid=($cid)"
  (http get -H (gen-headers $bvid $cookie) $api_url).data.subtitle.subtitles
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

def gen-headers [bvid: string, cookie: string] : [nothing -> list<string>] {
  return [
    'Cookie' $cookie
    'User-Agent' 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0'
    'Accept' 'application/json, text/plain, */*'
    'Accept-Language' 'en-US,en;q=0.5'
    # 'Accept-Encoding': 'gzip, deflate, br',
    'Referer' $"https://www.bilibili.com/video/($bvid)/?p=1"
    'Origin' 'https://www.bilibili.com'
    'Connection' 'keep-alive'
    'Sec-Fetch-Dest' 'empty'
    'Sec-Fetch-Mode' 'cors'
    'Sec-Fetch-Site' 'same-site'
  ]
}

# 将浮点时间转化为srt格式的时间字符串，比如 0:00:19.319
def float-to-srt [] : [float -> string] {
  let hours: int = $in // 3600
  let minutes: int = ($in - ($hours * 3600)) // 60
  let seconds: int = $in - ($hours * 3600) - ($minutes * 60)
  let milliseconds: int  = ($in * 1000 | into int) - 1000 * (($hours * 3600) * 1000 + ($minutes * 60) + $seconds)

  return $"($hours):($minutes | fill -a l -c 0 --width 2):($seconds | fill -a l -c 0 --width 2).($milliseconds | fill -a l -c 0 --width 3)"
}
