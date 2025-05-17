use internal.nu *

# 备份 scoop 应用列表
export def "backup scoop" [date?: string] : nothing -> nothing {
  let date = if $date != null { $date } else { current-date }
  ^scoop export | save ($env.PACKAGE_MANAGER | path join scoop $'($date).json')
}
