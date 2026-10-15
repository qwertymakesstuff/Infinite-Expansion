# Infinite Expansion - builds the custom emotes pack, started by
# "Build Custom Emotes.cmd".
#
# Your animations go in <game>\iw7-mod\emotes\, listed in emotes.txt there
# (this script creates it with its instructions): each is put on the game's
# body rig and built into iw7-mod\zone\ix_emotes.ff, and the mod plays it on a
# copy of your character from the Emotes page's Custom category (step 2).
# Before anything is built, the converter must read and write back the game's
# own animations byte for byte. With no animations listed it builds the test
# emote instead: one of the game's own character animations (the Hoff at his
# decks) under a new name (step 1). It takes a few minutes, because x64-zt
# loads Spaceland's zone. What it does and why: IXEmotes.Core.ps1.
#
#   -GameDir <folder>    the game folder (found through Steam when left out)
#   -ZoneTool <file>     a zonetool.exe to use instead of downloading x64-zt
#   -KeepWork            keep x64-zt's dump\, zonetool\ and zone_source\ files
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
. (Join-Path $PSScriptRoot 'IXEmotes.Core.ps1')

$emotesLog = Get-IXEmoteLogPath
[IO.File]::WriteAllText($emotesLog, '')

# x64-zt renames the console window it shares with this script.
function Reset-IXTitle {
    try {
        $Host.UI.RawUI.WindowTitle = 'Infinite Expansion - Custom Emotes'
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
        Write-IXPictureLog $emotesLog ('== ' + $Text)
    }
    else {
        Write-Host ('  ' + $Text) -ForegroundColor DarkGray
        Write-IXPictureLog $emotesLog $Text
    }
}

$exitCode = 1
Write-Host 'INFINITE EXPANSION - CUSTOM EMOTES' -ForegroundColor Cyan
try {
    Enable-IXTls12
    if (-not $GameDir) {
        $GameDir = Find-IXGameDir
    }
    if (-not $GameDir -or -not (Test-IXGameDir $GameDir)) {
        throw 'Infinite Warfare was not found. Run it again with -GameDir "<the folder with iw7_ship.exe>".'
    }
    Write-IXPictureLog $emotesLog ('Game folder: ' + $GameDir)
    $manifest = Initialize-IXEmoteManifest $GameDir
    $emotes = @(Read-IXEmoteManifest $GameDir)
    if ($emotes.Count -eq 0) {
        Write-Host ('No animations are listed in ' + $manifest + ', so this builds the test emote (a game animation).') -ForegroundColor Cyan
    }
    else {
        Write-Host ('Your animations, from ' + $manifest + ':') -ForegroundColor Cyan
        foreach ($emote in $emotes) {
            Write-Host ('  ' + $emote.Id + '  ' + $emote.File + ' -> ' + $emote.Name + ' (' + $(if ($emote.Loop) { 'loops' } else { 'plays once' }) + ')') -ForegroundColor Cyan
            Write-IXPictureLog $emotesLog ('emote ' + $emote.Id + ': ' + $emote.File + ', loop ' + $emote.Loop + ', wheel "' + $emote.Wheel + '", menu "' + $emote.Name + '"')
        }
    }
    $built = Invoke-IXEmoteBuild -GameDir $GameDir -ZoneTool $ZoneTool -Log $show -KeepWork:$KeepWork -Emotes $emotes
    Reset-IXTitle

    Write-Host ''
    Write-Host 'Done.' -ForegroundColor Magenta
    if ($built.Custom) {
        foreach ($emote in @($built.Emotes)) {
            Write-Host ('  ' + $emote.Name + ' (' + $emote.Asset + ', ' + (Format-IXSeconds $emote.Seconds) + ' s, ' + $(if ($emote.Loop) { 'loops' } else { 'plays once' }) + ') is in ' + $built.Pack) -ForegroundColor Green
        }
        Write-Host ('  What was checked and how each bone was put on the game''s rig: ' + $emotesLog) -ForegroundColor Green
    }
    else {
        Write-Host ('  ' + $built.Source + ' (' + $built.Zone + ', ' + (Format-IXSeconds $built.Seconds) + ' s) is now ix_emote_proof in ' + $built.Pack) -ForegroundColor Green
        Write-Host ('  Its ' + @($built.Bones).Count + ' bone names (the body rig to animate) are in ' + $emotesLog) -ForegroundColor Green
    }
    if (-not $built.Verified) {
        Write-Host '  x64-zt could not list the new pack to check it; it is installed unchecked.' -ForegroundColor Yellow
    }
    $first = @($built.Emotes)[0]
    Write-Host ('  Start the game: Emotes > Browse emotes > Custom > ' + $first.Name + '.') -ForegroundColor Green
    $exitCode = 0
}
catch {
    Reset-IXTitle
    Write-Host ''
    Write-Host ('Could not build the emotes: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Details: ' + $emotesLog) -ForegroundColor Red
    Write-IXPictureLog $emotesLog ('ERROR: ' + $_.Exception.Message)
    Write-IXPictureLog $emotesLog ($_.ScriptStackTrace)
}

if (-not $NoPause) {
    Write-Host ''
    Read-Host 'Press Enter to close' | Out-Null
}
exit $exitCode
