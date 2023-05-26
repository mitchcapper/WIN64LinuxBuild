# coreutils

[Original Source](https://github.com/coreutils/coreutils) | [Changes](https://github.com/mitchcapper/coreutils/compare/master...win32_enhancements)

- Standard GNULIB patches
- Moved to use gunlibs platform neutral stats lib when possible
- Make sure there is an inode ID number before comparing it
- Change fork code over to gnulib execute/spawnp gnulib library
- _WIN32 gate of security/ownership code that doesn't apply for windows
- tail properly support reopening files and allows delete/rename while tailing
- Most of the GNULIB patches are used by the code including:
  - proper windows symlink support
  - windows stat  listing for files and drives (ls/du/df/etc.)
  - 
