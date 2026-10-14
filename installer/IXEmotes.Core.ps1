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

# Builds the proof pack from start to end: x64-zt from GitHub (unless $ZoneTool
# names a zonetool.exe to use), the three x64-zt runs and the build described
# at the top, the install, then the clean-up of x64-zt, its download and its
# work files ($KeepWork keeps the work files). The game must be closed and the
# mod installed. $Log and $Progress work as for Invoke-IXPictureBuild. Throws
# when no pack could be built; nothing is installed then.
function Invoke-IXEmoteProofBuild {
    param([string]$GameDir, [string]$ZoneTool, [scriptblock]$Log, $Progress, [switch]$KeepWork)
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

        & $report 'Copying the animation' $true
        $commands = @(('loadzone ' + $found.Zone), ('loadzone ' + $found.Zone), ('dumpasset ' + $found.Type + ' ' + $found.Name), 'quit')
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

        & $report 'Building the emote pack' $true
        $folder = Join-IXPath $GameDir @('zonetool', $IXEmoteZone, 'xanim')
        if ([IO.Directory]::Exists($folder)) {
            [IO.Directory]::Delete($folder, $true)
        }
        Copy-IXXabRenamed $dumped $folder $proof.Asset | Out-Null
        $csvFolder = Join-IXPath $GameDir @('zone_source')
        [IO.Directory]::CreateDirectory($csvFolder) | Out-Null
        $rows = @('// Infinite Expansion custom emotes, built by installer\IXEmotes.ps1', ($found.Type + ',' + $proof.Asset))
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
        $verified = $false
        $listed = @(Read-IXZoneAssetList $GameDir $IXEmoteZone)
        if ($listed.Count -gt 0) {
            $match = @($listed | Where-Object { $_.Type -eq $found.Type -and $_.Name -eq $proof.Asset })
            if ($match.Count -eq 0) {
                throw ('The built emote pack does not hold ' + $proof.Asset + '; it was not installed.')
            }
            $verified = $true
        }
        else {
            & $report ('x64-zt did not find ' + $IXEmoteZone + ' to list it; the pack is installed unchecked') $false
        }

        $emote = [pscustomobject]@{
            Id       = $proof.Id
            Asset    = $proof.Asset
            Seconds  = $header.Seconds
            Loop     = $false
            Category = 'Custom'
            Wheel    = $proof.Wheel
            Name     = $proof.Name
        }
        $pack = Install-IXEmotePack $GameDir $built @($emote)
        return [pscustomobject]@{
            Pack     = $pack
            List     = (Get-IXEmoteListPath $GameDir)
            Source   = $found.Name
            Zone     = $found.Zone
            Type     = $found.Type
            Seconds  = $header.Seconds
            Bones    = $bones
            Verified = $verified
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
