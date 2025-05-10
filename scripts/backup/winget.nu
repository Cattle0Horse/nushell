use mod_utils.nu *

# 备份 scoop 应用列表
export def "backup winget" [date?: string] : nothing -> nothing {
    let date = if $date != null { $date } else { current-date }
    ^winget export --disable-interactivity --nowarn -o ($env.PACKAGE_MANAGER | path join winget $'($date).json')
}
