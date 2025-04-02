# Uninstall McAfee and Lenovo Vantage
Get-AppPackage -AllUsers -Name "*mcafee*" | Remove-AppPackage
Get-AppPackage -AllUsers -Name "*lenovo*" | Remove-AppPackage