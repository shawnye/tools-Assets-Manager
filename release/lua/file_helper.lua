local M = {}

local lfs = require "lfs"
local os = require "os"

--local
function stripSlash( f )
  --strip last / or \\
  local lastChar = f:sub(#f,#f)
  --print(lastChar)
  if lastChar == '/' or lastChar == '\\' then
    f = f:sub(1,-2)
    --print("stripped:", f)
  end

  return f
end

M.getParent = function(f)
  if not f then
    return nil
  end	

  f = stripSlash(f)

  local s,e = f:find('[^/\\]+$')
  if not s then
	return nil
  end

  return f:sub(1,s-1)
  
end


--print('M.getParent', M.getParent("c:/zhong/asdf\\asdfds.lua"))

M.exists = function(f)
  if not f then
    return false
  end 
  f = stripSlash(f) 

  --windows only
  local lastChar = f:sub(#f,#f)
  if lastChar == ':' then
    return true, "hard drive"
  end  

  local mode = lfs.attributes (f, 'mode')  -- dev such as "c:/"
  return mode ~= nil, mode
end

--print('M.exists', M.exists("c:\\"))


--[[include all the parent dir, should not create dev ]]
M.createDirs = function(dir)
  if dir and M.exists(dir) then
    return true
  end

  local pd = M.getParent(dir)

 -- print("get parent=",pd)
  
  if pd and pd ~= '' and not M.exists(pd) then
	 local b,err = M.createDirs(pd)
	 if not b then
 		   return false , "fail to create dir '" .. pd .. "': " .. tostring(err);
  	end
  end

 -- print(" --creating:", dir)

  local b,err = lfs.mkdir (dir)
  if not b then
	return false , err;
  end	

 -- print("dir created:", dir)

  return true 
  
end

--[[
a,err = M.createDirs("c:/a/b/中/c")
if err then
  print(err)
end
--]]

M.copyFile = function(srcFile, destFile, overwrite)
  if not M.exists(srcFile) then
    --print("srcFile does not exists :" .. srcFile)
    return false ,"srcFile does not exists :" .. srcFile
  end

  if not overwrite and M.exists(destFile) then
    --print("ignoring existed destFile:" .. destFile)
    --return false , "ignoring existed destFile:" .. destFile
    --do delete
    os.remove(destFile)
  end

  local dir = M.getParent(destFile)
  M.createDirs(dir)

  local s,err = io.open(srcFile,"rb")
  if not s then
    print("can not read src file: " .. srcFile, err)
    return false ,err
  end

  local d,err2 = io.open(destFile,"wb")
  if not d then
    print("can not write dest file: " .. destFile, err2)
    return false,err2
  end
  d:setvbuf("full")

  local size = lfs.attributes (srcFile, 'size')
  
  local v = s:read("*a")
  d:write(v)
 
  d:flush()
  d:close()
  s:close()
	
  print("file copied ", srcFile, destFile, size)

  return true
end



local _fileCopied = 0
function _copyDir( srcDir, destDir, overwrite, maxLevel )
    if maxLevel == 0 then
      return true
    end
 

    local destFile = nil
    for file in lfs.dir(srcDir) do
        if file ~= "." and file ~= ".." then
            local f = srcDir..'/'..file

            local attr = lfs.attributes (f)
            if attr.mode == "directory" then
                _copyDir (f, destDir .."/" .. file, overwrite, (not maxLevel and 1 or maxLevel-1))
            elseif attr.mode == "file" then
                 destFile = destDir .. "/" .. file
                 local s,e = M.copyFile(f, destFile ,overwrite )
                if not s then
                  --print("fail to copy file " .. f .. " to " ..destFile )
                  return false , "fail to copy file " .. f .. " to " ..destFile .. ":" .. e
                end
                _fileCopied = _fileCopied + 1
            else
              -- dropped
            end
        end
    end

    return true
end
 
 --[[
  copy all files/dirs inside srcDir to destDir/
]]
M.copyDir = function ( srcDir, destDir, overwrite, maxLevel )
    if  not maxLevel  then
      maxLevel = 1000
    end

    if not overwrite then
      overwrite = true
    end

    destDir = stripSlash(destDir)

    local rt,err = _copyDir(srcDir, destDir, overwrite, maxLevel)
    if rt then
      return true,  _fileCopied
    else
      return false ,err
    end
end

--test
--m.copyFile("c:/test2.xls","f:/test10/test中文.xls")

--local b, count = m.copyDir("C:/distpy","f:/test10/", true)
--print ("file copied",count)

 return M