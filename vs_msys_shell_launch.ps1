$StartScript="$args";
Set-StrictMode -version latest;
$ErrorActionPreference = "Stop";

if (! $env:VS_ENV_INITIALIZED) {
    $instances=Get-CimInstance MSFT_VSInstance -Namespace root/cimv2/vs;
    $VS_INSTANCE = $instances[0]
    foreach ($instance in $instances) {
        if ( [System.Version]$VS_INSTANCE.Version -lt [System.Version]$instance.Version ) {
            $VS_INSTANCE=$instance;
        }
    }
    $path_before=$env:PATH.Trim(';');
    $VS_DEV_SHELL_PATH="$($VS_INSTANCE.InstallLocation)/Common7/Tools/Microsoft.VisualStudio.DevShell.dll";
    $VS_INSTANCE_ID=$VS_INSTANCE.IdentifyingNumber;
    $env:VS_ENV_INITIALIZED=1;
    Write-Host "Starting msys shell with VS tools from: $($VS_INSTANCE.ProductLocation)"
    Import-Module $VS_DEV_SHELL_PATH;
    Enter-VsDevShell $VS_INSTANCE_ID -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64";
    if (! $env:WLB_NO_PATH_CLEAN ){ #this is similar to what msys2 does when -full-path is not used but we want to preserve the VS additions (plus any WLB_PATH_ADD The user might want)
        $path_after=$env:PATH;
        # pwsh powershell location attempt

        $pwshPath = ""
        $versions = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\PowerShellCore\InstalledVersions\"
        foreach ($version in $versions) {
            $installedDir = Get-ItemPropertyValue -Path $version.PSPath -Name "InstallDir" -ErrorAction SilentlyContinue
            if ($installedDir -and (Test-Path "$installedDir\pwsh.exe")) {
                $pwshPath = ";$installedDir"
                break
            }
    }

        $pathAdd="${env:SystemRoot};${env:SystemRoot}/system32;${env:SystemRoot}/Wbem;${env:SystemRoot}/system32/WindowsPowerShell/v1.0;${env:USERPROFILE}/.dotnet/tools${pwshPath}"
        if ( $env:WLB_PATH_ADD ){
            $pathAdd="$env:WLB_PATH_ADD;$pathAdd"
        }
        $path_after=$path_after.replace($path_before,$pathAdd).replace(";;",";").Trim(';').replace("//","/").replace("\\","\")
        $env:PATH=$path_after
        if ( $env:WLB_BUILD_TRACE ) {
            Write-Host "Stripped path to:"
        $env:PATH.Split(";") | ForEach-Object { Write-Host "`t$_" }
        }
        
        
    }
}
. "$($env:WLB_SCRIPT_FOLDER)/msys_shell.ps1" "$StartScript"
