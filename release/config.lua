--local M = {}

local home = _ENV._HOME
--print("in config.lua",home)
if not home then
  local lfs = require "lfs"
  if not lfs then
    print("! You must set '_HOME' or put lfs.dll under the same dir as config.lua")
    return nil
  end

  home = lfs.currentdir()
end
package.cpath=string.format( '%s/?.dll;%s/?53.dll;%s/lib/?.dll;%s/lib/?53.dll;',home,home,home,home )
package.path= string.format( '%s/?.lua;%s/?.luac;%s/lua/?.lua;%s/lua/?.luac;%s/lib/?.lua;%s/lib/?.luac;',home,home ,home,home,home,home)

return "OK"
--return M
