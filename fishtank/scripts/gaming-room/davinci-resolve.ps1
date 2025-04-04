# Check if DaVinci is already installed, if it is, skip the installation
$installed = Get-Command "C:\Program Files\Blackmagic Design\DaVinci Resolve\Resolve.exe" -ErrorAction SilentlyContinue
if ($installed) {
    Write-Output "DaVinci Resolve is already installed. Skipping installation..."
    exit
}

# Install and configure DaVinci Resolve
$davinci_filename = "DaVinci_Resolve_19.1.4_Windows"
$download_url = "https://apps.iktim.no/Software/Windows/$davinci_filename.zip"

# Download to the download folder
$download_folder = "$env:USERPROFILE\Downloads"
$zip_file = "$download_folder\$davinci_filename.zip"
$extract_folder = "$download_folder\$davinci_filename"
$installerExe = "$davinci_filename.exe"

Write-Output "Downloading DaVinci Resolve from $download_url..."
if (Test-Path $zip_file) {
    Write-Output "File $zip_file already exists. Skipping download..."
} else {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $download_url -OutFile $zip_file
}
Write-Output "Extracting DaVinci Resolve to $extract_folder..."
if (Test-Path $extract_folder) {
    Write-Output "Folder $extract_folder already exists. Skipping extraction..."
} else {
    Expand-Archive -Path $zip_file -DestinationPath $extract_folder -Force
    Write-Output "Extraction completed."
}

Write-Output "Starting DaVinci Resolve installer..."
$installerPath = Join-Path $extract_folder $installerExe

# Launch the installer (without any silent switch)
$installerProc = Start-Process -FilePath $installerPath -PassThru

# Wait and search for the MSI file in the Temp directory
$tempFolder = [System.IO.Path]::GetTempPath()
Write-Output "Searching for ResolveInstaller.msi in $tempFolder..."
$msiFound = $null
$maxWait = 60  # maximum wait time in seconds
$elapsed = 0

while ($elapsed -lt $maxWait -and !$msiFound) {
    Start-Sleep -Seconds 2
    $msiFound = Get-ChildItem -Path $tempFolder -Filter "ResolveInstaller.msi" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    $elapsed += 2
}

if ($msiFound) {
    $msiPath = $msiFound.FullName
    Write-Output "Found MSI installer at $msiPath. Launching silent MSI installation..."
    $logFile = "$download_folder\ResolveInstall.log"
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /log `"$logFile`" ALLUSERS=1 REBOOT=ReallySuppress" -Wait
    Write-Output "MSI installation completed."
} else {
    Write-Error "ResolveInstaller.msi was not found in $tempFolder within $maxWait seconds."
}

# Close the original installer if it's still running
if (!$installerProc.HasExited) {
    Write-Output "Closing the original installer process..."
    $installerProc | Stop-Process -Force
    $setupProc = Get-Process -Name "SetupResolve" -ErrorAction SilentlyContinue
    if ($setupProc) {
        Write-Output "Closing SetupResolve.exe process..."
        $setupProc | Stop-Process -Force
    } else {
        Write-Output "SetupResolve.exe process not found."
    }
} else {
    Write-Output "Original installer process has already exited."
}

# Remove the downloaded zip file and extracted folder
if (Test-Path $zip_file) {
    Remove-Item -Path $zip_file -Force
    Write-Output "Removed downloaded zip file: $zip_file"
} else {
    Write-Output "Zip file $zip_file not found. Skipping removal..."
}

if (Test-Path $extract_folder) {
    Remove-Item -Path $extract_folder -Recurse -Force
    Write-Output "Removed extracted folder: $extract_folder"
} else {
    Write-Output "Extracted folder $extract_folder not found. Skipping removal..."
}

Write-Output "DaVinci Resolve installation process is complete."
