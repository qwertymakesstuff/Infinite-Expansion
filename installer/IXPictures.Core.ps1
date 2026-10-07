# Infinite Expansion - character pictures for the CHARACTER menu, without any window.
#
# The game's menus can only draw pictures that are inside a loaded fastfile. The
# in-match character cards are only inside each map's own fastfile, which is
# loaded only during a match (KNOWN_LIMITATIONS.md L28). This builds a small
# fastfile, iw7-mod\zone\ix_portraits.ff, from the player's own game files:
#
#   1. x64-zt (github.com/Joelrau/x64-zt), the fastfile tool iw7-mod's own
#      documentation describes, runs in the game folder once per map. Through
#      its console it dumps one stock menu material as a pattern
#      (zm_character_select_hoff, from techsets_ui_boot) and every image of
#      the map's zones, in its own .iw7Image format, while the zones load.
#      Images can only be dumped then: their pixels are freed once a zone has
#      loaded (IW_API_NOTES.md section 18).
#   2. Each card becomes a material of its own, named ix_card_* / ix_icon_*, so
#      nothing clashes with the game's own names, with the card's .iw7Image
#      renamed to match. The materials refer to the pattern's techset (its
#      shaders, in code_post_gfx) instead of copying it.
#   3. x64-zt builds the zone (-buildzone ix_portraits), and the result goes to
#      <game>\iw7-mod\zone\, where iw7-mod finds custom zones (fastfiles.cpp).
#      The menu script loads it with iw7-mod's loadzone command.
#
# Nothing of the game's art ships with the mod: every player builds the pack
# from their own copy of the game. Dot-sourced after IXSetup.Core.ps1 by
# IXPictures.ps1 and by tools/tests/test_installer.py. Windows PowerShell 5.1
# compatible and ASCII only, like IXSetup.Core.ps1.

$IXPictureTemplate = 'zm_character_select_hoff'
# The zone of its image, then the zone of the material itself: IW7 keeps
# materials in techsets_<zone>, which x64-zt's loadzone does not load by itself.
$IXPictureTemplateZones = @('ui_boot', 'techsets_ui_boot')
$IXZoneToolReleaseApi = 'https://api.github.com/repos/Joelrau/x64-zt/releases/tags/latest'
$IXZoneToolCopyName = 'ix-zonetool.exe'
$IXZoneToolReady = 'initialization complete'

# The log of the last picture build, shared by the setup and the console version.
function Get-IXPictureLogPath {
    return Join-Path ([IO.Path]::GetTempPath()) 'InfiniteExpansionPictures.log'
}

# Appends a line to that log; never fails.
function Write-IXPictureLog {
    param([string]$Path, [string]$Text)
    try {
        [IO.File]::AppendAllText($Path, $Text + "`r`n")
    }
    catch {
    }
}

# The language zones of a map: <xxx>_<map>.ff in the game's zone\ folder or a
# language folder under it (eng_cp_town in English), then their patches
# (<xxx>_patch_<map>), whose images replace the others. eng_<map> and
# eng_patch_<map> when none is found; x64-zt reports a missing zone and skips it.
function Get-IXLanguageZones {
    param([string]$GameDir, [string]$Map)
    $found = @()
    $zoneDir = $null
    if ($GameDir) {
        $zoneDir = Join-IXPath $GameDir @('zone')
    }
    if ($zoneDir -and [IO.Directory]::Exists($zoneDir)) {
        $folders = @($zoneDir) + @([IO.Directory]::GetDirectories($zoneDir))
        foreach ($pattern in @(('^[a-z]{3}_' + [regex]::Escape($Map) + '$'), ('^[a-z]{3}_patch_' + [regex]::Escape($Map) + '$'))) {
            foreach ($folder in $folders) {
                foreach ($path in [IO.Directory]::GetFiles($folder, ('*_' + $Map + '.ff'))) {
                    $name = [IO.Path]::GetFileNameWithoutExtension($path)
                    if ($name -cmatch $pattern -and $found -notcontains $name) {
                        $found += $name
                    }
                }
            }
        }
    }
    if ($found.Count -eq 0) {
        $found = @(('eng_' + $Map), ('eng_patch_' + $Map))
    }
    return $found
}

