# Infinite Expansion - custom emotes, without any window.
#
# A custom emote is an animation played on a copy of the player's character
# (custom_scripts\ix\fun\emote_custom.gsc). The animation must be inside a
# zone the game has loaded, so this builds one, iw7-mod\zone\ix_emotes.ff, on
# the player's PC, with x64-zt (github.com/Joelrau/x64-zt), and writes next
# to it the list the menu script reads (ix_emotes.txt).
#
# Step 1 of the custom emotes is a proof that uses none of the player's own
# art: the build copies one of the game's own character animations, one the
# stock scripts already play on a character model, under a new name:
#
#   1. x64-zt runs in the game folder and lists the zones that should hold it
#      ("dumpcsv <zone>": every asset of the zone as "<type>,<name>", with the
#      game's own name for each asset type), which also gives the name IW7
#      uses for animations; nothing is guessed.
#   2. A second run loads that zone and dumps the animation in x64-zt's own
#      .xab format ("dumpasset <type> <name>", to dump\assets\xanim\). Unlike
#      an image's pixels, an animation lives in the zone's permanent memory
#      (x64-zt's xanim_parts::write streams all of it into
#      XFILE_BLOCK_VIRTUAL), so it can be dumped after the load.
#   3. The copy gets the new name (ix_emote_proof), in the file name, which is
#      the name x64-zt gives the asset (xanim_parts::name, write), and in the
#      name stored inside the file. x64-zt builds the zone from it.
#   4. A third run loads the new zone and lists it, to prove that it loads and
#      holds the animation under the new name, before it is installed.
#
# Nothing of the game's art ships with the mod: every player builds the pack
# from their own copy of the game. Dot-sourced after IXSetup.Core.ps1 and
# IXPictures.Core.ps1 (x64-zt's download and console) by IXEmotes.ps1 and by
# tools/tests/test_installer.py. Windows PowerShell 5.1 compatible and ASCII
# only, like IXSetup.Core.ps1.

# The proof's animation: the Hoff working his decks, which Spaceland's DJ booth
# plays on his full-body model (scripts\cp\maps\cp_zmb\cp_zmb_dj.gsc dj_idle,
# precached in cp_zmb.gsc precache()). Looked for in Spaceland's zone, then its
# patch, whose assets replace the zone's.
$IXEmoteProof = [pscustomobject]@{
    Source = 'iw7_cp_zom_hoff_dj_desk_01'
    Zones  = @('cp_zmb', 'patch_cp_zmb')
    Asset  = 'ix_emote_proof'
    Id     = 'u1'
    Wheel  = 'Hoff decks'
    Name   = 'Test - Hoff at the decks'
}
# x64-zt's own dump format (utils\io\assetmanager.hpp): a type byte, an
# "existing" byte, then the data. dump_single() is an array of one.
$IXDumpTypeArray = 8
$IXDumpTypeString = 6
# IW7's XAnimParts (x64-zt zonetool\iw7\structs.hpp): 0x88 bytes, framerate (a
# float) at 100, numframes (16 bits) at 116, flags at 118 (ANIM_LOOP = 1).
$IXXAnimPartsSize = 136

# The log of the last emote build.
function Get-IXEmoteLogPath {
    return Join-Path ([IO.Path]::GetTempPath()) 'InfiniteExpansionEmotes.log'
}

# The assets x64-zt listed for a zone ("dumpcsv <zone>" writes
# dump\<zone>\<zone>.csv, one "<type>,<name>" per asset), or none.
function Read-IXZoneAssetList {
    param([string]$GameDir, [string]$Zone)
    $rows = @()
    $path = Join-IXPath $GameDir @('dump', $Zone, ($Zone + '.csv'))
    if (-not [IO.File]::Exists($path)) {
        return $rows
    }
    foreach ($line in [IO.File]::ReadAllLines($path)) {
        $comma = $line.IndexOf(',')
        if ($comma -gt 0) {
            $rows += [pscustomobject]@{ Type = $line.Substring(0, $comma); Name = $line.Substring($comma + 1).Trim() }
        }
    }
    return $rows
}

# Where an asset is: the last of $Zones whose list names it (ignoring case,
# as the game does), with the type and the exact name the list gives; or $null.
function Find-IXZoneAsset {
    param([string]$GameDir, [string[]]$Zones, [string]$Name)
    $found = $null
    foreach ($zone in @($Zones)) {
        foreach ($row in @(Read-IXZoneAssetList $GameDir $zone)) {
            if ($row.Name -ieq $Name) {
                $found = [pscustomobject]@{ Zone = $zone; Type = $row.Type; Name = $row.Name }
            }
        }
    }
    return $found
}

