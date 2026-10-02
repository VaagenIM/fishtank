$ErrorActionPreference = "Stop"

$username = "Vaagen"
$user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
if (-not $user) {
    New-LocalUser -Name $username -NoPassword -Description "Restricted User Account" | Out-Null
    $usersGroup = Get-LocalGroup | Where-Object SID -eq "S-1-5-32-545"
    Add-LocalGroupMember -Group $usersGroup.Name -Member $username
}

$assetRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$wallpaper = Join-Path $assetRoot "assets\gaming-room\wallpaper.jpg"
$lockscreen = Join-Path $assetRoot "assets\gaming-room\lockscreenwallpaper.jpg"
$programData = [Environment]::GetFolderPath("CommonApplicationData")
$wallpaperDestination = Join-Path $programData "wallpaper.jpg"
$lockscreenDestination = Join-Path $programData "lockscreenwallpaper.jpg"
Copy-Item -LiteralPath $wallpaper -Destination $wallpaperDestination -Force
Copy-Item -LiteralPath $lockscreen -Destination $lockscreenDestination -Force

$scriptPath = Join-Path $programData "UserConfig.ps1"
$scriptContent = @"
`$user = Get-LocalUser -Name '$username'
`$sid = `$user.SID.Value
`$hive = "Registry::HKEY_USERS\`$sid"
Set-LocalUser -Name '$username' -Password `$null
New-Item -Path "`$hive\Control Panel\Desktop" -Force | Out-Null
Set-ItemProperty -Path "`$hive\Control Panel\Desktop" -Name WallPaper -Value '$wallpaperDestination'
Set-ItemProperty -Path "`$hive\Control Panel\Desktop" -Name WallpaperStyle -Value 4
Set-ItemProperty -Path "`$hive\Control Panel\Desktop" -Name TileWallpaper -Value 0

`$personalization = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization"
New-Item -Path `$personalization -Force | Out-Null
Set-ItemProperty -Path `$personalization -Name LockScreenImage -Value '$lockscreenDestination'
Set-ItemProperty -Path `$personalization -Name NoChangingLockScreen -Value 1

`$policies = "`$hive\Software\Microsoft\Windows\CurrentVersion\Policies"
New-Item -Path "`$policies\ActiveDesktop" -Force | Out-Null
Set-ItemProperty -Path "`$policies\ActiveDesktop" -Name NoChangingWallPaper -Value 1
New-Item -Path "`$policies\System" -Force | Out-Null
Set-ItemProperty -Path "`$policies\System" -Name NoChangingLockScreen -Value 1
Set-ItemProperty -Path "`$policies\System" -Name NoChangingProfile -Value 1
Set-ItemProperty -Path "`$policies\System" -Name NoDispScrSavPage -Value 1

rundll32.exe user32.dll,UpdatePerUserSystemParameters
"@
Set-Content -LiteralPath $scriptPath -Value $scriptContent -Encoding UTF8 -Force

$taskName = "ApplySettings_$username"
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" `
    -WorkingDirectory $programData
$triggers = @(
    (New-ScheduledTaskTrigger -AtStartup),
    (New-ScheduledTaskTrigger -AtLogOn)
)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers `
    -Principal $principal -Settings $settings -Force | Out-Null
Write-Output "Scheduled task '$taskName' created successfully."
