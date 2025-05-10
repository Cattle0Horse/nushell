export def "git home" [] : nothing -> path {
  ^git rev-parse --show-toplevel
}
