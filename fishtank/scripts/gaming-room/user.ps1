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
}

# Define the source and destination of the wallpaper
$SourceWallpaper = "assets\gaming-room\wallpaper.jpg"
$DestinationWallpaper = "C:\ProgramData\wallpaper.jpg"

# Copy the wallpaper to the hidden ProgramData folder
Copy-Item -Path $SourceWallpaper -Destination $DestinationWallpaper -Force
Write-Output "Wallpaper copied to C:\ProgramData\wallpaper.jpg"

$userSID = (Get-LocalUser -Name $Username).SID

# TODO: Set wallpaper for user on every login
# TODO: Set user icon on every login (standard user icon / disabled)
# TODO: Set the password to nothing (empty string) on every boot
