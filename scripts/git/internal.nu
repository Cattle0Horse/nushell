# todo: 类型注释

# 获取当前仓库的根目录
export def git-root [] {
  ^git rev-parse --show-toplevel
}

export def git-current-branch [] {
  ^git rev-parse --abbrev-ref HEAD
}

# 查询暂存区是否有未提交的更改
export def git-has-changed-in-staging [] {
  (^git diff --cached --quiet | complete).exit_code == 1
}

# 列出未暂存的文件
export def git-ls-unstaged-changes [] {
  ^git ls-files --modified --others --exclude-standard
}

# 查询是否有上游分支
export def git-has-up-branch [] {
  (^git rev-parse --abbrev-ref @{u} | complete).exit_code != 0
}

# 查询是否有未推送的更改
export def git-has-unpushed-changes [] {
  ((^git rev-list @{u}.. | complete).stdout | split row "\n" | length) - 1 != 0
}

# 判断是当前目录是否在git仓库中
export def git-is-in-git-repo [] {
  (^git rev-parse --is-inside-work-tree | complete).exit_code == 0
}

# git diff --name-only # 已跟踪未暂存的文件
# git ls-files --others --exclude-standard # 未跟踪的文件
# git ls-files --modified --others --exclude-standard # 未暂存的文件（上面两个的和）
