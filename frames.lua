sdorfehs.frame_s = function(frame)
  return "{x:" .. frame.x .. " y:" .. frame.y .. " w:" .. frame.w .. " h:" ..
    frame.h .. "}"
end

-- take control of a new hs.window and resize it to a particular frame
-- return a window table object
sdorfehs.frame_capture = function(space_id, frame_id, hswin)
  local win = {
    ["win"] = hswin,
    ["frame"] = frame_id,
    ["space"] = space_id,
  }
  table.insert(sdorfehs.windows, win)
  sdorfehs.window_reframe(win)
  sdorfehs.window_restack(win, 1)
  return win
end

-- move the top window of a frame to the bottom of the stack, raise the next
-- available or last window to the top
sdorfehs._frame_cycle = function(space_id, frame_id, reverse, complain)
  local wnf = sdorfehs.windows_not_visible(space_id)

  if table.count(wnf) == 0 then
    if complain then
      sdorfehs.frame_message(space_id, sdorfehs.spaces[space_id].frame_current,
        "No more windows")
    end
    return
  end

  local fwin = sdorfehs.frame_top_window(space_id, frame_id)
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
    sdorfehs.frame_raise_window(space_id, frame_id, cwin)
  end
end
sdorfehs.frame_cycle = function(space_id, frame_id, complain)
  sdorfehs._frame_cycle(space_id, frame_id, false, complain)
end
sdorfehs.frame_reverse_cycle = function(space_id, frame_id, complain)
  sdorfehs._frame_cycle(space_id, frame_id, true, complain)
end

-- find a frame relative to frame_id in the direction dir
sdorfehs.frame_find = function(space_id, frame_id, dir)
  local cur = sdorfehs.spaces[space_id].frames[frame_id]

  if dir == sdorfehs.direction.LEFT then
    -- x+w touching the x of the current frame, with same y
    for i, f in pairs(sdorfehs.spaces[space_id].frames) do
      if f.x + f.w == cur.x and f.y == cur.y then
        return i
      end
    end
    -- or just x+w touching the x of the current frame
    for i, f in pairs(sdorfehs.spaces[space_id].frames) do
      if f.x + f.w == cur.x then
        return i
      end
    end
  elseif dir == sdorfehs.direction.RIGHT then
    -- x touching the x+w of the current frame, with same y
    for i, f in pairs(sdorfehs.spaces[space_id].frames) do
      if f.x == cur.x + cur.w and f.y == cur.y then
        return i
      end
    end
    -- or just x touching the x+w of the current frame
    for i, f in pairs(sdorfehs.spaces[space_id].frames) do
      if f.x == cur.x + cur.w then
        return i
      end
    end
  elseif dir == sdorfehs.direction.DOWN then
    -- y touching the y+h of the current frame, with same x
    for i, f in pairs(sdorfehs.spaces[space_id].frames) do
      if f.y == cur.y + cur.h and f.x == cur.x then
        return i
      end
    end
    -- or just y touching the y+h of the current frame
    for i, f in pairs(sdorfehs.spaces[space_id].frames) do
      if f.y == cur.y + cur.h then
        return i
      end
    end
  elseif dir == sdorfehs.direction.UP then
    -- y+h touching the y of the current frame, with same x
    for i, f in pairs(sdorfehs.spaces[space_id].frames) do
      if f.y + f.h == cur.y and f.x == cur.x then
        return i
      end
    end
    -- or just y+h touching the y of the current frame
    for i, f in pairs(sdorfehs.spaces[space_id].frames) do
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

sdorfehs.frame_with_gap = function(space_id, frame_id)
  local iframe = sdorfehs.inset(sdorfehs.spaces[space_id].frames[frame_id],
    sdorfehs.gap)

  if sdorfehs.frame_find(space_id, frame_id,
   sdorfehs.direction.LEFT) ~= frame_id then
    iframe.x = iframe.x - (sdorfehs.gap / 2)
    iframe.w = iframe.w + (sdorfehs.gap / 2)
  end

  if sdorfehs.frame_find(space_id, frame_id,
   sdorfehs.direction.UP) ~= frame_id then
    iframe.y = iframe.y - (sdorfehs.gap / 2)
    iframe.h = iframe.h + (sdorfehs.gap / 2)
  end

  if sdorfehs.frame_find(space_id, frame_id,
   sdorfehs.direction.RIGHT) ~= frame_id then
    iframe.w = iframe.w + (sdorfehs.gap / 2)
  end

  if sdorfehs.frame_find(space_id, frame_id,
   sdorfehs.direction.DOWN) ~= frame_id then
    iframe.h = iframe.h + (sdorfehs.gap / 2)
  end

  return iframe
