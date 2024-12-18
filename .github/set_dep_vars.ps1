Set-StrictMode -version latest;
$ErrorActionPreference = "Stop";
$VerbosePreference="Continue";

$cacheKey= $env:Configuration + (date +'%m%d')
$arr=($env:DEPS).split()
$cnt=1
foreach ($dep in $arr) {
	if ($dep){
		echo "Dep$($cnt)Name=$dep" >> $env:GITHUB_OUTPUT
		$cacheKey+=$dep + "-"
		$cnt++		
	}
}
$failAction="fail"
$postfix=""
if ($env:Configuration -eq "Debug") {
	#$failAction="ignore"
	$postfix="-Debug"
}
echo "DepsCacheKey=$cacheKey" >> $env:GITHUB_OUTPUT
echo "DepsFailAction=$failAction" >> $env:GITHUB_OUTPUT
echo "DepsPostfix=$postfix" >> $env:GITHUB_OUTPUT