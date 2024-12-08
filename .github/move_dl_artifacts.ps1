Set-StrictMode -version latest;
$ErrorActionPreference = "Stop";
$VerbosePreference="Continue";


$files = (Get-ChildItem -Path d:/artifacts/*.zip -Force -ErrorAction SilentlyContinue)
foreach ($file in $files){
	$folder = $file.BaseName.replace("WLB-","").replace("-Debug","")
	$srcPath = "d:/artifacts/$($folder)"
	if ( -not (Test-Path -Path $srcPath)  ){
		Expand-Archive -Path $file.FullName -DestinationPath $srcPath
		Write-Host "Extracting $folder"
	}
}

$folders = (Get-ChildItem -Path d:/artifacts/* -Directory -Force -ErrorAction SilentlyContinue)

foreach ($folder in $folders) {
	$srcPath = "d:/artifacts/$($folder.Name)"
	$dstPath = "$($env:WLB_BASE_FOLDER)/$($folder.Name)/final"
	New-Item -ItemType Directory -Force -Path "$($env:WLB_BASE_FOLDER)/$($folder.Name)"

	Move-Item -Path $srcPath -Destination $dstPath
	Write-Output "$srcPath => $dstPath"
}