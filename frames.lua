spoonfish.frame_s = function(frame)
  return "{x:" .. frame.x .. " y:" .. frame.y .. " w:" .. frame.w .. " h:" ..
    frame.h .. "}"
end

-- take control of a new hs.window and resize it to a particular frame
-- return a window table object
spoonfish.frame_capture = function(space_id, frame_id, hswin)
  local win = {
    ["win"] = hswin,
    ["frame"] = frame_id,
    ["space"] = space_id,
    ["app_pid"] = hswin:application():pid(),
  }
  table.insert(spoonfish.windows, win)
  spoonfish.window_reframe(win)
  spoonfish.window_restack(win, 1)
  return win
end

-- move the top window of a frame to the bottom of the stack, raise the next
-- available or last window to the top
spoonfish._frame_cycle = function(space_id, frame_id, reverse, complain)
  local wnf = spoonfish.windows_not_visible(space_id)

  if table.count(wnf) == 0 then
    if complain then
      spoonfish.frame_message(space_id, spoonfish.spaces[space_id].frame_current,
        "No more windows")
    end
    return
  end

  local fwin = spoonfish.frame_top_window(space_id, frame_id)
  if fwin then
    -- move this top window to the bottom of the stack
    spoonfish.window_restack(fwin, spoonfish.position.BACK)
  end

  -- find the first window that is not in a frame and bring it forth
  local cwin = wnf[1]
  if reverse then
    cwin = wnf[table.count(wnf)]
  end
  if cwin ~= nil then
    cwin["frame"] = frame_id
    spoonfish.frame_raise_window(space_id, frame_id, cwin)
  end
end
spoonfish.frame_cycle = function(space_id, frame_id, complain)
  spoonfish._frame_cycle(space_id, frame_id, false, complain)
end
spoonfish.frame_reverse_cycle = function(space_id, frame_id, complain)
  spoonfish._frame_cycle(space_id, frame_id, true, complain)
end

-- find a frame relative to frame_id in the direction dir
spoonfish.frame_find = function(space_id, frame_id, dir)
  local cur = spoonfish.spaces[space_id].frames[frame_id]

  if dir == spoonfish.direction.LEFT then
    -- x+w touching the x of the current frame, with same y
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.x + f.w == cur.x and f.y == cur.y then
        return i
      end
    end
    -- or just x+w touching the x of the current frame
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.x + f.w == cur.x then
        return i
      end
    end
  elseif dir == spoonfish.direction.RIGHT then
    -- x touching the x+w of the current frame, with same y
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.x == cur.x + cur.w and f.y == cur.y then
        return i
      end
    end
    -- or just x touching the x+w of the current frame
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.x == cur.x + cur.w then
        return i
      end
    end
  elseif dir == spoonfish.direction.DOWN then
    -- y touching the y+h of the current frame, with same x
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.y == cur.y + cur.h and f.x == cur.x then
        return i
      end
    end
    -- or just y touching the y+h of the current frame
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.y == cur.y + cur.h then
        return i
      end
    end
  elseif dir == spoonfish.direction.UP then
    -- y+h touching the y of the current frame, with same x
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.y + f.h == cur.y and f.x == cur.x then
        return i
      end
    end
    -- or just y+h touching the y of the current frame
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
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

spoonfish.frame_with_gap = function(space_id, frame_id)
  local iframe = spoonfish.inset(spoonfish.spaces[space_id].frames[frame_id],
    spoonfish.gap)

  if spoonfish.frame_find(space_id, frame_id,
   spoonfish.direction.LEFT) ~= frame_id then
    iframe.x = iframe.x - (spoonfish.gap / 2)
    iframe.w = iframe.w + (spoonfish.gap / 2)
  end

  if spoonfish.frame_find(space_id, frame_id,
   spoonfish.direction.UP) ~= frame_id then
    iframe.y = iframe.y - (spoonfish.gap / 2)
    iframe.h = iframe.h + (spoonfish.gap / 2)
  end

  if spoonfish.frame_find(space_id, frame_id,
   spoonfish.direction.RIGHT) ~= frame_id then
    iframe.w = iframe.w + (spoonfish.gap / 2)
  end

  if spoonfish.frame_find(space_id, frame_id,
   spoonfish.direction.DOWN) ~= frame_id then
    iframe.h = iframe.h + (spoonfish.gap / 2)
  end

  return iframe
end

-- give focus to frame and raise its active window
spoonfish.frame_focus = function(space_id, frame_id, raise)
  if spoonfish.spaces[space_id].frames[frame_id] == nil then
    error("bogus frame " .. frame_id .. " on space " .. space_id)
    return
  end

  local fc = spoonfish.spaces[space_id].frame_current
  local wof = spoonfish.frame_top_window(space_id, frame_id)
  if wof ~= nil then
    spoonfish.window_reframe(wof)
    if raise then
      wof["win"]:focus()
    end
    spoonfish.window_reborder(wof)
  end

  if frame_id ~= fc then
    spoonfish.spaces[space_id].frame_current = frame_id
    spoonfish.spaces[space_id].frame_previous = fc

    spoonfish.frame_message(space_id, frame_id, "Frame " .. frame_id)
  end
end

-- split a frame horizontally
spoonfish.frame_horizontal_split = function(space_id, frame_id)
  return spoonfish.frame_split(space_id, frame_id, false)
end

-- raise a window in a given frame, assigning it to that frame
spoonfish.frame_raise_window = function(space_id, frame_id, win)
  spoonfish.window_reframe(win)
  spoonfish.window_show(win)
  win["win"]:focus()
  spoonfish.window_restack(win, spoonfish.position.FRONT)
  spoonfish.window_reborder(win)
end

