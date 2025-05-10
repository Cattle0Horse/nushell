# 20250418
def "nu-complete docker containers" [] {
    ^docker ps -a --format "{{.ID}} {{.Names}}" | lines
        | parse "{value} {description}"
}

def "nu-complete docker images" [] {
    ^docker images --format "{{.ID}} {{.Repository}}" | lines
        | parse "{value} {description}"
}

def "nu-complete docker run" [] {
    (nu-complete docker images)
    | append (nu-complete docker containers)
}

def "nu-complete docker pull" [] {
    [always, missing, never]
}

def "nu-complete docker remove image" [] {
    [local, all]
}

def "nu-complete local files" [] {
    ^ls | lines
}

def "nu-complete docker compose ps" [] {
    ^docker compose ps -a --format "{{.ID}} {{.Names}}" | lines
        | parse "{value} {description}"
}

def "nu-complete docker compose service status" [] {
    [paused restarting removing running dead created exited]
}

def "nu-complete docker subcommands" [] {
    # ^docker --help | lines | where $it =~ '^ {2}[A-Za-z]' | parse --regex '^ {2}([^\s*]+)\*?\s+.+$'
    ^docker --help | lines | where $it =~ '^ {2}[A-Za-z]' | parse --regex '^ {2}(?P<value>[^\s*]+)\*?\s+(?P<description>.+)$'
}

# 登录到 Docker 注册服务器
export extern "docker login" [
    server?: string                                     # Docker 注册服务器 URL
    --password(-p): string                              # 密码
    --password-stdin                                    # 从标准输入读取密码
    --username(-u): string                              # 用户名
]

# 从 Docker 注册服务器注销
export extern "docker logout" [
    server?: string                                     # Docker 注册服务器 URL
]

# 在 Docker Hub 上搜索镜像
export extern "docker search" [
    term?: string
    --filter(-f): string                                # 根据提供的条件过滤输出
    --format: string                                    # 使用 Go 模板美化输出
    --limit: int                                        # 搜索结果最大数量
    --no-trunc                                          # 不截断输出
]

# 显示 docker 版本信息
export extern "docker version" [
    --format(-f): string                                # 使用提供的 Go 模板格式化输出
    --kubeconfig: string                                # Kubernetes 配置文件
]

# 检查容器文件系统中对文件或目录的更改
export extern "docker system events" [
    --filter(-f): string                                # 根据提供的条件过滤输出
    --format: string                                    # 使用 Go 模板美化输出
    --since: string                                     # 显示从某时间戳或相对时间开始的所有事件
    --until: string                                     # 持续输出事件直到某时间戳或相对时间
]

# 附加本地标准输入、输出和错误流到正在运行的容器
export extern "docker container attach" [
    container?: string@"nu-complete docker containers"
    --detach-keys:string                                # 覆盖用于断开容器的按键序列
    --no-stdin                                          # 不附加标准输入
    --sig-proxy                                         # 将接收到的所有信号代理给进程
]

# 从容器的更改创建一个新镜像
export extern "docker container commit" [
    container?: string@"nu-complete docker containers"
    --author(-a): string                                # 作者（例如 "John Hannibal Smith <hannibal@a-team.com>"）
    --change(-c): string                                # 对创建的镜像应用 Dockerfile 指令
    --message(-m): string                               # 提交信息
    --pause(-p)                                         # 提交期间暂停容器（默认启用）
]

