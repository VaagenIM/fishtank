@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "zipPath=%USERPROFILE%\Desktop\fishtank.zip"
set "extractPath=%USERPROFILE%\Desktop\fishtank-main"
set "downloadUrl=https://github.com/VaagenIM/fishtank/archive/refs/heads/main.zip"

if not exist "%SystemRoot%\System32\curl.exe" (
    echo curl.exe is required to download Fishtank.
    exit /b 1
)

if exist "%extractPath%" (
    echo Removing the previous Fishtank deployment...
    rmdir /s /q "%extractPath%"
    if exist "%extractPath%" (
        echo Could not remove "%extractPath%".
        exit /b 1
    )
)

echo Downloading Fishtank...
curl.exe --fail --location --silent --show-error --output "%zipPath%" "%downloadUrl%"
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

echo Starting Fishtank...
start "" "%ComSpec%" /d /k call "%extractPath%\run.bat"
exit /b 0