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
# uninstalling removes exactly those files and leaves other mods alone.

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
$IXShortcutName = 'IW7-Mod (Infinite Warfare).lnk'
# The player's Steam name, for the mod's menu script, which sets iw7-mod's "name"
# setting from it while that is still iw7-mod's default "Unknown Soldier".
$IXPlayerNameFile = 'ui_scripts/InfiniteExpansion/steam-name.txt'

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

# Relative paths, with /, of every file the package installs, sorted.
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
    return @($files | Sort-Object)
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
    }
    if ($state.GameFound) {
        $target = Get-IXTarget $GameDir
        $state.ClientFound = [IO.File]::Exists((Join-Path $GameDir $IXClientExe))
        $state.HasRecord = [IO.File]::Exists((Join-Path $target $IXRecordName))
        $state.Installed = $state.HasRecord -or [IO.File]::Exists((Join-IXPath $target @('custom_scripts', 'cp', 'ix_main.gsc')))
        if ($state.Installed) {
            $state.InstalledVersion = Get-IXPackageVersion $target
        }
        $state.OldCopy = Test-IXOldCopy $GameDir
    }
    return [pscustomobject]$state
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

# Removes the recorded files (or, without a record, the package's own file list),
# the record, and the Mods-menu copy.
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
    $old = Remove-IXOldCopy $GameDir $files
    return [pscustomobject]@{
        Target         = $target
        Removed        = $removed
        OldCopyRemoved = $old.Removed
        OldCopyLeft    = $old.Left
        OldCopyPath    = $old.Path
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

# A desktop shortcut that starts iw7-mod from the game folder. Windows only; returns its path or $null.
function New-IXShortcut {
    param([string]$GameDir)
    if ($env:OS -ne 'Windows_NT') {
        return $null
    }
    $desktop = [Environment]::GetFolderPath('Desktop')
    if (-not $desktop) {
        return $null
    }
    $path = Join-Path $desktop $IXShortcutName
    $exe = Join-Path $GameDir $IXClientExe
    $shell = New-Object -ComObject WScript.Shell
    $link = $shell.CreateShortcut($path)
    $link.TargetPath = $exe
    $link.WorkingDirectory = $GameDir
    $link.IconLocation = $exe + ',0'
    $link.Description = 'Call of Duty: Infinite Warfare with the iw7-mod client'
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

# Starts iw7-mod.exe the way its install guide says: from the game folder.
function Start-IXGame {
    param([string]$GameDir)
    $exe = Join-Path $GameDir $IXClientExe
    if (-not [IO.File]::Exists($exe)) {
        throw "$IXClientExe is not in the game folder."
    }
    Start-Process -FilePath $exe -WorkingDirectory $GameDir | Out-Null
}

# ---------------------------------------------------------------------------
# Apps & features entry (Windows only)

# Where the setup keeps a copy of itself and the mod, for uninstalling from
# Windows Settings after the download is gone.
function Get-IXSetupCopyDir {
    if (-not $env:LOCALAPPDATA) {
        return $null
    }
    return Join-IXPath $env:LOCALAPPDATA @('InfiniteExpansion', 'Setup')
}

# Copies the setup (installer\ and mods\infinite_expansion\ below $SetupRoot) to $Destination.
function Copy-IXSetup {
    param([string]$SetupRoot, [string]$Destination)
    if (Test-IXSamePath $SetupRoot $Destination) {
        return
    }
    if ([IO.Directory]::Exists($Destination)) {
        [IO.Directory]::Delete($Destination, $true)
    }
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

# Removes the Settings entry and the setup copy, unless the copy is running ($RunningFrom).
# Returns $true when the copy still has to be removed after the window closes.
function Unregister-IXUninstaller {
    param([string]$RunningFrom)
    try {
        if (Test-Path -LiteralPath $IXUninstallKey) {
            Remove-Item -LiteralPath $IXUninstallKey -Recurse -Force
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
