# Install choco upgrade all at startup, as well as a scheduled task to run it daily at 3 AM
choco install choco-upgrade-all-at-startup -y

# Define the task name and the command to run
$taskName = "ChocoUpgradeAll"
$command = "choco upgrade all -y"

# Define when you want the task to run. In this example, we'll run it every day at 3 AM.
$triggerTime = "03:00"

# Define the action to run the command (choco upgrade all -y)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"$command`""

# Define the trigger (daily at 3 AM)
$trigger = New-ScheduledTaskTrigger -Daily -At $triggerTime

# Define the task principal (runs with highest privileges)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the scheduled task
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Description "Runs choco upgrade all -y"

# Register the scheduled task
Register-ScheduledTask -TaskName $taskName -InputObject $task -Force

Write-Output "Scheduled task '$taskName' created successfully to run 'choco upgrade all -y' daily at $triggerTime."
