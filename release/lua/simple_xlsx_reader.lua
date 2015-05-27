
local ziparchive = require 'ziparchive'
--local lom = require "lxp.lom" -- too slow
local lxp =  require"lxp"

function resetTable( t )  --for  table resue
  if not t or type(t) ~= 'table' then
    return nil
  end

  for k,_ in pairs(t) do
    t[k] = nil
  end

  return t
end

function SpreadsheetColLettersToNum(colLetters)
      if colLetters then
          local colNum = 0
          local index = 1
          repeat
              colNum = colNum * 26
              colNum = colNum + colLetters:byte(index) - ('A'):byte(1) + 1
              index = index + 1
          until index > #colLetters

          return colNum
      end
      return nil
end

  --[[

    2, A, B1
    return {row=,col=} , toUpperCase()

  ]]
function SpreadsheetPosition( str )
  local self = {
    row = nil,
    col = nil,
    colNum = nil
  }

  function self.parse( str )
    if not str then
      return
    end
    --print("***parsing ..." .. str)
    --str = str:upper()
    --find word first, then number
    local s,e = str:find("%a+")
     if s then
      self.col = (str:sub(s,e)):upper()
    end
    s,e = str:find("%d+")

    if s then
      self.row = tonumber(str:sub(s,e))
    end

    colNum = SpreadsheetColLettersToNum(self.col)
    --[[
    for k, v in string.gmatch(str, "(%w*)(%d*)") do
       print ("gmatched> ", k,v)
    end
    ]]

  end

  function self.tostring(  )
    return table.concat({"<",tostring(self.row), "," , tostring(self.col) ,">"})
  end

  if str then
    self.parse(str)
  end

  return self
end

--[[
  local test = SpreadsheetPosition("ab34")
  print(test.tostring(), test.colNum)
  test = SpreadsheetPosition("b")
  print(test.tostring())
--]]
--[[
{minRow=xx, minCol=yy, maxRow=xx1, maxCol=yy1}
]]
function SpreadsheetRange(str)
  local self = {
    minRow = 1,
    minCol = "A",
    maxRow = nil,
    maxCol = nil,

    minColNum = 1,
    maxColNum = nil
    --SpreadsheetPosition
    --min = nil
    --max = nil
  }


  function _parsePosition( position )
    return SpreadsheetPosition(position)
  end




  function _setSingle( t )
    if t.row then
      self.minRow = t.row or 1
      self.maxRow = t.row
    elseif t.col then
      self.minCol = t.col or "A"
      self.maxCol = t.col

    end

  end

  --[[
    str:eg: 2, A, B1, A3:B4
  ]]
  function self.parse( str )
    if not str then
      return nil
    end

    local c = str:find(":") --should not be ":" only , or startsWith/endsWith it, min should < max
    if c then
      if #str == 1 then
         return null , "invalid range: " .. str
      elseif c == 1 then
        str = str:sub(2) -- remove first
        local t = _parsePosition(str)
        _setSingle(t)

      elseif c == #str then
        str = str:sub(1,-2) --remove last
        local t = _parsePosition(str)
        _setSingle(t)
      else
        local t1 = _parsePosition(str:sub(1,c-1))
        local t2 = _parsePosition(str:sub(c+1))

        self.minRow = t1.row or 1
        self.minCol = t1.col or "A"
        self.maxRow = t2.row
        self.maxCol = t2.col

      end

    else
      local t = _parsePosition(str)
      _setSingle(t)
    end

    self.minColNum = SpreadsheetColLettersToNum(self.minCol)
    self.maxColNum = SpreadsheetColLettersToNum(self.maxCol)
  end

  --[[
    四面出击
  ]]
  function self.union( r )
    if not r then
      return
    end

    --nil means the minist for minRow/Col, means the max for maxRow/Col

    if not self.minRow or ( r.minRow and  r.minRow < self.minRow ) then
      self.minRow = r.minRow
    end

    if not self.minCol or ( r.minCol and  r.minCol < self.minCol ) then
      self.minCol = r.minCol
    end

    if not r.maxRow or ( self.maxRow and  r.maxRow > self.maxRow ) then
      self.maxRow = r.maxRow
    end

    if not r.maxCol or ( self.maxCol and  r.maxCol > self.maxCol ) then
      self.maxCol = r.maxCol
    end

    self.minColNum = SpreadsheetColLettersToNum(self.minCol)
    self.maxColNum = SpreadsheetColLettersToNum(self.maxCol)

  end

  function self.inRange( spreadsheetPosition )
    if not spreadsheetPosition then
      return false
    end

    local rc = _parsePosition(spreadsheetPosition) -- should have both row and col
 --   print("in range? " .. rc.tostring())
    if not rc then
      --should return error ?
      return false
    end

    if self.minRow and rc.row < self.minRow then
      return false
    end
    if self.maxRow and rc.row > self.maxRow then
      return false
    end
    if self.minColNum and rc.colNum and rc.colNum < self.minColNum then
      return false
    end
    if self.maxColNum and rc.colNum and rc.colNum > self.maxColNum then
      return false
    end

    return true
  end

  function self.tostring(  )
    return table.concat({"[<",tostring(self.minRow), "," , tostring(self.minCol) ,">, <",
                            tostring(self.maxRow), ",", tostring(self.maxCol),">]"})
  end

  if str then
    self.parse(str)
  end

  return self

