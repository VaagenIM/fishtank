$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot
Set-Location -LiteralPath $scriptRoot

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $powershell = (Get-Command powershell.exe).Source
    $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"") + $args
    Start-Process -FilePath $powershell -Verb RunAs -WorkingDirectory $scriptRoot -ArgumentList $arguments
    exit 0
}

$desktopPath = [Environment]::GetFolderPath("Desktop")
$checklistPath = Join-Path $desktopPath "Fishtank-install-checklist.txt"
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Item, [string]$Details) {
    $failures.Add("$Item :: $Details")
}

function Write-Checklist {
    $header = @(
        "# Fishtank installation checklist"
        "# Generated: $(Get-Date -Format s)"
    )
    if ($failures.Count -eq 0) {
        $content = $header + @("", "- [x] No failures were reported.")
    } else {
        $content = $header + @(
            "# Review these items before putting the machine into service."
            ""
        ) + ($failures | ForEach-Object { "- [ ] $_" })
    }
    $content | Set-Content -LiteralPath $checklistPath -Encoding UTF8
    Write-Output "Installation checklist: $checklistPath"
}

trap {
    Add-Failure "Unhandled runner error" $_.Exception.Message
    Write-Warning "An unexpected error was recorded; continuing with the remaining steps."
    continue
}

function Read-YesNo([string]$Prompt) {
    $response = Read-Host "$Prompt (Y/n)"
    return [string]::IsNullOrWhiteSpace($response) -or $response -match "^(?i)y(es)?$"
}

function Get-RepoPath([string]$RelativePath) {
    return Join-Path $scriptRoot $RelativePath
}

function Invoke-ScriptFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Failure $Path "Script file was not found."
        return $false
    }
    try {
        Write-Output "Running script: $Path"
        Unblock-File -LiteralPath $Path -ErrorAction SilentlyContinue
        $global:LASTEXITCODE = 0
        & $Path
        if ($LASTEXITCODE -ne 0) {
            throw "Exited with code $LASTEXITCODE."
        }
        return $true
    } catch {
        Add-Failure $Path $_.Exception.Message
        Write-Warning "Failed: $Path"
        return $false
    }
}

function Install-ChocoPackages([string]$File, [string[]]$Blacklist) {
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Add-Failure $File "Package list was not found."
        return
    }
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Add-Failure $File "Chocolatey is not available."
        return
    }

    Get-Content -LiteralPath $File |
        Where-Object { $_ -notmatch "^\s*#" -and $_ -match "\S" } |
        ForEach-Object {
            $package = ($_ -replace "#.*", "").Trim()
            try {
                $packagePattern = "^{0}\|" -f [regex]::Escape($package)
                if (-not (choco.exe list --local-only --limit-output | Select-String -Pattern $packagePattern)) {
                    Write-Output "Installing $package..."
                    & choco.exe install $package --yes --no-progress
                    if ($LASTEXITCODE -ne 0) {
                        throw "Chocolatey exited with code $LASTEXITCODE."
                    }
                } else {
                    Write-Output "$package is already installed. Skipping."
                }

                if ($Blacklist -contains $package) {
                    & choco.exe pin add --name $package --yes
                    if ($LASTEXITCODE -ne 0) {
                        throw "Chocolatey pin exited with code $LASTEXITCODE."
                    }
                }
            } catch {
                Add-Failure "Chocolatey package '$package'" $_.Exception.Message
                Write-Warning "Failed: $package"
            }
        }
}

function Install-PackageFolder([string]$Folder, [string[]]$Blacklist) {
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
        return
    }
    try {
        Get-ChildItem -LiteralPath $Folder -Filter "*.txt" -File |
            Sort-Object FullName |
            ForEach-Object { Install-ChocoPackages $_.FullName $Blacklist }
    } catch {
        Add-Failure $Folder $_.Exception.Message
        Write-Warning "Could not process package folder: $Folder"
    }
}

function Invoke-ScriptFolder([string]$Folder) {
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
        return
    }
    try {
        Get-ChildItem -LiteralPath $Folder -Filter "*.ps1" -File |
            Sort-Object FullName |
            ForEach-Object { Invoke-ScriptFile $_.FullName }
    } catch {
        Add-Failure $Folder $_.Exception.Message
        Write-Warning "Could not process script folder: $Folder"
    }
}

$options = @{
    set_password = $null
    install_sunshine = $null
    install_common = $null
    install_dev = $null
    install_gaming_room = $null
    install_scripts = $null
    reboot_after = $null
    userpw = $null
    sunshine_uname = $null
    sunshine_password = $null
}

$options.userpw = $env:FISHTANK_USERPW
$options.sunshine_uname = $env:FISHTANK_SUNSHINE_USER
$options.sunshine_password = $env:FISHTANK_SUNSHINE_PASSWORD
$postReboot = $args -contains "--post-reboot"
if ($postReboot) {
    Unregister-ScheduledTask -TaskName "Fishtank-PostReboot" -Confirm:$false -ErrorAction SilentlyContinue
}
if ($options.sunshine_uname -and $options.sunshine_password) {
    $options.install_sunshine = $true
}

foreach ($arg in $args) {
    switch -Wildcard ($arg) {
        "--no-user" { $options.set_password = $false }
        "--no-sunshine" { $options.install_sunshine = $false }
        "--all" {
            $options.install_common = $true
            $options.install_dev = $true
            $options.install_gaming_room = $true
            $options.install_scripts = $true
            $options.reboot_after = $true
        }
        "--userpw=*" {
            $options.userpw = $arg.Substring(9)
            $options.set_password = $true
        }
        "--sunshine-creds=*" {
            $parts = $arg.Substring(18) -split ":", 2
            if ($parts.Count -ne 2 -or [string]::IsNullOrWhiteSpace($parts[0])) {
                throw "Sunshine credentials must use --sunshine-creds=username:password."
            }
            $options.sunshine_uname = $parts[0]
            $options.sunshine_password = $parts[1]
            $options.install_sunshine = $true
        }
        "--common" { $options.install_common = $true }
        "--dev" { $options.install_dev = $true }
        "--scripts" { $options.install_scripts = $true }
        "--gaming" { $options.install_gaming_room = $true }
        "--restart" { $options.reboot_after = $true }
        "--post-reboot" { }
    }
}

