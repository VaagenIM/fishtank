@echo off

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

:: Launch run.bat without any CLI arguments (user will be prompted)
echo Running run.bat...
start "" cmd /k "%extractPath%\run.bat"

echo Deployment completed.
exit