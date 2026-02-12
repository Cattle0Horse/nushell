# openspec nushell completions
# openspec version: 1.1.1
# nushell version: 0.110.0

def "nu-complete openspec completion shells" [] {
  [
    { value: "zsh", description: "Zsh" }
    { value: "bash", description: "Bash" }
    { value: "fish", description: "Fish" }
    { value: "powershell", description: "PowerShell" }
  ]
}

def "nu-complete openspec commands" [] {
  [
    { value: "init", description: "初始化项目" }
    { value: "update", description: "更新指令文件" }
    { value: "list", description: "列出 changes 或 specs" }
    { value: "view", description: "交互式面板" }
    { value: "change", description: "管理 change 提案" }
    { value: "archive", description: "归档 change 并更新 specs" }
    { value: "spec", description: "管理和查看 specs" }
    { value: "config", description: "查看或修改全局配置" }
    { value: "schema", description: "管理 workflow schema" }
    { value: "validate", description: "校验 change 或 spec" }
    { value: "show", description: "展示 change 或 spec" }
    { value: "feedback", description: "提交反馈" }
    { value: "completion", description: "管理补全脚本" }
    { value: "status", description: "展示 artifact 完成状态" }
    { value: "instructions", description: "输出任务指令" }
    { value: "templates", description: "显示模板路径" }
    { value: "schemas", description: "列出可用 schema" }
    { value: "new", description: "创建新条目" }
    { value: "help", description: "显示帮助" }
  ]
}

def "nu-complete openspec list sort" [] {
  [
    { value: "recent", description: "按最近时间排序" }
    { value: "name", description: "按名称排序" }
  ]
}

def "nu-complete openspec type" [] {
  [
    { value: "change", description: "change 项" }
    { value: "spec", description: "spec 项" }
  ]
}

def "nu-complete openspec config scope" [] {
  [
    { value: "global", description: "全局配置" }
  ]
}

def "nu-complete openspec init tools" [] {
  [
    { value: "all", description: "启用全部工具" }
    { value: "none", description: "不启用工具" }
    { value: "amazon-q", description: "Amazon Q" }
    { value: "antigravity", description: "Antigravity" }
    { value: "auggie", description: "Auggie" }
    { value: "claude", description: "Claude" }
    { value: "cline", description: "Cline" }
    { value: "codex", description: "Codex" }
    { value: "codebuddy", description: "CodeBuddy" }
    { value: "continue", description: "Continue" }
    { value: "costrict", description: "Costrict" }
    { value: "crush", description: "Crush" }
    { value: "cursor", description: "Cursor" }
    { value: "factory", description: "Factory" }
    { value: "gemini", description: "Gemini" }
    { value: "github-copilot", description: "GitHub Copilot" }
    { value: "iflow", description: "iFlow" }
    { value: "kilocode", description: "KiloCode" }
    { value: "opencode", description: "OpenCode" }
    { value: "qoder", description: "Qoder" }
    { value: "qwen", description: "Qwen" }
    { value: "roocode", description: "RooCode" }
    { value: "trae", description: "Trae" }
    { value: "windsurf", description: "Windsurf" }
  ]
}

def "nu-complete openspec schema artifacts" [] {
  [
    { value: "proposal", description: "提案" }
    { value: "specs", description: "规格" }
    { value: "design", description: "设计" }
    { value: "tasks", description: "任务" }
  ]
}

# 用于规范驱动开发的 AI 原生系统
export extern "openspec" [
  --no-color # 禁用颜色输出
  --version(-V) # 显示版本
  --help(-h) # 显示帮助
]

# 初始化项目
export extern "openspec init" [
  path?: string # 项目路径
  --tools: string@"nu-complete openspec init tools" # 指定工具
  --force # 强制清理旧文件
  --help(-h) # 显示帮助
]

# 更新指令文件
export extern "openspec update" [
  path?: string # 项目路径
  --force # 强制更新
  --help(-h) # 显示帮助
]

# 列出 changes 或 specs
export extern "openspec list" [
  --specs # 列出 specs
  --changes # 列出 changes
  --sort: string@"nu-complete openspec list sort" # 排序方式
  --json # JSON 输出
  --help(-h) # 显示帮助
]

# 交互式面板
export extern "openspec view" [
  --help(-h) # 显示帮助
]

# 管理 change 提案
export extern "openspec change" [
  --help(-h) # 显示帮助
]

# 展示 change
export extern "openspec change show" [
  change_name?: string # change 名称
  --json # JSON 输出
  --deltas-only # 仅差异
  --requirements-only # 仅需求
  --no-interactive # 禁用交互
  --help(-h) # 显示帮助
]

# 列出 changes
export extern "openspec change list" [
  --help(-h) # 显示帮助
]

# 校验 change
export extern "openspec change validate" [
  change_name?: string # change 名称
  --strict # 严格模式
  --json # JSON 输出
  --no-interactive # 禁用交互
  --help(-h) # 显示帮助
]

# 归档 change 并更新 specs
export extern "openspec archive" [
  change_name?: string # change 名称
  --yes(-y) # 跳过确认
  --skip-specs # 跳过 spec 更新
  --no-validate # 跳过校验
  --help(-h) # 显示帮助
]

# 管理和查看 specs
export extern "openspec spec" [
  --help(-h) # 显示帮助
]