# Reads the start of an animation dumped by x64-zt (xanim_parts::dump): the
# XAnimParts as an array of one, then its name as a string. Throws when the
# file is not laid out that way.
function Read-IXXabHeader {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    $nameAt = 6 + $IXXAnimPartsSize
    if ($bytes.Length -lt $nameAt + 3 -or $bytes[0] -ne $IXDumpTypeArray -or $bytes[1] -ne 1 -or [BitConverter]::ToUInt32($bytes, 2) -ne 1) {
        throw ([IO.Path]::GetFileName($Path) + ' is not an animation as x64-zt dumps it.')
    }
    if ($bytes[$nameAt] -ne $IXDumpTypeString -or $bytes[$nameAt + 1] -ne 1) {
        throw ([IO.Path]::GetFileName($Path) + ' has no name where x64-zt writes it.')
    }
    $end = [Array]::IndexOf($bytes, [byte]0, $nameAt + 2)
    if ($end -lt 0) {
        throw ([IO.Path]::GetFileName($Path) + ' ends inside its name.')
    }
    $framerate = [BitConverter]::ToSingle($bytes, 6 + 100)
    $frames = [BitConverter]::ToUInt16($bytes, 6 + 116)
    $seconds = 0
    if ($framerate -gt 0) {
        $seconds = $frames / $framerate
    }
    return [pscustomobject]@{
        Name      = [Text.Encoding]::ASCII.GetString($bytes, $nameAt + 2, $end - $nameAt - 2)
        Framerate = $framerate
        Frames    = $frames
        Loop      = (($bytes[6 + 118] -band 1) -ne 0)
        Seconds   = $seconds
        NameStart = $nameAt + 2
        NameEnd   = $end
    }
}

# The bone names of a dumped animation: they follow its name, boneCount[9] of
# them (struct byte 128) when its bone list (the pointer at 8) is set, each a
# string or a reference back to an earlier string (xanim_parts::dump,
# assetmanager.hpp dump_string). These are the skeleton's own bone names, from
# the player's own game files.
function Read-IXXabBones {
    param([string]$Path)
    $header = Read-IXXabHeader $Path
    $bytes = [IO.File]::ReadAllBytes($Path)
    $bones = @()
    if ([BitConverter]::ToUInt64($bytes, 6 + 8) -eq 0) {
        return $bones
    }
    $count = $bytes[6 + 128]
    # What the file has stored so far, in order: the parts, then the name.
    $entries = @($null, $header.Name)
    $at = $header.NameEnd + 1
    for ($i = 0; $i -lt $count; $i++) {
        if ($at + 2 -gt $bytes.Length) {
            throw ([IO.Path]::GetFileName($Path) + ' ends inside its bone names.')
        }
        $kind = $bytes[$at]
        if ($kind -eq $IXDumpTypeString -and $bytes[$at + 1] -eq 1) {
            $end = [Array]::IndexOf($bytes, [byte]0, $at + 2)
            if ($end -lt 0) {
                throw ([IO.Path]::GetFileName($Path) + ' ends inside a bone name.')
            }
            $bone = [Text.Encoding]::ASCII.GetString($bytes, $at + 2, $end - $at - 2)
            $entries += $bone
            $bones += $bone
            $at = $end + 1
        }
        elseif ($kind -eq 9 -and $at + 9 -le $bytes.Length) {
            $index = [BitConverter]::ToUInt32($bytes, $at + 1)
            $offset = [BitConverter]::ToUInt32($bytes, $at + 5)
            if ($index -ge $entries.Count -or $null -eq $entries[$index]) {
                throw ([IO.Path]::GetFileName($Path) + ' refers to a bone name it does not have.')
            }
            $bones += ([string]$entries[$index]).Substring($offset)
            $at += 9
        }
        else {
            throw ([IO.Path]::GetFileName($Path) + ' has no bone name where x64-zt writes one.')
        }
    }
    return $bones
}

