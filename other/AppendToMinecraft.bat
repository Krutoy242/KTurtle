@echo off
 
set "Source=.\src"
 
@>"C:\Users\Krutoy\AppData\Roaming\.CCLauncher\InformationTech[1.7.10]\saves\Computers\computer\5\KrutoyTurtle.lua" (
for /f "delims=" %%i in ('dir/a-d/b/s "%Source%"') do @(
 if "%%~xi"==".lua" (
  echo.
  echo.--%%~ni.lua
  echo.
  type "%%i"
  echo.
 )
 )
)