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

# Initialize options
$options = @{
    set_password         = $null
    install_sunshine     = $null
    install_common       = $null
    install_dev          = $null
    install_gaming_room  = $null
    install_scripts      = $null
    reboot_after         = $null
    userpw               = $null
    sunshine_uname       = $null
    sunshine_password    = $null
}

# Parse command-line arguments
foreach ($arg in $args) {
    switch -Wildcard ($arg) {
        "--no-user"            { $options.set_password = $false }
        "--no-sunshine"        { $options.install_sunshine = $false }
        "--all" {
            $options.install_common = $true
            $options.install_dev = $true
            $options.install_gaming_room = $true
            $options.install_scripts = $true
            $options.reboot_after = $true
        }
        "--userpw=*" {
            $options.userpw = $arg -replace "--userpw=", ""
            $options.set_password = $true
        }
        "--sunshine-creds=*" {
            $creds = $arg -replace "--sunshine-creds=", ""
            $parts = $creds -split ":", 2
            if ($parts.Length -eq 2) {
                $options.sunshine_uname = $parts[0]
                $options.sunshine_password = $parts[1]
                $options.install_sunshine = $true
            }
        }
        "--common"  { $options.install_common = $true }
        "--dev"     { $options.install_dev = $true }
        "--scripts" { $options.install_scripts = $true }
        "--gaming"  { $options.install_gaming_room = $true}
        "--restart" { $options.reboot_after = $true }
    }
}

if ($options.set_password -eq $null) {
    $options.set_password = yn_prompt "Set a password for this admin account?"
}

if ($options.set_password) {
    $pw = if ($options.userpw) {
        ConvertTo-SecureString $options.userpw -AsPlainText -Force
    } else {
        Read-Host -AsSecureString -Prompt "Enter a password"
    }
    $pw2 = if ($options.userpw) {
        $pw
    } else {
        Read-Host -AsSecureString -Prompt "Re-enter the password"
    }

    if ([System.Net.NetworkCredential]::new("", $pw).Password -ne [System.Net.NetworkCredential]::new("", $pw2).Password) {
        Write-Output "Passwords do not match. Exiting..."
        exit
    }

    $UserAccount = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -replace ".*\\", ""
    $UserAccount | Set-LocalUser -Password $pw
    Write-Output "Password set successfully."
}

if ($options.install_sunshine -eq $null) {
    $options.install_sunshine = yn_prompt "Install sunshine software for remote desktop?"
}

if ($options.install_sunshine) {
    if (-not $options.sunshine_uname) {
        $options.sunshine_uname = Read-Host -Prompt "Enter a username for the sunshine account"
    }
    $secure_pw = if ($options.sunshine_password) {
        ConvertTo-SecureString $options.sunshine_password -AsPlainText -Force
    } else {
        Read-Host -AsSecureString -Prompt "Enter a password for the sunshine account"
    }
    $options.sunshine_password = [System.Net.NetworkCredential]::new("", $secure_pw).Password
}

if ($options.install_common -eq $null) { $options.install_common = yn_prompt "Install common software?" }
if ($options.install_dev -eq $null) { $options.install_dev = yn_prompt "Install developer software?" }
if ($options.install_gaming_room -eq $null) { $options.install_gaming_room = yn_prompt "Install gaming room software?" }
if ($options.install_scripts -eq $null) { $options.install_scripts = yn_prompt "Install scripts? (Debloat, auto-update, etc.)" }
if ($options.reboot_after -eq $null) { $options.reboot_after = yn_prompt "Reboot after installation?" }

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

function Start-InstallJob($appFolder, $scriptFolder = $null, $blacklist = @()) {
    $jobs = @()

    if ($appFolder -and (Test-Path $appFolder)) {
        Get-ChildItem -Path $appFolder -Filter "*.txt" | ForEach-Object {
            Get-Content $_.FullName | Where-Object { ($_ -notmatch "^#|^$") -and ($_ -match "\S") } | ForEach-Object {
                $package = $_ -replace "#.*", ""
                $package = $package.Trim()

                $jobs += Start-Job -ScriptBlock {
                    param($package, $blacklist)
                    if (-not (choco list --local-only | Select-String "^$package\s")) {
                        Write-Output "Installing $package..."
                        choco install -y --ignore-checksums $package
                    } else {
                        Write-Output "$package is already installed. Skipping..."
                    }

                    if ($blacklist -contains $package) {
                        Write-Output "Pinning $package..."
                        choco pin add -n $package
                    }
                } -ArgumentList $package, $blacklist
            }
        }
    }

    if ($scriptFolder -and (Test-Path $scriptFolder)) {
        $jobs += Start-Job -ScriptBlock {
            param($folder)
            Get-ChildItem -Path $folder -Filter "*.ps1" | ForEach-Object {
                Write-Output "Running script: $($_.FullName)"
                Unblock-File -Path $_.FullName
                & $_.FullName
            }
        } -ArgumentList $scriptFolder
    }

    return $jobs
}

execute_scripts_recursive "scripts/remove-bloat"

$jobs = @()
$jobs += Start-InstallJob -appFolder "apps/base" -scriptFolder $null -blacklist $blacklist
if ($jobs.Count -gt 0) {
    Write-Output "Waiting for base installation jobs to complete..."
    $jobs | ForEach-Object { Wait-Job $_ }
    $jobs | ForEach-Object { Receive-Job $_; Remove-Job $_ }
}

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

$jobs = @()

if ($install_common) {
    $jobs += Start-InstallJob "apps/common" "scripts/common" $blacklist
}

if ($install_dev) {
    $jobs += Start-InstallJob "apps/dev" "scripts/dev" $blacklist
}

if ($install_gaming_room) {
    $jobs += Start-InstallJob "apps/gaming-room" "scripts/gaming-room" $blacklist
}

if ($jobs.Count -gt 0) {
    Write-Output "Waiting for installation jobs to complete..."
    $jobs | ForEach-Object { Wait-Job $_ }
    $jobs | ForEach-Object { Receive-Job $_; Remove-Job $_ }
}

if ($install_scripts) {
    $jobs = @()
    $jobs += Start-InstallJob $null "scripts"
    if ($jobs.Count -gt 0) {
        Write-Output "Waiting for scripts to complete..."
        $jobs | ForEach-Object { Wait-Job $_ }
        $jobs | ForEach-Object { Receive-Job $_; Remove-Job $_ }
    }
}

Write-Output "Fishtank is set up!"

if ($reboot_after) {
    Write-Output "Rebooting in 15 seconds..."
    Start-Sleep -Seconds 15
    Restart-Computer -Force
}

# If we aren't restarting out, we can just pause the script to let the user see the output
pause