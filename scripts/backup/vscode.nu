use mod_utils.nu *

def "nu-complete profile-name-list" [] : nothing -> list<string> {
  # todo: await VSCode API
  # https://github.com/microsoft/vscode/issues/211890
  # Provide API to access Profiles
  ('~/AppData/Roaming/Code/User/globalStorage/storage.json' | open).userDataProfiles.name
}

# export def "backup vscode" [] {}

# 备份 VSCode 扩展列表
export def "backup vscode extensions" [
  profile_name?: string@"nu-complete profile-name-list"
] : [
  nothing -> string
  string -> string
  nothing -> nothing
  string -> nothing
] {
  let profile_name = if $profile_name != null { $profile_name } else if $in != null { $in } else { null }

  let extensions_str: string = if $profile_name == null {
      ^code --list-extensions
  } else {
      ^code --list-extensions --profile $profile_name
  }

  return ({ "recommendations": ($extensions_str | lines) } | to json --indent 2)
}
