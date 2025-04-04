# Install and configure DaVinci Resolve
$davinci_filename = "DaVinci_Resolve_19.1.4_Windows"
$download_url = "https://apps.iktim.no/Software/Windows/$davinci_filename.zip"

# Download to the download folder
$download_folder = "$env:USERPROFILE\Downloads"
$zip_file = "$download_folder\$davinci_filename.zip"
$extract_folder = "$download_folder\$davinci_filename"
$filename = "$davinci_filename.exe"

Write-Output "Downloading DaVinci Resolve from $download_url..."
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $download_url -OutFile $zip_file
Write-Output "Extracting DaVinci Resolve to $extract_folder..."
Expand-Archive -Path $zip_file -DestinationPath $extract_folder -Force
Write-Output "Running DaVinci Resolve installer..."

$installerPath = Join-Path $extract_folder $filename
Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
Write-Output "DaVinci Resolve installation completed."