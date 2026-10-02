@echo off
setlocal EnableExtensions DisableDelayedExpansion

::
:: Gaming room installer
::

:: Prompt for sunshine username
set /p SUNUSER=Enter a username for the sunshine account:

:: Prompt for password
set /p USERPW=Enter a password for the user and sunshine account:

:: Define paths
set "zipPath=%USERPROFILE%\Desktop\fishtank.zip"
set "extractPath=%USERPROFILE%\Desktop\fishtank-main"

if exist "%extractPath%" (
    echo Removing the previous Fishtank deployment...
    rmdir /s /q "%extractPath%"
    if exist "%extractPath%" (
        echo Could not remove "%extractPath%".
        exit /b 1
    )
)

echo Downloading Fishtank...
curl.exe --fail --location --silent --show-error --output "%zipPath%" "https://github.com/VaagenIM/fishtank/archive/refs/heads/main.zip"
if errorlevel 1 (
    echo Download failed.
    exit /b 1
)

echo Extracting Fishtank...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Expand-Archive -LiteralPath '%zipPath%' -DestinationPath '%USERPROFILE%\Desktop' -Force"
if errorlevel 1 (
    echo Extraction failed.
    del /q "%zipPath%" 2>nul
    exit /b 1
)

del /q "%zipPath%"
if not exist "%extractPath%\run.bat" (
    echo The downloaded archive did not contain "%extractPath%\run.bat".
    exit /b 1
)

echo Running run.bat...
set "FISHTANK_USERPW=%USERPW%"
set "FISHTANK_SUNSHINE_USER=%SUNUSER%"
set "FISHTANK_SUNSHINE_PASSWORD=%USERPW%"
start "" "%ComSpec%" /d /k call "%extractPath%\run.bat" --all --no-user

echo Deployment completed.
exit /b 0
