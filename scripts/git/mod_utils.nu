# 模块内部使用的工具方法，便于脚本处理
# todo: 类型注释

export def git_current_branch [] {
    ^git rev-parse --abbrev-ref HEAD
}

# 查询暂存区是否有未提交的更改
export def git_has_changed_in_staging [] {
    (^git diff --cached --quiet | complete).exit_code == 1
}

# 列出未暂存的文件
export def git_ls_unstaged_changes [] {
    ^git ls-files --modified --others --exclude-standard
}

# 查询是否有上游分支
export def git_has_up_branch [] {
    (^git rev-parse --abbrev-ref @{u} | complete).exit_code != 0
}

# 查询是否有未推送的更改
export def git_has_unpushed_changes [] {
    ((^git rev-list @{u}.. | complete).stdout | split row "\n" | length) - 1 != 0
}

# 判断是当前目录是否在git仓库中
export def git_is_in_git_repo [] {
    (^git rev-parse --is-inside-work-tree | complete).exit_code == 0
}

# git diff --name-only # 已跟踪未暂存的文件
# git ls-files --others --exclude-standard # 未跟踪的文件
# git ls-files --modified --others --exclude-standard # 未暂存的文件（上面两个的和）


