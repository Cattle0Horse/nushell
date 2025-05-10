# 20250418
################################################################
# 函数
################################################################

# 支持的架构列表
def scoopArches [] {
  ["32bit" "64bit"]
}

# 所有已安装应用列表
def scoopInstalledApps [] {
  let localAppDir = if ('SCOOP' in $env) {
    [$env.SCOOP 'apps'] | path join
  } else {
    [$env.USERPROFILE 'scoop' 'apps'] | path join
  }
  let localApps = (ls $localAppDir | get name | path basename)

  let globalAppDir = if ('SCOOP_GLOBAL' in $env) {
    [$env.SCOOP_GLOBAL 'apps'] | path join
  } else {
    [$env.ProgramData 'scoop' 'apps'] | path join
  }
  let globalApps = if ($globalAppDir | path exists) { ls $globalAppDir | get name | path basename }

  $localApps | append $globalApps
}

# 所有已安装应用带星号列表
def scoopInstalledAppsWithStar [] {
  scoopInstalledApps | prepend '*'
}

# 所有存储桶清单列表
def scoopAllApps [] {
  let bucketsDir = if ('SCOOP' in $env) {
    [$env.SCOOP 'buckets'] | path join
  } else {
    [$env.USERPROFILE 'scoop' 'buckets'] | path join
  }
  (ls -s $bucketsDir | get name) | each {|bucket| ls ([$bucketsDir $bucket 'bucket'] | path join) | get name | path parse | where extension == json | get stem } | flatten | uniq
}

# 所有未安装应用列表
def scoopAvailableApps [] {
  let all = (scoopAllApps)
  let installed = (scoopInstalledApps)

  $all | where $it not-in $installed
}

# 所有配置选项列表
def scoopConfigs [] {
  [
    '7ZIPEXTRACT_USE_EXTERNAL'
    'MSIEXTRACT_USE_LESSMSI'
    'NO_JUNCTIONS'
    'SCOOP_REPO'
    'SCOOP_BRANCH'
    'proxy'
    'default_architecture'
    'debug'
    'force_update'
    'show_update_log'
    'manifest_review'
    'shim'
    'rootPath'
    'globalPath'
    'cachePath'
    'gh_token'
    'virustotal_api_key'
    'cat_style'
    'ignore_running_processes'
    'private_hosts'
    'aria2-enabled'
    'aria2-warning-enabled'
    'aria2-retry-wait'
    'aria2-split'
    'aria2-max-connection-per-server'
    'aria2-min-split-size'
    'aria2-options'
  ]
}

# 布尔值作为字符串
def scoopBooleans [] {
  ["'true'" "'false'"]
}

def scoopRepos [] {
  [
    '<url id="d0160bvftae3mnmr8u70" type="url" status="parsed" title="GitHub - ScoopInstaller/Scoop: A command-line installer for Windows." wc="6290">https://github.com/ScoopInstaller/Scoop</url> '
  ]
}

def scoopBranches [] {
  ['master' 'develop']
}

def scoopShimBuilds [] {
  ['kiennq' 'scoopcs' '71']
}

def scoopCommands [] {
  let libexecDir = if ('SCOOP' in $env) {
    [$env.SCOOP 'apps' 'scoop' 'current' 'libexec'] | path join
  } else {
    [$env.USERPROFILE 'scoop' 'apps' 'scoop' 'current' 'libexec'] | path join
  }

  let commands = (
    ls $libexecDir
    | each {|command|
      [
        [value description];
        [
          # 例如scoop-help.ps1 -> help
          ($command.name | path parse | get stem | str substring 6..)
          # 第二行以 '# Summary: ' 开头
          # 例如'# Summary: Install apps' -> 'Install apps'
          (open $command.name | lines | skip 1 | first | str substring 11..)
        ]
      ]
    }
    | flatten
  )
  $commands
}

def scoopAliases [] {
  scoop alias list | str trim | lines | slice 2.. | split column " " | get column1
}

