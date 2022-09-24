-- callback for watch_app() when a window has been created
sdorfehs.ignore_events = false
sdorfehs.app_event = function(element, event)
  if sdorfehs.ignore_events then
    return
  end

  if event == sdorfehs.events.windowCreated then
    if element:isStandard() then
      sdorfehs.log.i("new window created: " .. element:title())
      sdorfehs.watch_hswindow(element)
    end
  elseif event == sdorfehs.events.focusedWindowChanged then
    local win = sdorfehs.window_find_by_id(element:id())
    if win ~= nil then
      -- TODO: don't do this when it's in response to a window destroying
      sdorfehs.frame_focus(win["frame"], false)
    end
  elseif event == sdorfehs.events.windowResized then
    local win = sdorfehs.window_find_by_id(element:id())
    if win ~= nil then
      sdorfehs.window_reframe(win)
    end
  end
end

-- callback for .app_watcher, informing about a new or closed app
sdorfehs.app_meta_event = function(name, event, app)
  if event == hs.application.watcher.launched then
    sdorfehs.watch_app(app)
  elseif event == hs.application.watcher.terminated then
    local appWatcher = sdorfehs.apps[app:pid()]
    if appWatcher then
      appWatcher.watcher:stop()
      for id, watcher in pairs(appWatcher.windows) do
        -- TODO
        -- watcher:stop()
      end
      sdorfehs.apps[app:pid()] = nil
    end
  end
end

-- watch an application to be notififed when it creates a new window
sdorfehs.watch_app = function(app)
  if sdorfehs.apps[app:pid()] then
    return
  end

  if not string.find(app:title(), sdorfehs.apps_to_watch) then
    return
  end

  sdorfehs.log.i("watching app " .. app:pid() .. ": " .. app:name())

  local watcher = app:newWatcher(sdorfehs.app_event)
  sdorfehs.apps[app:pid()] = {
    watcher = watcher,
    windows = {},
  }
  watcher:start({
    sdorfehs.events.windowCreated,
    sdorfehs.events.windowMoved,
    sdorfehs.events.windowResized,
    sdorfehs.events.focusedWindowChanged,
  })

  -- watch windows that already exist
  for _, w in pairs(app:allWindows()) do
    sdorfehs.watch_hswindow(w)
  end
end

-- watch a hs.window object to be notified when it is closed or moved
sdorfehs.watch_hswindow = function(hswin)
  if not hswin:isStandard() then
    return
  end

  sdorfehs.log.i(" watching window: " .. hswin:title())
  local watcher = hswin:newWatcher(sdorfehs.window_event, { id = hswin:id() })
  watcher:start({
    sdorfehs.events.elementDestroyed,
    sdorfehs.events.windowResized,
    sdorfehs.events.windowMoved,
  })

  sdorfehs.frame_capture(sdorfehs.frame_current, hswin)
end

-- callback for watch_hswindow() when a window has been closed or moved
sdorfehs.window_event = function(hswin, event, watcher, info)
  if not sdorfehs.initialized then
    return
  end

  if event == sdorfehs.events.elementDestroyed then
    local win = sdorfehs.window_find_by_id(info["id"])
    sdorfehs.log.i("window destroyed: " .. hs.inspect(win))
    watcher:stop()
    if win ~= nil then
      sdorfehs.window_remove(win)

      -- stay on this frame
      sdorfehs.frame_focus(win["frame"], false)
    end
  end
end
