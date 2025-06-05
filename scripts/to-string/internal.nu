
# 提供变量转化为nushell可定义的字符串的方法

# table 转换为 string
export def "table-to-string" [
  --indent(-i) : int # 缩进，如果不设置则压缩为一行
] : table -> string {
  let headers = $in | columns
  let headers_str = ("[" + ($headers | str join ", ") + "]")
  let rows: list<string> = ($in | each {|record|
    "[" + ($headers | each { |header| $record | get $header } | str join ", ") + "]"
  })

  if ($indent | is-empty) {
    if ($rows | is-empty) {
      $'[($headers_str);]'
    } else {
      $'[($headers_str); ($rows | str join ", ")]'
    }
  } else {
    if ($rows | is-empty) {
      $'[(char newline)($headers_str);(char newline)]'
    } else {
      use std repeat
      let indent_str = ((char newline) + ((char space) | repeat $indent | str join))
      let data_str = ($rows | str join ("," + ($indent_str)))
      $'[($indent_str)($headers_str);($indent_str)($data_str)(char newline)]'
    }
  }
}

# record 转换为 string
export def "record-to-string" [
  --indent(-i) : int # 缩进，如果不设置则压缩为一行
] : record -> string {
  let rows: list<string> = ($in | transpose key value | each {|it|
    $'"($it.key)": ($it.value)'
  })

  if ($indent | is-empty) {
    if ($rows | is-empty) {
      '{}'
    } else {
      $'{($rows | str join ", ")}'
    }
  } else {
    if ($rows | is-empty) {
      $'{(char newline)}'
    } else {
      use std/util repeat
      let indent_str = ((char newline) + ((char space) | repeat $indent | str join))
      let data_str = ($rows | str join ($indent_str))
      $'{($indent_str)($data_str)(char newline)}'
    }
  }
}
