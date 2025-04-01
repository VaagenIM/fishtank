[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "Machine")
choco install ollama
$env:OLLAMA_HOST = "0.0.0.0:11434"