export const DATA_DIR = ($nu.data-dir | path join data kimi)

export const SYSTEM_PROMPT = "你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。"
export const TEMPERATURE = 0.3
export const MODEL_LIST_URL = "https://api.moonshot.cn/v1/models"
export const BASE_URL = "https://api.moonshot.cn/v1/chat/completions"
export const MODEL = "moonshot-v1-auto"
export const MOONSHOT_API_KEY_PATH = ($DATA_DIR | path join key)
export const KIMI_PRE_SOLUTIONS_FOLDER_PATH = ($DATA_DIR | path join pre_solutions)

export def get-model-list-online [api_key: string] {
  http get $MODEL_LIST_URL --headers ["Authorization" $"Bearer ($api_key)"] | get data | get id
}

export def get-model-list [] {
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

export def "from-sse" [] {
  # generate 通过连续调用闭包生成值列表
  $in | lines | generate {|line pending = {data: []}|
    match ($line | split row -n 2 ":" | each { str trim }) {
      [$prefix $content] if $prefix == "id" => {
        return {next: ($pending | upsert id $content)}
      }

      [$prefix $content] if $prefix == "event" => {
        return {next: ($pending | upsert event $content)}
      }

      [$prefix $content] if $prefix == "data" => {
        return {next: ($pending | update data { append $content })}
        }

      [$empty] if $empty == "" => {
        if ($pending == {data: []}) {
          return {next: $pending}
        }
        return {next: {data: []} out: ($pending | update data { str join "\n" })}
      }

      _ => { error make {msg: $"unexpected: ($line)"} }
    }
  }
}

export def to-raw [] : string -> string {
  $in | str trim | str replace -a -r "(\r\n|\n|\r)" '\n'
}

export def "kimi-adapter" [ ] : list<any> -> list<record<data: string, usage?: record<prompt_tokens: int, completion_tokens: int, total_tokens: int>>> {
  $in | generate {|it pending=null|
    let data = ($it | get data)
    if $data == '[DONE]' {
      return {next: null}
    }
    let json = ($data | from json).choices.0
    let out = {data: ($json.delta | get --ignore-errors content | default '')}
    if 'usage' in $json {
      return {next: null out: ($out | upsert usage $json.usage)}
    }
    return {next: null out: $out}
  }
}
