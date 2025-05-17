# 判断是否为空目录
export def is-empty-dir [dir: path] : [nothing -> bool] {
  (ls -a $dir | length) == 0
}

def __clear-empty-dir-recursion [
  dir: path
  --verbose(-v) # 是否显示删除的目录
] : [nothing -> bool] {
  ls -f $dir | where type == dir | get name | each {|it|
    if (__clear-empty-dir-recursion $it) {
      if $verbose {
        print $"deleted ($it)"
      }
      rm $it
    }
  }
  return (is-empty-dir $dir)
}

# 递归删除空目录（不会处理隐藏文件）
export def clear-empty-dir-recursion [
  dir: path
  --verbose(-v) # 是否显示删除的目录
] : [nothing -> nothing] {
  __clear-empty-dir-recursion --verbose=$verbose $dir | ignore
}

# 获取目录下的空目录（非递归）
export def get-empty-dir [dir: path] : [nothing -> list] {
  # 判断是否为空目录时，需要加入隐藏文件
  ls -f $dir | where type == dir | get name | where {|it| is-empty-dir $it }
}
