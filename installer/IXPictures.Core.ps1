# Infinite Expansion - character pictures for the CHARACTER menu, without any window.
#
# The game's menus can only draw pictures that are inside a loaded fastfile. The
# in-match character cards are only inside each map's own fastfile, which is
# loaded only during a match (KNOWN_LIMITATIONS.md L28). This builds a small
# fastfile, iw7-mod\zone\ix_portraits.ff, from the player's own game files:
#
#   1. x64-zt (github.com/Joelrau/x64-zt), the fastfile tool iw7-mod's own
#      documentation describes, runs in the game folder with -dds, once per
#      map, and dumps through its console: one stock menu material as a
#      pattern (zm_character_select_hoff, in ui_boot) and the map's character
#      cards as DDS images.
#   2. Each card becomes a material of its own, named ix_card_* / ix_icon_*, so
#      nothing clashes with the game's own names. The materials refer to the
#      pattern's techset (its shaders) instead of copying it.
#   3. x64-zt builds the zone (-buildzone ix_portraits), and the result goes to
#      <game>\iw7-mod\zone\, where iw7-mod finds custom zones (fastfiles.cpp).
#      The menu script loads it with iw7-mod's loadzone command.
#
# Nothing of the game's art ships with the mod: every player builds the pack
# from their own copy of the game. Dot-sourced after IXSetup.Core.ps1 by
# IXPictures.ps1 and by tools/tests/test_installer.py. Windows PowerShell 5.1
# compatible and ASCII only, like IXSetup.Core.ps1.

$IXPictureTemplate = 'zm_character_select_hoff'
$IXPictureTemplateZone = 'ui_boot'
$IXZoneToolReleaseApi = 'https://api.github.com/repos/Joelrau/x64-zt/releases/tags/latest'
$IXZoneToolCopyName = 'ix-zonetool.exe'
$IXZoneToolReady = 'initialization complete'

# The language zones of a map: <xxx>_<map>.ff in the game's zone\ folder or a
# language folder under it (eng_cp_town in English). eng_<map> when none is
# found, which x64-zt reports as missing and skips.
function Get-IXLanguageZones {
    param([string]$GameDir, [string]$Map)
    $found = @()
    $zoneDir = $null
    if ($GameDir) {
        $zoneDir = Join-IXPath $GameDir @('zone')
    }
    if ($zoneDir -and [IO.Directory]::Exists($zoneDir)) {
        $folders = @($zoneDir) + @([IO.Directory]::GetDirectories($zoneDir))
        foreach ($folder in $folders) {
            foreach ($path in [IO.Directory]::GetFiles($folder, ('*_' + $Map + '.ff'))) {
                $name = [IO.Path]::GetFileNameWithoutExtension($path)
                if ($name -cmatch ('^[a-z]{3}_' + [regex]::Escape($Map) + '$') -and $found -notcontains $name) {
                    $found += $name
                }
            }
        }
    }
    if ($found.Count -eq 0) {
        $found = @('eng_' + $Map)
    }
    return $found
}

# The cards to pack: for each map, the zones that hold its cards and, per card,
# the stock image and the material name the pack gives it. The names come from
# the game's cp/zombies/<map>_playercash_images.csv: a team card ("icon") per
# character, and the main card with "team" replaced by "main" (IW_API_NOTES.md
# section 16). Regular characters get one card per map; special characters
# only exist on their own map. Elvira's main card is in the language zone of
# her map; $GameDir is where to look for it.
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
# loadzone waits for the zones loading before it (x64-zt load_zone and
# wait_for_database), so the map's first zone is named once more after the
# others: that returns once all of them are loaded, and the dumps that follow
# find the cards. The first run also dumps the pattern material.
function Get-IXPictureDumpRuns {
    param($Plan)
    $runs = @()
    $first = $true
    foreach ($map in @($Plan)) {
        $commands = @()
        if ($first) {
            $commands += @(('loadzone ' + $IXPictureTemplateZone), ('loadzone ' + $IXPictureTemplateZone), ('dumpasset material ' + $IXPictureTemplate))
            $first = $false
        }
        foreach ($zone in $map.Zones) {
            $commands += 'loadzone ' + $zone
        }
        $commands += 'loadzone ' + @($map.Zones)[0]
        foreach ($image in $map.Images) {
            $commands += 'dumpasset image ' + $image.Source
        }
        $commands += 'quit'
        $runs += [pscustomobject]@{ Map = $map.Map; Title = $map.Title; Commands = $commands }
    }
    return $runs
}

