local M = {}

local math = require"math"
local os = require"os"
local io = require"io"
local reader = require"simple_xlsx_reader"

local ansicode = require"ansicode"

require "string_helper"

require "csv_helper"

local ch = CsvHelper(",")

--local csv = require"csv"
--local csvw

local currentRow = {}
local f



local date = require "date"
--[[

操作系统起始日期-Excel起始日期
1970-1900=25569日
(40557-25569)*86400 UTC秒数

--@see http://tieske.github.io/date/
local x = date((40557-25569)*86400 )
print(x:fmt("%Y-%m-%d"))

]]

local x = nil --tmp date object
local pos = nil
local v = nil
local encoding = nil --default: utf-8

function createCsv(cell) --dimension, type, position, value, formula, rowNum
    --[[
    local pos = SpreadsheetPosition(cell.position)
    --print ("dim.col, cur.col",cell.dimension.maxCol , cell.position, cell.value)
    if cell.dimension.maxCol == pos.col then
      print("last col " .. cell.position ,value)
    end
    --]]
    --first row
    if not lastRowNum then
      lastRowNum = cell.rowNum
      --io.write("\n" .. lastRowNum )
      --currentRow[#currentRow+1] = lastRowNum
    end


    v = cell.value
    --print("reading v", v)
    if v and type(v) == 'string' then
      v = v:trim()
      pos = SpreadsheetPosition(cell.position)
      --print('cell.position', cell.position, pos.tostring())
      if pos.col == 'N' or pos.col == 'O' or pos.col == 'P' then
        x = tonumber(v)
        if x then
          x = date((x-25569)*86400 )
          v = x:fmt("%Y-%m-%d")
        end


      end

    end
    if lastRowNum ~= cell.rowNum then
      --do job such as insert db or save as cvs, etc
      if currentRow[2] and  currentRow[2] ~= '' then
        --print("currentRow[2]",currentRow[2])
        f:write ( ch.toCSV(currentRow) )
        f:write("\n")
      else
        print("ignore row [col(2) is null]",cell.rowNum, currentRow[1])

      end


      currentRow = resetTable(currentRow) or {}
      lastRowNum = cell.rowNum
      --io.write("\n" .. lastRowNum .. ">")
      if encoding == '2' then

        v = ansicode.u82a(v)
      end

       currentRow[#currentRow+1] = v  --append

    else

      if encoding == '2' then
        v = ansicode.u82a(v)
      end
      currentRow[#currentRow+1] = v
    end

   return true
end


local row_counter = 0

M.do_import = function(components,iup)
     local file_path = components.text_location.value

    local start = date()
    --start:fmt("%Y-%m-%d %H:%M:%S")
    components.appendLog( os.date("%Y-%m-%d %H:%M:%S") .. " > 导入..." .. components.text_location.value )
    components.progressbar.value = 0

    encoding = components.encoding_list.value

    --print('selected encoding=' .. encoding)

    local ansi_str = ansicode.u82a(file_path)

    --[[ ]]
    f,err = io.open(ansi_str .. ".csv","w")
    if err then
      print("can not create csv file !",err)
      return
    end

    --"full": 完全缓冲；只有在缓存满或当你显式的对文件调用 flush（参见 io.flush） 时才真正做输出操作。
    f:setvbuf ("full" , 2^15) --32K


    --csvw = csv.writer(ansi_str .. ".csv",",")


    local workbook,err = Workbook(ansi_str)

    row_counter = 0

    --iup.SetIdle(import_idle_cb)


    local status, msg = workbook.sheet(1, {
        CellHandler = createCsv,
        RowHandler =
        function ( row )
          row_counter = row_counter + 1
          --print("row_counter",row_counter)
          if row.rowNum %1000 == 0 then
            --f:flush()
            --print(collectgarbage("count") )
            collectgarbage()

          end

          if row.rowNum %10 == 0 then
            components.progressbar.value = 100 * row.rowNum / row.dimension.maxRow --update progress
            components.progressbar.tip = math.floor(components.progressbar.value) .. '%'
            iup.LoopStep() --like yield

            --if cancelflag then break end
          end

          return true
        end
        ,
        SheetHandler = function ( sheet )
          print("sheet.dimension =" .. sheet.dimension.tostring())
          return true
        end
      },
      {"8:1000000"}

    )
  components.progressbar.value = 100
  components.progressbar.tip = "100%"

  f:close()
  workbook:close()

  local ed = date()

  local d = date.diff(ed, start)


  print("csv created:",file_path .. ".csv")
  components.appendLog("csv 文件创建成功:" .. file_path .. ".csv")
  components.appendLog("csv 文件编码:" .. components.encoding_list.valuestring)

  components.appendLog("文件行数: " .. row_counter - 8 .. " \t,耗时" .. string.format("%.2f", d:spanminutes()) .. "分") --start from 8

  print(collectgarbage("count") .. " KB used")

  collectgarbage('collect') -- performs a full garbage-collection cycle
  print(collectgarbage("count") .. " KB used after GC")

end



return M
