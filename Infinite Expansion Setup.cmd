@echo off
rem Infinite Expansion - setup. Opens the install / uninstall window.
rem It runs installer\IXSetup.ps1 with Windows PowerShell, which comes with Windows 10 and 11.
if not exist "%~dp0installer\IXSetup.ps1" (
    echo The installer folder is missing. Extract the whole download first, then run this file again.
    pause
    exit /b 1
)
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0installer\IXSetup.ps1" %*
