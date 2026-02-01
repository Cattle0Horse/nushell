# Rime 词库管理模块
# 提供词库的 git 仓库管理和更新功能

use const.nu *
use utils.nu *
use weasel.nu *

# 获取词库更新时间记录键
def get-schema-update-time-key [repo_name: string] {
  return $"($repo_name)_schema_update_time"
}

# 验证 git 仓库状态
def validate-git-repo [repo_path: string] {
  if not ($repo_path | path exists) {
    print $"(ansi red)错误：词库目录不存在: ($repo_path)(ansi reset)"
    return false
  }

  let git_dir = ($repo_path | path join ".git")
  if not ($git_dir | path exists) {
    print $"(ansi red)错误：目录不是 git 仓库: ($repo_path)(ansi reset)"
    return false
  }

  return true
}

# 获取 git 仓库远程信息
def get-git-remote-info [repo_path: string] {
  try {
    let result = (git -C $repo_path remote -v | complete)
    if $result.exit_code == 0 {
      let lines = ($result.stdout | lines)
      let origin_line = ($lines | where {|line| $line | str contains "origin"} | first)
      if ($origin_line | is-not-empty) {
        # 解析 git remote 输出: "origin  https://github.com/user/repo.git (fetch)"
        let parts = ($origin_line | str trim | split row " ")
        if ($parts | length) >= 2 {
          return ($parts | get 1)
        }
      }
    }
    return null
  } catch {
    return null
  }
}

# 获取 git 仓库最新提交信息
def get-git-latest-commit [repo_path: string] {
  try {
    let result = (^git -C $repo_path log -1 --format="%H|%ci|%s" | complete)
    if $result.exit_code == 0 {
      let commit_info = ($result.stdout | str trim | split row "|")
      if ($commit_info | length) >= 3 {
        return {
          hash: ($commit_info | get 0)
          date: ($commit_info | get 1 | into datetime)
          message: ($commit_info | get 2)
        }
      }
    }
    return null
  } catch {
    return null
  }
}

# 检查 git 仓库是否有更新
def check-git-updates [repo_path: string] {
  try {
    # 先获取远程更新
    let fetch_result = (^git -C $repo_path fetch | complete)
    if $fetch_result.exit_code != 0 {
      print $"(ansi yellow)警告：获取远程更新失败: ($repo_path)(ansi reset)"
      return false
    }

    # 获取当前分支
    let current_branch_result = (^git -C $repo_path branch --show-current | complete)
    if $current_branch_result.exit_code != 0 {
      print $"(ansi yellow)警告：获取当前分支失败: ($repo_path)(ansi reset)"
      return false
    }
    let current_branch = ($current_branch_result.stdout | str trim)

    # 检查本地分支和远程分支的差异
    let diff_result = (^git -C $repo_path log ..origin/($current_branch) --oneline | complete)
    if $diff_result.exit_code == 0 {
      # 如果有输出，说明远程有新的提交
      let has_updates = not ($diff_result.stdout | str trim | is-empty)
      return $has_updates
    }
    return false
  } catch {
    print $"(ansi yellow)警告：检查远程更新失败: ($repo_path)(ansi reset)"
    return false
  }
}

