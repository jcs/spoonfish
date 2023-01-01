-- callback for watch_app() when a window has been created
sdorfehs.ignore_events = false
sdorfehs.app_event = function(element, event)
  if sdorfehs.ignore_events then
    return
  end

  if element == nil then
    sdorfehs.log.e("app_event got nil element for " .. hs.inspect(event))
    return
  end

  if event == sdorfehs.events.windowCreated then
    if element:isStandard() then
      sdorfehs.watch_hswindow(element)
    end
  elseif event == sdorfehs.events.focusedWindowChanged then
    local win = sdorfehs.window_find_by_id(element:id())
    if win ~= nil then
      -- TODO: don't do this when it's in response to a window destroying
      sdorfehs.frame_focus(win["space"], win["frame"], false)
    end
  elseif event == sdorfehs.events.windowResized then
    local win = sdorfehs.window_find_by_id(element:id())
    if win ~= nil then
      sdorfehs.window_reframe(win)
    end
  end
end

-- callback for .app_watcher, informing about a new or closed app
sdorfehs.app_meta_event = function(name, event, hsapp)
  if event == hs.application.watcher.launched then
    sdorfehs.watch_app(hsapp)
  elseif event == hs.application.watcher.terminated then
    sdorfehs.log.i("app " .. hsapp:pid() .. " terminated")

    local app = sdorfehs.apps[hsapp:pid()]
    if app == nil then
      return
    end

    app["watcher"]:stop()

    -- checking w["win"]:application() will probably fail by this point
    for _, w in ipairs(sdorfehs.windows) do
      if w["app_pid"] == hsapp:pid() then
        sdorfehs.log.i("cleaning up window " .. w["win"]:title())
        sdorfehs.window_remove(w)
      end
    end

    sdorfehs.apps[hsapp:pid()] = nil
  end
end

-- watch an application to be notififed when it creates a new window
sdorfehs.watch_app = function(hsapp)
  if sdorfehs.apps[hsapp:pid()] then
    return
  end

  local matched = false
  for _, p in pairs(sdorfehs.apps_to_watch) do
    if not p:find("^%^") then
      p = sdorfehs.escape_pattern(p)
    end
    if hsapp:title():find(p) then
      matched = true
      break
    end
    if matched then
      break
    end
  end
  if not matched then
    -- sdorfehs.log.i("not watching app[" .. hsapp:pid() .. "] " .. hsapp:title())
    return
  end

  sdorfehs.log.i("watching app[" .. hsapp:pid() .. "] " .. hsapp:title() ..
    " (" ..  hsapp:name() .. ")")

  local watcher = hsapp:newWatcher(sdorfehs.app_event)
  sdorfehs.apps[hsapp:pid()] = {
    watcher = watcher,
  }
  watcher:start({
    sdorfehs.events.windowCreated,
    sdorfehs.events.windowMoved,
    sdorfehs.events.windowResized,
    sdorfehs.events.focusedWindowChanged,
  })

  -- watch windows that already exist
  local wf = hs.window.filter.new(hsapp:name())
  for _, w in pairs(wf:getWindows()) do
    sdorfehs.watch_hswindow(w)
  end
end

-- watch a hs.window object to be notified when it is closed or moved
sdorfehs.watch_hswindow = function(hswin)
  if not hswin:isStandard() then
    return
  end

  for _, p in pairs(sdorfehs.windows_to_ignore) do
    if not p:find("^%^") then
      p = sdorfehs.escape_pattern(p)
    end
    if hswin:title():find(p) then
      sdorfehs.log.i(" ignoring window " .. hswin:title() .. ", matches " .. p)
      return
    end
  end

  -- this is unfortunate but there's no space info in the window object
  local w_space = hs.spaces.activeSpaceOnScreen()
  for _, space_id in
   pairs(hs.spaces.spacesForScreen(hs.screen.mainScreen():getUUID())) do
    local wins = hs.spaces.windowsForSpace(space_id)

    for _, w in pairs(wins) do
      if w == hswin:id() then
        w_space = space_id
        break
      end
    end
  end

  sdorfehs.log.i(" space[" .. w_space .. "]: watching window " .. hswin:id() ..
    ": " .. hswin:title())
  local watcher = hswin:newWatcher(sdorfehs.window_event, { id = hswin:id() })
  watcher:start({
    sdorfehs.events.elementDestroyed,
    sdorfehs.events.windowResized,
    sdorfehs.events.windowMoved,
  })

  sdorfehs.frame_capture(w_space, sdorfehs.spaces[w_space].frame_current, hswin)
end

-- callback for watch_hswindow() when a window has been closed or moved
sdorfehs.window_event = function(hswin, event, watcher, info)
  if not sdorfehs.initialized then
    return
  end

  if event == sdorfehs.events.elementDestroyed then
    local win = sdorfehs.window_find_by_id(info["id"])
    watcher:stop()
    if win ~= nil then
      sdorfehs.window_remove(win)

      -- stay on this frame
      sdorfehs.frame_focus(win["space"], win["frame"], false)
    end
  end
end

-- callback from hs.spaces.watcher
sdorfehs.spaces_event = function(new_space)
  if new_space == -1 then
    new_space = hs.spaces.activeSpaceOnScreen()
  end

  sdorfehs.log.d("switched to space " .. new_space)

  if sdorfehs.spaces[new_space] then
    sdorfehs.frame_focus(new_space, sdorfehs.spaces[new_space].frame_current,
      true)
  end
end
