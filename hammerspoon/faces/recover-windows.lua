-- Emergency window recovery script
-- Run in Hammerspoon console: dofile("/tmp/recover-windows.lua")
local screen = hs.screen.mainScreen():frame()
local x, y = 100, 100
for _, window in ipairs(hs.window.allWindows()) do
  if window:isStandard() then
    local frame = window:frame()
    if frame and frame.x < 0 then
      window:setTopLeft({x = x, y = y})
      print("Recovered: " .. (window:title() or "untitled") .. " to " .. x .. "," .. y)
      x = x + 30
      y = y + 30
      if y > 600 then y = 100; x = x + 100 end
    end
  end
end
print("Done!")
