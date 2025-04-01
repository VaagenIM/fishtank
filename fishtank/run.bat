@echo off
:: Check for admin rights
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~f0' -Verb RunAs"
    exit
)

:: Unblock the script
powershell -Command "Unblock-File -Path run.ps1"

:: Start an interactive PowerShell session with Unrestricted policy
powershell -NoExit -ExecutionPolicy Unrestricted -File run.ps1

echo Script execution completed.
pause