# 创建新容器
export extern "docker container create" [
    image?: string@"nu-complete docker images"          # 要从中创建容器的镜像
    command?: string                                     # 容器内运行的命令
    ...args: string
    --add-host: string                                  # 添加自定义主机到 IP 映射（host:ip）
    --annotation: string                                # 添加注解到容器（传递到 OCI 运行时）（默认 map[]）
    --attach: string                                    # 附加到 STDIN、STDOUT 或 STDERR
    --blkio-weight: int                                 # 块 IO（相对权重），范围 10 到 1000，0 表示禁用（默认 0）
    --blkio-weight-device: string                       # 块 IO 权重（相对设备权重）（默认 []）
    --cap-add: string                                   # 添加 Linux 权限
    --cap-drop: string                                  # 移除 Linux 权限
    --cgroup-parent: string                             # 容器可选的父 cgroup
    --cgroupns: string                                  # 使用的 cgroup 命名空间（host|private）
    --cidfile: string                                   # 将容器 ID 写入文件
    --cpu-period: int                                   # 限制 CPU CFS 周期
    --cpu-quota: int                                    # 限制 CPU CFS 配额
    --cpu-rt-period: int                                # 限制 CPU 实时周期（微秒）
    --cpu-rt-runtime: int                               # 限制 CPU 实时运行时间（微秒）
    --cpu-shares(-c): int                               # CPU 共享（相对权重）
    --cpus: int                                         # 使用的 CPU 数量
    --cpuset-cpus: string                               # 允许执行的 CPU（如 0-3, 0,1）
    --cpuset-mems: string                               # 允许执行的内存节点（如 0-3, 0,1）
    --detach(-d)                                        # 后台运行容器并输出容器 ID
    --detach-keys: string                               # 覆盖用于断开容器的按键序列
    --device: string                                    # 向容器添加宿主机设备
    --device-cgroup-rule: string                        # 向 cgroup 允许的设备列表添加规则
    --device-read-bps: int                              # 限制设备的读取速率（每秒字节数）（默认 []）
    --device-read-iops: int                             # 限制设备的读取速率（每秒 IO）（默认 []）
    --device-write-bps: int                             # 限制设备的写入速率（每秒字节数）（默认 []）
    --device-write-iops: int                            # 限制设备的写入速率（每秒 IO）（默认 []）
    --disable-content-trust                             # 跳过镜像验证（默认启用）
    --dns: int                                          # 设置自定义 DNS 服务器
    --dns-option: string                                # 设置 DNS 选项
    --dns-search: string                                # 设置自定义 DNS 搜索域
    --domainname: string                                # 容器的 NIS 域名
    --entrypoint: string                                # 覆盖镜像的默认 ENTRYPOINT
    --env(-e): string                                   # 设置环境变量
    --env-file: string                                  # 从文件读取环境变量
    --expose: string                                    # 开放端口或端口范围
    --gpus: string                                      # 向容器添加 GPU 设备（使用 'all' 传递所有 GPU）
    --group-add: string                                 # 添加附加用户组
    --health-cmd: string                                # 健康检查的命令
    --health-interval: duration                         # 检查间隔时间（单位：ms|s|m|h）（默认 0s）
    --health-retries: int                               # 连续失败次数达到后报告不健康
    --health-start-interval: duration                   # 启动期间检查之间的间隔时间（默认 0s）
    --health-start-period: duration                     # 启动期间容器初始化的时间（默认 0s）
    --health-timeout: duration                          # 单次健康检查的最大允许时间（默认 0s）
    --help                                              # 打印使用说明
    --hostname(-h): string                              # 容器主机名
    --init                                              # 在容器内运行 init，转发信号并收割进程
    --interactive(-i)                                   # 即使未附加也保持 STDIN 打开
    --ip: string                                        # IPv4 地址（例如 172.30.100.104）
    --ip6: string                                       # IPv6 地址（例如 2001:db8::33）
    --ipc: string                                       # 使用的 IPC 模式
    --isolation: string                                 # 容器隔离技术
    --kernel-memory: int                                # 内核内存限制
    --label(-l): string                                 # 设置容器的元数据
    --label-file: string                                # 从行分隔的标签文件中读取
    --link: string                                      # 添加与其他容器的连接
    --link-local-ip: string                             # 容器的 IPv4/IPv6 链路本地地址
    --log-driver: string                                # 容器的日志驱动
    --log-opt: string                                   # 日志驱动选项
    --mac-address: string                               # 容器的 MAC 地址（例如 92:d0:c6:0a:29:33）
    --memory(-m): int                                   # 内存限制
    --memory-reservation: int                           # 内存软限制
    --memory-swap: int                                  # 内存+交换分区限制，-1 表示无限制
    --memory-swappiness: int                            # 调整容器内存交换倾向（0 到 100）（默认 -1）
    --mount: string                                     # 向容器附加文件系统挂载点
    --name: string                                      # 为容器分配名称
    --network: string                                   # 将容器连接到网络
    --network-alias: string                             # 添加容器的网络别名
    --no-healthcheck                                    # 禁用容器指定的 HEALTHCHECK
    --oom-kill-disable                                  # 禁用 OOM Killer
    --oom-score-adj: int                                # 调整宿主机的 OOM 优先级（-1000 到 1000）
    --pid: string                                       # 使用的 PID 命名空间
    --pids-limit: int                                   # 调整容器的进程数限制（-1 表示无限制）
    --platform: string                                  # 若服务器支持多平台，设置平台
    --privileged                                        # 给容器授予扩展权限
    --publish(-p): string                               # 将容器端口映射到宿主机
    --publish-all(-P)                                   # 将所有暴露的端口随机映射到宿主机端口
    --pull: string@"nu-complete docker pull"            # 在运行前拉取镜像（"always"、"missing"、"never"）（默认 "missing"）
    --quiet(-q)                                         # 抑制拉取输出
    --read-only                                         # 以只读方式挂载容器根文件系统
    --restart: string                                   # 容器退出时应用的重启策略（默认 "no"）
    --rm                                                # 容器退出时自动删除
    --runtime: string                                   # 为容器使用的运行时
    --security-opt: string                              # 安全选项
    --shm-size: int                                     # /dev/shm 的大小
    --sig-proxy                                         # 将接收到的信号代理给进程（默认启用）
    --stop-signal: string                               # 停止容器所发送的信号
    --stop-timeout: int                                 # 停止容器的超时时间（秒）
    --storage-opt: string                               # 容器的存储驱动选项
    --sysctl: string                                    # Sysctl 选项（默认 map[]）
    --tmpfs: string                                     # 挂载 tmpfs 目录
    --tty(-t)                                           # 分配伪终端
    --ulimit: int                                       # Ulimit 选项（默认 []）
    --user(-u): string                                  # 用户名或 UID（格式：<name|uid>[:<group|gid>]）
    --userns: string                                    # 使用的用户命名空间
    --uts: string                                       # 使用的 UTS 命名空间
    --volume(-v): string                                # 绑定挂载卷
    --volume-driver: string                             # 容器的可选卷驱动
    --volumes-from: string                              # 从指定容器挂载卷
    --workdir(-w): string                               # 容器内的工作目录
]

