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

# Copies the package into <game>\iw7-mod\, removes files an older version left
# behind, writes the record, and removes the Mods-menu copy.
function Install-IX {
    param([string]$GameDir, [string]$PackageRoot)
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
