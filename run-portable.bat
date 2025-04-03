@echo off
:: Define the URL of the source code and the destination file
set "url=https://github.com/VaagenIM/fishtank/archive/refs/heads/main.zip"
set "dest=%USERPROFILE%\Desktop\fishtank.zip"
set "extractDir=%USERPROFILE%\Desktop\fishtank"

:: Download the ZIP file to the Desktop using curl (faster and more reliable)
echo Downloading fishtank.zip...
curl -L -o "%dest%" "%url%"

:: Extract the ZIP file to the Desktop
echo Extracting the ZIP file...
powershell -Command "Expand-Archive -Path %dest% -DestinationPath %USERPROFILE%\Desktop"

:: Remove the zip file
echo Removing the ZIP file...
del "%dest%"

:: Change to the extracted directory
cd /d "%extractDir%\fishtank-main"

:: Run the run.bat file
echo Running run.bat...
call run.bat

:: Clean up the downloaded ZIP file
del "%dest%"

:: End
echo Deployment completed.
