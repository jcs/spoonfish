-- find a window object in s.windows from a hs.window object
sdorfehs.window_find_by_hswindow = function(win)
  for _, w in pairs(sdorfehs.windows) do
    if w["win"] == win then
      return w
    end
  end

  return nil
end

sdorfehs.window_find_by_id = function(id)
  for _, w in pairs(sdorfehs.windows) do
    if w["win"]:id() == id then
      return w
    end
  end

  return nil
end

sdorfehs.window_reframe = function(win)
  if win == nil or win == {} then
    error("bogus window passed")
    return
  end

  if win["frame"] == 0 then
    sdorfehs.window_hide(win)
  else
    local frame = sdorfehs.frames[win["frame"]]
    if frame == nil then
      error("no frame for window " .. win["win"]:title() .. ": " ..
        hs.inspect(win))
      return
    end

    win["win"]:move(sdorfehs.inset(frame, sdorfehs.gap), nil, true, 0)
  end
end

sdorfehs.window_restack = function(win, pos)
  if pos == nil then
    error("invalid position argument")
    return
  end

  local new_stack = {}
  for _, w in ipairs(sdorfehs.windows) do
    if w == win then
      if pos == sdorfehs.position.FRONT then
        table.insert(new_stack, 1, w)
      end
    else
      table.insert(new_stack, w)
    end
  end
  if pos == sdorfehs.position.BACK then
    table.insert(new_stack, win)
  end
  sdorfehs.windows = new_stack
end

sdorfehs.window_remove = function(win)
  local frame_id = win["frame"]
  sdorfehs.window_restack(win, sdorfehs.position.REMOVE)
  if frame_id ~= 0 then
    sdorfehs.frame_cycle(frame_id)
  end
end

sdorfehs.window_hide = function(win)
  local win_frame = win["win"]:frame()
  win["restore_pos"] = win_frame
  local screen_frame = win["win"]:screen():fullFrame()
  local off_rect = hs.geometry.rect(screen_frame.w + 10, screen_frame.h + 10,
    win_frame.w, win_frame.h)
  win["win"]:move(off_rect, nil, false, 0)
end

sdorfehs.window_show = function(win)
  win["win"]:unminimize()
  -- don't move, since window_reframe will probably do so
end

sdorfehs.windows_on_frame = function(frame_id)
  local wins = {}
  for _, w in ipairs(sdorfehs.windows) do
    if w["frame"] == frame_id then
      table.insert(wins, w)
    end
  end
  return wins
end
