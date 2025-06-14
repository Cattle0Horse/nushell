# 对于b的已合并的分支是指那些最后提交节点在b之前或当前的分支，即b是他们的延申


# 获取当前仓库的根目录
export def git-root [] : nothing -> string {
  ^git rev-parse --show-toplevel
}

export def git-current-branch [] : nothing -> string {
  # ^git branch --no-color --show-current
  ^git rev-parse --abbrev-ref HEAD
}

# 查询暂存区是否有未提交的更改
export def git-has-changed-in-staging [] : nothing -> bool {
  (^git diff --cached --quiet | complete).exit_code == 1
}

# 列出未暂存的文件
export def git-unstaged-changes [] : nothing -> list<string> {
  ^git ls-files --modified --others --exclude-standard | lines --skip-empty
}

# 获取当前分支的上游（远程跟踪）分支
export def git-upstream-branch []: nothing -> string {
  ^git rev-parse --abbrev-ref @{u}
}

# 获取未推送的 commit's hash
export def git-has-unpushed-changes [] : nothing -> list<string> {
  ^git rev-list @{u}.. | lines
}

# 判断是当前目录是否在git仓库中
export def git-is-inside-repo [] : nothing -> bool {
  (^git rev-parse --is-inside-work-tree | complete).exit_code == 0
}

# 获取远程仓库
export def git-remotes [] : nothing -> list<string> {
  ^git remote | lines | each { |line| $line | str trim }
}

# 获取默认分支名称
export def git-main-branch [ upstream: string="origin" ] : nothing -> string {
  ^git symbolic-ref --short --quiet $'refs/remotes/($upstream)/HEAD' | split row '/' -n 2 | last
}

# 获取所有提交的作者
export def git-authors [] : nothing -> list<string> {
  ^git log --no-color --format='%aN' | lines | str trim | uniq
}

# 获取所有提交的邮箱
export def git-emails [] : nothing -> list<string> {
  ^git log --no-color --format='%aE' | lines | str trim | uniq
}

export def git-local-branches [] : nothing -> list<string> {
  ^git for-each-ref --no-color --format='%(refname:short)' refs/heads/
}

# 获取远程分支
export def git-remote-branches [upstream: string="origin"] : nothing -> list<string> {
  ^git for-each-ref --no-color --format='%(refname:short)' $'refs/remotes/($upstream)/' --exclude $'refs/remotes/($upstream)/HEAD'
}

# 获取git路径下的引用信息（管道in为引用目录路径，如refs/heads、refs/remotes/origin）
def git-refs-message [
  parser: record              # 解析对象，格式为{key: value}，key为nushell变量名，value为git标识名，例如{ref: '%(refname:short)'}
  --exclude(-e): list<string> # 要排除的模式列表
  --count(-n): int            # 限制输出数量
  --merged(-m)                # 列出已合并到当前分支的分支
  --mergedc(-M): string       # 列出已合并到指定分支的分支（对于--merged的补充，因为nushell不支持位置参数可选）
  --no-merged(-d)             # 列出未合并到当前分支的分支
  --no-mergedc(-D): string    # 列出未合并到指定分支的分支（对于--no-merged的补充，因为nushell不支持位置参数可选）
  --contains(-c)              # 列出包含指定提交的分支
  --containsc(-C): string     # 列出包含指定提交的分支（对于--contains的补充，因为nushell不支持位置参数可选）
  --no-contains(-s)           # 列出不包含指定提交的分支
  --no-containsc(-S): string  # 列出不包含指定提交的分支（对于--no-contains的补充，因为nushell不支持位置参数可选）
] : string -> table {
  let pt = $parser | transpose key value
  let sep1 = "\u{1f}" # 使用ASCII unit separator，极低概率出现在git内容中（一个ref的内容分隔符）
  let sep2 = "\u{1e}" # 使用ASCII record separator，极低概率出现在git内容中（多个refs的分隔符）

  mut args = ['--no-color']
  if ($exclude | is-not-empty)      { $args ++= ($exclude | each {|it| ['--exclude' $it]} | flatten) }
  if ($count | is-not-empty)        { $args ++= ['--count' $count] }
  # note: 下面的参数理应至多只有一个，但这里不做复杂的判断了
  if $merged      { $args ++= ['--merged'] }
  if $no_merged   { $args ++= ['--no-merged'] }
  if $contains    { $args ++= ['--contains'] }
  if $no_contains { $args ++= ['--no-contains'] }

  if ($mergedc | is-not-empty)      { $args ++= ['--merged' $mergedc] }
  if ($no_mergedc | is-not-empty)   { $args ++= ['--no-merged' $no_mergedc] }
  if ($containsc | is-not-empty)    { $args ++= ['--contains' $containsc] }
  if ($no_containsc | is-not-empty) { $args ++= ['--no-contains' $no_containsc] }

  ^git for-each-ref $in --format (($pt | get value | str join $sep1) + $sep2) ...$args
  | split row $sep2
  | where { is-not-empty }
  | str trim
  | parse ($pt | get key | each {|it| "{" + $it + "}" } | str join $sep1)
}

