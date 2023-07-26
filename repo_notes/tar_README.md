# tar

While the changes are only #defined for windows, the spawn code should work for all platforms.  Did not go through and rewrite grandchild handlers for Windows, but those could also be done if needed.  Doing an stdin and stdout with external compressor seems to require this (normal external compressor usage does work).

[Original Source](https://www.gnu.org/software/tar/) | [Changes](https://github.com/mitchcapper/tar/compare/master...win32_enhancements)

- Standard GNULIB patches
- Disable some permission settings that don't apply
- Largest changes to change fork code over to gnulib execute/spawnp library
- Fixed symbolic links to work properly in create, extract, compare on windows
- minor paxutils [Changes](https://github.com/mitchcapper/paxutils/compare/master...win32_enhancements)
