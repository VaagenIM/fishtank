[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
choco install ollama -y
$env:OLLAMA_HOST = "0.0.0.0:11434"

# Add 11434 to the firewall for both private and public networks
$firewallRuleName = "Ollama Port 11434"
$firewallRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 11434 -Profile Any
    Write-Output "Firewall rule '$firewallRuleName' created for port 11434."
} else {
    Write-Output "Firewall rule '$firewallRuleName' already exists. Skipping creation."
}