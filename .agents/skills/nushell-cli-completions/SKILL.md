---
name: nushell-cli-completions
description: 为外部 CLI 编写 Nushell (nu) 命令补全脚本。要求：只显示完整命令、所有命令使用 export 导出、候选支持 value+description、参数帮助用注释表达。
---

# Nushell 外部 CLI 补全工作流

## 目标

- 生成可加载的 `*.nu` 补全脚本
- 候选项支持 `value` + `description`
- 参数帮助用签名内注释表达，命令描述放在定义上方注释
- 策略：固定只显示完整命令

## 快速流程

1) **收集 CLI 信息**：通过 `<cmd> --help` 和子命令 help 遍历所有级次，理清参数与枚举值。

2) **定义 Completer**：为枚举值、子命令参数（如 help 后的命令名）定义补全函数。候选建议使用记录列表格式：`{ value: ..., description: ... }`。

```nu
def "nu-complete demo sort" [] {
  [
    { value: "recent", description: "按最近时间排序" }
    { value: "name", description: "按名称排序" }
  ]
}
```

3) **编写命令签名**：
   - 为每一个层级（包括叶子命令）定义 `export extern "cmd sub ..."`。
   - 顶层命令 `export extern "cmd"` 仅保留全局 flags。
   - 命令说明位于 `export extern` 上方注释。
   - 参数说明位于参数行尾 `#` 注释。
   - **禁止**在主命令中使用 `subcommand: string` 或 `subcommand?: string` 作为子命令占位符，这会干扰 Nushell 对子命令签名的识别。

```nu
# 显示帮助
export extern "mycli help" [
  topic: string@"nu-complete mycli topics" # 帮助主题
  --help(-h) # 显示帮助
]
```

## 关键约定

- **总是使用 export**: 所有命令签名必须以 `export extern` 开头，否则外部无法识别。
- **说明分离**: 参数说明在行尾，命令说明在上方。不要将 flags 混入位置参数的候选列表中。
- **只显示完整命令**: 通过为每个层级定义独立的 `export extern` 实现，确保补全列表展示的是具体的命令路径。
- **防止文件回退**: 对于不需要文件补全的参数（包括可选参数），可以使用 `string@[]` 显式屏蔽 Nushell 默认的文件补全回退。

## 异常排查

- **NO RECORDS FOUND**: 检查顶层签名是否包含不必要的位置参数，或与 CLI 实际语法不符。
- **补全为文件路径**: 检查位置参数是否缺少 `@completer` 声明；确认是否需要使用 `@[]` 屏蔽默认文件补全。
- **补全列表混乱**: 检查是否误将 flags 塞进了位置参数的候选列表中。