# 检查容器文件系统中对文件或目录的更改
export extern "docker container diff" [
    container?: string@"nu-complete docker containers"
]

# 在运行的容器中执行命令
export extern "docker container exec" [
    container?: string@"nu-complete docker containers"
    --detach(-d)                                        # 后台模式：在后台运行命令
    --env(-e): string                                   # 设置环境变量
    --interactive(-i)                                   # 保持 STDIN 打开
    --privileged                                        # 授予命令扩展权限
    --tty(-t)                                           # 分配伪终端
    --user(-u): string                                  # 用户名或 UID（格式：<name|uid>[:<group|gid>]）
    --workdir(-w): string                               # 容器内的工作目录
]

# 将容器的文件系统导出为 tar 归档
export extern "docker container export" [
    container?: string@"nu-complete docker containers"
    --output(-o): string                                # 写入文件，而不是写入标准输出
]

# 显示一个或多个容器的详细信息
export extern "docker container inspect" [
    container?: string@"nu-complete docker containers"
    --format(-f):string                                 # 使用 Go 模板格式化输出
    --size(-s)                                          # 显示总文件大小
    --type:string                                       # 返回指定类型的 JSON
]

# 终止一个或多个运行中的容器
export extern "docker container kill" [
    container?: string@"nu-complete docker containers"
    --signal(-s):string                                 # 发送给容器的信号
]

# 获取容器日志
export extern "docker container logs" [
    container?: string@"nu-complete docker containers"
    --details                                           # 显示日志的额外细节
    --follow(-f)                                        # 跟随日志输出
    --since: string                                     # 显示从指定时间戳或相对时间开始的日志
    --tail(-n): string                                  # 显示日志末尾的行数
    --timestamps(-t)                                    # 显示时间戳
    --until: string                                     # 显示指定时间戳或相对时间之前的日志
]

# 列出容器
export extern "docker container ls" [
    --all(-a)                                           # 显示所有容器（默认仅显示运行中）
    --filter: string                                    # 根据条件过滤输出
    --format: string                                    # 使用 Go 模板美化输出
    --last(-n): int                                     # 显示最近创建的 n 个容器（包含所有状态）（默认 -1）
    --latest(-l)                                        # 显示最新创建的容器（包含所有状态）
    --no-trunc                                          # 不截断输出
    --quiet(-q)                                         # 仅显示容器 ID
    --size(-s)                                          # 显示总文件大小
]

