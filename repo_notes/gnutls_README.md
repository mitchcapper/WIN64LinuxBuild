# gnutls

[Original Source](https://gnutls.org/) | [Changes](https://github.com/mitchcapper/gnutls/compare/master...win32_enhancements)

- Standard GNULIB patches (though minimal gnulib additional includes due to LGPL/GPL licensing reqs)
- Support for MSVC, by default only gcc/mingw is supported removed dynamic array from groups
- Needed to build libtasn1 and p11-kit as well to get complete successful build.  [P11-kit Changes](https://github.com/mitchcapper/p11-kit/compare/master...win32_enhancements).
