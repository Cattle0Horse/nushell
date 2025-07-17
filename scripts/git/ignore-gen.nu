# Constants
const GITHUB_API_URL = "https://api.github.com"
const GITIGNORE_REPO = "github/gitignore"
const GITIGNORE_RAW_URL = $"($GITHUB_API_URL)/repos/($GITIGNORE_REPO)/contents"
const GITHUB_RAW_CONTENT_BASE_URL = $"https://raw.githubusercontent.com/($GITIGNORE_REPO)/main"

const GITHUB_REPO_URL = $"https://github.com/($GITIGNORE_REPO).git"
const DATA_DIR = ([$nu.data-dir data git ignore] | path join)
const REPO_DIR = ($DATA_DIR | path join "repo")
const LAST_UPDATE_FILE = ($DATA_DIR | path join "config.json")
const UPDATE_INTERVAL = 604800  # 7 days in seconds

def ensure-directories [] {
  if not ($DATA_DIR | path exists) {
    mkdir $DATA_DIR
  }
}

def get-last-update [] {
  if not ($LAST_UPDATE_FILE | path exists) {
    return 0
  }
  open $LAST_UPDATE_FILE | get timestamp
}

def update-last-update [] {
  ensure-directories
  {timestamp: (date now | format date "%s" | into int)} | save -f $LAST_UPDATE_FILE
}

def should-update [] {
  let last_update = (get-last-update)
  let current_time = (date now | format date "%s" | into int)
  $current_time - $last_update > $UPDATE_INTERVAL
}

def clone-or-pull [] {
  if not ($REPO_DIR | path exists) {
    print "Cloning gitignore repository..."
    ^git clone $GITHUB_REPO_URL $REPO_DIR
  } else if (should-update) {
    ensure-directories
    print "Updating gitignore repository..."
    cd $REPO_DIR
    ^git pull origin main
    update-last-update
  }
}

def get-templates [
  --remote(-r) # Force fetch from remote
] : nothing -> list<string> {
  if $remote {
    http get $GITIGNORE_RAW_URL
  } else {
    clone-or-pull
    # 只获取根目录下的
    ls --short-names $REPO_DIR
  }
  | where name ends-with '.gitignore'
  | get name
}

def get-template-content [
  template: string
  --remote(-r) # Force fetch from remote
] {
  if $remote {
    let template_url = $'($GITHUB_RAW_CONTENT_BASE_URL)/($template)'
    http get --raw $template_url
  } else {
    clone-or-pull
    open --raw ($REPO_DIR | path join $template)
  }
}

def cmpl-ignore-gen-templates [] {
  get-templates | each {|it| str replace --regex '\.gitignore$' ''}
}

# 列出可用的gitignore模板
@example "List all templates" { git-ignore-gen-list } --result ["Actionscript.gitignore", "Ada.gitignore", "Agda.gitignore", "Android.gitignore", ...]
@example "Search for Python templates" { git-ignore-gen-list "Python" } --result ["Python.gitignore"]
@example "Force fetch from remote" { git-ignore-gen-list --remote } --result ["Actionscript.gitignore", "Ada.gitignore", "Agda.gitignore", "Android.gitignore", ...]
export def git-ignore-gen-list [
  term?: string # Search term
  --remote (-r) # Force fetch from remote
] : nothing -> list<string> {
  print "Fetching available templates..."
  get-templates --remote=$remote
  | if ($term | is-empty) {
    $in
  } else {
    $in | where $it =~ $term
  }
  | each { str replace --regex '\.gitignore$' '' }
  | sort
}

# 生成指定语言的gitignore文件
@example "Generate Python gitignore" { git-ignore-gen "Python" } --result "# Byte-compiled / optimized / DLL files\n__pycache__/\n*.py[cod]\n*$py.class\n\n# C extensions\n*.so\n\n# Distribution / packaging\n.Python\nbuild/\n..."
@example "Generate to specific directory" { git-ignore-gen "Python" --output . }
@example "Force overwrite existing file" { git-ignore-gen "Python" --force }
export def git-ignore-gen [
  template: string@cmpl-ignore-gen-templates # Template name
  --output(-o): path # Output file path
  --remote(-r) # Force fetch from remote
  --force(-f) # Overwrite existing file
] : [
  nothing -> string
  nothing -> nothing
] {
  let output_file = if ($output | is-empty) { '.gitignore' } else { $output | path join '.gitignore' }

  let template_name = $template + ".gitignore"

  print $"Generating ($template_name) to ($output_file)..."

  get-template-content $template_name --remote=$remote
  | if ($output | is-empty) {
    $in
  } else {
    $in | save --force=$force $output_file
    print $"Successfully generated ($output_file)"
  }
}

# 查看gitignore模板仓库状态
@example "Get repository status when exists" { git-ignore-gen-status } --result {
  status: true
  status_message: "Repository status fetched"
  porcelain_status: "clean"
  current_branch: "main"
  last_commit: "a1b2c3d Update templates"
  last_update: 2025-06-01
  next_update: 2025-06-08
  template_count: 200
  clone_time: 2025-05-25
}
@example "Get repository status when not exists" { git-ignore-gen-status } --result {
  status: false
  status_message: "Repository not found"
  porcelain_status: null
  current_branch: null
  last_commit: null
  last_update: null
  next_update: null
  template_count: null
  clone_time: null
}
export def git-ignore-gen-status [] : nothing -> record {
  if not ($REPO_DIR | path exists) {
    return {
      status: false
      status_message: "Repository not found"
      porcelain_status: null
      current_branch: null
      last_commit: null
      last_update: null
      next_update: null
      template_count: null
      clone_time: null
    }
  }

  let last_update_timestamp = get-last-update
  let next_update_timestamp = ($last_update_timestamp + $UPDATE_INTERVAL)

  cd $REPO_DIR

  let porcelain_status = ^git status --porcelain | if ($in | is-empty) { "clean" } else { "dirty" }
  let current_branch = ^git branch --show-current | str trim
  let last_commit = ^git log -1 --format="%h %s" | str trim
  let templates = ls --short-names $REPO_DIR | where name ends-with '.gitignore'
  let template_count = $templates | length
  let clone_time = ^git log -1 --reverse --format=%ct | str trim | into int | into datetime -f '%s'

  {
    status: true
    status_message: "Repository status fetched"
    porcelain_status: $porcelain_status
    current_branch: $current_branch
    last_commit: $last_commit
    last_update: ($last_update_timestamp | into datetime -f '%s')
    next_update: ($next_update_timestamp | into datetime -f '%s')
    template_count: $template_count
    clone_time: $clone_time
  }
}

# 更新gitignore模板仓库
@example "Update repository" { git-ignore-gen-update }
export def git-ignore-gen-update [] : nothing -> nothing {
  if ($REPO_DIR | path exists) {
    cd $REPO_DIR
    ^git pull origin main
    update-last-update
    print "Repository updated successfully"
  } else {
    clone-or-pull
    print "Repository cloned successfully"
  }
}

# 清理本地gitignore模板仓库
@example "Clean repository with confirmation" { git-ignore-gen-clean }
@example "Force clean without confirmation" { git-ignore-gen-clean --force }
export def git-ignore-gen-clean [--force(-f)] : nothing -> nothing {
  if ($force or (input --default 'N' "Are you sure you want to clean the repository? (y/N):" | str trim) == 'y') {
    if ($REPO_DIR | path exists) {
      rm -rf $REPO_DIR
      rm -f $LAST_UPDATE_FILE
      print "Repository cleaned successfully"
    } else {
      print "Repository is already clean"
    }
  }
}
