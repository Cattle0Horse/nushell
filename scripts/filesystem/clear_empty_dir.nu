use internal.nu *

# 删除一个目录下的空目录
export def clear-empty-dir [
  dir: path
  --recursion(-r) # 是否递归删除
  --verbose(-v) # 是否显示删除的目录
] : [
  nothing -> nothing
] {
  if $recursion {
    clear-empty-dir-recursion --verbose=$verbose $dir
  } else {
    get-empty-dir $dir | each {|it|
      if $verbose {
        print $"deleted ($it)"
      }
      rm $it
    }
  }
}
