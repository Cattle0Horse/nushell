# open or close a feature/bugfix/hotfix branch
use complete.nu *

export-env {
  if 'GIT_FLOW' not-in $env {
    $env.GIT_FLOW = {
      branches: {
        dev: dev
        main: main
        release: release
        hotfix: hotfix
        bugfix: bugfix
        feature: feature
      }
      separator: '/'
    }
  }
}

def git-kind-select [
  kind: string
  sep: string
] : nothing -> list<string> {
  ^git for-each-ref --no-color --format='%(refname:short)' refs/heads/
  | lines
  | where ($it | str starts-with $"($kind)($sep)")
}

# open a new feature branch
export def git-open-feature [
  name: string
  base?: string@cmpl-git-local-branches
] : nothing -> nothing {
  let prefix = $env.GIT_FLOW.branches.feature
  let sep = $env.GIT_FLOW.separator
  if ($base | is-empty) {
    ^git checkout -b $"($prefix)($sep)($name)"
  } else {
    ^git checkout -b $"($prefix)($sep)($name)" $base
  }
}

# open a new bugfix branch
export def git-open-bugfix [
  name: string
  base?: string@cmpl-git-local-branches
] : nothing -> nothing {
  let prefix = $env.GIT_FLOW.branches.bugfix
  let sep = $env.GIT_FLOW.separator
  if ($base | is-empty) {
    ^git checkout -b $"($prefix)($sep)($name)"
  } else {
    ^git checkout -b $"($prefix)($sep)($name)" $base
  }
}

# open a new hotfix branch
export def git-open-hotfix [
  name: string
  base?: string@cmpl-git-local-branches
] : nothing -> nothing {
  let prefix = $env.GIT_FLOW.branches.hotfix
  let sep = $env.GIT_FLOW.separator
  if ($base | is-empty) {
    ^git checkout -b $"($prefix)($sep)($name)"
  } else {
    ^git checkout -b $"($prefix)($sep)($name)" $base
  }
}