# The best DDS x64-zt dumped for a stock image: images\<name>.dds, or the
# largest of the streamed sizes, streamed_images\<name>_stream<n>.dds.
function Find-IXDumpedImage {
    param([string]$DumpRoot, [string]$Name)
    $plain = Join-IXPath $DumpRoot @('images', ($Name + '.dds'))
    if ([IO.File]::Exists($plain)) {
        return $plain
    }
    $folder = Join-IXPath $DumpRoot @('streamed_images')
    if (-not [IO.Directory]::Exists($folder)) {
        return $null
    }
    $best = $null
    $bestSize = -1
    foreach ($path in [IO.Directory]::GetFiles($folder, ($Name + '_stream*.dds'))) {
        $size = (New-Object System.IO.FileInfo $path).Length
        if ($size -gt $bestSize) {
            $best = $path
            $bestSize = $size
        }
    }
    return $best
}

# Writes x64-zt's build input for the pack from what it dumped:
# zonetool\ix_portraits\ (a material per card, its DDS image, the pattern's
# techset state files) and zone_source\ix_portraits.csv. Returns the materials
# written and the stock images that were not dumped.
#
# The pattern's techset (its shaders) is the game's own, so the pack refers to
# it instead of carrying a copy that would replace the game's for every menu:
# a "techset,,<name>" row, which x64-zt adds as a reference (zonetool.cpp
# parse_csv_file). "require,ui_boot" loads the pattern's zone first, so that
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
    $rows = @('// Infinite Expansion character pictures, built by installer\IXPictures.ps1', ('require,' + $IXPictureTemplateZone))
    if ($techset) {
        $rows += 'techset,,' + $techset
    }
    $written = @()
    $missing = @()
    foreach ($map in @($Plan)) {
        foreach ($image in $map.Images) {
            $dds = Find-IXDumpedImage $dump $image.Source
            if (-not $dds) {
                $missing += $image.Source
                continue
            }
            [IO.File]::Copy($dds, (Join-IXPath $images @($image.Name + '.dds')), $true)
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

# The game folder's files under x64-zt's working folders, to tell afterwards
# which ones this run created.
function Get-IXZoneToolFiles {
    param([string]$GameDir)
    $files = @()
    foreach ($folder in @('dump', 'zonetool', 'zone_source')) {
        $path = Join-IXPath $GameDir @($folder)
        if ([IO.Directory]::Exists($path)) {
            $files += [IO.Directory]::GetFiles($path, '*', [IO.SearchOption]::AllDirectories)
        }
    }
    return $files
}

# Deletes what this run added under dump\, zonetool\ and zone_source\, and the
# folders that became empty. Files that were there before stay.
function Remove-IXZoneToolWork {
    param([string]$GameDir, [string[]]$Before)
    $keep = @{}
    foreach ($path in @($Before)) {
        $keep[$path.ToLowerInvariant()] = $true
    }
    $removed = 0
    foreach ($path in (Get-IXZoneToolFiles $GameDir)) {
        if (-not $keep.ContainsKey($path.ToLowerInvariant())) {
            [IO.File]::Delete($path)
            Remove-IXEmptyParents $GameDir $path
            $removed++
        }
    }
    foreach ($folder in @('dump', 'zonetool', 'zone_source')) {
        $path = Join-IXPath $GameDir @($folder)
        if ([IO.Directory]::Exists($path) -and @([IO.Directory]::GetFileSystemEntries($path)).Count -eq 0) {
            [IO.Directory]::Delete($path)
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
# Returns its path.
function Save-IXZoneTool {
    param([string]$Folder, $Source)
    [IO.Directory]::CreateDirectory($Folder) | Out-Null
    $zip = Join-IXPath $Folder @('zonetool.zip')
    $exe = $null
    try {
        Save-IXHttpFile $Source.Url $zip
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
                    & $Log $line
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
        try {
            $process.StandardInput.Close()
        }
        catch {
        }
        $process.Dispose()
    }
}
