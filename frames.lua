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

-- return a table of frame ids touching frame_id on side dir
spoonfish.frame_find_touching = function(space_id, frame_id, dir)
  local cur = spoonfish.spaces[space_id].frames[frame_id].rect
  local found = {}

  if dir == spoonfish.direction.LEFT then
    -- x+w touching the x of the current frame, with same y
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.rect.x + f.rect.w == cur.x and f.rect.y == cur.y then
        found[i] = true
      end
    end
    -- or just x+w touching the x of the current frame
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.rect.x + f.rect.w == cur.x then
        found[i] = true
      end
    end
  elseif dir == spoonfish.direction.RIGHT then
    -- x touching the x+w of the current frame, with same y
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.rect.x == cur.x + cur.w and f.rect.y == cur.y then
        found[i] = true
      end
    end
    -- or just x touching the x+w of the current frame
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.rect.x == cur.x + cur.w then
        found[i] = true
      end
    end
  elseif dir == spoonfish.direction.DOWN then
    -- y touching the y+h of the current frame, with same x
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.rect.y == cur.y + cur.h and f.rect.x == cur.x then
        found[i] = true
      end
    end
    -- or just y touching the y+h of the current frame
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.rect.y == cur.y + cur.h then
        found[i] = true
      end
    end
  elseif dir == spoonfish.direction.UP then
    -- y+h touching the y of the current frame, with same x
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.rect.y + f.rect.h == cur.y and f.rect.x == cur.x then
        found[i] = true
      end
    end
    -- or just y+h touching the y of the current frame
    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if f.rect.y + f.rect.h == cur.y then
        found[i] = true
      end
    end
  else
    error("frame_find_touching: bogus direction")
  end

  return table.keys(found)
end

spoonfish.frame_rect_with_gap = function(space_id, frame_id)
  local rect = spoonfish.spaces[space_id].frames[frame_id].rect
  local hgap = spoonfish.gap / 2
  local grect = spoonfish.inset(rect, hgap)
  local srect = spoonfish.spaces[space_id].rect

  if rect.x == srect.x then
    -- touching left side
    grect.x = grect.x + hgap
    grect.w = grect.w - hgap
  end

  if rect.y == srect.y then
    -- touching top
    grect.y = grect.y + hgap
    grect.h = grect.h - hgap
  end

  if (rect.x + rect.w) == (srect.x + srect.w) then
    -- touching right side
    grect.w = grect.w - hgap
  end

  if (rect.y + rect.h) == (srect.y + srect.h) then
    -- touching bottom
    grect.h = grect.h - hgap
  end

  return grect
end

-- give focus to frame and raise its active window
spoonfish.frame_focus = function(space_id, frame_id, raise)
  if spoonfish.spaces[space_id].frames[frame_id] == nil then
    error("bogus frame " .. frame_id .. " on space " .. space_id)
    return
  end

  local fc = spoonfish.spaces[space_id].frame_current
  local wof = spoonfish.frame_top_window(space_id, frame_id)
  if wof then
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

spoonfish.frame_resize_interactively = function(space_id, frame_id)
  if table.count(spoonfish.spaces[space_id].frames) == 1 then
    spoonfish.frame_message(space_id,
      table.keys(spoonfish.spaces[space_id].frames)[1],
      "Cannot resize only frame", false)
    return
  end

  spoonfish.resizing = true
  spoonfish.frame_message(space_id, frame_id, "Resize frame", true)
end

-- shrink or grow a given frame
spoonfish.frame_resize = function(space_id, frame_id, dir)
  local origrect = spoonfish.inset(
    spoonfish.spaces[space_id].frames[frame_id].rect, 0)
  local srect = spoonfish.spaces[space_id].rect
  local resized = {}

  if dir == spoonfish.direction.LEFT or dir == spoonfish.direction.RIGHT or
   dir == spoonfish.direction.UP or dir == spoonfish.direction.DOWN then
    local amt = spoonfish.resize_unit
    local xy = "x"
    local wh = "w"

    if dir == spoonfish.direction.LEFT or dir == spoonfish.direction.UP then
      -- shrink
      amt = -amt
    end

    if dir == spoonfish.direction.UP or dir == spoonfish.direction.DOWN then
      xy = "y"
      wh = "h"
    end

    if (origrect[xy] == srect[xy]) and
     (origrect[xy] + origrect[wh] == srect[xy] + srect[wh]) then
      -- the original frame can't be resized in this direction, don't bother
      -- resizing any others
      return
    end

    for i, f in pairs(spoonfish.spaces[space_id].frames) do
      if (f.rect[xy] == srect[xy]) and
       (f.rect[xy] + f.rect[wh] == srect[xy] + srect[wh]) then
        -- this frame can't be resized in this direction
      else
        -- shrink/grow frames with this frame's coord
        if f.rect[xy] == origrect[xy] then
          if (f.rect[xy] + f.rect[wh]) == (srect[xy] + srect[wh]) then
            -- frame is on the right/bottom screen edge, keep its edge there by
            -- moving it left or up
            f.rect[xy] = f.rect[xy] - amt
          end
          f.rect[wh] = f.rect[wh] + amt
          resized[i] = true
        end

        -- grow/shrink frames with edge of this frame's shrunken/grown edge
        if (f.rect[xy] + f.rect[wh] == origrect[xy]) or
         (f.rect[xy] == origrect[xy] + origrect[wh]) then
          if (f.rect[xy] + f.rect[wh]) == (srect[xy] + srect[wh]) then
            -- frame is on the right/bottom screen edge, keep its edge there
            f.rect[xy] = f.rect[xy] + amt
          end
          f.rect[wh] = f.rect[wh] - amt
          resized[i] = true
        end
      end
    end
  else
    error("frame_resize: bogus direction")
    return
  end

  spoonfish.draw_frames(space_id)

  for _, w in ipairs(spoonfish.windows) do
    if w["space"] == space_id and resized[w["frame"]] then
      spoonfish.window_reframe(w)
    end
  end
