dotnet-script "%WLB_SCRIPT_FOLDER%\vs_debug_help\DebugProjGen.csx" --exe which --include_paths . --define HAVE_CONFIG_H --include sys.h posixstat.h --compile which.c bash.c getopt.c getopt1.c --libraries ./tilde/libtilde.a
