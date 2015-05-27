@echo off

rem copy must use \  %~dp0
set CWD=%cd%\
set DEV=%CWD%..\desktop53
set RELEASE=%CWD%..\release

set PATH=%DEV%;%PATH%

rd /s /q  %RELEASE%\
md %RELEASE%
md %RELEASE%\lua 
md %RELEASE%\lua\actions 
 

rem can not copy subdir£¡
copy  %DEV% %RELEASE%\
copy %DEV%\lua\*.lua  %RELEASE%\lua\	
copy %DEV%\lua\actions\*.lua  %RELEASE%\lua\actions\	

rem copy %DEV%\odbc\*.*  %RELEASE%\odbc\	

rem copy %DEV%\cURL\*.*  %RELEASE%\cURL\	


del %RELEASE%\*.exe
del %RELEASE%\*.bat
del %RELEASE%\m.lua

glue srlua_icon53.exe  bootstrap.lua  %RELEASE%/main.exe
