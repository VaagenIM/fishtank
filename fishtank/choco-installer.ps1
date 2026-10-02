# Enable Developer Mode
Write-Output "Enabling Developer Mode..."
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"

$ErrorActionPreference = "Stop"

# https://chocolatey.org/install
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Output "Chocolatey is installed. Updating Chocolatey..."
    choco upgrade chocolatey -y
} else {
    Write-Output "Chocolatey is not installed. Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# The installer updates the machine PATH, but the current PowerShell process
# keeps its original environment until it is refreshed.
$env:Path = @(
    [Environment]::GetEnvironmentVariable("Path", "Machine")
    [Environment]::GetEnvironmentVariable("Path", "User")
) -join ";"
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    throw "Chocolatey is not available after installation."
}