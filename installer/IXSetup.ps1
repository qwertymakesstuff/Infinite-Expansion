<#
Infinite Expansion - setup window.

Start it with "Infinite Expansion Setup.cmd", next to the installer folder. It finds
Infinite Warfare through Steam, shows what is installed, and installs or uninstalls the
mod with one click (the logic is in IXSetup.Core.ps1). After installing, Windows
Settings > Apps lists the mod, and uninstalling there runs this script with -Uninstall.

Switches:
  -GameDir <folder>   use this game folder instead of looking in Steam
  -Install            install as soon as the window opens (used after "run as administrator")
  -Uninstall          uninstall as soon as the window opens (Windows Settings > Apps)
  -NoWindow           no window: install (or uninstall, with -Uninstall), print the result,
                      and exit with 0 or 1

Windows PowerShell 5.1 runs this file, so it stays ASCII and avoids PowerShell 7 syntax
(tools/tests/test_installer.py checks both).
#>
param(
    [string]$GameDir,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$NoWindow
)

$ErrorActionPreference = 'Stop'
$SetupRoot = Split-Path -Parent $PSScriptRoot
$PackageRoot = Join-Path (Join-Path $SetupRoot 'mods') 'infinite_expansion'
$ScriptPath = $PSCommandPath
$LogPath = Join-Path ([IO.Path]::GetTempPath()) 'InfiniteExpansionSetup.log'
. (Join-Path $PSScriptRoot 'IXSetup.Core.ps1')

# Every control this script uses; each must be an x:Name in IXSetup.xaml.
$IXControlNames = @(
    'TitleBar', 'MinButton', 'CloseButton', 'VersionText',
    'GameDot', 'GameText', 'BrowseButton',
    'ClientDot', 'ClientText', 'ClientLink',
    'ModDot', 'ModText', 'NoteText',
    'InstallButton', 'UninstallButton', 'StatusTitle', 'StatusText', 'RepoLink'
)

$Colors = @{
    Ok   = '#39FF14'
    Warn = '#FFE66D'
    Bad  = '#FF2E97'
    Off  = '#6C6285'
    Info = '#22E4FF'
}
$Dash = [string][char]0x2014
$Middot = [string][char]0x00B7

function Write-IXLog {
    param([string]$Text)
    try {
        [IO.File]::AppendAllText($LogPath, (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '  ' + $Text + [Environment]::NewLine)
    }
    catch {
    }
}

function Resolve-IXGameDir {
    if ($GameDir) {
        return $GameDir.TrimEnd('\', '/')
    }
    return Find-IXGameDir
}

# True when the error is Windows refusing access (a protected game folder).
function Test-IXAccessDenied {
    param($ErrorRecord)
    $exception = $ErrorRecord.Exception
    while ($exception) {
        if ($exception -is [UnauthorizedAccessException]) {
            return $true
        }
        if ($exception -is [IO.IOException] -and ($exception.HResult -band 0xFFFF) -eq 5) {
            return $true
        }
        $exception = $exception.InnerException
    }
    return $false
}

# ---------------------------------------------------------------------------
# Without a window

if ($NoWindow) {
    try {
        $dir = Resolve-IXGameDir
        if (-not (Test-IXGameDir $dir)) {
            throw 'Infinite Warfare was not found. Pass -GameDir "<game folder>".'
        }
        if ($Uninstall) {
            $result = Uninstall-IX $dir $PackageRoot
            Unregister-IXUninstaller $SetupRoot | Out-Null
            Write-Output ('Removed {0} files from {1}.' -f $result.Removed, $result.Target)
        }
        else {
            $result = Install-IX $dir $PackageRoot
            Register-IXUninstaller $dir (Get-IXPackageVersion $PackageRoot) $SetupRoot | Out-Null
            Write-Output ('Installed {0} files into {1}.' -f $result.Copied, $result.Target)
        }
        exit 0
    }
    catch {
        [Console]::Error.WriteLine($_.Exception.Message)
        exit 1
    }
}

# ---------------------------------------------------------------------------
# The window

function Show-IXFatal {
    param([string]$Message)
    Write-IXLog ('FATAL ' + $Message)
    try {
        Add-Type -AssemblyName PresentationFramework
        [void][System.Windows.MessageBox]::Show($Message + "`n`nLog: " + $LogPath, 'Infinite Expansion Setup', 'OK', 'Error')
    }
    catch {
        Write-Host $Message
    }
}

try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    $stream = [IO.File]::OpenRead((Join-Path $PSScriptRoot 'IXSetup.xaml'))
    try {
        $window = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create($stream))
    }
    finally {
        $stream.Close()
    }
}
catch {
    Show-IXFatal ('The setup window could not be opened: ' + $_.Exception.Message)
    exit 1
}

