local lfs = require"lfs"

print(_VERSION)
print(os.getenv("OS") .. " " .. os.getenv("PROCESSOR_ARCHITECTURE") .. " CPUx" .. os.getenv("NUMBER_OF_PROCESSORS"))


--_ENV
_HOME = lfs.currentdir();
print("APP_HOME=", _HOME)

require "config"
require "lua.main"

main()