# Copies a dumped animation under a new name: the file is named after it, and
# the name inside it is replaced. Later parts of the file refer back to
# earlier ones by their order, never by byte offset (assetmanager.hpp
# DUMP_TYPE_OFFSET), so a name of another length leaves them valid.
function Copy-IXXabRenamed {
    param([string]$Source, [string]$Folder, [string]$Name)
    $header = Read-IXXabHeader $Source
    $bytes = [IO.File]::ReadAllBytes($Source)
    $stream = New-Object IO.MemoryStream
    $stream.Write($bytes, 0, $header.NameStart)
    $nameBytes = [Text.Encoding]::ASCII.GetBytes($Name)
    $stream.Write($nameBytes, 0, $nameBytes.Length)
    $stream.Write($bytes, $header.NameEnd, $bytes.Length - $header.NameEnd)
    [IO.Directory]::CreateDirectory($Folder) | Out-Null
    $target = Join-IXPath $Folder @($Name + '.xab')
    [IO.File]::WriteAllBytes($target, $stream.ToArray())
    $stream.Dispose()
    return $target
}

# The animation x64-zt dumped: dump\assets\xanim\<name>.xab, found ignoring case.
function Find-IXDumpedAnimation {
    param([string]$GameDir, [string]$Name)
    $folder = Join-IXPath $GameDir @('dump', 'assets', 'xanim')
    if ([IO.Directory]::Exists($folder)) {
        foreach ($path in [IO.Directory]::GetFiles($folder, '*.xab')) {
            if ([IO.Path]::GetFileNameWithoutExtension($path) -ieq $Name) {
                return $path
            }
        }
    }
    return $null
}

