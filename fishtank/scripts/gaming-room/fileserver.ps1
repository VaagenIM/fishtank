$ScriptContent = @"
# Define network drive mappings
`$Drives = @(
    @{Letter="T"; Path="\\10.5.0.5\Transfer"; User="guest"; Password="" }
    @{Letter="R"; Path="\\10.5.0.5\Ressurser"; User="guest"; Password="" }
    @{Letter="S"; Path="\\10.5.0.5\Spill"; User="guest"; Password="" }
)

# Iterate through each drive and map it
foreach (`$Drive in `$Drives) {
    # Remove existing drive mapping if present
    if (Test-Path "`$(`$Drive.Letter):\") {
        Write-Output "Drive `$(`$Drive.Letter): already mapped. Skipping..."
    } else {
        Write-Output "Mapping `$(`$Drive.Letter): to `$(`$Drive.Path)..."
        net use "`$(`$Drive.Letter):" "`$(`$Drive.Path)" /user:"`$(`$Drive.User)" "`$(`$Drive.Password)" /persistent:yes
    }
}

Write-Output "All drives mapped successfully."
"@

# Write the script content to a file
$ScriptPath = "C:\ProgramData\map_drives.ps1"
Set-Content -Path $ScriptPath -Value $ScriptContent

# Create a scheduled task to map network drives at user login
$TaskName = "MapDrives"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $ScriptPath" -WorkingDirectory "C:\ProgramData"
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "INTERACTIVE" -LogonType InteractiveToken
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -StartWhenAvailable

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings

Write-Output "Scheduled task '$TaskName' created successfully to map network drives on login."