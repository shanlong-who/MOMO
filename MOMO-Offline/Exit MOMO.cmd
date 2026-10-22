@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0scripts\launch.cmd" stop
if errorlevel 1 (
  echo.
  echo MOMO could not be closed. You can also right-click the cat and choose Exit MOMO.
  pause
  exit /b 1
)
