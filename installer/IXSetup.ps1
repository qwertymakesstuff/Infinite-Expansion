<#
Infinite Expansion - setup window.

Start it with "Infinite Expansion Setup.cmd", next to the installer folder. It finds
Infinite Warfare through Steam (or offers Steam's install dialog), downloads the iw7-mod
client when the game folder has none, installs or uninstalls the mod with one click, and
then starts the game (the logic is in IXSetup.Core.ps1). The first install also builds
the character pictures from the player's own game files (IXPictures.Core.ps1), once.
After installing, Windows Settings > Apps lists the mod, and uninstalling there runs this
script with -Uninstall.

Switches:
  -GameDir <folder>   use this game folder instead of looking in Steam
  -Install            install as soon as the window opens (used after "run as administrator")
  -Uninstall          uninstall as soon as the window opens (Windows Settings > Apps)
  -NoPictures         do not build the character pictures
  -ZoneTool <file>    build them with this zonetool.exe instead of downloading x64-zt
  -NoWindow           no window: install (downloading iw7-mod if needed, then building the
                      character pictures), or uninstall with -Uninstall; print the result
                      and exit with 0 or 1 (1 only when the mod itself was not installed)

Windows PowerShell 5.1 runs this file, so it stays ASCII and avoids PowerShell 7 syntax
(tools/tests/test_installer.py checks both).
#>
param(
    [string]$GameDir,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$NoPictures,
    [string]$ZoneTool,
    [switch]$NoWindow
)

$ErrorActionPreference = 'Stop'
$SetupRoot = Split-Path -Parent $PSScriptRoot
$PackageRoot = Join-Path (Join-Path $SetupRoot 'mods') 'infinite_expansion'
$ScriptPath = $PSCommandPath
$CorePath = Join-Path $PSScriptRoot 'IXSetup.Core.ps1'
$PicturesCorePath = Join-Path $PSScriptRoot 'IXPictures.Core.ps1'
$LogPath = Join-Path ([IO.Path]::GetTempPath()) 'InfiniteExpansionSetup.log'
. $CorePath
. $PicturesCorePath

# Every control this script uses; each must be an x:Name in IXSetup.xaml.
$IXControlNames = @(
    'TitleBar', 'MinButton', 'CloseButton', 'VersionText',
    'GameDot', 'GameText', 'SteamLink', 'BrowseButton',
    'ClientDot', 'ClientText', 'ClientLink',
    'ModDot', 'ModText', 'ReinstallLink', 'NoteText',
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

# The innermost message of an error (a failed EndInvoke wraps the script's own error).
function Get-IXErrorText {
    param($ErrorRecord)
    $exception = $ErrorRecord.Exception
    while ($exception.InnerException) {
        $exception = $exception.InnerException
    }
    return $exception.Message
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
            if (-not [IO.File]::Exists((Join-Path $dir $IXClientExe))) {
                $client = Install-IXClient $dir
                Write-Output ('Downloaded {0} ({1}, from {2}).' -f $IXClientExe, $client.Version, $client.Source)
            }
            $player = ConvertTo-IXPlayerName (Get-IXSteamPersonaName)
            $result = Install-IX $dir $PackageRoot $player
            Register-IXUninstaller $dir (Get-IXPackageVersion $PackageRoot) $SetupRoot | Out-Null
            Write-Output ('Installed {0} files into {1}.' -f $result.Copied, $result.Target)
            if ($player) {
                Write-Output ('In-game name: {0} (from Steam).' -f $player)
            }
            # The character pictures, the first time. A failure here leaves the
            # mod installed: the menu shows initials instead.
            if (-not $NoPictures -and -not [IO.File]::Exists((Get-IXPicturePackPath $dir))) {
                Write-Output 'Building the character pictures (first time only, a few minutes)...'
                $pictureLogFile = Get-IXPictureLogPath
                [IO.File]::WriteAllText($pictureLogFile, '')
                $pictureLog = {
                    param([string]$Text, [bool]$Step)
                    if ($Step) {
                        Write-Host ('  ' + $Text + '...')
                        $Text = '== ' + $Text
                    }
                    Write-IXPictureLog $pictureLogFile $Text
                }
                try {
                    $built = Invoke-IXPictureBuild -GameDir $dir -ZoneTool $ZoneTool -Log $pictureLog
                    Write-Output ('Character pictures: {0} in {1}.' -f $built.Pictures, $built.Pack)
                    foreach ($failure in $built.Failed) {
                        Write-Output ('  ' + $failure)
                    }
                }
                catch {
                    Write-Output ('Character pictures could not be built: ' + $_.Exception.Message + ' Details: ' + $pictureLogFile)
                }
            }
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

function Set-IXVisible {
    param($Control, [bool]$Visible)
    if ($Visible) {
        $Control.Visibility = 'Visible'
    }
    else {
        $Control.Visibility = 'Collapsed'
    }
}

# Reads the state of the game folder and updates every row and button.
function Update-IXView {
    $state = Get-IXState $script:GameDir $PackageRoot
    $script:State = $state
    $script:StateText = ConvertTo-Json -InputObject $state -Compress

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
        $ui.GameText.Text = 'Not found ' + $Dash + ' STEAM installs it'
        $ui.GameText.ToolTip = $null
    }
    Set-IXVisible $ui.SteamLink (-not $state.GameFound)

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
        $ui.ClientText.Text = 'Not installed ' + $Dash + ' INSTALL downloads it'
    }
    Set-IXVisible $ui.ClientLink ($state.GameFound -and -not $state.ClientFound)

    $outdated = $state.Installed -and $state.PackageVersion -and (($state.InstalledVersion -ne $state.PackageVersion) -or $state.FilesDiffer)
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
        if ($outdated -and $state.InstalledVersion -eq $state.PackageVersion) {
            $text = $text + ' ' + $Dash + ' newer files are ready'
            Set-IXDot $ui.ModDot $Colors.Warn
        }
        elseif ($outdated) {
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
    Set-IXVisible $ui.ReinstallLink ($state.Installed -and -not $outdated -and $state.PackageFound)
    if ($state.PicturesBuilt -or $NoPictures) {
        $ui.ReinstallLink.ToolTip = 'Copy the mod files again'
    }
    else {
        $ui.ReinstallLink.ToolTip = 'Copy the mod files again and build the character pictures'
    }

    # The green button is always the next step: INSTALL, UPDATE, then PLAY.
    if ($outdated) {
        $ui.InstallButton.Content = 'UPDATE'
    }
    elseif ($state.Installed -and $state.ClientFound) {
        $ui.InstallButton.Content = 'PLAY'
    }
    else {
        $ui.InstallButton.Content = 'INSTALL'
    }
    $ui.InstallButton.IsEnabled = $state.GameFound -and ($state.PackageFound -or $ui.InstallButton.Content -eq 'PLAY')
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
        Set-IXStatus 'GAME NOT FOUND' 'Click STEAM to install Infinite Warfare (you need to own it on Steam); this window notices when it is there. Installed somewhere else? Click BROWSE.' $Colors.Bad
    }
    elseif (-not $state.PackageFound) {
        Set-IXStatus 'UNINSTALL ONLY' 'To install, run the setup from the full download.' $Colors.Warn
    }
    elseif ($ui.InstallButton.Content -eq 'PLAY' -and -not $state.PicturesBuilt -and -not $NoPictures) {
        Set-IXStatus 'READY TO PLAY' 'Click PLAY, then pick Zombies in the main menu. No character pictures yet: REINSTALL builds them (a few minutes, once).' $Colors.Ok
    }
    elseif ($ui.InstallButton.Content -eq 'PLAY') {
        Set-IXStatus 'READY TO PLAY' 'Click PLAY, then pick Zombies in the main menu. The dead are waiting.' $Colors.Ok
    }
    elseif ($ui.InstallButton.Content -eq 'UPDATE') {
        Set-IXStatus 'UPDATE READY' 'Click UPDATE to replace the installed files.' $Colors.Warn
    }
    elseif (-not $state.ClientFound) {
        Set-IXStatus 'READY' 'Click INSTALL. It downloads the iw7-mod client from its official GitHub page, puts it in the game folder with a desktop shortcut, installs Infinite Expansion, then builds its character pictures from your game files (a few minutes, once).' $Colors.Ok
    }
    else {
        Set-IXStatus 'READY' 'Click INSTALL. It copies the mod into the game''s iw7-mod folder, adds an uninstall entry to Windows Settings, then builds the character pictures from your game files (a few minutes, once).' $Colors.Ok
    }
}

# Busy: everything that starts work is disabled until the work is done.
function Set-IXBusy {
    param([bool]$Busy)
    $script:Busy = $Busy
    foreach ($name in @('InstallButton', 'UninstallButton', 'BrowseButton', 'SteamLink', 'ClientLink', 'ReinstallLink')) {
        $ui[$name].IsEnabled = -not $Busy
    }
    if (-not $Busy) {
        Update-IXView
    }
}

function Start-IXElevated {
    param([string]$Action)
    $switch = '-Install'
    if ($Action -eq 'uninstall') {
        $switch = '-Uninstall'
    }
    $arguments = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + $ScriptPath + '" ' + $switch + ' -GameDir "' + $script:GameDir.TrimEnd('\', '/') + '"'
    if ($NoPictures) {
        $arguments = $arguments + ' -NoPictures'
    }
    if ($ZoneTool) {
        $arguments = $arguments + ' -ZoneTool "' + $ZoneTool + '"'
    }
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
    Set-IXStatus 'SOMETHING WENT WRONG' ((Get-IXErrorText $ErrorRecord) + ' Details: ' + $LogPath) $Colors.Bad
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

# What the status line says about the player's name.
function Get-IXNameText {
    param([string]$SteamName, [string]$PlayerName)
    if ($PlayerName) {
        return ' In game you are "' + $PlayerName + '", your Steam name, unless you already picked another name.'
    }
    if ($SteamName) {
        return ' Your Steam name has letters the game cannot show: type  name <your name>  in the game console (~) instead.'
    }
    return ''
}

# Installs the mod. $ClientText describes an iw7-mod download that came first.
function Invoke-IXInstall {
    param([string]$ClientText)
    try {
        $steamName = $null
        try {
            $steamName = Get-IXSteamPersonaName
        }
        catch {
            Write-IXLog ('steam name: ' + $_.Exception.Message)
        }
        $player = ConvertTo-IXPlayerName $steamName
        $result = Install-IX $script:GameDir $PackageRoot $player
        $registered = Register-IXUninstaller $script:GameDir (Get-IXPackageVersion $PackageRoot) $SetupRoot
        $script:RemoveCopyOnExit = $false
        Write-IXLog ('installed ' + $result.Copied + ' files into ' + $result.Target)
        $text = $ClientText + 'Copied ' + $result.Copied + ' mod files into ' + $result.Target + '.'
        if ($result.StaleRemoved -gt 0) {
            $text = $text + ' Removed ' + $result.StaleRemoved + ' file(s) an older version left.'
        }
        $text = $text + (Get-IXOldCopyText $result) + (Get-IXNameText $steamName $player)
        if ($registered) {
            $text = $text + ' Uninstall here or in Windows Settings > Apps.'
        }
        Update-IXView
        Complete-IXInstall $text
    }
    catch {
        Invoke-IXFailure $_ 'install'
    }
}

# After installing: the character pictures, the first time (README "Character
# pictures"). x64-zt cannot run next to the game; then REINSTALL builds them later.
function Complete-IXInstall {
    param([string]$Text)
    if ($NoPictures -or $script:State.PicturesBuilt) {
        Set-IXStatus 'ALL SET' ($Text + ' Click PLAY.') $Colors.Ok
        return
    }
    if (Test-IXGameRunning) {
        Set-IXStatus 'ALL SET' ($Text + ' For the character pictures, close the game and click REINSTALL. Then click PLAY.') $Colors.Ok
        return
    }
    $logFile = Get-IXPictureLogPath
    try {
        [IO.File]::WriteAllText($logFile, 'Game folder: ' + $script:GameDir + [Environment]::NewLine)
    }
    catch {
    }
    Write-IXLog 'building the character pictures'
    $progress = [hashtable]::Synchronized(@{ Done = 0; Total = 0; Phase = 'Starting' })
    Start-IXJob $PictureBuildScript @($script:GameDir, $progress, $logFile, [string]$ZoneTool) $progress @{
        Title   = 'BUILDING CHARACTER PICTURES'
        Prefix  = 'First time only, a few minutes. '
        What    = 'The character pictures are still being built (first time only). Closing stops it; REINSTALL builds them later.'
        Stop    = $true
        Context = $Text
        Then    = {
            param($Built, [string]$Text)
            Write-IXLog ('character pictures: ' + $Built.Pictures + ' in ' + $Built.Pack + '; not copied: ' + $Built.Missing.Count)
            $more = ' Built ' + $Built.Pictures + ' character pictures from your game files'
            if ($Built.Missing.Count -gt 0) {
                $more = $more + ' (' + $Built.Missing.Count + ' cards not found; those show initials)'
            }
            Set-IXStatus 'ALL SET' ($Text + $more + '. Click PLAY.') $Colors.Ok
        }
        Fail    = {
            param([string]$Failure, [string]$Text)
            Write-IXLog ('character pictures failed: ' + $Failure)
            Set-IXStatus 'ALL SET' ($Text + ' The character pictures could not be built (' + $Failure + '), so the menu shows initials; REINSTALL tries again. Details: ' + (Get-IXPictureLogPath) + '. Click PLAY.') $Colors.Warn
        }
    }
}

function Invoke-IXUninstall {
    try {
        $result = Uninstall-IX $script:GameDir $PackageRoot
        $script:RemoveCopyOnExit = Unregister-IXUninstaller $SetupRoot
        Write-IXLog ('removed ' + $result.Removed + ' files from ' + $result.Target)
        $text = 'Removed ' + $result.Removed + ' files from ' + $result.Target + '.' + (Get-IXOldCopyText $result)
        Update-IXView
        Set-IXStatus 'UNINSTALLED' ($text + ' The iw7-mod client stays. Infinite Expansion has been laid to rest.') $Colors.Bad
    }
    catch {
        Invoke-IXFailure $_ 'uninstall'
    }
}

# ---------------------------------------------------------------------------
# Work that takes a while runs in a second PowerShell runspace, so the window
# keeps responding, and a timer shows its progress: the iw7-mod download and the
# character pictures.

$ClientDownloadScript = [IO.File]::ReadAllText($CorePath) + @'

$ErrorActionPreference = 'Stop'
Install-IXClient -GameDir $args[0] -Progress $args[1]
'@

# Both core files, then the build. The log callback is made in that runspace,
# where it runs.
$PictureBuildScript = [IO.File]::ReadAllText($CorePath) + [Environment]::NewLine + [IO.File]::ReadAllText($PicturesCorePath) + @'

$ErrorActionPreference = 'Stop'
$pictureLogFile = $args[2]
$pictureLog = {
    param([string]$Text, [bool]$Step)
    if ($Step) {
        $Text = '== ' + $Text
    }
    Write-IXPictureLog $pictureLogFile $Text
}
Invoke-IXPictureBuild -GameDir $args[0] -Progress $args[1] -Log $pictureLog -ZoneTool $args[3]
'@

# Runs $Script with $Arguments in the background. $Job holds: Title (the status
# title meanwhile), Prefix (text before the progress), What (the question when
# the window closes meanwhile), Stop (stop the work then), Then and Fail (called
# with the result or the error text, then Context).
function Start-IXJob {
    param([string]$Script, [object[]]$Arguments, $Progress, [hashtable]$Job)
    Set-IXBusy $true
    $shell = [PowerShell]::Create()
    [void]$shell.AddScript($Script)
    foreach ($argument in $Arguments) {
        [void]$shell.AddArgument($argument)
    }
    $Job.Shell = $shell
    $Job.Progress = $Progress
    $Job.Handle = $shell.BeginInvoke()
    $script:Job = $Job
    Set-IXStatus $Job.Title ($Job.Prefix + $Progress.Phase + '...') $Colors.Info
    $script:JobTimer.Start()
}

function Start-IXClientDownload {
    param([scriptblock]$Then)
    if ($script:Busy) {
        return
    }
    if (Test-IXGameRunning) {
        Set-IXStatus 'CLOSE THE GAME FIRST' 'iw7-mod.exe cannot be replaced while the game is running.' $Colors.Warn
        return
    }
    try {
        Test-IXWritable $script:GameDir
    }
    catch {
        Invoke-IXFailure $_ 'install'
        return
    }
    $progress = [hashtable]::Synchronized(@{ Done = 0; Total = 0; Phase = 'Looking up the latest iw7-mod' })
    Start-IXJob $ClientDownloadScript @($script:GameDir, $progress) $progress @{
        Title   = 'INSTALLING IW7-MOD'
        Prefix  = ''
        What    = 'iw7-mod is still downloading.'
        Stop    = $false
        Context = $null
        Then    = $Then
        Fail    = {
            param([string]$Failure)
            Write-IXLog ('iw7-mod download failed: ' + $Failure)
            Set-IXStatus 'IW7-MOD DOWNLOAD FAILED' ($Failure + ' You can also download it by hand: ' + $IXClientUrl) $Colors.Bad
        }
    }
}

function Update-IXJob {
    $job = $script:Job
    if ($null -eq $job) {
        $script:JobTimer.Stop()
        return
    }
    $progress = $job.Progress
    $text = [string]$progress.Phase
    if ($progress.Total -gt 0) {
        $text = $text + ': ' + ('{0:N1} of {1:N1} MB' -f ($progress.Done / 1MB), ($progress.Total / 1MB))
    }
    elseif ($progress.Done -gt 0) {
        $text = $text + ': ' + ('{0:N1} MB' -f ($progress.Done / 1MB))
    }
    $ui.StatusText.Text = $job.Prefix + $text
    if (-not $job.Handle.IsCompleted) {
        return
    }

    $script:JobTimer.Stop()
    $script:Job = $null
    $result = $null
    $failure = $null
    try {
        $output = @($job.Shell.EndInvoke($job.Handle))
        if ($output.Count -gt 0) {
            $result = $output[$output.Count - 1]
        }
        else {
            $failure = 'It stopped without a result.'
        }
    }
    catch {
        $failure = Get-IXErrorText $_
    }
    finally {
        $job.Shell.Dispose()
    }
    Set-IXBusy $false
    if ($failure) {
        & $job.Fail $failure $job.Context
        return
    }
    & $job.Then $result $job.Context
}

# Stops the background work when the window closes. The work's own clean-up
# runs: for the pictures, x64-zt is ended and its files removed.
function Stop-IXJob {
    $job = $script:Job
    if ($null -eq $job) {
        return
    }
    $script:JobTimer.Stop()
    $script:Job = $null
    try {
        $job.Shell.Stop()
    }
    catch {
        Write-IXLog ('stop: ' + $_.Exception.Message)
    }
    $job.Shell.Dispose()
}

# What a finished iw7-mod download did, for the status line; also makes the desktop shortcut.
function Complete-IXClient {
    param($Client)
    Write-IXLog ('iw7-mod.exe ' + $Client.Version + ' from ' + $Client.Source + ', verified: ' + $Client.Verified)
    $text = 'Downloaded iw7-mod ' + $Client.Version + ' from ' + $Client.Source
    if ($Client.Verified) {
        $text = $text + ' (checksum verified)'
    }
    $text = $text + '.'
    try {
        $shortcut = New-IXShortcut $script:GameDir
        if ($shortcut) {
            $text = $text + ' Desktop shortcut: ' + [IO.Path]::GetFileNameWithoutExtension($shortcut) + '.'
        }
    }
    catch {
        Write-IXLog ('shortcut: ' + $_.Exception.Message)
    }
    return $text + ' Its first start downloads the rest of its files. '
}

function Invoke-IXPlay {
    try {
        if (-not (Test-IXSteamRunning)) {
            try {
                Start-Process 'steam://open/main'
            }
            catch {
            }
            Set-IXStatus 'STARTING STEAM' 'iw7-mod needs Steam running. Click PLAY again once Steam is open.' $Colors.Warn
            return
        }
        Start-IXGame $script:GameDir
        Write-IXLog 'started iw7-mod'
        $window.Close()
    }
    catch {
        Invoke-IXFailure $_ 'play'
    }
}

# The green button.
function Invoke-IXPrimary {
    if ($ui.InstallButton.Content -eq 'PLAY') {
        Invoke-IXPlay
    }
    elseif (-not $script:State.ClientFound) {
        Start-IXClientDownload {
            param($Client)
            Invoke-IXInstall (Complete-IXClient $Client)
        }
    }
    else {
        Invoke-IXInstall ''
    }
}

function Invoke-IXSteamInstall {
    try {
        Start-Process $IXSteamInstallUrl
    }
    catch {
        Start-Process $IXSteamStoreUrl
    }
    Set-IXStatus 'WAITING FOR STEAM' 'Install Infinite Warfare in the Steam window. This setup notices when the game is there.' $Colors.Info
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

# Every few seconds while idle: notice a game Steam just installed, an iw7-mod.exe copied
# in by hand, or the game starting and stopping.
function Update-IXWatch {
    if ($script:Busy) {
        return
    }
    try {
        $wasFound = $script:State.GameFound
        if (-not $wasFound -and -not $GameDir) {
            $found = Find-IXGameDir
            if ($found) {
                $script:GameDir = $found
            }
        }
        $state = Get-IXState $script:GameDir $PackageRoot
        if ((ConvertTo-Json -InputObject $state -Compress) -ne $script:StateText) {
            Update-IXView
            if (-not $wasFound -and $script:State.GameFound) {
                Set-IXReadyStatus
            }
        }
    }
    catch {
        Write-IXLog ('refresh: ' + $_.Exception.Message)
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

$script:JobTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:JobTimer.Interval = [TimeSpan]::FromMilliseconds(150)
$script:JobTimer.Add_Tick({ Update-IXJob })
$script:WatchTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:WatchTimer.Interval = [TimeSpan]::FromSeconds(4)
$script:WatchTimer.Add_Tick({ Update-IXWatch })

$ui.TitleBar.Add_MouseLeftButtonDown({
        try {
            $window.DragMove()
        }
        catch {
        }
    })
$ui.MinButton.Add_Click({ $window.WindowState = 'Minimized' })
$ui.CloseButton.Add_Click({ $window.Close() })
$ui.SteamLink.Add_Click({ Invoke-IXSteamInstall })
$ui.BrowseButton.Add_Click({ Invoke-IXBrowse })
$ui.ClientLink.Add_Click({
        Start-IXClientDownload {
            param($Client)
            $text = Complete-IXClient $Client
            Set-IXStatus 'IW7-MOD INSTALLED' ($text + 'Now click INSTALL for Infinite Expansion.') $Colors.Ok
        }
    })
$ui.ReinstallLink.Add_Click({ Invoke-IXInstall '' })
$ui.RepoLink.Add_Click({ Start-Process $IXProjectUrl })
$ui.InstallButton.Add_Click({ Invoke-IXPrimary })
$ui.UninstallButton.Add_Click({ Invoke-IXUninstall })
$window.Add_ContentRendered({
        if ($Install -and $ui.InstallButton.IsEnabled -and $ui.InstallButton.Content -ne 'PLAY') {
            Invoke-IXPrimary
        }
        elseif ($Uninstall -and $ui.UninstallButton.IsEnabled) {
            Invoke-IXUninstall
        }
    })
$window.Add_Closing({
        if ($script:Busy -and $null -ne $script:Job) {
            $answer = [System.Windows.MessageBox]::Show($window, $script:Job.What + "`n`nClose anyway?", 'Infinite Expansion Setup', 'YesNo', 'Question')
            if ($answer -ne 'Yes') {
                $_.Cancel = $true
                return
            }
            if ($script:Job.Stop) {
                Stop-IXJob
            }
        }
    })

$script:Busy = $false
$script:Job = $null
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
$script:WatchTimer.Start()

try {
    [void]$window.ShowDialog()
}
catch {
    Show-IXFatal ('The setup window stopped: ' + $_.Exception.Message)
}
$script:WatchTimer.Stop()
$script:JobTimer.Stop()

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
