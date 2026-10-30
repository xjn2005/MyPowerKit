$ErrorActionPreference = 'Stop'

function Assert-True {
    param(
        [Parameter(Mandatory)]
        [bool] $Condition,

        [Parameter(Mandatory)]
        [string] $Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$installerPath = Join-Path $repositoryRoot 'install.ps1'

if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    throw "Installer not found: $installerPath"
}

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("scripts-profile-test-" + [guid]::NewGuid().ToString('N'))
$testProfile = Join-Path $testRoot 'Microsoft.PowerShell_profile.ps1'
$startMarker = '# >>> scripts utilities >>>'
$endMarker = '# <<< scripts utilities <<<'
$commands = [ordered]@{
    pcdoctor = 'pc-doctor.ps1'
    memtop    = 'memtop.ps1'
    netcheck  = 'net-check.ps1'
    wslstop   = 'wsl-stop.ps1'
}

try {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
    Set-Content -LiteralPath $testProfile -Value '# existing profile content' -Encoding UTF8

    & $installerPath -ProfilePath $testProfile | Out-Null
    $firstInstall = Get-Content -LiteralPath $testProfile -Raw

    Assert-True ($firstInstall.Contains('# existing profile content')) 'initial installation must preserve existing profile content'
    Assert-True ($firstInstall.Contains($startMarker)) 'initial installation must write the start marker'
    Assert-True ($firstInstall.Contains($endMarker)) 'initial installation must write the end marker'

    foreach ($entry in $commands.GetEnumerator()) {
        $expectedPath = (Resolve-Path -LiteralPath (Join-Path (Join-Path $repositoryRoot 'powershell') $entry.Value)).Path
        Assert-True ($firstInstall.Contains("function $($entry.Key)")) "profile must define $($entry.Key)"
        Assert-True ($firstInstall.Contains($expectedPath)) "profile must use the resolved path for $($entry.Key)"
    }

    Add-Content -LiteralPath $testProfile -Value '# user content after managed block' -Encoding UTF8
    & $installerPath -ProfilePath $testProfile | Out-Null
    $secondInstall = Get-Content -LiteralPath $testProfile -Raw

    Assert-True ($secondInstall.Contains('# existing profile content')) 'repeat installation must preserve content before the managed block'
    Assert-True ($secondInstall.Contains('# user content after managed block')) 'repeat installation must preserve content after the managed block'
    Assert-True (([regex]::Matches($secondInstall, [regex]::Escape($startMarker))).Count -eq 1) 'start marker must occur exactly once'
    Assert-True (([regex]::Matches($secondInstall, [regex]::Escape($endMarker))).Count -eq 1) 'end marker must occur exactly once'

    foreach ($commandName in $commands.Keys) {
        $functionPattern = "(?m)^function $([regex]::Escape($commandName))\s*\{"
        Assert-True (([regex]::Matches($secondInstall, $functionPattern)).Count -eq 1) "$commandName must occur exactly once"
    }

    Push-Location $testRoot
    try {
        . $testProfile

        foreach ($entry in $commands.GetEnumerator()) {
            $expectedPath = (Resolve-Path -LiteralPath (Join-Path (Join-Path $repositoryRoot 'powershell') $entry.Value)).Path
            $functionCommand = Get-Command -Name $entry.Key -CommandType Function
            Assert-True ($functionCommand.ScriptBlock.ToString().Contains($expectedPath)) "$($entry.Key) must resolve correctly outside the repository"
        }
    }
    finally {
        Pop-Location
    }

    Write-Host 'PASS: portable profile installer behavior is correct.'
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
