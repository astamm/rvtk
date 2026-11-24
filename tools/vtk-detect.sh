# tools/vtk-detect.sh -- shared VTK detection helpers.
# Source this file (. tools/vtk-detect.sh) from configure / configure.win.
#
# Caller must set before sourcing:
#   VTK_MIN_SUFFIX        e.g. "9.1"
#
# Optionally: CXX (the C++ compiler R would use for packages; export CXX=... to
# override).  Used by vtk_detect_stdlib to pick between the GNU (libstdc++)
# and libc++ pre-built archives below.

## vtk_detect_from_prefix PREFIX
## On success sets vtk_include_dir and vtk_version_suffix and returns 0.
vtk_detect_from_prefix() {
    _prefix="$1"
    _min="${VTK_MIN_SUFFIX}"

    ## Versioned include directory (vtk-X.Y)
    _vdir="$(find "${_prefix}/include" -maxdepth 1 -name "vtk-*" -type d 2>/dev/null \
        | sort -V | tail -1)"
    if test -n "${_vdir}"; then
        _sfx="$(basename "${_vdir}" | sed 's/^vtk-//')"
        if printf '%s\n%s\n' "${_min}" "${_sfx}" | sort -V | head -1 \
                | grep -qx "${_min}"; then
            vtk_version_suffix="${_sfx}"
            vtk_include_dir="${_vdir}"
            return 0
        fi
        return 1
    fi

    ## Unversioned include directory (vtk/)
    if test -d "${_prefix}/include/vtk"; then
        _hdr="${_prefix}/include/vtk/vtkVersionQuick.h"
        if test -f "${_hdr}"; then
            _major="$(grep '#define VTK_MAJOR_VERSION' "${_hdr}" | awk '{print $3}')"
            _minor="$(grep '#define VTK_MINOR_VERSION' "${_hdr}" | awk '{print $3}')"
            if test -n "${_major}" && test -n "${_minor}"; then
                _det="${_major}.${_minor}"
                if printf '%s\n%s\n' "${_min}" "${_det}" | sort -V | head -1 \
                        | grep -qx "${_min}"; then
                    vtk_version_suffix=""
                    vtk_include_dir="${_prefix}/include/vtk"
                    return 0
                fi
                return 1
            fi
        fi
        echo "WARNING: Could not read VTK version from ${_hdr}; proceeding." >&2
        vtk_version_suffix=""
        vtk_include_dir="${_prefix}/include/vtk"
        return 0
    fi

    return 1
}

## vtk_detect_stdlib
## Detects which C++ standard library the package build would link against.
## vtksys / the bundled third-party code is C-only, but the header includes
## (vtkType.h -> <vector>, <string>, ...) and any consumer TU pull in libc++ or
## libstdc++ symbols, so the pre-built static archives must match the runtime
## the compiler targets.
##
##   libc++     -- clang with -stdlib=libc++  (CRAN's r-devel-linux-x86_64-
##                 fedora-clang flavor defaults to libc++)
##   libstdc++  -- GCC, or clang targeting libstdc++ (the common macOS/Homebrew
##                 system-VTK case)
##   unknown    -- the compiler is unavailable or exports neither macro
##
## Detection compiles a TU that expands <ciso646> macros; _LIBCPP_VERSION proves
## libc++, __GLIBCXX__ proves libstdc++.  Prefer the compiler R recorded as CXX
## so the probe matches real package builds: the CXX environment variable when
## set, otherwise `R CMD config CXX` (which honours the user's Makevars; R does
## not export CXX into configure's environment before R 4.3), and finally `c++`
## from PATH.
vtk_detect_stdlib() {
    vtk_stdlib="unknown"
    _probe_cxx="${CXX:-}"
    if test -z "${_probe_cxx}" && command -v R > /dev/null 2>&1; then
        _probe_cxx="$(R CMD config CXX 2>/dev/null)"
    fi
    _probe_cxx="${_probe_cxx:-c++}"
    _tmpf="${TMPDIR:-/tmp}/rvtk-stdlib-probe.$$"
    cat > "${_tmpf}.cc" << 'EOF'
#if defined(__has_include)
#  if __has_include(<ciso646>)
#    include <ciso646>
#  endif
#endif
#if defined(_LIBCPP_VERSION)
#  define RVTK_STDLIB libcxx
#elif defined(__GLIBCXX__)
#  define RVTK_STDLIB libstdcxx
#else
#  define RVTK_STDLIB unknown
#endif
RVTK_STDLIB
EOF
    ## Compile only (-c), never link, and tolerate compiler absence / errors.
    if ${_probe_cxx} -x c++ -std=c++17 -E -dM "${_tmpf}.cc" > "${_tmpf}.out" 2>/dev/null; then
        if grep -q '^#define _LIBCPP_VERSION' "${_tmpf}.out"; then
            vtk_stdlib="libc++"
        elif grep -q '^#define __GLIBCXX__' "${_tmpf}.out"; then
            vtk_stdlib="libstdc++"
        fi
    fi
    rm -f "${_tmpf}.cc" "${_tmpf}.out"
}

## vtk_generate_module_list OUT_FILE
## Derive the available module list from the recorded linker flags (vtk_libs),
## mirroring rvtk::vtk_conf_modules() in R: keep vtk<UpperCase> modules and
## vtksys, drop bundled third-party libs, write sorted unique list to OUT_FILE.
vtk_generate_module_list() {
    _out="$1"
    printf '%s\n' "${vtk_libs}" \
    | tr ' ' '\n' \
    | sed -n 's/^-l//p' \
    | sed -E 's/^lib//; s/\.a$//; s/\.dll$//; s/-[0-9].*$//' \
    | grep -E '^(vtk[A-Z]|vtksys)' \
    | sort -u > "${_out}"
}

## Initialise shared state variables.
vtk_found="no"
vtk_version_suffix=""
vtk_include_dir=""
vtk_lib_dir=""
vtk_cppflags=""
vtk_libs=""
vtk_version=""