$ui = @{}
foreach ($name in $IXControlNames) {
    $control = $window.FindName($name)
    if ($null -eq $control) {
        Show-IXFatal ("The setup window has no control named '" + $name + "'.")
        exit 1
    }
    $ui[$name] = $control
}

$BrushConverter = New-Object System.Windows.Media.BrushConverter

function New-IXBrush {
    param([string]$Color)
    return $BrushConverter.ConvertFromString($Color)
}

function Set-IXDot {
    param($Dot, [string]$Color)
    $Dot.Fill = New-IXBrush $Color
    if ($Color -eq $Colors.Off) {
        $Dot.Effect = $null
        return
    }
    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString($Color)
    $glow.BlurRadius = 10
    $glow.ShadowDepth = 0
    $glow.Opacity = 0.9
    $Dot.Effect = $glow
}

function Set-IXStatus {
    param([string]$Title, [string]$Text, [string]$Color)
    $ui.StatusTitle.Text = $Title
    $ui.StatusTitle.Foreground = New-IXBrush $Color
    $ui.StatusText.Text = $Text
}

# Reads the state of the game folder and updates every row and button.
function Update-IXView {
    $state = Get-IXState $script:GameDir $PackageRoot
    $script:State = $state

    if ($state.PackageVersion) {
        $ui.VersionText.Text = 'v' + $state.PackageVersion
    }
    else {
        $ui.VersionText.Text = 'uninstaller'
    }

    if ($state.GameFound) {
        Set-IXDot $ui.GameDot $Colors.Ok
        $ui.GameText.Text = $state.GameDir
        $ui.GameText.ToolTip = $state.GameDir
    }
    else {
        Set-IXDot $ui.GameDot $Colors.Bad
        $ui.GameText.Text = 'Not found ' + $Dash + ' click BROWSE'
        $ui.GameText.ToolTip = $null
    }

    $ui.ClientLink.Visibility = 'Collapsed'
    if (-not $state.GameFound) {
        Set-IXDot $ui.ClientDot $Colors.Off
        $ui.ClientText.Text = 'Waiting for the game folder'
    }
    elseif ($state.ClientFound) {
        Set-IXDot $ui.ClientDot $Colors.Ok
        $ui.ClientText.Text = 'Found (iw7-mod.exe)'
    }
    else {
        Set-IXDot $ui.ClientDot $Colors.Warn
        $ui.ClientText.Text = 'No iw7-mod.exe in the game folder'
        $ui.ClientLink.Visibility = 'Visible'
    }

    $outdated = $state.Installed -and $state.PackageVersion -and ($state.InstalledVersion -ne $state.PackageVersion)
    if (-not $state.GameFound) {
        Set-IXDot $ui.ModDot $Colors.Off
        $ui.ModText.Text = '-'
    }
    elseif ($state.Installed) {
        $text = 'Installed'
        if ($state.InstalledVersion) {
            $text = $text + ' ' + $Middot + ' v' + $state.InstalledVersion
        }
        if (-not $state.HasRecord) {
            $text = $text + ' (copied by hand)'
        }
        if ($outdated) {
            $text = $text + ' ' + $Dash + ' v' + $state.PackageVersion + ' is ready'
            Set-IXDot $ui.ModDot $Colors.Warn
        }
        else {
            Set-IXDot $ui.ModDot $Colors.Ok
        }
        $ui.ModText.Text = $text
    }
    else {
        Set-IXDot $ui.ModDot $Colors.Off
        $ui.ModText.Text = 'Not installed'
    }

    if ($outdated) {
        $ui.InstallButton.Content = 'UPDATE'
    }
    elseif ($state.Installed) {
        $ui.InstallButton.Content = 'REINSTALL'
    }
    else {
        $ui.InstallButton.Content = 'INSTALL'
    }
    $ui.InstallButton.IsEnabled = $state.GameFound -and $state.PackageFound
    $ui.UninstallButton.IsEnabled = $state.GameFound -and ($state.Installed -or $state.OldCopy)

    # One short line each: the window has room for about two.
    $notes = @()
    if ($state.GameFound -and $state.OldCopy) {
        $notes += 'Old Mods-menu copy found: installing removes it.'
    }
    if (-not $state.PackageFound) {
        $notes += 'Mod files not found next to the setup: uninstall only.'
    }
    if ($state.GameRunning) {
        $notes += 'The game is running: restart it afterwards.'
    }
    if ($notes.Count -gt 0) {
        $ui.NoteText.Text = $notes -join [Environment]::NewLine
        $ui.NoteText.ToolTip = 'The Mods-menu copy (mods\infinite_expansion) makes your game impossible to join for friends. This setup installs into the iw7-mod folder instead.'
        $ui.NoteText.Visibility = 'Visible'
    }
    else {
        $ui.NoteText.Visibility = 'Collapsed'
    }
}

