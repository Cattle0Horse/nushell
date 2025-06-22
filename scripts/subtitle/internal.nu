
# 将srt格式按块分隔
def split-srt [] : string -> list<string> {
  split row --regex '(\r\n|\n){2}'
  | each { str trim }
  | where { is-not-empty }
}

# 00:00:02,560 -> 2.56
def srt-time-to-seconds [] : string -> float {
  str replace ',' '.'
  | parse '{h}:{m}:{s}'
  | first
  | do {
    ($in.h | into int) * 3600 + ($in.m | into int) * 60 + ($in.s | into float) | into string --decimals 3 | into float
  }
}

# 2.56 -> 00:00:02,560
def seconds-to-srt-time [] : [float -> string] {
  let hours: int = ($in // 3600) | into int
  let minutes: int = ($in - ($hours * 3600)) // 60 | into int
  let seconds: int = $in - ($hours * 3600) - ($minutes * 60) | into int
  let milliseconds: int  = ($in * 1000 | into int) - 1000 * (($hours * 3600) * 1000 + ($minutes * 60) + $seconds)

  $"($hours):($minutes | fill -a l -c 0 --width 2):($seconds | fill -a l -c 0 --width 2),($milliseconds | fill -a l -c 0 --width 3)"
}


# 解析srt格式到nushell类型
export def parse-srt [] : string -> table<from: float, to: float, content: string> {
  split-srt
  | each {|block|
    let lines = $block | lines --skip-empty
    let times = $lines | get 1 | parse '{from} --> {to}' | first
    let content = $lines | skip 2 | str join (char newline)

    {
      from: ($times.from | srt-time-to-seconds)
      to: ($times.to | srt-time-to-seconds)
      content: $content
    }
  }
}

export def srt-to-json [
  --indent(-i): int = 2
] : string -> string {
  parse-srt | to json --indent=$indent
}

export def json-to-srt [] : string -> string {
  from json | enumerate | reduce --fold '' {|it, acc|
    $acc + ([
        ($it.index + 1)
        $"($it.item.from | seconds-to-srt-time) --> ($it.item.to | seconds-to-srt-time)"
        $it.item.content
      ]
      | str join (char newline)
    ) + (char newline) + (char newline)
  }
}

export def srt-to-txt [] : string -> string {
  parse-srt | get content | str join (char newline)
}

export def json-to-txt [] : string -> string {
  from json | get content | str join (char newline)
}
