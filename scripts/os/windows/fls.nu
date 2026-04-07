# File Locksmith (PowerToys) 的 Nushell 包装命令。
# - `fls who` / `fls files`: 使用 `--json` 查询占用信息
# - `fls wait`: 阻塞等待文件释放
# - `fls kill`: 终止占用目标路径的进程
# 参考文档: https://learn.microsoft.com/zh-cn/windows/powertoys/file-locksmith

export-env {
  if 'FILELOCKSMITHCLI_PATH' not-in $env {
    $env.FILELOCKSMITHCLI_PATH = 'FileLocksmithCLI.exe'
  }
}

# 按进程聚合展示占用信息
export def "fls who" [
  ...paths: path # 要检查的文件或目录（支持多个）
] : nothing -> list<record<pid: int, name: string, user: string, files: list<string>>> {
  let out = (do { ^$env.FILELOCKSMITHCLI_PATH --json ...$paths } | complete)
  if $out.exit_code != 0 {
    let err = ($out.stderr | default "" | str trim)
    let msg = if ($err | is-empty) { $out.stdout | default "" | str trim } else { $err }
    error make { msg: (if ($msg | is-empty) { $"fls: filelocksmithcli 失败，exit_code=($out.exit_code)" } else { $msg }) }
  }

  ($out.stdout | from json).processes
}

# 按文件聚合占用信息
export def "fls files" [
  ...paths: path # 要检查的文件或目录（支持多个）
] : nothing -> table<file: string, holders: list<record<pid: int, name: string, user: string>>> {
  fls who ...$paths
  | each {|p|
      ($p.files | default [] | each {|f| { file: $f, pid: $p.pid, name: $p.name, user: $p.user } })
    }
  | flatten
  | group-by file
  | transpose file rows
  | each {|r| { file: $r.file, holders: ($r.rows | select pid name user | uniq-by pid) } }
}

# 等待解锁
export def "fls wait" [
  ...paths: path # 要检查的文件或目录（支持多个）
  --timeout: int # 等待超时毫秒数
] : nothing -> string {
  mut args = ['--wait']
  if ($timeout | is-not-empty) { $args ++= ['--timeout', $timeout] }
  ^$env.FILELOCKSMITHCLI_PATH ...$args ...$paths
}

# 结束占用进程以解锁文件
export def "fls kill" [
  ...paths: path # 要解锁的文件或目录（支持多个）
] : nothing -> string {
  ^$env.FILELOCKSMITHCLI_PATH --kill ...$paths
}

