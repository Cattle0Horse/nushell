export-env {
  if ('FAV_HOME' not-in $env) {
    $env.FAV_HOME = ($nu.data-dir | path join 'data' 'fav')
  }
}

# 返回数据文件路径，必要时创建父目录
def fav-file []: nothing -> path {
  if (not ($env.FAV_HOME | path exists)) {
    mkdir $env.FAV_HOME
  }
  $env.FAV_HOME | path join 'favorites.json'
}

# 读取收藏列表；文件不存在时返回空列表
def load-favs []: nothing -> list {
  let file = (fav-file)
  if ($file | path exists) {
    open $file
  } else {
    []
  }
}

# 写回收藏列表
def save-favs [favs: list]: nothing -> nothing {
  $favs | to json --indent 2 | save --force (fav-file)
}

# 生成展示文本：有 name 时为 "name — path"，否则仅 path
def fav-display []: record -> string {
  let it = $in
  let name = ($it.name? | default '')
  if ($name | is-empty) {
    $it.path
  } else {
    $"($name) — ($it.path)"
  }
}

# 收藏一个路径（默认为当前工作目录）
@example "收藏当前目录" { fav add }
@example "收藏指定路径并起名" { fav add ~/projects/foo --name foo }
@example "带标签收藏" { fav add --name work-repo --tag work }
export def "fav add" [
  path?: string # 要收藏的路径，省略时为 pwd
  --name(-n): string # 别名，便于识别与搜索
  --tag(-t): string # 标签，用于分组过滤
  --force(-f) # 如路径已存在则覆盖 name/tag
]: nothing -> nothing {
  let target = (if ($path | is-empty) { pwd } else { $path } | path expand)
  if (not ($target | path exists)) {
    error make { msg: $"路径不存在：($target)" }
  }

  let favs = (load-favs)
  let existing_idx = ($favs | enumerate | where item.path == $target | get -o 0.index)

  let entry = {
    name: ($name | default null)
    path: $target
    tag: ($tag | default null)
    added_at: (date now | format date '%Y-%m-%dT%H:%M:%S%:z')
  }

  let new_favs = if $existing_idx != null {
    if (not $force) {
      error make { msg: $"已收藏：($target)。使用 --force 覆盖。" }
    }
    $favs | update $existing_idx $entry
  } else {
    $favs | append $entry
  }

  save-favs $new_favs
  print $"已收藏：($target)"
}

# 列出全部收藏（可按 tag 过滤）
@example "列出全部收藏" { fav list }
@example "仅列出某个标签" { fav list --tag work }
export def "fav list" [
  --tag(-t): string # 按 tag 过滤
]: nothing -> table {
  let favs = (load-favs)
  if ($tag | is-not-empty) {
    $favs | where tag == $tag
  } else {
    $favs
  }
}

# 模糊搜索并选中一条收藏，输出 path 字符串（便于管道）
@example "选一条并 cd" { fav pick | cd }
@example "对选中的路径 ls" { ls (fav pick) }
@example "按 tag 过滤再选" { fav pick --tag work | cd }
export def "fav pick" [
  --tag(-t): string # 按 tag 过滤
]: nothing -> any {
  let favs = (load-favs)
  let candidates = (if ($tag | is-not-empty) {
    $favs | where tag == $tag
  } else {
    $favs
  })

  if ($candidates | is-empty) {
    print '暂无收藏'
    return null
  }

  let picked = ($candidates | input list --fuzzy -d {|it| $it | fav-display } '选择一个收藏路径')
  if ($picked | is-empty) {
    return null
  }
  $picked.path
}

# 模糊搜索并删除一条收藏
@example "删除一条收藏" { fav rm }
export def "fav rm" [
  --tag(-t): string # 按 tag 过滤
]: nothing -> nothing {
  let favs = (load-favs)
  let candidates = (if ($tag | is-not-empty) {
    $favs | where tag == $tag
  } else {
    $favs
  })

  if ($candidates | is-empty) {
    print '暂无收藏'
    return
  }

  let picked = ($candidates | input list --fuzzy -d {|it| $it | fav-display } '选择要删除的收藏')
  if ($picked | is-empty) {
    return
  }

  let new_favs = ($favs | where path != $picked.path)
  save-favs $new_favs
  print $"已删除：($picked.path)"
}
