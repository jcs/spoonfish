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
    sdorfehs.events.focusedWindowChanged,
  })

  -- watch windows that already exist
  for _, w in pairs(app:allWindows()) do
    sdorfehs.watch_hswindow(w)
  end
end

sdorfehs.app_event = function(element, event)
  if event == sdorfehs.events.windowCreated then
    if element:isStandard() then
      sdorfehs.log.i("new window created: " .. element:title())
      sdorfehs.watch_hswindow(element)
    end
  elseif event == sdorfehs.events.focusedWindowChanged then
    sdorfehs.log.d("window focus changed: " .. element:title())
    -- TODO: handle window change
  end
end

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

  -- if there are no windows on this frame, become the front-runner
  local frame_id = 0
  if #sdorfehs.windows_on_frame(sdorfehs.frame_current) == 0 then
    frame_id = sdorfehs.frame_current
  end
  sdorfehs.frame_capture(frame_id, hswin)
end

sdorfehs.window_event = function(hswin, event, watcher, info)
  if not sdorfehs.is_initialized then
    return
  end

  if event == sdorfehs.events.elementDestroyed then
    local win = sdorfehs.window_find_by_id(info["id"])
    sdorfehs.log.i("window destroyed: " .. hs.inspect(win))
    watcher:stop()
    if win ~= nil then
      sdorfehs.window_remove(win)
    end
  else
    -- hs.alert.show("window event: " .. event)
  end
end
