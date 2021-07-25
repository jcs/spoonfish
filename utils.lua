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

sdorfehs.outline_timer = nil
sdorfehs._outline = nil
sdorfehs.outline = function(rect)
  if sdorfehs.outline_timer ~= nil then
    sdorfehs.outline_timer:stop()
  end

  if sdorfehs._outline ~= nil then
    sdorfehs._outline:delete()
    sdorfehs._outline = nil
  end

  sdorfehs._outline = hs.drawing.rectangle(rect)
  sdorfehs._outline:setStrokeColor({ ["hex"] = "#ff0000" })
  sdorfehs._outline:setFill(false)
  sdorfehs._outline:setStrokeWidth(5)
  sdorfehs._outline:show()
--  sdorfehs.outline_timer = hs.timer.doAfter(sdorfehs.outline_secs, function()
--    if sdorfehs._outline ~= nil then
--      sdorfehs._outline:delete()
--      sdorfehs._outline = nil
--    end
--    sdorfehs.outline_timer = nil
--  end)
end
