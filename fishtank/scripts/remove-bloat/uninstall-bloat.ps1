$ErrorActionPreference = "Stop"
$checklistPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Fishtank-install-checklist.txt"

try {
    $bculFile = Join-Path -Path $PSScriptRoot -ChildPath "uninstall.bcul"
    if (-not (Test-Path -LiteralPath $bculFile -PathType Leaf)) {
        throw "Uninstall list not found: $bculFile"
    }

    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        throw "Chocolatey is required to install Bulk Crap Uninstaller."
    }

    & choco.exe install bulk-crap-uninstaller --yes --no-progress
    if ($LASTEXITCODE -ne 0) {
        throw "Bulk Crap Uninstaller installation failed with exit code $LASTEXITCODE."
    }

    $installRoot = Join-Path ${env:ProgramFiles} "BCUninstaller"
    $bcuConsole = Get-ChildItem -LiteralPath $installRoot -Filter "BCU-console.exe" -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $bcuConsole) {
        throw "BCU-console.exe was not found below $installRoot."
    }

    Write-Host "Running BCU-console with uninstall list: $bculFile"
    & $bcuConsole.FullName "uninstall" $bculFile "/Q" "/U" "/J=VeryGood"
    if ($LASTEXITCODE -ne 0) {
        throw "BCU-console failed with exit code $LASTEXITCODE."
    }

    Write-Output "Finished uninstalling applications listed in $bculFile."
} catch {
    $entry = "- [ ] BCU uninstall :: $($_.Exception.Message)"
    Add-Content -LiteralPath $checklistPath -Value $entry -Encoding UTF8
    Write-Error $_
    throw
}
