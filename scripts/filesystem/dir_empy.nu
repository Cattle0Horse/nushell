def collect-empty-dirs-recursive-parent [
  dir: path       # 起始目录
  --delete        # 递归时删除空目录
] : nothing -> record<empty: int, dirs: list<path>> {
  ls --full-paths $dir | where type == dir | get name | reduce --fold { empty: 0, dirs: [] } {|it acc|
    let res = collect-empty-dirs-recursive-parent $it --delete=$delete
    $acc | update empty ($acc.empty + $res.empty) | update dirs ($acc.dirs ++ $res.dirs)
  }
  | if (($in | get empty) == (ls --all $dir | length)) { # 判断空目录数量是否等于项目数量
    if $delete {
      rm $dir
    }
    {
      empty: 1,
      dirs: ($in.dirs | append $dir)
    }
  } else {
    {
      empty: 0,
      dirs: $in.dirs
    }
  }
}

def collect-empty-dirs-recursive [
  dir: path       # 起始目录
  --delete        # 递归时删除空目录
] : nothing -> list<path> {
  if (ls --all $dir | is-empty) {
    if $delete {
      rm $dir
    }
    [$dir]
  } else {
    ls --full-paths $dir | where type == dir | get name | reduce --fold [] {|it acc|
      $acc | append (collect-empty-dirs-recursive $it --delete=$delete)
    }
  }
}

# 查找并操作空目录的主命令（隐藏目录不会递归，但是会作为存在项检测）
export def dir-empty [
  path?: path     # 要检查的目录路径，默认为当前目录
  --recursive(-r) # 递归检查子目录
  --delete(-d)    # 删除找到的空目录
  --parent(-p)    # 将只有空子目录的父目录视为空目录
] : nothing -> list<path> {
  let path = if ($path | is-empty) { pwd } else { $path }
  if $recursive {
    if $parent {
      collect-empty-dirs-recursive-parent $path --delete=$delete | get dirs
    } else {
      collect-empty-dirs-recursive $path --delete=$delete
    }
  } else {
    ls --full-paths $path
    | where type == dir
    | get name
    | where {|it|
      let empty = ls --all $it | is-empty
      if $delete and $empty {
        rm $it
      }
      $empty
    }
  }
}
