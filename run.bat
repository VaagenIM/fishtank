@echo off

:: Set CWD to the script's directory
cd /d "%~dp0/fishtank"

:: Check for admin rights
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^ "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit
)

:: Unblock the script
powershell -Command "Unblock-File -Path run.ps1"

:: Start an interactive PowerShell session with Unrestricted policy
powershell -NoExit -ExecutionPolicy Unrestricted -File run.ps1

echo Script execution completed.
pause