# Seconds as the list writes them, whatever the PC's language: 5.033.
function Format-IXSeconds {
    param([double]$Seconds)
    return [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0:0.###}', $Seconds)
}

# The list line the menu script reads (ui_scripts\InfiniteExpansion\__init__.lua):
# id|animation|seconds|loop|category|wheel name|menu name
function Format-IXEmoteLine {
    param($Emote)
    $loop = '0'
    if ($Emote.Loop) {
        $loop = '1'
    }
    return (@($Emote.Id, $Emote.Asset, (Format-IXSeconds $Emote.Seconds), $loop, $Emote.Category, $Emote.Wheel, $Emote.Name) -join '|')
}

# Where x64-zt saved the built zone: zone\ when the game has that folder, else
# the game folder (filesystem.cpp get_zone_path, zone_buffer::save).
function Find-IXBuiltEmoteZone {
    param([string]$GameDir)
    foreach ($candidate in @((Join-IXPath $GameDir @('zone', ($IXEmoteZone + '.ff'))), (Join-IXPath $GameDir @($IXEmoteZone + '.ff')))) {
        if ([IO.File]::Exists($candidate)) {
            return $candidate
        }
    }
    return $null
}

# Moves the built zone into <game>\iw7-mod\zone\ and writes the list next to it.
function Install-IXEmotePack {
    param([string]$GameDir, [string]$Built, $Emotes)
    $destination = Get-IXEmotePackPath $GameDir
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    [IO.File]::Copy($Built, $destination, $true)
    [IO.File]::Delete($Built)
    $lines = @('# Infinite Expansion custom emotes, built by Build Custom Emotes. One per line:', '# id|animation|seconds|loop|category|wheel name|menu name')
    foreach ($emote in @($Emotes)) {
        $lines += Format-IXEmoteLine $emote
    }
    [IO.File]::WriteAllText((Get-IXEmoteListPath $GameDir), (($lines -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding $false))
    return $destination
}

# Your own animations (step 2): the files go in <game>\iw7-mod\emotes\, and
# emotes.txt there lists what to build from them, one per line:
#   file | loop | wheel name | menu name
# The loop has no default: whether an emote loops is decided for each one.
$IXEmoteSourceFolder = 'emotes'
$IXEmoteManifestName = 'emotes.txt'
$IXEmoteMax = 20
# The rig your animations are put on: the body model of a Spaceland player
# (scripts\cp\maps\cp_zmb\cp_zmb_player_character_setup.gsc
# init_player_characters), the first of these the zone listing has; else the
# Hoff's full body at the DJ booth (cp_zmb_dj.gsc: level.dj setmodel), which
# plays the proof's animation in the stock scripts.
$IXEmoteRigModels = @('body_zmb_hero_jock', 'zmb_body_hero_valley_girl', 'zmb_hero_nerd', 'zmb_hero_rapper', 'fullbody_zmb_hero_dj')
# How many more of the zone's animations, besides the proof's, the reader and
# writer must give back byte for byte before anything is built.
$IXEmoteSampleCount = 8

function Get-IXEmoteSourceDir {
    param([string]$GameDir)
    return Join-IXPath (Get-IXTarget $GameDir) @($IXEmoteSourceFolder)
}

# Creates <game>\iw7-mod\emotes\emotes.txt with its instructions, if missing.
function Initialize-IXEmoteManifest {
    param([string]$GameDir)
    $folder = Get-IXEmoteSourceDir $GameDir
    $path = Join-IXPath $folder @($IXEmoteManifestName)
    if (-not [IO.File]::Exists($path)) {
        [IO.Directory]::CreateDirectory($folder) | Out-Null
        $lines = @(
            '# Infinite Expansion custom emotes. Put your animations (.fbx) in this folder',
            '# and list each one here, one per line:',
            '#',
            '#   file | loop | wheel name | menu name',
            '#',
            '#   file        an .fbx in this folder',
            '#   loop        0: plays once; 1: plays again and again until you move',
            '#   wheel name  up to 14 letters, digits, spaces, "." and "-"',
            '#   menu name   up to 27 of the same',
            '#',
            '# For example:',
            '#   DanceMoves.fbx | 0 | Dance Moves | Dance Moves',
            '#',
            '# Then run Build Custom Emotes.cmd. With no lines it builds the test emote.')
        [IO.File]::WriteAllText($path, (($lines -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding $false))
    }
    return $path
}

# The emotes emotes.txt lists, checked: ids u1, u2 ... in order, and an
# animation name for each from its file name. Throws, naming the line, at the
# first line that is not right; none when there is no list.
function Read-IXEmoteManifest {
    param([string]$GameDir)
    $folder = Get-IXEmoteSourceDir $GameDir
    $path = Join-IXPath $folder @($IXEmoteManifestName)
    $emotes = @()
    if (-not [IO.File]::Exists($path)) {
        return $emotes
    }
    $assets = @{}
    $number = 0
    foreach ($raw in [IO.File]::ReadAllLines($path)) {
        $number++
        $line = $raw.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) {
            continue
        }
        $where = $IXEmoteManifestName + ' line ' + $number + ': '
        $fields = @($line.Split('|') | ForEach-Object { $_.Trim() })
        if ($fields.Count -ne 4) {
            throw ($where + 'write it as "file | loop | wheel name | menu name".')
        }
        $file = $fields[0]
        if ($file -notmatch '^[^\\/:*?"<>|]+\.[Ff][Bb][Xx]$') {
            throw ($where + 'the file must be an .fbx in ' + $folder + '.')
        }
        $source = Join-IXPath $folder @($file)
        if (-not [IO.File]::Exists($source)) {
            throw ($where + $file + ' is not in ' + $folder + '.')
        }
        if ($fields[1] -ne '0' -and $fields[1] -ne '1') {
            throw ($where + 'the loop is 0 (plays once) or 1 (loops); there is no default.')
        }
        foreach ($check in @(@('wheel name', $fields[2], 14), @('menu name', $fields[3], 27))) {
            if ($check[1] -cnotmatch '^[A-Za-z0-9 .\-]+$' -or $check[1].Length -gt $check[2]) {
                throw ($where + 'the ' + $check[0] + ' is 1 to ' + $check[2] + ' letters, digits, spaces, "." or "-".')
            }
        }
        if ($emotes.Count -ge $IXEmoteMax) {
            throw ($where + 'at most ' + $IXEmoteMax + ' emotes.')
        }
        $base = ([IO.Path]::GetFileNameWithoutExtension($file).ToLowerInvariant() -replace '[^a-z0-9]+', '_').Trim('_')
        if ($base -eq '') {
            $base = 'emote'
        }
        if ($base.Length -gt 34) {
            $base = $base.Substring(0, 34).TrimEnd('_')
        }
        $asset = 'ix_emote_' + $base
        for ($n = 2; $assets.ContainsKey($asset); $n++) {
            $asset = 'ix_emote_' + $base + '_' + $n
        }
        $assets[$asset] = $true
        $emotes += [pscustomobject]@{
            Id       = 'u' + ($emotes.Count + 1)
            Asset    = $asset
            File     = $file
            Source   = $source
            Seconds  = 0
            Loop     = ($fields[1] -eq '1')
            Category = 'Custom'
            Wheel    = $fields[2]
            Name     = $fields[3]
        }
    }
    return $emotes
}

# Compiles installer\IXEmoteConvert.cs (once per session): with the .NET
# Framework compiler in Windows PowerShell 5.1 (C# 5; mscorlib and System.dll
# hold all it uses), or with PowerShell 7's own, given the .NET assemblies
# that hold the same types there.
function Import-IXEmoteConverter {
    if ('IXEmotes.Converter' -as [type]) {
        return
    }
    $source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'IXEmoteConvert.cs'))
    if ($PSVersionTable.PSEdition -eq 'Core') {
        Add-Type -TypeDefinition $source -ReferencedAssemblies @('System.Collections', 'System.IO.Compression', 'System.Runtime.Extensions') -IgnoreWarnings -WarningAction SilentlyContinue
    }
    else {
        # Windows PowerShell's Add-Type fails on a compiler warning unless told not to.
        Add-Type -TypeDefinition $source -IgnoreWarnings
    }
}

