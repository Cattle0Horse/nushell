# 模型选项补全
def "nu-complete whisper-ctranslate2 models" [] {
    [
        [value];
        ["tiny"] ["tiny.en"] ["base"] ["base.en"] ["small"] ["small.en"]
        ["medium"] ["medium.en"] ["large-v1"] ["large-v2"] ["large-v3"]
        ["large-v3-turbo"] ["turbo"] ["distil-large-v2"] ["distil-large-v3"]
        ["distil-medium.en"] ["distil-small.en"]
    ]
}

# 输出格式补全
def "nu-complete whisper-ctranslate2 output-formats" [] {
    [[value]; ["txt"] ["vtt"] ["srt"] ["tsv"] ["json"] ["all"]]
}

# 设备类型补全
def "nu-complete whisper-ctranslate2 devices" [] {
    [[value]; ["auto"] ["cpu"] ["cuda"]]
}

# 计算类型补全
def "nu-complete whisper-ctranslate2 compute-types" [] {
    [
        [value];
        ["default"] ["auto"] ["int8"] ["int8_float16"] ["int8_bfloat16"]
        ["int8_float32"] ["int16"] ["float16"] ["float32"] ["bfloat16"]
    ]
}

# 任务类型补全
def "nu-complete whisper-ctranslate2 tasks" [] {
    [[value]; ["transcribe"] ["translate"]]
}

# 语言补全
def "nu-complete whisper-ctranslate2 languages" [] {
    [
        [value];
        ["af"] ["am"] ["ar"] ["as"] ["az"] ["ba"] ["be"] ["bg"] ["bn"] ["bo"]
        ["br"] ["bs"] ["ca"] ["cs"] ["cy"] ["da"] ["de"] ["el"] ["en"] ["es"]
        ["et"] ["eu"] ["fa"] ["fi"] ["fo"] ["fr"] ["gl"] ["gu"] ["ha"] ["haw"]
        ["he"] ["hi"] ["hr"] ["ht"] ["hu"] ["hy"] ["id"] ["is"] ["it"] ["ja"]
        ["jw"] ["ka"] ["kk"] ["km"] ["kn"] ["ko"] ["la"] ["lb"] ["ln"] ["lo"]
        ["lt"] ["lv"] ["mg"] ["mi"] ["mk"] ["ml"] ["mn"] ["mr"] ["ms"] ["mt"]
        ["my"] ["ne"] ["nl"] ["nn"] ["no"] ["oc"] ["pa"] ["pl"] ["ps"] ["pt"]
        ["ro"] ["ru"] ["sa"] ["sd"] ["si"] ["sk"] ["sl"] ["sn"] ["so"] ["sq"]
        ["sr"] ["su"] ["sv"] ["sw"] ["ta"] ["te"] ["tg"] ["th"] ["tk"] ["tl"]
        ["tr"] ["tt"] ["uk"] ["ur"] ["uz"] ["vi"] ["yi"] ["yo"] ["yue"] ["zh"]
        ["Afrikaans"] ["Albanian"] ["Amharic"] ["Arabic"] ["Armenian"] ["Assamese"]
        ["Azerbaijani"] ["Bashkir"] ["Basque"] ["Belarusian"] ["Bengali"] ["Bosnian"]
        ["Breton"] ["Bulgarian"] ["Burmese"] ["Cantonese"] ["Castilian"] ["Catalan"]
        ["Chinese"] ["Croatian"] ["Czech"] ["Danish"] ["Dutch"] ["English"] ["Estonian"]
        ["Faroese"] ["Finnish"] ["Flemish"] ["French"] ["Galician"] ["Georgian"] ["German"]
        ["Greek"] ["Gujarati"] ["Haitian"] ["Haitian Creole"] ["Hausa"] ["Hawaiian"]
        ["Hebrew"] ["Hindi"] ["Hungarian"] ["Icelandic"] ["Indonesian"] ["Italian"]
        ["Japanese"] ["Javanese"] ["Kannada"] ["Kazakh"] ["Khmer"] ["Korean"] ["Lao"]
        ["Latin"] ["Latvian"] ["Letzeburgesch"] ["Lingala"] ["Lithuanian"] ["Luxembourgish"]
        ["Macedonian"] ["Malagasy"] ["Malay"] ["Malayalam"] ["Maltese"] ["Mandarin"]
        ["Maori"] ["Marathi"] ["Moldavian"] ["Moldovan"] ["Mongolian"] ["Myanmar"]
        ["Nepali"] ["Norwegian"] ["Nynorsk"] ["Occitan"] ["Panjabi"] ["Pashto"]
        ["Persian"] ["Polish"] ["Portuguese"] ["Punjabi"] ["Pushto"] ["Romanian"]
        ["Russian"] ["Sanskrit"] ["Serbian"] ["Shona"] ["Sindhi"] ["Sinhala"]
        ["Sinhalese"] ["Slovak"] ["Slovenian"] ["Somali"] ["Spanish"] ["Sundanese"]
        ["Swahili"] ["Swedish"] ["Tagalog"] ["Tajik"] ["Tamil"] ["Tatar"] ["Telugu"]
        ["Thai"] ["Tibetan"] ["Turkish"] ["Turkmen"] ["Ukrainian"] ["Urdu"] ["Uzbek"]
        ["Valencian"] ["Vietnamese"] ["Welsh"] ["Yiddish"] ["Yoruba"]
    ]
}

