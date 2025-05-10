# todo: 缓存模型列表，避免每次请求都要重新加载
# todo: 流式输出

const DATA_DIR = ($nu.data-dir | path join data kimi)

const SYSTEM_PROMPT = "你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。"
const TEMPERATURE = 0.3
const MODEL_LIST_URL = "https://api.moonshot.cn/v1/models"
const BASE_URL = "https://api.moonshot.cn/v1/chat/completions"
const MODEL = "moonshot-v1-auto"
const MOONSHOT_API_KEY_PATH = ($DATA_DIR | path join key)
const KIMI_PRE_SOLUTIONS_FOLDER_PATH = ($DATA_DIR | path join pre_solutions)

def get-model-list-online [api_key: string] {
  http get $MODEL_LIST_URL --headers ["Authorization" $"Bearer ($api_key)"] | get data | get id
}

def get-model-list [] {
  [
    'moonshot-v1-auto'
    'moonshot-v1-8k'
    'moonshot-v1-32k'
    'moonshot-v1-128k'
    'moonshot-v1-8k-vision-preview'
    'moonshot-v1-32k-vision-preview'
    'moonshot-v1-128k-vision-preview'
    'kimi-latest'
  ]
}

export-env {
  if ($MOONSHOT_API_KEY_PATH | path exists) {
    $env.MOONSHOT_API_KEY = open $MOONSHOT_API_KEY_PATH --raw | str trim
  }
  if ($KIMI_PRE_SOLUTIONS_FOLDER_PATH | path exists) {
    $env.KIMI_PRE_SOLUTIONS = (ls -f $KIMI_PRE_SOLUTIONS_FOLDER_PATH).name | reduce --fold {} {|file, acc|
      let data = ($file | open --raw | split row -n 2 (char newline)) | str trim
      if ($data | length) < 2 {
        $acc
      } else {
        $acc | insert $data.0 $data.1
      }
    } | transpose key value
  }
}

# 从环境指定的文件中读取 cookie
export def get-cookie [] : [nothing -> string] {
  $env.MOONSHOT_API_KEY
}

# 保存 cookie 到环境变量指定的文件中
export def save-cookie [] : [string -> nothing] {
  $in | save -f $MOONSHOT_API_KEY_PATH
}

# 单次聊天
export def send [
  --system_prompt(-p): string = $SYSTEM_PROMPT # 系统提示词
  --temperature(-t): number = $TEMPERATURE # 随机性
  --model(-m): string@get-model-list = $MODEL # 模型名称
  --api_key(-k): string # 密钥
  # --stream=true # 是否流式输出，目前只允许流式输出（因为非流失输出当响应过大时，响应不完全）
  --stdout(-o)=true # 是否直接输出到控制台（如果按string返回，那么则是一次性输出）
] : [
  string -> string
  string -> nothing
] {
  let api_key = if $api_key != null { $api_key } else { $env.MOONSHOT_API_KEY }

  # note: 需要转化换行符
  let system_content = ($system_prompt | str trim | str replace -a -r "(\r\n|\n|\r)" '\n')
  let user_content = ($in | str trim | str replace -a -r "(\r\n|\n|\r)" '\n')

  let result = (http post $BASE_URL --headers [
    'Content-Type' 'application/json'
    "Authorization" $"Bearer ($api_key)"] $'{
    "model": "($model)",
    "messages": [
        {"role": "system", "content": "($system_content)"},
        {"role": "user", "content": "($user_content)"}
    ],
    "temperature": ($TEMPERATURE),
    "stream": true
  }' | lines | each {|line|
    if ($line | str starts-with 'data: ') {
      if ( $line == 'data: [DONE]' ) {
        return ''
      }
      let data = ($line | str substring 6.. | from json).choices.delta.content.0
      if $stdout { print --no-newline --raw $data }
      return $data
    }
  } | where { $in | is-not-empty } | str join '')

  if not $stdout {
    return $result
  }
}

# 选择预制方案执行
export def main [
  --temperature(-t): number = $TEMPERATURE # 随机性
  --model(-m): string@get-model-list = $MODEL # 模型名称
  --api_key(-k): string # 密钥
  --stdout(-o)=true # 是否直接输出到控制台（如果按string返回，那么则是一次性输出）
] : [
  string -> string
  string -> nothing
] {
  let api_key = if $api_key != null { $api_key } else { $env.MOONSHOT_API_KEY }

  let choose: int = ($env.KIMI_PRE_SOLUTIONS | get key | input list --index "请选择预制方案")
  if $choose == null {
    print $"(ansi yellow)未选择预制方案，已取消(ansi yellow)"
    return
  }

  $in | send --model $model --api_key $api_key --temperature $temperature --system_prompt ($env.KIMI_PRE_SOLUTIONS | get $choose | get value) --stdout=$stdout
}
