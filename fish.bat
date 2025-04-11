@echo off

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

:: Delete old fishtank-main if it exists
if exist "%extractPath%" (
    echo Deleting existing folder: %extractPath%
    rmdir /s /q "%extractPath%"
)

:: Download the ZIP file
echo Downloading fishtank.zip...
curl -L -o "%zipPath%" "https://github.com/VaagenIM/fishtank/archive/refs/heads/main.zip"

:: Extract the ZIP file to the Desktop
echo Extracting the ZIP file...
powershell -Command "Expand-Archive -Path '%zipPath%' -DestinationPath '%USERPROFILE%\Desktop'"

:: Remove the zip file
echo Cleaning up...
del "%zipPath%"

:: Launch run.bat with args
echo Running run.bat...
start "" cmd /k "%extractPath%\run.bat" --all --userpw=%USERPW% --sunshine-creds=%SUNUSER%:%USERPW%

:: End
echo Deployment completed.
exit
