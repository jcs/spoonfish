-- callback for watch_app() when a window has been created
spoonfish.ignore_events = false
spoonfish.app_event = function(element, event)
  if spoonfish.ignore_events then
    return
  end

  if element == nil then
    spoonfish.log.e("app_event got nil element for " .. hs.inspect(event))
    return
  end

  if event == spoonfish.events.windowCreated then
    if element:isStandard() then
      spoonfish.watch_hswindow(element)
    end
  elseif event == spoonfish.events.focusedWindowChanged then
    local win = spoonfish.window_find_by_id(element:id())
    if win ~= nil then
      -- TODO: don't do this when it's in response to a window destroying
      spoonfish.frame_focus(win["space"], win["frame"], false)
    end
  elseif event == spoonfish.events.windowResized then
    local win = spoonfish.window_find_by_id(element:id())
    if win ~= nil then
      spoonfish.window_reframe(win)
    end
  end
end

-- callback for .app_watcher, informing about a new or closed app
spoonfish.app_meta_event = function(name, event, hsapp)
  if event == hs.application.watcher.launched then
    spoonfish.watch_app(hsapp)
  elseif event == hs.application.watcher.terminated then
    spoonfish.log.i("app " .. hsapp:pid() .. " terminated")

    local app = spoonfish.apps[hsapp:pid()]
    if app == nil then
      return
    end

    app["watcher"]:stop()

    -- checking w["win"]:application() will probably fail by this point
    for _, w in ipairs(spoonfish.windows) do
      if w["app_pid"] == hsapp:pid() then
        spoonfish.log.i("cleaning up window " .. w["win"]:title())
        spoonfish.window_remove(w)
      end
    end

    spoonfish.apps[hsapp:pid()] = nil
  end
end

-- watch an application to be notififed when it creates a new window
spoonfish.watch_app = function(hsapp)
  if spoonfish.apps[hsapp:pid()] then
    return
  end

  local matched = false
  for _, p in pairs(spoonfish.apps_to_watch) do
    if not p:find("^%^") then
      p = spoonfish.escape_pattern(p)
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
    -- spoonfish.log.i("not watching app[" .. hsapp:pid() .. "] " .. hsapp:title())
    return
  end

  spoonfish.log.i("watching app[" .. hsapp:pid() .. "] " .. hsapp:title() ..
    " (" ..  hsapp:name() .. ")")

  local watcher = hsapp:newWatcher(spoonfish.app_event)
  spoonfish.apps[hsapp:pid()] = {
    watcher = watcher,
  }
  watcher:start({
    spoonfish.events.windowCreated,
    spoonfish.events.windowMoved,
    spoonfish.events.windowResized,
    spoonfish.events.focusedWindowChanged,
  })

  -- watch windows that already exist
  local wf = hs.window.filter.new(hsapp:name())
  for _, w in pairs(wf:getWindows()) do
    spoonfish.watch_hswindow(w)
  end
end

-- watch a hs.window object to be notified when it is closed or moved
spoonfish.watch_hswindow = function(hswin)
  if not hswin:isStandard() then
    return
  end

  for _, p in pairs(spoonfish.windows_to_ignore) do
    if not p:find("^%^") then
      p = spoonfish.escape_pattern(p)
    end
    if hswin:title():find(p) then
      spoonfish.log.i(" ignoring window " .. hswin:title() .. ", matches " .. p)
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

  spoonfish.log.i(" space[" .. w_space .. "]: watching window " .. hswin:id() ..
    ": " .. hswin:title())
  local watcher = hswin:newWatcher(spoonfish.window_event, { id = hswin:id() })
  watcher:start({
    spoonfish.events.elementDestroyed,
    spoonfish.events.windowResized,
    spoonfish.events.windowMoved,
  })

  spoonfish.frame_capture(w_space, spoonfish.spaces[w_space].frame_current, hswin)
end

-- callback for watch_hswindow() when a window has been closed or moved
spoonfish.window_event = function(hswin, event, watcher, info)
  if not spoonfish.initialized then
    return
  end

  if event == spoonfish.events.elementDestroyed then
    local win = spoonfish.window_find_by_id(info["id"])
    watcher:stop()
    if win ~= nil then
      spoonfish.window_remove(win)

      -- stay on this frame
      spoonfish.frame_focus(win["space"], win["frame"], false)
    end
  end
end

-- callback from hs.spaces.watcher
spoonfish.spaces_event = function(new_space)
  if new_space == -1 then
    new_space = hs.spaces.activeSpaceOnScreen()
  end

  spoonfish.log.d("switched to space " .. new_space)

  if spoonfish.spaces[new_space] then
    spoonfish.frame_focus(new_space, spoonfish.spaces[new_space].frame_current,
      true)
  end
end
