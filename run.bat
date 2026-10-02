@echo off
setlocal EnableExtensions

set "root=%~dp0fishtank"
set "script=%root%\run.ps1"

if not exist "%script%" (
    echo Could not find "%script%".
    exit /b 1
)

pushd "%root%" || exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "Unblock-File -LiteralPath '%script%' -ErrorAction SilentlyContinue"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%" %*
set "exitCode=%ERRORLEVEL%"
popd

if not "%exitCode%"=="0" (
    echo Fishtank stopped with exit code %exitCode%.
)
pause
exit /b %exitCode%
