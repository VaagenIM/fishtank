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
$ScriptPath = "C:\ProgramData\FirstLoginConfig.ps1"
$ScriptContent = @"
# Get the SID of the user "$Username"
`$userSID = (Get-LocalUser -Name "$Username").SID

# Reset the password to empty, just for good measure
net user $Username ""
net user $Username /passwordreq:no

# Set the registry keys for disabling password change for the user
New-Item -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Force
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name DisableChangePassword -Value 1
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Force
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name DisableChangePassword -Value 1

# Set the wallpaper for the user by SID (directly modifying the registry)
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Control Panel\Desktop" -Name WallPaper -Value "$DestinationWallpaper"
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Control Panel\Desktop" -Name WallpaperStyle -Value 4  # Fill
Set-ItemProperty -Path "Registry::HKEY_USERS\`$userSID\Control Panel\Desktop" -Name TileWallpaper -Value 0

# Set the lock screen image (for users with appropriate policies) via SID (global setting)
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "$DestinationLockscreenWallpaper"

# Run UpdatePerUserSystemParameters as user Vaagen (via registry change)
Start-Sleep -Seconds 10
rundll32.exe user32.dll, UpdatePerUserSystemParameters, 0, True

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

Write-Output "Registry settings applied successfully. (User needs to log out and back in for some changes to take effect.)"
"@

# Write the script content to a file
Set-Content -Path $ScriptPath -Value $ScriptContent

# Add as a scheduled task to run silently
$TaskName = "ApplySettings_$Username"

# Delete the task if it already exists
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Define the action to run the script silently
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

# Set trigger to run at user login
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Define task principal (run with highest privileges)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType Password -RunLevel Highest

# Create the scheduled task
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Description "Applies settings for user '$Username' on login"

# Register the scheduled task
Register-ScheduledTask -TaskName $TaskName -InputObject $Task

Write-Output "Scheduled task '$TaskName' created successfully."
