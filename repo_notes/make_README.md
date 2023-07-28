# make

Several items are done in the build script rather than as a source patch.  Note, while this does supporting building without a real shell (bash/sh) any complex makefiles won't work.

[Original Source](https://savannah.gnu.org/projects/make/) | [Changes](https://github.com/mitchcapper/make/compare/master...win32_enhancements)

- Standard GNULIB patches
- Mostly removing some of the hardcoded/included gnulib based modules for the newer official gnulib modules (clearing out gl/lib/* gl/modules/*)
- Changed the shell detection/override support to work across all platforms and have more configurability following ENV vars:
  - **MAKESHELL** - shell to use as long as makefile doesn't override it
  - **NOMAKESHELL** - semicolon separated list of shells that are ignored if read from a makefile as the shell
  - **DEFAULTSHELL** - the shell to consider the default shell for the platform.  This only matters in situations that GNU make thinks it can execute a call to itself directly.  When this is not equal to the shell in use then the shell is called for all executes (Ensuring if they want to do something else it occurs).  When equal it can just start itself.
    
