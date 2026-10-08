# Infinite Expansion - installer logic, without any window.
#
# Dot-sourced by IXSetup.ps1 (the setup window) and by tools/tests/test_installer.py,
# which runs it on Linux with PowerShell 7. On Windows it runs in Windows PowerShell
# 5.1, so it avoids PowerShell 7 syntax (?:, ??, &&, ||), Join-Path with more than
# two parts and .NET Core-only APIs, and the file stays ASCII (5.1 reads a script
# without a byte order mark in the ANSI code page).
#
# What it installs: the mod's custom_scripts and ui_scripts folders, copied into
# <game>\iw7-mod\, a search path of the iw7-mod client (README: Installation). The
# record <game>\iw7-mod\infinite-expansion.json lists the copied files, so that
# uninstalling removes exactly those files and leaves other mods alone. Updates
# come from the project's newest GitHub release (section "Updates" below).

$IXAppId = '292730'                  # Steam app id of Call of Duty: Infinite Warfare
$IXGameExe = 'iw7_ship.exe'          # the game's executable (iw7-mod src/client/main.cpp)
$IXClientExe = 'iw7-mod.exe'         # the iw7-mod client, which lives next to it
$IXRecordName = 'infinite-expansion.json'
$IXPayloadFolders = @('custom_scripts', 'ui_scripts')
$IXUninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\InfiniteExpansion'
$IXProjectUrl = 'https://github.com/qwertymakesstuff/Infinite-Expansion'
$IXClientUrl = 'https://github.com/auroramod/iw7-mod'
# Where iw7-mod.exe comes from (iw7-mod's install guide: "Download iw7-mod.exe on the
# latest release"), and iw7-mod's own update server as a fallback: its updater reads
# files.json there ([name, size, SHA-1] entries) and downloads data/<name>
# (src/client/component/updater.cpp).
$IXClientReleaseApi = 'https://api.github.com/repos/auroramod/iw7-mod/releases/latest'
$IXClientUpdateServer = 'https://iw7-mod.auroramod.dev/'
$IXSteamInstallUrl = 'steam://install/292730'
$IXSteamStoreUrl = 'https://store.steampowered.com/app/292730/'
# The player's Steam name, for the mod's menu script, which sets iw7-mod's "name"
# setting from it while that is still iw7-mod's default "Unknown Soldier".
$IXPlayerNameFile = 'ui_scripts/InfiniteExpansion/steam-name.txt'
# Character pictures for the CHARACTER menu, a zone built on the player's PC
# (IXPictures.Core.ps1) and kept where iw7-mod finds custom zones.
$IXPictureZone = 'ix_portraits'
# The launcher in the game folder, compiled on the player's PC from the
# installer folder's IXLauncher.cs, with ix-launcher.ico built in.
$IXLauncherName = 'Infinite Expansion.exe'
$IXLauncherSource = 'IXLauncher.cs'
$IXLauncherIcon = 'ix-launcher.ico'
$IXLauncherShortcutName = 'Infinite Expansion.lnk'
# Given to the launcher when the setup starts the game: the setup has just
# installed or looked for an update, so the launcher need not.
$IXLauncherNoUpdate = '--ix-no-update'
# Updates: the newest release of the project, which .github/workflows/release.yml
# publishes for each version (tag v<version>, asset Infinite-Expansion-<version>.zip).
$IXReleaseApi = 'https://api.github.com/repos/qwertymakesstuff/Infinite-Expansion/releases/latest'
$IXReleaseDownloads = 'https://github.com/qwertymakesstuff/Infinite-Expansion/releases/download/'
$IXUpdateMaxBytes = 64MB

# ---------------------------------------------------------------------------
# Paths

# Joins a base path and relative parts; parts may contain / or \ separators.
function Join-IXPath {
    param([string]$Base, [string[]]$Parts)
    $path = $Base
    foreach ($part in $Parts) {
        foreach ($piece in ($part -split '[\\/]')) {
            if ($piece -ne '') {
                $path = Join-Path $path $piece
            }
        }
    }
    return $path
}

function Get-IXFullPath {
    param([string]$Path)
    return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Test-IXSamePath {
    param([string]$A, [string]$B)
    if (-not $A -or -not $B) {
        return $false
    }
    return [string]::Equals((Get-IXFullPath $A), (Get-IXFullPath $B), [StringComparison]::OrdinalIgnoreCase)
}

# The full path of a recorded file below $Root, or $null when the entry would
# point anywhere else: outside $Root, or outside the folders the mod owns.
function Resolve-IXEntry {
    param([string]$Root, [string]$Relative, [string[]]$AllowedTop = $IXPayloadFolders)
    if (-not $Relative) {
        return $null
    }
    if ($Relative -match '(^|[\\/])\.\.([\\/]|$)' -or $Relative -match '^[\\/]' -or $Relative -match ':') {
        return $null
    }
    $top = ($Relative -split '[\\/]')[0]
    if ($AllowedTop -notcontains $top) {
        return $null
    }
    $rootFull = Get-IXFullPath $Root
    $full = [IO.Path]::GetFullPath((Join-IXPath $rootFull @($Relative)))
    $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }
    return $full
}

# ---------------------------------------------------------------------------
# The package (the folder next to the installer)

function Get-IXPackageVersion {
    param([string]$PackageRoot)
    if (-not $PackageRoot) {
        return $null
    }
    $bootstrap = Join-IXPath $PackageRoot @('custom_scripts', 'ix', 'core', 'bootstrap.gsc')
    if (-not [IO.File]::Exists($bootstrap)) {
        return $null
    }
    $match = [regex]::Match([IO.File]::ReadAllText($bootstrap), 'level\.ix\.version\s*=\s*"([^"]+)"')
    if ($match.Success) {
        return $match.Groups[1].Value
    }
    return $null
}

