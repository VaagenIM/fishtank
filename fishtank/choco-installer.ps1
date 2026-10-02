$ErrorActionPreference = "Stop"

# Enable Developer Mode
Write-Output "Enabling Developer Mode..."
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
if ($LASTEXITCODE -ne 0) {
    throw "Could not enable Developer Mode."
}

# https://chocolatey.org/install
if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
    Write-Output "Chocolatey is installed. Updating Chocolatey..."
    & choco.exe upgrade chocolatey --yes --no-progress
    if ($LASTEXITCODE -ne 0) {
        throw "Could not update Chocolatey."
    }
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