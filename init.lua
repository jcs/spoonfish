spoonfish = {}

require("spoonfish/frames")
require("spoonfish/windows")
require("spoonfish/events")
require("spoonfish/utils")


-- default configuration, can be overridden in loading init.lua before calling
-- spoonfish.start()
spoonfish.gap = 22
spoonfish.terminal = "iTerm2"
spoonfish.frame_message_secs = 1
spoonfish.frame_message_font_size = 18
spoonfish.border_color = "#000000"
spoonfish.border_size = 4
spoonfish.shadow_color = "#000000"
spoonfish.shadow_size = 8

-- for these lists, anything not starting with ^ will be run through
-- escape_pattern to escape dashes and other special characters, so be sure
-- to escape such characters manually in ^-prefixed patterns
spoonfish.apps_to_watch = {
  "^" .. spoonfish.terminal,
  "^Firefox",
}
spoonfish.windows_to_ignore = {
  "Picture-in-Picture",
  "^Open ",
  "^Save ",
  "^Export",
}


-- let's go
spoonfish.start = function()
  local s = spoonfish

  -- spaces and frame rects, keyed by frame number
  s.spaces = {}
  for _, space_id in
   pairs(hs.spaces.spacesForScreen(hs.screen.mainScreen():getUUID())) do
    s.spaces[space_id] = {}
    s.spaces[space_id].frames = {}
    s.spaces[space_id].frames[1] = hs.screen.mainScreen():frame()
    s.spaces[space_id].frame_previous = 1
    s.spaces[space_id].frame_current = 1
  end

  s.direction = {
    LEFT = 1,
    RIGHT = 2,
    DOWN = 3,
    UP = 4,
  }

  s.position = {
    FRONT = 1,
    BACK = 2,
    REMOVE = 3,
  }

  s.initialized = false
  s.events = hs.uielement.watcher

  -- windows, array by window stack order
  s.windows = {}

  -- apps, keyed by pid
  s.apps = {}

  s.log = hs.logger.new("spoonfish", "debug")

  -- watch for new apps launched
  s.app_watcher = hs.application.watcher.new(s.app_meta_event)
  s.app_watcher:start()

  -- watch existing apps
  local apps = hs.application.runningApplications()
  for i = 1, #apps do
    s.watch_app(apps[i])
  end

  -- watch when switching spaces
  s.spaces_watcher = hs.spaces.watcher.new(spoonfish.spaces_event)
  s.spaces_watcher:start()

  spoonfish.initialized = true

  s.in_modal = false
  s.send_modal = false

  s.eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown },
   function(event)
    local key = hs.keycodes.map[event:getKeyCode()]
    local flags = event:getFlags()
    local ctrl = flags:containExactly({ "ctrl" })
    local nomod = flags:containExactly({}) or flags:containExactly({ "shift" })

    local cs = hs.spaces.activeSpaceOnScreen()
    local space = s.spaces[cs]

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

    spoonfish.ignore_events = true

    if key == "tab" then
      if nomod or ctrl then
        s.frame_focus(cs, space.frame_previous, true)
      end
    elseif key == "left" then
      if nomod then
        s.frame_focus(cs,
          s.frame_find(cs, space.frame_current, s.direction.LEFT), true)
      elseif ctrl then
        s.frame_swap(cs, space.frame_current,
          s.frame_find(cs, space.frame_current, s.direction.LEFT))
      end
    elseif key == "right" then
      if nomod then
        s.frame_focus(cs,
          s.frame_find(cs, space.frame_current, s.direction.RIGHT),
          true)
      elseif ctrl then
        s.frame_swap(cs, space.frame_current,
          s.frame_find(cs, space.frame_current, s.direction.RIGHT))
      end
    elseif key == "up" then
      if nomod then
        s.frame_focus(cs,
          s.frame_find(cs, space.frame_current, s.direction.UP),
          true)
      elseif ctrl then
        s.frame_swap(cs, space.frame_current,
          s.frame_find(cs, space.frame_current, s.direction.UP))
      end
    elseif key == "down" then
      if nomod then
        s.frame_focus(cs,
          s.frame_find(cs, space.frame_current, s.direction.DOWN),
          true)
      elseif ctrl then
        s.frame_swap(cs, space.frame_current,
          s.frame_find(cs, space.frame_current, s.direction.DOWN))
      end
    elseif key == "space" then
      if nomod or ctrl then
        s.frame_cycle(cs, space.frame_current, true)
      end
    elseif key == "a" then
      if nomod then
        s.send_modal = true
        hs.eventtap.keyStroke({ "ctrl" }, "a")
      else
        s.frame_reverse_cycle(cs, space.frame_current, true)
      end
    elseif key == "c" then
      if nomod then
        -- create terminal window
        spoonfish.ignore_events = false
        local a = hs.appfinder.appFromName(spoonfish.terminal)
        if a == nil then
          hs.osascript.applescript("tell application \"" .. spoonfish.terminal
            .. "\" to activate")
        else
          a:setFrontmost(false)
          hs.eventtap.keyStroke({ "cmd" }, "n")
        end
      end
    elseif key == "p" then
      if nomod or ctrl then
        s.frame_reverse_cycle(cs, space.frame_current, true)
      end
    elseif key == "n" then
      if nomod or ctrl then
        s.frame_cycle(cs, space.frame_current, true)
      end
    elseif key == "R" then
      if nomod then
        s.frame_remove(cs, space.frame_current)
      end
    elseif key == "s" then
      if nomod then
        s.frame_horizontal_split(cs, space.frame_current)
      end
    elseif key == "S" then
      if nomod then
        s.frame_vertical_split(cs, space.frame_current)
      end
    end

    hs.timer.doAfter(0.25, function()
      spoonfish.ignore_events = false
    end)

    -- swallow event
    return true
  end):start()

  -- startup config
  local cs = hs.spaces.activeSpaceOnScreen()

  spoonfish.frame_vertical_split(cs, 1)
  spoonfish.frame_horizontal_split(cs, 2)
  spoonfish.frame_focus(cs, 1, true)
end

return spoonfish
