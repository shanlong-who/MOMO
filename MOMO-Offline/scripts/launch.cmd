@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "MOMO_ACTION=%~1"
if not defined MOMO_ACTION set "MOMO_ACTION=start"
for %%I in ("%~dp0..") do set "MOMO_APP_DIR=%%~fI"
set "MOMO_RUNNER="

rem Optional: point MOMO_RSCRIPT at a particular Rscript.exe.
if defined MOMO_RSCRIPT goto custom_r

for /f "delims=" %%R in ('where Rscript.exe 2^>nul') do if not defined MOMO_RUNNER set "MOMO_RUNNER=%%R"
if defined MOMO_RUNNER goto run_momo

rem Read standard R installer registry keys. No registry values are changed.
for %%K in ("HKCU\Software\R-core\R" "HKCU\Software\R-core\R64" "HKLM\Software\R-core\R" "HKLM\Software\R-core\R64" "HKLM\Software\WOW6432Node\R-core\R") do (
  for /f "tokens=2,*" %%A in ('reg query "%%~K" /v InstallPath /s 2^>nul') do (
    if /i "%%A"=="REG_SZ" if not defined MOMO_RUNNER call :try_home "%%B"
  )
)
if defined MOMO_RUNNER goto run_momo

rem Fall back to common install locations, most recently modified first.
for /f "delims=" %%D in ('dir /b /ad /o-d "%LOCALAPPDATA%\Programs\R\R-*" 2^>nul') do if not defined MOMO_RUNNER call :try_home "%LOCALAPPDATA%\Programs\R\%%D"
for /f "delims=" %%D in ('dir /b /ad /o-d "%ProgramFiles%\R\R-*" 2^>nul') do if not defined MOMO_RUNNER call :try_home "%ProgramFiles%\R\%%D"
if defined MOMO_RUNNER goto run_momo

echo Rscript.exe was not found.
echo Install R for Windows, or start run_momo.R from your own R session.
echo For a custom installation, set MOMO_RSCRIPT to your Rscript.exe path.
exit /b 1

:try_home
if exist "%~1\bin\Rscript.exe" set "MOMO_RUNNER=%~1\bin\Rscript.exe"
if not defined MOMO_RUNNER if exist "%~1\bin\x64\Rscript.exe" set "MOMO_RUNNER=%~1\bin\x64\Rscript.exe"
exit /b 0

:custom_r
if not exist "%MOMO_RSCRIPT%" goto invalid_custom_r
set "MOMO_RUNNER=%MOMO_RSCRIPT%"
goto run_momo

:invalid_custom_r
echo MOMO_RSCRIPT points to a file that does not exist.
exit /b 1

:run_momo
if /i "%MOMO_ACTION%"=="start" goto start_momo
"%MOMO_RUNNER%" --vanilla "%MOMO_APP_DIR%\scripts\launch.R" "%MOMO_ACTION%"
exit /b %ERRORLEVEL%

:start_momo
powershell.exe -NoProfile -Command "$momoHelper = Join-Path $env:MOMO_APP_DIR 'scripts\launch.R'; $momoPaths = @(& $env:MOMO_RUNNER --vanilla $momoHelper paths); if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; if ($momoPaths.Count -ne 3) { Write-Error 'MOMO could not determine its local data directories.'; exit 1 }; $momoLog = Join-Path $momoPaths[1] ('startup-' + [guid]::NewGuid().ToString('N')); $momoArguments = @('--vanilla', ([char]34 + (Join-Path $env:MOMO_APP_DIR 'run_momo.R') + [char]34)); try { Start-Process -FilePath $env:MOMO_RUNNER -ArgumentList $momoArguments -WindowStyle Hidden -RedirectStandardOutput ($momoLog + '.out.log') -RedirectStandardError ($momoLog + '.err.log') -ErrorAction Stop } catch { Write-Error $_; exit 1 }; & $env:MOMO_RUNNER --vanilla $momoHelper await; exit $LASTEXITCODE"
exit /b %ERRORLEVEL%
