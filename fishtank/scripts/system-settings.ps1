# Set the system locale to English (US)
Set-WinSystemLocale en-US

# Set the display language to English (US)
Set-WinUILanguageOverride -Language en-US

# Set country/region to Norway
Set-WinHomeLocation -GeoId 177  # 177 = Norway

# Set the input method (keyboard layout) to Norwegian
$LanguageList = Get-WinUserLanguageList
$LanguageList.Add("nb-NO") # Add Norwegian language (for display purposes)
Set-WinUserLanguageList $LanguageList -Force

# Set the time zone to Europe/Oslo
Set-TimeZone -Id "W. Europe Standard Time"

# Set the keyboard layout to Norwegian
$LanguageList = Get-WinUserLanguageList
$LanguageList[0].InputMethodTips.Clear() # Clear any existing input methods
$LanguageList[0].InputMethodTips.Add("0409:00000414")  # Norwegian Keyboard Layout
Set-WinUserLanguageList $LanguageList -Force

# Notify user
Write-Host "Language, keyboard, region, and timezone settings have been updated."
Write-Host "A system restart may be required for all changes to take effect."