# 获取所有本地分支引用信息
export def git-local-branch-message [
  --exclude(-e): list<string> # 要排除的模式列表
  --count(-n): int            # 限制输出数量
  --merged(-m)                # 列出已合并到当前分支的分支
  --mergedc(-M): string       # 列出已合并到指定分支的分支（对于--merged的补充，因为nushell不支持位置参数可选）
  --no-merged(-d)             # 列出未合并到当前分支的分支
  --no-mergedc(-D): string    # 列出未合并到指定分支的分支（对于--no-merged的补充，因为nushell不支持位置参数可选）
  --contains(-c)              # 列出包含指定提交的分支
  --containsc(-C): string     # 列出包含指定提交的分支（对于--contains的补充，因为nushell不支持位置参数可选）
  --no-contains(-s)           # 列出不包含指定提交的分支
  --no-containsc(-S): string  # 列出不包含指定提交的分支（对于--no-contains的补充，因为nushell不支持位置参数可选）
]: nothing -> table {
  let ref_path = "refs/heads/"

  let parser = {
    branch:         '%(refname:short)'
    ref:            '%(refname)'
    obj_sha:        '%(objectname)'
    cm_parents:     '%(parent)'

    author_name:    '%(authorname)'
    author_email:   '%(authoremail:trim)'
    author_date:    '%(authordate:iso8601)'

    committer_name: '%(committername)'
    committer_email:'%(committeremail:trim)'
    committer_date: '%(committerdate:iso8601)'

    msg_contents:   '%(contents)' # 包含了 subject、body 和 trailers
    msg_subject:    '%(contents:subject)'
    msg_body:       '%(contents:body)'
    msg_trailers:   '%(contents:trailers)'

    br_up_remote:   '%(upstream:remotename)'
    br_up_branch:   '%(upstream:short)'
  }

  let exclude = if ($exclude | is-empty) { [] } else { $exclude | each {|it| $ref_path + $it } }

  $ref_path | git-refs-message $parser --exclude=$exclude --count=$count --merged=$merged --mergedc=$mergedc --no-merged=$no_merged --no-mergedc=$no_mergedc --contains=$contains --containsc=$containsc --no-contains=$no_contains --no-containsc=$no_containsc
  | each {|it|
    {
      branch: $it.branch
      ref:    $it.ref
      commit: {
        hash:     $it.obj_sha
        parents:  ($it.cm_parents | split row ' ')
        contents: $it.msg_contents
        subject:  $it.msg_subject
        body:     $it.msg_body
        trailers: $it.msg_trailers
      }
      author: {
        name:  $it.author_name
        email: $it.author_email
        date:  ($it.author_date | into datetime)
      }
      committer: {
        name:  $it.committer_name
        email: $it.committer_email
        date:  ($it.committer_date | into datetime)
      }
      upstream: {
        remote: $it.br_up_remote
        branch: $it.br_up_branch
      }
    }
  }
}

