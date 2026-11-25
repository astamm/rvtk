## Update

This is a submission of the package update from v0.2.0 to v0.3.0 (a regular
version update; not a resubmission of a previously rejected package).

## Summary of the update

* **Module availability is now explicit.** Each pre-built release archive ships
  a `vtk_modules.txt` recording the exact module set it was built with;
  `available_modules()` reports it at run time. `LdFlags()` and `LdFlagsFile()`
  validate requested modules by default (`check = TRUE`): a request for a
  module the installation does not provide fails fast at install time with an
  actionable error, instead of surfacing later as a linker error.
* **Pre-built archives now contain every buildable VTK module.** The hand-curated
  18-module bundle of 0.2.0 is replaced by `VTK_BUILD_ALL_MODULES=ON` minus a
  deny-list of modules that pull in unavailable external dependencies
  (rendering toolkits, Python bindings, MPI, HDF5/netcdf/Exodus third-party IO,
  remote modules, ...). The archives therefore provide all modules that can be
  built without external dependencies, and downstream packages opt in to
  linking a subset (`modules = ...` in `LdFlags()`, `LdFlagsFile()`,
  `use_rvtk()`) to reduce link time and storage. Each archive holds
  **160 static libraries**: 110 VTK kit modules, `libvtksys`, 23 viskores
  libraries, and 26 third-party libraries.
* **System-VTK behavior is now fail-fast too.** When rvtk links against a
  system VTK installation, the available modules are derived from the
  recorded linker flags and a downstream package requesting a module the
  system VTK does not provide hard-fails at install time rather than at load.
* **Third-party license notices in the archives were audited and corrected.**
  The `licenses/` tree bundled into each archive now matches exactly what the
  archives contain: notices for components that are not shipped (CGNS,
  ExodusII, HDF5, IOSS, netCDF, PROJ) were removed, and notices for shipped
  components that were missing (Viskores, LCL, lodepng, VPIC) were added.
* **Previous pre-built archive issues are resolved.** The four issues raised by
  CRAN-facing rhub runs of 0.2.0 (downstream undefined symbols from a
  too-small curated module set, libstdc++ ABI incompatibility for
  clang/libc++ consumers, macOS deployment target, and Valgrind "definitely
  lost" reports in VTK internals) are addressed: see the CI section, the
  README, and the package vignettes.

## CI on CRAN-relevant platforms

Because this package conditionally downloads pre-built binaries at install
time, CI replicates the CRAN environments where hosted runners cannot reach
the archives:

* **`prebuilt-audit.yaml`** runs two legs in the *exact* containers CRAN's
  checkers use:
  * `arm64-ubuntu` — `ghcr.io/r-devel/rcheckserver/ubuntu:latest` on an arm64
    runner (CRAN's linux-arm64 checker image). Installs the source tarball,
    asserts the `linux-aarch64` archive is selected, runs the tinytest suite,
    and compiles, links, and runs a C++ program against the real aarch64
    archives.
  * `musl-alpine` — `ghcr.io/bastistician/rcheck-musl:latest` (Alpine, R built
    against musl; the environment of CRAN's `bastistician/Rcheck`). Same
    recipe, asserting the musl archive is selected and that the busybox
    `mktemp` guard holds.
* **`R-CMD-check.yaml`** runs `R CMD check` on 8 matrix legs: macOS (arm64;
  system VTK and pre-built), Windows (system VTK and pre-built), and Linux
  (release, oldrel-1, and devel; system VTK and pre-built).
* **`rhub.yaml`** runs the standard `r-hub/actions/check-for-cran` workflow on
  Linux, Windows, and macOS at every release candidate.

The archive build workflow (`build-vtk-libs.yml`) additionally gates each
archive before publication with a whole-archive link check, a macOS
deployment-target check (`otool` asserts `minos 13.0`), and a libc++-ABI
check (no `__try_use_facet` / `__cxa_call_terminate` in the libc++ archive).

## R CMD check results

0 errors | 0 warnings | 0 notes (locally, on macOS arm64, and on the CI
matrix above).

### Platforms checked

* **CRAN standard flavors** — all OK on v0.2.0 (the version currently listed
  by CRAN); v0.3.0 is checked locally and on the CI matrix above, and is
  submitted for the full 13-flavor run.
* **R-hub** — see `rhub.yaml`; earlier 0.2.0 rhub runs are documented below.

## Notes

* The package downloads pre-built VTK 9.7.2 libraries at install time from
  <https://github.com/astamm/rvtk/releases/tag/v9.7.2> when no suitable system
  VTK installation is found. Pre-built binaries are provided for Windows
  (Rtools45 static.posix x64, static and shared), macOS arm64, macOS x86_64,
  Linux x86_64 (glibc), Linux x86_64 (musl / Alpine), Linux x86_64
  (glibc, libc++/clang), and Linux aarch64.
* The installed package contains no compiled code (`NeedsCompilation: no`); it
  ships the pre-built VTK libraries and the build-time glue that downstream
  packages use to link against them.
* Since v0.1.3 both CRAN-flagged platforms (linux-arm64 and musl) are
  exercised on every push and PR via the `prebuilt-audit` workflow.
* The pre-built libraries are static; downstream packages compiled against them
  are self-contained. The ABI and deployment-target constraints are documented
  in the README and vignette, and the libc++ archive serves CRAN's
  `r-devel-linux-x86_64-fedora-clang` flavor.

## Resubmission notes (v0.2.0, post-Rhub — retained for reference)

The rhub runs of 0.2.0 raised four issues, all resolved in 0.3.0:

1. **Downstream undefined-symbol failures (#14).** `vtkFiltersExtraction`
   depends on `vtkParallelDIY`, `vtkParallelCore`, and `vtkFiltersHyperTree`,
   which were missing from the curated default `modules` list. The pre-built
   bundles always contained the full VTK library; 0.3.0 ships every buildable
   module and `use_rvtk()` links **all** bundled modules by default
   (`modules = NULL`), which cannot fail with missing-module symbols.
2. **Pre-built ABI constraints (#15).** The GCC/libstdc++-built archives broke
   consumers using clang `-stdlib=libc++` or newer GCC. 0.3.0 adds a
   `*-linux-x86_64-libcxx` archive built with clang + libc++, selected by
   configure when the compiler targets libc++, and asserts at build time that
   it is free of libstdc++-ABI symbols.
3. **macOS deployment target (#16).** Older macOS archives carried
   `LC_BUILD_VERSION minos 26.0`. The build workflow passes
   `-DCMAKE_OSX_DEPLOYMENT_TARGET=13.0` for both macOS jobs and asserts the
   resulting `minos 13.0` before packaging.
4. **Valgrind "definitely lost" report (#17).** ~1.5 KB of VTK pipeline
   internals are reported as lost; inherent to the static build. A suppression
   file ships at `inst/valgrind/vtk.supp` and is documented in the vignette.
