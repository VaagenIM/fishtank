# Ensure that the script is run as an administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process -Verb RunAs -FilePath PowerShell -ArgumentList "cd $((Get-Location).Path); .\$((Get-Item $MyInvocation.MyCommand.Path).Name) $args"
    exit
}

function yn_prompt($prompt) {
    $response = Read-Host -prompt "$prompt (Y/n)"
    if ($response -eq "y" -or $response -eq "") {
        return $true
    } else {
        return $false
    }
}

$set_password = yn_prompt "Set a password for this admin account?"

if ($set_password) {
    $pw = Read-Host -AsSecureString -Prompt "Enter a password"
    $pw2 = Read-Host -AsSecureString -Prompt "Re-enter the password"

    if ([System.Net.NetworkCredential]::new("", $pw).Password -ne [System.Net.NetworkCredential]::new("", $pw2).Password) {
        Write-Output "Passwords do not match. Exiting..."
        exit
    }

    $UserAccount = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $UserAccount = $UserAccount -replace ".*\\", ""
    $UserAccount | Set-LocalUser -Password $pw
    Write-Output "Password set successfully."
}

$install_sunshine = yn_prompt "Install sunshine software for remote desktop?"

if ($install_sunshine) {
    $sunshine_uname = Read-Host -Prompt "Enter a username for the sunshine account"
    $sunshine_password = Read-Host -AsSecureString -Prompt "Enter a password for the sunshine account"
    $sunshine_password_clean = [System.Net.NetworkCredential]::new("", $sunshine_password).Password
}

$install_common      = yn_prompt "Install common software?"
$install_dev         = yn_prompt "Install developer software?"
$install_gaming_room = yn_prompt "Install gaming room software? (Adds a user, ollama, wallpaper, and maps network drives)"
$run_scripts         = yn_prompt "Run final scripts? (Debloat, auto-update, etc.)"
$logout_after        = yn_prompt "Log out after installation?"

Unblock-File choco-installer.ps1
. .\choco-installer.ps1

# Load blacklist entries (packages that should be pinned)
$blacklistFile = "apps/autoupdate-blacklist.txt"
if (Test-Path $blacklistFile) {
    $blacklist = Get-Content $blacklistFile | Where-Object { $_ -notmatch "^#|^$" }
} else {
    $blacklist = @()
}

function install_choco_packages($file) {
    Write-Output "Installing packages from $file..."
    $packages = Get-Content $file | Where-Object { ($_ -notmatch "^#|^$") -and ($_ -match "\S") }

    $packages | ForEach-Object -Parallel {
        $packageName = ($_ -replace "#.*", "").Trim()
        $isInstalled = choco list --local-only | Select-String "^$packageName\s"
        if (-not $isInstalled) {
            Write-Output "Installing $packageName..."
            choco install -y --ignore-checksums $packageName
        } else {
            Write-Output "$packageName already installed. Skipping..."
        }

        if ($using:blacklist -contains $packageName) {
            Write-Output "Pinning $packageName to suppress upgrades..."
            choco pin add -n $packageName
        }
    } -ThrottleLimit 8
}

function install_choco_packages_recursive($directory) {
    Write-Output "Processing package files in $directory..."
    if (Test-Path $directory) {
        Get-ChildItem -Path $directory -Filter "*.txt" | ForEach-Object {
            install_choco_packages $_.FullName
        }
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

function execute_scripts_recursive($directory) {
    Write-Output "Executing scripts in $directory..."
    if (Test-Path $directory) {
        Get-ChildItem -Path $directory -Filter "*.ps1" |
        ForEach-Object -Parallel {
            Unblock-File -Path $using:scriptPath
            Write-Output "Running script: $using:scriptPath..."
            & $using:scriptPath
        } -ArgumentList $_.FullName -ThrottleLimit 8
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

# Sunshine install
if ($install_sunshine) {
    Write-Output "Installing sunshine..."
    choco install -y sunshine

    $sunshine_binary = "C:\Program Files\Sunshine\sunshine.exe"
    $sunshine_creds = "--creds `"$sunshine_uname`" `"$sunshine_password_clean`""

    Start-Process -FilePath $sunshine_binary -ArgumentList $sunshine_creds -WindowStyle Hidden -Wait
    Stop-Process -Name "sunshine" -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath $sunshine_binary -ArgumentList $sunshine_creds -WindowStyle Hidden
}

# Install groups
if ($install_common) {
    install_choco_packages_recursive "apps/common"
    execute_scripts_recursive "scripts/common"
}
if ($install_dev) {
    install_choco_packages_recursive "apps/dev"
    execute_scripts_recursive "scripts/dev"
}
if ($install_gaming_room) {
    install_choco_packages_recursive "apps/gaming-room"
    execute_scripts_recursive "scripts/gaming-room"
}

# Run scripts
if ($run_scripts) {
    Write-Output "Running final script executions... (cleanup, debloat, etc.)"
    execute_scripts_recursive "scripts"
}

Write-Output "Fishtank is set up!"

if ($logout_after) {
    Write-Output "Logging out in 5 seconds..."
    Start-Sleep -Seconds 5
    shutdown /l
}