end

-- split a frame vertically or horizontally
spoonfish.frame_split = function(space_id, frame_id, vertical)
  local old_rect = spoonfish.spaces[space_id].frames[frame_id].rect
  local new_rect = {}

  -- halve current frame
  if vertical then
    new_rect = hs.geometry.rect(
      old_rect.x,
      old_rect.y,
      math.floor(old_rect.w / 2),
      old_rect.h
    )
  else
    new_rect = hs.geometry.rect(
      old_rect.x,
      old_rect.y,
      old_rect.w,
      math.floor(old_rect.h / 2)
    )
  end
  spoonfish.spaces[space_id].frames[frame_id].rect = new_rect

  -- reframe all windows in that old frame
  for _, w in ipairs(spoonfish.windows) do
    if w["space"] == space_id and w["frame"] == frame_id then
      spoonfish.window_reframe(w)
    end
  end

  local new_frame_id = table.count(spoonfish.spaces[space_id].frames) + 1
  local new_frame_rect = {}

  if vertical then
    new_frame_rect = hs.geometry.rect(
      new_rect.x + new_rect.w,
      new_rect.y,
      old_rect.w - new_rect.w,
      new_rect.h
    )
  else
    new_frame_rect = hs.geometry.rect(
      new_rect.x,
      new_rect.y + new_rect.h,
      new_rect.w,
      old_rect.h - new_rect.h
    )
  end
  spoonfish.spaces[space_id].frames[new_frame_id] = { rect = new_frame_rect }

  spoonfish.draw_frames(space_id)
  spoonfish.frame_focus(space_id, new_frame_id, true)

  -- we'll probably want to go to this frame on tab
  spoonfish.spaces[space_id].frame_previous = new_frame_id
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
    spoonfish.frame_message(space_id,
      table.keys(spoonfish.spaces[space_id].frames)[1],
      "Cannot remove only frame", false)
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

  spoonfish.frame_focus(space_id, spoonfish.spaces[space_id].frame_previous,
    true)
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
spoonfish.frame_message = function(space_id, frame_id, message, sticky)
  if spoonfish.frame_message_timer ~= nil then
    spoonfish.frame_message_timer:stop()
  end

  if spoonfish._frame_message ~= nil then
    spoonfish._frame_message:delete()
    spoonfish._frame_message = nil
  end

  if message == nil then
    return
  end

  if spoonfish.spaces[space_id].frames[frame_id] == nil then
    return
  end
  local frame = spoonfish.spaces[space_id].frames[frame_id].rect

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

  if not sticky then
    spoonfish.frame_message_timer = hs.timer.doAfter(
      spoonfish.frame_message_secs, function()
        if spoonfish._frame_message ~= nil then
          spoonfish._frame_message:delete()
          spoonfish._frame_message = nil
        end
        spoonfish.frame_message_timer = nil
      end)
  end
end

-- for debugging
spoonfish.draw_frames = function(space_id)
  if not spoonfish.debug_frames then
    return
  end

  for i, f in pairs(spoonfish.spaces[space_id].frames) do
    if f.outline == nil then
      f.outline = hs.drawing.rectangle(f.rect)
    else
      f.outline:setFrame(f.rect)
    end
    f.outline:setLevel(hs.drawing.windowLevels.normal)
    f.outline:setStrokeColor({ ["hex"] = "#ff0000" })
    f.outline:setStrokeWidth(4)
    f.outline:setFill(false)
    f.outline:show()
  end
end
