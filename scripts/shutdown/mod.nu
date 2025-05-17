# todo: implement me

const DATA_FOLDER = ($nu.data-dir | path join data shutdown)

def agree [
  prompt: string
  --default-not (-n)
] {
  let prompt = if ($prompt | str ends-with '!') {
    $'(ansi red)($prompt)(ansi reset)'
  } else {
    $'($prompt)'
  }
  (if $default_not { [no yes] } else { [yes no] } | input list $prompt) == 'yes'
}

export-env {
  # 关机日志文件
  $env.SHUTDOWN_LOG = ($DATA_FOLDER | path join "shutdown.log")
}

# 立即关机
export def "shutdown now" [] {
  # 记录日志
  let entry = $"[{(date now)}] Immediate shutdown"
  $entry | save --append $env.SHUTDOWN_LOG

  # 强制立即关机
  ^shutdown /s /f /t 0
}

# 3. 定义取消关机
export def "shutdown cancel" [] {
  # 记录日志
  let entry = $"[{(date now)}] Cancel shutdown"
  $entry | save --append $env.SHUTDOWN_LOG

  # 发送取消信号
  ^shutdown /a
}

# 4. 定义计划任务列表查询
export def "shutdown task-list" [] {
  # 列出所有名称以 “ShutdownAtTime” 开头的计划任务
  ^schtasks /query /fo LIST /v | where Name =~ "ShutdownAtTime"
}

# 5. 定义删除指定任务
export def "shutdown task-remove" [
  task_name: string
] {
  # 记录日志
  let entry = $"[{(date now)}] Remove task: ($task_name)"
  $entry | save --append $env.SHUTDOWN_LOG

  # 强制删除任务
  ^schtasks /Delete /TN $task_name /F
}

# 6. 定义查看关机历史
export def "shutdown history" [] {
  # 打印日志文件内容
  open $env.SHUTDOWN_LOG | lines
}

# 延迟时间关机
export def "shutdown after" [
  --time: int = 30
  --restart
  --cancel
  --force
  --reason: string = "无特殊原因"
] {
  # 记录关机原因到日志
  if not $cancel {
    let log_entry = $"时间: (date now) - 原因: ($reason) - 延迟: ($time) 秒"
    $log_entry | save --append shutdown_log.txt
  }

  # 取消关机
  if $cancel {
    print "已取消关机操作..."
    ^shutdown /a
    return
  }

  # 强制关机
  if $force {
    print "强制关机中..."
    ^shutdown /s /f /t 0
    return
  }

  # 提示用户确认
  if not (agree -n $"你将会在 ($time) 秒后关机，原因: ($reason)，是否确认!") {
    print "已取消关机操作。"
    return
  }

  # 执行关机或重启
  if $restart {
    print $"系统将在 ($time) 秒后重启。"
    ^shutdown /r /t $time
  } else {
    print $"系统将在 ($time) 秒后关机，原因: ($reason)。"
    ^shutdown /s /t $time
  }
}

# 指定时间关机
export def "shutdown at" [
  time: string,  # 格式为 HH:MM，例如 "23:30"
  --daily,     # 是否每天执行
  --once     # 是否仅执行一次
  --task_name:string = "ShutdownAtTime"
] {
  let shutdown_cmd = "shutdown /s /f /t 0"

  # 构建 schtasks 命令参数
  let schedule = if $daily {
    "DAILY"
  } else if $once {
    "ONCE"
  } else {
    "ONCE"
  }

  # 创建计划任务
  ^schtasks /Create /TN $task_name /TR $shutdown_cmd /SC $schedule /ST $time /F

  print $"已创建计划任务 ($task_name)，将在 ($time) 执行关机操作。"
}