# Runs a call into the converter; its own message, not PowerShell's wrapping
# ("Exception calling ..."), is what goes to the player.
function Invoke-IXEmoteConverter {
    param([scriptblock]$Call)
    try {
        return (& $Call)
    }
    catch {
        $e = $_.Exception
        while ($null -ne $e.InnerException) {
            $e = $e.InnerException
        }
        throw $e.Message
    }
}

# The zone's other animations to check the reader and writer on: up to
# $IXEmoteSampleCount of the same type and zone as the proof's, in the
# listing's order.
function Select-IXEmoteSamples {
    param([string]$GameDir, $Found)
    $samples = @()
    $seen = @{ ($Found.Name.ToLowerInvariant()) = $true }
    foreach ($row in @(Read-IXZoneAssetList $GameDir $Found.Zone)) {
        if ($samples.Count -ge $IXEmoteSampleCount) {
            break
        }
        if ($row.Type -ne $Found.Type -or $seen.ContainsKey($row.Name.ToLowerInvariant())) {
            continue
        }
        $seen[$row.Name.ToLowerInvariant()] = $true
        $samples += $row.Name
    }
    return $samples
}

# The model x64-zt dumped: dump\assets\xmodel\<name>.xmb, found ignoring case.
function Find-IXDumpedModel {
    param([string]$GameDir, [string]$Name)
    $folder = Join-IXPath $GameDir @('dump', 'assets', 'xmodel')
    if ([IO.Directory]::Exists($folder)) {
        foreach ($path in [IO.Directory]::GetFiles($folder, '*.xmb')) {
            if ([IO.Path]::GetFileNameWithoutExtension($path) -ieq $Name) {
                return $path
            }
        }
    }
    return $null
}