# 暂停一个或多个容器中的所有进程
export extern "docker container pause" [
    container?: string@"nu-complete docker containers"
]

# 删除所有已停止的容器
export extern "docker container prune" [
    --filter: string                                    # 提供过滤条件（例如 'until=24h'）
    --force(-f)                                         # 不提示确认
]

# 列出容器的端口映射或特定映射
export extern "docker container port" [
    container?: string@"nu-complete docker containers"
]

# 重命名容器
export extern "docker container rename" [
    container?: string@"nu-complete docker containers"
    name?: string                                       # 新名称
]

# 重启一个或多个容器
export extern "docker container restart" [
    container?: string@"nu-complete docker containers"
    --time(-t): int                                     # 停止前等待的秒数
    --signal(-s): string                                # 停止容器所发送的信号
]

# 删除一个或多个容器
export extern "docker container rm" [
    container?: string@"nu-complete docker containers"
]

# 在新容器中运行命令
export extern "docker container run" [
    image?: string@"nu-complete docker run"             # 要创建容器的镜像
    command?: string                                    # 容器内运行的命令
    ...args: string
    --add-host: string                                  # 添加自定义主机到 IP 映射（host:ip）
    --annotation: string                                # 添加注解到容器（传递到 OCI 运行时）（默认 map[]）
    --attach: string                                    # 附加到 STDIN、STDOUT 或 STDERR
    --blkio-weight: int                                 # 块 IO（相对权重），范围 10 到 1000，0 表示禁用（默认 0）
    --blkio-weight-device: string                       # 块 IO 权重（相对设备权重）（默认 []）
    --cap-add: string                                   # 添加 Linux 权限
    --cap-drop: string                                  # 移除 Linux 权限
    --cgroup-parent: string                             # 容器可选的父 cgroup
    --cgroupns: string                                  # 使用的 cgroup 命名空间（host|private）
    --cidfile: string                                   # 将容器 ID 写入文件
    --cpu-period: int                                   # 限制 CPU CFS 周期
    --cpu-quota: int                                    # 限制 CPU CFS 配额
    --cpu-rt-period: int                                # 限制 CPU 实时周期（微秒）
    --cpu-rt-runtime: int                               # 限制 CPU 实时运行时间（微秒）
    --cpu-shares(-c): int                               # CPU 共享（相对权重）
    --cpus: int                                         # 使用的 CPU 数量
    --cpuset-cpus: string                               # 允许执行的 CPU（如 0-3,0,1）
    --cpuset-mems: string                               # 允许执行的内存节点（如 0-3,0,1）
    --detach(-d)                                        # 后台运行并输出容器 ID
    --detach-keys: string                               # 覆盖用于断开容器的按键序列
    --device: string                                    # 向容器添加宿主机设备
    --device-cgroup-rule: string                        # 向 cgroup 允许的设备列表添加规则
    --device-read-bps: int                              # 限制设备读取速率（字节/秒）（默认 []）
    --device-read-iops: int                             # 限制设备读取速率（IO/秒）（默认 []）
    --device-write-bps: int                             # 限制设备写入速率（字节/秒）（默认 []）
    --device-write-iops: int                            # 限制设备写入速率（IO/秒）（默认 []）
    --disable-content-trust                             # 跳过镜像验证（默认启用）
    --dns: int                                          # 设置自定义 DNS 服务器
    --dns-option: string                                # 设置 DNS 选项
    --dns-search: string                                # 设置自定义 DNS 搜索域
    --domainname: string                                # 容器的 NIS 域名
    --entrypoint: string                                # 覆盖镜像的默认 ENTRYPOINT
    --env(-e): string                                   # 设置环境变量
    --env-file: string                                  # 从文件读取环境变量
    --expose: string                                    # 开放端口或端口范围
    --gpus: string                                      # 向容器添加 GPU 设备（'all' 表示所有 GPU）
    --group-add: string                                 # 添加额外用户组
    --health-cmd: string                                # 健康检查命令
    --health-interval: duration                         # 检查间隔（ms|s|m|h）（默认 0s）
    --health-retries: int                               # 连续失败次数后报告不健康
    --health-start-interval: duration                   # 启动期间检查间隔（默认 0s）
    --health-start-period: duration                     # 启动期间初始化时长（默认 0s）
    --health-timeout: duration                          # 单次检查最大时长（默认 0s）
    --help                                              # 打印使用说明
    --hostname(-h): string                              # 容器主机名
    --init                                              # 在容器内运行 init，转发信号并回收进程
    --interactive(-i)                                   # 保持 STDIN 打开
    --ip: string                                        # IPv4 地址（例如 172.30.100.104）
    --ip6: string                                       # IPv6 地址（例如 2001:db8::33）
    --ipc: string                                       # 使用的 IPC 模式
    --isolation: string                                 # 容器隔离技术
    --kernel-memory: int                                # 内核内存限制
    --label(-l): string                                 # 设置容器元数据
    --label-file: string                                # 从标签文件读取
    --link: string                                      # 添加与其他容器的链接
    --link-local-ip: string                             # 容器链路本地地址
    --log-driver: string                                # 日志驱动
    --log-opt: string                                   # 日志驱动选项
    --mac-address: string                               # 容器 MAC 地址（例如 92:d0:c6:0a:29:33）
    --memory(-m): int                                   # 内存限制
    --memory-reservation: int                           # 内存软限制
    --memory-swap: int                                  # 内存+交换限制，-1 表示无限制
    --memory-swappiness: int                            # 内存交换倾向（0–100）（默认 -1）
    --mount: string                                     # 挂载文件系统
    --name: string                                      # 指定容器名称
    --network: string                                   # 连接到网络
    --network-alias: string                             # 添加网络别名
    --no-healthcheck                                    # 禁用 HEALTHCHECK
    --oom-kill-disable                                  # 禁用 OOM 杀手
    --oom-score-adj: int                                # 调整 OOM 优先级（-1000–1000）
    --pid: string                                       # 使用的 PID 命名空间
    --pids-limit: int                                   # 进程数限制（-1 表示无限制）
    --platform: string                                  # 多平台服务器上设置平台
    --privileged                                        # 授予扩展权限
    --publish(-p): string                               # 映射端口到宿主机
    --publish-all(-P)                                   # 随机映射所有暴露端口
    --pull: string@"nu-complete docker pull"            # 运行前拉取镜像（"always"、"missing"、"never"）（默认 "missing"）
    --quiet(-q)                                         # 静默拉取输出
    --read-only                                         # 以只读方式挂载根文件系统
    --restart: string                                   # 重启策略（默认 "no"）
    --rm                                                # 容器退出时自动删除
    --runtime: string                                   # 容器运行时
    --security-opt: string                              # 安全配置
    --shm-size: int                                     # /dev/shm 大小
    --sig-proxy                                         # 代理信号（默认启用）
    --stop-signal: string                               # 停止信号
    --stop-timeout: int                                 # 停止超时（秒）
    --storage-opt: string                               # 存储驱动选项
    --sysctl: string                                    # Sysctl 选项（默认 map[]）
    --tmpfs: string                                     # 挂载 tmpfs
    --tty(-t)                                           # 分配伪终端
    --ulimit: int                                       # Ulimit 选项（默认 []）
    --user(-u): string                                  # 用户名或 UID（格式：<name|uid>[:<group|gid>]）
    --userns: string                                    # 用户命名空间
    --uts: string                                       # UTS 命名空间
    --volume(-v): string                                # 绑定挂载卷
    --volume-driver: string                             # 卷驱动
    --volumes-from: string                              # 从指定容器挂载卷
    --workdir(-w): string                               # 工作目录
]

