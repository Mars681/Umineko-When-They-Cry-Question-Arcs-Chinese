@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Patch.ps1" -Mode Install %*
set "patchExit=%ERRORLEVEL%"
pause
exit /b %patchExit%
