$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location $repoRoot
try {
  git config core.hooksPath .githooks
  Write-Host 'Configured git hooks path to .githooks' -ForegroundColor Green
}
finally {
  Pop-Location
}
