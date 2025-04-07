# Define the path to the .bcul uninstall list (in the same directory as the script)
$bculFile = Join-Path -Path $PSScriptRoot -ChildPath "uninstall.bcul"

# Define path to BCU-console.exe installed via Chocolatey
$BCUConsolePath = "C:\Program Files\BCUninstaller\win-x64\BCU-console.exe"

# Validate BCU-console exists
if (-not (Test-Path $BCUConsolePath)) {
    Write-Error "BCU-console.exe not found at $BCUConsolePath. Please verify the installation."
    exit 1
}

# Validate the .bcul file exists
if (-not (Test-Path $bculFile)) {
    Write-Error "Uninstall list not found at $bculFile. Please ensure 'uninstall.bcul' exists in the script directory."
    exit 1
}

# Build argument string to uninstall using the .bcul file silently
$arguments = "uninstall `"$bculFile`" /Q /U /J=VeryGood"

Write-Host "Running BCU-console with uninstall list: $bculFile"
Start-Process -FilePath $BCUConsolePath -ArgumentList $arguments -Wait -WindowStyle Hidden

Write-Output "Finished uninstalling applications listed in $bculFile."