# 启动一个或多个已停止的容器
export extern "docker container start" [
    container?: string@"nu-complete docker containers"
    --attach(-a)                                        # 附加 STDOUT/STDERR 并转发信号
    --interactive(-i)                                   # 附加容器 STDIN
    --detach-keys: string                               # 覆盖断开按键序列
]

# 实时显示一个或多个容器的资源使用统计
export extern "docker container stats" [
    container?: string@"nu-complete docker containers"
    --all(-a)                                           # 显示所有容器（默认仅运行中）
    --format: string                                    # 使用 Go 模板美化输出
    --no-stream                                         # 禁用流式输出，仅获取第一个结果
    --no-trunc                                          # 不截断输出
]

# 停止一个或多个运行中的容器
export extern "docker container stop" [
    container?: string@"nu-complete docker containers"
    --time(-t): int                                     # 停止前等待的秒数
    --signal(-s): int                                   # 停止容器所发送的信号
]

# 显示容器中的运行进程
export extern "docker container top" [
    container?: string@"nu-complete docker containers"
]

# 取消暂停一个或多个容器中的所有进程
export extern "docker container unpause" [
    container?: string@"nu-complete docker containers"
]

# 更新一个或多个容器的配置
export extern "docker container update" [
    container?: string@"nu-complete docker containers"
    --blkio-weight: int                                 # 块 IO（相对权重），范围 10 到 1000，0 表示禁用（默认 0）
    --cpu-period: int                                   # 限制 CPU CFS 周期
    --cpu-quota: int                                    # 限制 CPU CFS 配额
    --cpu-rt-period: int                                # 限制 CPU 实时周期（微秒）
    --cpu-rt-runtime: int                               # 限制 CPU 实时运行时间（微秒）
    --cpu-shares(-c): int                               # CPU 共享（相对权重）
    --cpus: float                                       # 使用的 CPU 数量
    --cpuset-cpus: string                               # 允许执行的 CPU（如 0-3,0,1）
    --cpuset-mems: string                               # 允许执行的内存节点（如 0-3,0,1）
    --memory(-m): binary                                # 内存限制
    --memory-reservation: binary                        # 内存软限制
    --memory-swap: binary                               # 内存+交换限制，-1 表示无限制
    --pids-limit: int                                   # 进程数限制（-1 表示无限制）
    --restart: string                                   # 重启策略（默认 "no"）
]