# 获取远程所有分支信息
export def git-remote-branch-message [
  upstream: string="origin"   # 上游仓库
  --exclude(-e): list<string> # 要排除的模式列表
  --count(-n): int            # 限制输出数量
  --merged(-m)                # 列出已合并到当前分支的分支
  --mergedc(-M): string       # 列出已合并到指定分支的分支（对于--merged的补充，因为nushell不支持位置参数可选）
  --no-merged(-d)             # 列出未合并到当前分支的分支
  --no-mergedc(-D): string    # 列出未合并到指定分支的分支（对于--no-merged的补充，因为nushell不支持位置参数可选）
  --contains(-c)              # 列出包含指定提交的分支
  --containsc(-C): string     # 列出包含指定提交的分支（对于--contains的补充，因为nushell不支持位置参数可选）
  --no-contains(-s)           # 列出不包含指定提交的分支
  --no-containsc(-S): string  # 列出不包含指定提交的分支（对于--no-contains的补充，因为nushell不支持位置参数可选）
]: nothing -> table {
  let ref_path = $"refs/remotes/($upstream)/"

  let parser = {
    branch:         '%(refname:short)'
    ref:            '%(refname)'
    obj_sha:        '%(objectname)'
    cm_parents:     '%(parent)'

    author_name:    '%(authorname)'
    author_email:   '%(authoremail:trim)'
    author_date:    '%(authordate:iso8601)'

    committer_name: '%(committername)'
    committer_email:'%(committeremail:trim)'
    committer_date: '%(committerdate:iso8601)'

    msg_contents:   '%(contents)' # 包含了 subject、body 和 trailers
    msg_subject:    '%(contents:subject)'
    msg_body:       '%(contents:body)'
    msg_trailers:   '%(contents:trailers)'
  }

  let exclude = $exclude | append 'HEAD' | each {|it| $ref_path + $it }

  $ref_path | git-refs-message $parser --exclude=$exclude --count=$count --merged=$merged --mergedc=$mergedc --no-merged=$no_merged --no-mergedc=$no_mergedc --contains=$contains --containsc=$containsc --no-contains=$no_contains --no-containsc=$no_containsc
  | each {|it|
    {
      branch: $it.branch
      ref:    $it.ref
      commit: {
        hash:     $it.obj_sha
        parents:  ($it.cm_parents | split row ' ')
        contents: $it.msg_contents
        subject:  $it.msg_subject
        body:     $it.msg_body
        trailers: $it.msg_trailers
      }
      author: {
        name:  $it.author_name
        email: $it.author_email
        date:  ($it.author_date | into datetime)
      }
      committer: {
        name:  $it.committer_name
        email: $it.committer_email
        date:  ($it.committer_date | into datetime)
      }
    }
  }
}

# git diff --name-only # 已跟踪未暂存的文件
# git ls-files --others --exclude-standard # 未跟踪的文件
# git ls-files --modified --others --exclude-standard # 未暂存的文件（上面两个的和）

# 获取所有本地分支引用的扩展信息
# export def git-all-local-refs []: nothing -> table {
# # table<
# #   ref: string,
# #   ref_info: record<short:string, full:string, symref:string, worktree:string>,
# #   object_info: record<type:string,sha:string,sha_short:string,size:int,disk_size:int,deltabase:string>,
# #   commit_meta: record<tree:string,parents:string,tag:string,peeled_sha:string>,
# #   author_info: record<name:string,email:string,date_iso:datetime,mailmap_name:string>,
# #   committer_info: record<name:string,email:string,date_iso:datetime>,
# #   tagger_info: record<name:string,email:string,date_iso:datetime>,
# #   signature_info: record<raw:string,grade:string,signer:string,key:string,fingerprint:string>,
# #   message: record<subject:string,body:string,trailers:string>,
# #   branch_info: record<upstream_remote:string,upstream_branch:string,ahead:int,behind:int>
# # >
#   let ref_path = "refs/heads"

