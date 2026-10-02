# Set the system locale to English (US)
Set-WinSystemLocale en-US

# Set the display language to English (US)
Set-WinUILanguageOverride -Language en-US

# Set country/region to Norway
Set-WinHomeLocation -GeoId 177  # 177 = Norway

$languageList = Get-WinUserLanguageList
if (-not ($languageList.LanguageTag -contains "nb-NO")) {
    $languageList.Add("nb-NO")
}

# Set the time zone to Europe/Oslo
Set-TimeZone -Id "W. Europe Standard Time"

# Set the keyboard layout to Norwegian on the Norwegian language entry.
$norwegian = $languageList | Where-Object LanguageTag -eq "nb-NO"
$norwegian.InputMethodTips.Clear()
$norwegian.InputMethodTips.Add("0414:00000414")
Set-WinUserLanguageList $languageList -Force

# Notify user
Write-Host "Language, keyboard, region, and timezone settings have been updated."
Write-Host "A system restart may be required for all changes to take effect."