# Builds the emote pack from start to end: x64-zt from GitHub (unless
# $ZoneTool names a zonetool.exe to use), its runs and the build, the install,
# then the clean-up of x64-zt, its download and its work files ($KeepWork
# keeps the work files). The game must be closed and the mod installed. $Log
# and $Progress work as for Invoke-IXPictureBuild. Throws when no pack could be
# built; nothing is installed then.
#
# With no $Emotes it builds the proof (step 1, described at the top). With
# $Emotes (Read-IXEmoteManifest), your animations (step 2):
#   1. x64-zt lists Spaceland's zones, as for the proof, which also names a
#      player body model there (the rig) and the zone's other animations.
#   2. It dumps the proof's animation, up to $IXEmoteSampleCount others and the
#      body model.
#   3. Every dumped animation must read and write back byte for byte
#      (IXEmoteConvert.cs Converter.RoundTrip: the parts as xanim_parts::dump
#      writes them, and every data stream read to its end as Greyhound reads
#      IW7's); nothing is built otherwise. What they show about the header
#      fields the converter sets is learned from them (XAnimRules).
#   4. Each of your animations is put on the body model's rig and written as an
#      animation of its own, the proof's header its template, then built.
function Invoke-IXEmoteBuild {
    param([string]$GameDir, [string]$ZoneTool, [scriptblock]$Log, $Progress, [switch]$KeepWork, $Emotes)
    $report = {
        param([string]$Text, [bool]$Step)
        if ($Step -and $null -ne $Progress) {
            $Progress.Phase = $Text
            $Progress.Done = 0
            $Progress.Total = 0
        }
        if ($Log) {
            $null = & $Log $Text $Step
        }
    }.GetNewClosure()
    $lines = {
        param([string]$Line)
        & $report $Line $false
    }.GetNewClosure()

    if (Test-IXGameRunning) {
        throw 'Close Infinite Warfare first: x64-zt cannot run next to the game.'
    }
    $menuScript = Join-IXPath (Get-IXTarget $GameDir) @('ui_scripts', 'InfiniteExpansion', '__init__.lua')
    if (-not [IO.File]::Exists($menuScript)) {
        throw 'Install Infinite Expansion first. The emotes are for its Emotes page.'
    }

    $proof = $IXEmoteProof
    $custom = @($Emotes).Count -gt 0
    if ($custom) {
        Import-IXEmoteConverter
    }
    $exe = Join-IXPath $GameDir @($IXZoneToolCopyName)
    $downloadDir = $null
    $before = $null
    try {
        if (-not $ZoneTool) {
            & $report 'Downloading x64-zt' $true
            Enable-IXTls12
            $source = Get-IXZoneToolFromGitHub
            & $report ('x64-zt: ' + $source.Url + ' sha256=' + $source.Hash) $false
            $downloadDir = Join-Path ([IO.Path]::GetTempPath()) 'InfiniteExpansionZoneTool'
            $ZoneTool = Save-IXZoneTool $downloadDir $source $Progress
        }
        [IO.File]::Copy($ZoneTool, $exe, $true)
        $before = @(Get-IXZoneToolFiles $GameDir)

        & $report ('Looking for the animation ' + $proof.Source) $true
        $commands = @()
        foreach ($zone in $proof.Zones) {
            $commands += 'dumpcsv ' + $zone
        }
        $commands += 'quit'
        $run = Invoke-IXZoneTool $GameDir $exe @('-unbuffered-io') $commands $lines
        & $report ('x64-zt exit code: ' + $run.ExitCode) $false
        $found = Find-IXZoneAsset $GameDir $proof.Zones $proof.Source
        if (-not $found) {
            throw ('x64-zt did not list the animation ' + $proof.Source + ' in ' + ($proof.Zones -join ' or ') + '.')
        }
        & $report ('found: ' + $found.Type + ',' + $found.Name + ' in ' + $found.Zone) $false
        $rigFound = $null
        $samples = @()
        if ($custom) {
            foreach ($model in $IXEmoteRigModels) {
                $rigFound = Find-IXZoneAsset $GameDir $proof.Zones $model
                if ($rigFound) {
                    break
                }
            }
            if (-not $rigFound) {
                throw ('x64-zt did not list a body model to take the rig from (' + ($IXEmoteRigModels -join ', ') + ') in ' + ($proof.Zones -join ' or ') + '.')
            }
            & $report ('body model: ' + $rigFound.Type + ',' + $rigFound.Name + ' in ' + $rigFound.Zone) $false
            $samples = @(Select-IXEmoteSamples $GameDir $found)
            & $report ('animations to check: ' + (@($found.Name) + $samples -join ' ')) $false
        }

        if ($custom) {
            & $report 'Reading the game''s animations and body model' $true
        }
        else {
            & $report 'Copying the animation' $true
        }
        $commands = @(('loadzone ' + $found.Zone), ('loadzone ' + $found.Zone), ('dumpasset ' + $found.Type + ' ' + $found.Name))
        foreach ($sample in $samples) {
            $commands += 'dumpasset ' + $found.Type + ' ' + $sample
        }
        if ($custom) {
            if ($rigFound.Zone -ne $found.Zone) {
                $commands += 'loadzone ' + $rigFound.Zone
            }
            $commands += 'dumpasset ' + $rigFound.Type + ' ' + $rigFound.Name
        }
        $commands += 'quit'
        $run = Invoke-IXZoneTool $GameDir $exe @('-unbuffered-io') $commands $lines
        & $report ('x64-zt exit code: ' + $run.ExitCode) $false
        $dumped = Find-IXDumpedAnimation $GameDir $found.Name
        if (-not $dumped) {
            throw ('x64-zt did not dump the animation ' + $found.Name + '.')
        }
        $header = Read-IXXabHeader $dumped
        & $report ('animation: ' + $header.Name + ', ' + $header.Frames + ' frames at ' + $header.Framerate + ' per second, loop ' + $header.Loop) $false
        $bones = @(Read-IXXabBones $dumped)
        & $report ('bones (' + $bones.Count + '): ' + ($bones -join ' ')) $false
        if ($header.Seconds -le 0) {
            throw ('The animation ' + $found.Name + ' has no length.')
        }

        $folder = Join-IXPath $GameDir @('zonetool', $IXEmoteZone, 'xanim')
        if ($custom) {
            & $report 'Checking the reader and writer on the game''s animations' $true
            $decoded = New-Object 'System.Collections.Generic.List[IXEmotes.XAnim]'
            $failed = @()
            foreach ($name in @($found.Name) + $samples) {
                $path = Find-IXDumpedAnimation $GameDir $name
                if (-not $path) {
                    & $report ('not dumped: ' + $name) $false
                    continue
                }
                $bytes = [IO.File]::ReadAllBytes($path)
                $why = [IXEmotes.Converter]::RoundTrip($bytes, $name)
                if ($null -ne $why) {
                    & $report ('round trip ' + $name + ': ' + $why) $false
                    $failed += $name + ': ' + $why
                    continue
                }
                $anim = Invoke-IXEmoteConverter { [IXEmotes.Converter]::ReadDecoded($bytes, $name) }
                $decoded.Add($anim)
                & $report ('round trip ' + $name + ': identical (' + $bytes.Length + ' bytes, ' + $anim.Rotations.Count + ' rotations, ' + $anim.Translations.Count + ' translations)') $false
            }
            if ($failed.Count -gt 0) {
                throw ('These game animations do not read and write back byte for byte, so the converter is not trusted with yours and nothing was built: ' + ($failed -join '; '))
            }
            if ($decoded.Count -lt 2) {
                throw ('Only ' + $decoded.Count + ' of the game''s animations could be checked; at least 2 are needed.')
            }
            $rules = Invoke-IXEmoteConverter { [IXEmotes.XAnimRules]::Learn($decoded) }
            & $report ('learned from them: ' + $rules.Notes) $false

            $rigPath = Find-IXDumpedModel $GameDir $rigFound.Name
            if (-not $rigPath) {
                throw ('x64-zt did not dump the body model ' + $rigFound.Name + '.')
            }
            $rigBytes = [IO.File]::ReadAllBytes($rigPath)
            $rig = Invoke-IXEmoteConverter { [IXEmotes.Rig]::Read($rigBytes, $rigFound.Name) }
            & $report ('body model bones (' + $rig.Bones.Length + '): ' + ($rig.Bones -join ' ')) $false
            $agree = 0.0
            $compare = [IXEmotes.Converter]::CompareWithRig($decoded[0], $rig, [ref]$agree)
            & $report ('the proof''s animation against the body model''s rest pose: ' + $compare) $false

            & $report 'Converting your animations' $true
            if ([IO.Directory]::Exists($folder)) {
                [IO.Directory]::Delete($folder, $true)
            }
            [IO.Directory]::CreateDirectory($folder) | Out-Null
            $templateBytes = [IO.File]::ReadAllBytes($dumped)
            foreach ($emote in @($Emotes)) {
                & $report ($emote.File + ' -> ' + $emote.Asset) $false
                $fbx = [IO.File]::ReadAllBytes($emote.Source)
                $loop = [bool]$emote.Loop
                try {
                    $result = Invoke-IXEmoteConverter { [IXEmotes.Converter]::Convert($fbx, $rigBytes, $templateBytes, $emote.Asset, $loop, $rules) }
                }
                catch {
                    throw ($emote.File + ': ' + $_.Exception.Message)
                }
                [IO.File]::WriteAllBytes((Join-IXPath $folder @($emote.Asset + '.xab')), $result.Xab)
                $emote.Seconds = $result.Seconds
                & $report ('  ' + $result.Frames + ' frames at ' + (Format-IXSeconds $result.Framerate) + ' per second, ' + (Format-IXSeconds $result.Seconds) + ' s, loop ' + $emote.Loop) $false
                & $report ('  bones (' + @($result.Mapped).Count + '): ' + (@($result.Mapped) -join ' ')) $false
                if (@($result.Unused).Count -gt 0) {
                    & $report ('  animated but not used: ' + (@($result.Unused) -join ' ')) $false
                }
                if (@($result.MissingInRig).Count -gt 0) {
                    & $report ('  not in the body model: ' + (@($result.MissingInRig) -join ' ')) $false
                }
                & $report ('  ' + $result.Report) $false
            }
        }

        & $report 'Building the emote pack' $true
        $rows = @('// Infinite Expansion custom emotes, built by installer\IXEmotes.ps1')
        if ($custom) {
            foreach ($emote in @($Emotes)) {
                $rows += $found.Type + ',' + $emote.Asset
            }
        }
        else {
            if ([IO.Directory]::Exists($folder)) {
                [IO.Directory]::Delete($folder, $true)
            }
            Copy-IXXabRenamed $dumped $folder $proof.Asset | Out-Null
            $rows += $found.Type + ',' + $proof.Asset
        }
        $csvFolder = Join-IXPath $GameDir @('zone_source')
        [IO.Directory]::CreateDirectory($csvFolder) | Out-Null
        [IO.File]::WriteAllText((Join-IXPath $csvFolder @($IXEmoteZone + '.csv')), (($rows -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding $false))
        $stale = Find-IXBuiltEmoteZone $GameDir
        if ($stale) {
            [IO.File]::Delete($stale)
        }
        $build = Invoke-IXZoneTool $GameDir $exe @('-buildzone', $IXEmoteZone, '-unbuffered-io') @() $lines
        & $report ('x64-zt exit code: ' + $build.ExitCode) $false
        $built = Find-IXBuiltEmoteZone $GameDir
        if (-not $built) {
            throw 'x64-zt did not build the emote pack.'
        }

        # The game loads the pack the same way x64-zt does; one that x64-zt
        # cannot load is not installed.
        & $report 'Checking the emote pack' $true
        $check = Invoke-IXZoneTool $GameDir $exe @('-unbuffered-io') @(('dumpcsv ' + $IXEmoteZone), 'quit') $lines
        & $report ('x64-zt exit code: ' + $check.ExitCode) $false
        if ($check.ExitCode -ne 0) {
            throw 'x64-zt could not load the emote pack it built, so it was not installed.'
        }
        $assets = @($proof.Asset)
        if ($custom) {
            $assets = @(@($Emotes) | ForEach-Object { $_.Asset })
        }
        $verified = $false
        $listed = @(Read-IXZoneAssetList $GameDir $IXEmoteZone)
        if ($listed.Count -gt 0) {
            foreach ($asset in $assets) {
                $match = @($listed | Where-Object { $_.Type -eq $found.Type -and $_.Name -eq $asset })
                if ($match.Count -eq 0) {
                    throw ('The built emote pack does not hold ' + $asset + '; it was not installed.')
                }
            }
            $verified = $true
        }
        else {
            & $report ('x64-zt did not find ' + $IXEmoteZone + ' to list it; the pack is installed unchecked') $false
        }

        if ($custom) {
            $installed = @($Emotes)
        }
        else {
            $installed = @([pscustomobject]@{
                    Id       = $proof.Id
                    Asset    = $proof.Asset
                    Seconds  = $header.Seconds
                    Loop     = $false
                    Category = 'Custom'
                    Wheel    = $proof.Wheel
                    Name     = $proof.Name
                })
        }
        $pack = Install-IXEmotePack $GameDir $built $installed
        return [pscustomobject]@{
            Pack     = $pack
            List     = (Get-IXEmoteListPath $GameDir)
            Source   = $found.Name
            Zone     = $found.Zone
            Type     = $found.Type
            Seconds  = $header.Seconds
            Bones    = $bones
            Verified = $verified
            Emotes   = $installed
            Custom   = $custom
        }
    }
    finally {
        # A pack that was built but not installed (its check failed) must not
        # stay in the game's own zone folder.
        try {
            $leftover = Find-IXBuiltEmoteZone $GameDir
            if ($leftover) {
                [IO.File]::Delete($leftover)
            }
        }
        catch {
            & $report ('could not delete the unused pack: ' + $_.Exception.Message) $false
        }
        try {
            if ([IO.File]::Exists($exe)) {
                [IO.File]::Delete($exe)
            }
        }
        catch {
            & $report ('could not delete ' + $exe + ': ' + $_.Exception.Message) $false
        }
        try {
            if ($null -ne $before -and -not $KeepWork) {
                & $report ('work files removed: ' + (Remove-IXZoneToolWork $GameDir $before)) $false
            }
        }
        catch {
            & $report ('could not remove the work files: ' + $_.Exception.Message) $false
        }
        try {
            if ($downloadDir -and [IO.Directory]::Exists($downloadDir)) {
                [IO.Directory]::Delete($downloadDir, $true)
            }
        }
        catch {
            & $report ('could not delete ' + $downloadDir + ': ' + $_.Exception.Message) $false
        }
    }
}

# The proof alone (step 1): Invoke-IXEmoteBuild with no emotes of your own.
function Invoke-IXEmoteProofBuild {
    param([string]$GameDir, [string]$ZoneTool, [scriptblock]$Log, $Progress, [switch]$KeepWork)
    return Invoke-IXEmoteBuild -GameDir $GameDir -ZoneTool $ZoneTool -Log $Log -Progress $Progress -KeepWork:$KeepWork -Emotes @()
}
