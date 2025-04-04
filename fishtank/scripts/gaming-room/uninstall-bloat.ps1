# Helper function to uninstall an app silently if found
function Uninstall-ByDisplayName {
    param (
        [string]$NameMatch
    )

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*$NameMatch*" }

        foreach ($app in $apps) {
            $uninstallCmd = $app.UninstallString
            if ($uninstallCmd) {
                Write-Host "Uninstalling $($app.DisplayName)..."

                # Attempt to silently uninstall
                if ($uninstallCmd -match "msiexec\.exe") {
                    # Make sure /quiet or /qn is used
                    $silentCmd = "$uninstallCmd /quiet /norestart"
                } else {
                    # Some EXE uninstallers might support /S or /quiet, but it's vendor-specific
                    $silentCmd = "$uninstallCmd /S /quiet /norestart"
                }

                # TODO: Bypass prompts...
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c $silentCmd" -Wait -WindowStyle Hidden
            }
        }
    }
}

# Uninstall Lenovo Vantage
Uninstall-ByDisplayName -NameMatch "Lenovo Vantage"

# Uninstall McAfee
Uninstall-ByDisplayName -NameMatch "McAfee"

Write-Output "McAfee and Lenovo Vantage have been uninstalled."
