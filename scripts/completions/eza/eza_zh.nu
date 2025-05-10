def "nu-complete eza when" [] {
    [[value]; ["always"] ["auto"] ["never"]]
}

def "nu-complete eza sort-field" [] {
    # 名称, 名称(大写), 大小, 扩展名, 扩展名(大写), 修改时间, 更改时间, 访问时间, 创建时间, inode, 类型, 无
    [[value]; ["name"] ["Name"] ["extension"] ["Extension"] ["size"] ["type"] ["modified"] ["accessed"] ["created"] ["inode"] ["none"] ["date"] ["time"] ["old"] ["new"]]
}

def "nu-complete eza time-field" [] {
    # 修改时间, 访问时间, 创建时间, 更改时间
    [[value]; ["modified"] ["accessed"] ["created"] ["changed"]]
}

def "nu-complete eza time-style" [] {
    [[value]; ["default"] ["iso"] ["long-iso"] ["full-iso"] ["relative"] ["+<FORMAT>"]]
}

def "nu-complete eza color-scale" [] {
    [[value]; ["all"] ["age"] ["size"]]
}

def "nu-complete eza color-scale-mode" [] {
    [[value]; ["fixed"] ["gradient"]]
}

# 一个现代的、维护中的 ls 替代品
export extern "eza" [
    path?: path                                             # 要列出的文件夹
    --help                                                  # 显示命令行选项列表
    --version(-v)                                           # 显示 eza 的版本
    --oneline(-1)                                           # 每行显示一个条目
    --long(-l)                                              # 以表格形式显示扩展的文件元数据
    --grid(-G)                                              # 以网格形式显示条目（默认）
    --across(-x)                                            # 横向排序网格，而不是纵向
    --recurse(-R)                                           # 递归进入目录
    --tree(-T)                                              # 以树形结构递归进入目录
    --dereference(-X)                                       # 显示信息时解析符号链接
    --classify(-F): string@"nu-complete eza when"="auto"    # 按文件名显示类型指示器
    --colour: string@"nu-complete eza when"="auto"          # 使用终端颜色的时机
    --color: string@"nu-complete eza when"="auto"           # 使用终端颜色的时机
    --colour-scale: string@"nu-complete eza color-scale"="all"                                          # 分别突出显示 'field' 的不同级别
    --color-scale: string@"nu-complete eza color-scale"="all"                                           # 分别突出显示 'field' 的不同级别
    --colour-scale-mode: string@"nu-complete eza color-scale-mode"                                      # 在 --color-scale 中使用渐变或固定颜色
    --color-scale-mode: string@"nu-complete eza color-scale-mode"                                      # 在 --color-scale 中使用渐变或固定颜色
    --icons: string@"nu-complete eza when"="auto"           # 显示图标的时机
    --no-quotes                                             # 不对包含空格的文件名加引号
    --hyperlink                                             # 将条目显示为超链接
    --absolute                                              # 显示条目的绝对路径（开启、跟随、关闭）
    --width(-w): int                                        # 设置屏幕宽度（列数）
    --all(-a)                                               # 显示隐藏文件和 'dot' 文件。使用两次还显示 '.' 和 '..' 目录
    --almost-all(-A)                                        # 等同于 --all；为兼容 `ls -A` 提供
    --list-dirs(-d)                                         # 将目录作为文件列出；不列出其内容
    --level(-L): int                                        # 限制递归深度
    --reverse(-r)                                           # 反转排序顺序
    --sort(-s): string@"nu-complete eza sort-field"         # 按哪个字段排序
    --group-directories-first                               # 先列出目录再列出其他文件
    --only-dirs(-D)                                         # 只列出目录
    --only-files(-f)                                        # 只列出文件
    --ignore-glob(-I): string                               # 忽略的文件 glob 模式（用管道分隔）
    --git-ignore                                            # 忽略 `.gitignore` 中提到的文件
    --binary(-b)                                            # 使用二进制前缀列出文件大小
    --bytes(-B)                                             # 以字节为单位列出文件大小，不加前缀
    --group(-g)                                             # 列出每个文件的组
    --smart-group                                           # 仅在组名与所有者不同时显示组
    --header(-h)                                            # 每列添加表头行
    --links(-H)                                             # 列出每个文件的硬链接数量
    --inode(-i)                                             # 列出每个文件的 inode 号
    --modified(-m)                                          # 使用修改时间戳字段
    --mounts(-M)                                            # 显示挂载信息（仅限 Linux 和 Mac）
    --numeric(-n)                                           # 列出数值型用户和组 ID
    --flags(-O)                                             # 列出文件标志（仅限 Mac、BSD 和 Windows）
    --blocksize(-S)                                         # 显示分配的文件系统块的大小
    --time(-t): string@"nu-complete eza time-field"         # 列出哪个时间戳字段
    --accessed(-u)                                          # 使用访问时间戳字段
    --created(-U)                                           # 使用创建时间戳字段
    --changed                                               # 使用更改时间戳字段
    --time-style: string@"nu-complete eza time-style"       # 格式化时间戳的方式（也可以使用自定义格式 '+<FORMAT>' 如 '+%Y-%m-%d %H:%M'）
    --total-size                                            # 显示目录的大小（仅限 Unix）
    --no-permissions                                        # 抑制权限字段
    --octal-permissions(-o)                                 # 以八进制格式列出每个文件的权限
    --no-filesize                                           # 抑制文件大小字段
    --no-user                                               # 抑制用户字段
    --no-time                                               # 抑制时间字段
    --stdin                                                 # 从标准输入读取文件名
    --git                                                   # 列出每个文件的 Git 状态（如果被跟踪或忽略）
    --no-git                                                # 抑制 Git 状态
    --git-repos                                             # 列出 git-tree 状态的根
    --extended(-@)                                          # 列出每个文件的扩展属性和大小
    --context(-Z)                                           # 列出每个文件的安全上下文
]
