param(
  [switch]$InstallMissing
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Win32Dir = Join-Path $RepoRoot "codex-pet-watch\win32"

function Find-VsDevCmd {
  $candidates = @()

  $vswherePaths = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe",
    "$env:ProgramFiles\Microsoft Visual Studio\Installer\vswhere.exe"
  )

  foreach ($vswhere in $vswherePaths) {
    if (Test-Path -LiteralPath $vswhere) {
      $installations = & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
      foreach ($install in $installations) {
        if ($install) {
          $candidates += Join-Path $install "Common7\Tools\VsDevCmd.bat"
        }
      }
    }
  }

  $candidates += @(
    "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat",
    "$env:ProgramFiles\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat",
    "$env:ProgramFiles\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat",
    "$env:ProgramFiles\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat",
    "$env:ProgramFiles\Microsoft Visual Studio\2022\Preview\Common7\Tools\VsDevCmd.bat",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  return $null
}

function Require-WindowsBuildTools {
  $vsDevCmd = Find-VsDevCmd
  if ($vsDevCmd) {
    return $vsDevCmd
  }

  Write-Host "Missing Windows C++ build tools." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Required:"
  Write-Host "- Visual Studio 2022 Build Tools"
  Write-Host "- C++ build tools workload"
  Write-Host "- Windows 10/11 SDK"
  Write-Host "- CMake tools for Windows"
  Write-Host ""

  if ($InstallMissing) {
    & "$PSScriptRoot\get-tools.ps1"
    $vsDevCmd = Find-VsDevCmd
    if ($vsDevCmd) {
      return $vsDevCmd
    }
    throw "Build tools were not found after install. Open a new terminal and rerun .\build.ps1."
  }

  Write-Host "To install the headless CLI toolchain, run:"
  Write-Host "  .\tools\get-tools.ps1"
  Write-Host ""
  Write-Host "Or run the build with:"
  Write-Host "  .\build.ps1 -InstallMissing"
  throw "Missing Windows build prerequisites."
}

function Invoke-WindowsBuild {
  param(
    [Parameter(Mandatory = $true)]
    [string]$VsDevCmd
  )

  $cmd = "call `"$VsDevCmd`" -arch=x64 -host_arch=x64 >nul && build_msvc_x64.bat"

  Stop-RepoAppletProcesses

  Write-Host "Building Windows x64..."
  Push-Location $Win32Dir
  try {
    & cmd.exe /d /c $cmd
    if ($LASTEXITCODE -ne 0) {
      throw "Build failed with exit code $LASTEXITCODE."
    }
  }
  finally {
    Pop-Location
  }
}

function Stop-RepoAppletProcesses {
  $outputPaths = @(
    (Join-Path $Win32Dir "build-x64\Release\codex_pet_watch.exe"),
    (Join-Path $Win32Dir "build\codex_pet_watch.exe")
  )

  $normalizedOutputs = @{}
  foreach ($path in $outputPaths) {
    $normalizedOutputs[[System.IO.Path]::GetFullPath($path).ToLowerInvariant()] = $true
  }

  $processes = Get-Process codex_pet_watch -ErrorAction SilentlyContinue
  foreach ($process in $processes) {
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
    if ($normalizedOutputs.ContainsKey($normalizedPath)) {
      Write-Host "Stopping running applet before rebuild: $processPath"
      Stop-Process -Id $process.Id -Force
      $process.WaitForExit(5000) | Out-Null
    }
  }
}

$vsDevCmd = Require-WindowsBuildTools
Invoke-WindowsBuild -VsDevCmd $vsDevCmd

Write-Host ""
Write-Host "Build complete." -ForegroundColor Green
