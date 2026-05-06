param(
  [switch]$NoBuild,
  [switch]$Restart,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$AppletArgs
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ExePath = Join-Path $RepoRoot "codex-pet-watch\win32\build-x64\Release\codex_pet_watch.exe"

$isWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)

if (-not $isWindowsPlatform) {
  throw "run.ps1 currently launches the Windows x64 applet. Use the macOS app bundle on macOS."
}

if (-not [Environment]::Is64BitOperatingSystem) {
  throw "This applet is built for 64-bit Windows."
}

function Get-RunningRepoApplet {
  $expectedPath = [System.IO.Path]::GetFullPath($ExePath).ToLowerInvariant()
  $matches = @()

  foreach ($process in (Get-Process codex_pet_watch -ErrorAction SilentlyContinue)) {
    $processPath = $null
    try {
      $processPath = $process.Path
    }
    catch {
      continue
    }

    if (-not $processPath) {
      continue
    }

    $normalizedPath = [System.IO.Path]::GetFullPath($processPath).ToLowerInvariant()
    if ($normalizedPath -eq $expectedPath) {
      $matches += $process
    }
  }

  return $matches
}

if (-not (Test-Path -LiteralPath $ExePath)) {
  if ($NoBuild) {
    throw "Missing executable: $ExePath"
  }

  Write-Host "Executable is missing; building first..."
  & (Join-Path $RepoRoot "build.ps1")
}

$running = @(Get-RunningRepoApplet)
if ($running.Count -gt 0) {
  if (-not $Restart) {
    Write-Host "Applet is already running: $ExePath"
    Write-Host "Use .\run.ps1 -Restart to stop and relaunch it."
    return
  }

  foreach ($process in $running) {
    Write-Host "Stopping running applet: $($process.Path)"
    Stop-Process -Id $process.Id -Force
    $process.WaitForExit(5000) | Out-Null
  }
}

Write-Host "Launching: $ExePath"
if ($AppletArgs -and $AppletArgs.Count -gt 0) {
  Start-Process -FilePath $ExePath -ArgumentList $AppletArgs -WindowStyle Hidden
}
else {
  Start-Process -FilePath $ExePath -WindowStyle Hidden
}
