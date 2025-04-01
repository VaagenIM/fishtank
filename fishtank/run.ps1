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

    # Set the current users password to the entered password
    $UserAccount = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $UserAccount = $UserAccount -replace ".*\\", ""
    $UserAccount | Set-LocalUser -Password $pw
    Write-Output "Password set successfully."
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
                choco pin add -n $package
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
            Unblock-File -Path $_.FullName  # Unblock the script
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
    # We need to run the user script first to create the user
    Unblock-File -Path "scripts/gaming-room/user.ps1"
    & "scripts/gaming-room/user.ps1"
    execute_scripts_recursive "scripts/gaming-room"
}

Write-Output "Fishtank is set up!"

# Log out in 5 seconds
Write-Output "Logging out in 5 seconds..."
Start-Sleep -Seconds 5
shutdown /l
