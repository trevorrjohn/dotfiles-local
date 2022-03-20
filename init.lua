require("hs.ipc")

-- Reload from the command line
-- hs -c "hs.reload()"
hs.ipc.cliInstall()

hs.loadSpoon("ShiftIt")
local obj = {}
obj.mash = { 'ctrl', 'alt', 'cmd', 'shift' }
obj.mapping = {
  left = { obj.mash, 'left' },
  right = { obj.mash, 'right' },
  up = { obj.mash, 'up' },
  down = { obj.mash, 'down' },
  upleft = { obj.mash, '1' },
  upright = { obj.mash, '2' },
  botleft = { obj.mash, '3' },
  botright = { obj.mash, '4' },
  maximum = { obj.mash, 'm' },
  toggleFullScreen = { obj.mash, 'f' },
  toggleZoom = { obj.mash, 'z' },
  center = { obj.mash, 'c' },
  nextScreen = { obj.mash, 'n' },
  previousScreen = { obj.mash, 'p' },
  resizeOut = { obj.mash, '=' },
  resizeIn = { obj.mash, '-' }
}

-- spoon.ShiftIt:bindHotkeys(obj.mapping);
spoon.ShiftIt:bindHotkeys({})