# The cards to pack: for each map, the zones that hold its cards and, per card,
# the stock image and the material name the pack gives it. The names come from
# the game's cp/zombies/<map>_playercash_images.csv: a team card ("icon") per
# character, and the main card with "team" replaced by "main" (IW_API_NOTES.md
# section 16). Regular characters get one card per map; special characters
# only exist on their own map. Zones are listed so that a later one replaces
# an earlier one's image (patch_cp_zmb holds Willard's cards; Elvira's main card
# is in the language zones of her map, found in $GameDir).
function Get-IXPicturePlan {
    param([string]$GameDir)
    $cast = @('sally', 'poindexter', 'andre', 'aj')
    $maps = @(
        @{ Map = 'cp_zmb'; Title = 'Zombies in Spaceland'; Key = 'zmb'; Zones = @('cp_zmb', 'patch_cp_zmb'); Main = 'zm_pc_score_main_plyr_{0}'; Team = 'zm_pc_score_team_plyr_{0}'; Special = 'hoff' },
        @{ Map = 'cp_rave'; Title = 'Rave in the Redwoods'; Key = 'rave'; Zones = @('cp_rave'); Main = 'zm_main_plyr_{0}_dlc1'; Team = 'zm_team_plyr_{0}_dlc1'; Special = 'kevin' },
        @{ Map = 'cp_disco'; Title = 'Shaolin Shuffle'; Key = 'disco'; Zones = @('cp_disco'); Main = 'zm_main_plyr_{0}_dlc2'; Team = 'zm_team_plyr_{0}_dlc2'; Special = 'pam' },
        @{ Map = 'cp_town'; Title = 'Attack of the Radioactive Thing'; Key = 'town'; Zones = (@('cp_town') + @(Get-IXLanguageZones $GameDir 'cp_town')); Main = 'zm_main_plyr_{0}_dlc3'; Team = 'zm_team_plyr_{0}_dlc3'; Special = 'elvira' },
        @{ Map = 'cp_final'; Title = 'The Beast from Beyond'; Key = 'final'; Zones = @('cp_final'); Main = 'zm_main_plyr_{0}_dlc4'; Team = 'zm_team_plyr_{0}_dlc4'; Special = $null }
    )
    $plan = @()
    foreach ($map in $maps) {
        $images = @()
        for ($slot = 1; $slot -le 4; $slot++) {
            $who = $cast[$slot - 1]
            $images += [pscustomobject]@{ Source = ($map.Main -f $slot); Name = ('ix_card_' + $map.Key + '_' + $who) }
            $images += [pscustomobject]@{ Source = ($map.Team -f $slot); Name = ('ix_icon_' + $map.Key + '_' + $who) }
        }
        if ($map.Special) {
            $images += [pscustomobject]@{ Source = ($map.Main -f 5); Name = ('ix_card_' + $map.Special) }
            $images += [pscustomobject]@{ Source = ($map.Team -f 5); Name = ('ix_icon_' + $map.Special) }
        }
        if ($map.Map -eq 'cp_zmb') {
            # Willard Wyler's cards are in patch_cp_zmb, named after the last map.
            $images += [pscustomobject]@{ Source = 'zm_main_plyr_6_dlc4'; Name = 'ix_card_willard' }
            $images += [pscustomobject]@{ Source = 'zm_team_plyr_6_dlc4'; Name = 'ix_icon_willard' }
        }
        $plan += [pscustomobject]@{ Map = $map.Map; Title = $map.Title; Zones = $map.Zones; Images = $images }
    }
    return $plan
}

# The x64-zt runs that dump the pattern material and every card: one run per
# map, so that a map that fails (not installed, or x64-zt stops) costs only its
# own cards. Each run types its commands into x64-zt's console and quits.
#
# The first run loads the pattern's zones, names the first one again (loadzone
# waits for the loads before it: load_zone, wait_for_database) and dumps the
# material, which lives in permanent zone memory. It must come before any
# dumpzone, whose type filter stays set for the rest of the run
# (asset_type_filter) and would keep a material from being dumped. Images cannot be dumped that
# way: their pixels are in the zone's temporary block, freed after the load,
# and "dumpasset image" then reads freed memory (x64-zt crashed on every map,
# 2026-10-07). "dumpzone iw7 <zone> image" dumps a zone's images while it loads
# and returns when it has (dump_zone), to dump\<zone>\images\<name>.iw7Image.
function Get-IXPictureDumpRuns {
    param($Plan)
    $runs = @()
    $first = $true
    foreach ($map in @($Plan)) {
        $commands = @()
        if ($first) {
            foreach ($zone in $IXPictureTemplateZones) {
                $commands += 'loadzone ' + $zone
            }
            $commands += @(('loadzone ' + $IXPictureTemplateZones[0]), ('dumpasset material ' + $IXPictureTemplate))
            $first = $false
        }
        foreach ($zone in $map.Zones) {
            $commands += 'dumpzone iw7 ' + $zone + ' image'
        }
        $commands += 'quit'
        $runs += [pscustomobject]@{ Map = $map.Map; Title = $map.Title; Commands = $commands }
    }
    return $runs
}

