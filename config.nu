const NU_LIB_DIRS = [
  "~/.config/nushell/scripts"
]

# const NU_PLUGIN_DIRS = [
#   ($nu.current-exe | path dirname)
#   ...$NU_PLUGIN_DIRS
# ]

$env.config.show_banner = false
$env.config.buffer_editor = "code"

# 终端使用 utf-8 字符集
do { ^chcp 65001 } | ignore

# alias 应该在 complete 之后，否则补全不会应用与 alias 的命令

use git *
use backup *
use filesystem *
use str *

use bilibili
use bilibili/alias.nu *
use kimi
use link
use chcp

use completions/scoop/scoop_zh.nu *
use completions/git/git_zh.nu *
use completions/docker/docker_zh.nu *

# use completions/whisper-ctranslate2/whisper-ctranslate2_zh.nu *
# alias whisper = whisper-ctranslate2

# use completions/eza/eza_zh.nu *
# use eza


alias cc = code
# 创建并进入文件夹
def mc --env [folder: string] : nothing -> nothing { mkdir $folder; cd $folder }
