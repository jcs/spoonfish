-- come on, lua
table.count = function(tab)
  local c = 0
  for i, j in pairs(tab) do
    c = c + 1
  end
  return c
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
