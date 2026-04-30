# mdtk nushell completions

# markdown toolkit
export extern "mdtk" [
  command?: string@[]

  --version # 显示版本
  --help(-h) # 显示帮助
]

# 下载 MARKDOWN_FILE 中的图片并将链接改写为本地路径
export extern "mdtk img" [
  markdown_file: path # 待处理的 markdown 文件
  --output(-o): path # 改写后的 markdown 输出文件；默认写 stdout
  --attachment: path # 附件（图片）目录；默认 <output dir>/attachments/<output stem>/
  --absolute: path # 将图片链接改写为 root-absolute 路径，剥离此前缀（. 表示当前工作目录）
  --concurrency(-c): int # 并发下载数，默认 8，≥1
  --timeout(-t): number # 单次 HTTP 超时秒，默认 30.0，≥0.1
  --user-agent: string # HTTP User-Agent
  --max-bytes: int # 单张图大小上限字节，默认 52428800（50 MiB），≥1
  --redownload # 强制重新抓取远程 URL 并重新复制本地文件
  --no-progress # 抑制 stderr 进度条
  --verbose(-v) # 详细输出
  --help(-h) # 显示帮助
]

# 抓取 URL 并输出 markdown（默认走 Jina Reader）
export extern "mdtk read" [
  url: string@[] # 待抓取的 URL
  --json # 输出结构化 JSON 而非 markdown+frontmatter
  --output(-o): path # 写入文件而非 stdout
  --timeout(-t): number # HTTP 超时秒，默认 30.0，≥0.1
  --no-auth # 即使设置了 JINA_API_KEY 也不发送
  --verbose(-v) # 详细输出
  --help(-h) # 显示帮助
]
