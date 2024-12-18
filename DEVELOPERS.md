# Key Goals
- We try to avoid modifying the users system or msys install.  We try to make sure everything we download/use is stored under the WLB_BASE_FOLDER for easy cleanup (or alternate bases).  Sometimes we will use a users tools (ie cmake binary) but shouldn't require them.
- Builds follow a standardized format even if the app itself doesn't.  Sometimes this results in us having to manually move files around to match the final folder structure.
- For new builds use the build script generator [BuildScriptGenerator.csx](build/BuildScriptGenerator.csx) to generate the initial build template.  See the build [README](build/README.md) for details on its use.

# Helpers in Detail
The helpers are where the bulk of code is consolidated down that we would use for repeatedly.  They are broken down into the following

- helpers.sh - The main helper file any utility functions not found in the others, also something of the main on run handler
- helpers_gnu.sh - Mostly gnulib related tools for adding our additional modules, making sure our wrapper scripts are used, removing test/doc/po features if flagged to do so to speed up runs
- helpers_cmake.sh - By default most things are built around standard make, for cmake builds this has all the helper functions and wrappers.  We go to decent length to support a variety of cmake build engines (see BLD_CONFIG_CMAKE_STYLE) by default.  
- helpers_bashtrace.sh - Provide meaingful stacktraces on failure, ability to log all the shell commands we execute (output stored in - `buildname-cmd.log`), ability to filter certain items out of the trace as well.
- helpers_git.sh - handle cloning, custom git options, some staging features so it is easier to track automatic code changes (these get staged) vs manual code edits you may make (so you can easily see those and make them back to the original lib).  Git settings are all stored in ENV vars to avoid screwing up any actual git configs.
- helpers_vcpkg.sh - handles installing and removing vcpkg packages, adding them to the proper path/env/includes even installs vcpkg is not installed (we use a local copy separate from the system to avoid polluting the users vcpkg.
- helpers_ini.sh - INI reader and config merge/templating tool.  It also handles exporting the final config to a file so it can be consumed by other things (ie our visual studio sln generator).

# Custom build steps / blocks
In an effort to create cleaner build scripts some code was moved more behind the scenes in non obvious ways.  For example many steps will start the block with: `if [[ -z $SKIP_STEP || $SKIP_STEP == "STEPNAME" ]]; then` this means if no step is specified or if it is the step to resume at go into the block.  Easy enough.  What needs to happen inside that block is `SKIP_STEP=""` otherwise it won't proceed to the next step properly on resumes.  The built in steps this happens automatically on, generally the first function they call has a `SKIP_STEP=""` line.   The other item, purely for error messages, is "CUR_STEP".  If yo want to set this on entering a step to the step name and then set it back to empty at the end if there is an error it will say "you may be able to resume by passing step X to the build script.  This is not required though, purely a user help thing.

# debugging build failures

- Setting the env var `BLD_CONFIG_BUILD_DEBUG` to 1 will not only build with debug symbols but also will make the build scripts themselves more verbose.   

in the base working dir we generate several useful files including:
- `buildname-cmd.log` - Nearly all the shell commands our helper scripts execute on a given run
- `buildname-configure.log` - the output of the configure command
- `buildname-env.log` - The enviromental variables set when configure was run

The build scripts support resuming.  Most support several default steps (run the buildscript with --help to see the list of those).  IE `./f_buildname_build.sh bootstrap` will start at the bootstrapping step.  Some build scripts make have custom steps in them you can see by opening them.
It is not recommended to run most commands manually but rather try to use the resuming of the build script.  There can often be environmental variables set in the script that if not set when the command is run manually will change the outcome. 

# patch generation
Easy way to generate the patch from modified repo, go to your modified branch (make sure code committed) and run: git diff --color=never master > repo_NAME.patch

You will want to preserve whitespace when generating the patch but we will ignore whne applying.


# GitHub Actions
The github action build scripts use some cheats to work. For one, because we can't wait cross workflow completions deps are done based on the last flow.  If openssl depends on our zstd then the zstd copy it uses to build is the one from the github action prior to the current one.  This past artifact use means if a bug is fixed in a dep it may require two commits to show in the final product. Technically this can have a recursive effect.  If A depends on B which depends on C and a bug is fixed in C it may take 3 commits to reach A (first commit fixes it in C and generates the C artifact, next commit results in B being built with the updated artifact, and finally the 3rd commit results in C picking it up).  This only applies when one dep completely includes the other.  If B just references A and C also references A then in two commits C will pick it up.

In theory we could build on non-windows platforms but right now we dont try to do so as I am not sure there is much reason.  There would also need to be some windows specific changes to the helpers gated properly.

Right now we build static versions in debug and release configurations for every library.