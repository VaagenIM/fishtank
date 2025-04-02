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

# Copy the wallpaper to the hidden ProgramData folder
Copy-Item -Path $SourceWallpaper -Destination $DestinationWallpaper -Force
Write-Output "Wallpaper copied to C:\ProgramData\wallpaper.jpg"

# Skip windows onboarding
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "SkipMachineOOBE" -Value 1
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "SkipUserOOBE" -Value 1

$ScriptPath = "C:\ProgramData\ApplySettings_$Username.ps1"
$ScriptContent = @"
# Get the SID of the user "$Username"
`$userSID = (Get-LocalUser -Name "$Username").SID

# Prevent user from being able to change password
Set-ItemProperty -Path "Registry::HKEY_USERS\$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name DisableChangePassword -Value 1

# Set the wallpaper for the user by SID (directly modifying the registry)
Set-ItemProperty -Path "Registry::HKEY_USERS\$userSID\Control Panel\Desktop" -Name WallPaper -Value "C:\ProgramData\wallpaper.jpg"

# Set the wallpaper style to 'Fill' for the user by SID (direct registry modification)
Set-ItemProperty -Path "Registry::HKEY_USERS\$userSID\Control Panel\Desktop" -Name WallpaperStyle -Value 10
Set-ItemProperty -Path "Registry::HKEY_USERS\$userSID\Control Panel\Desktop" -Name TileWallpaper -Value 0

# Set the lock screen image (for users with appropriate policies) via SID (global setting)
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "C:\ProgramData\wallpaper.jpg"

# Run UpdatePerUserSystemParameters as user Vaagen (via registry change)
# This method works as the changes are immediately reflected without needing to invoke a separate process.
Start-Sleep -Seconds 10
rundll32.exe user32.dll, UpdatePerUserSystemParameters, 0, True
"@

# Write the script content to a file
Set-Content -Path $ScriptPath -Value $ScriptContent

# Add as a scheduled task to run silently
$TaskName = "ApplySettings_$Username"

# Delete the task if it already exists
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Define the action to run PowerShell script silently
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$ScriptPath`""

# Set trigger to run at user login
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Define task principal (run with highest privileges)
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the scheduled task
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Description "Applies settings for user '$Username' on login"

# Register the scheduled task
Register-ScheduledTask -TaskName $TaskName -InputObject $Task

Write-Output "Scheduled task '$TaskName' created successfully."
