# bash

Important: Bash is not working by most definitions of the word.   It compiles, it runs scripts but has prompt and interactive issues and several fork calls right now are not converted.



bash is quite complex without much in the way of native MSVC builds or non msys/cygwin ability.   Even with heavy GNULIB modules likely it will not ever come close to the other standard builds.   It may be possible to get something able to execute most make /  configure files without the need for msys.   In addition, forking on Windows is very expensive in comparison.   While msys/cygwin are able to emulate the environment underneath they still have the same fork performance problem.  Between builtins and bash fork changes it may be possible to do a good bit more without forking or with better fork performance. The 3 big categories of conversions are:

- **Fork code** - converting this to posix_spawn can be quite tricky as bash often has a lot of internal code after fork before exec (if any exec) and some complex expectations of being able to have the child die.  In addition the items required for the new process are not clear given its script backed.  These things mostly can be overcome but requires some complex state to do the spawn later define actions first style.  The shell needs to be fast too so we can't just clone any and everything when we don't need to.   

- **Terminal / readline code **- there is no termios/sgtty support for windows and not much in the way of recent ports.   PDCurses may be the best option here with some overlapping code.  Still one of the bigger points of failure right now with issues.

- **Signals **- The most obvious and least likely to be close to fixed.  bash has massive signal usage and windows doesn't support most signals.   Some can potentially be ignored in many situations, a few can be simulated,  a few more will require to drastic and hacky type support (ie SIGALRM)



[Original Source](https://savannah.gnu.org/projects/bash/) | [Changes](https://github.com/mitchcapper/bash/compare/master...win32_enhancements)

- Added GNULIB to project (technically it has some handpicked gnulib files but no standard gnulib import path)
- Switched main makefile to automake.  A near requirement for standard gnulib building.  
- Modified code to work with all slashes on windows and windows path env vars
- Some function defines updated from K&R to modern defines
- Work towards fork/terminal/signals implementation
