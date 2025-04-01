# Install WSL, if it is not already installed
if (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | Where-Object { $_.State -eq "Enabled" }) {
    Write-Output "WSL is already installed. Skipping installation..."
} else {
    wsl --install
}