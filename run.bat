@echo off

:: Set CWD to the script's directory
cd /d "%~dp0/fishtank"

:: Check for admin rights
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requesting administrative privileges...
    set args=%*
    if defined args (
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '%args%'"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
            "Start-Process -FilePath '%~f0' -Verb RunAs"
    )
    exit
)

:: Unblock the script
powershell -Command "Unblock-File -Path run.ps1"

:: Run the PowerShell script with passed arguments
powershell -ExecutionPolicy Unrestricted -File run.ps1 %*

echo Script execution completed.
pause
