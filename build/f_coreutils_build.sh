#!/bin/bash

OUR_PATH="$(readlink -f "$0")";
CALL_CMD="$1"

SCRIPT_FOLDER="$(dirname "${OUR_PATH}")"
if [[ ! -z "$WLB_SCRIPT_FOLDER" ]]; then
	SCRIPT_FOLDER="${WLB_SCRIPT_FOLDER}"
fi
. "$SCRIPT_FOLDER/helpers.sh" "${CALL_CMD}" "${OUR_PATH}"


PreInitialize;


BLD_CONFIG_BUILD_NAME="coreutils";
BLD_CONFIG_CONFIG_CMD_ADDL="fu_cv_sys_mounted_getfsstat=yes fu_cv_sys_stat_statvfs=yes --enable-no-install-program=chcon,chgrp,chmod,chown,selinux,runcon,mknod,mkfifo,expr,tty,groups,group-list,id,kill,logname,nohup,ptx,split"
BLD_CONFIG_ADD_WIN_ARGV_LIB=1
#needed for whois
BLD_CONFIG_CONFIG_ADL_LIBS="-lAdvapi32"
BLD_CONFIG_GNU_LIBS_ADDL=( "ioctl" "symlink" "unistd" "sigpipe" "fprintf-posix" )
#We cannot use it as we need automake-subdirs which it does not support
BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY=0
#BLD_CONFIG_GNU_LIBS_USE_GNULIB_TOOL_PY_ADDL_MK_FILES_FIX=( "lib/gnulib.mk" )

#warning we used to patch tee and split with some sigpipe work arounds see old diff for details now using sigpipe maybe not needed?
function ourmain() {
	startcommon;

if test 5 -gt 100; then
	echo "Just move the fi down as you want to skip steps"
fi

	git clone --recurse-submodules https://github.com/coreutils/coreutils .
	apply_our_repo_patch;
#fi
	add_items_to_gitignore;
#fi

	gnulib_add_addl_modules_to_bootstrap;

	gnulib_switch_to_master_and_patch;
	# We want to avoid patching these and just replace the types, used in lots of places and this way less likely to break on master changes
	#windows typedefs these so lets rename them
	git checkout src/od.c src/fmt.c
	sed -i -E "s/([ \t,:;]|^)(CHAR|INT|LONG|SHORT)([ \t,:;]|\\$)/\1SS\2\3/g" src/od.c
	#MS defines WORD already so lets change it
	sed -i -E "s/WORD/GNUWORD/g" src/fmt.c

	#Not sure why likely something with our gnulib_tool.py usage/dir fix but it wants to see alloc.c and alloc.in.h in the root rather than just the lib dir.  It still puts them in the lib dir so we will just symlink to where they will be;)
	cd $BLD_CONFIG_SRC_FOLDER


	setup_build_env; #need this for the autoconf patch

	./bootstrap --no-bootstrap-sync --no-git --gnulib-srcdir=gnulib --skip-po

#fi;
	gnulib_ensure_buildaux_scripts_copied;
#fi;
	configure_fixes;
	configure_run;
#fi


#	setup_build_env; #makes sure color is enabled before make
#	make
	make -j 8 || make #easier to see if there are errors than with multiplicity
	make install

	finalcommon;
}
ourmain;

