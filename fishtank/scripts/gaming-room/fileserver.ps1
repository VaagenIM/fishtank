$ScriptContent = @"
# Map network drives silently
`$Drives = @(
    @{Letter="T"; Path="\\\\10.5.0.5\\Transfer"; User="guest"; Password="" }
    @{Letter="R"; Path="\\\\10.5.0.5\\Ressurser"; User="guest"; Password="" }
    @{Letter="S"; Path="\\\\10.5.0.5\\Spill"; User="guest"; Password="" }
)

foreach (`$Drive in `$Drives) {
    if (Test-Path "`$(`$Drive.Letter):\") {
        # Already mapped
    } else {
        net use "`$(`$Drive.Letter):" "`$(`$Drive.Path)" /user:"`$(`$Drive.User)" "`$(`$Drive.Password)" /persistent:yes > `$null 2>&1
    }
}
"@

# Save script
$ScriptPath = "C:\ProgramData\map_drives.ps1"
Set-Content -Path $ScriptPath -Value $ScriptContent -Force

# Create a hidden scheduled task to run at user login
$TaskName = "MapDrives"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$UsersGroup = Get-LocalGroup | Where-Object { $_.SID -eq "S-1-5-32-545" }
$Principal = New-ScheduledTaskPrincipal -GroupId $UsersGroup.Name -LogonType InteractiveToken
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -Hidden

# Remove if exists
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Register new one
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings

Write-Output "Silent login task '$TaskName' created successfully."