end

-- give focus to frame and raise its active window
sdorfehs.frame_focus = function(space_id, frame_id, raise)
  if sdorfehs.spaces[space_id].frames[frame_id] == nil then
    error("bogus frame " .. frame_id .. " on space " .. space_id)
    return
  end

  local fc = sdorfehs.spaces[space_id].frame_current
  local wof = sdorfehs.frame_top_window(space_id, frame_id)
  if wof ~= nil then
    sdorfehs.window_reframe(wof)
    if raise then
      wof["win"]:focus()
    end
    sdorfehs.window_reborder(wof)
  end

  if frame_id ~= fc then
    sdorfehs.spaces[space_id].frame_current = frame_id
    sdorfehs.spaces[space_id].frame_previous = fc

    sdorfehs.frame_message(space_id, frame_id, "Frame " .. frame_id)
  end
end

-- split a frame horizontally
sdorfehs.frame_horizontal_split = function(space_id, frame_id)
  return sdorfehs.frame_split(space_id, frame_id, false)
end

-- raise a window in a given frame, assigning it to that frame
sdorfehs.frame_raise_window = function(space_id, frame_id, win)
  sdorfehs.window_reframe(win)
  sdorfehs.window_show(win)
  win["win"]:focus()
  sdorfehs.window_restack(win, sdorfehs.position.FRONT)
  sdorfehs.window_reborder(win)
end

-- split a frame vertically or horizontally
sdorfehs.frame_split = function(space_id, frame_id, vertical)
  local old_frame = sdorfehs.spaces[space_id].frames[frame_id]

  -- halve current frame
  if vertical then
    sdorfehs.spaces[space_id].frames[frame_id] = hs.geometry.rect(
      old_frame.x,
      old_frame.y,
      math.floor(old_frame.w / 2),
      old_frame.h
    )
  else
    sdorfehs.spaces[space_id].frames[frame_id] = hs.geometry.rect(
      old_frame.x,
      old_frame.y,
      old_frame.w,
      math.floor(old_frame.h / 2)
    )
  end

  -- reframe all windows in that old frame
  for _, w in ipairs(sdorfehs.windows) do
    if w["space"] == space_id and w["frame"] == frame_id then
      sdorfehs.window_reframe(w)
    end
  end

  local new_frame = table.count(sdorfehs.spaces[space_id].frames) + 1

  if vertical then
    sdorfehs.spaces[space_id].frames[new_frame] = hs.geometry.rect(
      sdorfehs.spaces[space_id].frames[frame_id].x +
      sdorfehs.spaces[space_id].frames[frame_id].w,
      sdorfehs.spaces[space_id].frames[frame_id].y,
      old_frame.w - sdorfehs.spaces[space_id].frames[frame_id].w,
      sdorfehs.spaces[space_id].frames[frame_id].h
    )
  else
    sdorfehs.spaces[space_id].frames[new_frame] = hs.geometry.rect(
      sdorfehs.spaces[space_id].frames[frame_id].x,
      sdorfehs.spaces[space_id].frames[frame_id].y +
      sdorfehs.spaces[space_id].frames[frame_id].h,
      sdorfehs.spaces[space_id].frames[frame_id].w,
      old_frame.h - sdorfehs.spaces[space_id].frames[frame_id].h
    )
  end

  sdorfehs.frame_focus(space_id, frame_id, true)

  -- we'll probably want to go to this frame on tab
  sdorfehs.spaces[space_id].frame_previous = new_frame
  sdorfehs.log.d(" after split, focused frame now " ..
    sdorfehs.spaces[space_id].frame_current .. ", previous " ..
    sdorfehs.spaces[space_id].frame_previous)
end

