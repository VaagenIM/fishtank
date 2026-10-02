$ErrorActionPreference = "Stop"

# Install the startup helper and also keep a predictable scheduled task.
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    throw "Chocolatey is not available."
}
& choco.exe install choco-upgrade-all-at-startup --yes --no-progress
if ($LASTEXITCODE -ne 0) {
    throw "Could not install choco-upgrade-all-at-startup."
}

$taskName = "ChocoUpgradeAll"
$triggerTime = "03:00"
$chocoPath = (Get-Command choco.exe).Source
$action = New-ScheduledTaskAction -Execute $chocoPath -Argument "upgrade all --yes --no-progress"

# Define the trigger (daily at 3 AM)
$trigger = New-ScheduledTaskTrigger -Daily -At $triggerTime

# Define the task principal (runs with highest privileges)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the scheduled task
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal `
    -Settings $settings -Description "Runs Chocolatey upgrades daily at $triggerTime"

# Register the scheduled task
Register-ScheduledTask -TaskName $taskName -InputObject $task -Force

Write-Output "Scheduled task '$taskName' created successfully to run 'choco upgrade all -y' daily at $triggerTime."
