# Set network mode to Private
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private

# Open the port for "ping"
New-NetFirewallRule -DisplayName "Allow ICMPv4-In" -Direction Inbound -Protocol ICMPv4 -Action Allow -LocalPort Any -Profile Any