param(
  [switch]$NoBuild,
  [switch]$Restart,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$AppletArgs
)

$ErrorActionPreference = "Stop"

& "$PSScriptRoot\tools\run.ps1" -NoBuild:$NoBuild -Restart:$Restart @AppletArgs