# 布尔值补全
def "nu-complete whisper-ctranslate2 boolean" [] {
    [[value]; ["True"] ["False"]]
}

# whisper-ctranslate2 命令定义
export extern "whisper-ctranslate2" [
    ...audio: path                                              # 要转录的音频文件
    --help(-h)                                                  # 显示帮助信息并退出
    --version                                                   # 显示程序版本号并退出

    # 模型选择选项
    --model: string@"nu-complete whisper-ctranslate2 models"    # 要使用的Whisper模型名称（默认：small）
    --model_directory: path                                     # 查找CTranslate2 Whisper模型的目录（例如微调模型）

    # 模型缓存控制选项
    --model_dir: path                                           # 保存模型文件的路径；默认使用~/.cache/huggingface/
    --local_files_only: string@"nu-complete whisper-ctranslate2 boolean" # 仅使用缓存中的模型，不连接互联网检查是否有更新版本

    # 控制生成输出的配置选项
    --output_dir(-o): path                                      # 保存输出的目录（默认：.）
    --output_format(-f): string@"nu-complete whisper-ctranslate2 output-formats" # 输出文件格式；如果未指定，将生成所有可用格式
    --pretty_json(-p): string@"nu-complete whisper-ctranslate2 boolean" # 以人类可读格式生成json
    --print_colors: string@"nu-complete whisper-ctranslate2 boolean" # 使用实验性颜色编码策略打印转录文本，突出显示高置信度或低置信度的单词
    --verbose: string@"nu-complete whisper-ctranslate2 boolean" # 是否打印进度和调试消息
    --highlight_words: string@"nu-complete whisper-ctranslate2 boolean" # 在srt和vtt输出格式中突出显示每个单词（需要--word_timestamps True）
    --max_line_width: int                                       # 在srt和vtt输出格式中，行中字符的最大数量（需要--word_timestamps True）
    --max_line_count: int                                       # 在srt和vtt输出格式中，段落中的最大行数（需要--word_timestamps True）
    --max_words_per_line: int                                   # 每行最大单词数（需要--word_timestamps True，与--max_line_width无关）

    # 计算配置选项
    --device: string@"nu-complete whisper-ctranslate2 devices" # 用于CTranslate2推理的设备（默认：auto）
    --threads: int                                             # 用于CPU推理的线程数（默认：0）
    --device_index: int                                        # 放置模型的设备ID（默认：0）
    --compute_type: string@"nu-complete whisper-ctranslate2 compute-types" # 要使用的量化类型

    # 算法执行选项
    --task: string@"nu-complete whisper-ctranslate2 tasks"     # 执行X->X语音识别（'transcribe'）或X->英语翻译（'translate'）
    --language: string@"nu-complete whisper-ctranslate2 languages" # 音频中使用的语言，指定None执行语言检测
    --temperature: number                                      # 用于采样的温度（默认：0）
    --temperature_increment_on_fallback: number                # 当解码失败时增加的温度（默认：0.2）
    --prompt_reset_on_temperature: number                      # 如果温度高于此值，则重置提示（默认：0.5）
    --prefix: string                                           # 为第一个窗口提供的可选前缀文本
    --best_of: int                                             # 使用非零温度采样时的候选数量（默认：5）
    --beam_size: int                                           # 波束搜索中的波束数量，仅在温度为零时适用（默认：5）
    --patience: number                                         # 波束解码中使用的可选耐心值（默认：1.0）
    --length_penalty: number                                   # 可选的令牌长度惩罚系数（默认：1.0）
    --suppress_blank: string@"nu-complete whisper-ctranslate2 boolean" # 在采样开始时抑制空白输出
    --suppress_tokens: string                                  # 采样期间要抑制的令牌ID的逗号分隔列表
    --initial_prompt: string                                   # 为第一个窗口提供的可选提示文本
    --condition_on_previous_text: string@"nu-complete whisper-ctranslate2 boolean" # 是否将模型的前一个输出作为下一个窗口的提示
    --compression_ratio_threshold: number                      # 如果gzip压缩比高于此值，则视为解码失败（默认：2.4）
    --logprob_threshold: number                                # 如果平均对数概率低于此值，则视为解码失败（默认：-1.0）
    --no_speech_threshold: number                              # 如果<|nospeech|>令牌的概率高于此值且解码因logprob_threshold而失败，则将该段视为静音（默认：0.6）
    --word_timestamps: string@"nu-complete whisper-ctranslate2 boolean" # 提取单词级时间戳并基于它们优化结果
    --prepend_punctuations: string                              # 如果word_timestamps为True，将这些标点符号与下一个单词合并
    --append_punctuations: string                               # 如果word_timestamps为True，将这些标点符号与前一个单词合并
    --repetition_penalty: number                                # 应用于先前生成的令牌分数的惩罚（设置>1以惩罚）（默认：1.0）
    --no_repeat_ngram_size: int                                 # 防止重复此大小的ngrams（设置0以禁用）（默认：0）
    --hallucination_silence_threshold: number                   # 当word_timestamps为True时，检测到可能的幻觉时跳过长于此阈值的静音期（以秒为单位）
    --hotwords: string                                          # 模型的热词/提示短语，对于你希望模型优先考虑的名称很有用
    --batched: string@"nu-complete whisper-ctranslate2 boolean" # 使用批处理转录，可提供额外2x-4x速度提升
    --batch_size: int                                           # 使用批处理转录时，用于解码的最大并行请求数
    --multilingual: string@"nu-complete whisper-ctranslate2 boolean" # 对每个段落执行语言检测

    # VAD过滤器参数
    --vad_filter: string@"nu-complete whisper-ctranslate2 boolean" # 启用语音活动检测(VAD)以过滤掉没有语音的音频部分
    --vad_threshold: number                                     # 启用vad_filter时，高于此值的概率被视为语音
    --vad_min_speech_duration_ms: int                           # 启用vad_filter时，短于min_speech_duration_ms的最终语音块将被丢弃
    --vad_max_speech_duration_s: number                         # 启用vad_filter时，语音块的最大持续时间（秒）
    --vad_min_silence_duration_ms: int                          # 启用vad_filter时，每个语音块结束时等待分离的时间

    # 说话人分离选项
    --hf_token: string                                          # 启用下载说话人分离模型的HuggingFace令牌
    --speaker_name: string                                      # 用于标识说话者的名称（例如SPEAKER_00）
    --speaker_num: int                                          # 用于说话人分离的说话者数量

    # 实时转录选项
    --live_transcribe: string@"nu-complete whisper-ctranslate2 boolean" # 实时转录模式
    --live_volume_threshold: number                             # 在实时转录模式下激活监听的最小音量阈值
    --live_input_device: int                                    # 设置实时流输入设备ID
    --live_input_device_sample_rate: int                        # 设置输入设备的实时采样率
]
