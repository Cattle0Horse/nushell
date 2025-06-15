# 字符串环绕功能，支持匹配符号对和直接环绕

const SYMBOL_LR = {
  '(': ')'
  '[': ']'
  '{': '}'
  '<': '>'
}
const SYMBOL_RL = {
  ')': '('
  ']': '['
  '}': '{'
  '>': '<'
}
const SYMBOL_LEFT = ['(' '[' '{' '<' ]
const SYMBOL_RIGHT = [')' ']' '}' '>']

# 环绕字符串
export def "str surround" [
  symbols: string # 支持 ( [ { < ) ] } > 进行匹配，若无匹配则直接环绕
  --match(-m) # 必须匹配符号
  --no-match(-M) # 不要匹配符号
  --count(-n): int=1 # 重复次数
] : string -> string {
  if $no_match and $match {
    print $"(ansi red)无法匹配符号(ansi reset)"
    return null
  }
  if $count < 1 {
    print $"(ansi red)重复次数必须大于0(ansi reset)"
    return null
  }

  let s = if $no_match {
    { left: $symbols, right: $symbols }
  } else if $symbols in $SYMBOL_LEFT {
    { left: $symbols, right: ($SYMBOL_LR | get $symbols) }
  } else if $symbols in $SYMBOL_RIGHT {
    { left: ($SYMBOL_RL | get $symbols), right: $symbols }
  } else if $match {
    print $"(ansi red)无法匹配符号(ansi reset)"
    return null
  } else {
    { left: $symbols, right: $symbols }
  }

  $in | if $count != 1 {
    use std repeat
    $"($s.left | repeat $count | str join)($in)($s.right | repeat $count | str join)"
  } else {
    $"($s.left)($in)($s.right)"
  }
}