end

--[[ do test

  local r = SpreadsheetRange("A1:C5")
  print(r.tostring())

  print (r.inRange("B4"))
  print (r.inRange("D1"))

  local r2 = SpreadsheetRange("b:d8")
  print(r2.tostring())

  r2.union(r)

  print("Union> ", r2.tostring())

--]]

--[[
  Closure-based objects
]]
function Workbook(filename)
  -- the new instance to return as public table at last, no ':' needed
  local self = {
    -- public fields go in the instance table
    _VERSION = 0.1
  }

  local _sheets = {} -- 1-sheetName1, 2=sheetName2
  local _handlers = {}  --预先声明

  function self.getSheets()
    return _sheets
  end

  function self.getTotalSheets()
    local count = 0
    for _,_ in pairs(_sheets) do
      count = count + 1
    end

    return count
  end



  --[[
-<sheets>
  <sheet r:id="rId1" sheetId="1" name="主表"/>
</sheets>
  ]]
  local _workbook_callbacks = {
    StartElement = function (parser, name, attributes)
      --print("parsing " .. name)
      if name == 'sheet' then
        --print(attributes.sheetId .. "=" .. attributes.name)
        _sheets[attributes.sheetId] = attributes.name
      end
    end,

    EndElement = false,

    CharacterData =  false
  }

  local _sharedstrings = {}

  local _sharedstrings_callbacks = {
    StartElement = function (parser, name, attributes)  --<si><t xml:space="preserve">资产帐簿 </t></si>
     -- print ("parsing tag...<" .. name .. ">")
    end,

    EndElement = function (parser, name)
      if name == "t" then
        self.CharacterData = true -- restores placeholder
      else
        self.CharacterData = false
      end
    end,

    CharacterData =  function (parser, string)
        --  print("[" .. Lz(string) .. "]")
          --insert into table
          _sharedstrings[#_sharedstrings+1] = string
    end
}

--local _cellHandler = nil
--local _rangeList = nil -- {A, B1, A3:B4} should ananlysis the outerbound
local __fastRangeList = {} -- { SpreadsheetRange{minRow=xx, minCol=yy, maxRow=xx1, maxCol=yy1} ,...} if one of is nil ,means unchecked
local _outerbound = nil -- a range object, when outer of bound,  parser should stop() ,when maxRow and maxCol reached

--==============================================================================

function _parseRangeList( rangeList )
  if not rangeList then
    print("OUTER BOUND: NO")
    return
  end

  for _,v in ipairs(rangeList) do
    local r = SpreadsheetRange(v)
    __fastRangeList[#__fastRangeList+1] = r
    if _outerbound then
      _outerbound.union(r) -- spread min or max with r
    else
      _outerbound = r
    end


  end
  print("OUTER BOUND:", _outerbound.tostring())

end

function _inRange( position )
  --default true
  if #__fastRangeList == 0 then
    return true
  end
  for _,r in ipairs(__fastRangeList) do
    if r.inRange(position) then
      return true
    end
  end

  return false
end

--==============================================================================
--[[

ST_Celltype= b(boolean), e(error), inlineStr, n(number) ,s(sharedString) ,str(formular string)
<dimension ref="A1:AF203"/>
...
<sheetData>
-<row r="2" spans="1:7" ht="13.5" customFormat="1" s="1">
  -<c r="A2" s="1" t="s">
    <v>7</v>
  </c>
  -<c r="B2" s="1">
    <f>sum(a1:b3)</f>
    <v>13950301</v>
  </c>
  <c r="AK9" t="str">
    <f>T("15440811G000030")</f>
    <v>15440811G000030</v>
  </c>

</row>
]]

--[[get dimension only!
local _sheet_dimension_callbacks = {
  StartElement = function (parser, name, attributes)
    if name == "dimension" then  --once only
        _dimension = SpreadsheetRange(attributes.ref)
        parser:stop()
    end
  end
}
]]


local _sheet_callbacks = {

    StartElement = function (parser, name, attributes)
      if name == "c" then
        --print("reading column ".. attributes.r ..", cellNum",self.cellNum, _outerbound)

        self.cellNum =  self.cellNum + 1
        if not _outerbound or not _outerbound.maxColNum or (_outerbound.maxColNum and self.cellNum <= _outerbound.maxColNum) then
          self.cell =  resetTable(self.cell) or {}

          self.cell.type=attributes.t
          self.cell.s=attributes.s
          self.cell.position=attributes.r
          self.cell.rowNum = self.rowNum
          self.cell.dimension = self.dimension
          --print("making cell :" .. attributes.r )

       end

      elseif name == "v" then  --value
        self.canParseCharacterData = true

      elseif name == "f" then  --formula

      elseif name == "dimension" then  --once only
        self.dimension = SpreadsheetRange(attributes.ref)
        if _handlers.SheetHandler then
            local doNext = _handlers.SheetHandler({dimension = self.dimension})  --once only
            if not doNext then
              print("Stop when parsing sheet (User canceled)")

              p:stop()
            end
        end

      elseif name == "row" then  --new row
        local rn = tonumber(attributes.r)

        if _handlers.RowHandler then
          self.row = resetTable(self.row) or {}

          self.row.dimension = self.dimension
          self.row.rowNum=rn

          local doNext, msg =_handlers.RowHandler(self.row)
          if not doNext then
              print("Stop when parsing row " .. rn, "|\tcause: (User canceled) " .. tostring(msg))

              p:stop()
          end
        end

        --print ("reading row " .. rn, type(rn), type(_outerbound.maxRow))
        if  (_outerbound and _outerbound.maxRow and rn > _outerbound.maxRow) then
            print("Stop parsing for the sake of out-of-bound: row > ", _outerbound.maxRow)
           p:stop()
        end
        self.rowNum = rn

        self.cellNum = 0
      end
    end,

    EndElement = function (parser, name)
      if name == "v" and self.cell then
        self.CharacterData = true -- restores placeholder
      else
        self.CharacterData = false
      end
    end,
    --value or formula
    CharacterData = function (parser, string)
          if not self.canParseCharacterData then
            return
          end
          self.canParseCharacterData=false

          if not self.cell then
            return
          end

          if not _inRange(self.cell.position) then
            --print ("ignored cell: " .. self.cell.position)
            return
          end

          if self.cell.type == "s" then
            local num = tonumber(string)
            if num == nil then
              print(self.cell.position, "nil v?", string)
            end
            self.cell.value=_sharedstrings[num+1]
          else
            self.cell.value = string
          end

          --print(string .." ==>" .. Lz(tostring(self.cell.value)))

          if _handlers.CellHandler then
            local doNext = _handlers.CellHandler(self.cell)
            --self.cell = nil --consumed

            if not doNext then
              p:stop()
            end
          end
    end
}

  function _xlsx_readdocument(archive, documentName, callbacks)
    local file = archive:fileopen(documentName)
    if not file then return end
   -- print ("DOC reading>" .. documentName)
    local buffer = archive:fileread(file)
    archive:fileclose(file)
   -- print ("<DOC read:" .. documentName)

    p = lxp.new(callbacks)
    status, err = p:parse(buffer)
    if not status then return nil, err end
    --print("parsing done")
    p:close();

    return "OK"
  end

  local _archive = nil

  function _init(filename)

    _archive,err = ziparchive.open(filename)
    
    if not _archive then
      print("无法打开文件:" .. filename , err)
    end
    
    

    --read first
    _xlsx_readdocument(_archive, "xl/workbook.xml" ,  _workbook_callbacks)

--[[
    print("sheet list :")
    for k,v in pairs(_sheets) do
      print(k,Lz(v))
    end

    print ("Files in archive..." )

    for i=1,_archive:fileentrycount() do
      entry = _archive:fileentry(i)
      print(entry.filename)
    end
]]

    return "OK"
 end

function self.close()
  if _archive then
    _archive:close()
  end
end

--local _dimension = nil  --a SpreadsheetRange Object


local _sharedStringsLoaded = false -- can use next(sharedStrings) to decide if empty
--[[
    <current>
    handlers {CellHandler(cell), RowHandler(row),SheetHandler(sheet)}
    return true to continue, false to stop
    rangeList: {A, B1, A3:B4}

    return dimension
  ]]
 function self.sheet( index, handlers , rangeList)
   if not index or index < 1 or index > self.getTotalSheets() then
     return nil , "Invalid sheet index: " .. tostring(index)
   end

   print("------------reading sheet[" .. index .. "] " .. _sheets[tostring(index)])
   --延长加载
   if  not _sharedStringsLoaded then
        _xlsx_readdocument(_archive, "xl/sharedStrings.xml" ,  _sharedstrings_callbacks)
        _sharedStringsLoaded = true
   end

   --sheet_callbacks.cellHandler = cellHandler  --bad argument #-1 to 'new' (invalid option cellHandler)
   --_cellHandler = cellHandler
   if handlers then
     _handlers = handlers
   end

   _parseRangeList ( rangeList )
   _xlsx_readdocument(_archive, "xl/worksheets/sheet" .. index .. ".xml" , _sheet_callbacks) --block?

   return "OK"
 end



  _init(filename)
  -- return the instance
  return self
end