#   let parser = {
#     # —— 一、引用信息 ——————————————————————————
#     ref_short:     '%(refname:short)'
#     ref_full:      '%(refname)'
#     ref_symref:    '%(symref)'
#     ref_worktree:  '%(worktreepath)'

#     # —— 二、对象信息 ——————————————————————————
#     obj_type:      '%(objecttype)'
#     obj_sha:       '%(objectname)'
#     obj_sha_short: '%(objectname:short)'
#     obj_size:      '%(objectsize)'
#     obj_disk:      '%(objectsize:disk)'
#     obj_delta:     '%(deltabase)'

#     # —— 三、提交/标签元数据 —————————————————————
#     cm_tree:       '%(tree)'
#     cm_parents:    '%(parent)' # 父提交，可能有一个或两个
#     cm_tag:        '%(tag)'
#     cm_peeled:     '%(*objectname)'

#     # —— 四、作者/提交者/标签创建者 —————————————————
#     author_name:    '%(authorname)'
#     author_email:   '%(authoremail:trim)'
#     author_date:    '%(authordate:iso8601)'
#     author_mailmap:'%(authorname:mailmap)'

#     committer_name:    '%(committername)'
#     committer_email:   '%(committeremail:trim)'
#     committer_date:    '%(committerdate:iso8601)'

#     tagger_name:    '%(taggername)'
#     tagger_email:   '%(taggeremail:trim)'
#     tagger_date:    '%(taggerdate:iso8601)'

#     # —— 六、消息正文与 Trailer —————————————————
#     msg_subject:    '%(contents:subject)'
#     msg_body:       '%(contents:body)'
#     msg_trailers:   '%(contents:trailers)' # 提交消息末尾的一组“键: 值”，如 Fixes: #1234 和 Signed-off-by: Alice <alice@example.com>

#     # —— 七、分支关系与比较 ———————————————————
#     br_up_remote:   '%(upstream:remotename)'
#     br_up_branch:   '%(upstream:short)'
#     # ahead-behind:<commit>：输出 “<ahead> <behind>”，表示当前分支与指定 <commit> 的先后提交数。
#   }

#   $ref_path | git-refs-message $parser | each {|it|
#     {
#       ref: {
#         short:   $it.ref_short
#         full:    $it.ref_full
#         symref:  $it.ref_symref
#         worktree:$it.ref_worktree
#       }
#       object: {
#         type:      $it.obj_type
#         sha:       $it.obj_sha
#         sha_short: $it.obj_sha_short
#         size:      ($it.obj_size | into int)
#         disk_size: ($it.obj_disk | into int)
#         deltabase: $it.obj_delta
#       }
#       commit_meta: {
#         tree:       $it.cm_tree
#         parents:    $it.cm_parents
#         tag:        $it.cm_tag
#         peeled_sha: $it.cm_peeled
#       }
#       author: {
#         name:       $it.author_name
#         email:      $it.author_email
#         date_iso:   ($it.author_date | into datetime)
#         mailmap_name:$it.author_mailmap
#       }
#       committer: {
#         name:     $it.committer_name
#         email:    $it.committer_email
#         date_iso: ($it.committer_date | into datetime)
#       }
#       tagger: {
#         name:     $it.tagger_name
#         email:    $it.tagger_email
#         # date_iso: ($it.tagger_date | into datetime)
#         date_iso: ($it.tagger_date)
#       }
#       message: {
#         subject:  $it.msg_subject
#         body:     $it.msg_body
#         trailers: $it.msg_trailers
#       }
#       upstream: {
#         remote: $it.br_up_remote
#         branch: $it.br_up_branch
#         # ahead:            ($it.br_ahead | into int)
#         # behind:           ($it.br_behind| into int)
#       }
#     }
#   }
# }
