const date_format_YmdHMS: string = "%Y%m%d%H%M%S"

# 获取当前时间
export def current-date [format: string = $date_format_YmdHMS] : nothing -> string {
    date now | format date $format
}
