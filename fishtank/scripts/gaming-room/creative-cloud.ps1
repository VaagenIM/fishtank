$ErrorActionPreference = "Stop"

if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw "winget is required to install Adobe Creative Cloud."
}

& winget.exe install --id Adobe.CreativeCloud --exact `
    --source winget --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) {
    throw "winget failed to install Adobe Creative Cloud with exit code $LASTEXITCODE."
}