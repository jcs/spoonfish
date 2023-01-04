table.copy = function(tab)
  local ret = {}
  for k, v in pairs(tab) do
    ret[k] = v
  end
  return ret
end

-- come on, lua
table.count = function(tab)
  local c = 0
  for i, j in pairs(tab) do
    c = c + 1
  end
  return c
end

table.keys = function(tab)
  local ret = {}
  for k, _ in pairs(tab) do
    ret[#ret + 1] = k
  end
  return ret
end

spoonfish.dir_from_string = function(str)
  lstr = str:lower()

  if lstr == "left" then
    return spoonfish.direction.LEFT
  elseif lstr == "right" then
    return spoonfish.direction.RIGHT
  elseif lstr == "up" then
    return spoonfish.direction.UP
  elseif lstr == "down" then
    return spoonfish.direction.DOWN
  else
    error("dir_from_string: invalid direction")
    return nil
  end
end

spoonfish.last_alert = nil
spoonfish.alert = function(str)
  if spoonfish.last_alert then
    hs.alert.closeSpecific(spoonfish.last_alert, 0)
  end

  local style = hs.alert.defaultStyle
  style["atScreenEdge"] = 2
  spoonfish.last_alert = hs.alert(str, style)
end

spoonfish.inset = function(rect, ins)
  return hs.geometry.rect(rect.x + ins, rect.y + ins, rect.w - (ins * 2),
    rect.h - (ins * 2))
end

spoonfish.dump_wins = function(wins)
  for i, w in pairs(wins) do
    print("win[" .. i .. "] space[" .. w["space"] .. "] frame[" ..
      w["frame"] .. "] title:" .. w["win"]:title())
  end
end

spoonfish.dump_frames = function(space_id)
  for i, f in pairs(spoonfish.spaces[space_id].frames) do
    print("frame[" .. f["id"] .. "]")
  end
end

spoonfish.escape_pattern = function(str)
  local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
  return str:gsub(quotepattern, "%%%1")
end

spoonfish.rect_s = function(rect)
  return "{x:" .. rect.x .. " y:" .. rect.y .. " w:" .. rect.w .. " h:" ..
    rect.h .. "}"
end
