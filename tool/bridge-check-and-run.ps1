param(
  [switch]$SkipInstall,
  [switch]$SkipRun,
  [switch]$AllFiles,
  [ValidateSet('dev', 'start')]
  [string]$RunScript = 'dev'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [string[]]$Arguments = @()
  )

  Write-Host "==> $Name" -ForegroundColor Cyan
  & $Executable @Arguments

  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE."
  }
}

function Get-ChangedBridgeFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot
  )

  $trackedOutput = & git -C $RepositoryRoot diff --name-only --diff-filter=ACMR
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read tracked bridge file changes from git.'
  }

  $untrackedOutput = & git -C $RepositoryRoot ls-files --others --exclude-standard
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read untracked bridge file changes from git.'
  }

  $files = @($trackedOutput + $untrackedOutput) |
    Where-Object {
      $_ -match '^packages/bridge/' -and
      $_ -notmatch '^packages/bridge/(dist|node_modules)/' -and
      $_ -match '\.(ts|js|cjs|mjs|json)$'
    } |
    Sort-Object -Unique

  return @($files)
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$bridgeDir = Join-Path $repoRoot 'packages/bridge'
$nodeModulesDir = Join-Path $bridgeDir 'node_modules'
$changedFiles = @()

if (-not $AllFiles) {
  $changedFiles = @(Get-ChangedBridgeFiles -RepositoryRoot $repoRoot)
}

$relativeChangedFiles = $changedFiles | ForEach-Object { $_ -replace '^packages/bridge/', '' }

Push-Location $bridgeDir
try {
  if (-not $SkipInstall -and -not (Test-Path $nodeModulesDir)) {
    Invoke-Step -Name 'npm ci' -Executable 'npm' -Arguments @('ci')
  }
  elseif (-not $SkipInstall) {
    Write-Host 'node_modules already exists; skipping npm ci. Use a clean install manually when needed.' -ForegroundColor Yellow
  }

  if ($AllFiles) {
    Invoke-Step -Name 'npm run format' -Executable 'npm' -Arguments @('run', 'format')
  }
  elseif ($changedFiles.Count -gt 0) {
    Invoke-Step -Name 'prettier changed files' -Executable 'npm' -Arguments (@('exec', 'prettier', '--', '--write') + $relativeChangedFiles)
  }
  else {
    Write-Host 'No changed bridge files detected; skipping prettier. Use -AllFiles for a project-wide pass.' -ForegroundColor Yellow
  }

  Invoke-Step -Name 'npm run typecheck' -Executable 'npm' -Arguments @('run', 'typecheck')
  Invoke-Step -Name 'npm test -- --passWithNoTests --runInBand' -Executable 'npm' -Arguments @('test', '--', '--passWithNoTests', '--runInBand')
  Invoke-Step -Name 'npm run build' -Executable 'npm' -Arguments @('run', 'build')

  if ($SkipRun) {
    Write-Host 'Skipping npm run because -SkipRun was provided.' -ForegroundColor Yellow
    return
  }

  Invoke-Step -Name "npm run $RunScript" -Executable 'npm' -Arguments @('run', $RunScript)
}
finally {
  Pop-Location
}
