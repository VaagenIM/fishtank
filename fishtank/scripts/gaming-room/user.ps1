# Ensure the user "Vaagen" exists without a password
$Username = "Vaagen"

# Check if the user exists
$user = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue

if ($user) {
    Write-Output "User '$Username' already exists. Skipping creation."
} else {
    Write-Output "User '$Username' does not exist. Creating now..."

    # Create the user with no password
    New-LocalUser -Name $Username -NoPassword -Description "Restricted User Account"
    Write-Output "User '$Username' created successfully."

    # Add to the 'Users' group (non-admin)
    $UsersGroup = Get-LocalGroup | Where-Object { $_.SID -eq "S-1-5-32-545" }
    Add-LocalGroupMember -Group $UsersGroup.Name -Member $Username
    net user $Username /passwordreq:no
    Write-Output "User '$Username' added to the '$($UsersGroup.Name)' group."
    Set-LocalUser -name "$Username" -Password ([securestring]::new())
}

# Define the source and destination of the wallpaper
$SourceWallpaper = "assets\gaming-room\wallpaper.jpg"
$DestinationWallpaper = "C:\ProgramData\wallpaper.jpg"

# Define the source and destination of the screensaver
$SourceLockscreenWallpaper = "assets\gaming-room\lockscreenwallpaper.jpg"
$DestinationLockscreenWallpaper = "C:\ProgramData\lockscreenwallpaper.jpg"

# Copy the wallpaper + LockscreenWallpaper to the hidden ProgramData folder
Copy-Item -Path $SourceWallpaper -Destination $DestinationWallpaper -Force
Copy-Item -Path $SourceLockscreenWallpaper -Destination $DestinationLockscreenWallpaper -Force

# Create a PowerShell script that will be executed on the first login to configure the user profile
$ScriptPath = "C:\ProgramData\UserConfig.ps1"
$ScriptContent = @"
# Get the SID of the user "$Username"
`$userSID = (Get-LocalUser -Name "$Username").SID.Value

# Reset the password to empty, just for good measure
Set-LocalUser -name "$Username" -Password ([securestring]::new())

# Set the wallpaper for the user by SID (directly modifying the registry)
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Control Panel\Desktop" -Name WallPaper -Value "$DestinationWallpaper"
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Control Panel\Desktop" -Name WallpaperStyle -Value 4  # Fill
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Control Panel\Desktop" -Name TileWallpaper -Value 0

# Set the lock screen image (for users with appropriate policies) via SID (global setting)
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "$DestinationLockscreenWallpaper"
New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Policies\Microsoft\Windows\Personalization" -Force
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "$DestinationLockscreenWallpaper"

# Prevent users from changing the wallpaper
New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" -Force
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" -Name NoChangingWallPaper -Value 1

# Prevent users from changing the lockscreen wallpaper
New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Force
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name NoChangingLockScreen -Value 1
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name NoChangingLockScreen -Value 1

# Prevent users from changing the profile picture
New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Force
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name NoChangingProfile -Value 1

# Prevent users from changing the screensaver
New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Force
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name NoDispScrSavPage -Value 1

# Prevent users from adding custom themes
New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Policies\Microsoft\Windows\Personalization" -Force
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Policies\Microsoft\Windows\Personalization" -Name NoChangingTheme -Value 1

# Disable the ability to change the lock screen slideshow settings (if applicable)
New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Policies\Microsoft\Windows\Personalization" -Force
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Policies\Microsoft\Windows\Personalization" -Name NoLockScreenSlideshow -Value 1

if (Test-Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Lenovo") {
    # Target Lenovo-specific registry policies if applicable
    # Lenovo may have additional registry paths such as those found in `HKEY_LOCAL_MACHINE\SOFTWARE\Lenovo\` or `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Lenovo`
    # Here, we can set some example Lenovo policies if they exist on the system, to block user changes:

    # Disable customization of wallpaper for Lenovo devices
    New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo" -Force
    Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo" -Name "NoChangingWallpaper" -Value 1

    # Prevent changes to lock screen settings for Lenovo devices
    New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo" -Force
    Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo" -Name "NoLockscreenCustomization" -Value 1

    # Prevent users from accessing Lenovo System Updates (example policy)
    New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo\SystemUpdate" -Force
    Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo\SystemUpdate" -Name "DisableUI" -Value 1

    # Disable Lenovo Vantage customizations for the user (if Lenovo Vantage app is present)
    New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo\Vantage" -Force
    Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo\Vantage" -Name "NoUserProfileCustomization" -Value 1

    # Disable the Lenovo quick launch bar or other Lenovo-specific toolbar settings
    New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo\QuickLaunch" -Force
    Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo\QuickLaunch" -Name "DisableToolbar" -Value 1

    # Disable Lenovo OEM-specific screen savers (if applicable)
    New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo\ScreenSaver" -Force
    Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Lenovo\ScreenSaver" -Name "DisableOEMScreensaver" -Value 1
}

# Apply the wallpaper / user settings
rundll32.exe user32.dll, UpdatePerUserSystemParameters, 0, True
Start-Sleep -Seconds 10
rundll32.exe user32.dll, UpdatePerUserSystemParameters, 0, True
"@

# Write the script content to a file
Set-Content -Path $ScriptPath -Value $ScriptContent

$TaskName = "ApplySettings_$Username"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $ScriptPath" -WorkingDirectory "C:\ProgramData"
$StartupTrigger = New-ScheduledTaskTrigger -AtStartup
$LogonTrigger = New-ScheduledTaskTrigger -AtLogon

# Correctly create a trigger that repeats every 30 minutes indefinitely
$RepetitionTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 30) `
    -RepetitionDuration ([TimeSpan]::MaxValue)

$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -StartWhenAvailable

# Clean up any existing tasks
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "$TaskName-Logon" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "$TaskName-Repeat" -Confirm:$false -ErrorAction SilentlyContinue

# Register the tasks
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $StartupTrigger -Principal $Principal -Settings $Settings
Register-ScheduledTask -TaskName "$TaskName-Logon" -Action $Action -Trigger $LogonTrigger -Principal $Principal -Settings $Settings
Register-ScheduledTask -TaskName "$TaskName-Repeat" -Action $Action -Trigger $RepetitionTrigger -Principal $Principal -Settings $Settings

Write-Output "Scheduled task '$TaskName' created successfully."