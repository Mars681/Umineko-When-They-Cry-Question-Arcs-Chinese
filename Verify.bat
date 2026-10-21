@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Patch.ps1" -Mode Verify %*
set "patchExit=%ERRORLEVEL%"
pause
exit /b %patchExit%