def batStyles [] {
  ['default' 'auto' 'full' 'plain' 'changes' 'header' 'header-filename' 'header-filesize' 'grid' 'rule' 'numbers' 'snip']
}

def scoopShims [] {
  let localShimDir = if ('SCOOP' in $env) { [$env.SCOOP 'shims'] | path join } else if (scoop config root_path | path exists) { scoop config root_path } else { [$env.USERPROFILE 'scoop' 'shims'] | path join }
  let localShims = if ($localShimDir | path exists) { ls $localShimDir | get name | path parse | select stem extension | where extension == shim | get stem } else { [] }

  let globalShimDir = if ('SCOOP_GLOBAL' in $env) { [$env.SCOOP_GLOBAL 'shims'] | path join } else if (scoop config global_path | path exists) { scoop config global_path } else { [$env.ProgramData 'scoop' 'shims'] | path join }
  let globalShims = if ($globalShimDir | path exists) { ls $globalShimDir | get name | path parse | select stem extension | where extension == shim | get stem } else { [] }

  $localShims | append $globalShims | uniq | sort
}

################################################################
# scoop
################################################################

# Windows 命令行安装程序
export extern "scoop" [
  alias?: string@scoopCommands # 可用的 scoop 命令和别名
  --help (-h) # 显示此命令的帮助
  --version (-v) # 显示当前 scoop 及添加的存储桶版本
]

################################################################
# scoop list
################################################################

