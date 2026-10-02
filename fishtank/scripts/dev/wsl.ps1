$ErrorActionPreference = "Stop"

$feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($feature.State -eq "Enabled") {
    Write-Output "WSL is already installed. Skipping installation..."
} else {
    wsl --install
}