# Relative paths, with /, of every file the package installs, sorted by
# character code: Sort-Object would sort by the PC's language rules, which put
# "menu_tree.gsc" before "menu.gsc".
function Get-IXPayloadFiles {
    param([string]$PackageRoot)
    $files = New-Object System.Collections.Generic.List[string]
    if (-not $PackageRoot -or -not [IO.Directory]::Exists($PackageRoot)) {
        return @()
    }
    $root = Get-IXFullPath $PackageRoot
    foreach ($folder in $IXPayloadFolders) {
        $dir = Join-Path $root $folder
        if (-not [IO.Directory]::Exists($dir)) {
            continue
        }
        foreach ($file in [IO.Directory]::GetFiles($dir, '*', [IO.SearchOption]::AllDirectories)) {
            $files.Add($file.Substring($root.Length + 1).Replace('\', '/'))
        }
    }
    $files.Sort([StringComparer]::Ordinal)
    return @($files)
}

# ---------------------------------------------------------------------------
# Finding the game

# Steam install folders from the registry (none outside Windows).
function Get-IXSteamRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    $keys = @(
        @('HKCU:\Software\Valve\Steam', 'SteamPath'),
        @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'InstallPath'),
        @('HKLM:\SOFTWARE\Valve\Steam', 'InstallPath')
    )
    foreach ($key in $keys) {
        try {
            $value = (Get-ItemProperty -LiteralPath $key[0] -Name $key[1] -ErrorAction Stop).($key[1])
            if ($value) {
                $roots.Add(($value -replace '/', '\'))
            }
        }
        catch {
        }
    }
    return @($roots)
}

# Every Steam library: each root itself plus the folders its
# steamapps\libraryfolders.vdf lists (both the old and the current format).
function Get-IXSteamLibraries {
    param([string[]]$SteamRoots)
    $libraries = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    foreach ($root in $SteamRoots) {
        if (-not $root) {
            continue
        }
        $candidates = New-Object System.Collections.Generic.List[string]
        $candidates.Add($root)
        $vdf = Join-IXPath $root @('steamapps', 'libraryfolders.vdf')
        if ([IO.File]::Exists($vdf)) {
            foreach ($line in [IO.File]::ReadAllLines($vdf)) {
                $match = [regex]::Match($line, '^\s*"(?:path|\d+)"\s+"([^"]+)"\s*$')
                if ($match.Success) {
                    $value = $match.Groups[1].Value.Replace('\\', '\')
                    if ($value -match '[\\/]') {
                        $candidates.Add($value)
                    }
                }
            }
        }
        foreach ($library in $candidates) {
            $key = $library.TrimEnd('\', '/').ToLowerInvariant()
            if (-not $seen.ContainsKey($key)) {
                $seen[$key] = $true
                $libraries.Add($library)
            }
        }
    }
    return @($libraries)
}

function Test-IXGameDir {
    param([string]$Path)
    if (-not $Path) {
        return $false
    }
    return [IO.File]::Exists((Join-Path $Path $IXGameExe))
}

# The game folder, from the Steam libraries, or $null.
function Find-IXGameDir {
    param([string[]]$SteamRoots)
    if ($null -eq $SteamRoots) {
        $SteamRoots = Get-IXSteamRoots
    }
    foreach ($library in (Get-IXSteamLibraries $SteamRoots)) {
        $common = Join-IXPath $library @('steamapps', 'common')
        $candidates = New-Object System.Collections.Generic.List[string]
        $manifest = Join-IXPath $library @('steamapps', "appmanifest_$IXAppId.acf")
        if ([IO.File]::Exists($manifest)) {
            $match = [regex]::Match([IO.File]::ReadAllText($manifest), '"installdir"\s+"([^"]+)"')
            if ($match.Success) {
                $candidates.Add((Join-Path $common $match.Groups[1].Value))
            }
        }
        $candidates.Add((Join-Path $common 'Call of Duty Infinite Warfare'))
        foreach ($dir in $candidates) {
            if (Test-IXGameDir $dir) {
                return $dir
            }
        }
    }
    return $null
}

# The display name of the Steam account, from <Steam>\config\loginusers.vdf: the
# account logged in now (HKCU ...\Valve\Steam\ActiveProcess\ActiveUser), else the one
# marked MostRecent, else any. $null when there is none.
function Get-IXSteamPersonaName {
    param([string[]]$SteamRoots)
    if ($null -eq $SteamRoots) {
        $SteamRoots = Get-IXSteamRoots
    }
    $active = $null
    try {
        $id = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam\ActiveProcess' -Name 'ActiveUser' -ErrorAction Stop).ActiveUser
        if ($id) {
            $active = ([long]76561197960265728 + [long]$id).ToString()
        }
    }
    catch {
    }
    foreach ($root in $SteamRoots) {
        if (-not $root) {
            continue
        }
        $vdf = Join-IXPath $root @('config', 'loginusers.vdf')
        if (-not [IO.File]::Exists($vdf)) {
            continue
        }
        $best = $null
        $bestScore = 0
        foreach ($block in [regex]::Matches([IO.File]::ReadAllText($vdf, [Text.Encoding]::UTF8), '"(\d{17})"\s*\{([^{}]*)\}')) {
            $persona = [regex]::Match($block.Groups[2].Value, '"(?i:PersonaName)"\s+"((?:[^"\\]|\\.)*)"')
            if (-not $persona.Success) {
                continue
            }
            $score = 1
            if ($block.Groups[1].Value -eq $active) {
                $score = 3
            }
            elseif ([regex]::IsMatch($block.Groups[2].Value, '"(?i:MostRecent)"\s+"1"')) {
                $score = 2
            }
            if ($score -gt $bestScore) {
                $bestScore = $score
                $best = $persona.Groups[1].Value -replace '\\(.)', '$1'
            }
        }
        if ($null -ne $best) {
            return $best
        }
    }
    return $null
}

# A name the game can show as it is: printable ASCII without the quote, backslash,
# semicolon, percent and caret (colour codes), at most 31 characters. $null when the
# Steam name has other characters, which the game would show as boxes.
function ConvertTo-IXPlayerName {
    param([string]$Name)
    if (-not $Name -or $Name -match '[^\x20-\x7E]') {
        return $null
    }
    $clean = (($Name -replace '["\\;%^]', '') -replace '\s+', ' ').Trim()
    if ($clean.Length -gt 31) {
        $clean = $clean.Substring(0, 31).Trim()
    }
    if ($clean.Length -eq 0) {
        return $null
    }
    return $clean
}

# ---------------------------------------------------------------------------
# State

function Get-IXTarget {
    param([string]$GameDir)
    return Join-Path $GameDir 'iw7-mod'
}

function Get-IXOldCopyDir {
    param([string]$GameDir)
    return Join-IXPath $GameDir @('mods', 'infinite_expansion')
}

# The copy loaded from the Mods menu (README: solo only), found by its entry script.
function Test-IXOldCopy {
    param([string]$GameDir)
    return [IO.File]::Exists((Join-IXPath (Get-IXOldCopyDir $GameDir) @('custom_scripts', 'cp', 'ix_main.gsc')))
}

function Read-IXRecord {
    param([string]$GameDir)
    $path = Join-Path (Get-IXTarget $GameDir) $IXRecordName
    if (-not [IO.File]::Exists($path)) {
        return $null
    }
    try {
        return [IO.File]::ReadAllText($path) | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Read-IXRecordFiles {
    param([string]$GameDir)
    $record = Read-IXRecord $GameDir
    if ($null -eq $record -or $null -eq $record.files) {
        return @()
    }
    return @($record.files | ForEach-Object { [string]$_ })
}

function Write-IXRecord {
    param([string]$GameDir, [string]$Version, [string[]]$Files)
    $record = [ordered]@{
        name        = 'Infinite Expansion'
        version     = $Version
        installedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        files       = @($Files)
    }
    $path = Join-Path (Get-IXTarget $GameDir) $IXRecordName
    $json = ConvertTo-Json -InputObject $record -Depth 4
    [IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding $false))
}

function Test-IXGameRunning {
    $running = @(Get-Process -Name 'iw7-mod', 'iw7_ship' -ErrorAction SilentlyContinue)
    return $running.Count -gt 0
}

# Everything the setup window shows.
function Get-IXState {
    param([string]$GameDir, [string]$PackageRoot)
    $state = [ordered]@{
        GameDir          = $GameDir
        GameFound        = (Test-IXGameDir $GameDir)
        ClientFound      = $false
        PackageVersion   = (Get-IXPackageVersion $PackageRoot)
        PackageFound     = (@(Get-IXPayloadFiles $PackageRoot).Count -gt 0)
        Installed        = $false
        HasRecord        = $false
        InstalledVersion = $null
        OldCopy          = $false
        GameRunning      = (Test-IXGameRunning)
        PicturesBuilt    = $false
        FilesDiffer      = $false
        LauncherFound    = $false
    }
    if ($state.GameFound) {
        $target = Get-IXTarget $GameDir
        $state.ClientFound = [IO.File]::Exists((Join-Path $GameDir $IXClientExe))
        $state.PicturesBuilt = [IO.File]::Exists((Get-IXPicturePackPath $GameDir))
        $state.LauncherFound = [IO.File]::Exists((Get-IXLauncherPath $GameDir))
        $state.HasRecord = [IO.File]::Exists((Join-Path $target $IXRecordName))
        $state.Installed = $state.HasRecord -or [IO.File]::Exists((Join-IXPath $target @('custom_scripts', 'cp', 'ix_main.gsc')))
        if ($state.Installed) {
            $state.InstalledVersion = Get-IXPackageVersion $target
            if ($state.PackageFound) {
                $state.FilesDiffer = -not (Test-IXFilesCurrent $PackageRoot $target)
            }
        }
        $state.OldCopy = Test-IXOldCopy $GameDir
    }
    return [pscustomobject]$state
}

# True when every file of the package is installed in $Target with the same
# content. A newer download can keep the version number, so the setup compares
# the files themselves to offer UPDATE.
function Test-IXFilesCurrent {
    param([string]$PackageRoot, [string]$Target)
    foreach ($relative in (Get-IXPayloadFiles $PackageRoot)) {
        $installed = Join-IXPath $Target @($relative)
        if (-not [IO.File]::Exists($installed)) {
            return $false
        }
        $source = Join-IXPath $PackageRoot @($relative)
        if ((New-Object System.IO.FileInfo $source).Length -ne (New-Object System.IO.FileInfo $installed).Length) {
            return $false
        }
        if ((Get-IXFileHash $source 'SHA256') -ne (Get-IXFileHash $installed 'SHA256')) {
            return $false
        }
    }
    return $true
}

# ---------------------------------------------------------------------------
# Files

function Remove-IXEmptyParents {
    param([string]$Root, [string]$Path)
    $rootFull = Get-IXFullPath $Root
    $dir = [IO.Path]::GetDirectoryName($Path)
    while ($dir -and $dir.Length -gt $rootFull.Length -and $dir.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
        if (@([IO.Directory]::GetFileSystemEntries($dir)).Count -gt 0) {
            break
        }
        [IO.Directory]::Delete($dir)
        $dir = [IO.Path]::GetDirectoryName($dir)
    }
}

# Deletes one recorded file, then any folders that became empty. $true if a file was deleted.
function Remove-IXFile {
    param([string]$Root, [string]$Relative, [string[]]$AllowedTop = $IXPayloadFolders)
    $full = Resolve-IXEntry $Root $Relative $AllowedTop
    if (-not $full -or -not [IO.File]::Exists($full)) {
        return $false
    }
    [IO.File]::Delete($full)
    Remove-IXEmptyParents $Root $full
    return $true
}

# Removes the Mods-menu copy's own files. Anything else in that folder stays.
function Remove-IXOldCopy {
    param([string]$GameDir, [string[]]$Files)
    $root = Get-IXOldCopyDir $GameDir
    $result = [pscustomobject]@{ Removed = 0; Left = 0; Path = $root }
    if (-not (Test-IXOldCopy $GameDir)) {
        return $result
    }
    $allowed = @($IXPayloadFolders) + @('desc.txt')
    foreach ($relative in (@($Files) + @('desc.txt'))) {
        if (Remove-IXFile $root $relative $allowed) {
            $result.Removed++
        }
    }
    if ([IO.Directory]::Exists($root)) {
        $left = @([IO.Directory]::GetFiles($root, '*', [IO.SearchOption]::AllDirectories)).Count
        if ($left -eq 0) {
            [IO.Directory]::Delete($root, $true)
        }
        $result.Left = $left
    }
    return $result
}

# Copies the package into <game>\iw7-mod\, writes the player's name file when
# $PlayerName is given, removes files an older version left behind, writes the
# record, and removes the Mods-menu copy.
function Install-IX {
    param([string]$GameDir, [string]$PackageRoot, [string]$PlayerName)
    if (-not (Test-IXGameDir $GameDir)) {
        throw "$IXGameExe was not found in '$GameDir'."
    }
    $files = @(Get-IXPayloadFiles $PackageRoot)
    if ($files.Count -eq 0) {
        throw 'The mod files are missing. Extract the whole download, then run the setup from it.'
    }
    $target = Get-IXTarget $GameDir
    [IO.Directory]::CreateDirectory($target) | Out-Null
    $previous = @(Read-IXRecordFiles $GameDir)
    $copied = 0
    foreach ($relative in $files) {
        $destination = Resolve-IXEntry $target $relative
        if (-not $destination) {
            continue
        }
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
        [IO.File]::Copy((Join-IXPath $PackageRoot @($relative)), $destination, $true)
        $copied++
    }
    if ($PlayerName) {
        $namePath = Resolve-IXEntry $target $IXPlayerNameFile
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($namePath)) | Out-Null
        [IO.File]::WriteAllText($namePath, $PlayerName, (New-Object System.Text.UTF8Encoding $false))
        $files += $IXPlayerNameFile
    }
    $stale = 0
    foreach ($relative in $previous) {
        if ($files -notcontains $relative) {
            if (Remove-IXFile $target $relative) {
                $stale++
            }
        }
    }
    Write-IXRecord $GameDir (Get-IXPackageVersion $PackageRoot) $files
    $old = Remove-IXOldCopy $GameDir $files
    return [pscustomobject]@{
        Target         = $target
        Copied         = $copied
        PlayerName     = $PlayerName
        StaleRemoved   = $stale
        OldCopyRemoved = $old.Removed
        OldCopyLeft    = $old.Left
        OldCopyPath    = $old.Path
    }
}

function Get-IXPicturePackPath {
    param([string]$GameDir)
    return Join-IXPath (Get-IXTarget $GameDir) @('zone', ($IXPictureZone + '.ff'))
}

# The list of cards in the zone, which the menu script reads.
function Get-IXPictureListPath {
    param([string]$GameDir)
    return Join-IXPath (Get-IXTarget $GameDir) @('zone', ($IXPictureZone + '.txt'))
}

# Deletes the character pictures zone and its list, if built. $true if the zone was there.
function Remove-IXPicturePack {
    param([string]$GameDir)
    $path = Get-IXPicturePackPath $GameDir
    $list = Get-IXPictureListPath $GameDir
    $found = [IO.File]::Exists($path)
    foreach ($file in @($path, $list)) {
        if ([IO.File]::Exists($file)) {
            [IO.File]::Delete($file)
            Remove-IXEmptyParents (Get-IXTarget $GameDir) $file
        }
    }
    return $found
}

# Removes the recorded files (or, without a record, the package's own file list),
# the record, the character pictures zone, the Mods-menu copy, and the launcher
# with its desktop shortcut.
function Uninstall-IX {
    param([string]$GameDir, [string]$PackageRoot)
    $target = Get-IXTarget $GameDir
    $files = @(Read-IXRecordFiles $GameDir)
    if ($files.Count -eq 0) {
        $files = @(Get-IXPayloadFiles $PackageRoot)
    }
    $removed = 0
    foreach ($relative in $files) {
        if (Remove-IXFile $target $relative) {
            $removed++
        }
    }
    $record = Join-Path $target $IXRecordName
    if ([IO.File]::Exists($record)) {
        [IO.File]::Delete($record)
    }
    if (Remove-IXPicturePack $GameDir) {
        $removed++
    }
    $old = Remove-IXOldCopy $GameDir $files
    # A launcher still waiting for Steam cannot be deleted; that is no reason
    # to fail (or to ask for administrator rights).
    $launcher = $false
    $launcherLeft = $null
    try {
        $launcher = Remove-IXLauncher $GameDir
    }
    catch {
        $launcherLeft = Get-IXLauncherPath $GameDir
    }
    return [pscustomobject]@{
        Target          = $target
        Removed         = $removed
        OldCopyRemoved  = $old.Removed
        OldCopyLeft     = $old.Left
        OldCopyPath     = $old.Path
        LauncherRemoved = $launcher
        LauncherLeft    = $launcherLeft
    }
}

# ---------------------------------------------------------------------------
# The iw7-mod client

# Windows PowerShell 5.1 may still default to TLS 1.0, which GitHub refuses.
function Enable-IXTls12 {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    catch {
    }
}

function New-IXRequest {
    param([string]$Url)
    $request = [Net.HttpWebRequest]::Create($Url)
    $request.UserAgent = 'InfiniteExpansionSetup'
    $request.Timeout = 30000
    $request.ReadWriteTimeout = 30000
    return $request
}

function Invoke-IXHttpText {
    param([string]$Url)
    $request = New-IXRequest $Url
    $request.Accept = 'application/vnd.github+json, application/json'
    $response = $request.GetResponse()
    try {
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream(), [Text.Encoding]::UTF8)
        return $reader.ReadToEnd()
    }
    finally {
        $response.Close()
    }
}

# Downloads $Url to $Path. $Progress, a synchronized hashtable, gets Done and Total bytes.
function Save-IXHttpFile {
    param([string]$Url, [string]$Path, $Progress)
    $response = (New-IXRequest $Url).GetResponse()
    try {
        if ($null -ne $Progress) {
            $Progress.Total = $response.ContentLength
            $Progress.Done = 0
        }
        $source = $response.GetResponseStream()
        $target = [IO.File]::Create($Path)
        try {
            $buffer = New-Object byte[] 65536
            $done = 0
            while ($true) {
                $read = $source.Read($buffer, 0, $buffer.Length)
                if ($read -le 0) {
                    break
                }
                $target.Write($buffer, 0, $read)
                $done += $read
                if ($null -ne $Progress) {
                    $Progress.Done = $done
                }
            }
        }
        finally {
            $target.Close()
            $source.Close()
        }
    }
    finally {
        $response.Close()
    }
}

function Get-IXFileHash {
    param([string]$Path, [string]$Algorithm)
    if ($Algorithm -eq 'SHA1') {
        $hasher = [Security.Cryptography.SHA1]::Create()
    }
    else {
        $hasher = [Security.Cryptography.SHA256]::Create()
    }
    $stream = [IO.File]::OpenRead($Path)
    try {
        $bytes = $hasher.ComputeHash($stream)
    }
    finally {
        $stream.Close()
    }
    return [BitConverter]::ToString($bytes).Replace('-', '')
}

# The newest release's iw7-mod.exe: download URL, and the SHA-256 GitHub lists for it, if any.
function Get-IXClientFromGitHub {
    param([string]$ApiUrl = $IXClientReleaseApi)
    $release = Invoke-IXHttpText $ApiUrl | ConvertFrom-Json
    foreach ($asset in @($release.assets)) {
        if ([string]$asset.name -eq $IXClientExe) {
            $hash = $null
            $digest = [string]$asset.digest
            if ($digest.StartsWith('sha256:')) {
                $hash = $digest.Substring(7)
            }
            return [pscustomobject]@{
                Source    = 'GitHub'
                Version   = [string]$release.tag_name
                Url       = [string]$asset.browser_download_url
                Algorithm = 'SHA256'
                Hash      = $hash
            }
        }
    }
    throw ('the latest release has no ' + $IXClientExe)
}

# The same file from iw7-mod's update server, with the SHA-1 its own updater checks.
function Get-IXClientFromUpdateServer {
    param([string]$ServerUrl = $IXClientUpdateServer)
    $base = $ServerUrl.TrimEnd('/') + '/'
    $list = Invoke-IXHttpText ($base + 'files.json') | ConvertFrom-Json
    foreach ($entry in @($list)) {
        $item = @($entry)
        if ($item.Count -eq 3 -and [string]$item[0] -eq $IXClientExe -and $item[2]) {
            return [pscustomobject]@{
                Source    = 'the iw7-mod update server'
                Version   = 'latest'
                Url       = $base + 'data/' + $IXClientExe
                Algorithm = 'SHA1'
                Hash      = [string]$item[2]
            }
        }
    }
    throw ('files.json lists no ' + $IXClientExe)
}

# Throws unless $Path looks like the right program and matches the listed checksum.
function Test-IXClientFile {
    param([string]$Path, $Source)
    if ((New-Object System.IO.FileInfo $Path).Length -lt 256KB) {
        throw 'the download is too small to be iw7-mod.exe'
    }
    $stream = [IO.File]::OpenRead($Path)
    try {
        $first = $stream.ReadByte()
        $second = $stream.ReadByte()
    }
    finally {
        $stream.Close()
    }
    if ($first -ne 0x4D -or $second -ne 0x5A) {
        throw 'the download is not a Windows program'
    }
    if ($Source.Hash) {
        $actual = Get-IXFileHash $Path $Source.Algorithm
        if ($actual -ne $Source.Hash) {
            throw ($Source.Algorithm + ' checksum mismatch')
        }
    }
}

# Puts iw7-mod.exe into the game folder: from the latest GitHub release, or else from
# iw7-mod's update server. The client downloads the rest of its files itself the first
# time it starts (iw7-mod's install guide, step 3).
function Install-IXClient {
    param(
        [string]$GameDir,
        $Progress,
        [string]$ApiUrl = $IXClientReleaseApi,
        [string]$ServerUrl = $IXClientUpdateServer
    )
    if (-not (Test-IXGameDir $GameDir)) {
        throw "$IXGameExe was not found in '$GameDir'."
    }
    Enable-IXTls12
    $target = Join-Path $GameDir $IXClientExe
    $temp = $target + '.download'
    $failures = @()
    foreach ($origin in @('github', 'server')) {
        try {
            if ($null -ne $Progress) {
                $Progress.Phase = 'Looking up the latest iw7-mod'
            }
            if ($origin -eq 'github') {
                $source = Get-IXClientFromGitHub $ApiUrl
            }
            else {
                $source = Get-IXClientFromUpdateServer $ServerUrl
            }
            if ($null -ne $Progress) {
                $Progress.Phase = 'Downloading iw7-mod.exe from ' + $source.Source
            }
            Save-IXHttpFile $source.Url $temp $Progress
            Test-IXClientFile $temp $source
            if ([IO.File]::Exists($target)) {
                [IO.File]::Delete($target)
            }
            [IO.File]::Move($temp, $target)
            return [pscustomobject]@{
                Path     = $target
                Source   = $source.Source
                Version  = $source.Version
                Verified = [bool]$source.Hash
            }
        }
        catch {
            $failures += ($origin + ': ' + $_.Exception.Message)
            if ([IO.File]::Exists($temp)) {
                [IO.File]::Delete($temp)
            }
        }
    }
    throw ('iw7-mod could not be downloaded (' + ($failures -join '; ') + ').')
}

# The desktop shortcut called $Name, or $null where there is no desktop (not Windows).
function Get-IXDesktopShortcutPath {
    param([string]$Name)
    if ($env:OS -ne 'Windows_NT') {
        return $null
    }
    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop) {
        return $null
    }
    return Join-Path $desktop $Name
}

# A desktop shortcut to $Target, started in $GameDir, with $Target's own icon.
# Windows only; returns its path or $null.
function Save-IXShortcut {
    param([string]$Name, [string]$Target, [string]$GameDir, [string]$Description)
    $path = Get-IXDesktopShortcutPath $Name
    if (-not $path) {
        return $null
    }
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut($path)
    $link.TargetPath = $Target
    $link.WorkingDirectory = $GameDir
    $link.IconLocation = $Target + ',0'
    $link.Description = $Description
    $link.Save()
    return $path
}

# Throws (access denied) when Windows does not let this user write to the game folder.
function Test-IXWritable {
    param([string]$GameDir)
    $probe = Join-Path $GameDir ('ix-setup-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllText($probe, 'probe')
    [IO.File]::Delete($probe)
}

function Test-IXSteamRunning {
    return @(Get-Process -Name 'steam' -ErrorAction SilentlyContinue).Count -gt 0
}

# Starts the game from the game folder: with the launcher when the setup built
# it (it waits for Steam), else iw7-mod.exe the way its install guide says.
# $Arguments (a command line) go to the game; the launcher also gets
# $IXLauncherNoUpdate, because the setup has just installed or looked for an
# update. Returns the program it started.
function Start-IXGame {
    param([string]$GameDir, [string]$Arguments)
    $exe = Join-Path $GameDir $IXClientExe
    if (-not [IO.File]::Exists($exe)) {
        throw "$IXClientExe is not in the game folder."
    }
    $launcher = Get-IXLauncherPath $GameDir
    if ([IO.File]::Exists($launcher)) {
        $exe = $launcher
        $Arguments = ($IXLauncherNoUpdate + ' ' + $Arguments).Trim()
    }
    if ($Arguments) {
        Start-Process -FilePath $exe -WorkingDirectory $GameDir -ArgumentList $Arguments | Out-Null
    }
    else {
        Start-Process -FilePath $exe -WorkingDirectory $GameDir | Out-Null
    }
    return $exe
}

# ---------------------------------------------------------------------------
# The launcher: "Infinite Expansion.exe" in the game folder (IXLauncher.cs says
# what it does). It is compiled here, on the player's PC, by the C# compiler
# that Windows 10 and 11 come with (.NET Framework 4: csc.exe, C# 5), so the
# download carries no program file and Windows has no downloaded program to
# warn about.

function Get-IXLauncherPath {
    param([string]$GameDir)
    return Join-IXPath $GameDir @($IXLauncherName)
}

# The .NET Framework 4 C# compiler, or $null.
function Find-IXCSharpCompiler {
    $windows = $env:WINDIR
    if (-not $windows) {
        return $null
    }
    foreach ($framework in @('Framework64', 'Framework')) {
        $path = Join-IXPath $windows @('Microsoft.NET', $framework, 'v4.0.30319', 'csc.exe')
        if ([IO.File]::Exists($path)) {
            return $path
        }
    }
    return $null
}

# The launcher's AssemblyVersion, which takes up to four numbers: "0.2.0" is
# "0.2.0.0"; anything else is "0.0.0.0".
function Get-IXLauncherVersion {
    param([string]$Version)
    if ($Version -notmatch '^\d{1,4}(\.\d{1,4}){0,3}$') {
        return '0.0.0.0'
    }
    $parts = @($Version.Split('.'))
    while ($parts.Count -lt 4) {
        $parts += '0'
    }
    return ($parts -join '.')
}

# Runs the compiler without a window. Returns its exit code and output.
function Invoke-IXCSharpCompiler {
    param([string]$Compiler, [string[]]$Arguments, [int]$TimeoutSeconds = 120)
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $Compiler
    $info.Arguments = ($Arguments -join ' ')
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $process = [Diagnostics.Process]::Start($info)
    try {
        $output = $process.StandardOutput.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            throw 'The C# compiler did not finish.'
        }
        $process.WaitForExit()
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $output.Result }
    }
    finally {
        $process.Dispose()
    }
}

# The compiler's first error line, for a status message.
function Get-IXCompilerError {
    param([string]$Output)
    $lines = @(([string]$Output) -split "`r?`n" | Where-Object { $_.Trim() })
    foreach ($line in $lines) {
        if ($line -match 'error') {
            return $line.Trim()
        }
    }
    if ($lines.Count -gt 0) {
        return $lines[$lines.Count - 1].Trim()
    }
    return 'no output'
}

# Compiles <game>\Infinite Expansion.exe from $InstallerDir\IXLauncher.cs, with
# the package version filled in. The icon goes in when the compiler takes it,
# else the launcher is built without it. $Compiler: csc.exe, found by
# Find-IXCSharpCompiler when not given. Returns the launcher's path and whether
# it has the icon.
function New-IXLauncher {
    param([string]$GameDir, [string]$InstallerDir, [string]$Version, [string]$Compiler)
    if (-not $Compiler) {
        $Compiler = Find-IXCSharpCompiler
    }
    if (-not $Compiler) {
        throw 'the C# compiler of .NET Framework 4 (csc.exe) was not found'
    }
    $sourcePath = Join-IXPath $InstallerDir @($IXLauncherSource)
    if (-not [IO.File]::Exists($sourcePath)) {
        throw ($IXLauncherSource + ' is missing next to the setup')
    }
    $placeholder = 'AssemblyVersion("0.0.0.0")'
    $source = [IO.File]::ReadAllText($sourcePath).Replace($placeholder, 'AssemblyVersion("' + (Get-IXLauncherVersion $Version) + '")')
    $iconPath = Join-IXPath $InstallerDir @($IXLauncherIcon)
    $work = Join-IXPath ([IO.Path]::GetTempPath()) @('ix-launcher-' + [Guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($work) | Out-Null
    try {
        $sourceFile = Join-IXPath $work @($IXLauncherSource)
        $built = Join-IXPath $work @($IXLauncherName)
        [IO.File]::WriteAllText($sourceFile, $source, (New-Object System.Text.UTF8Encoding $false))
        $arguments = @('/nologo', '/noconfig', '/target:winexe', '/optimize+', '/reference:System.dll', ('/out:"' + $built + '"'))
        $icon = [IO.File]::Exists($iconPath)
        $result = $null
        if ($icon) {
            $result = Invoke-IXCSharpCompiler $Compiler ($arguments + @(('/win32icon:"' + $iconPath + '"'), ('"' + $sourceFile + '"')))
            if ($result.ExitCode -ne 0 -or -not [IO.File]::Exists($built)) {
                $icon = $false
                if ([IO.File]::Exists($built)) {
                    [IO.File]::Delete($built)
                }
            }
        }
        if (-not $icon) {
            $result = Invoke-IXCSharpCompiler $Compiler ($arguments + @('"' + $sourceFile + '"'))
        }
        if ($result.ExitCode -ne 0 -or -not [IO.File]::Exists($built)) {
            throw ('the C# compiler failed: ' + (Get-IXCompilerError $result.Output))
        }
        $path = Get-IXLauncherPath $GameDir
        [IO.File]::Copy($built, $path, $true)
        return [pscustomobject]@{ Path = $path; Icon = $icon }
    }
    finally {
        try {
            [IO.Directory]::Delete($work, $true)
        }
        catch {
        }
    }
}

# Builds the launcher and its desktop shortcut. A shortcut that cannot be made
# is left out. Returns the launcher's path, whether it has the icon, and the
# shortcut's path ($null without one).
function Install-IXLauncher {
    param([string]$GameDir, [string]$InstallerDir, [string]$Version, [string]$Compiler)
    $launcher = New-IXLauncher $GameDir $InstallerDir $Version $Compiler
    $shortcut = $null
    try {
        $shortcut = Save-IXShortcut $IXLauncherShortcutName $launcher.Path $GameDir 'Call of Duty: Infinite Warfare with Infinite Expansion (iw7-mod)'
    }
    catch {
    }
    return [pscustomobject]@{ Path = $launcher.Path; Icon = $launcher.Icon; Shortcut = $shortcut }
}

# Deletes the launcher, and its desktop shortcut while that still points at it.
# $true when the launcher was there.
function Remove-IXLauncher {
    param([string]$GameDir)
    $path = Get-IXLauncherPath $GameDir
    $found = [IO.File]::Exists($path)
    if ($found) {
        [IO.File]::Delete($path)
    }
    $shortcut = Get-IXDesktopShortcutPath $IXLauncherShortcutName
    if ($shortcut -and [IO.File]::Exists($shortcut)) {
        $shell = New-Object -ComObject WScript.Shell
        $target = $shell.CreateShortcut($shortcut).TargetPath
        if (Test-IXSamePath $target $path) {
            [IO.File]::Delete($shortcut)
        }
    }
    return $found
}

# ---------------------------------------------------------------------------
# Apps & features entry (Windows only)

# %LOCALAPPDATA%\InfiniteExpansion: the setup's copy of itself, downloaded
# updates, and its settings. $null where there is no LOCALAPPDATA (not Windows).
function Get-IXDataDir {
    if (-not $env:LOCALAPPDATA) {
        return $null
    }
    return Join-IXPath $env:LOCALAPPDATA @('InfiniteExpansion')
}

# Where the setup keeps a copy of itself and the mod, for uninstalling from
# Windows Settings after the download is gone. The launcher starts this copy to
# update (IXLauncher.cs).
function Get-IXSetupCopyDir {
    $data = Get-IXDataDir
    if (-not $data) {
        return $null
    }
    return Join-IXPath $data @('Setup')
}

# Copies the setup (installer\ and mods\infinite_expansion\ below $SetupRoot) to
# $Destination, over the copy of an older version, whose files this one no
# longer has are deleted. The folder itself stays: an older setup handing over
# to this one may still be running from it (Updates below).
function Copy-IXSetup {
    param([string]$SetupRoot, [string]$Destination)
    if (Test-IXSamePath $SetupRoot $Destination) {
        return
    }
    $copied = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($folder in @('installer', 'mods\infinite_expansion')) {
        $source = Join-IXPath $SetupRoot @($folder)
        if (-not [IO.Directory]::Exists($source)) {
            continue
        }
        $sourceFull = Get-IXFullPath $source
        foreach ($file in [IO.Directory]::GetFiles($sourceFull, '*', [IO.SearchOption]::AllDirectories)) {
            $destinationFile = Join-IXPath $Destination @($folder, $file.Substring($sourceFull.Length + 1))
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destinationFile)) | Out-Null
            [IO.File]::Copy($file, $destinationFile, $true)
            [void]$copied.Add((Get-IXFullPath $destinationFile))
        }
    }
    if (-not [IO.Directory]::Exists($Destination)) {
        return
    }
    foreach ($file in [IO.Directory]::GetFiles((Get-IXFullPath $Destination), '*', [IO.SearchOption]::AllDirectories)) {
        if ($copied.Contains((Get-IXFullPath $file))) {
            continue
        }
        try {
            [IO.File]::Delete($file)
            Remove-IXEmptyParents $Destination $file
        }
        catch {
        }
    }
}

# Adds "Infinite Expansion" to Windows Settings > Apps, for the current user.
# Returns $true when the entry was written.
function Register-IXUninstaller {
    param([string]$GameDir, [string]$Version, [string]$SetupRoot)
    $copy = Get-IXSetupCopyDir
    if (-not $copy) {
        return $false
    }
    Copy-IXSetup $SetupRoot $copy
    $script = Join-IXPath $copy @('installer', 'IXSetup.ps1')
    $game = $GameDir.TrimEnd('\', '/')
    $command = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + $script + '" -Uninstall -GameDir "' + $game + '"'
    $values = [ordered]@{
        DisplayName     = 'Infinite Expansion (Infinite Warfare zombies mod)'
        DisplayVersion  = [string]$Version
        Publisher       = 'Infinite Expansion'
        InstallLocation = (Get-IXTarget $game)
        DisplayIcon     = (Join-IXPath $copy @('installer', 'ix.ico'))
        UninstallString = $command
        URLInfoAbout    = $IXProjectUrl
    }
    try {
        New-Item -Path $IXUninstallKey -Force | Out-Null
        foreach ($name in $values.Keys) {
            New-ItemProperty -LiteralPath $IXUninstallKey -Name $name -Value $values[$name] -PropertyType String -Force | Out-Null
        }
        New-ItemProperty -LiteralPath $IXUninstallKey -Name 'NoModify' -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -LiteralPath $IXUninstallKey -Name 'NoRepair' -Value 1 -PropertyType DWord -Force | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Removes the Settings entry, downloaded updates, the setup's settings and the
# setup copy, unless the copy is running ($RunningFrom). Returns $true when the
# copy still has to be removed after the window closes.
function Unregister-IXUninstaller {
    param([string]$RunningFrom)
    try {
        if (Test-Path -LiteralPath $IXUninstallKey) {
            Remove-Item -LiteralPath $IXUninstallKey -Recurse -Force
        }
    }
    catch {
    }
    $updates = Get-IXUpdatesDir
    Remove-IXOldUpdates $updates $RunningFrom
    try {
        if ($updates -and [IO.Directory]::Exists($updates) -and @([IO.Directory]::GetFileSystemEntries($updates)).Count -eq 0) {
            [IO.Directory]::Delete($updates)
        }
        $settings = Get-IXSettingsPath
        if ($settings -and [IO.File]::Exists($settings)) {
            [IO.File]::Delete($settings)
        }
    }
    catch {
    }
    $copy = Get-IXSetupCopyDir
    if (-not $copy -or -not [IO.Directory]::Exists($copy)) {
        return $false
    }
    if (Test-IXSamePath $RunningFrom $copy) {
        return $true
    }
    try {
        [IO.Directory]::Delete($copy, $true)
    }
    catch {
    }
    return $false
}

# ---------------------------------------------------------------------------
# Updates (README "Updates")
#
# .github/workflows/release.yml publishes a GitHub release for each version of
# the mod: tag v<version>, with Infinite-Expansion-<version>.zip, the whole
# download under an Infinite-Expansion\ folder. The launcher looks for a newer
# one each time it starts the game and hands over to the setup copy
# (IXSetup.ps1 -Update); the setup window looks when it opens. The download is
# checked against the SHA-256 GitHub lists for it, unpacked below
# %LOCALAPPDATA%\InfiniteExpansion\Updates, and the new version's own setup
# installs it, so each version installs itself the way it was written to.

# "v0.3.2" or "0.3.2" as "0.3.2"; $null unless it is one to four numbers.
function ConvertTo-IXVersion {
    param([string]$Text)
    $value = ([string]$Text).Trim()
    if ($value -match '^[vV]') {
        $value = $value.Substring(1)
    }
    if ($value -notmatch '^\d{1,6}(\.\d{1,6}){0,3}$') {
        return $null
    }
    return $value
}

# 1, 0 or -1 as version $A is newer than, the same as or older than $B. Missing
# numbers count as 0 ("0.4" is "0.4.0"), and so does text that is no version.
function Compare-IXVersion {
    param([string]$A, [string]$B)
    $left = ConvertTo-IXVersion $A
    $right = ConvertTo-IXVersion $B
    if (-not $left) {
        $left = '0'
    }
    if (-not $right) {
        $right = '0'
    }
    # Not $a / $b: PowerShell names ignore case, and those are the [string] parameters.
    $leftParts = @($left.Split([char]'.'))
    $rightParts = @($right.Split([char]'.'))
    for ($i = 0; $i -lt 4; $i++) {
        $x = 0
        $y = 0
        if ($i -lt $leftParts.Count) {
            $x = [int]$leftParts[$i]
        }
        if ($i -lt $rightParts.Count) {
            $y = [int]$rightParts[$i]
        }
        if ($x -gt $y) {
            return 1
        }
        if ($x -lt $y) {
            return -1
        }
    }
    return 0
}

# The HTTP status of a failed request (404 and so on), or 0.
function Get-IXHttpStatus {
    param($ErrorRecord)
    $exception = $ErrorRecord.Exception
    while ($exception) {
        if ($exception -is [Net.WebException] -and $null -ne $exception.Response) {
            return [int]$exception.Response.StatusCode
        }
        $exception = $exception.InnerException
    }
    return 0
}

# The newest release: its version and tag, the zip's address and size, the
# SHA-256 GitHub lists for it ($null if none) and the release page; $null when
# the project has no release yet. Throws when GitHub cannot be reached, or the
# release is not one this setup can install: its zip must be on the project's
# own release downloads ($Downloads).
function Get-IXLatestRelease {
    param([string]$ApiUrl = $IXReleaseApi, [string]$Downloads = $IXReleaseDownloads)
    Enable-IXTls12
    try {
        $text = Invoke-IXHttpText $ApiUrl
    }
    catch {
        if ((Get-IXHttpStatus $_) -eq 404) {
            return $null
        }
        throw
    }
    $release = $text | ConvertFrom-Json
    $tag = [string]$release.tag_name
    $version = ConvertTo-IXVersion $tag
    if (-not $version) {
        throw ("the newest release is called '" + $tag + "', which is not a version number")
    }
    foreach ($asset in @($release.assets)) {
        if ([string]$asset.name -notmatch '^Infinite-Expansion-[\w.-]+\.zip$') {
            continue
        }
        $url = [string]$asset.browser_download_url
        if (-not $url.StartsWith($Downloads, [StringComparison]::Ordinal)) {
            throw ('the download of release ' + $tag + ' is not on the project''s GitHub page')
        }
        $hash = $null
        $digest = [string]$asset.digest
        if ($digest.StartsWith('sha256:')) {
            $hash = $digest.Substring(7).ToUpperInvariant()
        }
        return [pscustomobject]@{
            Version = $version
            Tag     = $tag
            Url     = $url
            Size    = [long]$asset.size
            Hash    = $hash
            Page    = [string]$release.html_url
        }
    }
    throw ('release ' + $tag + ' has no Infinite-Expansion zip')
}

function Get-IXUpdatesDir {
    $data = Get-IXDataDir
    if (-not $data) {
        return $null
    }
    return Join-IXPath $data @('Updates')
}

# Unpacks $Zip into $Destination. Refuses entries that would land outside it
# (".." or absolute paths) and more than $IXUpdateMaxBytes in all.
function Expand-IXZip {
    param([string]$Zip, [string]$Destination)
    Add-Type -AssemblyName System.IO.Compression
    $root = Get-IXFullPath $Destination
    [IO.Directory]::CreateDirectory($root) | Out-Null
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    $stream = [IO.File]::OpenRead($Zip)
    try {
        $archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Read)
        try {
            $total = 0
            foreach ($entry in $archive.Entries) {
                $name = $entry.FullName.Replace('\', '/')
                if ($name -match '(^|/)\.\.(/|$)' -or $name.StartsWith('/') -or $name.Contains(':')) {
                    throw ('the download has a file outside its folder: ' + $name)
                }
                $path = [IO.Path]::GetFullPath((Join-IXPath $root @($name)))
                if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                    throw ('the download has a file outside its folder: ' + $name)
                }
                if ($name.EndsWith('/')) {
                    [IO.Directory]::CreateDirectory($path) | Out-Null
                    continue
                }
                $total += $entry.Length
                if ($total -gt $IXUpdateMaxBytes) {
                    throw 'the download unpacks to more than 64 MB'
                }
                [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
                $source = $entry.Open()
                try {
                    $target = [IO.File]::Create($path)
                    try {
                        $source.CopyTo($target)
                    }
                    finally {
                        $target.Close()
                    }
                }
                finally {
                    $source.Close()
                }
            }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $stream.Close()
    }
}

# The folder of an unpacked download that holds installer\ and mods\ (the
# download's own folder, or the one folder in it), or $null.
function Find-IXDownloadRoot {
    param([string]$Folder)
    foreach ($candidate in @($Folder) + @([IO.Directory]::GetDirectories($Folder))) {
        if ([IO.File]::Exists((Join-IXPath $candidate @('installer', 'IXSetup.ps1'))) -and
            [IO.Directory]::Exists((Join-IXPath $candidate @('mods', 'infinite_expansion')))) {
            return $candidate
        }
    }
    return $null
}

# Downloads $Release's zip into a new folder below $UpdatesDir, checks its size
# and SHA-256, unpacks it, and checks that it holds that version. Returns the
# folder with its installer\ and mods\. Leaves nothing behind when a check fails.
# $Progress, a synchronized hashtable, gets Phase, Done and Total.
function Save-IXUpdate {
    param($Release, [string]$UpdatesDir, $Progress)
    if (-not $UpdatesDir) {
        throw 'there is no folder for updates (LOCALAPPDATA is not set)'
    }
    [IO.Directory]::CreateDirectory($UpdatesDir) | Out-Null
    $folder = Join-IXPath $UpdatesDir @($Release.Version + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    $zip = $folder + '.zip'
    try {
        if ($null -ne $Progress) {
            $Progress.Phase = 'Downloading Infinite Expansion ' + $Release.Version + ' from GitHub'
        }
        Save-IXHttpFile $Release.Url $zip $Progress
        $size = (New-Object System.IO.FileInfo $zip).Length
        if ($Release.Size -gt 0 -and $size -ne $Release.Size) {
            throw ('the download has ' + $size + ' bytes; the release lists ' + $Release.Size)
        }
        if ($Release.Hash -and (Get-IXFileHash $zip 'SHA256') -ne $Release.Hash) {
            throw 'SHA256 checksum mismatch'
        }
        if ($null -ne $Progress) {
            $Progress.Phase = 'Unpacking Infinite Expansion ' + $Release.Version
        }
        Expand-IXZip $zip $folder
        $root = Find-IXDownloadRoot $folder
        if (-not $root) {
            throw 'the download has no installer folder'
        }
        $version = Get-IXPackageVersion (Join-IXPath $root @('mods', 'infinite_expansion'))
        if ($version -ne $Release.Version) {
            throw ('the download holds version ' + $version + ', not ' + $Release.Version)
        }
        return $root
    }
    catch {
        if ([IO.Directory]::Exists($folder)) {
            try {
                [IO.Directory]::Delete($folder, $true)
            }
            catch {
            }
        }
        throw
    }
    finally {
        if ([IO.File]::Exists($zip)) {
            try {
                [IO.File]::Delete($zip)
            }
            catch {
            }
        }
    }
}

# Deletes downloaded updates, except the one the setup runs from ($Keep, a
# folder in it or below it). A folder in use stays for next time.
function Remove-IXOldUpdates {
    param([string]$UpdatesDir, [string]$Keep)
    if (-not $UpdatesDir -or -not [IO.Directory]::Exists($UpdatesDir)) {
        return
    }
    $keepFull = $null
    if ($Keep) {
        $keepFull = (Get-IXFullPath $Keep) + [IO.Path]::DirectorySeparatorChar
    }
    foreach ($dir in [IO.Directory]::GetDirectories($UpdatesDir)) {
        if ($keepFull -and $keepFull.StartsWith((Get-IXFullPath $dir) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        try {
            [IO.Directory]::Delete($dir, $true)
        }
        catch {
        }
    }
    foreach ($file in [IO.Directory]::GetFiles($UpdatesDir, '*.zip')) {
        try {
            [IO.File]::Delete($file)
        }
        catch {
        }
    }
}

# The setup's own settings: key=value lines in %LOCALAPPDATA%\InfiniteExpansion\
# settings.ini, which the launcher reads too. AutoUpdate=0: the launcher does
# not look for updates.
function Get-IXSettingsPath {
    $data = Get-IXDataDir
    if (-not $data) {
        return $null
    }
    return Join-IXPath $data @('settings.ini')
}

function Get-IXAutoUpdate {
    $path = Get-IXSettingsPath
    if (-not $path -or -not [IO.File]::Exists($path)) {
        return $true
    }
    foreach ($line in [IO.File]::ReadAllLines($path)) {
        if ($line -match '^\s*AutoUpdate\s*=\s*0\s*$') {
            return $false
        }
    }
    return $true
}

# Returns $false where there is no settings folder (not Windows).
function Set-IXAutoUpdate {
    param([bool]$On)
    $path = Get-IXSettingsPath
    if (-not $path) {
        return $false
    }
    $lines = New-Object System.Collections.Generic.List[string]
    if ([IO.File]::Exists($path)) {
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ($line -notmatch '^\s*AutoUpdate\s*=') {
                $lines.Add($line)
            }
        }
    }
    $value = '1'
    if (-not $On) {
        $value = '0'
    }
    $lines.Add('AutoUpdate=' + $value)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
    [IO.File]::WriteAllLines($path, $lines.ToArray())
    return $true
}

# The game's command line the launcher passed on (Base64 of UTF-8 text, so it
# survives being passed between programs), or ''.
function ConvertFrom-IXPlayArgs {
    param([string]$Encoded)
    if (-not $Encoded) {
        return ''
    }
    try {
        return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Encoded))
    }
    catch {
        return ''
    }
}

# One argument for a Windows command line, quoted the way programs split them
# again (CommandLineToArgvW rules, as the launcher's Quote does).
function ConvertTo-IXArgument {
    param([string]$Value)
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }
    $text = New-Object System.Text.StringBuilder
    [void]$text.Append('"')
    $backslashes = 0
    foreach ($c in $Value.ToCharArray()) {
        if ($c -eq [char]'\') {
            $backslashes++
            continue
        }
        if ($c -eq [char]'"') {
            [void]$text.Append([char]'\', $backslashes * 2 + 1)
        }
        else {
            [void]$text.Append([char]'\', $backslashes)
        }
        $backslashes = 0
        [void]$text.Append($c)
    }
    [void]$text.Append([char]'\', $backslashes * 2)
    [void]$text.Append('"')
    return $text.ToString()
}

# The PowerShell running this script: Windows PowerShell for the setup.
function Get-IXPowerShellPath {
    return (Get-Process -Id $PID).Path
}

# Arguments for PowerShell to run the setup $Script with $Arguments; $Window: a
# setup window, which needs one thread for WPF and no console (Windows only).
function Get-IXSetupArguments {
    param([string]$Script, [string[]]$Arguments, [bool]$Window)
    $list = @('-NoProfile', '-ExecutionPolicy', 'Bypass')
    if ($Window -and $env:OS -eq 'Windows_NT') {
        $list += @('-STA', '-WindowStyle', 'Hidden')
    }
    return @($list + @('-File', $Script) + @($Arguments))
}

# Starts the setup window of the download in $Root with $Arguments: the new
# version installs itself.
function Start-IXSetupFrom {
    param([string]$Root, [string[]]$Arguments)
    $script = Join-IXPath $Root @('installer', 'IXSetup.ps1')
    $line = (@(Get-IXSetupArguments $script $Arguments $true) | ForEach-Object { ConvertTo-IXArgument $_ }) -join ' '
    Start-Process -FilePath (Get-IXPowerShellPath) -ArgumentList $line -WorkingDirectory $Root | Out-Null
}
