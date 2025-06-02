# todo: 支持处理相对路径

# 判断是否是目录
def is-dir [] : path -> bool {
  ($in | path type) == 'dir'
}

# 符号链接
export def main [
  source_file: path # 源文件
  link: path # 生成的链接位置
  --symbol(-S) # 符号链接(默认)
  --directory(-D) # 目录链接
  --hard(-H) # 硬链接
] : nothing -> nothing {
  if not ($source_file | path exists) {
    print $"(ansi red)Error: ($source_file) is not found(ansi reset)"
    return
  }
  if ($link | path exists) {
    print $"(ansi red)Error: ($link) already exists(ansi reset)"
    return
  }
  if $hard {
    if ($source_file | is-dir) {
      print $"(ansi red)Error: can't create hard link for folder(ansi reset)"
      return
    }
    ^mklink /H $link $source_file
  } else if $directory {
    if not ($source_file | is-dir) {
      print $"(ansi red)Error: You should not create directory link for file(ansi reset)"
      return
    }
    ^mklink /J $link $source_file
  } else {
    if ($source_file | is-dir) {
      ^mklink /D $link $source_file
    } else {
      ^mklink $link $source_file
    }
  }
}
