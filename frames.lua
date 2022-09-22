sdorfehs.frame_s = function(frame)
  return "{x:" .. frame.x .. " y:" .. frame.y .. " w:" .. frame.w .. " h:" ..
    frame.h .. "}"
end

-- take control of a new hs.window and resize it to a particular frame
-- return a window table object
sdorfehs.frame_capture = function(frame_id, hswin)
  local win = {
    ["win"] = hswin,
    ["frame"] = frame_id,
  }
  table.insert(sdorfehs.windows, win)
  sdorfehs.window_reframe(win)
  sdorfehs.window_restack(win, 1)
  return win
end

-- move the top window of a frame to the bottom of the stack, raise the next
-- available or last window to the top
sdorfehs._frame_cycle = function(frame_id, reverse)
  local wnf = sdorfehs.windows_not_visible()

  if table.count(wnf) == 0 then
    sdorfehs.log.d("no hidden windows to cycle")
    return
  end

  local fwin = sdorfehs.frame_top_window(frame_id)
  if fwin then
    -- move this top window to the bottom of the stack
    sdorfehs.window_restack(fwin, sdorfehs.position.BACK)
  end

  -- find the first window that is not in a frame and bring it forth
  local cwin = wnf[1]
  if reverse then
    cwin = wnf[table.count(wnf)]
  end
  if cwin ~= nil then
    cwin["frame"] = frame_id
    sdorfehs.frame_raise_window(frame_id, cwin)
  end
end
sdorfehs.frame_cycle = function(frame_id)
  sdorfehs._frame_cycle(frame_id, false)
end
sdorfehs.frame_reverse_cycle = function(frame_id)
  sdorfehs._frame_cycle(frame_id, true)
end

-- find a frame relative to frame_id in the direction dir
sdorfehs.frame_find = function(frame_id, dir)
  local cur = sdorfehs.frames[frame_id]

  if dir == sdorfehs.direction.LEFT then
    -- x+w touching the x of the current frame, with same y
    for i, f in pairs(sdorfehs.frames) do
      if f.x + f.w == cur.x and f.y == cur.y then
        return i
      end
    end
    -- or just x+w touching the x of the current frame
    for i, f in pairs(sdorfehs.frames) do
      if f.x + f.w == cur.x then
        return i
      end
    end
  elseif dir == sdorfehs.direction.RIGHT then
    -- x touching the x+w of the current frame, with same y
    for i, f in pairs(sdorfehs.frames) do
      if f.x == cur.x + cur.w and f.y == cur.y then
        return i
      end
    end
    -- or just x touching the x+w of the current frame
    for i, f in pairs(sdorfehs.frames) do
      if f.x == cur.x + cur.w then
        return i
      end
    end
  elseif dir == sdorfehs.direction.DOWN then
    -- y touching the y+h of the current frame, with same x
    for i, f in pairs(sdorfehs.frames) do
      if f.y == cur.y + cur.h and f.x == cur.x then
        return i
      end
    end
    -- or just y touching the y+h of the current frame
    for i, f in pairs(sdorfehs.frames) do
      if f.y == cur.y + cur.h then
        return i
      end
    end
  elseif dir == sdorfehs.direction.UP then
    -- y+h touching the y of the current frame, with same x
    for i, f in pairs(sdorfehs.frames) do
      if f.y + f.h == cur.y and f.x == cur.x then
        return i
      end
    end
    -- or just y+h touching the y of the current frame
    for i, f in pairs(sdorfehs.frames) do
      if f.y + f.h == cur.y then
        return i
      end
    end
  else
    error("frame_find: bogus direction")
  end

  -- nothing applicable, keep the current frame
  return frame_id
end

-- give focus to frame and raise its active window
sdorfehs.frame_focus = function(frame_id)
  if sdorfehs.frames[frame_id] == nil then
    error("bogus frame " .. frame_id)
    return
  end

  sdorfehs.frame_previous = sdorfehs.frame_current
  sdorfehs.frame_current = frame_id

  local wof = sdorfehs.frame_top_window(frame_id)
  if wof ~= nil then
    sdorfehs.window_reframe(wof)
    wof["win"]:focus()
  end

  sdorfehs.outline(sdorfehs.frames[frame_id])
end

-- split a frame horizontally
sdorfehs.frame_horizontal_split = function(frame_id)
  return sdorfehs.frame_split(frame_id, false)
end

-- raise a window in a given frame, assigning it to that frame
sdorfehs.frame_raise_window = function(frame_id, win)
  sdorfehs.window_reframe(win)
  sdorfehs.window_show(win)
  win["win"]:focus()
  sdorfehs.window_restack(win, sdorfehs.position.FRONT)
end

-- split a frame vertically or horizontally
sdorfehs.frame_split = function(frame_id, vertical)
  local old_frame = sdorfehs.frames[frame_id]

  -- halve current frame
  if vertical then
    sdorfehs.frames[frame_id] = hs.geometry.rect(
      old_frame.x,
      old_frame.y,
      math.floor(old_frame.w / 2),
      old_frame.h
    )
  else
    sdorfehs.frames[frame_id] = hs.geometry.rect(
      old_frame.x,
      old_frame.y,
      old_frame.w,
      math.floor(old_frame.h / 2)
    )
  end

  -- reframe all windows in that old frame
  for _, w in ipairs(sdorfehs.windows) do
    if w["frame"] == frame_id then
      sdorfehs.window_reframe(w)
    end
  end

  local new_frame = table.count(sdorfehs.frames) + 1

  if vertical then
    sdorfehs.frames[new_frame] = hs.geometry.rect(
      sdorfehs.frames[frame_id].x + sdorfehs.frames[frame_id].w,
      sdorfehs.frames[frame_id].y,
      old_frame.w - sdorfehs.frames[frame_id].w,
      sdorfehs.frames[frame_id].h
    )
  else
    sdorfehs.frames[new_frame] = hs.geometry.rect(
      sdorfehs.frames[frame_id].x,
      sdorfehs.frames[frame_id].y + sdorfehs.frames[frame_id].h,
      sdorfehs.frames[frame_id].w,
      old_frame.h - sdorfehs.frames[frame_id].h
    )
  end

  sdorfehs.frame_focus(frame_id)

  -- we'll probably want to go to this frame on tab
  sdorfehs.frame_previous = new_frame
end

-- swap the front-most windows of two frames
sdorfehs.frame_swap = function(frame_id_from, frame_id_to)
  print("TODO")
  -- TODO
end

-- remove current frame
sdorfehs.frame_remove = function()
  if table.count(sdorfehs.frames) == 1 then
    return
  end

  local id_removing = sdorfehs.frame_current

  -- reframe all windows in the current frame and renumber higher frames
  for _, w in ipairs(sdorfehs.windows) do
    if w["frame"] == id_removing then
      w["frame"] = 0
      sdorfehs.window_reframe(w)
    elseif w["frame"] > id_removing then
      w["frame"] = w["frame"] - 1
    end
  end

  -- shift other frame numbers down
  table.remove(sdorfehs.frames, id_removing)

  if sdorfehs.frame_previous > id_removing then
    sdorfehs.frame_previous = sdorfehs.frame_previous - 1
  end

  sdorfehs.frame_focus(sdorfehs.frame_previous)
end

-- split a frame vertically
sdorfehs.frame_vertical_split = function(frame_id)
  return sdorfehs.frame_split(frame_id, true)
end

-- return the first window in this frame
sdorfehs.frame_top_window = function(frame_id)
  for _, w in ipairs(sdorfehs.windows) do
    if w["frame"] == frame_id then
      return w
    end
  end
end
