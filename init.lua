spoonfish = {}

require("spoonfish/frames")
require("spoonfish/windows")
require("spoonfish/events")
require("spoonfish/utils")


-- default configuration, can be overridden in loading init.lua before calling
-- spoonfish.start()

-- prefix key (with control)
spoonfish.prefix_key = "a"

-- set sizes to 0 to disable
spoonfish.border_color = "#000000"
spoonfish.border_size = 4
spoonfish.shadow_color = "#000000"
spoonfish.shadow_size = 8

-- space to put between windows in adjoining frames
spoonfish.gap = 22

-- program to send 'new window' to for 'c' command
spoonfish.terminal = "iTerm2"

-- for per-frame messages
spoonfish.frame_message_secs = 1
spoonfish.frame_message_font_size = 18

-- increment to resize interactively
spoonfish.resize_unit = 10

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

  -- debugging flags
  s.debug_frames = false

  s.log = hs.logger.new("spoonfish", "debug")

  -- spaces and frame rects, keyed by frame number
  s.spaces = {}
  for _, space_id in
   pairs(hs.spaces.spacesForScreen(hs.screen.mainScreen():getUUID())) do
    s.spaces[space_id] = { rect = hs.screen.mainScreen():frame() }
    s.spaces[space_id].frames = {}
    s.spaces[space_id].frames[1] = {
      rect = hs.screen.mainScreen():frame(),
    }
    s.spaces[space_id].frame_previous = 1
    s.spaces[space_id].frame_current = 1

    if space_id == hs.spaces.activeSpaceOnScreen() then
      spoonfish.draw_frames(space_id)
    end
  end

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

  s.initialized = true
  s.in_modal = false
  s.send_modal = false
  s.resizing = false

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

    if s.resizing then
      if key == "down" or key == "left" or key == "right" or key == "up" then
        if nomod then
          s.frame_resize(cs, space.frame_current, s.dir_from_string(key))
        end
      else
        -- any other key will exit
        s.resizing = false
        s.frame_message(cs, space.frame_current, nil)
        return true
      end

      -- redisplay the frame message as it probably just changed size
      s.frame_message(cs, space.frame_current, "Resize frame", true)

      return true
    end

    if not s.in_modal then
      if ctrl and key == spoonfish.prefix_key then
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

    -- we're in modal, so anything after this point will reset it
    s.in_modal = false

    -- in-modal key bindings
    if flags:containExactly({ "shift" }) then
      key = string.upper(key)
    end

    s.ignore_events = true

    -- TODO: put these in a table for dynamic reassignment

    if key == "tab" then
      if nomod or ctrl then
        s.frame_focus(cs, space.frame_previous, true)
      end
    elseif key == "down" or key == "left" or key == "right" or key == "up" then
      local touching = s.frame_find_touching(cs, space.frame_current,
        s.dir_from_string(key))
      if touching[1] then
        if nomod then
          s.frame_focus(cs, touching[1], true)
        elseif ctrl then
          s.frame_swap(cs, space.frame_current, touching[1])
        end
      end
    elseif key == "space" then
      if nomod or ctrl then
        s.frame_cycle(cs, space.frame_current, true)
      end
    elseif key == spoonfish.prefix_key then
      if nomod then
        s.send_modal = true
        hs.eventtap.keyStroke({ "ctrl" }, spoonfish.prefix_key)
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
    elseif key == "r" then
      if nomod then
        s.frame_resize_interactively(cs, space.frame_current)
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
end

return spoonfish
