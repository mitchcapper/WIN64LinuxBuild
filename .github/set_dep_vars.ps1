Set-StrictMode -version latest;
$ErrorActionPreference = "Stop";
$VerbosePreference="Continue";

$cacheKey=(date +'%m%d')
$arr=($env:DEPS).split()
$cnt=1
foreach ($dep in $arr) {
	if ($dep){
		echo "Dep$($cnt)Name=$dep" >> $env:GITHUB_OUTPUT
		$cacheKey+=$dep + "-"
		$cnt++		
	}
}
echo "DepsCacheKey=$cacheKey" >> $env:GITHUB_OUTPUT