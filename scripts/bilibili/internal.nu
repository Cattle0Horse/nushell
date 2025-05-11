export const DATA_DIR = ($nu.data-dir | path join data bilibili)

export const HEADERS: record = {
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

export const BILIBILI_COOKIE_PATH = ($DATA_DIR | path join cookie)

# 获取视频信息 (web接口)
export def get-video-info-by-web [bvid: string, cookie: string] : [nothing -> record] {
  let api_url = $"https://api.bilibili.com/x/web-interface/view?bvid=($bvid)"
  http get -H (gen-headers $bvid $cookie) $api_url | get data
}

# 获取字幕列表
export def get-subtitle-list [bvid: string, aid: int, cid: int, cookie: string] {
  let api_url = $"https://api.bilibili.com/x/player/wbi/v2?aid=($aid)&cid=($cid)"
  (http get -H (gen-headers $bvid $cookie) $api_url).data.subtitle.subtitles
}

export def gen-headers [bvid: string, cookie: string] : [nothing -> list<string>] {
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
export def float-to-srt [] : [float -> string] {
  let hours: int = $in // 3600
  let minutes: int = ($in - ($hours * 3600)) // 60
  let seconds: int = $in - ($hours * 3600) - ($minutes * 60)
  let milliseconds: int  = ($in * 1000 | into int) - 1000 * (($hours * 3600) * 1000 + ($minutes * 60) + $seconds)

  return $"($hours):($minutes | fill -a l -c 0 --width 2):($seconds | fill -a l -c 0 --width 2).($milliseconds | fill -a l -c 0 --width 3)"
}
