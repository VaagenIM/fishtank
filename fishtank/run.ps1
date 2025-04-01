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

$install_common = yn_prompt "Install common software?"
$install_dev = yn_prompt "Install developer software?"
$install_gaming_room = yn_prompt "Install gaming room software? (Adds a user, ollama, wallpaper, and maps network drives)"

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

    # Read the package list and process each package
    Get-Content $file | ForEach-Object {
        $package = $_.Trim()

        if ($package -notmatch "^#|^$") {
            if ((choco list -r --id-only $package) -eq "") {
                Write-Output "Installing $package..."
                powershell -Command "choco install -y $package"
            } else {
                Write-Output "$package is already installed. Skipping installation..."
            }

            # If the package is in the blacklist, pin it
            if ($blacklist -contains $package) {
                Write-Output "Pinning $package to suppress upgrades..."
                choco pin add -n=$package
            }
        }
    }
}

function install_choco_packages_recursive($directory) {
    Write-Output "Processing package files in $directory..."

    if (Test-Path $directory) {
        # Get all .txt files in the directory
        Get-ChildItem -Path $directory -Filter "*.txt" | ForEach-Object {
            Write-Output "Installing packages from $($_.FullName)..."
            install_choco_packages $_.FullName
        }
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

function execute_scripts_recursive($directory) {
    Write-Output "Executing scripts in $directory..."

    if (Test-Path $directory) {
        # Get all .ps1 script files in the directory
        Get-ChildItem -Path $directory -Filter "*.ps1" | ForEach-Object {
            Write-Output "Running script: $($_.FullName)..."
            & $_.FullName  # Executes the script
        }
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

execute_scripts_recursive "scripts"

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

Write-Output "Fishtank is set up!"