sdorfehs = {}

require("sdorfehs/frames")
require("sdorfehs/windows")
require("sdorfehs/events")
require("sdorfehs/utils")

-- configuration:
sdorfehs.gap = 10
sdorfehs.outline_secs = 2
sdorfehs.apps_to_watch = "^iTerm"

sdorfehs.is_initialized = false
sdorfehs.events = hs.uielement.watcher

-- frame rects, keyed by frame number
sdorfehs.frames = {}
sdorfehs.frame_previous = 1
sdorfehs.frame_current = 1

sdorfehs.direction = {
  LEFT = 1,
  RIGHT = 2,
  DOWN = 3,
  UP = 4,
}

sdorfehs.position = {
  FRONT = 1,
  BACK = 2,
}

-- windows, array by window stack order
sdorfehs.windows = {}

-- apps, keyed by pid
sdorfehs.apps = {}

-- let's go
sdorfehs.start = function()
  local s = sdorfehs

  s.log = hs.logger.new("sdorfehs", "debug")

  s.menu = hs.menubar.new()
  s.menu:setTitle("-")

  s.modal = hs.hotkey.modal.new("ctrl", "a")

  -- initial frame
  s.frames[1] = hs.screen.primaryScreen():frame()

  -- watch for new apps launched
  s.app_watcher = hs.application.watcher.new(s.app_meta_event)
  s.app_watcher:start()

  -- watch existing apps
  local apps = hs.application.runningApplications()
  for i = 1, #apps do
    s.watch_app(apps[i])
  end

  -- XXX
  s.outline(s.frames[s.frame_current])

  function s.modal:entered()
    s.menu:setTitle("◉")
  end

  function s.modal:exited()
    s.menu:setTitle("-")
  end

  s.modal:bind("", "escape", function()
    s.modal:exit()
  end)

  s.modal:bind("", "tab", function()
    s.frame_focus(s.frame_previous)
    s.modal:exit()
  end)

  s.modal:bind("", "left", function()
    s.frame_focus(s.frame_find(s.frame_current, s.direction.LEFT))
    s.modal:exit()
  end)
  s.modal:bind("control", "left", function()
    -- TODO
    s.modal:exit()
  end)

  s.modal:bind("", "right", function()
    s.frame_focus(s.frame_find(s.frame_current, s.direction.RIGHT))
    s.modal:exit()
  end)

  s.modal:bind("", "up", function()
    s.frame_focus(s.frame_find(s.frame_current, s.direction.UP))
    s.modal:exit()
  end)

  s.modal:bind("", "down", function()
    s.frame_focus(s.frame_find(s.frame_current, s.direction.DOWN))
    s.modal:exit()
  end)

  s.modal:bind("", "space", function()
    s.frame_cycle(s.frame_current)
    s.modal:exit()
  end)

  s.modal:bind("control", "space", function()
    s.frame_cycle(s.frame_current)
    s.modal:exit()
  end)

  s.modal:bind("shift", "S", function()
    s.frame_vertical_split(s.frame_current)
    s.modal:exit()
  end)

  s.modal:bind("", "s", function()
    s.frame_horizontal_split(s.frame_current)
    s.modal:exit()
  end)

  -- a: send a literal control+a
  -- TODO: figure out how to do this with a modal not of control+a
  s.modal:bind("", "a", function()
    s.alert "sending a"
    s.modal:exit()
    s.modal.k:disable()
    hs.eventtap.keyStroke({ "ctrl" }, "a")
    hs.timer.usleep(10000)
    s.modal.k:enable()
  end)

  -- c: create terminal window
  s.modal:bind("", "c", function()
    hs.osascript.applescript('tell application "iTerm2" to create window with default profile')
    s.modal:exit()
  end)
end

return sdorfehs
