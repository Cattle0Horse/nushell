# nu 版本: 0.106.0

# 此脚本通过导出 `uv generate-shell-completion` 的输出并添加更多补全器创建而成

module completions {

  const PYPRJ = 'pyproject.toml'

  # 将字符串拆分为参数列表，考虑引号的影响
  # 代码复制并修改自 https://github.com/nushell/nushell/issues/14582#issuecomment-2542596272
  def args-split []: string -> list<string> {
    # 定义状态
    const STATE_NORMAL = 0
    const STATE_IN_SINGLE_QUOTE = 1
    const STATE_IN_DOUBLE_QUOTE = 2
    const STATE_ESCAPE = 3
    const WHITESPACES = [" " "\t" "\n" "\r"]

    # 初始化变量
    mut state = $STATE_NORMAL
    mut current_token = ""
    mut result: list<string> = []
    mut prev_state = $STATE_NORMAL

    # 处理每个字符
    for char in ($in | split chars) {
      if $state == $STATE_ESCAPE {
        # 处理转义字符
        $current_token = $current_token + $char
        $state = $prev_state
      } else if $char == '\' {
        # 进入转义状态
        $prev_state = $state
        $state = $STATE_ESCAPE
      } else if $state == $STATE_NORMAL {
        if $char == "'" {
          $state = $STATE_IN_SINGLE_QUOTE
        } else if $char == '"' {
          $state = $STATE_IN_DOUBLE_QUOTE
        } else if ($char in $WHITESPACES) {
          # 正常状态下的空白字符表示标记边界
          $result = $result | append $current_token
          $current_token = ""
        } else {
          $current_token = $current_token + $char
        }
      } else if $state == $STATE_IN_SINGLE_QUOTE {
        if $char == "'" {
          $state = $STATE_NORMAL
        } else {
          $current_token = $current_token + $char
        }
      } else if $state == $STATE_IN_DOUBLE_QUOTE {
        if $char == '"' {
          $state = $STATE_NORMAL
        } else {
          $current_token = $current_token + $char
        }
      }
    }
    # 处理最后一个标记
    $result = $result | append $current_token
    # 返回结果
    $result
  }

  def "nu-complete uv python_preference" [] {
    [ "only-managed" "managed" "system" "only-system" ]
  }

  def "nu-complete uv python_fetch" [] {
    [ "automatic" "manual" "never" ]
  }

  def "nu-complete uv color" [] {
    [ "auto" "always" "never" ]
  }

  def "nu-complete uv index_strategy" [] {
    [ "first-index" "unsafe-first-match" "unsafe-best-match" ]
  }

  def "nu-complete uv keyring_provider" [] {
    [ "disabled" "subprocess" ]
  }

  def "nu-complete uv resolution" [] {
    [ "highest" "lowest" "lowest-direct" ]
  }

  def "nu-complete uv prerelease" [] {
    [ "disallow" "allow" "if-necessary" "explicit" "if-necessary-or-explicit" ]
  }

  def "nu-complete uv fork_strategy" [] {
    [ "fewest" "requires-python" ]
  }

  def "nu-complete uv link_mode" [] {
    [ "clone" "copy" "hardlink" "symlink" ]
  }

  def "nu-complete uv python_platform" [] {
    [ "windows" "linux" "macos" "x86_64-pc-windows-msvc" "aarch64-pc-windows-msvc" "i686-pc-windows-msvc" "x86_64-unknown-linux-gnu" "aarch64-apple-darwin" "x86_64-apple-darwin" "aarch64-unknown-linux-gnu" "aarch64-unknown-linux-musl" "x86_64-unknown-linux-musl" "riscv64-unknown-linux" "x86_64-manylinux2014" "x86_64-manylinux_2_17" "x86_64-manylinux_2_28" "x86_64-manylinux_2_31" "x86_64-manylinux_2_32" "x86_64-manylinux_2_33" "x86_64-manylinux_2_34" "x86_64-manylinux_2_35" "x86_64-manylinux_2_36" "x86_64-manylinux_2_37" "x86_64-manylinux_2_38" "x86_64-manylinux_2_39" "x86_64-manylinux_2_40" "aarch64-manylinux2014" "aarch64-manylinux_2_17" "aarch64-manylinux_2_28" "aarch64-manylinux_2_31" "aarch64-manylinux_2_32" "aarch64-manylinux_2_33" "aarch64-manylinux_2_34" "aarch64-manylinux_2_35" "aarch64-manylinux_2_36" "aarch64-manylinux_2_37" "aarch64-manylinux_2_38" "aarch64-manylinux_2_39" "aarch64-manylinux_2_40" "aarch64-linux-android" "x86_64-linux-android" "wasm32-pyodide2024" "arm64-apple-ios" "arm64-apple-ios-simulator" "x86_64-apple-ios-simulator" ]
  }

  def "nu-complete uv output_format" [] {
    [ "text" "json" ]
  }

  def find-pyproject-file [] {
    mut folder = $env.PWD
    loop {
      let $try_path = $folder | path join $PYPRJ
      if ($try_path | path exists) {
        return $try_path
      }
      if (($folder | path parse).parent | is-empty) {
        # 已在根目录
        return null
      }
      $folder = $folder | path dirname
    }
  }

  def get-groups []: nothing -> list<string> {
    let file = (find-pyproject-file)
    try { open $file | get -o dependency-groups | columns } catch { [] }
  }

  # 子命令的组补全器
  def "nu-complete uv groups" [] {
    get-groups
  }

  # "uv add" 的组补全器
  # 当没有组时，建议使用常用名称 "dev"
  def "nu-complete uv groups for add" [] {
    get-groups | default ['dev']
  }

  # 从包及其版本字符串列表中，仅获取包名称
  # 参考: https://packaging.python.org/en/latest/specifications/dependency-specifiers/#dependency-specifiers
  def parse-package-names []: list<string> -> list<string> {
    $in | split column  -n 2 -r '[\s\[@>=<;~!]' p v | get p
  }

  # 从 "project.dependencies" 获取包
  def get-main-packages [] {
    let file = (find-pyproject-file)
    try { open $file | get -o project.dependencies | parse-package-names } catch { [] }
  }

  # 从 "project.optional-dependencies" 获取包
  def get-optional-packages [] {
    let file = (find-pyproject-file)
    try { open $file | get -o project.optional-dependencies | parse-package-names } catch { [] }
  }

  # 从 "dependency-groups" 获取包
  # 参考: https://packaging.python.org/en/latest/specifications/dependency-groups/#dependency-groups
  def get-dependency-group-packages [only_group?: string] {
    let file = (find-pyproject-file)
    let dg = try { open $file | get -o dependency-groups } catch { [] }
    # 一个组可以包含其他组，例如:
    # dev = ['click', { include-group = "docs" }, { include-group = "linting" }, { include-group = "test" }]
    let handle_line = {|p| if (($p | describe) == 'string') { $p } else { $dg | get ($p.include-group) } }
    if ($only_group | is-not-empty) {
      $dg | get $only_group | each $handle_line | flatten | parse-package-names
    } else {
      $dg | items { |gn, pk| $pk | each $handle_line | flatten } | flatten | parse-package-names
    }
  }

  def get-all-dependencies [] {
    get-main-packages | append (get-optional-packages) | append (get-dependency-group-packages)
  }

  export def "nu-complete uv packages" [context: string, position?:int] {
    let preceding = $context | str substring ..$position
    let prev_tokens = $preceding | str trim | args-split
    # 检查是否指定了 "--group"
    let go = $prev_tokens | enumerate | find '--group' | get -o index.0
    let group = if ($go | is-not-empty) { $prev_tokens | get -o ($go + 1)}
    if ($group | is-empty ) {
      get-all-dependencies
    } else {
      get-dependency-group-packages $group
    }
  }

  # 一个极快的 Python 包管理器
  export extern uv [
    command: string
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
    --version(-V)             # 显示 uv 版本
  ]

  # 管理认证
  export extern "uv auth" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 登录到服务
  export extern "uv auth login" [
    service: string           # 要登录的服务的域名或 URL
    --username(-u): string    # 用于服务的用户名
    --password: string        # 用于服务的密码
    --token(-t): string       # 用于服务的令牌
    --keyring-provider: string@"nu-complete uv keyring_provider" # 用于存储凭证的密钥环提供程序
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 从服务登出
  export extern "uv auth logout" [
    service: string           # 要登出的服务的域名或 URL
    --username(-u): string    # 要登出的用户名
    --keyring-provider: string@"nu-complete uv keyring_provider" # 用于存储凭证的密钥环提供程序
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示服务的认证令牌
  export extern "uv auth token" [
    service: string           # 要查找的服务的域名或 URL
    --username(-u): string    # 要查找的用户名
    --keyring-provider: string@"nu-complete uv keyring_provider" # 用于读取凭证的密钥环提供程序
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示 uv 凭证目录的路径
  export extern "uv auth dir" [
    service?: string          # 要查找的服务的域名或 URL
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv auth helper protocol" [] {
    [ "bazel" ]
  }

  # 作为外部工具的凭证助手
  export extern "uv auth helper" [
    --protocol: string@"nu-complete uv auth helper protocol" # 要使用的凭证助手协议
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 检索 URI 的凭证
  export extern "uv auth helper get" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 运行命令或脚本
  export extern "uv run" [
    --extra: string           # 包含指定额外名称的可选依赖
    --all-extras              # 包含所有可选依赖
    --no-extra: string        # 如果提供了 `--all-extras`，则排除指定的可选依赖
    --no-all-extras
    --dev                     # 包含开发依赖组
    --no-dev                  # 禁用开发依赖组
    --group: string@"nu-complete uv groups"           # 包含指定依赖组的依赖
    --no-group: string@"nu-complete uv groups"        # 禁用指定的依赖组
    --no-default-groups       # 忽略默认依赖组
    --only-group: string@"nu-complete uv groups"      # 仅包含指定依赖组的依赖
    --all-groups              # 包含所有依赖组的依赖
    --module(-m)              # 运行 Python 模块
    --only-dev                # 仅包含开发依赖组
    --editable                # 将任何非可编辑依赖（包括项目和任何工作区成员）安装为可编辑
    --no-editable             # 将任何可编辑依赖（包括项目和任何工作区成员）安装为非可编辑
    --inexact                 # 不移除环境中存在的无关包
    --exact                   # 执行精确同步，移除无关包
    --env-file: path          # 从 `.env` 文件加载环境变量
    --no-env-file             # 避免从 `.env` 文件读取环境变量
    --with(-w): string@"nu-complete uv packages"        # 运行时已安装给定的包
    --with-editable: path     # 运行时已以可编辑模式安装给定的包
    --with-requirements: path # 运行时已安装给定文件中列出的包
    --isolated                # 在隔离的虚拟环境中运行命令
    --active                  # 优先使用活动的虚拟环境而不是项目的虚拟环境
    --no-active               # 优先使用项目的虚拟环境而不是活动环境
    --no-sync                 # 避免同步虚拟环境
    --locked                  # 断言 `uv.lock` 将保持不变
    --frozen                  # 运行时不更新 `uv.lock` 文件
    --script(-s)              # 将给定路径作为 Python 脚本运行
    --gui-script              # 将给定路径作为 Python GUI 脚本运行
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --all-packages            # 运行命令时安装所有工作区成员
    --package: string         # 在工作区中的特定包中运行命令
    --no-project              # 避免发现项目或工作区
    --python(-p): string      # 用于运行环境的 Python 解释器
    --show-resolution         # 是否显示任何环境修改的解析器和安装程序输出
    --max-recursion-depth: string # `uv run` 允许递归调用的次数
    --python-platform: string@"nu-complete uv python_platform" # 应为其安装要求的平台
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv init vcs" [] {
    [ "git" "none" ]
  }

  def "nu-complete uv init build_backend" [] {
    [ "uv" "hatch" "flit" "pdm" "poetry" "setuptools" "maturin" "scikit" ]
  }

  def "nu-complete uv init author_from" [] {
    [ "auto" "git" "none" ]
  }

  # 创建新项目
  export extern "uv init" [
    path?: path               # 用于项目/脚本的路径
    --name: string            # 项目名称
    --bare                    # 仅创建 `pyproject.toml`
    --virtual                 # 创建虚拟项目，而不是包
    --package                 # 设置项目以构建为 Python 包
    --no-package              # 不设置项目以构建为 Python 包
    --app                     # 为应用程序创建项目
    --lib                     # 为库创建项目
    --script                  # 创建脚本
    --description: string     # 设置项目描述
    --no-description          # 禁用项目描述
    --vcs: string@"nu-complete uv init vcs" # 为项目初始化版本控制系统
    --build-backend: string@"nu-complete uv init build_backend" # 为项目初始化所选的构建后端
    --backend                 # 构建后端的无效选项名称
    --no-readme               # 不创建 `README.md` 文件
    --author-from: string@"nu-complete uv init author_from" # 填写 `pyproject.toml` 中的 `authors` 字段
    --no-pin-python           # 不为项目创建 `.python-version` 文件
    --pin-python              # 为项目创建 `.python-version` 文件
    --no-workspace            # 避免发现工作区并创建独立项目
    --python(-p): string      # 用于确定最低支持 Python 版本的 Python 解释器
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv add bounds" [] {
    [ "lower" "major" "minor" "exact" ]
  }

  # 向项目添加依赖
  export extern "uv add" [
    ...packages: string       # 要添加的包，作为 PEP 508 要求（例如 `ruff==0.5.0`）
    --requirements(-r): path  # 添加给定文件中列出的包
    --constraints(-c): path   # 使用给定的要求文件约束版本 [env: UV_CONSTRAINT=]
    --marker(-m): string      # 将此标记应用于所有添加的包
    --dev                     # 将要求添加到开发依赖组 [env: UV_DEV=]
    --optional: string        # 将要求添加到包指定额外的可选依赖
    --group: string@"nu-complete uv groups for add"           # 将要求添加到指定的依赖组
    --editable                # 将要求添加为可编辑
    --no-editable
    --raw                     # 按提供的方式添加依赖
    --bounds: string@"nu-complete uv add bounds" # 添加依赖时要使用的版本说明符类型
    --rev: string             # 从 Git 添加依赖时要使用的提交
    --tag: string             # 从 Git 添加依赖时要使用的标签
    --branch: string          # 从 Git 添加依赖时要使用的分支
    --lfs                     # 从 Git 添加依赖时是否使用 Git LFS
    --extra: string           # 要为依赖启用的额外功能
    --no-sync                 # 避免同步虚拟环境
    --locked                  # 断言 `uv.lock` 将保持不变
    --frozen                  # 添加依赖而不重新锁定项目
    --active                  # 优先使用活动的虚拟环境而不是项目的虚拟环境
    --no-active               # 优先使用项目的虚拟环境而不是活动环境
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --package: string         # 将依赖添加到工作区中的特定包
    --script: path            # 将依赖添加到指定的 Python 脚本，而不是项目
    --python(-p): string      # 用于解析和同步的 Python 解释器
    --workspace               # 将依赖添加为工作区成员
    --no-workspace            # 不将依赖添加为工作区成员
    --no-install-project      # 不安装当前项目
    --only-install-project    # 仅安装当前项目
    --no-install-workspace    # 不安装任何工作区成员，包括当前项目
    --only-install-workspace  # 仅安装工作区成员，包括当前项目
    --no-install-local        # 不安装本地路径依赖
    --only-install-local      # 仅安装本地路径依赖
    --no-install-package: string@"nu-complete uv packages" # 不安装给定的包
    --only-install-package: string@"nu-complete uv packages" # 仅安装给定的包
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 从项目中移除依赖
  export extern "uv remove" [
    ...packages: string@"nu-complete uv packages"       # 要移除的依赖名称（例如 `ruff`）
    --dev                     # 从开发依赖组中移除包
    --optional: string        # 从项目指定额外的可选依赖中移除包
    --group: string@"nu-complete uv groups"           # 从指定的依赖组中移除包
    --no-sync                 # 重新锁定项目后避免同步虚拟环境
    --active                  # 优先使用活动的虚拟环境而不是项目的虚拟环境
    --no-active               # 优先使用项目的虚拟环境而不是活动环境
    --locked                  # 断言 `uv.lock` 将保持不变
    --frozen                  # 移除依赖而不重新锁定项目
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --package: string         # 从工作区中的特定包中移除依赖
    --script: path            # 从指定的 Python 脚本中移除依赖，而不是从项目中移除
    --python(-p): string      # 用于解析和同步的 Python 解释器
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv version bump" [] {
    [ "major" "minor" "patch" "stable" "alpha" "beta" "rc" "post" "dev" ]
  }

  # 读取或更新项目版本
  export extern "uv version" [
    value?: string            # 将项目版本设置为此值
    --bump: string@"nu-complete uv version bump" # 使用给定的语义更新项目版本
    --dry-run                 # 不将新版本写入 `pyproject.toml`
    --short                   # 仅显示版本
    --output-format: string@"nu-complete uv output_format" # 输出格式
    --no-sync                 # 重新锁定项目后避免同步虚拟环境
    --active                  # 优先使用活动的虚拟环境而不是项目的虚拟环境
    --no-active               # 优先使用项目的虚拟环境而不是活动环境
    --locked                  # 断言 `uv.lock` 将保持不变
    --frozen                  # 更新版本而不重新锁定项目
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --package: string         # 更新工作区中特定包的版本
    --python(-p): string      # 用于解析和同步的 Python 解释器
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 更新项目环境
  export extern "uv sync" [
    --extra: string           # 包含指定额外名称的可选依赖
    --output-format: string@"nu-complete uv output_format" # 选择输出格式
    --all-extras              # 包含所有可选依赖
    --no-extra: string        # 如果提供了 `--all-extras`，则排除指定的可选依赖
    --no-all-extras
    --dev                     # 包含开发依赖组
    --no-dev                  # 禁用开发依赖组
    --only-dev                # 仅包含开发依赖组
    --group: string@"nu-complete uv groups"           # 包含指定依赖组的依赖
    --no-group: string@"nu-complete uv groups"        # 禁用指定的依赖组
    --no-default-groups       # 忽略默认依赖组
    --only-group: string@"nu-complete uv groups"      # 仅包含指定依赖组的依赖
    --all-groups              # 包含所有依赖组的依赖
    --editable                # 将任何非可编辑依赖（包括项目和任何工作区成员）安装为可编辑
    --no-editable             # 将任何可编辑依赖（包括项目和任何工作区成员）安装为非可编辑
    --inexact                 # 不移除环境中存在的无关包
    --exact                   # 执行精确同步，移除无关包
    --active                  # 将依赖同步到活动的虚拟环境
    --no-active               # 优先使用项目的虚拟环境而不是活动环境
    --no-install-project      # 不安装当前项目
    --only-install-project    # 仅安装当前项目
    --no-install-workspace    # 不安装任何工作区成员，包括根项目
    --only-install-workspace  # 仅安装工作区成员，包括根项目
    --no-install-local        # 不安装本地路径依赖
    --only-install-local      # 仅安装本地路径依赖
    --no-install-package: string@"nu-complete uv packages" # 不安装给定的包
    --only-install-package: string@"nu-complete uv packages" # 仅安装给定的包
    --locked                  # 断言 `uv.lock` 将保持不变
    --frozen                  # 同步而不更新 `uv.lock` 文件
    --dry-run                 # 执行试运行，不写入锁定文件或修改项目环境
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --all-packages            # 同步工作区中的所有包
    --package: string         # 为工作区中的特定包同步
    --script: path            # 为 Python 脚本同步环境，而不是当前项目
    --python(-p): string      # 用于项目环境的 Python 解释器
    --python-platform: string@"nu-complete uv python_platform" # 应为其安装要求的平台
    --check                   # 检查 Python 环境是否与项目同步
    --no-check
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 更新项目的锁定文件
  export extern "uv lock" [
    --check                   # 检查锁定文件是否是最新的
    --locked                  # 检查锁定文件是否是最新的
    --check-exists            # 断言 `uv.lock` 存在而不检查它是否是最新的
    --dry-run                 # 执行试运行，不写入锁定文件
    --script: path            # 锁定指定的 Python 脚本，而不是当前项目
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --python(-p): string      # 解析期间使用的 Python 解释器
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv export format" [] {
    [ "requirements.txt" "pylock.toml" "cyclonedx1.5" ]
  }

  # 将项目的锁定文件导出为其他格式
  export extern "uv export" [
    --format: string@"nu-complete uv export format" # `uv.lock` 应导出到的格式
    --all-packages            # 导出整个工作区
    --package: string         # 导出工作区中特定包的依赖
    --prune: string           # 从依赖树中修剪给定的包
    --extra: string           # 包含指定额外名称的可选依赖
    --all-extras              # 包含所有可选依赖
    --no-extra: string        # 如果提供了 `--all-extras`，则排除指定的可选依赖
    --no-all-extras
    --dev                     # 包含开发依赖组
    --no-dev                  # 禁用开发依赖组
    --only-dev                # 仅包含开发依赖组
    --group: string@"nu-complete uv groups"           # 包含指定依赖组的依赖
    --no-group: string@"nu-complete uv groups"        # 禁用指定的依赖组
    --no-default-groups       # 忽略默认依赖组
    --only-group: string@"nu-complete uv groups"      # 仅包含指定依赖组的依赖
    --all-groups              # 包含所有依赖组的依赖
    --no-annotate             # 排除指示每个包来源的注释注释
    --annotate
    --no-header               # 排除生成的输出文件顶部的注释标头
    --header
    --editable                # 将任何非可编辑依赖（包括项目和任何工作区成员）导出为可编辑
    --no-editable             # 将任何可编辑依赖（包括项目和任何工作区成员）导出为非可编辑
    --hashes                  # 包含所有依赖的哈希
    --no-hashes               # 在生成的输出中省略哈希
    --output-file(-o): path   # 将导出的要求写入给定的文件
    --no-emit-project         # 不发出当前项目
    --only-emit-project       # 仅发出当前项目
    --no-emit-workspace       # 不发出任何工作区成员，包括根项目
    --only-emit-workspace     # 仅发出工作区成员，包括根项目
    --no-emit-local           # 不在导出的要求中包含本地路径依赖
    --only-emit-local         # 仅在导出的要求中包含本地路径依赖
    --no-emit-package: string@"nu-complete uv packages" # 不发出给定的包
    --only-emit-package: string@"nu-complete uv packages" # 仅发出给定的包
    --locked                  # 断言 `uv.lock` 将保持不变
    --frozen                  # 导出前不更新 `uv.lock`
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --script: path            # 导出指定 PEP 723 Python 脚本的依赖，而不是当前项目
    --python(-p): string      # 解析期间使用的 Python 解释器
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示项目的依赖树
  export extern "uv tree" [
    --universal               # 显示与平台无关的依赖树
    --depth(-d): string       # 依赖树的最大显示深度
    --prune: string           # 从依赖树显示中修剪给定的包
    --package: string         # 仅显示指定的包
    --no-dedupe               # 不去重重复的依赖通常，当一个包已经显示其依赖时，进一步出现的依赖将不会重新显示其依赖，并将包含 (*) 以指示它已被显示此标志将导致这些重复项被重复
    --invert                  # 显示给定包的反向依赖此标志将反转树并显示依赖于给定包的包
    --outdated                # 显示树中每个包的最新可用版本
    --show-sizes              # 显示树中包的压缩 wheel 大小
    --dev                     # 包含开发依赖组
    --only-dev                # 仅包含开发依赖组
    --no-dev                  # 禁用开发依赖组
    --group: string@"nu-complete uv groups"           # 包含指定依赖组的依赖
    --no-group: string@"nu-complete uv groups"        # 禁用指定的依赖组
    --no-default-groups       # 忽略默认依赖组
    --only-group: string@"nu-complete uv groups"      # 仅包含指定依赖组的依赖
    --all-groups              # 包含所有依赖组的依赖
    --locked                  # 断言 `uv.lock` 将保持不变
    --frozen                  # 显示要求而不锁定项目
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --script: path            # 显示指定 PEP 723 Python 脚本的依赖树，而不是当前项目
    --python-version: string  # 过滤树时要使用的 Python 版本
    --python-platform: string@"nu-complete uv python_platform" # 过滤树时要使用的平台
    --python(-p): string      # 用于锁定和过滤的 Python 解释器
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 格式化项目中的 Python 代码
  export extern "uv format" [
    --check                   # 检查文件是否已格式化而不应用更改
    --diff                    # 显示格式化更改的差异而不应用它们
    --version: string         # 用于格式化的 Ruff 版本
    ...extra_args: string     # 要传递给 Ruff 的附加参数
    --no-project              # 避免发现项目或工作区
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 运行并安装 Python 包提供的命令
  export extern "uv tool" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv tool run generate_shell_completion" [] {
    [ "bash" "elvish" "fish" "nushell" "powershell" "zsh" ]
  }

  # 运行 Python 包提供的命令
  export extern "uv tool run" [
    --from: string            # 使用给定的包提供命令
    --with(-w): string@"nu-complete uv packages"        # 运行时已安装给定的包
    --with-editable: path     # 运行时已以可编辑模式安装给定的包
    --with-requirements: path # 运行时已安装给定文件中列出的包
    --constraints(-c): path   # 使用给定的要求文件约束版本
    --build-constraints(-b): path # 构建源代码分发版时使用给定的要求文件约束构建依赖
    --overrides: path         # 使用给定的要求文件覆盖版本
    --isolated                # 在隔离的虚拟环境中运行工具，忽略任何已安装的工具
    --env-file: path          # 从 `.env` 文件加载环境变量
    --no-env-file             # 避免从 `.env` 文件读取环境变量
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --lfs                     # 从 Git 添加依赖时是否使用 Git LFS
    --python(-p): string      # 用于构建运行环境的 Python 解释器
    --show-resolution         # 是否显示任何环境修改的解析器和安装程序输出
    --python-platform: string@"nu-complete uv python_platform" # 应为其安装要求的平台
    --generate-shell-completion: string@"nu-complete uv tool run generate_shell_completion"
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv tool uvx generate_shell_completion" [] {
    [ "bash" "elvish" "fish" "nushell" "powershell" "zsh" ]
  }

  # 运行 Python 包提供的命令
  export extern "uv tool uvx" [
    --from: string            # 使用给定的包提供命令
    --with(-w): string@"nu-complete uv packages"        # 运行时已安装给定的包
    --with-editable: path     # 运行时已以可编辑模式安装给定的包
    --with-requirements: path # 运行时已安装给定文件中列出的包
    --constraints(-c): path   # 使用给定的要求文件约束版本
    --build-constraints(-b): path # 构建源代码分发版时使用给定的要求文件约束构建依赖
    --overrides: path         # 使用给定的要求文件覆盖版本
    --isolated                # 在隔离的虚拟环境中运行工具，忽略任何已安装的工具
    --env-file: path          # 从 `.env` 文件加载环境变量
    --no-env-file             # 避免从 `.env` 文件读取环境变量
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --lfs                     # 从 Git 添加依赖时是否使用 Git LFS
    --python(-p): string      # 用于构建运行环境的 Python 解释器
    --show-resolution         # 是否显示任何环境修改的解析器和安装程序输出
    --python-platform: string@"nu-complete uv python_platform" # 应为其安装要求的平台
    --generate-shell-completion: string@"nu-complete uv tool uvx generate_shell_completion"
    --version(-V)             # 显示 uvx 版本
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 安装 Python 包提供的命令
  export extern "uv tool install" [
    package: string           # 要从中安装命令的包
    --from: string            # 要从中安装命令的包
    --with(-w): string@"nu-complete uv packages"        # 包含以下附加要求
    --with-requirements: path # 运行时已安装给定文件中列出的包
    --editable(-e)            # 以可编辑模式安装目标包，以便在包的源目录中进行的更改无需重新安装即可反映
    --with-editable: path     # 以可编辑模式包含给定的包
    --with-executables-from: string # 从以下包安装可执行文件
    --constraints(-c): path   # 使用给定的要求文件约束版本
    --overrides: path         # 使用给定的要求文件覆盖版本
    --excludes: path          # 使用给定的要求文件从解析中排除包
    --build-constraints(-b): path # 构建源代码分发版时使用给定的要求文件约束构建依赖
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --force                   # 强制安装工具
    --lfs                     # 从 Git 添加依赖时是否使用 Git LFS
    --python(-p): string      # 用于构建工具环境的 Python 解释器
    --python-platform: string@"nu-complete uv python_platform" # 应为其安装要求的平台
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 升级已安装的工具
  export extern "uv tool upgrade" [
    ...name: string           # 要升级的工具名称，以及可选的版本说明符
    --all                     # 升级所有工具
    --python(-p): string      # 升级工具，并指定它使用给定的 Python 解释器来构建其环境与 `--all` 一起使用以应用于所有工具
    --python-platform: string@"nu-complete uv python_platform" # 应为其安装要求的平台
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-setting-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 列出已安装的工具
  export extern "uv tool list" [
    --show-paths              # 是否显示每个工具环境和已安装可执行文件的路径
    --show-version-specifiers # 是否显示用于安装每个工具的版本说明符
    --show-with               # 是否显示与每个工具一起安装的附加要求
    --show-extras             # 是否显示与每个工具一起安装的额外要求
    --show-python             # 是否显示与每个工具关联的 Python 版本
    --python-preference: string@"nu-complete uv python_preference"
    --no-python-downloads
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 卸载工具
  export extern "uv tool uninstall" [
    ...name: string           # 要卸载的工具名称
    --all                     # 卸载所有工具
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 确保工具可执行目录在 `PATH` 中
  export extern "uv tool update-shell" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示 uv 工具目录的路径
  export extern "uv tool dir" [
    --bin                     # 显示 `uv tool` 将安装可执行文件的目录
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 管理 Python 版本和安装
  export extern "uv python" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 列出可用的 Python 安装
  export extern "uv python list" [
    request?: string          # 要过滤的 Python 请求
    --all-versions            # 列出所有 Python 版本，包括旧的补丁版本
    --all-platforms           # 列出所有平台的 Python 下载
    --all-arches              # 列出所有架构的 Python 下载
    --only-installed          # 仅显示已安装的 Python 版本
    --only-downloads          # 仅显示可用的 Python 下载
    --show-urls               # 显示可用 Python 下载的 URL
    --output-format: string@"nu-complete uv output_format" # 选择输出格式
    --python-downloads-json-url: string # 指向自定义 Python 安装的 JSON 的 URL
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 下载并安装 Python 版本
  export extern "uv python install" [
    --install-dir(-i): path   # 存储 Python 安装的目录
    --bin                     # 将 Python 可执行文件安装到 `bin` 目录
    --no-bin                  # 不在 `bin` 目录中安装 Python 可执行文件
    --registry                # 在 Windows 注册表中注册 Python 安装
    --no-registry             # 不在 Windows 注册表中注册 Python 安装
    ...targets: string        # 要安装的 Python 版本
    --mirror: string          # 设置用于下载 Python 安装的源 URL
    --pypy-mirror: string     # 设置用于下载 PyPy 安装的源 URL
    --python-downloads-json-url: string # 指向自定义 Python 安装的 JSON 的 URL
    --reinstall(-r)           # 如果已安装请求的 Python 版本，则重新安装它
    --force(-f)               # 安装期间替换现有的 Python 可执行文件
    --upgrade(-U)             # 将现有的 Python 安装升级到最新的补丁版本
    --default                 # 用作默认 Python 版本
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 升级已安装的 Python 版本
  export extern "uv python upgrade" [
    --install-dir(-i): path   # 存储 Python 安装的目录
    ...targets: string        # 要升级的 Python 次要版本
    --mirror: string          # 设置用于下载 Python 安装的源 URL
    --pypy-mirror: string     # 设置用于下载 PyPy 安装的源 URL
    --reinstall(-r)           # 如果已安装最新的 Python 补丁，则重新安装它
    --python-downloads-json-url: string # 指向自定义 Python 安装的 JSON 的 URL
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 搜索 Python 安装
  export extern "uv python find" [
    request?: string          # Python 请求
    --no-project              # 避免发现项目或工作区
    --system                  # 仅查找系统 Python 解释器
    --no-system
    --script: path            # 查找 Python 脚本的环境，而不是当前项目
    --show-version            # 显示将要使用的 Python 版本，而不是解释器的路径
    --python-downloads-json-url: string # 指向自定义 Python 安装的 JSON 的 URL
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 固定到特定的 Python 版本
  export extern "uv python pin" [
    request?: string          # Python 版本请求
    --resolved                # 写入解析的 Python 解释器路径而不是请求
    --no-resolved
    --no-project              # 避免验证 Python 固定与项目或工作区兼容
    --global                  # 更新全局 Python 版本固定
    --rm                      # 移除 Python 版本固定
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示 uv Python 安装目录
  export extern "uv python dir" [
    --bin                     # 显示 `uv python` 将安装 Python 可执行文件的目录
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 卸载 Python 版本
  export extern "uv python uninstall" [
    --install-dir(-i): path   # 安装 Python 的目录
    ...targets: string        # 要卸载的 Python 版本
    --all                     # 卸载所有托管的 Python 版本
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 确保 Python 可执行目录在 `PATH` 中
  export extern "uv python update-shell" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 使用与 pip 兼容的接口管理 Python 包
  export extern "uv pip" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv pip compile format" [] {
    [ "requirements.txt" "pylock.toml" ]
  }

  def "nu-complete uv pip compile annotation_style" [] {
    [ "line" "split" ]
  }

  def "nu-complete uv pip compile torch_backend" [] {
    [ "auto" "cpu" "cu130" "cu129" "cu128" "cu126" "cu125" "cu124" "cu123" "cu122" "cu121" "cu120" "cu118" "cu117" "cu116" "cu115" "cu114" "cu113" "cu112" "cu111" "cu110" "cu102" "cu101" "cu100" "cu92" "cu91" "cu90" "cu80" "rocm6.4" "rocm6.3" "rocm6.2.4" "rocm6.2" "rocm6.1" "rocm6.0" "rocm5.7" "rocm5.6" "rocm5.5" "rocm5.4.2" "rocm5.4" "rocm5.3" "rocm5.2" "rocm5.1.1" "rocm4.2" "rocm4.1" "rocm4.0.1" "xpu" ]
  }

  def "nu-complete uv pip compile resolver" [] {
    [ "backtracking" "legacy" ]
  }

  # 将 `requirements.in` 文件编译为 `requirements.txt` 或 `pylock.toml` 文件
  export extern "uv pip compile" [
    ...src_file: path         # 包含给定文件中列出的包
    --constraints(-c): path   # 使用给定的要求文件约束版本
    --overrides: path         # 使用给定的要求文件覆盖版本
    --excludes: path          # 使用给定的要求文件从解析中排除包
    --build-constraints(-b): path # 构建源代码分发版时使用给定的要求文件约束构建依赖
    --extra: string           # 包含指定额外名称的可选依赖；可以提供多次
    --all-extras              # 包含所有可选依赖
    --no-all-extras
    --group: string@"nu-complete uv groups"           # 从 `pyproject.toml` 安装指定的依赖组
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --no-deps                 # 忽略包依赖，而是仅将命令行上明确列出的包添加到结果要求文件
    --deps
    --output-file(-o): path   # 将编译的要求写入给定的 `requirements.txt` 或 `pylock.toml` 文件
    --format: string@"nu-complete uv pip compile format" # 应输出解析的格式
    --no-strip-extras         # 在输出文件中包含额外功能
    --strip-extras
    --no-strip-markers        # 在输出文件中包含环境标记
    --strip-markers
    --no-annotate             # 排除指示每个包来源的注释注释
    --annotate
    --no-header               # 排除生成的输出文件顶部的注释标头
    --header
    --annotation-style: string@"nu-complete uv pip compile annotation_style" # 输出文件中包含的注释注释样式，用于指示每个包的来源
    --custom-compile-command: string # 要包含在 `uv pip compile` 生成的输出文件顶部的标头注释
    --python(-p): string      # 解析期间使用的 Python 解释器
    --system                  # 将包安装到系统 Python 环境
    --no-system
    --generate-hashes         # 在输出文件中包含分发版哈希
    --no-generate-hashes
    --no-build                # 不构建源代码分发版
    --build
    --no-binary: string       # 不安装预构建的 wheel
    --only-binary: string     # 仅使用预构建的 wheel；不构建源代码分发版
    --python-version: string  # 用于解析的 Python 版本
    --python-platform: string@"nu-complete uv python_platform" # 应为其解析要求的平台
    --universal               # 执行通用解析，尝试生成与所有操作系统、架构和 Python 实现兼容的单个 `requirements.txt` 输出文件
    --no-universal
    --no-emit-package: string@"nu-complete uv packages" # 指定要从输出解析中省略的包其依赖仍将包含在解析中等同于 pip-compile 的 `--unsafe-package` 选项
    --emit-index-url          # 在生成的输出文件中包含 `--index-url` 和 `--extra-index-url` 条目
    --no-emit-index-url
    --emit-find-links         # 在生成的输出文件中包含 `--find-links` 条目
    --no-emit-find-links
    --emit-build-options      # 在生成的输出文件中包含 `--no-binary` 和 `--only-binary` 条目
    --no-emit-build-options
    --emit-marker-expression  # 是否发出标记字符串，指示何时已知结果固定的依赖集是有效的
    --no-emit-marker-expression
    --emit-index-annotation   # 包含注释注释，指示用于解析每个包的索引（例如 `# from https://pypi.org/simple`）
    --no-emit-index-annotation
    --torch-backend: string@"nu-complete uv pip compile torch_backend" # 在 PyTorch 生态系统中获取包时要使用的后端（例如 `cpu`、`cu126` 或 `auto`）
    --allow-unsafe
    --no-allow-unsafe
    --reuse-hashes
    --no-reuse-hashes
    --resolver: string@"nu-complete uv pip compile resolver"
    --max-rounds: string
    --cert: string
    --client-cert: string
    --emit-trusted-host
    --no-emit-trusted-host
    --config: string
    --no-config
    --emit-options
    --no-emit-options
    --pip-args: string
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv pip sync torch_backend" [] {
    [ "auto" "cpu" "cu130" "cu129" "cu128" "cu126" "cu125" "cu124" "cu123" "cu122" "cu121" "cu120" "cu118" "cu117" "cu116" "cu115" "cu114" "cu113" "cu112" "cu111" "cu110" "cu102" "cu101" "cu100" "cu92" "cu91" "cu90" "cu80" "rocm6.4" "rocm6.3" "rocm6.2.4" "rocm6.2" "rocm6.1" "rocm6.0" "rocm5.7" "rocm5.6" "rocm5.5" "rocm5.4.2" "rocm5.4" "rocm5.3" "rocm5.2" "rocm5.1.1" "rocm4.2" "rocm4.1" "rocm4.0.1" "xpu" ]
  }

  # 使用 `requirements.txt` 或 `pylock.toml` 文件同步环境
  export extern "uv pip sync" [
    ...src_file: path         # 包含给定文件中列出的包
    --constraints(-c): path   # 使用给定的要求文件约束版本
    --build-constraints(-b): path # 构建源代码分发版时使用给定的要求文件约束构建依赖
    --extra: string           # 包含指定额外名称的可选依赖；可以提供多次
    --all-extras              # 包含所有可选依赖
    --no-all-extras
    --group: string@"nu-complete uv groups"           # 从 `pylock.toml` 或 `pyproject.toml` 安装指定的依赖组
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --require-hashes          # 要求每个要求都有匹配的哈希
    --no-require-hashes
    --verify-hashes
    --no-verify-hashes        # 禁用要求文件中哈希的验证
    --python(-p): string      # 应将包安装到的 Python 解释器
    --system                  # 将包安装到系统 Python 环境
    --no-system
    --break-system-packages   # 允许 uv 修改 `EXTERNALLY-MANAGED` Python 安装
    --no-break-system-packages
    --target: path            # 将包安装到指定的目录，而不是虚拟或系统 Python 环境包将安装在目录的顶级
    --prefix: path            # 将包安装到指定目录下的 `lib`、`bin` 和其他顶级文件夹，就像在该位置存在虚拟环境一样
    --no-build                # 不构建源代码分发版
    --build
    --no-binary: string       # 不安装预构建的 wheel
    --only-binary: string     # 仅使用预构建的 wheel；不构建源代码分发版
    --allow-empty-requirements # 允许空要求的同步，这将清除环境中的所有包
    --no-allow-empty-requirements
    --python-version: string  # 要求应支持的最低 Python 版本（例如 `3.7` 或 `3.7.9`）
    --python-platform: string@"nu-complete uv python_platform" # 应为其安装要求的平台
    --strict                  # 完成安装后验证 Python 环境，以检测具有缺失依赖或其他问题的包
    --no-strict
    --dry-run                 # 执行试运行，即不实际安装任何内容，而是解析依赖并打印结果计划
    --torch-backend: string@"nu-complete uv pip sync torch_backend" # 在 PyTorch 生态系统中获取包时要使用的后端（例如 `cpu`、`cu126` 或 `auto`）
    --ask(-a)
    --python-executable: string
    --user
    --cert: string
    --client-cert: string
    --config: string
    --no-config
    --pip-args: string
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv pip install torch_backend" [] {
    [ "auto" "cpu" "cu130" "cu129" "cu128" "cu126" "cu125" "cu124" "cu123" "cu122" "cu121" "cu120" "cu118" "cu117" "cu116" "cu115" "cu114" "cu113" "cu112" "cu111" "cu110" "cu102" "cu101" "cu100" "cu92" "cu91" "cu90" "cu80" "rocm6.4" "rocm6.3" "rocm6.2.4" "rocm6.2" "rocm6.1" "rocm6.0" "rocm5.7" "rocm5.6" "rocm5.5" "rocm5.4.2" "rocm5.4" "rocm5.3" "rocm5.2" "rocm5.1.1" "rocm4.2" "rocm4.1" "rocm4.0.1" "xpu" ]
  }

  # 将包安装到环境中
  export extern "uv pip install" [
    ...package: string        # 安装所有列出的包
    --requirements(-r): path  # 安装给定文件中列出的包
    --editable(-e): string    # 基于提供的本地文件路径安装可编辑包
    --constraints(-c): path   # 使用给定的要求文件约束版本
    --overrides: path         # 使用给定的要求文件覆盖版本
    --excludes: path          # 使用给定的要求文件从解析中排除包
    --build-constraints(-b): path # 构建源代码分发版时使用给定的要求文件约束构建依赖
    --extra: string           # 包含指定额外名称的可选依赖；可以提供多次
    --all-extras              # 包含所有可选依赖
    --no-all-extras
    --group: string@"nu-complete uv groups"           # 从 `pylock.toml` 或 `pyproject.toml` 安装指定的依赖组
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --reinstall               # 重新安装所有包，无论它们是否已安装暗示 `--refresh`
    --no-reinstall
    --reinstall-package: string@"nu-complete uv packages" # 重新安装特定包，无论它是否已安装暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --compile-bytecode        # 安装后将 Python 文件编译为字节码
    --no-compile-bytecode
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --no-deps                 # 忽略包依赖，而是仅安装命令行或要求文件中明确列出的包
    --deps
    --require-hashes          # 要求每个要求都有匹配的哈希
    --no-require-hashes
    --verify-hashes
    --no-verify-hashes        # 禁用要求文件中哈希的验证
    --python(-p): string      # 应将包安装到的 Python 解释器
    --system                  # 将包安装到系统 Python 环境
    --no-system
    --break-system-packages   # 允许 uv 修改 `EXTERNALLY-MANAGED` Python 安装
    --no-break-system-packages
    --target: path            # 将包安装到指定的目录，而不是虚拟或系统 Python 环境包将安装在目录的顶级
    --prefix: path            # 将包安装到指定目录下的 `lib`、`bin` 和其他顶级文件夹，就像在该位置存在虚拟环境一样
    --no-build                # 不构建源代码分发版
    --build
    --no-binary: string       # 不安装预构建的 wheel
    --only-binary: string     # 仅使用预构建的 wheel；不构建源代码分发版
    --python-version: string  # 要求应支持的最低 Python 版本（例如 `3.7` 或 `3.7.9`）
    --python-platform: string@"nu-complete uv python_platform" # 应为其安装要求的平台
    --inexact                 # 不移除环境中存在的无关包
    --exact                   # 执行精确同步，移除无关包
    --strict                  # 完成安装后验证 Python 环境，以检测具有缺失依赖或其他问题的包
    --no-strict
    --dry-run                 # 执行试运行，即不实际安装任何内容，而是解析依赖并打印结果计划
    --torch-backend: string@"nu-complete uv pip install torch_backend" # 在 PyTorch 生态系统中获取包时要使用的后端（例如 `cpu`、`cu126` 或 `auto`）
    --disable-pip-version-check
    --user
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 从环境中卸载包
  export extern "uv pip uninstall" [
    ...package: string@"nu-complete uv packages"        # 卸载所有列出的包
    --requirements(-r): path  # 卸载给定文件中列出的包
    --python(-p): string      # 应从中卸载包的 Python 解释器
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行远程要求文件的身份验证
    --system                  # 使用系统 Python 卸载包
    --no-system
    --break-system-packages   # 允许 uv 修改 `EXTERNALLY-MANAGED` Python 安装
    --no-break-system-packages
    --target: path            # 从指定的 `--target` 目录卸载包
    --prefix: path            # 从指定的 `--prefix` 目录卸载包
    --dry-run                 # 执行试运行，即不实际卸载任何内容，而是打印结果计划
    --disable-pip-version-check
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 以 requirements 格式列出环境中安装的包
  export extern "uv pip freeze" [
    --exclude-editable        # 从输出中排除任何可编辑包
    --strict                  # 验证 Python 环境，以检测具有缺失依赖和其他问题的包
    --no-strict
    --python(-p): string      # 应为其列出包的 Python 解释器
    --path: path              # 限制到指定的安装路径以列出包（可以使用多次）
    --system                  # 列出系统 Python 环境中的包
    --no-system
    --target: path            # 列出来自指定的 `--target` 目录的包
    --prefix: path            # 列出来自指定的 `--prefix` 目录的包
    --disable-pip-version-check
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv pip list format" [] {
    [ "columns" "freeze" "json" ]
  }

  # 以表格格式列出环境中安装的包
  export extern "uv pip list" [
    --editable(-e)            # 仅包含可编辑项目
    --exclude-editable        # 从输出中排除任何可编辑包
    --exclude: string         # 从输出中排除指定的包
    --format: string@"nu-complete uv pip list format" # 选择输出格式
    --outdated                # 列出过时的包
    --no-outdated
    --strict                  # 验证 Python 环境，以检测具有缺失依赖和其他问题的包
    --no-strict
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --python(-p): string      # 应为其列出包的 Python 解释器
    --system                  # 列出系统 Python 环境中的包
    --no-system
    --target: path            # 列出来自指定的 `--target` 目录的包
    --prefix: path            # 列出来自指定的 `--prefix` 目录的包
    --disable-pip-version-check
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示一个或多个已安装包的信息
  export extern "uv pip show" [
    ...package: string@"nu-complete uv packages"        # 要显示的包
    --strict                  # 验证 Python 环境，以检测具有缺失依赖和其他问题的包
    --no-strict
    --files(-f)               # 显示每个包的已安装文件的完整列表
    --python(-p): string      # 要在其中查找包的 Python 解释器
    --system                  # 显示系统 Python 环境中的包
    --no-system
    --target: path            # 显示来自指定的 `--target` 目录的包
    --prefix: path            # 显示来自指定的 `--prefix` 目录的包
    --disable-pip-version-check
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示环境的依赖树
  export extern "uv pip tree" [
    --show-version-specifiers # 显示对每个包施加的版本约束
    --depth(-d): string       # 依赖树的最大显示深度
    --prune: string           # 从依赖树显示中修剪给定的包
    --package: string         # 仅显示指定的包
    --no-dedupe               # 不去重重复的依赖通常，当一个包已经显示其依赖时，进一步出现的依赖将不会重新显示其依赖，并将包含 (*) 以指示它已被显示此标志将导致这些重复项被重复
    --invert                  # 显示给定包的反向依赖此标志将反转树并显示依赖于给定包的包
    --outdated                # 显示树中每个包的最新可用版本
    --show-sizes              # 显示树中包的压缩 wheel 大小
    --strict                  # 验证 Python 环境，以检测具有缺失依赖和其他问题的包
    --no-strict
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --python(-p): string      # 应为其列出包的 Python 解释器
    --system                  # 列出系统 Python 环境中的包
    --no-system
    --disable-pip-version-check
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 验证已安装的包具有兼容的依赖
  export extern "uv pip check" [
    --python(-p): string      # 应为其检查包的 Python 解释器
    --system                  # 检查系统 Python 环境中的包
    --no-system
    --python-version: string  # 应针对其检查包的 Python 版本
    --python-platform: string@"nu-complete uv python_platform" # 应为其检查包的平台
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示调试信息（不支持）
  export extern "uv pip debug" [
    --platform: string
    --python-version: string
    --implementation: string
    --abi: string
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 创建虚拟环境
  export extern "uv venv" [
    --python(-p): string      # 用于虚拟环境的 Python 解释器
    --system                  # 搜索 Python 解释器时忽略虚拟环境
    --no-system               # 此标志仅包含用于兼容性，没有效果
    --no-project              # 避免发现项目或工作区
    --seed                    # 将种子包（`pip`、`setuptools` 和 `wheel` 中的一个或多个）安装到虚拟环境
    --clear(-c)               # 移除目标路径处的任何现有文件或目录
    --no-clear                # 如果目标路径存在任何现有文件或目录，则失败而不提示
    --allow-existing          # 保留目标路径处的任何现有文件或目录
    path?: path               # 要创建的虚拟环境的路径
    --prompt: string          # 为虚拟环境提供替代的提示前缀
    --system-site-packages    # 授予虚拟环境对系统 site-packages 目录的访问权限
    --relocatable             # 使虚拟环境可重定位
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --no-seed
    --no-pip
    --no-setuptools
    --no-wheel
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 将 Python 包构建为源代码分发版和 wheel
  export extern "uv build" [
    src?: path                # 应从中构建立分发版的目录，或要构建为 wheel 的源代码分发版归档
    --package: string         # 构建工作区中的特定包
    --all-packages            # 构建工作区中的所有包
    --out-dir(-o): path       # 分发版应写入的输出目录
    --sdist                   # 从给定目录构建源代码分发版（"sdist"）
    --wheel                   # 从给定目录构建二进制分发版（"wheel"）
    --list                    # 使用 uv 构建后端时，列出构建时将包含的文件
    --build-logs
    --no-build-logs           # 隐藏构建后端的日志
    --force-pep517            # 始终通过 PEP 517 构建，不要使用 uv 构建后端的快速路径
    --clear                   # 构建前清除输出目录，移除陈旧的工件
    --create-gitignore
    --no-create-gitignore     # 不在输出目录中创建 `.gitignore` 文件
    --build-constraints(-b): path # 构建分发版时使用给定的要求文件约束构建依赖
    --require-hashes          # 要求每个要求都有匹配的哈希
    --no-require-hashes
    --verify-hashes
    --no-verify-hashes        # 禁用要求文件中哈希的验证
    --python(-p): string      # 用于构建环境的 Python 解释器
    --index: string           # 解析依赖时要使用的 URL，除默认索引外
    --default-index: string   # 默认包索引的 URL（默认: <https://pypi.org/simple>）
    --index-url(-i): string   # （已弃用: 请改用 `--default-index`）Python 包索引的 URL（默认: <https://pypi.org/simple>）
    --extra-index-url: string # （已弃用: 请改用 `--index`）除 `--index-url` 外要使用的额外包索引 URL
    --find-links(-f): string  # 除注册表索引中找到的候选分发版外，要搜索的位置
    --no-index                # 忽略注册表索引（例如 PyPI），而是依赖直接 URL 依赖和通过 `--find-links` 提供的依赖
    --upgrade(-U)             # 允许包升级，忽略任何现有输出文件中的固定版本暗示 `--refresh`
    --no-upgrade
    --upgrade-package(-P): string@"nu-complete uv packages" # 允许特定包的升级，忽略任何现有输出文件中的固定版本暗示 `--refresh-package`
    --index-strategy: string@"nu-complete uv index_strategy" # 针对多个索引 URL 解析时要使用的策略
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行索引 URL 的身份验证
    --resolution: string@"nu-complete uv resolution" # 为给定包要求在不同兼容版本之间选择时要使用的策略
    --prerelease: string@"nu-complete uv prerelease" # 考虑预发布版本时要使用的策略
    --pre
    --fork-strategy: string@"nu-complete uv fork_strategy" # 在 Python 版本和平台之间选择给定包的多个版本时要使用的策略
    --config-setting(-C): string # 传递给 PEP 517 构建后端的设置，指定为 `KEY=VALUE` 对
    --config-settings-package: string@"nu-complete uv packages" # 传递给特定包的 PEP 517 构建后端的设置，指定为 `PACKAGE:KEY=VALUE` 对
    --no-build-isolation      # 构建源代码分发版时禁用隔离
    --no-build-isolation-package: string@"nu-complete uv packages" # 为特定包构建源代码分发版时禁用隔离
    --build-isolation
    --exclude-newer: string   # 将候选包限制为在给定日期之前上传的包
    --exclude-newer-package: string@"nu-complete uv packages" # 将特定包的候选包限制为在给定日期之前上传的包
    --link-mode: string@"nu-complete uv link_mode" # 从全局缓存安装包时要使用的方法
    --no-sources              # 解析依赖时忽略 `tool.uv.sources` 表用于锁定符合标准的可发布包元数据，而不是使用任何工作区、Git、URL 或本地路径源
    --no-build                # 不构建源代码分发版
    --build
    --no-build-package: string@"nu-complete uv packages" # 不为特定包构建源代码分发版
    --no-binary               # 不安装预构建的 wheel
    --binary
    --no-binary-package: string@"nu-complete uv packages" # 不为特定包安装预构建的 wheel
    --refresh                 # 刷新所有缓存数据
    --no-refresh
    --refresh-package: string@"nu-complete uv packages" # 刷新特定包的缓存数据
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv publish trusted_publishing" [] {
    [ "automatic" "always" "never" ]
  }

  # 将分发版上传到索引
  export extern "uv publish" [
    ...files: path            # 要上传的文件的路径接受 glob 表达式
    --index: string           # 配置中用于发布的索引名称
    --username(-u): string    # 上传的用户名
    --password(-p): string    # 上传的密码
    --token(-t): string       # 上传的令牌
    --trusted-publishing: string@"nu-complete uv publish trusted_publishing" # 配置可信发布
    --keyring-provider: string@"nu-complete uv keyring_provider" # 尝试使用 `keyring` 进行远程要求文件的身份验证
    --publish-url: string     # 上传端点的 URL（不是索引 URL）
    --check-url: string       # 检查索引 URL 中是否存在现有文件以跳过重复上传
    --skip-existing
    --dry-run                 # 执行试运行而不上传文件
    --no-attestations         # 不上传已发布文件的证明
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 检查 uv 工作区
  export extern "uv workspace" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 查看当前工作区的元数据
  export extern "uv workspace metadata" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示工作区成员的路径
  export extern "uv workspace dir" [
    --package: string         # 显示工作区中特定包的路径
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 列出工作区的成员
  export extern "uv workspace list" [
    --paths                   # 显示路径而不是名称
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 构建后端的实现
  export extern "uv build-backend" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # PEP 517 钩子 `build_sdist`
  export extern "uv build-backend build-sdist" [
    sdist_directory: path
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # PEP 517 钩子 `build_wheel`
  export extern "uv build-backend build-wheel" [
    wheel_directory: path
    --metadata-directory: path
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # PEP 660 钩子 `build_editable`
  export extern "uv build-backend build-editable" [
    wheel_directory: path
    --metadata-directory: path
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # PEP 517 钩子 `get_requires_for_build_sdist`
  export extern "uv build-backend get-requires-for-build-sdist" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # PEP 517 钩子 `get_requires_for_build_wheel`
  export extern "uv build-backend get-requires-for-build-wheel" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # PEP 517 钩子 `prepare_metadata_for_build_wheel`
  export extern "uv build-backend prepare-metadata-for-build-wheel" [
    wheel_directory: path
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # PEP 660 钩子 `get_requires_for_build_editable`
  export extern "uv build-backend get-requires-for-build-editable" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # PEP 660 钩子 `prepare_metadata_for_build_editable`
  export extern "uv build-backend prepare-metadata-for-build-editable" [
    wheel_directory: path
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 管理 uv 的缓存
  export extern "uv cache" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 清除缓存，删除所有条目或与特定包相关的条目
  export extern "uv cache clean" [
    ...package: string        # 要从缓存中移除的包
    --force                   # 强制移除缓存，忽略正在使用的检查
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 从缓存中删除所有不可达对象
  export extern "uv cache prune" [
    --ci                      # 优化缓存以在持续集成环境（如 GitHub Actions）中持久化
    --force                   # 强制移除缓存，忽略正在使用的检查
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示缓存目录
  export extern "uv cache dir" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示缓存大小
  export extern "uv cache size" [
    --human(-H)               # 以人类可读的格式显示缓存大小（例如 `1.2 GiB` 而不是原始字节）
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 管理 uv 可执行文件
  export extern "uv self" [
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 更新 uv
  export extern "uv self update" [
    target_version?: string   # 更新到指定的版本如果未提供，uv 将更新到最新版本
    --token: string           # 用于身份验证的 GitHub 令牌令牌不是必需的，但可用于减少遇到速率限制的机会
    --dry-run                 # 运行而不执行更新
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 显示 uv 的版本
  export extern "uv self version" [
    --short                   # 仅打印版本
    --output-format: string@"nu-complete uv output_format"
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  # 清除缓存，删除所有条目或与特定包相关的条目
  export extern "uv clean" [
    ...package: string        # 要从缓存中移除的包
    --force                   # 强制移除缓存，忽略正在使用的检查
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

  def "nu-complete uv generate-shell-completion shell" [] {
    [ "bash" "elvish" "fish" "nushell" "powershell" "zsh" ]
  }

  # 生成 shell 补全
  export extern "uv generate-shell-completion" [
    shell: string@"nu-complete uv generate-shell-completion shell" # 要为其生成补全脚本的 shell
    --no-cache(-n)
    --cache-dir: path
    --python-preference: string@"nu-complete uv python_preference"
    --no-python-downloads
    --quiet(-q)
    --verbose(-v)
    --color: string@"nu-complete uv color"
    --native-tls
    --offline
    --no-progress
    --config-file: path
    --no-config
    --help(-h)
    --version(-V)
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --no-color                # 禁用颜色
    --no-native-tls
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
  ]

  # 显示命令的文档
  export extern "uv help" [
    --no-pager                # 打印帮助时禁用分页器
    ...command: string
    --no-cache(-n)            # 避免从缓存读取或写入缓存，而是在操作期间使用临时目录
    --cache-dir: path         # 缓存目录的路径
    --python-preference: string@"nu-complete uv python_preference"
    --managed-python          # 要求使用 uv 管理的 Python 版本
    --no-managed-python       # 禁用 uv 管理的 Python 版本
    --allow-python-downloads  # 允许在需要时自动下载 Python[环境变量: "UV_PYTHON_DOWNLOADS=auto"]
    --no-python-downloads     # 禁用 Python 的自动下载[环境变量: "UV_PYTHON_DOWNLOADS=never"]
    --python-fetch: string@"nu-complete uv python_fetch" # [`Self::python_downloads`] 的已弃用版本
    --quiet(-q)               # 使用静默输出
    --verbose(-v)             # 使用详细输出
    --no-color                # 禁用颜色
    --color: string@"nu-complete uv color" # 控制输出中颜色的使用
    --native-tls              # 是否从平台的原生证书存储加载 TLS 证书
    --no-native-tls
    --offline                 # 禁用网络访问
    --no-offline
    --allow-insecure-host: string # 允许与主机的不安全连接
    --preview                 # 是否启用所有实验性预览功能
    --no-preview
    --preview-features: string # 启用实验性预览功能
    --isolated                # 避免发现 `pyproject.toml` 或 `uv.toml` 文件
    --show-settings           # 显示当前命令的解析设置
    --no-progress             # 隐藏所有进度输出
    --no-installer-metadata   # 跳过将 `uv` 安装程序元数据文件（例如 `INSTALLER`、`REQUESTED` 和 `direct_url.json`）写入 site-packages `.dist-info` 目录
    --directory: path         # 在运行命令之前切换到给定目录
    --project: path           # 在给定目录中发现项目
    --config-file: path       # 用于配置的 `uv.toml` 文件的路径
    --no-config               # 避免发现配置文件（`pyproject.toml`、`uv.toml`）
    --help(-h)                # 显示此命令的简洁帮助
  ]

}

export use completions *
