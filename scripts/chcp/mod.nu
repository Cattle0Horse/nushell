# const IDENTIFIER_PATH = ($nu.data-dir | path self | path dirname | path join identifier.json)

# export-env {
#   $env.CHCP_DICT = ($IDENTIFIER_PATH | open | reduce --fold {} { |it acc| $acc | merge { $it.identifier: $it.CodePage } })
#   $env.CHCP_IDENTIFIER = $env.CHCP_DICT | columns
# }

# def "nu-complete identifiers" [] : nothing -> string {
#     $env.CHCP_IDENTIFIER
# }

use internal.nu *

def "nu-complete identifiers" [] : nothing -> list<string> {
  $CHCP_IDENTIFIER
}

# 改变当前终端字符集
export def main [
  identifier?: string@"nu-complete identifiers"
] : nothing -> nothing {
  if $identifier != null {
    ^chcp ($CHCP_DICT | get $identifier)
  } else {
    ^chcp
  }
}
