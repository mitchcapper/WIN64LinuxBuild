$StartScript="$args";
Set-StrictMode -version latest;
$ErrorActionPreference = "Stop";

$env:MSYS="winsymlinks:native wincmdln"
#$env:MSYS2_ARG_CONV_EXCL="/a;/b;/c;/d;/e;/f;/g;/h;/i;/j;/k;/l;/m;/n;/o;/p;/q;/r;/s;/u;/v;/w;/x;/y;/z;/0;/1;/2;/3;/4;/5;/6;/7;/8;/9;/A;/B;/C;/D;/E;/F;/G;/H;/I;/J;/K;/L;/M;/N;/O;/P;/Q;/R;/S;/T;/U;/V;/W;/X;/Y;/Z"
$env:MSYS2_ARG_CONV_EXCL="*"
if ($env:WLB_BASE_FOLDER){
	cd $env:WLB_BASE_FOLDER;
}
$msysPath = $env:MSYS_PATH;
if (! $msysPath){
	$msysPath = "c:/msys64";
}

if ($StartScript){
	. $msysPath/msys2_shell.cmd -ucrt64 -defterm -here -no-start -full-path -shell bash -l -c "$StartScript"
}else{
	. $msysPath/msys2_shell.cmd -ucrt64 -defterm -here -no-start -full-path
}