
# 对文件进行操作，读取后保存
@example "Basic usage: convert file content to uppercase" { str file input.txt {|it| $it | str upcase} }
@example "With output parameter: process and save to new location" { str file input.txt {|it| $it | lines | reverse | str join "\n"} -o output.txt }
@example "With force parameter: overwrite output file" { str file input.txt {|it| $it | str trim} -o "result.txt" -f }
@example "Complex operation: count words in file" { str file input.txt { split words | length | $"The file contains ($in) words" } }
export def "str file" [
  file_path: path # 文件路径
  action: closure # 操作函数（应当返回string）
  --output(-o): path # 输出文件路径（若无则覆盖原文件）
  --force(-f) # 若文件存在则覆盖（当使用output参数时有效）
] : nothing -> nothing {
  let force = if ($output | is-not-empty) { $force } else { true }
  let output = if ($output | is-not-empty) { $output } else { $file_path }

  open $file_path --raw
  | do $action
  | save --force=$force $output
}
