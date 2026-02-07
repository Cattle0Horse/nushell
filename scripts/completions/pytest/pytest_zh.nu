def "nu-complete --capture" [] { ["fd", "sys", "no", "tee-sys"] }
def "nu-complete --last-failed-no-failures" [] { ["all", "none"] }
def "nu-complete --tb" [] { ["auto", "long", "short", "line", "native", "no"] }
def "nu-complete --show-capture" [] { ["no", "stdout", "stderr", "log", "all"] }
def "nu-complete --color" [] { ["yes", "no", "auto"] }
def "nu-complete --code-highlight" [] { ["yes", "no"] }
def "nu-complete --pastebin" [] { ["failed", "all"] }
def "nu-complete --import-mode" [] { ["prepend", "append", "importlib"] }
def "nu-complete --doctest-report" [] { ["none", "cdiff", "ndiff", "udiff", "only_first_failure"] }
def "nu-complete --log-file-mode" [] { ["w"; "a"] }
def "nu-complete --assert" [] { ["plain"; "rewrite"] }
def "nu-complete --log-level" [] { ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] }

export extern pytest [
  file_or_dir?: path        # 用于测试发现的文件或目录列表
  -k: string                # 仅运行匹配给定子字符串表达式的测试
  --markers(-m): string     # 为测试函数注册新的标记
  --exitfirst(-x)           # 在第一个错误或失败的测试后立即退出
  --fixtures                # 显示可用的 fixtures，按插件出现顺序排序（以 '_' 开头的 fixtures 只有在使用 '-v' 时才会显示）
  --fixtures-per-test       # 显示每个测试的 fixtures
  --pdb                     # 在错误或 KeyboardInterrupt 时启动交互式 Python 调试器
  --pdbcls:string           # 指定用于 --pdb 的自定义交互式 Python 调试器
  --trace                   # 在运行每个测试时立即中断
  --capture:string@"nu-complete --capture"    # 每个测试的捕获方法
  -s                        # --capture=no 的快捷方式
  --runxfail                # 将 xfail 测试的结果报告为未标记
  --last-failed             # 仅重新运行上次运行中失败的测试（如果都没有失败，则运行所有测试）
  --failed-first            # 运行所有测试，但先运行上次失败的测试。这可能会重新排序测试，从而导致重复的 fixture 设置/拆卸
  --new-first               # 先运行新文件中的测试，然后按文件修改时间排序其余测试
  --cache-show?:string      # 显示缓存内容，不执行收集或测试。可选参数：glob（默认：'*'）
  --cache-clear             # 在测试运行开始时清除所有缓存内容
  --last-failed-no-failures:string@"nu-complete --last-failed-no-failures"  # 确定在没有先前（已知）失败或未找到缓存的 `lastfailed` 数据时是否执行测试。`all`（默认）会再次运行完整的测试套件。`none` 只会发出关于没有已知失败的消息并成功退出
  --stepwise                # 在测试失败时退出，并在下次从最后一个失败的测试继续
  --stepwise-skip           # 忽略第一个失败的测试，但在下一个失败的测试时停止。隐式启用 --stepwise
  --durations:int           # 显示 N 个最慢的设置/测试持续时间（N=0 表示所有）
  --durations-min?:int      # 包含在最慢列表中的最小持续时间（秒）。默认：0.005
  --verbose(-v)             # 增加详细程度
  --no-header               # 禁用头部信息
  --no-summary              # 禁用摘要
  --no-fold-skipped         # 在简短摘要中不折叠跳过的测试
  --quiet(-q)               # 减少详细程度
  --verbosity:int           # 设置详细程度。默认：0
  -r:string                 # 显示指定的额外测试摘要信息：(f)失败、(E)错误、(s)跳过、(x)失败、(X)通过、(p)通过、(P)带输出通过、(a)除通过外的所有（p/P）、或 (A)所有。(w)警告默认启用（参见 --disable-warnings），'N' 可用于重置列表（默认：'fE'）
  --disable-warnings        # 禁用警告摘要
  --showlocals(-l)          # 在回溯中显示局部变量（默认禁用）
  --no-showlocals           # 在回溯中隐藏局部变量（否定通过 addopts 传递的 --showlocals）
  --tb:string@"nu-complete --tb"                          # 回溯打印模式
  --xfail-tb                                              # 显示 xfail 的回溯（只要 --tb != no）
  --show-capture:string@"nu-complete --show-capture"      # 控制失败测试中捕获的 stdout/stderr/log 的显示方式。默认：all
  --full-trace                                            # 不截断任何回溯（默认是截断）
  --color:string@"nu-complete --color"                    # 彩色终端输出
  --code-highlight:string@"nu-complete --code-highlight"  # 是否应高亮显示代码（仅在 --color 也启用时）。默认：yes
  --pastebin:string@"nu-complete --pastebin"              # 将失败|所有信息发送到 bpaste.net pastebin 服务
  --junit-xml:path                          # 在给定路径创建 junit-xml 样式的报告文件
  --junit-prefix:string                     # 在 junit-xml 输出中为类名添加前缀
  --pythonwarnings(-W): string              # 设置要报告的警告，参见 Python 本身的 -W 选项
  --maxfail:int                             # 在第一次失败或错误后退出
  --strict-config                           # 在解析配置文件的 `pytest` 部分时遇到的任何警告都会引发错误
  --strict-markers                          # 在配置文件的 `markers` 部分未注册的标记会引发错误
  --config-file(-c):path                    # 从 `FILE` 加载配置，而不是尝试定位隐式配置文件之一
  --continue-on-collection-errors           # 即使发生收集错误也强制执行测试
  --rootdir:path            # 定义测试的根目录。可以是相对路径：'root_dir'、'./root_dir'、'root_dir/another_dir/'；绝对路径：'/home/user/root_dir'；带变量的路径：'$HOME/root_dir'
  --collect-only            # 仅收集测试，不执行它们
  --pyargs                  # 尝试将所有参数解释为 Python 包
  --ignore:path             # 在收集期间忽略路径（允许多个）
  --ignore-glob:path        # 在收集期间忽略路径模式（允许多个）
  --deselect:string         # 在收集期间取消选择项（通过节点 ID 前缀）（允许多个）
  --confcutdir:string       # 仅加载相对于指定目录的 conftest.py
  --noconftest              # 不加载任何 conftest.py 文件
  --keep-duplicates         # 保留重复的测试
  --collect-in-virtualenv                                   # 不忽略本地 virtualenv 目录中的测试
  --import-mode:string@"nu-complete --import-mode"          # 在导入测试模块和 conftest 文件时，前置/附加到 sys.path。默认：prepend
  --doctest-modules                                         # 在所有 .py 模块中运行 doctest
  --doctest-report:string@"nu-complete --doctest-report"    # 为 doctest 失败选择另一个输出格式
  --doctest-glob:string                                     # Doctests 文件匹配模式，默认：test*.txt
  --doctest-ignore-import-errors                            # 忽略 doctest 收集错误
  --doctest-continue-on-failure                             # 对于给定的 doctest，在第一次失败后继续运行
  --basetemp:path           # 本次测试运行的基本临时目录。（警告：如果此目录存在，将被删除）
  --version(-V)             # 显示 pytest 版本和插件信息。如果给定两次，还会显示插件信息
  --help(-h)                # 显示帮助消息和配置信息
  -p:string                 # 早期加载给定的插件模块名称或入口点（允许多个）。要避免加载插件，请使用 `no:` 前缀，例如 `no:doctest`
  --trace-config            # 跟踪 conftest.py 文件的考虑因素
  --debug?:path             # 将内部跟踪调试信息存储在此日志文件中。此文件以 'w' 打开并被截断，请谨慎使用。默认：pytestdebug.log
  --override-ini(-i): string                              # 使用 "option=value" 样式覆盖 ini 选项，例如 `-o xfail_strict=True -o cache_dir=cache`
  --assert:string@"nu-complete --assert"                  # 控制断言调试工具。'plain' 不执行断言调试。'rewrite'（默认）在导入时重写测试模块中的断言语句以提供断言表达式信息
  --setup-only              # 仅设置 fixtures，不执行测试
  --setup-show              # 在执行测试时显示 fixtures 的设置
  --setup-plan              # 显示将执行哪些 fixtures 和测试，但不执行任何操作
  --log-level:string@"nu-complete --log-level"            # 要捕获/显示的消息级别。默认未设置，因此取决于根/父日志处理程序的有效级别，默认为 "WARNING"
  --log-format:string                                     # 日志模块使用的日志格式
  --log-date-format:string                                # 日志模块使用的日志日期格式
  --log-cli-level:string@"nu-complete --log-level"        # CLI 日志级别
  --log-cli-format:string                                 # 日志模块使用的日志格式
  --log-cli-date-format:string                            # 日志模块使用的日志日期格式
  --log-file:path                                         # 日志将写入的文件路径
  --log-file-mode:string@"nu-complete --log-file-mode"    # 日志文件打开模式
  --log-file-level:string@"nu-complete --log-level"       # 日志文件日志级别
  --log-file-format:string                                # 日志模块使用的日志格式
  --log-file-date-format:string                           # 日志模块使用的日志日期格式
  --log-auto-indent:int                                   # 自动缩进传递给日志模块的多行消息。接受 true|on、false|off 或整数
  --log-disable:string                                    # 按名称禁用记录器。可以多次传递
]
