-- find a window object in s.windows from a hs.window object
sdorfehs.window_find_by_hswindow = function(win)
  for _, w in sdorfehs.windows do
    if w["win"] == win then
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

sdorfehs.window_hide = function(win)
  -- TODO: just move offscreen or something?
  win["win"]:minimize()
end

sdorfehs.window_show = function(win)
  win["win"]:unminimize()
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
