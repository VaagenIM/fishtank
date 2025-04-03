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

# Create a scheduled task that runs in the background to map network drives on login
$TaskName = "MapDrives"
$Action = New-ScheduledTaskAction -Execute "C:\Windows\System32\conhost.exe" -Argument "/c powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -NoInteractive -File `"$ScriptPath`" "
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $Username
$Principal = New-ScheduledTaskPrincipal -UserId [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -LogonType Interactive -RunLevel Highest
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Description "Maps network drives on login"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskName -InputObject $Task

Write-Output "Scheduled task '$TaskName' created successfully to map network drives on login."