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

# Ensure the script runs at login for all users by adding it to the registry
$RegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"

if (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force
}

Set-ItemProperty -Path $RegPath -Name "MapNetworkDrives" -Value "powershell -ExecutionPolicy Bypass -File `"$ScriptPath`""

Write-Output "Logon script registered in Windows Registry to run at startup for all users."
