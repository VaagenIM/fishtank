$ErrorActionPreference = "Stop"

# Apply the profile to every connected Ethernet adapter; interface names vary by
# hardware and localized Windows installations.
Get-NetConnectionProfile |
    Where-Object { $_.IPv4Connectivity -ne "Disconnected" } |
    ForEach-Object {
        Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private
    }

$ruleName = "Allow ICMPv4-In"
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol ICMPv4 `
        -Action Allow -Profile Private | Out-Null
}