# 阻塞直到一个或多个容器停止，然后打印它们的退出代码
export extern "docker container wait" [
    container?: string@"nu-complete docker containers"
]

# 从 Dockerfile 构建镜像
export extern "docker image build" [
    --add-host: string                                  # 添加自定义主机到 IP 映射（host:ip）
    --build-arg: string                                 # 设置构建时变量
    --cache-from: string                                # 作为缓存来源的镜像
    --cgroup-parent: string                             # 可选的父 cgroup
    --compress                                          # 使用 gzip 压缩构建上下文
    --file(-f): string@"nu-complete local files"        # Dockerfile 文件名（默认 'PATH/Dockerfile'）
    --iidfile: string                                   # 将镜像 ID 写入文件
    --isolation: string                                 # 容器隔离技术
    --label: string                                     # 为镜像设置元数据
    --network: string                                   # 设置构建期间 RUN 指令的网络模式（默认 "default"）
    --no-cache                                          # 构建镜像时不使用缓存
    --platform: string                                  # 设置平台（服务器支持多平台时）
    --progress: string                                  # 设置进度输出类型（auto、plain、tty）。使用 plain 显示容器输出
    --pull                                              # 总是尝试拉取更新的镜像
    --quiet(-q)                                         # 静默构建输出，并在成功时打印镜像 ID
    --secret: string                                    # 在构建中暴露的密钥文件（仅 BuildKit 启用时）：id=mysecret,src=/local/secret
    --ssh: string                                       # 在构建中暴露的 SSH 代理套接字或密钥（仅 BuildKit 启用时）
    --tag(-t): string                                   # 镜像名称及可选标签，格式 'name:tag'
    --target: string                                    # 设置要构建的目标阶段
    --ulimit: string                                    # Ulimit 选项（默认 []）
]

# 显示镜像历史
export extern "docker image history" [
    image?: string@"nu-complete docker images"
    --format: string                                    # 使用 Go 模板美化输出
    --no-trunc                                          # 不截断输出
    --quiet(-q)                                         # 仅显示数字 ID
]

# 为 SOURCE_IMAGE 创建一个指向的目标标签 TARGET_IMAGE
export extern "docker image tag" [
    source?: string@"nu-complete docker images"
    target?: string@"nu-complete docker images"
]

# 列出镜像
export extern "docker image ls" [
    --all(-a)                                           # 显示所有镜像（默认隐藏中间镜像）
    --digests                                           # 显示镜像摘要
    --filter: string                                    # 根据条件过滤输出
    --format: string                                    # 使用 Go 模板美化输出
    --no-trunc                                          # 不截断输出
    --quiet(-q)                                         # 仅显示数字 ID
]

# 从注册表下载镜像
export extern "docker image pull" [
    image?: string@"nu-complete docker images"
    --all-tags(-a)                                      # 拉取指定镜像的所有标签
    --disable-content-trust                             # 跳过镜像验证（默认启用）
    --plataform: string                                 # 设置平台（服务器支持多平台时）
    --quiet(-q)                                         # 静默拉取输出
]

