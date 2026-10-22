@echo off
setlocal EnableExtensions DisableDelayedExpansion
for %%I in ("%~dp0..") do set "PET_ROOT=%%~fI"
set "PET_ACTION=%~1"
if not defined PET_ACTION set "PET_ACTION=start"
set "R_HOME=%PET_ROOT%\runtime\R"
set "PET_RUNNER=%R_HOME%\bin\x64\Rscript.exe"
if not exist "%PET_RUNNER%" (
  echo The bundled R runtime is missing. Extract the entire portable ZIP before starting @PET@.
  exit /b 1
)
set "R_LIBS=%R_HOME%\library"
set "R_LIBS_USER=%R_HOME%\library"
set "R_LIBS_SITE=%R_HOME%\library"
set "R_DEFAULT_PACKAGES=utils,grDevices,graphics,stats,methods"
set "TCL_LIBRARY=%R_HOME%\Tcl\lib\tcl8.6"
set "TK_LIBRARY=%R_HOME%\Tcl\lib\tk8.6"
set "TCLLIBPATH="
set "LC_ALL="
set "LC_COLLATE="
set "LC_CTYPE="
set "LC_MONETARY="
set "LC_TIME="
set "LANG="
set "LANGUAGE=en"
if /i "%PET_ACTION%"=="start" goto start_pet
"%PET_RUNNER%" --vanilla "%PET_ROOT%\scripts\portable.R" "%PET_ACTION%"
exit /b %ERRORLEVEL%

:start_pet
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "$petHelper = Join-Path $env:PET_ROOT 'scripts\portable.R'; $petPaths = @(& $env:PET_RUNNER --vanilla $petHelper paths); if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; if ($petPaths.Count -ne 3) { Write-Error 'Could not determine local settings and log directories.'; exit 1 }; $petLog = Join-Path $petPaths[1] ('startup-' + [guid]::NewGuid().ToString('N')); $petArguments = @('--vanilla', ([char]34 + $petHelper + [char]34), 'run'); try { Start-Process -FilePath $env:PET_RUNNER -ArgumentList $petArguments -WindowStyle Hidden -WorkingDirectory $env:PET_ROOT -RedirectStandardOutput ($petLog + '.out.log') -RedirectStandardError ($petLog + '.err.log') -ErrorAction Stop } catch { Write-Error $_; exit 1 }; & $env:PET_RUNNER --vanilla $petHelper await; $petStatus = $LASTEXITCODE; if ($petStatus -ne 0) { if (Test-Path -LiteralPath ($petLog + '.err.log')) { Get-Content -LiteralPath ($petLog + '.err.log') }; Write-Host ('Logs: ' + $petPaths[1]) }; exit $petStatus"
exit /b %ERRORLEVEL%
