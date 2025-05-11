# todo: 处理 "finish_reason":"length"
# todo: 为什么阻塞了？为什么没有流式输出

use internal.nu *

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
  --stdout(-o)=true # 是否同时输出到控制台
  --token(-t) # 控制台是否显示消耗的 token 数
  --return(-r) # 是否返回结果
] : [
  string -> record
  string -> nothing
] {
  let api_key = if $api_key != null { $api_key } else { $env.MOONSHOT_API_KEY }

  # note: 需要转化换行符
  let system_content = ($system_prompt | to-raw)
  let user_content = ($in | to-raw)
  let headers = ['Content-Type' 'application/json' "Authorization" $"Bearer ($api_key)"]
  let json_body = $'{
    "model": "($model)",
    "messages": [
        {"role": "system", "content": "($system_content)"},
        {"role": "user", "content": "($user_content)"}
    ],
    "temperature": ($TEMPERATURE),
    "stream": true
  }'

  # note: 管道是支持字节流的
  let result = (http post --headers $headers $BASE_URL $json_body |
    from-sse |
    kimi-adapter |
    reduce --fold {data: ''} {|it, acc|
    let data: string = $it.data
    if $stdout {
      print --no-newline --raw $data
    }
    if 'usage' in $it {
      $acc | upsert usage $it.usage
    }
    $acc | update data ($acc.data + $data)
    # $acc
  })

  if $stdout {
    print ''
    if $token {
      if ('usage' not-in $result) {
        error make {msg: "未获取到 token 数"}
      }
      print --no-newline --raw $"(ansi green)消耗的 token 数: ($result.usage.total_tokens)(ansi green)"
    }
  }

  if $return {
    return $result
  }
}

# 选择预制方案执行
export def main [
  --temperature(-t): number = $TEMPERATURE # 随机性
  --model(-m): string@get-model-list = $MODEL # 模型名称
  --api_key(-k): string # 密钥
  --stdout(-o)=true # 是否直接输出到控制台（如果按string返回，那么则是一次性输出）
  --token(-t) # 控制台是否显示消耗的 token 数
  --return(-r) # 是否返回结果
] : [
  string -> record
  string -> nothing
] {
  let api_key = if $api_key != null { $api_key } else { $env.MOONSHOT_API_KEY }

  let choose: int = ($env.KIMI_PRE_SOLUTIONS | get key | input list --index "请选择预制方案")
  if $choose == null {
    print $"(ansi yellow)未选择预制方案，已取消(ansi yellow)"
    return
  }

  $in | send --model $model --api_key $api_key --temperature $temperature --system_prompt ($env.KIMI_PRE_SOLUTIONS | get $choose | get value) --stdout=$stdout --token=$token --return=$return
}
