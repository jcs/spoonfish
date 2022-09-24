sdorfehs = {}

require("sdorfehs/frames")
require("sdorfehs/windows")
require("sdorfehs/events")
require("sdorfehs/utils")

-- configuration:
sdorfehs.gap = 20
sdorfehs.apps_to_watch = "^kitty"
sdorfehs.frame_message_secs = 1
sdorfehs.outline_color = "#ff7f50"
sdorfehs.outline_size = 8


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
  REMOVE = 3,
}

sdorfehs.initialized = false
sdorfehs.events = hs.uielement.watcher

-- windows, array by window stack order
sdorfehs.windows = {}

-- apps, keyed by pid
sdorfehs.apps = {}

-- let's go
sdorfehs.start = function()
  local s = sdorfehs

  s.log = hs.logger.new("sdorfehs", "debug")

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

  sdorfehs.initialized = true

  s.in_modal = false
  s.send_modal = false

  s.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local key = hs.keycodes.map[event:getKeyCode()]
    local flags = event:getFlags()
    local ctrl = flags:containExactly({ "ctrl" })
    local nomod = flags:containExactly({}) or flags:containExactly({ "shift" })

    -- not sure why arrow keys come through with fn down
    if key == "up" or key == "down" or key == "left" or key == "right" then
      if flags:containExactly({ "ctrl", "fn" }) then
        ctrl = true
      elseif flags:containExactly({ "fn" }) then
        nomod = true
      end
    end

    if event:getType() ~= hs.eventtap.event.types.keyDown then
      return false
    end

    if not s.in_modal then
      if ctrl and key == "a" then
        if s.send_modal then
          s.send_modal = false
          return false
        end

        s.in_modal = true
        return true
      end

      -- not in modal, let event happen as normal
      return false
    end

    -- in-modal key bindings
    s.in_modal = false

    if flags:containExactly({ "shift" }) then
      key = string.upper(key)
    end

    sdorfehs.ignore_events = true

    if nomod then
      if key == "tab" then
        s.frame_focus(s.frame_previous, true)

      elseif key == "left" then
        s.frame_focus(s.frame_find(s.frame_current, s.direction.LEFT), true)
      elseif key == "right" then
        s.frame_focus(s.frame_find(s.frame_current, s.direction.RIGHT), true)
      elseif key == "up" then
        s.frame_focus(s.frame_find(s.frame_current, s.direction.UP), true)
      elseif key == "down" then
        s.frame_focus(s.frame_find(s.frame_current, s.direction.DOWN), true)

      elseif key == "space" then
        s.frame_cycle(s.frame_current, true)

      elseif key == "a" then
        s.send_modal = true
        hs.eventtap.keyStroke({ "ctrl" }, "a")

      elseif key == "c" then
        -- create terminal window
        sdorfehs.ignore_events = false
        local a = hs.appfinder.appFromName("kitty")
        if a == nil then
          hs.osascript.applescript('tell application "System Events" to ' ..
            'keystroke "n" using {command down}')
        else
          a:setFrontmost(false)
          hs.eventtap.keyStroke({ "cmd" }, "n")
        end

      elseif key == "p" then
        s.frame_reverse_cycle(s.frame_current, true)

      elseif key == "R" then
        s.frame_remove(s.frame_current)

      elseif key == "s" then
        s.frame_horizontal_split(s.frame_current)
      elseif key == "S" then
        s.frame_vertical_split(s.frame_current)
      end

    elseif ctrl then
      if key == "space" then
        s.frame_cycle(s.frame_current, true)

      elseif key == "a" then
        s.frame_reverse_cycle(s.frame_current, true)

      elseif key == "p" then
        s.frame_reverse_cycle(s.frame_current, true)

      elseif key == "left" then
        s.frame_swap(s.frame_current, s.frame_find(s.frame_current, s.direction.LEFT))
      elseif key == "right" then
        s.frame_swap(s.frame_current, s.frame_find(s.frame_current, s.direction.RIGHT))
      elseif key == "up" then
        s.frame_swap(s.frame_current, s.frame_find(s.frame_current, s.direction.UP))
      elseif key == "down" then
        s.frame_swap(s.frame_current, s.frame_find(s.frame_current, s.direction.DOWN))
      end
    end

    hs.timer.doAfter(0.25, function()
      sdorfehs.ignore_events = false
    end)

    -- swallow event
    return true
  end):start()

  sdorfehs.frame_vertical_split(1)
  sdorfehs.frame_horizontal_split(2)
  sdorfehs.frame_focus(1, true)
end

return sdorfehs
