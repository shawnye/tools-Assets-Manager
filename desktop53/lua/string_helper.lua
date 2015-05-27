--string extension
local stringx = require"stringx";

string.trim = function(self, enabled)
  if enabled ~= nil and not enabled then
    return self;
  end
  -- return self:gsub("^%s*(.-)%s*$", "%1")
  return stringx.trim(self); --self:match "^%s*(.-)%s*$"
end

string.isEmpty = function(self)
  return self == ''
end

string.isBlank = function(self)
  return self:trim() == ''
end

string.startsWith = function(self, startstr)
  return stringx.startsWith(self,startstr,0)
  --return self:sub(1,#startstr)==startstr
end

string.endsWith = function(self, endstr)
   return stringx.endsWith(self,endstr)
  --return self:sub(- #(endstr))==endstr
end

string.substring = function(self, s, e)
   return stringx.substring(self,s,e)
  --return self:sub(- #(endstr))==endstr
end

string.indexOf = function(self, key, start)
   return stringx.indexOf(self,key, start)
end

function _tchelper(first, rest)
      return first:upper()..rest:lower()
end

string.capitalizeWords = function(self)
  return self:gsub("(%a)([%w_']*)", _tchelper)
end


string.isValidMailAddress = function(self)
  return self:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")
end

--[[
print(("   sss  "):trim() .. "," )
print(("staxvdsfsdf"):startsWith("sta") )
print(("staxvdsfsdf"):endsWith("sf") )
print(("hello world !"):capitalizeWords() )

]]
