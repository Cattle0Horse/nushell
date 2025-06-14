use internal.nu *

def "nu-complete obsidian-projects" [] : nothing -> list<string> {
  ls --short-names $env.OBSIDIAN_ROOT | get name
}

# 备份 Obsidian 项目，不压缩，仅加密
export def "backup obsidian" [
  project: string@"nu-complete obsidian-projects"
  --password(-p): string
  --output(-o): path
] {
  mut args = [
    "-t7z" # 使用 7z 格式
    "-mhe=on" # 加密文件名
    "-mx0" # 不压缩
    "-p" # 下一个是密码，若未传输，则等待用户输入
  ]
  if ($password | is-not-empty) { $args = $args | append  $password }

  let input_file = ($env.OBSIDIAN_ROOT | path join $project)
  let output_file_name = $"obsidian-($project)-(current-date).7z"
  let output_file_name = if ($output | is-not-empty) {
    $output | path join $output_file_name
  } else {
    $output_file_name
  }

  ^7z a $output_file_name $input_file ...$args
}
