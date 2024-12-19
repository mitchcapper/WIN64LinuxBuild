param (
	[string] $install_path="c:/Program Files/vs_buildtools"
)

Set-StrictMode -version latest;
$ErrorActionPreference = "Stop";
$installer=Get-ChildItem ([IO.Path]::GetTempFileName()) | Rename-Item -NewName { [IO.Path]::ChangeExtension($_, ".exe") } -PassThru
Invoke-WebRequest 'https://aka.ms/vs/17/pre/vs_buildtools.exe'  -OutFile $installer
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $installer
$startInfo.Arguments = "--quiet --norestart --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --installPath c:/temp/vsbuild2  --wait"
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo
$process.Start()
$process.WaitForExit()
remove-item $installer
Write-Host DONE Tools Install to: $install_path