# 执行 git pull 更新
def perform-git-pull [repo_path: string] {
  try {
    print $"(ansi cyan)正在从远程仓库拉取更新...(ansi reset)"
    
    # 先获取当前分支
    let current_branch_result = (^git -C $repo_path branch --show-current | complete)
    if $current_branch_result.exit_code != 0 {
      print $"(ansi red)错误：获取当前分支失败(ansi reset)"
      return false
    }
    let current_branch = ($current_branch_result.stdout | str trim)
    
    # 检查是否有未提交的更改
    let status_result = (^git -C $repo_path status --porcelain | complete)
    if $status_result.exit_code == 0 and not ($status_result.stdout | str trim | is-empty) {
      print $"(ansi yellow)警告：存在未提交的更改，将先暂存这些更改(ansi reset)"
      let stash_result = (^git -C $repo_path stash | complete)
      if $stash_result.exit_code != 0 {
        print $"(ansi red)错误：暂存更改失败(ansi reset)"
        return false
      }
    }
    
    # 执行 pull
    let result = (^git -C $repo_path pull origin $current_branch | complete)
    if $result.exit_code == 0 {
      print $"(ansi green)✓ Git pull 成功(ansi reset)"
      if not ($result.stdout | str trim | is-empty) {
        print $"更新详情: ($result.stdout)"
      }
      
      # 如果之前暂存了更改，现在恢复
      if $status_result.exit_code == 0 and not ($status_result.stdout | str trim | is-empty) {
        print $"(ansi cyan)正在恢复暂存的更改...(ansi reset)"
        let pop_result = (^git -C $repo_path stash pop | complete)
        if $pop_result.exit_code != 0 {
          print $"(ansi yellow)警告：恢复暂存更改失败，请手动处理(ansi reset)"
        }
      }
      
      return true
    } else {
      print $"(ansi red)✗ Git pull 失败(ansi reset)"
      if not ($result.stderr | str trim | is-empty) {
        print $"错误信息: ($result.stderr)"
      }
      
      # 如果之前暂存了更改但 pull 失败，尝试恢复
      if $status_result.exit_code == 0 and not ($status_result.stdout | str trim | is-empty) {
        print $"(ansi cyan)正在恢复暂存的更改...(ansi reset)"
        let pop_result = (^git -C $repo_path stash pop | complete)
        if $pop_result.exit_code != 0 {
          print $"(ansi yellow)警告：恢复暂存更改失败，请手动处理(ansi reset)"
        }
      }
      
      return false
    }
  } catch { |err|
    print $"(ansi red)错误：执行 git pull 时发生异常: ($err.msg)(ansi reset)"
    return false
  }
}

# 检查词库状态
export def check-schema-status [
  --repo-path(-r): string  # 词库仓库路径（默认使用小狼毫用户目录）
  --repo-name(-n): string  # 仓库名称（用于记录时间）
] {
  print $"(ansi cyan)=== Rime 词库状态检查 ===(ansi reset)"

  # 确定词库路径
  let vocab_path = if ($repo_path | is-not-empty) {
    $repo_path
  } else {
    get-weasel-user-dir
  }

  if ($vocab_path | is-empty) {
    print $"(ansi red)错误：无法确定词库路径(ansi reset)"
    return false
  }

  print $"词库路径: ($vocab_path)"

  # 验证 git 仓库
  if not (validate-git-repo $vocab_path) {
    return false
  }

  # 获取远程信息
  let remote_url = (get-git-remote-info $vocab_path)
  if ($remote_url | is-not-empty) {
    print $"(ansi green)✓ 远程仓库: ($remote_url)(ansi reset)"
  } else {
    print $"(ansi yellow)⚠ 未找到远程仓库信息(ansi reset)"
  }

  # 获取本地最新提交
  let latest_commit = (get-git-latest-commit $vocab_path)
  if ($latest_commit | is-not-empty) {
    print $"(ansi green)✓ 本地最新提交(ansi reset)"
    print $"  提交哈希: ($latest_commit.hash)"
    print $"  提交时间: ($latest_commit.date)"
    print $"  提交信息: ($latest_commit.message)"
  } else {
    print $"(ansi red)✗ 无法获取本地提交信息(ansi reset)"
  }

  # 检查远程更新
  print $"(ansi cyan)正在检查远程更新...(ansi reset)"
  let has_updates = (check-git-updates $vocab_path)
  if $has_updates {
    print $"(ansi yellow)📥 发现远程更新(ansi reset)"
    
    # 显示具体的更新信息
    let current_branch_result = (^git -C $vocab_path branch --show-current | complete)
    if $current_branch_result.exit_code == 0 {
      let current_branch = ($current_branch_result.stdout | str trim)
      let log_result = (^git -C $vocab_path log ..origin/($current_branch) --oneline | complete)
      if $log_result.exit_code == 0 and not ($log_result.stdout | str trim | is-empty) {
        print $"(ansi cyan)待更新的提交:(ansi reset)"
        print ($log_result.stdout)
      }
    }
  } else {
    print $"(ansi green)✓ Schema 已是最新版本(ansi reset)"
  }

  # 检查时间记录
  let repo_name = if ($repo_name | is-not-empty) {
    $repo_name
  } else {
    # 从远程 URL 提取仓库名
    if ($remote_url | is-not-empty) {
      let url_parts = ($remote_url | split row "/")
      if ($url_parts | length) >= 1 {
        let repo_with_ext = ($url_parts | last)
        ($repo_with_ext | str replace ".git" "")
      } else {
        "unknown"
      }
    } else {
      "unknown"
    }
  }

  let update_time_key = (get-schema-update-time-key $repo_name)
  let local_time = (get-time-record $update_time_key)

  if ($local_time | is-not-empty) {
    print $"(ansi green)✓ 本地更新记录存在: ($local_time)(ansi reset)"
  } else {
    print $"(ansi yellow)⚠ 本地更新记录不存在(ansi reset)"
  }

  return true
}

