Get-AppxPackage Microsoft.549981C3F5F10 | Remove-AppxPackage # Remove Cortana app
Get-AppxPackage MicrosoftWindows.Client.WebExperience | Remove-AppxPackage # Remove Widgets app
Get-AppxPackage Microsoft.GetHelp | Remove-AppxPackage # Remove Get Help app
Get-AppxPackage Microsoft.YourPhone | Remove-AppxPackage # Remove Your Phone app
Get-AppxPackage Microsoft.BingWeather | Remove-AppxPackage # Remove Weather app
Get-AppxPackage Microsoft.BingNews | Remove-AppxPackage # Remove News app
Get-AppxPackage Microsoft.Todos | Remove-AppxPackage # Remove Microsoft To Do
Get-AppxPackage Microsoft.MicrosoftSolitaireCollection | Remove-AppxPackage # Remove Microsoft Solitaire Collection
Get-AppxPackage Microsoft.WindowsFeedbackHub | Remove-AppxPackage # Remove Feedback Hub
Get-AppxPackage Microsoft.MicrosoftOfficeHub | Remove-AppxPackage # Remove Office app
Get-AppxPackage Microsoft.PowerAutomateDesktop | Remove-AppxPackage # Remove Power Automate
Get-AppxPackage Microsoft.Microsoft3DViewer | Remove-AppxPackage # Remove 3D Viewer
Get-AppxPackage Microsoft.SkypeApp | Remove-AppxPackage # Remove Skype
Get-AppxPackage Microsoft.Getstarted | Remove-AppxPackage # Remove Tips app
Get-AppxPackage Microsoft.Office.OneNote | Remove-AppxPackage # Remove OneNote
Get-AppxPackage Microsoft.MSPaint | Remove-AppxPackage # Remove Paint 3D
Get-AppxPackage Microsoft.MicrosoftStickyNotes | Remove-AppxPackage # Remove Sticky Notes
Get-AppxPackage SpotifyAB.SpotifyMusic | Remove-AppxPackage # Remove Spotify
Get-AppxPackage Disney.37853FC22B2CE | Remove-AppxPackage # Remove Disney+
Get-AppxPackage Microsoft.XboxApp | Remove-AppxPackage # Remove Xbox Companion app
Get-AppxPackage Microsoft.MixedReality.Portal | Remove-AppxPackage # Remove Mixed Reality Portal
Get-AppxPackage Clipchamp.Clipchamp | Remove-AppxPackage # Remove ClipChamp
Get-AppxPackage MicrosoftCorporationII.QuickAssist | Remove-AppxPackage # Remove Quick Assist
Get-AppxPackage MicrosoftTeams | Remove-AppxPackage # Remove Teams
Get-AppxPackage Microsoft.GamingApp | Remove-AppxPackage # Remove Xbox app
Get-AppxPackage Microsoft.XboxApp | Remove-AppxPackage # Remove Xbox companion app
Get-AppxPackage MicrosoftCorporationII.MicrosoftFamily | Remove-AppxPackage # Remove Microsoft Family
Get-AppxPackage Microsoft.Windows.DevHome | Remove-AppxPackage # Remove Dev Home

Get-WindowsCapability -Online -Name App.StepsRecorder* | Remove-WindowsCapability -Online # Remove Steps Recorder
Get-WindowsCapability -Online -Name App.Support.QuickAssist* | Remove-WindowsCapability -Online # Remove Quick Assist
Get-WindowsCapability -Online -Name Browser.InternetExplorer* | Remove-WindowsCapability -Online # Remove Internet Explorer
Get-WindowsCapability -Online -Name Hello.Face.* | Remove-WindowsCapability -Online # Remove Windows Hello Face
Get-WindowsCapability -Online -Name MathRecognizer* | Remove-WindowsCapability -Online # Remove Math Recognizer
Get-WindowsCapability -Online -Name Media.WindowsMediaPlayer* | Remove-WindowsCapability -Online # Remove Windows Media Player
Get-WindowsCapability -Online -Name Microsoft.Windows.PowerShell.ISE* | Remove-WindowsCapability -Online # Remove PowerShell ISE
Get-WindowsCapability -Online -Name Microsoft.Windows.WordPad* | Remove-WindowsCapability -Online # Remove WordPad
Get-WindowsCapability -Online -Name XPS.Viewer* | Remove-WindowsCapability -Online # Remove XPS Viewer
Get-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer | Disable-WindowsOptionalFeature -Online -Remove # Remove Windows Media Player
Get-WindowsOptionalFeature -Online -FeatureName Internet-Explorer-Optional-* | Disable-WindowsOptionalFeature -Online -Remove -NoRestart # Remove Internet Explorer

# Disable SIUF (System Initiated User Feedback)
reg.exe ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d "0" /f

# Disable fast start-up
reg.exe ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d "0" /f

# Disable Windows Security summary notifications0
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender Security Center\Virus and threat protection" /v SummaryNotificationDisabled /t REG_DWORD /d "1" /f

# Disable get the most out of Windows
reg.exe ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v ScoobeSystemSettingEnabled /t REG_DWORD /d "0" /f

# Disable Tailored Experiences
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d "0" /f

# Disable Telemetry
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d "0" /f

# Disable Game Bar Auto Game Mode
reg.exe ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d "0" /f

# Disable Clipboard History
reg.exe ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Clipboard" /v EnableClipboardHistory /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowClipboardHistory /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowCrossDeviceClipboard /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d "0" /f
reg.exe ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d "0" /f

# More options: https://gist.github.com/y0lopix/bca18265869e5da9068de0a6729bc262