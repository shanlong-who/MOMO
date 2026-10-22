@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "MIMI_ACTION=%~1"
if not defined MIMI_ACTION set "MIMI_ACTION=start"
for %%I in ("%~dp0..") do set "MIMI_APP_DIR=%%~fI"
set "MIMI_RUNNER="

rem Optional: point MIMI_RSCRIPT at a particular Rscript.exe.
if defined MIMI_RSCRIPT goto custom_r

for /f "delims=" %%R in ('where Rscript.exe 2^>nul') do if not defined MIMI_RUNNER set "MIMI_RUNNER=%%R"
if defined MIMI_RUNNER goto run_mimi

rem Read standard R installer registry keys. No registry values are changed.
for %%K in ("HKCU\Software\R-core\R" "HKCU\Software\R-core\R64" "HKLM\Software\R-core\R" "HKLM\Software\R-core\R64" "HKLM\Software\WOW6432Node\R-core\R") do (
  for /f "tokens=2,*" %%A in ('reg query "%%~K" /v InstallPath 2^>nul') do (
    if /i "%%A"=="REG_SZ" if not defined MIMI_RUNNER call :try_home "%%B"
  )
)
if defined MIMI_RUNNER goto run_mimi

rem Fall back to common install locations, most recently modified first.
for /f "delims=" %%D in ('dir /b /ad /o-d "%LOCALAPPDATA%\Programs\R\R-*" 2^>nul') do if not defined MIMI_RUNNER call :try_home "%LOCALAPPDATA%\Programs\R\%%D"
for /f "delims=" %%D in ('dir /b /ad /o-d "%ProgramFiles%\R\R-*" 2^>nul') do if not defined MIMI_RUNNER call :try_home "%ProgramFiles%\R\%%D"
if defined MIMI_RUNNER goto run_mimi

echo Rscript.exe was not found.
echo Install R for Windows, or start run_mimi.R from your own R session.
echo For a custom installation, set MIMI_RSCRIPT to your Rscript.exe path.
exit /b 1

:try_home
if exist "%~1\bin\Rscript.exe" set "MIMI_RUNNER=%~1\bin\Rscript.exe"
if not defined MIMI_RUNNER if exist "%~1\bin\x64\Rscript.exe" set "MIMI_RUNNER=%~1\bin\x64\Rscript.exe"
exit /b 0

:custom_r
if not exist "%MIMI_RSCRIPT%" goto invalid_custom_r
set "MIMI_RUNNER=%MIMI_RSCRIPT%"
goto run_mimi

:invalid_custom_r
echo MIMI_RSCRIPT points to a file that does not exist.
exit /b 1

:run_mimi
if /i "%MIMI_ACTION%"=="start" goto start_mimi
"%MIMI_RUNNER%" --vanilla "%MIMI_APP_DIR%\scripts\launch.R" "%MIMI_ACTION%"
exit /b %ERRORLEVEL%

:start_mimi
powershell.exe -NoProfile -Command "$mimiHelper = Join-Path $env:MIMI_APP_DIR 'scripts\launch.R'; $mimiPaths = @(& $env:MIMI_RUNNER --vanilla $mimiHelper paths); if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; if ($mimiPaths.Count -ne 3) { Write-Error 'MIMI could not determine its local data directories.'; exit 1 }; $mimiLog = Join-Path $mimiPaths[1] ('startup-' + [guid]::NewGuid().ToString('N')); $mimiArguments = @('--vanilla', ([char]34 + (Join-Path $env:MIMI_APP_DIR 'run_mimi.R') + [char]34)); try { Start-Process -FilePath $env:MIMI_RUNNER -ArgumentList $mimiArguments -WindowStyle Hidden -RedirectStandardOutput ($mimiLog + '.out.log') -RedirectStandardError ($mimiLog + '.err.log') -ErrorAction Stop } catch { Write-Error $_; exit 1 }; & $env:MIMI_RUNNER --vanilla $mimiHelper await; exit $LASTEXITCODE"
exit /b %ERRORLEVEL%