-- swap the front-most windows of two frames
sdorfehs.frame_swap = function(space_id, frame_id_from, frame_id_to)
  local fwin = sdorfehs.frame_top_window(space_id, frame_id_from)
  local twin = sdorfehs.frame_top_window(space_id, frame_id_to)

  if fwin ~= nil then
    fwin["frame"] = frame_id_to
    sdorfehs.window_reframe(fwin)
  end
  if twin ~= nil then
    twin["frame"] = frame_id_from
    sdorfehs.window_reframe(twin)
  end
  sdorfehs.frame_focus(space_id, frame_id_to, true)
end

-- remove current frame
sdorfehs.frame_remove = function(space_id)
  if table.count(sdorfehs.spaces[space_id].frames) == 1 then
    return
  end

  local id_removing = sdorfehs.spaces[space_id].frame_current

  -- reframe all windows in the current frame and renumber higher frames
  for _, w in ipairs(sdorfehs.windows) do
    if w["space"] == space_id then
      if w["frame"] == id_removing then
        w["frame"] = 0
        sdorfehs.window_reframe(w)
      elseif w["frame"] > id_removing then
        w["frame"] = w["frame"] - 1
      end
    end
  end

  -- shift other frame numbers down
  table.remove(sdorfehs.spaces[space_id].frames, id_removing)

  if sdorfehs.spaces[space_id].frame_previous > id_removing then
    sdorfehs.spaces[space_id].frame_previous =
      sdorfehs.spaces[space_id].frame_previous - 1
  end

  -- TODO: actually resize other frames

  sdorfehs.frame_focus(space_id, sdorfehs.spaces[space_id].frame_previous, true)
end

-- split a frame vertically
sdorfehs.frame_vertical_split = function(space_id, frame_id)
  return sdorfehs.frame_split(space_id, frame_id, true)
end

-- return the first window in this frame
sdorfehs.frame_top_window = function(space_id, frame_id)
  for _, w in ipairs(sdorfehs.windows) do
    if w["space"] == space_id and w["frame"] == frame_id then
      return w
    end
  end
end

sdorfehs.frame_message_timer = nil
sdorfehs._frame_message = nil
sdorfehs.frame_message = function(space_id, frame_id, message)
  if sdorfehs.frame_message_timer ~= nil then
    sdorfehs.frame_message_timer:stop()
  end

  if sdorfehs._frame_message ~= nil then
    sdorfehs._frame_message:delete()
    sdorfehs._frame_message = nil
  end

  local frame = sdorfehs.spaces[space_id].frames[frame_id]
  if frame == nil then
    return
  end

  local textFrame = hs.drawing.getTextDrawingSize(message,
    { size = sdorfehs.frame_message_font_size })
  local lwidth = textFrame.w + 30
  local lheight = textFrame.h + 10

  sdorfehs._frame_message = hs.canvas.new {
    x = frame.x + (frame.w / 2) - (lwidth / 2),
    y = frame.y + (frame.h / 2) - (lheight / 2),
    w = lwidth,
    h = lheight,
  }:level(hs.canvas.windowLevels.popUpMenu)

  sdorfehs._frame_message[1] = {
    id = "1",
    type = "rectangle",
    action = "fill",
    center = {
      x = lwidth / 2,
      y = lheight / 2,
    },
    fillColor = { green = 0, blue = 0, red = 0, alpha = 0.9 },
    roundedRectRadii = { xRadius = 15, yRadius = 15 },
  }
  sdorfehs._frame_message[2] = {
    id = "2",
    type = "text",
    frame = {
      x = 0,
      y = ((lheight - sdorfehs.frame_message_font_size) / 2) - 1,
      h = "100%",
      w = "100%",
    },
    textAlignment = "center",
    textColor = { white = 1.0 },
    textSize = sdorfehs.frame_message_font_size,
    text = message,
  }

  sdorfehs._frame_message:show()

  sdorfehs.frame_message_timer = hs.timer.doAfter(sdorfehs.frame_message_secs,
    function()
      if sdorfehs._frame_message ~= nil then
        sdorfehs._frame_message:delete()
        sdorfehs._frame_message = nil
      end
      sdorfehs.frame_message_timer = nil
    end)
end
