# Rime 输入法工具模块
# 提供 Rime 模型更新和管理功能

# 导出所有子模块
use const.nu *
use utils.nu *
use weasel.nu *
use download.nu *
use model.nu *

# ===== 缓存管理命令 =====

export def "rime cache" [] {
  list-cache
}

# 列出缓存文件
export def "rime cache list" [] {
  list-cache
}

# 清除缓存
export def "rime cache rm" [
  ...patterns: string  # 要删除的缓存文件模式（支持通配符，如 * 表示全部）
] {
  if ($patterns | is-empty) {
    print $"(ansi yellow)请指定要删除的缓存文件模式(ansi reset)"
    print "用法: rime cache rm <pattern>..."
    print "示例:"
    print "  rime cache rm *           # 删除所有缓存"
    print "  rime cache rm gram        # 删除包含 'gram' 的缓存文件"
    print "  rime cache rm *.gram      # 删除所有 .gram 文件"
    return
  }

  for pattern in $patterns {
    if $pattern == "*" {
      clear-cache --all
    } else {
      clear-cache --pattern $pattern
    }
  }
}

# 显示缓存统计
export def "rime cache show" [] {
  cache-stats
}

# ===== 模型管理命令 =====

export def "rime model" [
  --target-dir(-t): string # 指定目标目录（默认使用小狼毫用户目录）
] {
  check-rime-model-status --target-dir=$target_dir
}

# 检查模型状态
export def "rime model check" [
  --target-dir(-t): string # 指定目标目录（默认使用小狼毫用户目录）
] {
  check-rime-model-status --target-dir=$target_dir
}

# 更新模型文件
export def "rime model update" [
  --force(-f)              # 强制更新，忽略时间戳检查
  --target-dir(-t): string # 指定目标目录（默认使用小狼毫用户目录）
] {
  update-rime-model --force=$force --target-dir=$target_dir
}

# ===== 小狼毫管理命令 =====

export def "rime weasel" [] {
  verify-weasel-installation
}

# 启动小狼毫服务
export def "rime weasel start" [] : nothing -> bool {
  start-weasel-server
}

# 停止小狼毫服务
export def "rime weasel stop" [] : nothing -> bool {
  stop-weasel-server
}

# 重启小狼毫服务
export def "rime weasel restart" [] : nothing -> bool {
  stop-weasel-server
  sleep 2sec
  start-weasel-server
}

# 重新部署小狼毫
export def "rime weasel redeploy" [] : nothing -> bool {
  redeploy-weasel
}

# 验证小狼毫安装
export def "rime weasel verify" [] : nothing -> bool {
  verify-weasel-installation
}

# ===== 信息命令 =====

# 显示 Rime 目录和状态信息
export def "rime info" [] {
  print $"(ansi cyan)=== Rime 目录信息 ===(ansi reset)"
  print $"缓存目录: ($RIME_CACHE_DIR)"
  print $"数据目录: ($RIME_DATA_DIR)"
  print $"时间记录文件: (get-time-record-file-path)"
  print ""

  # 显示目录状态
  print $"缓存目录状态: (if ($RIME_CACHE_DIR | path exists) { '✓ 存在' } else { '✗ 不存在' })"
  print $"数据目录状态: (if ($RIME_DATA_DIR | path exists) { '✓ 存在' } else { '✗ 不存在' })"
  print $"时间记录文件状态: (if (get-time-record-file-path | path exists) { '✓ 存在' } else { '✗ 不存在' })"
}
