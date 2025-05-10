# 列出git存储库的分支和最后一次提交的日期
export def "git age" [] : nothing -> table<name: string, last_commit: datetime> {
  ^git branch |
    lines |
    str substring 2.. |
    wrap name |
    insert last_commit {
      get name | each {
        ^git show $in --no-patch --format=%as | into datetime
      }
    } | sort-by last_commit
}