# 更新词库
export def update-schema [
  --repo-path(-r): string  # 词库仓库路径（默认使用小狼毫用户目录）
  --repo-name(-n): string  # 仓库名称（用于记录时间）
  --force(-f)              # 强制更新，即使没有远程更新
] {
  print $"(ansi cyan)=== Rime 词库更新工具 ===(ansi reset)"

  # 验证小狼毫安装
  if not (verify-weasel-installation) {
    print $"(ansi red)错误：小狼毫安装验证失败，无法继续(ansi reset)"
    return false
  }

  # 确定词库路径
  let vocab_path = if ($repo_path | is-not-empty) {
    $repo_path
  } else {
    get-weasel-user-dir
  }

  if ($vocab_path | is-empty) {
    print $"(ansi red)错误：无法确定词库路径(ansi reset)"
    return false
  }

  print $"词库路径: ($vocab_path)"

  # 验证 git 仓库
  if not (validate-git-repo $vocab_path) {
    print $"(ansi red)错误：词库路径不是有效的 git 仓库(ansi reset)"
    return false
  }

  # 获取远程信息
  let remote_url = (get-git-remote-info $vocab_path)
  if ($remote_url | is-empty) {
    print $"(ansi red)错误：未找到远程仓库信息，无法更新(ansi reset)"
    return false
  }

  print $"远程仓库: ($remote_url)"

  # 获取更新前的提交信息
  let before_commit = (get-git-latest-commit $vocab_path)

  # 检查是否需要更新
  if not $force {
    print $"(ansi cyan)正在检查远程更新...(ansi reset)"
    let has_updates = (check-git-updates $vocab_path)
    if not $has_updates {
      print $"(ansi green)✓ 词库已是最新版本，无需更新(ansi reset)"
      return true
    }
  } else {
    print $"(ansi yellow)强制更新模式(ansi reset)"
  }

  # 停止小狼毫服务
  if not (stop-weasel-server) {
    print $"(ansi yellow)警告：停止小狼毫服务失败，继续执行词库更新(ansi reset)"
  }

  # 等待1秒确保服务完全停止
  sleep 1sec

  # 执行 git pull
  let pull_success = (perform-git-pull $vocab_path)
  if not $pull_success {
    print $"(ansi red)❌ 词库更新失败(ansi reset)"
    # 尝试重新启动小狼毫服务
    if not (start-weasel-server) {
      print $"(ansi yellow)警告：启动小狼毫服务失败，请手动启动(ansi reset)"
    }
    return false
  }

  # 获取更新后的提交信息
  let after_commit = (get-git-latest-commit $vocab_path)

  # 保存更新时间记录
  let repo_name = if ($repo_name | is-not-empty) {
    $repo_name
  } else {
    # 从远程 URL 提取仓库名
    let url_parts = ($remote_url | split row "/")
    if ($url_parts | length) >= 1 {
      let repo_with_ext = ($url_parts | last)
      ($repo_with_ext | str replace ".git" "")
    } else {
      "unknown"
    }
  }

  let update_time_key = (get-schema-update-time-key $repo_name)
  let update_time = if ($after_commit | is-not-empty) {
    $after_commit.date
  } else {
    date now
  }

  try {
    save-time-record $update_time_key $update_time
  } catch { |err|
    print $"(ansi yellow)警告：保存更新时间记录失败: ($err.msg)(ansi reset)"
  }

  # 显示更新结果
  if ($before_commit | is-not-empty) and ($after_commit | is-not-empty) {
    if $before_commit.hash != $after_commit.hash {
      print $"(ansi green)📥 词库已更新到新版本(ansi reset)"
      print $"旧提交: ($before_commit.hash | str substring 0..7) - ($before_commit.message)"
      print $"新提交: ($after_commit.hash | str substring 0..7) - ($after_commit.message)"
    } else {
      print $"(ansi yellow)⚠ 词库内容未发生变化(ansi reset)"
    }
  }

  # 启动小狼毫服务
  if not (start-weasel-server) {
    print $"(ansi yellow)警告：启动小狼毫服务失败，请手动启动(ansi reset)"
  }

  # 触发重新部署
  sleep 1sec
  print $"(ansi cyan)正在触发重新部署...(ansi reset)"
  if not (redeploy-weasel) {
    print $"(ansi yellow)警告：触发重新部署失败，请手动重新部署(ansi reset)"
  }

  print $"(ansi green)🎉 词库更新成功完成！(ansi reset)"
  return true
}

