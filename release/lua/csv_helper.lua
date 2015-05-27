function resetTable( t )  --for  table resue
  if not t or type(t) ~= 'table' then
    return nil
  end

  for k,_ in pairs(t) do
    t[k] = nil
  end

  return t
end


--[[http://lua-users.org/wiki/CsvUtils]]
function CsvHelper(delim)
  -- the new instance to return as public table at last, no ':' needed
  local self = {
    -- public fields go in the instance table
    _VERSION = 0.2,
    _DESCRIPTION = "Csv Utils"
  }

  -- private fields are implemented using locals
  -- they are faster than table access, and are truly private, so the code that uses your class can't get them
  local _delim = delim or ','
  local _buffer = {} --reused table

  function _escapeCSV (s)
    if string.find(s, '[' .. _delim ..'"]') then
      s = '"' .. string.gsub(s, '"', '""') .. '"'
    end
    return s
  end
  --[[
    FIXME : 没有“” 时，换行被当做“”内的字符
  ]]
  function self.fromCSV (s)
    s = s .. _delim        -- ending comma
    local t = {}        -- table to collect fields
    local fieldstart = 1
    repeat
      -- next field is quoted? (start with `"'?)
      if string.find(s, '^"', fieldstart) then
        local a, c
        local i  = fieldstart
        repeat
          -- find closing quote
          a, i, c = string.find(s, '"("?)', i+1)
        until c ~= '"'    -- quote not followed by quote?
        if not i then error('unmatched "') end
        local f = string.sub(s, fieldstart+1, i-1)
        table.insert(t, (string.gsub(f, '""', '"')))
        fieldstart = string.find(s, _delim, i) + 1
      else                -- unquoted; find next comma
        local nexti = string.find(s, _delim , fieldstart)
        table.insert(t, string.sub(s, fieldstart, nexti-1))
        fieldstart = nexti + 1
      end
    until fieldstart > string.len(s)
    return t
  end

    -- Convert from table to CSV string
  function self.toCSV (tt)
    resetTable(_buffer)
    --local sb = StringBuffer(_buffer) --每次创建函数

  -- ChM 23.02.2014: changed pairs to ipairs
  -- assumption is that fromCSV and toCSV maintain data as ordered array
    for _,p in ipairs(tt) do
      --sb.append(_escapeCSV(p))
      _buffer[#_buffer+1] = _escapeCSV(p)
    end
    --return sb.tostring(_delim)
    return table.concat( _buffer, _delim)
  end

  -- return the instance
  return self
end


-- local t = CsvHelper().fromCSV([[
--号码,名称,编码,是否EPON出线,语音横列线架编码,语音横列端子,机房语音直列线架编码,机房语音直列端子,语音主干,跳接主干,跳接直列线架编码,跳接直列端子,宽带横列线架编码,宽带横列端子,PON加装横列线架编码,PON加装横列端子,末端直列线架编码,末端直列端子,交接箱编码,末端主干端子,配线端子号,分线盒编码,分线盒线序,分线盒地址,加装号码,备注,分光器编码,分光器地址,分光器端口,ONT MAC地址,SN号,ONT端口号
--3086898," 址山莲花街,址山莲花街机房2 ",HSLHS001,否,0101H,0001-056,,,,,,,,,,,0101V,123-69,DJ0502,45,89,DP120,9,茵庭园1栋之1,75000318327,test,,,,,,
--075000317877,愉景苑(城西),TSYJY001,否,,,,,,,,,0101E,12-56,,,0101V,789-69,直配,直配,直配,ZDP55,3,莲塘牌坊,,,,,,,,
--075000319037,东恩,EPDE001,否,,,0101E,,3,2,0103V,,0101H,120-65,,,0101V,123-56,DJ0102,3,5,DP2233,2,东阿路100号,,,,,,,,

--    ]])


--for i,v in ipairs(t) do
--  print(i,v)
--end
