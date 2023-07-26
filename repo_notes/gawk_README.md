# gawk

[Original Source](https://git.savannah.gnu.org/git/gawk.git) | [Changes](https://github.com/mitchcapper/gawk/compare/master...win32_enhancements)

- Remove much of the "pc/Win32" specific code opting to use the more updated gnulib code
- Add GNULIB proper to project to pull in more modules (makefiles adjusted to accommodate)
- minor other windows fixes
- Dynamic extension fixes for windows
- Builds in shared mode always to support dynamic extension loading
