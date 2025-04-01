# Enable Developer Mode
Write-Output "Enabling Developer Mode..."
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"

# Enable ExecutionPolicy to Unrestricted (Allows for scripts to run without signing)
# i.e. Python Venv scripts and other scripts
Set-ExecutionPolicy Unrestricted -Force

# Install WSL, if it is not already installed
if (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | Where-Object { $_.State -eq "Enabled" }) {
    Write-Output "WSL is already installed. Skipping installation..."
} else {
    wsl --install
}

# https://chocolatey.org/install
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Output "Chocolatey is installed. Updating Chocolatey..."
    choco upgrade chocolatey -y
} else {
    Write-Output "Chocolatey is not installed. Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}