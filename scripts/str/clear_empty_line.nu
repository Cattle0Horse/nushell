# 去除环绕部分的空白行（如markdown中的代码块）
export def "str clear-empty-line" [
  start?:string # 开始标记，如 "```go"
  end?:string # 结束标记，如 "```"
  --regex # 使用正则匹配
  --trim-right(-t) # 是否去除右侧空白
  --all(-a) # 去除全部空行（将会忽略start和end参数）
] : string -> string {
  $in
  | lines
  | if $trim_right {
    $in | str trim --right
  } else {
    $in
  }
  | if $all {
    $in | where { is-not-empty }
  } else {
    $in
    | reduce -f { inside: false, buffer: [] } {|line, acc|
      if $regex {
        if $line =~ $start {
          { inside: true, buffer: ($acc.buffer | append $line) }
        } else if $line =~ $end or not $acc.inside {
          { inside: false, buffer: ($acc.buffer | append $line) }
        } else if ($line | is-not-empty) {
          { inside: $acc.inside, buffer: ($acc.buffer | append $line) }
        } else { # 处理空行
          { inside: true, buffer: $acc.buffer }
        }
      } else {
        if $line == $start {
          { inside: true, buffer: ($acc.buffer | append $line) }
        } else if $line == $end or not $acc.inside {
          { inside: false, buffer: ($acc.buffer | append $line) }
        } else if ($line | is-not-empty) {
          { inside: $acc.inside, buffer: ($acc.buffer | append $line) }
        } else { # 处理空行
          { inside: true, buffer: $acc.buffer }
        }
      }
    }
    | get buffer
  }
  | str join (char nl)
}
