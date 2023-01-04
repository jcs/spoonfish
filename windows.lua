-- find a window table object from an hs.window object
spoonfish.window_find_by_hswindow = function(win)
  for _, w in pairs(spoonfish.windows) do
    if w["win"] == win then
      return w
    end
  end

  return nil
end

-- find a window table object from its hs.window id
spoonfish.window_find_by_id = function(id)
  for _, w in pairs(spoonfish.windows) do
    if w["win"]:id() == id then
      return w
    end
  end

  return nil
end

-- move a window to fit its frame, or hide it if in frame 0
spoonfish.window_reframe = function(win)
  if win == nil or win == {} then
    error("bogus window passed")
    return
  end

  if win["frame"] == 0 then
    error("bogus frame for win " .. win["title"])
    return
  end

  local iframe = spoonfish.frame_rect_with_gap(win["space"], win["frame"])
  win["win"]:move(iframe, nil, true, 0)

  if win["space"] == hs.spaces.activeSpaceOnScreen() then
    spoonfish.window_reborder(win)
  end
end

-- redraw a border and shadow on a window
spoonfish.window_reborder = function(win)
  if win == nil or win == {} then
    error("bogus window passed")
    return
  end

  if spoonfish.border_size == 0 then
    return
  end

  for _, w in pairs({ "shadow", "border" }) do
    local irect = spoonfish.frame_rect_with_gap(win["space"], win["frame"])
    irect = spoonfish.inset(irect, -(spoonfish.border_size))

    if w == "shadow" then
      irect.x = irect.x + spoonfish.shadow_size
      irect.y = irect.y + spoonfish.shadow_size
    end

    if win[w] == nil then
      win[w] = hs.drawing.rectangle(irect)
    else
      win[w]:setFrame(irect)
    end
    win[w]:setLevel(hs.drawing.windowLevels.desktopIcon)

    local color
    if w == "border" then
      color = spoonfish.border_color
    elseif w == "shadow" then
      color = spoonfish.shadow_color
    end
    win[w]:setStrokeColor({ ["hex"] = color })
    win[w]:setFill(true)
    win[w]:setFillColor({ ["hex"] = color })
    win[w]:setRoundedRectRadii(14, 14)
    win[w]:show()
  end
end

-- remove a window from the stack and bring up a new window in the frame
spoonfish.window_remove = function(win)
  local frame_id = win["frame"]
  if win["border"] ~= nil then
    win["border"]:delete()
    win["border"] = nil
  end
  if win["shadow"] ~= nil then
    win["shadow"]:delete()
    win["shadow"] = nil
  end
  spoonfish.window_restack(win, spoonfish.position.REMOVE)
  if frame_id ~= 0 then
    spoonfish.frame_cycle(win["space"], frame_id, false)
  end
end

-- move a window to the front or back of the window stack (or remove it)
spoonfish.window_restack = function(win, pos)
  if pos == nil then
    error("invalid position argument")
    return
  end

  local new_stack = {}
  for _, w in ipairs(spoonfish.windows) do
    if w == win then
      if pos == spoonfish.position.FRONT then
        table.insert(new_stack, 1, w)
      end
    else
      table.insert(new_stack, w)
    end
  end
  if pos == spoonfish.position.BACK then
    table.insert(new_stack, win)
  end
  spoonfish.windows = new_stack
end

-- restore a window but don't bother moving to its frame, window_reframe will
spoonfish.window_show = function(win)
  if win["win"]:isMinimized() then
    win["win"]:unminimize()
  end
end

-- return a table of windows not first in any frame
spoonfish.windows_not_visible = function(space_id)
  local wins = {}
  local topwins = {}
  for _, w in ipairs(spoonfish.windows) do
    if w["space"] == space_id then
      if topwins[w["frame"]] == nil then
        topwins[w["frame"]] = w
      else
        table.insert(wins, w)
      end
    end
  end
  return wins
end
