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

    # Set the current users password to the entered password
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

$install_common = yn_prompt "Install common software?"
$install_dev = yn_prompt "Install developer software?"
$install_gaming_room = yn_prompt "Install gaming room software? (Adds a user, ollama, wallpaper, and maps network drives)"
$install_scripts = yn_prompt "Install scripts? (Debloat, auto-update, etc.)"
$reboot_after = yn_prompt "Reboot after installation?"

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

    Get-Content $file | Where-Object {
        ($_ -notmatch "^#|^$") -and ($_ -match "\S")
    } | ForEach-Object {
        $packageName = $_ -replace "#.*", ""
        $packageName = $packageName.Trim()

        # Check if package is already installed
        $isInstalled = choco list --local-only | Select-String "^$packageName\s"

        if (-not $isInstalled) {
            Write-Output "Installing $packageName..."
            choco install -y --ignore-checksums $packageName
        } else {
            Write-Output "$packageName is already installed. Skipping installation..."
        }

        # If the package is in the blacklist, pin it
        if ($blacklist -contains $packageName) {
            Write-Output "Pinning $packageName to suppress upgrades..."
            choco pin add -n $packageName
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
            Unblock-File -Path $_.FullName
            & $_.FullName
        }
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

# Install apps/base.txt before proceeding
install_choco_packages "apps/base.txt"

# Run remove-bloat before proceeding
execute_scripts_recursive "scripts/remove-bloat"

if ($install_sunshine) {
    choco install -y sunshine
    $sunshine_binary = "C:\Program Files\Sunshine\sunshine.exe"
    $sunshine_creds = "--creds `"$sunshine_uname`" `"$sunshine_password_clean`""
    Start-Process -FilePath $sunshine_binary -ArgumentList $sunshine_creds -WindowStyle Hidden -Wait
    Stop-Process -Name "sunshine" -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath $sunshine_binary -ArgumentList $sunshine_creds -WindowStyle Hidden

    $firewall_rules = @(
        @{ Name = "Sunshine TCP 47984"; Port = 47984; Protocol = "TCP" },
        @{ Name = "Sunshine TCP 47989"; Port = 47989; Protocol = "TCP" },
        @{ Name = "Sunshine TCP 48010"; Port = 48010; Protocol = "TCP" },
        @{ Name = "Sunshine UDP 47998"; Port = 47998; Protocol = "UDP" },
        @{ Name = "Sunshine UDP 47999"; Port = 47999; Protocol = "UDP" },
        @{ Name = "Sunshine UDP 48000"; Port = 48000; Protocol = "UDP" }
    )

    foreach ($rule in $firewall_rules) {
        $ruleName = $rule.Name
        $port = $rule.Port
        $protocol = $rule.Protocol

        # Check if the rule already exists
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

        if (-not $existingRule) {
            Write-Output "Creating firewall rule: $ruleName for port $port ($protocol)..."
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol $protocol -LocalPort $port -Profile Any
        } else {
            Write-Output "Firewall rule: $ruleName already exists. Skipping..."
        }
    }

}

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

if ($install_scripts) {
    execute_scripts_recursive "scripts"
}

Write-Output "Fishtank is set up!"

if ($reboot_after) {
    Write-Output "Rebooting in 15 seconds..."
    Start-Sleep -Seconds 15
    Restart-Computer -Force
}

# If we aren't restarting out, we can just pause the script to let the user see the output
pause