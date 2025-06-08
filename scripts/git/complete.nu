export def "nu-complete git remotes" [] {
  ^git remote | lines | each { |line| $line | str trim }
}
