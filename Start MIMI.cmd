@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0MIMI\Start MIMI.cmd"
exit /b %ERRORLEVEL%
