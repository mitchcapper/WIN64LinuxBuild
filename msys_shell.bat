SET MSYS=winsymlinks:native wincmdln
SET MSYS2_ARG_CONV_EXCL="/a;/b;/c;/d;/e;/f;/g;/h;/i;/j;/k;/l;/m;/n;/o;/p;/q;/r;/s;/u;/v;/w;/x;/y;/z;/0;/1;/2;/3;/4;/5;/6;/7;/8;/9;/A;/B;/C;/D;/E;/F;/G;/H;/I;/J;/K;/L;/M;/N;/O;/P;/Q;/R;/S;/T;/U;/V;/W;/X;/Y;/Z"
cd %WLB_BASE_FOLDER%

IF [%MSYS_PATH%] == [] SET MSYS_PATH="C:\temp\msys64"

%MSYS_PATH%\msys2_shell.cmd -ucrt64 -defterm -here -no-start -full-path %*