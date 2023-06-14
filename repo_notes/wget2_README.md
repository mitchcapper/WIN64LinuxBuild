# wget2

Note there are official binary builds from them for windows.  The primary benefit of this modified build is if you want Visual Studio debug support.

[Original Source](https://gitlab.com/gnuwget/wget2) | [Changes](https://github.com/mitchcapper/wget2/compare/master...win32_enhancements)

- Standard GNULIB patches
- Fixes for GCC only compiler code
- Fixed wolfssl for Windows
- Better cert/defaults and better wolfssl support
- Fixed download io failures in windows due to early poll returns
- more accurate progress bars
- Native terminal VT code activation
- non-standard web port requests through http proxy fixed
