@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0scripts\launch.cmd" stop
if errorlevel 1 (
  echo.
  echo MIMI could not be closed. You can also right-click the cat and choose Exit MIMI.
  pause
  exit /b 1
)
