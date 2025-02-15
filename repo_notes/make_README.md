# make

Several items are done in the build script rather than as a source patch.  Note, while this does support building without a real shell (bash/sh) any complex makefiles won't work (aka if they have shell commands).  The goal is to allow the user to have ultimate say in what shells are used without having to manually edit makefiles.

[Original Source](https://savannah.gnu.org/projects/make/) | [Changes](https://github.com/mitchcapper/make/compare/master...win32_enhancements)

- Standard GNULIB patches
- Mostly removing some of the hardcoded/included gnulib based modules for the newer official gnulib modules (clearing out gl/lib/* gl/modules/*)
- Changed the shell detection/override support to work across all platforms and have more configurability following ENV vars:
  - **MAKESHELL** - shell to use as long as makefile doesn't override it
  - **NOMAKESHELL** - semicolon separated list of shells that are ignored if read from a makefile as the shell, sometimes software explicitly has in the Makefile to use bash or some other shell, if we are trying to force it to use a different shell it would fail here.  This allows you exclude one or more shells from ever being used even if the makefile calls for that shell specifically.
  - **DEFAULTSHELL** - the shell to consider the default shell for the platform.  This only matters in situations that GNU make thinks it can execute a call to itself directly.  When this is not equal to the shell in use then the shell is called for all executes (Ensuring if they want to do something else it occurs).  When equal it can just start itself.
    
