# Infinite Expansion - builds the character pictures for the CHARACTER menu.
#
# The setup builds them by itself the first time it installs the mod. This
# console version, started by "Build Character Pictures.cmd", builds them again:
# after a game update, or when the setup could not (the game was running, or
# something failed). It takes a few minutes, because x64-zt loads each zombies
# map to copy its character cards. What it does and why: IXPictures.Core.ps1.
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

$picturesLog = Get-IXPictureLogPath
[IO.File]::WriteAllText($picturesLog, '')

# x64-zt renames the console window it shares with this script.
function Reset-IXTitle {
    try {
        $Host.UI.RawUI.WindowTitle = 'Infinite Expansion - Character Pictures'
    }
    catch {
    }
}

# Steps in color, x64-zt's own lines in gray; everything goes to the log.
$show = {
    param([string]$Text, [bool]$Step)
    if ($Step) {
        Reset-IXTitle
        Write-Host ''
        Write-Host ($Text + '...') -ForegroundColor Magenta
        Write-IXPictureLog $picturesLog ('== ' + $Text)
    }
    else {
        Write-Host ('  ' + $Text) -ForegroundColor DarkGray
        Write-IXPictureLog $picturesLog $Text
    }
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
    Write-IXPictureLog $picturesLog ('Game folder: ' + $GameDir)
    $built = Invoke-IXPictureBuild -GameDir $GameDir -ZoneTool $ZoneTool -Log $show -KeepWork:$KeepWork
    Reset-IXTitle

    Write-Host ''
    Write-Host 'Done.' -ForegroundColor Magenta
    Write-Host ('  ' + $built.Pictures + ' pictures in ' + $built.Pack) -ForegroundColor Green
    foreach ($failure in $built.Failed) {
        Write-Host ('  ' + $failure + '; the cards it did not copy are skipped.') -ForegroundColor Yellow
    }
    if ($built.Missing.Count -gt 0) {
        Write-Host ('  ' + $built.Missing.Count + ' cards could not be copied; the menu shows initials for those. Details: ' + $picturesLog) -ForegroundColor Yellow
    }
    Write-Host '  Start the game: the CHARACTER menu now shows the cards.' -ForegroundColor Green
    $exitCode = 0
}
catch {
    Reset-IXTitle
    Write-Host ''
    Write-Host ('Could not build the pictures: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Details: ' + $picturesLog) -ForegroundColor Red
    Write-IXPictureLog $picturesLog ('ERROR: ' + $_.Exception.Message)
    Write-IXPictureLog $picturesLog ($_.ScriptStackTrace)
}

if (-not $NoPause) {
    Write-Host ''
    Read-Host 'Press Enter to close' | Out-Null
}
exit $exitCode
