# Define script content
$batchContent = @"
@echo off
set user=guest

:Start
net use t: \\10.5.0.5\Transfer /user:\%user% ""
net use r: \\10.5.0.5\Ressurser /user:\%user% ""
if ERRORLEVEL 1 goto End

:End
echo Kan ikke koble til Galtvort.
pause
"@

# Define file paths
$batchFile = "C:\ProgramData\map_drives.bat"
$taskName = "MapNetworkDrives"

# Save batch file to a global location
$batchContent | Set-Content -Path $batchFile -Encoding ASCII

# Set proper permissions (allows all users to read/execute)
icacls $batchFile /grant "Users:RX" /T /C

# Create a scheduled task to run for all users at logon
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$batchFile`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -LogonType Interactive
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Description "Maps network drives on startup"

# Register the task
Register-ScheduledTask -TaskName $taskName -InputObject $task -Force

# Run the task immediately
Start-ScheduledTask -TaskName $taskName

Write-Output "Startup script added for all users!"
