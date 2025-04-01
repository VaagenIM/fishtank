# Ensure the user "Vaagen" exists without a password
$Username = "Vaagen"

# Check if the user already exists
$user = Get-LocalUser -Name $Username -ErrorAction SilentlyContinue

if ($user) {
    Write-Output "User '$Username' already exists. Skipping creation."
} else {
    Write-Output "User '$Username' does not exist. Proceeding with creation."

    # Create the user with no password
    try {
        New-LocalUser -Name $Username -NoPassword -Description "Restricted User Account"
        Write-Output "User '$Username' created successfully."

        # Add to the 'Users' group (non-admin)
        $UsersGroup = Get-LocalGroup | Where-Object { $_.SID -eq "S-1-5-32-545" }
        Add-LocalGroupMember -Group $UsersGroup.Name -Member $Username
        Write-Output "User '$Username' added to 'Users' group."

        # Disable password requirement ONLY for 'Vaagen' (Not System-Wide)
        net user $Username /passwordreq:no
        Write-Output "Password requirement disabled for '$Username' only."

    } catch {
        Write-Error "Failed to create user '$Username': $_"
    }
}

# Ensure the user profile exists before applying registry changes
$UserProfilePath = "C:\Users\$Username"
if (!(Test-Path $UserProfilePath)) {
    Write-Output "User profile for '$Username' does not exist yet. Some registry settings may not apply until first login."
}

# Define the source and destination of the wallpaper
$SourceWallpaper = "assets\gaming-room\wallpaper.jpg"
$DestinationWallpaper = "C:\ProgramData\wallpaper.jpg"

# Copy the wallpaper to the hidden ProgramData folder
Copy-Item -Path $SourceWallpaper -Destination $DestinationWallpaper -Force
Write-Output "Wallpaper copied to C:\ProgramData\wallpaper.jpg"

# Get the SID of the newly created user "Vaagen"
$userSID = (Get-LocalUser -Name $Username).SID

# Apply wallpaper through User Registry (Ensuring the key exists)
$RegistryPathUser = "HKU:\$userSID\Control Panel\Desktop"

If (Test-Path $RegistryPathUser) {
    Set-ItemProperty -Path $RegistryPathUser -Name Wallpaper -Value $DestinationWallpaper
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
    Write-Output "Default wallpaper set for '$Username' at $DestinationWallpaper"
} else {
    Write-Output "User registry not loaded. Wallpaper will apply after first login."
}

# Prevent the "Vaagen" user from changing the wallpaper
$RegistryPathUserPolicy = "HKU:\$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\System"

If (Test-Path $RegistryPathUserPolicy) {
    Set-ItemProperty -Path $RegistryPathUserPolicy -Name "NoChangingWallpaper" -Value 1 -Type DWord
} else {
    Write-Output "Policy registry path not found. Restriction will apply after first login."
}

# Restrict user picture change
$RegPathIconUser = "HKU:\$userSID\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
If (!(Test-Path $RegPathIconUser)) { New-Item -Path $RegPathIconUser -Force }
Set-ItemProperty -Path $RegPathIconUser -Name "UseDefaultTile" -Value 1 -Type DWord

Write-Output "Wallpaper and user icon change restrictions applied to '$Username'."

# Optional: Force wallpaper refresh after login using a Scheduled Task
$TaskName = "ApplyWallpaperFor$Username"
$TaskAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters"
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn -User $Username
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId $Username -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Principal $TaskPrincipal -Force
Write-Output "Scheduled task created to ensure wallpaper applies on first login."
