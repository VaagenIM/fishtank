# Enable Developer Mode
Write-Output "Enabling Developer Mode..."
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"

# Enable execution of PowerShell scripts
Write-Output "Enabling execution of PowerShell scripts..."
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# https://chocolatey.org/install
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Output "Chocolatey is installed. Updating Chocolatey..."
    choco upgrade chocolatey -y
} else {
    Write-Output "Chocolatey is not installed. Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}