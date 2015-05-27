print(_VERSION)
print(os.getenv("OS") .. " " .. os.getenv("PROCESSOR_ARCHITECTURE") .. " CPUx" .. os.getenv("NUMBER_OF_PROCESSORS"))


local lfs = require"lfs"

--_ENV
_HOME = lfs.currentdir();
print("APP_HOME=", _HOME)
print("Starting Time: ", os.time(), os.date())

require "config"

require "lua.main"


--[[
print("BEGIN testing sqlite3...")
local sqlite3 = require("lsqlite3")
local db = sqlite3.open("db/assets.db")
assert( db:exec[-[
          Drop TABLE IF EXISTS test;
          CREATE TABLE test(n Integer, name varchar(100));
        ]-] )

local insert_stmt = assert( db:prepare("INSERT INTO test VALUES (?, ?)") )

local function insert(...)
  print(...)
  assert(insert_stmt:bind_values(...))
  insert_stmt:step()
  insert_stmt:reset()
end
insert(1, "Hello World")
insert(2, "This is a test")
print("changes or error:",  db:changes(), db:errcode())

 for a in db:nrows('SELECT * FROM test') do
    print(a.n, a.name)
 end

db:close()
]]


print("END testing")

main()
