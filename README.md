

<!-- MarkdownTOC -->

- [Current Tools](#current-tools)
- [What is it?](#what-is-it)
- [Warnings](#warnings)
- [Why](#why)
- [Requirements](#requirements)
  - [MSYS2](#msys2)
  - [Visual Studio 2022](#visual-studio-2022)
  - [ENV Vars](#env-vars)
  - [Shell Launch](#shell-launch)
- [Other Notes](#other-notes)
  - [Credits](#credits)
  - [Tips & Tricks](#tips--tricks)
  - [Why don't you add these patches upstream?](#why-dont-you-add-these-patches-upstream)
  - [Why does it take so long to build?](#why-does-it-take-so-long-to-build)
    - [Things we try to do to fix this](#things-we-try-to-do-to-fix-this)
  - [Why bash?](#why-bash)

<!-- /MarkdownTOC -->

# Current Tools
The link to the changes in each row will show the source changes. For build time modifications look at the [build/README](build/README.md) for details on each.

| Our Changes  | CI Action Status |
| :---: | :---: |
| [gnulib](repo_notes/gnulib_README.md)       | [![GNULIB Patch Tests](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/gnulib_tests.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/gnulib_tests.yml) |
|  [automake](repo_notes/automake_README.md)  |  [![automake Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_automake_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_automake_build.yml)  |
|  [awk](repo_notes/awk_README.md)  |  [![awk Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_awk_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_awk_build.yml)  |
|  [coreutils](repo_notes/coreutils_README.md)  |  [![coreutils Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_coreutils_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_coreutils_build.yml)  |
|  [diffutils](repo_notes/diffutils_README.md)  |  [![diffutils Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_diffutils_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_diffutils_build.yml)  |
|  [findutils](repo_notes/findutils_README.md)  |  [![findutils Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_findutils_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_findutils_build.yml)  |
|  [gawk](repo_notes/gawk_README.md)  |  [![gawk Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_gawk_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_gawk_build.yml)  |
|  [grep](repo_notes/grep_README.md)  |  [![grep Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_grep_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_grep_build.yml)  |
|  [gzip](repo_notes/gzip_README.md)  |  [![gzip Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_gzip_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_gzip_build.yml)  |
|  [highlight](repo_notes/highlight_README.md)  |  [![highlight Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_highlight_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_highlight_build.yml)  |
|  [libhsts](repo_notes/hsts_README.md)  |  [![libhsts Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_libhsts_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_libhsts_build.yml)  |
|  [make](repo_notes/make_README.md)  |  [![make Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_make_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_make_build.yml)  |
|  [openssl](repo_notes/openssl_README.md)  |  [![openssl Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_openssl_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_openssl_build.yml)  |
|  [patch](repo_notes/patch_README.md)  |  [![patch Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_patch_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_patch_build.yml)  |
|  [pcre2](repo_notes/pcre2_README.md)  |  [![pcre2 Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_pcre2_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_pcre2_build.yml)  |
|  [pdcurses](repo_notes/pdcurses.md)  |  [![pdcurses Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_pdcurses_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_pdcurses_build.yml)  |
|  [sed](repo_notes/sed_README.md)  |  [![sed Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_sed_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_sed_build.yml)  |
|  [symlinks](repo_notes/symlinks_README.md)  |  [![symlinks Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_symlinks_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_symlinks_build.yml)  |
|  [tar](repo_notes/tar_README.md) [paxutils](repo_notes/paxutils_README.md)  |  [![tar Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_tar_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_tar_build.yml)  |
|  [wget2](repo_notes/wget2_README.md)  |  [![wget2 Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_wget2_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_wget2_build.yml)  |
|  [wget](repo_notes/wget_README.md)  |  [![wget Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_wget_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_wget_build.yml)  |
|  [which](repo_notes/which_README.md)  |  [![which Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_which_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_which_build.yml)  |
|  [wolfCrypt](repo_notes/wolfcrypt_README.md)  |  [![wolfCrypt Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_wolfcrypt_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_wolfcrypt_build.yml)  |
|  [zlib](repo_notes/zlib_README.md)  |  [![zlib Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_zlib_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_zlib_build.yml)  |
|  [zstd](repo_notes/zstd_README.md)  |  [![zstd Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_zstd_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_zstd_build.yml)  |
|  [gnutls](repo_notes/gnutls_README.md)  |  [![gnutls Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_gnutls_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_gnutls_build.yml)  |
|  [p11-kit](repo_notes/gnutls_README.md)  |  [![p11-kit Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_p11-kit_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_p11-kit_build.yml)  |
|  [libtasn1](repo_notes/gnutls_README.md)  |  [![libtasn1 Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_libtasn1_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_libtasn1_build.yml)  |
|  WIP: [bash](repo_notes/bash_README.md)  |  [![bash Build](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_bash_build.yml/badge.svg)](https://github.com/mitchcapper/WIN64LinuxBuild/actions/workflows/tool_bash_build.yml)  |

# What is it?

It is a few primary components:

- This is a set of patches, mostly for [gnulib](repo_notes/gnulib_README.md), to increase compatibility with windows systems.
- A common bash script helper (helpers*.sh) and short template file for easily compiling gnulib and non-gnulib linux apps.  The focus is on moving as much duplicate code to the helper includes rather than in each build script. This includes several debug/trace tools and make/cmake/nmake wrappers.
- A bash script that uses the above helper lib to compile a variety of common *nix tools for details on changes for each use the link in the list above.
- A tool to generate a basic Visual Studio debug project to debug the target, if you can't run the binary in the debugger you can add `launchdebugger()` to the code run from the CLI and will get the normal JIT prompt.  Note due to how the debugger launch works it may better to do a bit earlier than needed (or in the main launch).  If the code you want to debug into is part of a library then you need to remove that code from the library (and add to your MSVC project) or build that library in MSVC.  The VS project comes with `wlb_debug.h` and `wlb_debug.c` that includes a basic console/file logger.
- Easy build flags to compile debug versions of all the libraries and the project itself with MSVC edit and continue support (without needing them all in a VS project)
- Minimal changes to each target to make it work, to reduce maintenance requirements as the code changes.  For some of these projects we throw additional gnulib modules at it that seem to fix the problems, there may be easier ways but this does result in minimal changes to the native code base.
- Build entire projects in Windows native debug mode for full VS debugging and symbols
- Logging of build process to create a batch file (.bat) to be able to build most projects without any subsystem at all
- Github actions produces **Windows binaries** for download.  You can find these under the workflow links in the list above, click on a successful one and then the downloads can be found under Artifacts on that page.  Note: you must be signed into github to see the artifacts produced.

# Warnings

DO NOT STAGE CHANGES in build folder.  NOTE: During the step in which we apply our patch we assumed any staged work is ours and discard it to a backup file.  Technically after we have run our_patch we won't mess with staged items again.   Similarly if there is gnulib used we use the same stage behavior when we go to patch it.

This code and the scripts were quickly written without much testing, and often involving poor quality hacks.  Things like disabling testing, help generation, direct manipulation of autogenerated files post generation rather than fixing the generators.  Often I use _WIN32 gating for changes, this might break cygwin platforms or using gcc/g++ in Windows. Again these code changes are low quality, if upstream projects want to consider including them may be able to clean up those code blocks.

# Why

Like many of us, I use multiple operating systems and have always used windows versions of *nix tools. Sadly these are not always perfect for my needs due to:

- They are exceptionally dated (aka https://gnuwin32.sourceforge.net/ )
- They use mingw requiring several additional dlls and have odd mingw behaviors.  This includes things like Cygwin which require the full cygwin emulation layer.   Cygwin does a good job of emulating linux api on windows (beyond that of mingw) but emulation involves many compatibility oddities or bugs, not to mention additional dll requirements.  You can get near any tool under cygwin but using them outside of the cygwin environment is often not a first class experience.
- They are missing compile / library options like PCRE or other useful features
- People go to great lengths to patch original sources to make them work for windows, but the depth of those patches requires frequent maintenance that can be hard to keep up


There is the linux subsystem for Windows (WSL2) now which while great has three issues:
1) you don't always choose the machines you must work on
2) it requires using a separate shell from your current
3) You need to use a hypervisor layer and the overhead that entails

By focusing on the core gnulib library we can have fewer changes to maintain and have more instant compatibility across projects.  We still use MSYS2 but only for building.  It provides the shell environment as it is light weight (no virtualization requirement) and has great compatibility with standard nix shell/systems. We also avoid using GCC and use MSVC's native compiler meaning binaries are fully debuggable with full symbol and stepping support.

# Requirements

A great way to figure out all the requirements is to look at the github actions environment setup.  If you run into build failures it may be because you have common apps in your bin PATH conflicting with native functionality. There are some linux programs as well that we try to prevent being called but can cause some havoc.   Two big ones `lib.exe` and `ranlib.exe` if your msys2 doesn't need them rename them to lib2.exe and ranlib2.exe.  We try to avoid any build script calling them but the msys2 versions, if called, can just wreak enough havoc to not cause hard failures but bugs very annoying to figure out.

## MSYS2

https://www.msys2.org/ MSYS2 is a linux sub-system for windows but unlike cygwin largely works not to simulate all things linux but to provide the infrastructure to do native windows compiling.  Note msys does use some cygwin packages for its env.  We don't need any packages installed from the UI just launch a shell once installed or unzipped and then run: `pacman -S pkg-config make gperf rsync autoconf wget gettext-devel automake autogen texinfo git bison python autoconf-archive libtool flex`.  Note for actually compiling we use a special way to enter the shell to make sure things we need are available (See Shell Launch below).  Note if you have an existing msys instance and already have various developer tools installed it may screw builds up. Configure scripts look for certain things and either fallback or try alternates when not found.  If you have something like GCC or msys/cygwin developer headers for certain packages installed these may take preference and either prevent builds from working, or require additional dlls to work.  The best solution is just create a second msys2 install just for this extract the msys2 archive to an alternate path and use the proper launcher to enter that msys and all will be well. Similarly it is possible that if you have certain tools in your default path for windows say gcc or some other app configure looks for you may find again strange behavior.  This can be harder to fix as you will need to edit your shell launch script to remove those paths from your path before starting.  I would highly recommend adding the environmental variable `MSYS2_ARG_CONV_EXCL="*")

###
Msys should generally not have a few tools NOT installed or not in the path including: cmake

## Visual Studio 2022

https://visualstudio.microsoft.com/vs/community/ free and older versions might work, but only tested with 2022.  Install cmake support (either through the cmake installer or VS) we will use this over the msys version so we have VS project formats.

## ENV Vars

Almost all config is done through the default_config.ini and overriding those settings in the f_*_build.sh scripts.  These are not required but some minor edits may need to be made the environmental variables are:

- WLB_BASE_FOLDER - The base folder for compiles
- WLB_SCRIPT_FOLDER - The checkout folder for this repo, most of the time we can get this from the executing script but a few bat files use it to be able to work with absolute paths
- MSYS_PATH - Path to your msys install used by the shell launcher scripts not required can edit them if you have non-default path.
- You can override any setting using ENV variables as well, for example to enable debug building rather than editing the build script you can do `export BLD_CONFIG_BUILD_DEBUG=1`

## Shell Launch

To launch an msys shell you can use the helper msys_shell.ps1 or msys_shell.bat helper scripts from this repo.  Note these are expected to be run from the "VS Developer Command Prompt" or "VS Developer Powershell", this makes all the MSVC compilers in our path and configured. The helpers do a few key things:

- Exclude the msys path assistance that turns windows paths (ie: c:\temp\etc) into nix equivalents.   This is because it often will break all backslash handling when we actually want a backslash.  Use forward slashes for paths (see tips and tricks below).
- Puts us in with the ucrt64/gcc default toolset, this is what we want we dont even have gcc/g++ installed but it prevents us accidentally linking with the wrong items.
- Enables the command line for apps to show up in windows tools, by default it doesn't
- Finally makes sure for symlinks it uses native windows symlinks

If you want to configure your term launcher to automatically put you into the msys term ready to go you can simulate what the Developer Term is doing and use a start command for the terminal like:
`&{Import-Module "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools/Microsoft.VisualStudio.DevShell.dll"; Enter-VsDevShell $VS_INSTANCE_ID -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"; . "$env:WLB_SCRIPT_FOLDER/msys_shell.ps1"}`.  To figure out your VS_INSTANCE_ID use the powershell command `Get-CimInstance MSFT_VSInstance`  and take the `IdentifyingNumber` from the one you want.  You can use the included `vs_msys_shell_launch.ps1` that will try to do the above before launching the msys shell.

Note the shell launch tools assume msys in c:\msys64 if the ENV var MSYS_PATH is not specified.  If you have it elsewhere update them accordingly or set the env var. 

# Other Notes

## Credits

Most of the work here was not done by me and there are some great resources out there.  There are links in places to original code. There are many other great compile projects out there including:

- https://gnuwin32.sourceforge.net/ - one of the most well known, many packages with detailed patch adjustments to make them work with Windows. Sadly stopped in 2010.
- https://github.com/mbuilov - Great builds for some common tools like grep, awk, sed in native MSVC form using an interesting process of cygwin to generate the commands and then the normal windows env to do the compiling.
- The https://github.com/coreutils team modernizing things and supporting GitHub mirroring of some gnulib libraries.
- https://github.com/uutils/coreutils a rust port of coreutils that is cross platform, hopefully they will take out a large segment of the coreutils need eventually.

## Tips & Tricks

- For paths try to use a path form that is compatible with both native msys binaries and windows binaries.  This form is "c:/path/to/item"  using forward slashes means works for both platforms and while normal msys autocompleting for paths is /c/path/to/item (no colon and leading slash) all tools seem to understand the "c:/path/to/item" form, in addition this is a valid windows path format so no conversion is needed.
- Even for non gnulib based tools using the gnulib build-aux comple/ar-lib wrappers that convert native gcc/ar commands to the MSVC equivalents is often enough to make many libraries work.
- It is possible to use msys to generate build batch files for Windows.   The helper scripts have a "log_make" function that can be called before the actual make command and will log the make sequence to a file.
- Non-makefile based builds (cmake etc) are a bit overcomplicated using wrapper scripts (or for cmake entire other build processes) to be able to capture the build commands and generate build .bat files.  This is often not needed and is more prone to breaking.   To prevent this set the best cmake style var to "vs" and any `BLD_CONFIG_BUILD_WINDOWS_COMPILE_WRAPPERS` set to 1 are set to 0.
- To build debug builds set the env var `BLD_CONFIG_BUILD_DEBUG=1` 
- To generate batch files for building without msys run the build script with the arg "log_full".  Note you likely need some generated files (like config.h) so these would need to be added along with the normal sources.
- Generally, when we make changes we try to stage them after so that unstaged work represents things you may have changed.  The exception is we don't stage config /build files themselves.   See warning under WARNINGS about the stage behavior.
- By default if a project uses gnulib we use the latest main branch from the project.  Sometimes our patches might get out of sink and be unable to apply cleanly until they are updated.  If this is the case you can still successfully build by running `export BLD_CONFIG_GNU_LIBS_BRANCH=known_ok_gnulib_commit_sha`. To figure out what commit to use look at our github action logs for the project you will see in the "Build Package" job a step called "GET GNULIB Success Commit" click it and you should see the commit ID ie: `Found GNULIB Success Commit: 109e2ea1836d171ff2e50df35380aa1926a99dee`

## Why don't you add these patches upstream?

Normally I do start with PR for changesets I think are likely to be integrated.  GNU has put considerable effort into a compatibility level for Windows ( https://www.gnu.org/software/gnulib/manual/html_node/Native-Windows-Support.html and more).  Still for most GNU projects Windows is a very low priority.  Cygwin and WSL2 both exist for Windows and require less work from a maintenance POV than a native Windows environment.   Accepting more Windows build support could create some expectation of maintenance, at a very minimum code has to be compilable when future changes happen making more work for others.   GNU primarily works through mailinglists, in general I have sent mail to these lists in case there is any interest in the projects.  Per above, this code is weakly tested and some hacks,  many GNU projects are broadly used, so much more testing would be needed.  A starting action would be to just run the native tests.  Nothing would be better for it making it into the official codebases.  As the code is ready now however I put it here.

## Why does it take so long to build?

Almost everything uses straight from the master branch sources rather than actual release archives.  For projects that use gnulib the cloning of this submodule can take quite some time.  If you are running build scripts multiple times you can provide a reference bare repo that it can fetch most of the data from (much faster).  To do so in your WLB_BASE_FOLDER run this command: `git clone --mirror https://git.savannah.gnu.org/git/gnulib.git` and thats it, we should automatically pick it up and use it. ~~~For those tools that rely on gnulib that means there is nearly always a bootstrap process, and it can be very slow. This is largely due to msys fork performance and the cost of process startup on windows vs *nix systems.~~~ Happy to say now that gnulib-tool.py is near parity for gnulib-tool bootstrapping is 100x faster.

### Things we try to do to fix this

- Build config caching less helpful if you are only compiling one tool once, but if re-configuring (ie after changing the gnu modules) this can save a boatload of time, as the configure scripts on windows are also quite slow.

## Why bash?

While I greatly prefer to not write bash scripts for large projects anymore, for a set of tools to assist with linux builds it seemed like the best choice.  Easy user modification and the ability to complete steps at the shell as well.

## Other Tools Not Considered

Generally the tools on this list are not considered as there are official native windows builds available if that is the case they will be linked to

- [curl](https://github.com/curl/curl/releases)

- [wget2](https://gitlab.com/gnuwget/wget2/-/artifacts) - we actually do have a wget2 build above mostly for debug support

- [nano](https://github.com/okibcn/nano-for-windows/releases)

- [less](https://github.com/jftuga/less-Windows/releases)

- [ffmpeg](https://github.com/rdp/ffmpeg-windows-build-helpers)

- [ripgrep](https://github.com/mitchcapper/ripgrep/actions)

- [mediainfo](https://mediaarea.net/en/MediaInfo)

# Developers / Custom Builds
See the [DEVELOPERS.md](DEVELOPERS.md) file for creating your own custom builds or more details on the internals of the tool.