# The dumped image of a card: dump\<zone>\images\<name>.iw7Image from the last
# of $Zones that has it, or $null.
function Find-IXDumpedImage {
    param([string]$GameDir, [string[]]$Zones, [string]$Name)
    $found = $null
    foreach ($zone in @($Zones)) {
        $path = Join-IXPath $GameDir @('dump', $zone, 'images', ($Name + '.iw7Image'))
        if ([IO.File]::Exists($path)) {
            $found = $path
        }
    }
    return $found
}

# Writes x64-zt's build input for the pack from what it dumped:
# zonetool\ix_portraits\ (a material per card, its image as .iw7Image, the
# pattern's techset state files) and zone_source\ix_portraits.csv. Returns the
# materials written and the stock images that were not dumped.
#
# x64-zt reads an image from images\<name>.iw7Image and writes it under that
# name (gfx_image::parse, write), so a renamed copy of the dump becomes the
# card's image: its pixels when the zone holds them, else its place in the
# game's own imagefile*.pak, which the game streams from as for any zone.
#
# The pattern's techset (its shaders) is the game's own, so the pack refers to
# it instead of carrying a copy that would replace the game's for every menu:
# a "techset,,<name>" row, which x64-zt adds as a reference (zonetool.cpp
# parse_csv_file). The "require" rows load the pattern's zones first, so that
# x64-zt finds that techset while it builds.
function New-IXPictureSource {
    param([string]$GameDir, $Plan)
    $dump = Join-IXPath $GameDir @('dump', 'assets')
    $templatePath = Join-IXPath $dump @('materials', ($IXPictureTemplate + '.json'))
    if (-not [IO.File]::Exists($templatePath)) {
        throw "x64-zt did not dump the menu material $IXPictureTemplate, which the pictures are patterned on."
    }
    $templateText = [IO.File]::ReadAllText($templatePath)
    $template = ConvertFrom-Json $templateText
    $templateImage = $null
    foreach ($texture in @($template.textureTable)) {
        if ($texture.image) {
            $templateImage = [string]$texture.image
            break
        }
    }
    if (-not $templateImage) {
        throw "The dumped material $IXPictureTemplate has no image to replace."
    }
    $quoted = '"' + $templateImage + '"'
    $techset = [string]$template.'techniqueSet->name'

    $source = Join-IXPath $GameDir @('zonetool', $IXPictureZone)
    if ([IO.Directory]::Exists($source)) {
        [IO.Directory]::Delete($source, $true)
    }
    $materials = Join-IXPath $source @('materials')
    $images = Join-IXPath $source @('images')
    [IO.Directory]::CreateDirectory($materials) | Out-Null
    [IO.Directory]::CreateDirectory($images) | Out-Null

    # The pattern's per-material techset files (state bits and the like),
    # techsets\<kind>\<techset>\<material>.<ext>: copied as they are, and
    # again under each card's name below. x64-zt reads them by material name,
    # and uses any file in the folder when one is missing (techset.cpp
    # get_parse_path).
    $techsets = Join-IXPath $dump @('techsets')
    $stateFiles = @()
    if ([IO.Directory]::Exists($techsets)) {
        foreach ($file in [IO.Directory]::GetFiles($techsets, '*', [IO.SearchOption]::AllDirectories)) {
            $relative = $file.Substring($techsets.Length).TrimStart('\', '/')
            $target = Join-IXPath $source @('techsets', $relative)
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
            [IO.File]::Copy($file, $target, $true)
            if ([IO.Path]::GetFileName($file).StartsWith($IXPictureTemplate + '.', [StringComparison]::OrdinalIgnoreCase)) {
                $stateFiles += $target
            }
        }
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    $rows = @('// Infinite Expansion character pictures, built by installer\IXPictures.ps1')
    foreach ($zone in $IXPictureTemplateZones) {
        $rows += 'require,' + $zone
    }
    if ($techset) {
        $rows += 'techset,,' + $techset
    }
    $written = @()
    $missing = @()
    foreach ($map in @($Plan)) {
        foreach ($image in $map.Images) {
            $dumped = Find-IXDumpedImage $GameDir $map.Zones $image.Source
            if (-not $dumped) {
                $missing += $image.Source
                continue
            }
            [IO.File]::Copy($dumped, (Join-IXPath $images @($image.Name + '.iw7Image')), $true)
            $text = $templateText.Replace($quoted, '"' + $image.Name + '"')
            [IO.File]::WriteAllText((Join-IXPath $materials @($image.Name + '.json')), $text, $utf8)
            foreach ($state in $stateFiles) {
                $name = $image.Name + [IO.Path]::GetFileName($state).Substring($IXPictureTemplate.Length)
                [IO.File]::Copy($state, (Join-Path ([IO.Path]::GetDirectoryName($state)) $name), $true)
            }
            $rows += 'material,' + $image.Name
            $written += $image.Name
        }
    }

    $csvFolder = Join-IXPath $GameDir @('zone_source')
    [IO.Directory]::CreateDirectory($csvFolder) | Out-Null
    [IO.File]::WriteAllText((Join-IXPath $csvFolder @($IXPictureZone + '.csv')), (($rows -join "`r`n") + "`r`n"), $utf8)
    return [pscustomobject]@{ Materials = $written; Missing = $missing; Source = $source }
}

# Where x64-zt saved the built zone: zone\ when the game has that folder, else
# the game folder (filesystem.cpp get_zone_path, zone_buffer::save).
function Find-IXBuiltPictureZone {
    param([string]$GameDir)
    foreach ($candidate in @((Join-IXPath $GameDir @('zone', ($IXPictureZone + '.ff'))), (Join-IXPath $GameDir @($IXPictureZone + '.ff')))) {
        if ([IO.File]::Exists($candidate)) {
            return $candidate
        }
    }
    return $null
}

# Moves the built zone into <game>\iw7-mod\zone\ and writes next to it the
# list of cards it holds, which the menu script reads, so that it never asks
# for a card the pack does not have.
function Install-IXPicturePack {
    param([string]$GameDir, [string]$Built, [string[]]$Materials)
    $destination = Get-IXPicturePackPath $GameDir
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    [IO.File]::Copy($Built, $destination, $true)
    [IO.File]::Delete($Built)
    $list = (@($Materials) -join "`r`n") + "`r`n"
    [IO.File]::WriteAllText((Get-IXPictureListPath $GameDir), $list, (New-Object System.Text.UTF8Encoding $false))
    return $destination
}

# The game folder's files and folders under x64-zt's working folders (and
# those folders), to tell afterwards which ones this run created.
function Get-IXZoneToolFiles {
    param([string]$GameDir)
    $entries = @()
    foreach ($folder in @('dump', 'zonetool', 'zone_source')) {
        $path = Join-IXPath $GameDir @($folder)
        if ([IO.Directory]::Exists($path)) {
            $entries += $path
            $entries += [IO.Directory]::GetFileSystemEntries($path, '*', [IO.SearchOption]::AllDirectories)
        }
    }
    return $entries
}

# Deletes the files this run added under dump\, zonetool\ and zone_source\,
# then the folders it added, once they are empty. What was there before stays.
# Returns how many files it deleted.
function Remove-IXZoneToolWork {
    param([string]$GameDir, [string[]]$Before)
    $keep = @{}
    foreach ($path in @($Before)) {
        $keep[$path.ToLowerInvariant()] = $true
    }
    $removed = 0
    $folders = @()
    foreach ($path in (Get-IXZoneToolFiles $GameDir)) {
        if ($keep.ContainsKey($path.ToLowerInvariant())) {
            continue
        }
        if ([IO.Directory]::Exists($path)) {
            $folders += $path
        }
        else {
            [IO.File]::Delete($path)
            $removed++
        }
    }
    # Deepest first: a folder's path is longer than its parent's.
    foreach ($folder in @($folders | Sort-Object -Property Length -Descending)) {
        if ([IO.Directory]::Exists($folder) -and @([IO.Directory]::GetFileSystemEntries($folder)).Count -eq 0) {
            [IO.Directory]::Delete($folder)
        }
    }
    return $removed
}

# The newest x64-zt build: the "Release zonetool.zip" asset of its "latest"
# release (.github/workflows/build.yml), and the SHA-256 GitHub lists, if any.
function Get-IXZoneToolFromGitHub {
    param([string]$ApiUrl = $IXZoneToolReleaseApi)
    $release = Invoke-IXHttpText $ApiUrl | ConvertFrom-Json
    foreach ($asset in @($release.assets)) {
        $name = [string]$asset.name
        if ($name -match '^release.zonetool\.zip$') {
            $hash = $null
            $digest = [string]$asset.digest
            if ($digest.StartsWith('sha256:')) {
                $hash = $digest.Substring(7)
            }
            return [pscustomobject]@{
                Name = $name
                Url  = [string]$asset.browser_download_url
                Hash = $hash
            }
        }
    }
    throw 'x64-zt''s latest release has no Release zonetool.zip'
}

# Downloads and unpacks x64-zt into $Folder, keeping only zonetool.exe.
# Returns its path. $Progress, a synchronized hashtable, gets Done and Total bytes.
function Save-IXZoneTool {
    param([string]$Folder, $Source, $Progress)
    [IO.Directory]::CreateDirectory($Folder) | Out-Null
    $zip = Join-IXPath $Folder @('zonetool.zip')
    $exe = $null
    try {
        Save-IXHttpFile $Source.Url $zip $Progress
        if ($Source.Hash) {
            $actual = Get-IXFileHash $zip 'SHA256'
            if ($actual -ne $Source.Hash.ToUpperInvariant()) {
                throw 'The x64-zt download does not match the checksum GitHub lists for it.'
            }
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($zip)
        try {
            foreach ($entry in $archive.Entries) {
                if ($entry.Name -ieq 'zonetool.exe') {
                    $exe = Join-IXPath $Folder @('zonetool.exe')
                    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $exe, $true)
                    break
                }
            }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        if ([IO.File]::Exists($zip)) {
            [IO.File]::Delete($zip)
        }
    }
    if (-not $exe) {
        throw 'The x64-zt download has no zonetool.exe.'
    }
    return $exe
}

# Runs x64-zt in the game folder (it loads iw7_ship.exe from there) and, once it
# reports that it is ready, types $Commands into its console, which reads them
# from standard input (component/iw7/console.cpp). That console only passes on
# commands once the game is set up, which "initialization complete" reports;
# without that line the commands go after two minutes anyway. Standard input
# stays open until x64-zt quits: at the end of its input the console would send
# the last command again and again. -unbuffered-io makes its output arrive line
# by line. Every output line goes to $Log (a script block) and the result.
# Gives up when nothing is printed for $IdleSeconds, or after $TimeoutSeconds.
function Invoke-IXZoneTool {
    param([string]$GameDir, [string]$Exe, [string[]]$Arguments, [string[]]$Commands, [scriptblock]$Log, [int]$TimeoutSeconds = 900, [int]$IdleSeconds = 300)
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $Exe
    $info.Arguments = ($Arguments -join ' ')
    $info.WorkingDirectory = $GameDir
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $process = [Diagnostics.Process]::Start($info)
    $process.StandardInput.NewLine = "`n"
    $lines = New-Object System.Collections.ArrayList
    $sent = (@($Commands).Count -eq 0)
    $start = Get-Date
    $lastOutput = $start
    try {
        $pending = $process.StandardOutput.ReadLineAsync()
        while ($true) {
            $ready = $false
            if ($pending.Wait(500)) {
                $line = $pending.Result
                if ($null -eq $line) {
                    break
                }
                [void]$lines.Add($line)
                $lastOutput = Get-Date
                if ($Log) {
                    $null = & $Log $line
                }
                $ready = $line.IndexOf($IXZoneToolReady, [StringComparison]::OrdinalIgnoreCase) -ge 0
                $pending = $process.StandardOutput.ReadLineAsync()
            }
            $now = Get-Date
            if (-not $sent -and ($ready -or ($now - $start).TotalSeconds -gt 120)) {
                Start-Sleep -Seconds 2
                foreach ($command in $Commands) {
                    $process.StandardInput.WriteLine($command)
                }
                $process.StandardInput.Flush()
                $sent = $true
            }
            if (($now - $lastOutput).TotalSeconds -gt $IdleSeconds -or ($now - $start).TotalSeconds -gt $TimeoutSeconds) {
                $process.Kill()
                throw 'x64-zt stopped responding; see the log.'
            }
        }
        $process.WaitForExit()
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Lines = @($lines) }
    }
    finally {
        # Stopped early (an error, or the setup window closing): x64-zt goes too.
        try {
            if (-not $process.HasExited) {
                $process.Kill()
                [void]$process.WaitForExit(10000)
            }
        }
        catch {
        }
        try {
            $process.StandardInput.Close()
        }
        catch {
        }
        $process.Dispose()
    }
}

# Builds the pack from start to end: x64-zt from GitHub (unless $ZoneTool names
# a zonetool.exe to use), one dump run per map, the build, the install, then the
# clean-up of x64-zt, its download and its work files ($KeepWork keeps the work
# files). The game must be closed and the mod installed.
#
# $Log, when given, gets every step (second argument $true) and every line
# x64-zt prints. $Progress, a synchronized hashtable, gets the current step in
# Phase, and Done and Total bytes while x64-zt downloads. Returns the pack's
# path, how many pictures it holds, the cards x64-zt did not copy, and the maps
# whose run failed. Throws when no pack could be built.
function Invoke-IXPictureBuild {
    param([string]$GameDir, [string]$ZoneTool, [scriptblock]$Log, $Progress, [switch]$KeepWork)
    # Closures, so that the callbacks keep these values wherever x64-zt's
    # output is read (PowerShell looks variables up along the call chain).
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
        throw 'Install Infinite Expansion first. The pictures are for its CHARACTER menu.'
    }

    $exe = Join-IXPath $GameDir @($IXZoneToolCopyName)
    $downloadDir = $null
    $before = $null
    $failed = @()
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

        $plan = Get-IXPicturePlan $GameDir
        $runs = @(Get-IXPictureDumpRuns $plan)
        $step = 0
        $failedInARow = 0
        foreach ($run in $runs) {
            $step++
            # Two maps failing in a row means x64-zt fails on every map; the
            # rest would only fail too, each with its own error box.
            if ($failedInARow -ge 2) {
                $failed += $run.Title + ': skipped after two maps failed in a row'
                & $report ('skipped ' + $run.Map + ': two maps failed in a row') $false
                continue
            }
            & $report ('Copying the character cards of ' + $run.Title + ' (' + $step + ' of ' + $runs.Count + ')') $true
            try {
                $result = Invoke-IXZoneTool $GameDir $exe @('-unbuffered-io') $run.Commands $lines
                & $report ('x64-zt exit code: ' + $result.ExitCode) $false
                if ($result.ExitCode -ne 0) {
                    $failed += $run.Title + ': x64-zt stopped early (exit code ' + $result.ExitCode + ')'
                    $failedInARow++
                }
                else {
                    $failedInARow = 0
                }
            }
            catch {
                $failed += $run.Title + ': ' + $_.Exception.Message
                & $report ('x64-zt failed on ' + $run.Map + ': ' + $_.Exception.Message) $false
                $failedInARow++
            }
        }

        & $report 'Building the picture pack' $true
        $prepared = New-IXPictureSource $GameDir $plan
        foreach ($name in $prepared.Missing) {
            & $report ('not copied: ' + $name) $false
        }
        if (@($prepared.Materials).Count -eq 0) {
            throw 'x64-zt copied none of the cards.'
        }
        $stale = Find-IXBuiltPictureZone $GameDir
        if ($stale) {
            [IO.File]::Delete($stale)
        }
        $build = Invoke-IXZoneTool $GameDir $exe @('-buildzone', $IXPictureZone, '-unbuffered-io') @() $lines
        & $report ('x64-zt exit code: ' + $build.ExitCode) $false
        $built = Find-IXBuiltPictureZone $GameDir
        if (-not $built) {
            throw 'x64-zt did not build the picture pack.'
        }
        $pack = Install-IXPicturePack $GameDir $built $prepared.Materials
        return [pscustomobject]@{
            Pack     = $pack
            Pictures = @($prepared.Materials).Count
            Missing  = @($prepared.Missing)
            Failed   = @($failed)
        }
    }
    finally {
        # Each step on its own: an error here must not hide the one that ended
        # the build, nor stop the other steps.
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
