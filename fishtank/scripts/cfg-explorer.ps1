Write-Output "Configuring Explorer..."

# Get all user SIDs
$userSIDs = Get-ChildItem "Registry::HKEY_USERS" | Where-Object { $_.Name -notmatch "S-1-5-18" } | Select-Object -ExpandProperty Name

reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d "1" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideDrivesWithNoMedia /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d "1" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoUseStoreOpenWith /t REG_DWORD /d "1" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v NoNewAppAlert /t REG_DWORD /d "1" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HidePeopleBar /t REG_DWORD /d "1" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAMeetNow /t REG_DWORD /d "1" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v AllowOnlineTips /t REG_DWORD /d "0" /f

# Apply settings for each user
foreach ($userSID in $userSIDs) {
    Write-Output "Applying user-specific settings for user SID: $userSID"

    $userHive = "$userSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    # Shows hidden files in file explorer (per user)
    reg.exe ADD "$userHive" /v Hidden /t REG_DWORD /d "1" /f

    # Shows empty drives in file explorer (per user)
    reg.exe ADD "$userHive" /v HideDrivesWithNoMedia /t REG_DWORD /d "0" /f

    # Shows file extension in file explorer (per user)
    reg.exe ADD "$userHive" /v HideFileExt /t REG_DWORD /d "0" /f

    # Opens file explorer to this pc and not quick access (per user)
    reg.exe ADD "$userHive" /v LaunchTo /t REG_DWORD /d "1" /f
}

Write-Output "Explorer configuration complete!"
