export-env {
  if ($env.GIT_COMMIT_TYPE? | is-empty) {
    $env.GIT_COMMIT_TYPE = [
      [value    description];
      [feat     '新增功能 | 新增了一个功能']
      [fix      '修复缺陷 | 修复了一个 Bug']
      [docs     '文档更新 | 修改文档，例如修改 README 文件、API 文档等']
      [style    '代码格式 | 修改代码的样式，例如调整缩进、空格、空行等']
      [refactor '代码重构 | 重构代码，例如修改代码结构、变量名、函数名等但不修改功能逻辑']
      [perf     '性能提升 | 优化性能，例如提升代码的性能、减少内存占用等']
      [test     '测试相关 | 修改测试用例，例如添加、删除、修改代码的测试用例等']
      [build    '构建相关 | 修改项目构建系统，例如修改依赖库、外部接口或者升级 Node 版本等']
      [ci       '持续集成 | 更改 CI 配置文件或脚本']
      [revert   '回退代码 | 回退一个或多个更改']
      [chore    '非业务性 | 对非业务性代码进行修改，例如修改构建流程或者工具配置等']
      [misc     '暂未归类 | 一些未分类或不知道如何分类的更改']
    ]
  }

  if ($env.GIT_COMMIT_EMOJI? | is-empty) {
    $env.GIT_COMMIT_EMOJI = {
      feat: '✨'
      fix: '🐛'
      docs: '📚'
      style: '💎'
      refactor: '📦'
      perf: '🚀'
      test: '🚨'
      build: '🛠'
      ci: '👷'
      revert: '⏪'
      chore: '🔧'
      misc: '🧩'
    }
  }

  if ($env.GIT_USE_EMOJI? | is-empty) {
    $env.GIT_USE_EMOJI = false
  }

  if ($env.GIT_EMOJI_ALIGN? | is-empty) {
    $env.GIT_EMOJI_ALIGN = 'center'
  }
}

const GIT_SCOPES_KEY = 'nushell.scopes'
const SEPARATOR = '»¦«'

def cmpl-types [] {
  $env.GIT_COMMIT_TYPE
}

def cmpl-scopes [] : nothing -> list<string> {
  ^git config get --local --default='' $GIT_SCOPES_KEY | split row $SEPARATOR
}

def cmpl-emoji-aligns [] : nothing -> list<string> {
  ["left" "center" "right"]
}

def get-emoji-symbol [type: string] : nothing -> string {
  let emoji = ^git config get --local --default='' $'nushell.emoji.($type)'

  if ( $emoji | is-empty ) {
    print $'(ansi yellow)Warning: type not found in nushell.emoji.($type) config(ansi reset)'
    print $'(ansi yellow)You can set it by running: (ansi reset)'
    print $'(ansi yellow)(char tab)git config set --local nushell.emoji.($type) "your-emoji-symbol"(ansi reset)'
    $env.GIT_COMMIT_EMOJI | get $type
  } else {
    $emoji
  }
}

def check-use-emoji [] : nothing -> bool {
  # 优先级: 当前仓库gitconfig > 环境变量
  let emoji = ^git config get --local --default='' 'nushell.useEmoji'
  if ($emoji == '') {
    $env.GIT_USE_EMOJI
  } else {
    $emoji | into bool
  }
}

def get-emoji-align [] : nothing -> string {
  # 优先级: 当前仓库gitconfig > 环境变量
  let align = ^git config get --local --default='' 'nushell.emojiAlign'
  if ($align == '') {
    $env.GIT_EMOJI_ALIGN
  } else {
    $align
  }
}

# 提交修改范围
export def git-commit-scope [
  --set(-s): list<string>
] : nothing -> list<string> {
  if ($set != null) {
    ^git config set --local $GIT_SCOPES_KEY ($set | str join $SEPARATOR)
  }
  ^git config get --local --default='' $GIT_SCOPES_KEY | split row $SEPARATOR
}

# 实现规范化提交信息的功能
export def git-commit [
  subject_message: string                 # 提交标题描述
  body?: string                           # 提交描述
  --type(-t): string@cmpl-types           # 指定提交类型
  --scope(-s): string@cmpl-scopes         # 指定提交范围
  --emoji(-e)                             # 使用表情符号
  --no-emoji                              # 不使用表情符号
  --emoji-align: string@cmpl-emoji-aligns # 表情符号对齐方式 (<left> type(scope): <center> subject <right>)

  --all(-A)                               # 自动暂存所有已修改和已删除的文件
  --amend(-a)                             # 修改上一次提交而不是添加新提交
  --allow-empty                           # 允许没有更改的提交
  --allow-empty-message                   # 允许空消息的提交
  --gpg-sign                              # GPG 签署提交
  --no-gpg-sign                           # 不 GPG 签署提交
  --no-edit                               # 不编辑提交信息
  --author: string                        # 覆盖提交作者
  --date: string                          # 覆盖作者日期

] : nothing -> nothing {
  let emoji_align = if ($emoji_align | is-empty) { get-emoji-align } else { $emoji_align }

  mut subject = []

  if ((not $no_emoji) and ($emoji or (check-use-emoji)) and ($emoji_align == 'left')) { $subject ++= [ (get-emoji-symbol $type) ] }

  if ($scope | is-not-empty) {
    if ($type | is-empty) {
      print $'(ansi red)Error: scope requires a type(ansi reset)'
      return
    }
    $subject ++= [ ($type + "(" + $scope + "):") ]
  } else if ($type | is-not-empty) {
    $subject ++= [ $'($type):' ]
  }

  if ((not $no_emoji) and ($emoji or (check-use-emoji)) and ($emoji_align == 'center')) { $subject ++= [ (get-emoji-symbol $type) ] }

  $subject ++= [ ($subject_message | str trim) ]

  if ((not $no_emoji) and ($emoji or (check-use-emoji)) and ($emoji_align == 'right')) { $subject ++= [ (get-emoji-symbol $type) ] }

  mut message = [ ($subject | str join ' ') ]

  if ($body | is-not-empty) { $message ++= [ ($body | str trim) ] }

  # skip: footer

  let message = ($message | str join $'(char newline)(char newline)')

  print $message

  mut args = [ --message $message ]
  if $all { $args ++= [ --all ] }
  if $amend { $args ++= [ --amend ] }
  if $allow_empty { $args ++= [ --allow-empty ] }
  if $allow_empty_message { $args ++= [ --allow-empty-message ] }
  if $gpg_sign { $args ++= [ --gpg-sign ] }
  if $no_gpg_sign { $args ++= [ --no-gpg-sign ] }
  if $no_edit { $args ++= [ --no-edit ] }
  if ($author | is-not-empty) { $args ++= [ --author $author ] }
  if ($date | is-not-empty) { $args ++= [ --date $date ] }

  ^git commit ...$args
}
