# Set keyboard layout to Norwegian
Set-WinUserLanguageList -LanguageList en-US, nb-NO -Force
Set-WinUILanguageOverride -Language en-US
Set-WinUserLanguageOverride -Language en-US

# Set input method (keyboard layout) to Norwegian
$LangList = Get-WinUserLanguageList
$LangList[0].InputMethodTips.Add("0414:00000414")  # Norwegian input method
Set-WinUserLanguageList $LangList -Force

# Set country to Norway
Set-WinHomeLocation -GeoId 177  # 177 = Norway

# Set system locale to English (US)
Set-WinSystemLocale -SystemLocale en-US

# Set timezone to Europe/Oslo
Set-TimeZone -Id "W. Europe Standard Time"

# Set display language to English (US)
Set-WinUILanguageOverride -Language en-US
Set-WinUserLanguageOverride -Language en-US

# Notify user
Write-Host "Language, keyboard, region, and timezone settings have been updated."
Write-Host "A system restart may be required for all changes to take effect."
