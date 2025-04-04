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

$install_common      = yn_prompt "Install common software?"
$install_dev         = yn_prompt "Install developer software?"
$install_gaming_room = yn_prompt "Install gaming room software? (Adds a user, ollama, wallpaper, and maps network drives)"
$install_scripts     = yn_prompt "Install scripts? (Debloat, auto-update, etc.)"
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

# Function: Process package files in a directory (runs installations concurrently per file)
function install_choco_packages_recursive($directory) {
    # Function: Install packages from a text file concurrently for each package
    function install_choco_packages($file) {
        Write-Output "Installing packages from $file..."
        $c_jobs = @()
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
                $c_jobs += $job
            } else {
                Write-Output "$packageName is already installed. Skipping installation..."
            }
            # If the package is in the blacklist, pin it
            if ($blacklist -contains $packageName) {
                Write-Output "Pinning $packageName to suppress upgrades..."
                choco pin add -n $packageName
            }
        }
        if ($c_jobs.Count -gt 0) {
            Write-Output "Waiting for package installation jobs to complete for file $file..."
            $c_jobs | Wait-Job | Out-Null
            $c_jobs | ForEach-Object { Receive-Job $_ | Write-Output }
        }
    }

    Write-Output "Processing package files in $directory..."
    if (Test-Path $directory) {
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
            Write-Output "Waiting for all package file jobs in $directory to complete..."
            $jobs | Wait-Job | Out-Null
            $jobs | ForEach-Object { Receive-Job $_ | Write-Output }
        }
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

# Function: Execute scripts (runs each script concurrently)
function execute_scripts_recursive($directory) {
    Write-Output "Executing scripts in $directory..."
    $jobs = @()
    if (Test-Path $directory) {
        Get-ChildItem -Path $directory -Filter "*.ps1" | ForEach-Object {
            Write-Output "Scheduling execution for script: $($_.FullName)..."
            Unblock-File -Path $_.FullName
            $job = Start-Job -ScriptBlock {
                param($scriptPath)
                & $scriptPath
            } -ArgumentList $_.FullName
            $jobs += $job
        }
        if ($jobs.Count -gt 0) {
            Write-Output "Waiting for script execution jobs in $directory to complete..."
            $jobs | Wait-Job | Out-Null
            $jobs | ForEach-Object { Receive-Job $_ | Write-Output }
        }
    } else {
        Write-Output "Directory $directory does not exist. Skipping..."
    }
}

# --- Sunshine Installation (runs in its own process) ---
if ($install_sunshine) {
    Write-Output "Installing sunshine in a separate process..."
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

# --- Run Package Installations and Script Executions Concurrently ---
$jobs = @()

if ($install_common) {
    $jobs += Start-Job -ScriptBlock { install_choco_packages_recursive "apps/common" }
    $jobs += Start-Job -ScriptBlock { execute_scripts_recursive "scripts/common" }
}

if ($install_dev) {
    $jobs += Start-Job -ScriptBlock { install_choco_packages_recursive "apps/dev" }
    $jobs += Start-Job -ScriptBlock { execute_scripts_recursive "scripts/dev" }
}

if ($install_gaming_room) {
    $jobs += Start-Job -ScriptBlock { install_choco_packages_recursive "apps/gaming-room" }
    $jobs += Start-Job -ScriptBlock { execute_scripts_recursive "scripts/gaming-room" }
}


if ($jobs.Count -gt 0) {
    Write-Output "Waiting for all package and script jobs to complete..."
    $jobs | Wait-Job | Out-Null
    $jobs | ForEach-Object { Receive-Job $_ | Write-Output }
}

# Catch-all wait (if any stray jobs remain)
Get-Job | Wait-Job | Out-Null
Write-Output "All package installations and script executions completed."

if ($install_scripts) {
    Write-Output "Running final script executions... (cleanup, debloat, etc.)"
    execute_scripts_recursive "scripts"
}

Write-Output "Fishtank is set up!"

if ($logout_after) {
    Write-Output "Logging out in 5 seconds..."
    Start-Sleep -Seconds 5
    shutdown /l
}