if ($null -eq $options.set_password) {
    $options.set_password = if ($postReboot) { $false } else { Read-YesNo "Set a password for this admin account?" }
}
if ($options.set_password) {
    $password = if ($null -ne $options.userpw) {
        ConvertTo-SecureString $options.userpw -AsPlainText -Force
    } else {
        Read-Host -AsSecureString -Prompt "Enter a password"
    }
    $confirmation = if ($null -ne $options.userpw) {
        $password
    } else {
        Read-Host -AsSecureString -Prompt "Re-enter the password"
    }
    if ([Net.NetworkCredential]::new("", $password).Password -ne [Net.NetworkCredential]::new("", $confirmation).Password) {
        throw "Passwords do not match."
    }
    $account = $identity.Name -replace ".*\\", ""
    Set-LocalUser -Name $account -Password $password
}

if ($null -eq $options.install_sunshine) {
    $options.install_sunshine = if ($postReboot) { $false } else { Read-YesNo "Install Sunshine for remote desktop?" }
}
if ($options.install_sunshine) {
    if (-not $options.sunshine_uname) { $options.sunshine_uname = Read-Host "Enter a username for the Sunshine account" }
    if (-not $options.sunshine_password) {
        $securePassword = Read-Host -AsSecureString -Prompt "Enter a password for the Sunshine account"
        $options.sunshine_password = [Net.NetworkCredential]::new("", $securePassword).Password
    }
}
if ($null -eq $options.install_common) { $options.install_common = if ($postReboot) { $false } else { Read-YesNo "Install common software?" } }
if ($null -eq $options.install_dev) { $options.install_dev = if ($postReboot) { $false } else { Read-YesNo "Install developer software?" } }
if ($null -eq $options.install_gaming_room) { $options.install_gaming_room = if ($postReboot) { $true } else { Read-YesNo "Install gaming-room software?" } }
if ($null -eq $options.install_scripts) { $options.install_scripts = if ($postReboot) { $true } else { Read-YesNo "Install scripts?" } }
if ($null -eq $options.reboot_after) { $options.reboot_after = $false }

Invoke-ScriptFile (Get-RepoPath "choco-installer.ps1") | Out-Null
$blacklistPath = Get-RepoPath "apps/autoupdate-blacklist.txt"
$blacklist = if (Test-Path -LiteralPath $blacklistPath) {
    Get-Content -LiteralPath $blacklistPath | Where-Object { $_ -notmatch "^\s*#" -and $_ -match "\S" }
} else { @() }

Invoke-ScriptFolder (Get-RepoPath "scripts/remove-bloat")
Install-PackageFolder (Get-RepoPath "apps/base") $blacklist

if ($options.install_sunshine) {
    try {
        & choco.exe install sunshine --yes --no-progress
        if ($LASTEXITCODE -ne 0) { throw "Chocolatey exited with code $LASTEXITCODE." }
        $sunshine = "C:\Program Files\Sunshine\sunshine.exe"
        if (-not (Test-Path -LiteralPath $sunshine)) { throw "Sunshine was not found at $sunshine." }
        $sunshineArgs = @("--creds", $options.sunshine_uname, $options.sunshine_password)
        Start-Process -FilePath $sunshine -ArgumentList $sunshineArgs -WindowStyle Hidden -Wait
        Stop-Process -Name "sunshine" -Force -ErrorAction SilentlyContinue
        Start-Process -FilePath $sunshine -ArgumentList $sunshineArgs -WindowStyle Hidden
    } catch {
        Add-Failure "Sunshine" $_.Exception.Message
        Write-Warning "Sunshine setup failed."
    }
}

if ($options.install_common) {
    Install-PackageFolder (Get-RepoPath "apps/common") $blacklist
    Invoke-ScriptFolder (Get-RepoPath "scripts/common")
}
if ($options.install_dev) {
    Install-PackageFolder (Get-RepoPath "apps/dev") $blacklist
    Invoke-ScriptFolder (Get-RepoPath "scripts/dev")
}
if ($options.install_gaming_room) {
    Install-PackageFolder (Get-RepoPath "apps/gaming-room") $blacklist
    Invoke-ScriptFolder (Get-RepoPath "scripts/gaming-room")
}
if ($options.install_scripts) { Invoke-ScriptFolder (Get-RepoPath "scripts") }

Write-Output "Fishtank is set up!"
if ($options.reboot_after) {
    try {
        $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" --post-reboot"
        $taskTrigger = New-ScheduledTaskTrigger -AtLogOn -User $identity.Name
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId $identity.Name -LogonType InteractiveToken -RunLevel Highest
        Register-ScheduledTask -TaskName "Fishtank-PostReboot" -Action $taskAction `
            -Trigger $taskTrigger -Principal $taskPrincipal -Force | Out-Null
        Write-Output "A post-reboot user setup pass was scheduled."
    } catch {
        Add-Failure "Post-reboot setup" $_.Exception.Message
        Write-Warning "Could not schedule the post-reboot setup pass."
    }
    Write-Checklist
    Write-Output "Rebooting in 15 seconds..."
    Start-Sleep -Seconds 15
    Restart-Computer -Force
} else {
    Write-Checklist
    pause
}
