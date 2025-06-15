use internal.nu *

# 删除一个目录下的空目录
export def clear-empty-dir [
  dir?: path
  --recursion(-r) # 递归删除
  --verbose(-v)   # 显示删除的目录
  --dry-run(-n)   # 试运行
] : [
  nothing -> nothing
] {
  let dir = if ($dir | is-empty) { pwd } else { $dir }
  if $recursion {
    clear-empty-dir-recursion --verbose=$verbose --dry-run=$dry_run $dir
  } else {
    get-empty-dir $dir | each {|it|
      if $verbose {
        print $"deleted ($it)"
      }
      if not $dry_run {
        rm $it
      }
    }
    | ignore
  }
}
