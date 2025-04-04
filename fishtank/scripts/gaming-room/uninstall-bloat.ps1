function BCUUninstall-ByDisplayName {
    param (
        [string]$NameMatch
    )

    # Define the path to Bulk Crap Uninstaller installed via Chocolatey
    $BCUPath = "C:\ProgramData\chocolatey\lib\bulk-crap-uninstaller\tools\BulkCrapUninstaller.exe"

    # Check if the Bulk Crap Uninstaller executable exists
    if (-not (Test-Path $BCUPath)) {
        Write-Error "Bulk Crap Uninstaller not found at $BCUPath. Please verify the installation."
        return
    }

    # Define the registry paths where uninstall information is stored
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "*$NameMatch*" }

        foreach ($app in $apps) {
            Write-Host "Initiating uninstallation of '$($app.DisplayName)' using Bulk Crap Uninstaller..."
            # Build the command-line arguments:
            # /u "DisplayName" tells BCU which program to uninstall
            # /silent runs the process silently
            $arguments = "/u `"$($app.DisplayName)`" /silent"

            # Start Bulk Crap Uninstaller with the specified arguments
            Start-Process -FilePath $BCUPath -ArgumentList $arguments -Wait -WindowStyle Hidden
        }
    }
}

# Example usage:
BCUUninstall-ByDisplayName -NameMatch "Lenovo Vantage"
BCUUninstall-ByDisplayName -NameMatch "McAfee"

Write-Output "Bulk uninstallation process has been initiated for matching applications."