# 将镜像推送到注册表
export extern "docker image push" [
    image?: string@"nu-complete docker images"
    --all-tags(-a)                                      # 推送指定镜像的所有标签
    --disable-content-trust                             # 跳过镜像验证（默认启用）
    --quiet(-q)                                         # 静默推送输出
]

# 将一个或多个镜像保存为 tar 归档（默认输出到 STDOUT）
export extern "docker image save" [
    image?: string@"nu-complete docker images"
    --output(-o): string                                # 写入文件，而不是标准输出
]

# 删除一个或多个镜像
export extern "docker image rm" [
    ...image: string@"nu-complete docker images"
    --force(-f)                                         # 强制删除镜像
    --no-prune                                          # 不删除未打标签的父镜像
]

# 使用 BuildKit 扩展构建功能
export extern "docker buildx" [
    --builder: string                                   # 覆盖配置的 builder 实例（默认 "default"）
]

# 停止并移除容器、网络
export extern "docker compose down" [
    --dry-run                                           # 以演练模式执行命令
    --remove-orphans                                    # 移除 Compose 文件中未定义的服务容器
    --rmi: string@"nu-complete docker remove image"     # 移除服务使用的镜像。"local" 仅移除未打自定义标签的镜像（"local"|"all"）
    --timeout(-t): int                                  # 指定关闭超时（秒）
    --volumes(-v)                                       # 移除 Compose 文件中声明的具名卷及附加到容器的匿名卷
]

# 列出容器
export extern "docker compose ps" [
    --all(-a)                                           # 显示所有已停止的容器（包括 run 命令创建的）
    --dry-run                                           # 以演练模式执行命令
    --filter: string                                    # 按属性过滤服务（支持的过滤器：status）
    --format: string                                    # 使用自定义模板格式化输出：'table'：表格形式打印，含列标题（默认）；'table 模板'：使用 Go 模板打印表格；'json'：JSON 格式打印；'模板'：使用 Go 模板打印；详情见 https://docs.docker.com/go/formatting/（默认 "table"）
    --no-truncate                                       # 不截断输出
    --orphans                                           # 包括孤立服务（项目未声明）（默认启用）
    --quite(-q)                                         # 仅显示 ID
    --services                                          # 显示服务
    --status: string@"nu-complete docker compose service status" # 按状态过滤服务，取值：[paused | restarting | removing | running | dead | created | exited]
]

# 停止容器
export extern "docker compose stop" [
    --dry-run                                           # 以演练模式执行命令
    --timeout(-t): int                                  # 指定关闭超时（秒）
]

# 重启服务容器
export extern "docker compose restart" [
    --dry-run                                           # 以演练模式执行命令
    --no-deps                                           # 不重启依赖服务
    --timeout(-t): int                                  # 指定关闭超时（秒）
]

# 创建并启动容器
export extern "docker compose up" [
    --abort-on-container-exit                           # 如果有容器停止，则停止所有容器。不兼容 -d/--detach
    --abort-on-container-failure                        # 如果有容器返回非零退出码，则停止所有容器。不兼容 -d/--detach
    --always-recreate-deps                              # 重新创建依赖容器。不兼容 --no-recreate
    --attach: string                                    # 限制附加到指定服务。不兼容 --attach-dependencies
    --attach-dependencies                               # 自动附加到所有依赖服务的日志输出
    --build                                             # 在启动容器前构建镜像
    --detach(-d)                                        # 后台模式：在后台运行容器
    --dry-run                                           # 以演练模式执行命令
    --exit-code-from: string                            # 返回所选服务容器的退出码。隐含 --abort-on-container-exit
    --force-recreate                                    # 即使配置和镜像未改变，也重新创建容器
    --menu                                              # 在附加模式下启用交互快捷键。不兼容 --detach，可启用或禁用
    --no-attach: string                                 # 不附加（流式日志）到指定服务
    --no-build                                          # 不构建镜像，即使有构建策略
    --no-color                                          # 输出单色
    --no-deps                                           # 不启动关联服务
    --no-log-prefix                                     # 日志中不打印前缀
    --no-recreate                                       # 如果容器已存在，则不重新创建。不兼容 --force-recreate
    --no-start                                          # 创建后不启动服务
    --pull: string@"nu-complete docker pull"            # 运行前拉取镜像（"always"|"missing"|"never"）（默认 "policy"）
    --quite-pull                                        # 拉取时不打印进度信息
    --remove-orphans                                    # 移除 Compose 文件中未定义的服务容器
    --renew-anon-volumes(-V)                            # 重新创建匿名卷，而不是使用之前容器的数据
    # --scale: scale                                      # 按服务扩缩到 NUM 实例。若 Compose 文件中存在 scale 设置，则此参数覆盖它
    --timeout(-t): int                                  # 在附加或容器已运行时，指定关闭超时（秒）
    --timestamps                                        # 显示时间戳
    --wait                                              # 等待服务运行或健康。隐含后台模式
    --wait-timeout: int                                 # 等待项目运行或健康的最长时长
    --watch(-w)                                         # 监视源代码，文件更新时重建或刷新容器
]

