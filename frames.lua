sdorfehs.frame_s = function(frame)
  return "{x:" .. frame.x .. " y:" .. frame.y .. " w:" .. frame.w .. " h:" ..
    frame.h .. "}"
end

sdorfehs.frame_focus = function(frame_id)
  sdorfehs.frame_previous = sdorfehs.frame_current
  sdorfehs.frame_current = frame_id

  local wof = sdorfehs.windows_on_frame(frame_id)
  if wof[1] ~= nil then
    sdorfehs.window_reframe(wof[1])
    wof[1]["win"]:focus()
  end

  sdorfehs.outline(sdorfehs.frames[frame_id])
end

sdorfehs.frame_cycle = function(frame_id)
  sdorfehs.log.d("cycling frame " .. frame_id)
  local wof = sdorfehs.windows_on_frame(frame_id)
  if wof[1] ~= nil then
    -- move this top window to the bottom of the stack
    sdorfehs.window_hide(wof[1])
    wof[1]["frame"] = 0
    sdorfehs.window_restack(wof[1], sdorfehs.position.BACK)
  end

  -- find the first window that is not in a frame and bring it forth
  local wnof = sdorfehs.windows_on_frame(0)
  if wnof[1] ~= nil then
    wnof[1]["frame"] = frame_id
    sdorfehs.frame_raise_window(frame_id, wnof[1])
  end
end

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

sdorfehs.frame_vertical_split = function(frame_id)
  return sdorfehs.frame_split(frame_id, true)
end

sdorfehs.frame_horizontal_split = function(frame_id)
  return sdorfehs.frame_split(frame_id, false)
end

sdorfehs.frame_capture = function(frame_id, hswin)
  local win = {
    ["win"] = hswin,
    ["frame"] = frame_id,
  }
  table.insert(sdorfehs.windows, win)
  sdorfehs.window_reframe(win)
  return win
end

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
    error("frame_find: bogus direction " .. dir)
  end

  -- nothing applicable, keep the current frame
  return frame_id
end

sdorfehs.frame_raise_window = function(frame_id, win)
  sdorfehs.window_reframe(win)
  sdorfehs.window_show(win)
  win["win"]:focus()
  sdorfehs.window_restack(win, sdorfehs.position.FRONT)
end

sdorfehs.frame_next_window = function(frame_id)
  local found_first = nil

  for _, w in ipairs(sdorfehs.windows) do
    if w["frame"] == frame_id then
      if found_first then
        return w
      end

      found_first = w
    end
  end

  -- this is the only window, or there are none
  return found_first
end
