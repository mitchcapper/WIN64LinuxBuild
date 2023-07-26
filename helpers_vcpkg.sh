

vcpkg_ensure_installed(){
	echo CHECKING FOR $BLD_CONFIG_VCPKG_BIN
	if [[ -f "${BLD_CONFIG_VCPKG_BIN}" ]]; then
    	return
	fi
	mkdir -p "${BLD_CONFIG_VCPKG_DIR}"
	cd "${BLD_CONFIG_VCPKG_DIR}"
	git clone https://github.com/microsoft/vcpkg .
	./bootstrap-vcpkg.bat
}

vcpkg_remove_package(){
	vcpkg_ensure_installed
	local TO_INSTALL=""
	for TO_INSTALL in "$@"; do
		mkdir -p "${BLD_CONFIG_VCPKG_BINARY_DIR}"
		export VCPKG_DEFAULT_BINARY_CACHE="${BLD_CONFIG_VCPKG_BINARY_DIR}"
		local INSTALL_ROOT=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}" "no_triplet")
		local INSTALL_TRIPLET=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}" "triplet") #this will have the triplet on it if strip is off
		local INSTALL_TARGET=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}") #triplet included when strip is off
		mkdir -p "${INSTALL_TARGET}"
		if [[ $BLD_CONFIG_VCPKG_STRIP_TRIPLET -eq 1 && ! -e "$INSTALL_TRIPLET" ]]; then
			ln -s "${INSTALL_TARGET}" "$INSTALL_TRIPLET"
		fi

		#host triplet doesnt seem to work 100%
		"${BLD_CONFIG_VCPKG_BIN}" remove "${TO_INSTALL}:${BLD_CONFIG_VCPKG_TRIPLET}" "--x-install-root=${INSTALL_ROOT}"

	done
}


vcpkg_install_package(){ #if the first parameter after optionally --head is a function that function will be called on install failure
	vcpkg_ensure_installed
	local TO_INSTALL=""
	local install_postfix=""
	if [[ "$1" == "--head" ]]; then
		shift;
		install_postfix="--head --editable"
	fi
	local ON_FAIL;
	if [ "$(type -t $1)" = "function" ]; then
		ON_FAIL=$1;
		shift;
	fi
	for TO_INSTALL in "$@"; do
		mkdir -p "${BLD_CONFIG_VCPKG_BINARY_DIR}"
		export VCPKG_DEFAULT_BINARY_CACHE="${BLD_CONFIG_VCPKG_BINARY_DIR}"
		local INSTALL_ROOT=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}" "no_triplet")
		local INSTALL_TRIPLET=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}" "triplet") #this will have the triplet on it if strip is off
		local INSTALL_TARGET=$(get_install_prefix_for_vcpkg_pkg "${TO_INSTALL}") #triplet included when strip is off
		mkdir -p "${INSTALL_TARGET}"
		if [[ $BLD_CONFIG_VCPKG_STRIP_TRIPLET -eq 1 && ! -e "$INSTALL_TRIPLET" ]]; then
			ln -s "${INSTALL_TARGET}" "$INSTALL_TRIPLET" 
		fi

		local RUN_CMD=""
		#host triplet doesnt seem to work 100%
		if [ -z ${ON_FAIL+x} ]; then
			"${BLD_CONFIG_VCPKG_BIN}" install "${TO_INSTALL}:${BLD_CONFIG_VCPKG_TRIPLET}" --host-triplet=${BLD_CONFIG_VCPKG_TRIPLET} --allow-unsupported "--x-install-root=${INSTALL_ROOT}" ${install_postfix}
		else
			"${BLD_CONFIG_VCPKG_BIN}" install "${TO_INSTALL}:${BLD_CONFIG_VCPKG_TRIPLET}" --host-triplet=${BLD_CONFIG_VCPKG_TRIPLET} --allow-unsupported "--x-install-root=${INSTALL_ROOT}" ${install_postfix} || {
				$ON_FAIL
				return;
			}
		fi
		
		local FILES=`find "${INSTALL_TARGET}" -name "*.pc"`
		if [[ "${FILES}" != "" ]]; then
			mapfile -t TO_FIX <<<$FILES
			for fl in "${TO_FIX[@]}"; do
				sed -i -E "s#^prefix=.+#prefix=${INSTALL_TARGET}#" "${fl}"
			done
		fi
		local DEBUG_DIR="${INSTALL_TARGET}/debug"
		if [[ -e "${DEBUG_DIR}" && $BLD_CONFIG_BUILD_DEBUG -eq 1 ]]; then
			if [[ -e "${INSTALL_TARGET}/debug/lib/pkgconfig" && -e "${INSTALL_TARGET}/lib/pkgconfig" ]]; then #assume normal pkg config is fine avoid needing to recurse
				rm -rf "${INSTALL_TARGET}/debug/lib/pkgconfig"
				rmdir --ignore-fail-on-non-empty "${INSTALL_TARGET}/debug/lib"
			fi
			for fl in "$DEBUG_DIR"/*; do
				if [[ -d "${fl}" ]]; then
					local DIR_NAME="${fl##*/}"    # print everything after the final "/"
					mv "${fl}"/* "${INSTALL_TARGET}/${DIR_NAME}/"
					rmdir "${fl}"
				else
					mv "${fl}" "${INSTALL_TARGET}/"
				fi
			done

			rmdir "${DEBUG_DIR}"
		fi
	done
}
get_install_prefix_for_vcpkg_pkg(){
	local BLD_NAME=$1
	local TRIPLET_FORCE=$2
	# cheating rather than actually try to reparse templates
	ADD_TRIPLET=""
	if [[  (! $BLD_CONFIG_VCPKG_STRIP_TRIPLET -eq 1 && ! $TRIPLET_FORCE == "no_triplet") || $TRIPLET_FORCE == "triplet" ]]; then
		ADD_TRIPLET="/${BLD_CONFIG_VCPKG_TRIPLET}"
	fi
	echo "${BLD_CONFIG_VCPKG_INSTALL_TARGET_BASEDIR}/${BLD_NAME}${ADD_TRIPLET}"
}
add_vcpkg_pkg_config(){
	local PTH=""
	#VCPKG_INSTALL_TARGET_BASEDIR
	for var in "$@"; do
		PTH=$(get_install_prefix_for_vcpkg_pkg "${var}")
		PTH=$(convert_to_msys_path "${PTH}")
		PKG_CONFIG_PATH="${PTH}/lib/pkgconfig:${PKG_CONFIG_PATH}";
	done
}