set DEFINES=_DEBUG WLB_INCLUDE_CONFIG_H WLB_WINSOCK_FIX WLB_DISABLE_DEBUG_ASSERT_AT_EXIT
set VCPKG_TRIPLET=x64-windows-static
dotnet-script --verbosity info "%WLB_SCRIPT_FOLDER%\vs_debug_help\DebugProjGen.csx" --define _WIN64 %DEFINES% HSTS_STATIC DEBUG PCRE2_STATIC LIBWGET_STATIC U_STATIC_IMPLEMENTATION PSL_STATIC  U_IMPORT WGET_PLUGIN_DIR="\"%WLB_BASE_FOLDER%/wget2/final/lib/wget2/plugins\"" LOCALEDIR="%WLB_BASE_FOLDER%/wget2/final/share/locale" SYSCONFDIR="\"%WLB_BASE_FOLDER%/wget2/final/etc/\"" HAVE_CONFIG_H MALLOC_RETURNS_NONNULL WGETVER_FILE="\"wget/wgetver.h\""   --exe wget2 --libraries crypt32.lib ./lib/.libs/gnu.lib ./libwget/.libs/wget.lib %WLB_BASE_FOLDER%/vc_pkgs/zstd/%VCPKG_TRIPLET%/lib/zstd.lib %WLB_BASE_FOLDER%/wolfcrypt/final/lib/wolfssl.lib %WLB_BASE_FOLDER%/pcre2/final/lib/pcre2-8.lib %WLB_BASE_FOLDER%/zlib/final/lib/zlibstatic.lib %WLB_BASE_FOLDER%/vc_pkgs/nghttp2/%VCPKG_TRIPLET%/lib/nghttp2.lib %WLB_BASE_FOLDER%/libpsl/final/lib/psl.lib %WLB_BASE_FOLDER%\vc_pkgs\bzip2\%VCPKG_TRIPLET%\lib\bz2.lib %WLB_BASE_FOLDER%\vc_pkgs\liblzma\%VCPKG_TRIPLET%\lib\lzma.lib %WLB_BASE_FOLDER%\vc_pkgs\brotli\%VCPKG_TRIPLET%\lib\brotlicommon-static.lib %WLB_BASE_FOLDER%\vc_pkgs\brotli\%VCPKG_TRIPLET%\lib\brotlidec-static.lib %WLB_BASE_FOLDER%\vc_pkgs\brotli\%VCPKG_TRIPLET%\lib\brotlienc-static.lib  %WLB_BASE_FOLDER%/libhsts/final/lib/hsts.lib --include_paths src . lib/ %WLB_BASE_FOLDER%/libpsl/final/include %WLB_BASE_FOLDER%/libhsts/final/include %WLB_BASE_FOLDER%/wolfcrypt/final/include %WLB_BASE_FOLDER%/pcre2/final/include include/wget  include/ %WLB_BASE_FOLDER%/pdcurses/final/include %WLB_BASE_FOLDER%/vc_pkgs/nghttp2/%VCPKG_TRIPLET%/include --include config.h  src/wget_bar.h src/wget_blacklist.h src/wget_dl.h src/wget_host.h src/wget_job.h src/wget_log.h src/wget_main.h src/wget_options.h src/wget_plugin.h src/wget_stats.h src/wget_testing.h src/wget_utils.h src/wget_xattr.h --compile src/bar.c src/blacklist.c src/dl.c src/host.c src/job.c src/log.c src/options.c src/plugin.c src/stats_server.c src/stats_site.c src/testing.c src/utils.c src/wget.c libwget/ssl_wolfssl.c libwget/io.c lib/fclose.c lib/msvc-nothrow.c lib/msvc-inval.c lib/close.c lib/poll.c libwget/hsts.c
