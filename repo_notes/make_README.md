# make

Several items are done in the build script rather than as a source patch.  Note, while this does build without a real shell (bash/sh) any complex makefiles won't work.

[Original Source](https://savannah.gnu.org/projects/make/) | [Changes](https://github.com/mitchcapper/make/compare/master...win32_enhancements)

- Standard GNULIB patches
- Mostly removing some of the hardcoded/included gnulib based modules for the newer official gnulib modules (clearing out gl/lib/* gl/modules/*)
- 