# 列出所有已安装应用，或符合提供的查询的应用
export extern "scoop list" [
  query?: string@scoopInstalledApps # 将被匹配的字符串
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop uninstall
################################################################

# 卸载指定的应用程序
export extern "scoop uninstall" [
  ...app: string@scoopInstalledApps # 将被卸载的应用
  --help (-h) # 显示此命令的帮助
  --global (-g) # 卸载全局安装的应用程序
  --purge (-p) # 持久数据将被移除通常当应用程序被卸载时，persist 属性/手动持久化的数据会被保留
]

################################################################
# scoop cleanup
################################################################

# 对指定的已安装应用执行清理，移除旧的/不常使用的版本
export extern "scoop cleanup" [
  ...app: string@scoopInstalledAppsWithStar # 将被清理的应用
  --help (-h) # 显示此命令的帮助
  --all (-a) # 清理所有应用（'*' 的替代）
  --global (-g) # 对全局安装的应用程序执行清理（如果使用 '*'，则包括它们）
  --cache (-k) # 移除过时的下载缓存这将只保留最新版本的缓存
]

################################################################
# scoop info
################################################################

# 显示有关应用的信息
export extern "scoop info" [
  app: string@scoopAllApps # 将被询问的应用
  --verbose (-v) # 显示完整路径和 URL
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop update
################################################################

# 更新已安装的应用程序，或 scoop 本身
export extern "scoop update" [
  ...app: string@scoopInstalledAppsWithStar # 哪些应用
  --help (-h) # 显示此命令的帮助
  --force (-f) # 即使没有新版本也强制更新
  --global (-g) # 更新全局安装的应用程序
  --independent (-i) # 不自动安装依赖项
  --no-cache (-k) # 不使用下载缓存
  --skip (-s) # 跳过哈希验证（谨慎使用！）
  --quiet (-q) # 隐藏多余的消息
  --all (-a) # 更新所有应用（'*' 的替代）
]

################################################################
# scoop install
################################################################

# 安装指定的应用程序
export extern "scoop install" [
  ...app: string@scoopAvailableApps # 哪些应用
  --arch (-a): string@scoopArches # 如果应用清单支持，则使用指定的架构
  --help (-h) # 显示此命令的帮助
  --global (-g) # 全局安装应用程序
  --independent (-i) # 不自动安装依赖项
  --no-cache (-k) # 不使用下载缓存
  --skip (-s) # 跳过哈希验证（谨慎使用！）
  --no-update-scoop (-u) # 如果 scoop 过时，安装前不要更新 scoop
]

################################################################
# scoop status
################################################################

# 显示状态并检查新的应用版本
export extern "scoop status" [
  --help (-h) # 显示此命令的帮助
  --local (-l) # 仅检查本地安装的应用的状态，并禁用对 scoop 和存储桶的远程获取/检查
]

################################################################
# scoop help
################################################################

# 显示 scoop 的帮助
export extern "scoop help" [
  --help (-h) # 显示此命令的帮助

  command?: string@scoopCommands # 显示指定命令的帮助
]

################################################################
# scoop alias
################################################################

# 添加、移除或列出 Scoop 别名
export extern "scoop alias" [
  --help (-h) # 显示此命令的帮助
]

# 添加别名
export extern "scoop alias add" [
  name: string # 别名名称
  command: string # scoop 命令
  description: string # 别名描述
]

# 列出所有别名
export extern "scoop alias list" [
  --verbose (-v) # 显示别名描述和表头（仅适用于 'list'）
]

# 移除别名
export extern "scoop alias rm" [
  ...name: string@scoopAliases # 将被移除的别名
]

################################################################
# scoop shim
################################################################

# 操作 Scoop 快捷方式
export extern "scoop shim" [
  --help (-h) # 显示此命令的帮助
]

# 添加自定义快捷方式
export extern "scoop shim add" [
  shim_name: string # 快捷方式名称
  command_path: path # 可执行文件路径
  ...cmd_args # 额外的命令参数
  --global (-g) # 操作全局快捷方式
]

# 移除快捷方式（注意：这可能会移除由应用清单添加的快捷方式）
export extern "scoop shim rm" [
  ...shim_name: string@scoopShims # 将被移除的快捷方式
  --global (-g) # 操作全局快捷方式
]

# 列出所有快捷方式或匹配的快捷方式
export extern "scoop shim list" [
  pattern?: string # 仅列出匹配的快捷方式
  --global (-g) # 操作全局快捷方式
]

# 显示快捷方式的信息
export extern "scoop shim info" [
  shim_name: string@scoopShims # 将被检索的快捷方式信息
  --global (-g) # 操作全局快捷方式
]

# 更改快捷方式的目标源
export extern "scoop shim alter" [
  shim_name: string@scoopShims # 将被更改的快捷方式
  --global (-g) # 操作全局快捷方式
]

################################################################
# scoop which
################################################################

# 定位通过 Scoop 安装的快捷方式/可执行文件的路径（类似于 Linux 上的 'which'）
export extern "scoop which" [
  command: string # 带有 .exe 的可执行文件名称
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop cat
################################################################

# 显示指定清单的内容
export extern "scoop cat" [
  app: string@scoopAllApps # 将被显示的应用
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop checkup
################################################################

# 执行一系列诊断测试，试图识别可能导致 Scoop 问题的因素
export extern "scoop checkup" [
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop home
################################################################

# 打开应用主页
export extern "scoop home" [
  app: string@scoopAllApps # 将被显示的应用
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop config ...
################################################################

# 获取或设置配置值
export extern "scoop config" [
  --help (-h) # 显示此命令的帮助
]

# 使用外部 7zip（来自路径）进行存档提取
export extern "scoop config 7ZIPEXTRACT_USE_EXTERNAL" [
  value?: string@scoopBooleans
]

# 优先使用 lessmsi 实用程序而非原生 msiexec
export extern "scoop config MSIEXTRACT_USE_LESSMSI" [
  value?: string@scoopBooleans
]

# 不使用 'current' 版本别名快捷方式和快捷方式将指向特定版本
export extern "scoop config NO_JUNCTIONS" [
  value?: string@scoopBooleans
]

# 包含 scoop 源代码的 Git 仓库
export extern "scoop config SCOOP_REPO" [
  value?: string@scoopRepos
]

# 允许使用不同于 master 的分支
export extern "scoop config SCOOP_BRANCH" [
  value?: string@scoopBranches
]

# [username:password@]host:port
export extern "scoop config proxy" [
  value?: string
]

# 允许配置应用安装的首选架构如果不指定，则由系统确定架构
export extern "scoop config default_architecture" [
  value?: string@scoopArches
]

# 显示额外和详细的输出
export extern "scoop config debug" [
  value?: string@scoopBooleans
]

# 强制应用更新到存储桶的版本
export extern "scoop config force_update" [
  value?: string@scoopBooleans
]

# 在 'scoop update' 上不显示更改的提交
export extern "scoop config show_update_log" [
  value?: string@scoopBooleans
]

# 显示即将安装的每个应用的清单，然后询问用户是否希望继续
export extern "scoop config manifest_review" [
  value?: string@scoopBooleans
]

# 选择 scoop 快捷方式构建
export extern "scoop config shim" [
  value?: string@scoopShimBuilds
]

# Scoop 根目录的路径
export extern "scoop config root_path" [
  value?: directory
]

# 全局应用的 Scoop 根目录路径
export extern "scoop config global_path" [
  value?: directory
]

# 用于下载，默认为 Scoop 根目录下的 'cache' 文件夹
export extern "scoop config cachePath" [
  value?: directory
]

# 用于进行身份验证请求的 GitHub API 令牌
export extern "scoop config gh_token" [
  value?: string
]

# 用于使用 virustotal 上传/扫描文件的 API 密钥
export extern "scoop config virustotal_api_key" [
  value?: string
]

# "scoop cat" 显示样式需要安装 "bat"
export extern "scoop config cat_style" [
  value?: string@batStyles
]

# 重置、卸载或更新时丢弃应用程序运行消息
export extern "scoop config ignore_running_processes" [
  value?: string@scoopBooleans
]

# 需要额外身份验证的私有主机数组
export extern "scoop config private_hosts" [
  value?: string
]

# 使用 aria2c 下载工件
export extern "scoop config aria2-enabled" [
  value?: string@scoopBooleans
]

# 禁用下载时显示的 Aria2c 警告
export extern "scoop config aria2-warning-enabled" [
  value?: string@scoopBooleans
]

# 重试之间的等待秒数
export extern "scoop config aria2-retry-wait" [
  value?: number
]

# 下载使用的连接数
export extern "scoop config aria2-split" [
  value?: number
]

# 每个下载连接到一个服务器的最大连接数
export extern "scoop config aria2-max-connection-per-server" [
  value?: number
]

# 下载的文件将按此配置的大小分割，并使用多个连接下载
export extern "scoop config aria2-min-split-size" [
  value?: string
]

# 额外的 aria2 选项数组
export extern "scoop config aria2-options" [
  value?: string
]

# 移除配置设置
export extern "scoop config rm" [
  name: string@scoopConfigs # 将被移除的应用
]

################################################################
# scoop hold
################################################################

# 暂停应用以禁用更新
export extern "scoop hold" [
  app: string@scoopInstalledApps # 将被暂停的应用
  --global (-g) # 暂停全局安装的应用
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop unhold
################################################################

# 取消暂停应用以启用更新
export extern "scoop unhold" [
  app: string@scoopInstalledApps # 将被取消暂停的应用
  --global (-g) # 取消暂停全局安装的应用
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop depends
################################################################

# 列出应用的依赖项，按安装顺序排列
export extern "scoop depends" [
  app: string@scoopAllApps # 问题应用
  --arch (-a): string@scoopArches # 如果应用清单支持，则使用指定的架构
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop export
################################################################

# 以 JSON 格式导出已安装的应用、存储桶（可选配置）
export extern "scoop export" [
  --config (-c) # 也导出 Scoop 配置文件
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop import
################################################################

# 从 JSON 格式的 Scoopfile 导入应用、存储桶和配置
export extern "scoop import" [
  file: path # Scoopfile 路径
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop reset
################################################################

# 重置应用以解决冲突
export extern "scoop reset" [
  app: string@scoopInstalledAppsWithStar # 将被重置的应用
  --all (-a) # 重置所有应用（'*' 的替代）
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop prefix
################################################################

# 返回指定应用的路径
export extern "scoop prefix" [
  app: string@scoopInstalledApps # 问题应用
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop create
################################################################

# 创建自定义应用清单
export extern "scoop create" [
  url: string # 清单的 URL
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop search
################################################################

# 搜索部分应用
export extern "scoop search" [
  query?: string # 显示匹配查询的应用名称
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop cache ...
################################################################

# 显示下载缓存
export extern "scoop cache" [
  ...apps: string@scoopInstalledAppsWithStar # 问题应用
  --help (-h) # 显示此命令的帮助
]

# 显示下载缓存
export extern "scoop cache show" [
  ...apps: string@scoopInstalledAppsWithStar # 问题应用
]

# 清除下载缓存
export extern "scoop cache rm" [
  ...apps: string@scoopInstalledAppsWithStar # 问题应用
  --all (-a) # 清除所有应用（'*' 的替代）
]

################################################################
# scoop download
################################################################

# 在缓存文件夹中下载应用并验证哈希值
export extern "scoop download" [
  app?: string@scoopAvailableApps # 问题应用
  --help (-h) # 显示此命令的帮助
  --force (-f) # 强制下载（覆盖缓存）
  --no-hash-check (-h) # 跳过哈希验证（谨慎使用！）
  --no-update-scoop (-u) # 如果 scoop 过时，下载前不要更新 scoop
  --arch (-a): string@scoopArches # 如果应用支持，则使用指定的架构
]

################################################################
# scoop bucket ...
################################################################

def scoopKnownBuckets [] {
  ["main" "extras" "versions" "nirsoft" "php" "nerd-fonts" "nonportable" "java" "games" "sysinternals"]
}

def scoopInstalledBuckets [] {
  let bucketsDir = if ('SCOOP' in $env) {
    [$env.SCOOP 'buckets'] | path join
  } else {
    [$env.USERPROFILE 'scoop' 'buckets'] | path join
  }

  let buckets = (ls $bucketsDir | get name | path basename)
  $buckets
}

def scoopAvailableBuckets [] {
  let known = (scoopKnownBuckets)
  let installed = (scoopInstalledBuckets)

  $known | where $it not-in $installed
}

# 添加、列出或移除存储桶
export extern "scoop bucket" [
  --help (-h) # 显示此命令的帮助
]

# 添加存储桶
export extern "scoop bucket add" [
  name: string@scoopAvailableBuckets # 存储桶名称
  repo?: string # git 仓库的 URL
  --help (-h) # 显示此命令的帮助
]

# 列出已安装的存储桶
export extern "scoop bucket list" [
  --help (-h) # 显示此命令的帮助
]

# 列出已知存储桶
export extern "scoop bucket known" [
  --help (-h) # 显示此命令的帮助
]

# 移除已安装的存储桶
export extern "scoop bucket rm" [
  name: string@scoopInstalledBuckets # 要移除的存储桶
  --help (-h) # 显示此命令的帮助
]

################################################################
# scoop virustotal
################################################################

# 在 virustotal.com 上查找应用的哈希值或 URL
export extern "scoop virustotal" [
  ...apps: string@scoopInstalledAppsWithStar # 要扫描的应用
  --all (-a) # 检查所有已安装的应用
  --scan (-s) # 发送下载 URL 进行分析（以及未来检索）
  --no-depends (-n) # 默认情况下，也会检查所有依赖项，这个标志避免了这一点
  --no-update-scoop (-u) # 如果 scoop 过时，检查前不要更新 scoop
  --passthru (-p) # 以对象形式返回报告
  --help (-h) # 显示此命令的帮助
]
