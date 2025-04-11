@echo off
:: Set CWD to the script's directory
cd /d "%~dp0/fishtank"

:: Check for admin rights
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit
)

:: Prompt for password
set /p USERPW=Enter a password for the user and sunshine account:

:: Prompt for sunshine username
set /p SUNUSER=Enter a username for the sunshine account:

:: Unblock the script
powershell -Command "Unblock-File -Path run.ps1"

:: Run the PowerShell script with --all and credentials
powershell -ExecutionPolicy Unrestricted -File run.ps1 ^
  --all --userpw="%USERPW%" --sunshine-creds="%SUNUSER%:%USERPW%"

echo Script execution completed.
pause
