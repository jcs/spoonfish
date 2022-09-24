-- find a window table object from an hs.window object
sdorfehs.window_find_by_hswindow = function(win)
  for _, w in pairs(sdorfehs.windows) do
    if w["win"] == win then
      return w
    end
  end

  return nil
end

-- find a window table object from its hs.window id
sdorfehs.window_find_by_id = function(id)
  for _, w in pairs(sdorfehs.windows) do
    if w["win"]:id() == id then
      return w
    end
  end

  return nil
end

-- move a window to fit its frame, or hide it if in frame 0
sdorfehs.window_reframe = function(win)
  if win == nil or win == {} then
    error("bogus window passed")
    return
  end

  if win["frame"] == 0 then
    error("bogus frame for win " .. win["title"])
    return
  end

  local iframe = sdorfehs.frame_with_gap(win["frame"])
  win["win"]:move(iframe, nil, true, 0)
end

-- remove a window from the stack and bring up a new window in the frame
sdorfehs.window_remove = function(win)
  local frame_id = win["frame"]
  sdorfehs.window_restack(win, sdorfehs.position.REMOVE)
  if frame_id ~= 0 then
    sdorfehs.frame_cycle(frame_id, false)
  end
end

-- move a window to the front or back of the window stack (or remove it)
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

-- restore a window but don't bother moving to its frame, window_reframe will
sdorfehs.window_show = function(win)
  if win["win"]:isMinimized() then
    win["win"]:unminimize()
  end
end

-- return a table of windows not first in any frame
sdorfehs.windows_not_visible = function()
  local wins = {}
  local topwins = {}
  for _, w in ipairs(sdorfehs.windows) do
    if topwins[w["frame"]] == nil then
      topwins[w["frame"]] = w
    else
      table.insert(wins, w)
    end
  end
  return wins
end