# The message under the buttons when nothing has happened yet.
function Set-IXReadyStatus {
    $state = $script:State
    if (-not $state.GameFound) {
        Set-IXStatus 'GAME NOT FOUND' 'Steam does not list Infinite Warfare here. Click BROWSE and pick iw7_ship.exe in the game folder.' $Colors.Bad
    }
    elseif (-not $state.PackageFound) {
        Set-IXStatus 'UNINSTALL ONLY' 'To install, run the setup from the full download.' $Colors.Warn
    }
    elseif ($state.Installed -and $state.HasRecord -and $state.InstalledVersion -eq $state.PackageVersion) {
        Set-IXStatus 'INSTALLED' 'Start a zombies match. The dead are waiting.' $Colors.Ok
    }
    elseif ($state.Installed) {
        Set-IXStatus 'UPDATE READY' ('Click ' + $ui.InstallButton.Content + ' to replace the installed files.') $Colors.Warn
    }
    else {
        Set-IXStatus 'READY' 'Click INSTALL. It copies the mod into the game''s iw7-mod folder and adds an uninstall entry to Windows Settings.' $Colors.Ok
    }
}

function Start-IXElevated {
    param([string]$Action)
    $switch = '-Install'
    if ($Action -eq 'uninstall') {
        $switch = '-Uninstall'
    }
    $arguments = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + $ScriptPath + '" ' + $switch + ' -GameDir "' + $script:GameDir.TrimEnd('\', '/') + '"'
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs | Out-Null
        $window.Close()
    }
    catch {
        Set-IXStatus 'NOTHING CHANGED' 'Administrator rights were not granted.' $Colors.Bad
    }
}

function Invoke-IXFailure {
    param($ErrorRecord, [string]$Action)
    Write-IXLog ($Action + ' failed: ' + $ErrorRecord.Exception.ToString())
    try {
        Update-IXView
    }
    catch {
        Write-IXLog ('refresh failed: ' + $_.Exception.Message)
    }
    if (Test-IXAccessDenied $ErrorRecord) {
        $answer = [System.Windows.MessageBox]::Show($window, "Windows did not allow changes in the game folder.`n`nTry again as administrator?", 'Infinite Expansion Setup', 'YesNo', 'Warning')
        if ($answer -eq 'Yes') {
            Start-IXElevated $Action
            return
        }
    }
    Set-IXStatus 'SOMETHING WENT WRONG' ($ErrorRecord.Exception.Message + ' Details: ' + $LogPath) $Colors.Bad
}

function Get-IXOldCopyText {
    param($Result)
    $text = ''
    if ($Result.OldCopyRemoved -gt 0) {
        $text = ' Removed the old Mods-menu copy.'
    }
    if ($Result.OldCopyLeft -gt 0) {
        $text = $text + ' ' + $Result.OldCopyLeft + ' file(s) of your own stay in ' + $Result.OldCopyPath + '.'
    }
    return $text
}

