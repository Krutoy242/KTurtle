@echo off
 
set "Source=.\src"
 
@>"KrutoyTurtle.lua" (
for /f "delims=" %%i in ('dir/a-d/b/s "%Source%"') do @(
 if "%%~xi"==".lua" (
  echo.
  echo.
  echo.
  echo.
  echo.
  echo.-- %%~ni.lua
  type "%%i"
  echo.
 )
 )
)