-- split a frame vertically or horizontally
spoonfish.frame_split = function(space_id, frame_id, vertical)
  local old_frame = spoonfish.spaces[space_id].frames[frame_id]

  -- halve current frame
  if vertical then
    spoonfish.spaces[space_id].frames[frame_id] = hs.geometry.rect(
      old_frame.x,
      old_frame.y,
      math.floor(old_frame.w / 2),
      old_frame.h
    )
  else
    spoonfish.spaces[space_id].frames[frame_id] = hs.geometry.rect(
      old_frame.x,
      old_frame.y,
      old_frame.w,
      math.floor(old_frame.h / 2)
    )
  end

  -- reframe all windows in that old frame
  for _, w in ipairs(spoonfish.windows) do
    if w["space"] == space_id and w["frame"] == frame_id then
      spoonfish.window_reframe(w)
    end
  end

  local new_frame = table.count(spoonfish.spaces[space_id].frames) + 1

  if vertical then
    spoonfish.spaces[space_id].frames[new_frame] = hs.geometry.rect(
      spoonfish.spaces[space_id].frames[frame_id].x +
      spoonfish.spaces[space_id].frames[frame_id].w,
      spoonfish.spaces[space_id].frames[frame_id].y,
      old_frame.w - spoonfish.spaces[space_id].frames[frame_id].w,
      spoonfish.spaces[space_id].frames[frame_id].h
    )
  else
    spoonfish.spaces[space_id].frames[new_frame] = hs.geometry.rect(
      spoonfish.spaces[space_id].frames[frame_id].x,
      spoonfish.spaces[space_id].frames[frame_id].y +
      spoonfish.spaces[space_id].frames[frame_id].h,
      spoonfish.spaces[space_id].frames[frame_id].w,
      old_frame.h - spoonfish.spaces[space_id].frames[frame_id].h
    )
  end

  spoonfish.frame_focus(space_id, frame_id, true)

  -- we'll probably want to go to this frame on tab
  spoonfish.spaces[space_id].frame_previous = new_frame
end

-- swap the front-most windows of two frames
spoonfish.frame_swap = function(space_id, frame_id_from, frame_id_to)
  local fwin = spoonfish.frame_top_window(space_id, frame_id_from)
  local twin = spoonfish.frame_top_window(space_id, frame_id_to)

  if fwin ~= nil then
    fwin["frame"] = frame_id_to
    spoonfish.window_reframe(fwin)
  end
  if twin ~= nil then
    twin["frame"] = frame_id_from
    spoonfish.window_reframe(twin)
  end
  spoonfish.frame_focus(space_id, frame_id_to, true)
end

-- remove current frame
spoonfish.frame_remove = function(space_id)
  if table.count(spoonfish.spaces[space_id].frames) == 1 then
    return
  end

  local id_removing = spoonfish.spaces[space_id].frame_current

  -- reframe all windows in the current frame and renumber higher frames
  for _, w in ipairs(spoonfish.windows) do
    if w["space"] == space_id then
      if w["frame"] == id_removing then
        w["frame"] = 0
        spoonfish.window_reframe(w)
      elseif w["frame"] > id_removing then
        w["frame"] = w["frame"] - 1
      end
    end
  end

  -- shift other frame numbers down
  table.remove(spoonfish.spaces[space_id].frames, id_removing)

  if spoonfish.spaces[space_id].frame_previous > id_removing then
    spoonfish.spaces[space_id].frame_previous =
      spoonfish.spaces[space_id].frame_previous - 1
  end

  -- TODO: actually resize other frames

  spoonfish.frame_focus(space_id, spoonfish.spaces[space_id].frame_previous, true)
end

-- split a frame vertically
spoonfish.frame_vertical_split = function(space_id, frame_id)
  return spoonfish.frame_split(space_id, frame_id, true)
end

-- return the first window in this frame
spoonfish.frame_top_window = function(space_id, frame_id)
  for _, w in ipairs(spoonfish.windows) do
    if w["space"] == space_id and w["frame"] == frame_id then
      return w
    end
  end
end

spoonfish.frame_message_timer = nil
spoonfish._frame_message = nil
spoonfish.frame_message = function(space_id, frame_id, message)
  if spoonfish.frame_message_timer ~= nil then
    spoonfish.frame_message_timer:stop()
  end

  if spoonfish._frame_message ~= nil then
    spoonfish._frame_message:delete()
    spoonfish._frame_message = nil
  end

  local frame = spoonfish.spaces[space_id].frames[frame_id]
  if frame == nil then
    return
  end

  local textFrame = hs.drawing.getTextDrawingSize(message,
    { size = spoonfish.frame_message_font_size })
  local lwidth = textFrame.w + 30
  local lheight = textFrame.h + 10

  spoonfish._frame_message = hs.canvas.new {
    x = frame.x + (frame.w / 2) - (lwidth / 2),
    y = frame.y + (frame.h / 2) - (lheight / 2),
    w = lwidth,
    h = lheight,
  }:level(hs.canvas.windowLevels.popUpMenu)

  spoonfish._frame_message[1] = {
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
  spoonfish._frame_message[2] = {
    id = "2",
    type = "text",
    frame = {
      x = 0,
      y = ((lheight - spoonfish.frame_message_font_size) / 2) - 1,
      h = "100%",
      w = "100%",
    },
    textAlignment = "center",
    textColor = { white = 1.0 },
    textSize = spoonfish.frame_message_font_size,
    text = message,
  }

  spoonfish._frame_message:show()

  spoonfish.frame_message_timer = hs.timer.doAfter(spoonfish.frame_message_secs,
    function()
      if spoonfish._frame_message ~= nil then
        spoonfish._frame_message:delete()
        spoonfish._frame_message = nil
      end
      spoonfish.frame_message_timer = nil
    end)
end
