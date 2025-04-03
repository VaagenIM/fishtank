# Uninstall McAfee silently
$mcafeeUninstall = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%McAfee%'"
foreach ($app in $mcafeeUninstall) {
    $app.Uninstall()
}

# Uninstall Lenovo Vantage silently
$lenovoVantageUninstall = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%Lenovo Vantage%'"
foreach ($app in $lenovoVantageUninstall) {
    $app.Uninstall()
}

Write-Output "McAfee and Lenovo Vantage have been uninstalled."
