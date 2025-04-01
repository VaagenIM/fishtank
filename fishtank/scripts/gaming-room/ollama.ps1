[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
choco install ollama -y
$env:OLLAMA_HOST = "0.0.0.0:11434"