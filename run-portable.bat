@echo off
:: Define the URL of the source code and the destination file
set "url=https://github.com/VaagenIM/fishtank/archive/refs/heads/main.zip"
set "dest=%USERPROFILE%\Desktop\fishtank.zip"

:: Download the ZIP file to the Desktop using curl (faster and more reliable)
echo Downloading fishtank.zip...
curl -L -o "%dest%" "%url%"

:: Extract the ZIP file to the Desktop
echo Extracting the ZIP file...
powershell -Command "Expand-Archive -Path %dest% -DestinationPath %USERPROFILE%\Desktop"

:: Remove the zip file
echo Removing the ZIP file...
del "%dest%"

:: Run the run.bat file (on a new window, since we are closing this one)
echo Running run.bat...
start cmd /k "%USERPROFILE%\Desktop\fishtank-main\run.bat"

:: Clean up the downloaded ZIP file
del "%dest%"

:: End
echo Deployment completed.