function Invoke-IXInstall {
    try {
        $result = Install-IX $script:GameDir $PackageRoot
        $registered = Register-IXUninstaller $script:GameDir (Get-IXPackageVersion $PackageRoot) $SetupRoot
        $script:RemoveCopyOnExit = $false
        Write-IXLog ('installed ' + $result.Copied + ' files into ' + $result.Target)
        $text = 'Copied ' + $result.Copied + ' files into ' + $result.Target + '.'
        if ($result.StaleRemoved -gt 0) {
            $text = $text + ' Removed ' + $result.StaleRemoved + ' file(s) an older version left.'
        }
        $text = $text + (Get-IXOldCopyText $result)
        if ($registered) {
            $text = $text + ' Uninstall here or in Windows Settings > Apps.'
        }
        Update-IXView
        Set-IXStatus 'INSTALLED' ($text + ' Start a zombies match. The dead are waiting.') $Colors.Ok
    }
    catch {
        Invoke-IXFailure $_ 'install'
    }
}

function Invoke-IXUninstall {
    try {
        $result = Uninstall-IX $script:GameDir $PackageRoot
        $script:RemoveCopyOnExit = Unregister-IXUninstaller $SetupRoot
        Write-IXLog ('removed ' + $result.Removed + ' files from ' + $result.Target)
        $text = 'Removed ' + $result.Removed + ' files from ' + $result.Target + '.' + (Get-IXOldCopyText $result)
        Update-IXView
        Set-IXStatus 'UNINSTALLED' ($text + ' Infinite Expansion has been laid to rest.') $Colors.Bad
    }
    catch {
        Invoke-IXFailure $_ 'uninstall'
    }
}

function Invoke-IXBrowse {
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Title = 'Pick iw7_ship.exe in your Infinite Warfare folder'
    $dialog.Filter = 'Infinite Warfare (iw7_ship.exe)|iw7_ship.exe|Programs (*.exe)|*.exe'
    if ($script:GameDir -and [IO.Directory]::Exists($script:GameDir)) {
        $dialog.InitialDirectory = $script:GameDir
    }
    if ($dialog.ShowDialog($window)) {
        $dir = Split-Path -Parent $dialog.FileName
        if (Test-IXGameDir $dir) {
            $script:GameDir = $dir
            Update-IXView
            Set-IXReadyStatus
        }
        else {
            Set-IXStatus 'NOT THE GAME FOLDER' ('There is no iw7_ship.exe in ' + $dir + '.') $Colors.Bad
        }
    }
}

try {
    $icon = New-Object System.Windows.Media.Imaging.BitmapImage
    $icon.BeginInit()
    $icon.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $icon.UriSource = New-Object System.Uri (Join-Path $PSScriptRoot 'ix.ico')
    $icon.EndInit()
    $window.Icon = $icon
}
catch {
    Write-IXLog ('icon: ' + $_.Exception.Message)
}

$ui.TitleBar.Add_MouseLeftButtonDown({
        try {
            $window.DragMove()
        }
        catch {
        }
    })
$ui.MinButton.Add_Click({ $window.WindowState = 'Minimized' })
$ui.CloseButton.Add_Click({ $window.Close() })
$ui.BrowseButton.Add_Click({ Invoke-IXBrowse })
$ui.ClientLink.Add_Click({ Start-Process $IXClientUrl })
$ui.RepoLink.Add_Click({ Start-Process $IXProjectUrl })
$ui.InstallButton.Add_Click({ Invoke-IXInstall })
$ui.UninstallButton.Add_Click({ Invoke-IXUninstall })
$window.Add_ContentRendered({
        if ($Install -and $ui.InstallButton.IsEnabled) {
            Invoke-IXInstall
        }
        elseif ($Uninstall -and $ui.UninstallButton.IsEnabled) {
            Invoke-IXUninstall
        }
    })

$script:RemoveCopyOnExit = $false
try {
    $script:GameDir = Resolve-IXGameDir
    Update-IXView
    Set-IXReadyStatus
    Write-IXLog ('opened; game folder: ' + $script:GameDir)
}
catch {
    Show-IXFatal ('The setup could not read the game folder: ' + $_.Exception.Message)
    exit 1
}

try {
    [void]$window.ShowDialog()
}
catch {
    Show-IXFatal ('The setup window stopped: ' + $_.Exception.Message)
}

# Uninstalled from the copy Windows Settings runs: remove that copy too.
if ($script:RemoveCopyOnExit) {
    try {
        Set-Location ([IO.Path]::GetTempPath())
        [IO.Directory]::Delete((Get-IXSetupCopyDir), $true)
    }
    catch {
        Write-IXLog ('could not remove the setup copy: ' + $_.Exception.Message)
    }
}