# 一个开源的容器管理平台
export extern "docker" [
    command?: string@"nu-complete docker subcommands"   # 子命令
    --config: string                                    # 客户端配置文件的位置（默认 "/root/.docker"）
    --context(-c): string                               # 用于连接守护进程的上下文名称（覆盖 DOCKER_HOST 环境变量和通过 "docker context use" 设置的默认上下文）
    --debug(-D)                                         # 启用调试模式
    --host(-H): string                                  # 要连接的守护进程 socket
    --log-level(-l): string                             # 设置日志级别（"debug"|"info"|"warn"|"error"|"fatal"）
    --tls                                               # 使用 TLS；--tlsverify 会隐含启用
    --tlscacert: string                                 # 仅信任由此 CA 签发的证书
    --tlscert: string                                   # TLS 证书文件路径
    --tlskey: string                                    # TLS 密钥文件路径
    --tlsverify                                         # 使用 TLS 并验证远程端
    --version(-v)                                       # 打印版本信息并退出
]

# 附加本地标准输入、输出和错误流到正在运行的容器
export alias "docker attach" = docker container attach
# 从容器的更改创建新镜像
export alias "docker commit" = docker container commit
export alias "docker cp" = docker container cp
# 创建新容器
export alias "docker create" = docker container create
# 检查容器文件系统中文件或目录的更改
export alias "docker diff" = docker container diff
# 在运行的容器中执行命令
export alias "docker exec" = docker container exec
# 将容器的文件系统导出为 tar 归档
export alias "docker export" = docker container export
# 显示一个或多个容器的详细信息
export alias "docker inspect" = docker container inspect
# 终止一个或多个运行中的容器
export alias "docker kill" = docker container kill
# 获取容器日志
export alias "docker logs" = docker container logs
# 暂停一个或多个容器中的所有进程
export alias "docker pause" = docker container pause
# 列出容器的端口映射或特定映射
export alias "docker port" = docker container port
# 重命名容器
export alias "docker rename" = docker container rename
# 重启一个或多个容器
export alias "docker restart" = docker container restart
# 列出容器
export alias "docker ps" = docker container ls
# 删除一个或多个容器
export alias "docker rm" = docker container rm
# 在新容器中运行命令
export alias "docker run" = docker container run
# 启动一个或多个已停止的容器
export alias "docker start" = docker container start
# 实时显示一个或多个容器的资源使用统计
export alias "docker stats" = docker container stats
# 停止一个或多个运行中的容器
export alias "docker stop" = docker container stop
# 显示容器中的运行进程
export alias "docker top" = docker container top
# 取消暂停一个或多个容器中的所有进程
export alias "docker unpause" = docker container unpause
# 更新一个或多个容器的配置
export alias "docker update" = docker container update
# 阻塞直到一个或多个容器停止，然后打印它们的退出码
export alias "docker wait" = docker container wait

# 从 Dockerfile 构建镜像
export alias "docker build" = docker image build
# 显示镜像历史
export alias "docker history" = docker image history
# 为 SOURCE_IMAGE 创建一个指向 TARGET_IMAGE 的标签
export alias "docker tag" = docker image tag
# 列出镜像
export alias "docker images" = docker image ls
# 删除一个或多个镜像
export alias "docker rmi" = docker image rm
# 从注册表下载镜像
export alias "docker pull" = docker image pull
# 将镜像推送到注册表
export alias "docker push" = docker image push
# 将一个或多个镜像保存为 tar 归档（默认输出到 STDOUT）
export alias "docker save" = docker image save

# 检查容器文件系统中文件或目录的更改
export alias "docker events" = docker system events
