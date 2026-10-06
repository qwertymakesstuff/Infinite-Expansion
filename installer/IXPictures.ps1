# Infinite Expansion - builds the character pictures for the CHARACTER menu.
#
# Started by "Build Character Pictures.cmd" next to the setup. Run it once
# after installing the mod (and again after the game updates its files); it
# takes a few minutes, because x64-zt loads each zombies map to copy its
# character cards. What it does and why: IXPictures.Core.ps1.
#
#   -GameDir <folder>    the game folder (found through Steam when left out)
#   -ZoneTool <file>     a zonetool.exe to use instead of downloading x64-zt
#   -KeepWork            keep x64-zt's dump\ and zonetool\ files, for fixing problems
#   -NoPause             do not wait for Enter at the end

param(
    [string]$GameDir,
    [string]$ZoneTool,
    [switch]$KeepWork,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'IXSetup.Core.ps1')
. (Join-Path $PSScriptRoot 'IXPictures.Core.ps1')

$logPath = Join-Path ([IO.Path]::GetTempPath()) 'InfiniteExpansionPictures.log'
[IO.File]::WriteAllText($logPath, '')

function Write-IXLog {
    param([string]$Text)
    [IO.File]::AppendAllText($logPath, $Text + "`r`n")
}

function Write-IXStep {
    param([string]$Text)
    Write-Host ''
    Write-Host $Text -ForegroundColor Magenta
    Write-IXLog ('== ' + $Text)
}

# x64-zt renames the console window it shares with this script.
function Reset-IXTitle {
    try {
        $Host.UI.RawUI.WindowTitle = 'Infinite Expansion - Character Pictures'
    }
    catch {
    }
}

$printLine = {
    param([string]$Line)
    Write-Host ('  ' + $Line) -ForegroundColor DarkGray
    Write-IXLog $Line
}

$exitCode = 1
Write-Host 'INFINITE EXPANSION - CHARACTER PICTURES' -ForegroundColor Cyan
try {
    Enable-IXTls12
    if (-not $GameDir) {
        $GameDir = Find-IXGameDir
    }
    if (-not $GameDir -or -not (Test-IXGameDir $GameDir)) {
        throw 'Infinite Warfare was not found. Run it again with -GameDir "<the folder with iw7_ship.exe>".'
    }
    Write-IXLog ('Game folder: ' + $GameDir)
    if (Test-IXGameRunning) {
        throw 'Close Infinite Warfare first.'
    }
    $menuScript = Join-IXPath (Get-IXTarget $GameDir) @('ui_scripts', 'InfiniteExpansion', '__init__.lua')
    if (-not [IO.File]::Exists($menuScript)) {
        throw 'Install Infinite Expansion first (Infinite Expansion Setup.cmd). The pictures are for its CHARACTER menu.'
    }

    $downloadDir = $null
    if (-not $ZoneTool) {
        Write-IXStep 'Downloading x64-zt (the fastfile tool iw7-mod''s documentation uses)...'
        $source = Get-IXZoneToolFromGitHub
        Write-IXLog ('x64-zt: ' + $source.Url + ' sha256=' + $source.Hash)
        $downloadDir = Join-Path ([IO.Path]::GetTempPath()) 'InfiniteExpansionZoneTool'
        $ZoneTool = Save-IXZoneTool $downloadDir $source
    }
    $exe = Join-IXPath $GameDir @($IXZoneToolCopyName)
    [IO.File]::Copy($ZoneTool, $exe, $true)

    $before = @(Get-IXZoneToolFiles $GameDir)
    $plan = Get-IXPicturePlan $GameDir
    try {
        # One x64-zt run per map: a map that is not installed, or that x64-zt
        # fails on, only costs its own cards.
        $runs = @(Get-IXPictureDumpRuns $plan)
        $step = 0
        foreach ($run in $runs) {
            $step++
            Write-IXStep ('Copying the character cards of ' + $run.Title + ' (' + $step + ' of ' + $runs.Count + ')...')
            try {
                $result = Invoke-IXZoneTool $GameDir $exe @('-dds', '-unbuffered-io') $run.Commands $printLine
                Write-IXLog ('x64-zt exit code: ' + $result.ExitCode)
                if ($result.ExitCode -ne 0) {
                    Write-Host ('  ' + $run.Title + ': x64-zt stopped early (exit code ' + $result.ExitCode + '); the cards it did not copy are skipped.') -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host ('  ' + $run.Title + ': ' + $_.Exception.Message) -ForegroundColor Yellow
                Write-IXLog ('x64-zt failed on ' + $run.Map + ': ' + $_.Exception.Message)
            }
            Reset-IXTitle
        }

        Write-IXStep 'Preparing the picture pack...'
        $prepared = New-IXPictureSource $GameDir $plan
        foreach ($name in $prepared.Missing) {
            Write-IXLog ('not dumped: ' + $name)
        }
        if (@($prepared.Materials).Count -eq 0) {
            throw 'x64-zt copied none of the cards; see the log.'
        }

        Write-IXStep 'Building ix_portraits.ff...'
        $stale = Find-IXBuiltPictureZone $GameDir
        if ($stale) {
            [IO.File]::Delete($stale)
        }
        $build = Invoke-IXZoneTool $GameDir $exe @('-buildzone', $IXPictureZone, '-unbuffered-io') @() $printLine
        Write-IXLog ('x64-zt exit code: ' + $build.ExitCode)
        Reset-IXTitle
        $built = Find-IXBuiltPictureZone $GameDir
        if (-not $built) {
            throw 'x64-zt did not build the picture pack; see the log.'
        }
        $pack = Install-IXPicturePack $GameDir $built $prepared.Materials
    }
    finally {
        if ([IO.File]::Exists($exe)) {
            [IO.File]::Delete($exe)
        }
        if ($downloadDir -and [IO.Directory]::Exists($downloadDir)) {
            [IO.Directory]::Delete($downloadDir, $true)
        }
        if (-not $KeepWork) {
            $removed = Remove-IXZoneToolWork $GameDir $before
            Write-IXLog ('work files removed: ' + $removed)
        }
    }

    Write-IXStep 'Done.'
    Write-Host ('  ' + @($prepared.Materials).Count + ' pictures in ' + $pack) -ForegroundColor Green
    if (@($prepared.Missing).Count -gt 0) {
        Write-Host ('  ' + @($prepared.Missing).Count + ' cards could not be copied; the menu shows initials for those. Details: ' + $logPath) -ForegroundColor Yellow
    }
    Write-Host '  Start the game: the CHARACTER menu now shows the cards.' -ForegroundColor Green
    $exitCode = 0
}
catch {
    Write-Host ''
    Write-Host ('Could not build the pictures: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Details: ' + $logPath) -ForegroundColor Red
    Write-IXLog ('ERROR: ' + $_.Exception.Message)
    Write-IXLog ($_.ScriptStackTrace)
}

if (-not $NoPause) {
    Write-Host ''
    Read-Host 'Press Enter to close' | Out-Null
}
exit $exitCode
