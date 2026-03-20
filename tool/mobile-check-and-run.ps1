param(
  [string]$DeviceId = '',
  [switch]$SkipPubGet,
  [switch]$SkipRun,
  [switch]$StrictAnalyze,
  [switch]$ApplyProjectFixes,
  [switch]$AllFiles,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterRunArgs = @()
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

function Get-ChangedDartFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot
  )

  $trackedOutput = & git -C $RepositoryRoot diff --name-only --diff-filter=ACMR -- ':(glob)apps/mobile/**/*.dart'
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read tracked Dart file changes from git.'
  }

  $untrackedOutput = & git -C $RepositoryRoot ls-files --others --exclude-standard -- ':(glob)apps/mobile/**/*.dart'
  if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read untracked Dart file changes from git.'
  }

  $files = @($trackedOutput + $untrackedOutput) |
    Where-Object { $_ -and $_ -notmatch '\.(g|freezed)\.dart$' } |
    Sort-Object -Unique

  return @($files)
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$appDir = Join-Path $repoRoot 'apps/mobile'
$changedDartFiles = @()

if (-not $AllFiles) {
  $changedDartFiles = @(Get-ChangedDartFiles -RepositoryRoot $repoRoot)
}

$relativeChangedDartFiles = $changedDartFiles | ForEach-Object { $_ -replace '^apps/mobile/', '' }

Push-Location $appDir
try {
  if (-not $SkipPubGet) {
    Invoke-Step -Name 'flutter pub get' -Executable 'flutter' -Arguments @('pub', 'get')
  }

  if ($AllFiles) {
    Invoke-Step -Name 'dart format .' -Executable 'dart' -Arguments @('format', '.')
  }
  elseif ($changedDartFiles.Count -gt 0) {
    Invoke-Step -Name 'dart format changed files' -Executable 'dart' -Arguments (@('format') + $relativeChangedDartFiles)
  }
  else {
    Write-Host 'No changed Dart files detected; skipping dart format. Use -AllFiles for a project-wide pass.' -ForegroundColor Yellow
  }

  if ($ApplyProjectFixes) {
    Invoke-Step -Name 'dart fix --apply' -Executable 'dart' -Arguments @('fix', '--apply')
  }
  else {
    Invoke-Step -Name 'dart fix --dry-run' -Executable 'dart' -Arguments @('fix', '--dry-run')
  }

  $analyzeArguments = @('analyze')
  if (-not $StrictAnalyze) {
    $analyzeArguments += @('--no-fatal-infos', '--no-fatal-warnings')
  }

  if ($AllFiles) {
    Invoke-Step -Name 'flutter analyze' -Executable 'flutter' -Arguments $analyzeArguments
  }
  elseif ($changedDartFiles.Count -gt 0) {
    Invoke-Step -Name 'flutter analyze changed files' -Executable 'flutter' -Arguments ($analyzeArguments + $relativeChangedDartFiles)
  }
  else {
    Write-Host 'No changed Dart files detected; skipping flutter analyze. Use -AllFiles for a project-wide pass.' -ForegroundColor Yellow
  }

  if ($SkipRun) {
    Write-Host 'Skipping flutter run because -SkipRun was provided.' -ForegroundColor Yellow
    return
  }

  $runArguments = @('run')
  if ($DeviceId) {
    $runArguments += @('-d', $DeviceId)
  }
  if ($FlutterRunArgs.Count -gt 0) {
    $runArguments += $FlutterRunArgs
  }

  Invoke-Step -Name 'flutter run' -Executable 'flutter' -Arguments $runArguments
}
finally {
  Pop-Location
}