# 展示 spec
export extern "openspec spec show" [
  spec_id?: string # spec ID
  --json # JSON 输出
  --requirements # 仅需求
  --no-scenarios # 不含场景
  --requirement(-r): int # 指定需求 ID
  --no-interactive # 禁用交互
  --help(-h) # 显示帮助
]

# 列出 specs
export extern "openspec spec list" [
  --json # JSON 输出
  --long # 显示详细信息
  --help(-h) # 显示帮助
]

# 校验 spec
export extern "openspec spec validate" [
  spec_id?: string # spec ID
  --strict # 严格模式
  --json # JSON 输出
  --no-interactive # 禁用交互
  --help(-h) # 显示帮助
]

# 查看或修改全局配置
export extern "openspec config" [
  --scope: string@"nu-complete openspec config scope" # 作用域
  --help(-h) # 显示帮助
]

# 显示配置路径
export extern "openspec config path" [
  --help(-h) # 显示帮助
]

# 列出配置
export extern "openspec config list" [
  --json # JSON 输出
  --help(-h) # 显示帮助
]

# 读取配置
export extern "openspec config get" [
  key: string # 键
  --help(-h) # 显示帮助
]

# 设置配置
export extern "openspec config set" [
  key: string # 键
  value: string # 值
  --string # 强制字符串
  --allow-unknown # 允许未知键
  --help(-h) # 显示帮助
]

# 移除配置
export extern "openspec config unset" [
  key: string # 键
  --help(-h) # 显示帮助
]

# 重置配置
export extern "openspec config reset" [
  --all # 重置全部
  --yes(-y) # 跳过确认
  --help(-h) # 显示帮助
]

# 打开配置文件
export extern "openspec config edit" [
  --help(-h) # 显示帮助
]

# 管理 workflow schema
export extern "openspec schema" [
  --help(-h) # 显示帮助
]

# 查看 schema 来源
export extern "openspec schema which" [
  name?: string # schema 名称
  --json # JSON 输出
  --all # 列出全部
  --help(-h) # 显示帮助
]

# 校验 schema
export extern "openspec schema validate" [
  name?: string # schema 名称
  --json # JSON 输出
  --verbose # 显示细节
  --help(-h) # 显示帮助
]

# 复制并自定义 schema
export extern "openspec schema fork" [
  source: string # 源 schema
  name?: string # 新名称
  --json # JSON 输出
  --force # 覆盖已有
  --help(-h) # 显示帮助
]

# 创建项目 schema
export extern "openspec schema init" [
  name: string # schema 名称
  --json # JSON 输出
  --description: string # 描述
  --artifacts: string@"nu-complete openspec schema artifacts" # artifact 列表
  --default # 设为默认
  --no-default # 不设为默认
  --force # 覆盖已有
  --help(-h) # 显示帮助
]

# 校验 change 或 spec
export extern "openspec validate" [
  item_name?: string # 条目名称
  --all # 校验全部
  --changes # 校验 changes
  --specs # 校验 specs
  --type: string@"nu-complete openspec type" # 指定类型
  --strict # 严格模式
  --json # JSON 输出
  --concurrency: int # 并发数
  --no-interactive # 禁用交互
  --help(-h) # 显示帮助
]

# 展示 change 或 spec
export extern "openspec show" [
  item_name?: string # 条目名称
  --json # JSON 输出
  --type: string@"nu-complete openspec type" # 指定类型
  --no-interactive # 禁用交互
  --deltas-only # 仅差异
  --requirements-only # 仅需求
  --requirements # 仅需求
  --no-scenarios # 不含场景
  --requirement(-r): int # 指定需求 ID
  --help(-h) # 显示帮助
]

# 提交反馈
export extern "openspec feedback" [
  message: string # 简要信息
  --body: string # 详细描述
  --help(-h) # 显示帮助
]

# 管理补全脚本
export extern "openspec completion" [
  --help(-h) # 显示帮助
]

# 生成补全脚本
export extern "openspec completion generate" [
  shell?: string@"nu-complete openspec completion shells" # shell 类型
  --help(-h) # 显示帮助
]

# 安装补全脚本
export extern "openspec completion install" [
  shell?: string@"nu-complete openspec completion shells" # shell 类型
  --help(-h) # 显示帮助
]

# 卸载补全脚本
export extern "openspec completion uninstall" [
  shell?: string@"nu-complete openspec completion shells" # shell 类型
  --help(-h) # 显示帮助
]

# 展示 artifact 完成状态
export extern "openspec status" [
  --change: string # change 名称
  --schema: string # schema 名称
  --json # JSON 输出
  --help(-h) # 显示帮助
]

# 输出任务指令
export extern "openspec instructions" [
  artifact?: string # artifact 名称
  --change: string # change 名称
  --schema: string # schema 名称
  --json # JSON 输出
  --help(-h) # 显示帮助
]

# 显示模板路径
export extern "openspec templates" [
  --schema: string # schema 名称
  --json # JSON 输出
  --help(-h) # 显示帮助
]

# 列出可用 schema
export extern "openspec schemas" [
  --json # JSON 输出
  --help(-h) # 显示帮助
]

# 创建新条目
export extern "openspec new" [
  --help(-h) # 显示帮助
]

# 创建 change 目录
export extern "openspec new change" [
  name: string # change 名称
  --description: string # 描述
  --schema: string # schema 名称
  --help(-h) # 显示帮助
]

# 显示帮助
export extern "openspec help" [
  command?: string@"nu-complete openspec commands" # 命令名称
  --help(-h) # 显示帮助
]
