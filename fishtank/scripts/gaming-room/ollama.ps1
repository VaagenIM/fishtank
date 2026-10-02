$ErrorActionPreference = "Stop"

[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
& choco.exe install ollama --yes --no-progress
if ($LASTEXITCODE -ne 0) {
    throw "Could not install Ollama."
}
$env:OLLAMA_HOST = "0.0.0.0:11434"

# Add 11434 to the firewall for both private and public networks
$firewallRuleName = "Ollama Port 11434"
$firewallRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 11434 -Profile Private | Out-Null
    Write-Output "Firewall rule '$firewallRuleName' created for port 11434."
} else {
    Write-Output "Firewall rule '$firewallRuleName' already exists. Skipping creation."
}