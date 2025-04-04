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

    # Set the current user's password to the entered password
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
$logout_after = yn_prompt "Log out after installation?"

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
    $jobs = @()

    Get-Content $file | Where-Object { ($_ -notmatch "^#|^$") -and ($_ -match "\S") } | ForEach-Object {
        $packageName = ($_ -replace "#.*", "").Trim()

        # Check if package is already installed
        $isInstalled = choco list --local-only | Select-String "^$packageName\s"
        if (-not $isInstalled) {
            Write-Output "Scheduling installation for $packageName..."
            $job = Start-Job -ScriptBlock {
                param($pkg)
                choco install -y --ignore-checksums $pkg
            } -ArgumentList $packageName
            $jobs += $job
        } else {
            Write-Output "$packageName is already installed. Skipping installation..."
        }

        # If the package is in the blacklist, pin it
        if ($blacklist -contains $packageName) {
            Write-Output "Pinning $packageName to suppress upgrades..."
            choco pin add -n $packageName
        }
    }

    if ($jobs.Count -gt 0) {
        Write-Output "Waiting for package installation jobs to complete..."
        $jobs | Wait-Job | Out-Null
        $jobs | ForEach-Object { Receive-Job $_ | Write-Output }
    }
}

function install_choco_packages_recursive($directory) {
    Write-Output "Processing package files in $directory..."
    if (Test-Path $directory) {
        # Get all .txt files in the directory and run each in its own job
        $jobs = @()
        Get-ChildItem -Path $directory -Filter "*.txt" | ForEach-Object {
            Write-Output "Scheduling package installations from $($_.FullName)..."
            $job = Start-Job -ScriptBlock {
                param($file)
                install_choco_packages $file
            } -ArgumentList $_.FullName
            $jobs += $job
        }
        if ($jobs.Count -gt 0) {
            Write-Output "Waiting for all package file jobs to complete..."
            $jobs | Wait-Job | Out-Null
            $jobs | ForEach-Object { Receive-Job $_ | Write-Output }
        }
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

function execute_scripts_recursive($directory) {
    Write-Output "Executing scripts in $directory..."
    $jobs = @()
    if (Test-Path $directory) {
        # Get all .ps1 script files in the directory and run each in its own job
        Get-ChildItem -Path $directory -Filter "*.ps1" | ForEach-Object {
            Write-Output "Scheduling execution for script: $($_.FullName)..."
            Unblock-File -Path $_.FullName  # Unblock the script before scheduling
            $job = Start-Job -ScriptBlock {
                param($scriptPath)
                & $scriptPath
            } -ArgumentList $_.FullName
            $jobs += $job
        }
        if ($jobs.Count -gt 0) {
            Write-Output "Waiting for script execution jobs to complete..."
            $jobs | Wait-Job | Out-Null
            $jobs | ForEach-Object { Receive-Job $_ | Write-Output }
        }
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

if ($install_sunshine) {
    Write-Output "Installing sunshine in a separate process..."
    # Run the installation in its own background job
    $sunshineJob = Start-Job -ScriptBlock {
        choco install -y sunshine
    }
    $sunshineJob | Wait-Job | Out-Null
    Remove-Job $sunshineJob

    $sunshine_binary = "C:\Program Files\Sunshine\sunshine.exe"
    $sunshine_creds = "--creds `"$sunshine_uname`" `"$sunshine_password_clean`""
    Start-Process -FilePath $sunshine_binary -ArgumentList $sunshine_creds -WindowStyle Hidden -Wait
    Stop-Process -Name "sunshine" -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath $sunshine_binary -ArgumentList $sunshine_creds -WindowStyle Hidden
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

Get-Job | Wait-Job | Out-Null

Write-Output "Fishtank is set up!"

if ($logout_after) {
    # Log out in 5 seconds
    Write-Output "Logging out in 5 seconds..."
    Start-Sleep -Seconds 5
    shutdown /l
}
