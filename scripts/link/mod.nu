# todo: 支持处理相对路径

# 判断是否是目录
def is-dir [] : path -> bool {
  ($in | path type) == 'dir'
}

# 符号链接
export def main [
  src: path # 源文件
  link: path # 链接位置
  --symbol(-S) # 符号链接(默认)
  --directory(-D) # 目录链接
  --hard(-H) # 硬链接
] : nothing -> nothing {
  if not ($src | path exists) {
    print $"(ansi red)Error: ($src) is not found(ansi reset)"
    return
  }
  if ($link | path exists) {
    print $"(ansi red)Error: ($link) already exists(ansi reset)"
    return
  }
  if $hard {
    if ($src | is-dir) {
      print $"(ansi red)Error: can't create hard link for folder(ansi reset)"
      return
    }
    ^mklink /H $link $src
  } else if $directory {
    if not ($src | is-dir) {
      print $"(ansi red)Error: You should not create directory link for file(ansi reset)"
      return
    }
    ^mklink /J $link $src
  } else {
    if ($src | is-dir) {
      ^mklink /D $link $src
    } else {
      ^mklink $link $src
    }
  }
}
