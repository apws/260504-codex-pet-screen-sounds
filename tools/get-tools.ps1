param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Require-Administrator {
  if (-not (Test-IsAdministrator)) {
    Write-Host "get-tools.ps1 must be run from an elevated PowerShell or Command Prompt." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Open PowerShell as Administrator, then run:"
    Write-Host "  .\tools\get-tools.ps1"
    Write-Host ""
    throw "Administrator privileges are required."
  }
}

function Repair-Winget {
  Write-Host "winget was not found. Bootstrapping WinGet with PowerShell..." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "This installs the Microsoft.WinGet.Client module from PSGallery,"
  Write-Host "then uses Repair-WinGetPackageManager -AllUsers."
  Write-Host ""

  $progressPreference = "SilentlyContinue"

  Install-PackageProvider -Name NuGet -Force | Out-Null
  Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope AllUsers | Out-Null
  Repair-WinGetPackageManager -AllUsers

  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if (-not $winget) {
    throw "WinGet bootstrap completed, but winget is still not available. Open a new elevated terminal and rerun .\tools\get-tools.ps1."
  }

  return $winget.Source
}

function Require-Winget {
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if (-not $winget) {
    return Repair-Winget
  }
  return $winget.Source
}

Require-Administrator

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
