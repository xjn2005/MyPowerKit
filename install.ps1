[CmdletBinding()]
param(
    [Parameter()]
    [string] $ProfilePath = $PROFILE
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$commands = [ordered]@{
    pcdoctor = 'pc-doctor.ps1'
    memtop    = 'memtop.ps1'
    netcheck  = 'net-check.ps1'
    wslstop   = 'wsl-stop.ps1'
}

$scriptsDirectory = Join-Path $PSScriptRoot 'powershell'
$resolvedCommands = [ordered]@{}

foreach ($entry in $commands.GetEnumerator()) {
    $scriptPath = Join-Path $scriptsDirectory $entry.Value

    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "Required script not found: $scriptPath"
    }

    $resolvedCommands[$entry.Key] = (Resolve-Path -LiteralPath $scriptPath).Path
}

$startMarker = '# >>> scripts utilities >>>'
$endMarker = '# <<< scripts utilities <<<'
$newLine = [Environment]::NewLine
$functionLines = foreach ($entry in $resolvedCommands.GetEnumerator()) {
    $escapedPath = $entry.Value.Replace("'", "''")
    "function $($entry.Key) { & '$escapedPath' @args }"
}
$managedBlock = @($startMarker) + @($functionLines) + @($endMarker) -join $newLine

$resolvedProfilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilePath)
$profileDirectory = Split-Path -Parent $resolvedProfilePath

if (-not (Test-Path -LiteralPath $profileDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
}

$existingContent = if (Test-Path -LiteralPath $resolvedProfilePath -PathType Leaf) {
    [System.IO.File]::ReadAllText($resolvedProfilePath)
}
else {
    ''
}

$managedBlockPattern = '(?ms)^[\t ]*' + [regex]::Escape($startMarker) + '[\t ]*\r?\n.*?^[\t ]*' + [regex]::Escape($endMarker) + '[\t ]*(?:\r?\n)?'
$managedBlockRegex = [regex]::new($managedBlockPattern)

if ($managedBlockRegex.IsMatch($existingContent)) {
    $updatedContent = $managedBlockRegex.Replace($existingContent, $managedBlock + $newLine, 1)
}
elseif ([string]::IsNullOrEmpty($existingContent)) {
    $updatedContent = $managedBlock + $newLine
}
else {
    $separator = if ($existingContent.EndsWith("`r") -or $existingContent.EndsWith("`n")) {
        ''
    }
    else {
        $newLine
    }

    $updatedContent = $existingContent + $separator + $managedBlock + $newLine
}

$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($resolvedProfilePath, $updatedContent, $utf8WithoutBom)

Write-Host "PowerShell commands installed in: $resolvedProfilePath"
Write-Host 'Run the following command to load them in this session:'
Write-Host '. $PROFILE'
