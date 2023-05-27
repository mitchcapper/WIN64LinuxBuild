$StartScript="$args";
Set-StrictMode -version latest;
$ErrorActionPreference = "Stop";

if (! $env:VS_ENV_INITIALIZED) {
    $env:VS_ENV_INITIALIZED=1;
    $VS_INSTANCE=Get-CimInstance MSFT_VSInstance;
    $VS_DEV_SHELL_PATH="$($VS_INSTANCE.InstallLocation)/Common7/Tools/Microsoft.VisualStudio.DevShell.dll";
    $VS_INSTANCE_ID=$VS_INSTANCE.IdentifyingNumber;
    Import-Module $VS_DEV_SHELL_PATH;
    Enter-VsDevShell $VS_INSTANCE_ID -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64";
}
. "$($env:WLB_SCRIPT_FOLDER)/msys_shell.ps1" "$StartScript"
