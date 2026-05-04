Write-Host "Stopping Codex processes..."
Get-Process | Where-Object {
  $_.ProcessName -match "codex"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

Write-Host "Checking CLI auth..."
codex login status

Write-Host "Launching Codex desktop..."
codex app
