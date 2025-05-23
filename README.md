## 配置

1. `data-dir` 作为数据目录，数据即配置。
   1. `config.nu` 作为配置文件。
   2. 涉及隐私配置的以环境变量的形式放于 `env.nu` 中（`$NU_LIB_DIRS` 除外）
   3. `$nu.data-dir/data` 作为私人数据，如每个插件的数据、api_key 等（暂时无法修改 history.txt 文件至其中）
2. 修改加载配置文件路径 `^setx XDG_CONFIG_HOME '%UserProfile%\.config'`，将会在 `$env.XDG_CONFIG_HOME\nushell` 加载配置
<!-- 环境变量设置 -->
3. 修改加载数据文件路径 `^setx XDG_DATA_HOME '%UserProfile%\.config'`，这会影响 `$nu.data-dir` 的值，同时将会在 `$env.XDG_DATA_HOME\nushell` 加载数据（默认会在 `$NU_LIB_DIRS` 加入 `$env.XDG_DATA_HOME\nushell\scripts` 和 `$env.XDG_DATA_HOME\nushell\completions`）
<!-- 注意：这样语法检查不会生效，在 config.nu 中显示指定 $NU_LIB_DIRS 比较好 -->

## 变量说明

- 特殊变量：https://www.nushell.sh/book/special_variables.html
- 启动阶段：https://www.nushell.sh/book/configuration.html#launch-stages

`$NU_LIB_DIRS` 是 `$env.NU_LIB_DIRS` 的常量版本：在使用 source、use 或 overlay use 命令时将搜索的目录列表。

## 实用

- https://www.nushell.sh/book/directory_stack.html
- `<Ctrl-R>`：查看命令历史记录
- 反引号：裸字符串无法包含空格和引号，反引号<code>`</code>用于帮助解析这种形式的命令和路径 <https://www.nushell.sh/book/working_with_strings.html#backtick-quoted-strings>
- 可以在 `env.nu` 文件中设置 `$cenv` 常量，这样就可以在脚本文件中以常量的形式定义变量了。在 vscode 的语法解释时会报错，不过并不影响实际使用

## 插件体系

- https://www.nushell.sh/book/plugins.html

## 脚本说明

- 脚本位于 scrips 目录下，尽量以文件模块的形式组织
  - 其中，`internal` 为模块内部使用的工具方法（可以是子模块，也可以是文件）
  - 不做过多的检测，自己的脚本自己清楚
