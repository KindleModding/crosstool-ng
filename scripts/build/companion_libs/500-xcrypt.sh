# Build script for libxcrypt

do_xcrypt_get() { :; }
do_xcrypt_extract() { :; }
do_xcrypt_for_build() { :; }
do_xcrypt_for_host() { :; }
do_xcrypt_for_target() { :; }

if [ "${CT_XCRYPT_TARGET}" = "y" ]; then

do_xcrypt_get() {
    CT_Fetch XCRYPT
}

do_xcrypt_extract() {
    CT_ExtractPatch XCRYPT
}

do_xcrypt_for_target() {
    local -a xcrypt_opts
    local prefix

    CT_DoStep INFO "Installing libxcrypt for target"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-xcrypt-target-${CT_TARGET}"

    xcrypt_opts+=( "host=${CT_TARGET}" )
    case "${CT_TARGET}" in
        *-*-mingw*)
            prefix="/mingw"
            ;;
        *)
            prefix="/usr"
            ;;
    esac
    xcrypt_opts+=( "cflags=${CT_ALL_TARGET_CFLAGS}" )
    xcrypt_opts+=( "prefix=${prefix}" )
    xcrypt_opts+=( "destdir=${CT_SYSROOT_DIR}" )
    xcrypt_opts+=( "shared=${CT_SHARED_LIBS}" )

    do_xcrypt_backend "${xcrypt_opts[@]}"

    CT_Popd
    CT_EndStep
}

# Build libxcrypt
#   Parameter     : description               : type      : default
#   host          : machine to run on         : tuple     : (none)
#   prefix        : prefix to install into    : dir       : (none)
#   destdir       : install destination       : dir       : (none)
do_xcrypt_backend() {
    local host
    local prefix
    local cflags
    local ldflags
    local shared
    local arg
    local -a extra_config

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    extra_config+=(
        "-disable-werror"
    )
    if [ "${shared}" != "y" ]; then
        extra_config+=("--disable-shared")
    fi
    # NOTE: We assume that we only want a *single* crypt implementation,
    #       so CT_XCRYPT_TARGET is only set when glibc's libcrypt has been disabled.
    extra_config+=("--enable-obsolete-api=no")

    CT_DoLog EXTRA "Configuring libxcrypt"

    CT_DoExecLog CFG                                                \
    CFLAGS="${cflags}"                                              \
    LDFLAGS="${ldflags}"                                            \
    ${CONFIG_SHELL}                                                 \
    "${CT_SRC_DIR}/xcrypt/configure"                                \
        --build=${CT_BUILD}                                         \
        --host=${host}                                              \
        --prefix="${prefix}"                                        \
        "${extra_config[@]}"

    CT_DoLog EXTRA "Building libxcrypt"
    CT_DoExecLog ALL make ${CT_JOBSFLAGS}
    CT_DoLog EXTRA "Installing libxcrypt"
    CT_DoExecLog ALL make install DESTDIR="${destdir}"
}

fi
