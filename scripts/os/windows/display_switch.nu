export-env {
  if ($env.DISPLAY_SWITCH_PATH? | is-empty) {
    $env.DISPLAY_SWITCH_PATH = 'C:/Windows/System32/DisplaySwitch.exe'
  }
}

def cmpl-display-switch [] {
  [
    ['value',   'description' ];
    ['internal' '仅电脑屏幕'  ]
    ['external' '仅外接屏幕'  ]
    ['clone'    '复制电脑屏幕']
    ['extend'   '扩展电脑屏幕']
  ]
}

# 显示屏切换
export def display-switch [way?: string@cmpl-display-switch] : nothing -> nothing {
  ^$env.DISPLAY_SWITCH_PATH $'/($way)'
}
