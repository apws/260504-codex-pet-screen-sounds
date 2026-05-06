param(
  [switch]$InstallMissing
)

$ErrorActionPreference = "Stop"

& "$PSScriptRoot\tools\build.ps1" -InstallMissing:$InstallMissing
