param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Require-Winget {
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if (-not $winget) {
    Write-Host "winget was not found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Install App Installer from Microsoft:"
    Write-Host "  https://apps.microsoft.com/detail/9nblggh4nns1"
    Write-Host ""
    Write-Host "Or install Visual Studio 2022 Build Tools manually:"
    Write-Host "  https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022"
    Write-Host ""
    Write-Host "Required workload:"
    Write-Host "  Desktop development with C++"
    Write-Host ""
    throw "Missing winget/App Installer."
  }
  return $winget.Source
}

Write-Host "Installing headless Windows C++ build tools with winget..."
Write-Host ""
Write-Host "This installs Visual Studio 2022 Build Tools, not the full Visual Studio IDE."
Write-Host "It may show a UAC prompt and can take a while."
Write-Host ""

$override = "--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"

if ($DryRun) {
  Write-Host "Dry run. This would execute:"
  Write-Host ""
  Write-Host "winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --source winget --accept-package-agreements --accept-source-agreements --override `"$override`""
  Write-Host ""
  Write-Host "No tools were installed."
  return
}

$winget = Require-Winget

& $winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --source winget --accept-package-agreements --accept-source-agreements --override $override

if ($LASTEXITCODE -ne 0) {
  throw "winget failed with exit code $LASTEXITCODE."
}

Write-Host ""
Write-Host "Install complete. Open a new terminal, then run:"
Write-Host "  .\build.ps1"
