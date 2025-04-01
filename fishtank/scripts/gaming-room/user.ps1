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
        Add-LocalGroupMember -Group "Users" -Member $Username
        Add-LocalGroupMember -Group "Brukere" -Member $Username
        Write-Output "User '$Username' added to 'Users' group."

    } catch {
        Write-Error "Failed to create user '$Username': $_"
    }
}

# Prevent user from setting a password (by enforcing an empty password)
secedit /export /cfg C:\secpol.cfg
(Get-Content C:\secpol.cfg) -replace "PasswordComplexity = 1", "PasswordComplexity = 0" | Set-Content C:\secpol.cfg
(Get-Content C:\secpol.cfg) -replace "MinimumPasswordLength = \d+", "MinimumPasswordLength = 0" | Set-Content C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
Remove-Item C:\secpol.cfg

Write-Output "Password change restrictions applied."

# Define the source and destination of the wallpaper
$SourceWallpaper = "assets\gaming-room\wallpaper.jpg"
$DestinationWallpaper = "C:\ProgramData\wallpaper.jpg"

# Copy the wallpaper to the hidden ProgramData folder
Copy-Item -Path $SourceWallpaper -Destination $DestinationWallpaper -Force
Write-Output "Wallpaper copied to C:\ProgramData\wallpaper.jpg"

# Set the default wallpaper using the copied file
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $DestinationWallpaper
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
Write-Output "Default wallpaper set to C:\ProgramData\wallpaper.jpg"

# Prevent "Vaagen" from changing wallpaper and user icon
$RegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"

# Disable wallpaper change
Set-ItemProperty -Path $RegistryPath -Name "NoChangingWallpaper" -Value 1 -Type DWord

# Restrict user picture change
$RegPathIcon = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
If (!(Test-Path $RegPathIcon)) { New-Item -Path $RegPathIcon -Force }
Set-ItemProperty -Path $RegPathIcon -Name "UseDefaultTile" -Value 1 -Type DWord

Write-Output "Wallpaper and user icon change restrictions applied."
