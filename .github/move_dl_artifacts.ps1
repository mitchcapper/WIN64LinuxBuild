Set-StrictMode -version latest;
$ErrorActionPreference = "Stop";
$VerbosePreference="Continue";


$folders = (Get-ChildItem -Path d:/artifacts/* -Directory -Force -ErrorAction SilentlyContinue)

foreach ($folder in $folders) {
	$srcPath = "d:/artifacts/$($folder.Name)"
	$dstPath = "$($env:WLB_BASE_FOLDER)/$($folder.Name)/final"
	New-Item -ItemType Directory -Force -Path "$($env:WLB_BASE_FOLDER)/$($folder.Name)"

	Move-Item -Path $srcPath -Destination $dstPath
	Write-Output "$srcPath => $dstPath"
}