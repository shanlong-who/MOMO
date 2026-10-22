@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0scripts\launch.cmd" start
if errorlevel 1 (
  echo.
  echo MOMO could not start. Read the message above or see README.md.
  pause
  exit /b 1
)
