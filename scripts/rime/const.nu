# Rime 配置常量

# GitHub 源配置
export const SCHEMA_OWNER = "amzxyz"
export const SCHEMA_REPO = "rime_wanxiang"
export const GRAM_REPO = "RIME-LMDG"
export const GRAM_RELEASE_TAG = "LTS"

# 模型文件配置
export const GRAM_MODEL_FILENAME = "wanxiang-lts-zh-hans.gram"
export const GRAM_KEY_TABLE = {
  "0": "zh-hans.gram"
}
export const GRAM_FILE_TABLE_INDEX = 0

# 文件和路径配置
export const RELEASE_TIME_RECORD_FILE = "release_time_record.json"

# 缓存目录配置
export const RIME_CACHE_DIR = ([$nu.cache-dir "rime"] | path join)
export const CACHE_METADATA_FILE = "cache_metadata.json"

# 数据目录配置
export const RIME_DATA_DIR = ([$nu.data-dir "data" "rime"] | path join)

# GitHub API 配置
export const GITHUB_API_HEADERS = {
  "User-Agent": "Nushell Rime Updater",
  "Accept": "application/vnd.github.v3+json"
}

# 小狼毫注册表路径
export const WEASEL_USER_DIR_REG_PATH = 'HKCU\Software\Rime\Weasel'
export const WEASEL_USER_DIR_REG_KEY = "RimeUserDir"
export const WEASEL_INSTALL_DIR_REG_PATH = 'HKLM\SOFTWARE\WOW6432Node\Rime\Weasel'
export const WEASEL_INSTALL_DIR_REG_KEY = "WeaselRoot"
export const WEASEL_SERVER_EXECUTABLE_REG_KEY = "ServerExecutable"

# 默认路径
export const DEFAULT_RIME_USER_DIR = ([$nu.home-dir "AppData" "Roaming" "Rime"] | path join)

# 缓存文件名生成函数
export def get-cache-filename [asset_info: record] {
  let timestamp = ($asset_info.updated_at | into datetime | format date "%Y%m%d_%H%M%S")
  let name_parts = ($asset_info.name | split row ".")
  let extension = ($name_parts | last)
  let basename = ($name_parts | drop | str join ".")
  return $"($basename)_($timestamp).($extension)"
}
