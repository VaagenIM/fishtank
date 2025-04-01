Write-Output "Configuring Explorer..."

# Shows hidden files in file explorer
reg.exe ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d "1" /f

# Shows empty drives in file explorer
reg.exe ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideDrivesWithNoMedia /t REG_DWORD /d "0" /f

# Shows file extension in file explorer
reg.exe ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d "0" /f

# Opens file explorer to this pc and not quick access
reg.exe ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d "1" /f

# Remove "Search the Store" from the right-click context menu
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoUseStoreOpenWith /t REG_DWORD /d "1" /f

# Remove "New app installed" notification
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoNewAppAlert /t REG_DWORD /d "1" /f

# Remove "People" from the taskbar
reg.exe ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HidePeopleBar /t REG_DWORD /d "1" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HidePeopleBar /t REG_DWORD /d "1" /f

# Disable search box on taskbar
reg.exe ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d "0" /f

# Disable Task View button on taskbar
reg.exe ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d "0" /f

# Disable Meet Now icon in notification area
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAMeetNow /t REG_DWORD /d "1" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v AllowOnlineTips /t REG_DWORD /d "0" /f