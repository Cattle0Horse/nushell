const SYS_ENV_PATH = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'

def extract-env [] : table -> list<string> {
  where name == Path | get value | split row ';' | where $it != ''
}

# 重新加载环境变量
export def --env reload-path [] {
  let user_path = registry query --hkcu environment | extract-env
  let sys_path = registry query --hklm $SYS_ENV_PATH | extract-env
  $env.path = ($user_path ++ $sys_path ++ $env.path | uniq --ignore-case)
}
