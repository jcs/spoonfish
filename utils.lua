-- come on, lua
table.count = function(tab)
  local c = 0
  for i, j in pairs(tab) do
    c = c + 1
  end
  return c
end

sdorfehs.last_alert = nil
sdorfehs.alert = function(str)
  if sdorfehs.last_alert then
    hs.alert.closeSpecific(sdorfehs.last_alert, 0)
  end

  local style = hs.alert.defaultStyle
  style["atScreenEdge"] = 2
  sdorfehs.last_alert = hs.alert(str, style)
end

sdorfehs.inset = function(rect, ins)
  return hs.geometry.rect(rect.x + ins, rect.y + ins, rect.w - (ins * 2),
    rect.h - (ins * 2))
end

sdorfehs.dump_wins = function(wins)
  for i, w in pairs(wins) do
    print("win[" .. i .. "] space[" .. w["space"] .. "] frame[" ..
      w["frame"] .. "] title:" .. w["win"]:title())
  end
end

sdorfehs.dump_frames = function(space_id)
  for i, f in pairs(sdorfehs.spaces[space_id].frames) do
    print("frame[" .. f["id"] .. "]")
  end
end

sdorfehs.escape_pattern = function(str)
  local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
  return str:gsub(quotepattern, "%%%1")
end