# 初始化词库仓库
export def init-schema-repo [
  repo_url: string         # Git 仓库 URL
  --target-dir(-t): string # 目标目录（默认使用小狼毫用户目录）
  --repo-name(-n): string  # 仓库名称（用于记录时间）
] {
  print $"(ansi cyan)=== 初始化 Rime 词库仓库 ===(ansi reset)"

  # 验证小狼毫安装
  if not (verify-weasel-installation) {
    print $"(ansi red)错误：小狼毫安装验证失败，无法继续(ansi reset)"
    return false
  }

  # 确定目标目录
  let target_directory = if ($target_dir | is-not-empty) {
    $target_dir
  } else {
    get-weasel-user-dir
  }

  if ($target_directory | is-empty) {
    print $"(ansi red)错误：无法确定目标目录(ansi reset)"
    return false
  }

  print $"目标目录: ($target_directory)"
  print $"仓库地址: ($repo_url)"

  # 检查目录是否已存在
  if ($target_directory | path exists) {
    # 检查是否已经是 git 仓库
    let git_dir = ($target_directory | path join ".git")
    if ($git_dir | path exists) {
      print $"(ansi yellow)警告：目标目录已经是 git 仓库(ansi reset)"

      # 检查远程是否匹配
      let existing_remote = (get-git-remote-info $target_directory)
      if ($existing_remote | is-not-empty) and ($existing_remote == $repo_url) {
        print $"(ansi green)✓ 远程仓库匹配，无需重新初始化(ansi reset)"
        return true
      } else {
        print $"(ansi red)错误：现有远程仓库不匹配(ansi reset)"
        print $"现有远程: ($existing_remote)"
        print $"期望远程: ($repo_url)"
        return false
      }
    } else {
      print $"(ansi red)错误：目标目录已存在但不是 git 仓库(ansi reset)"
      return false
    }
  }

  # 克隆仓库
  try {
    print $"(ansi cyan)正在克隆仓库...(ansi reset)"
    let result = (^git clone $repo_url $target_directory | complete)
    if $result.exit_code == 0 {
      print $"(ansi green)✓ 仓库克隆成功(ansi reset)"
    } else {
      print $"(ansi red)✗ 仓库克隆失败(ansi reset)"
      if not ($result.stderr | str trim | is-empty) {
        print $"错误信息: ($result.stderr)"
      }
      return false
    }
  } catch { |err|
    print $"(ansi red)错误：克隆仓库时发生异常: ($err.msg)(ansi reset)"
    return false
  }

  # 验证克隆结果
  if not (validate-git-repo $target_directory) {
    print $"(ansi red)错误：克隆后的目录验证失败(ansi reset)"
    return false
  }

  # 保存初始化时间记录
  let repo_name = if ($repo_name | is-not-empty) {
    $repo_name
  } else {
    # 从 URL 提取仓库名
    let url_parts = ($repo_url | split row "/")
    if ($url_parts | length) >= 1 {
      let repo_with_ext = ($url_parts | last)
      ($repo_with_ext | str replace ".git" "")
    } else {
      "unknown"
    }
  }

  let update_time_key = (get-schema-update-time-key $repo_name)
  try {
    save-time-record $update_time_key (date now)
  } catch { |err|
    print $"(ansi yellow)警告：保存初始化时间记录失败: ($err.msg)(ansi reset)"
  }

  print $"(ansi green)🎉 词库仓库初始化成功完成！(ansi reset)"
  return true
}
