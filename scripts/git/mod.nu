# 实用的git实用函数的集合

export use ignore.nu *
export use ignore-gen.nu *
export use url.nu *
export use utils.nu *
export use histogram.nu *
export use log.nu *
export use show.nu *
export use commit.nu *
export use clone.nu *
export use branch_cleanup.nu *
export use merge.nu *
export use flow.nu *

export-env {
  export use url.nu
  export use commit.nu
  export use clone.nu
  export use branch_cleanup.nu
  export use flow.nu
  export use merge.nu
}


# 管理本地 git 仓库，包括克隆、更新、删除等操作
# 可以使用json持久化 本地的git仓库
