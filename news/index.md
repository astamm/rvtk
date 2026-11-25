# Changelog

## rvtk 0.3.0

#### New features

- **[`available_modules()`](https://astamm.github.io/rvtk/reference/available_modules.md)
  reports the VTK modules in the detected installation.** Every
  pre-built release archive now ships a `vtk_modules.txt` file listing
  the exact module set it was built with, and the `configure` /
  `configure.win` scripts install it (for a system VTK the list is
  derived from the linker flags recorded in `vtk.conf`, mirroring the
  same filtering logic).

- **[`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md) /
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
  validate requested modules (`check = TRUE` by default).** A downstream
  package that requests a module the installation does not provide now
  fails fast at install time with an actionable error listing the
  missing module(s) and the available set, instead of failing later with
  a confusing linker error. Set `check = FALSE` to skip validation and
  link whatever the installation provides.

- **Pre-built archives now ship every VTK module except a curated
  deny-list.** The hand-curated 18-module bundle is replaced by
  `VTK_BUILD_ALL_MODULES=ON` minus modules that pull in unavailable
  external dependencies (rendering toolkits, Python bindings, MPI,
  HDF5/netcdf/Exodus third-party IO, remote modules, …). The archive
  layout and the 160-archive whole-archive link check are updated
  accordingly; `vtk_modules.txt` is generated from the installed
  libraries so it always reflects exactly what an archive contains.

## rvtk 0.2.0

CRAN release: 2026-11-18

#### New features

- **VTK bumped from 9.5.2 to 9.7.2.** The pre-built static libraries
  shipped via GitHub Releases and the Windows build are built against
  VTK 9.7.2. The `configure` script now also probes `vtk-9.7` and
  `vtk-9.6` before earlier `pkg-config` versions, and `tools/winlibs.R`
  downloads the 9.7.2 build.

- **Six additional VTK modules enabled in the pre-built bundles.** The
  pre-built bundles now explicitly enable `VTK_IOGeometry`,
  `VTK_FiltersCore`, `VTK_FiltersGeneral`, `VTK_FiltersGeometry`,
  `VTK_FiltersModeling`, and `VTK_FiltersExtraction` (closing issue
  [\#5](https://github.com/astamm/rvtk/issues/5)), together with their
  transitive dependencies `VTK_ParallelDIY`, `VTK_ParallelCore`,
  `VTK_FiltersHyperTree`, and `VTK_FiltersStatistics` (closing the
  undefined-symbol failures of issue
  [\#14](https://github.com/astamm/rvtk/issues/14)). These modules are
  also linked by `configure`’s `vtk_build_flags()` when a system VTK
  installation is found.

- **[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md):
  one-call downstream package setup.** A new
  [usethis](https://usethis.r-lib.org/)-style helper that configures a
  downstream R package to link against VTK in one step. Running
  [`rvtk::use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
  inside a downstream package project:

  1.  Adds `rvtk` to the `Imports` field of `DESCRIPTION`.
  2.  Writes `src/Makevars` with backtick-style `Rscript` invocations
      that query `tools/configure.R` for compiler and linker flags.
  3.  Writes `src/Makevars.win` with the Windows-specific `$(shell ...)`
      syntax that does the same.
  4.  Writes `tools/configure.R` that calls
      [`rvtk::CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md)
      and
      [`rvtk::LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
      with a customisable list of VTK modules.
  5.  Adds `src/vtk_libs.rsp` to `.gitignore`.
  6.  Creates `R/rvtk_imports.R` with a minimal `@importFrom rvtk` tag
      so that `R CMD check` does not warn about an unused `Imports`
      entry.

  By default the **full bundled VTK** is linked (`modules = NULL`); the
  `modules` argument lets downstream developers restrict linking to only
  the VTK modules they need, reducing link time and producing a smaller
  downstream package (an optimisation, not a requirement — see “Bug
  fixes” below). Uses **cli** for formatted console output when
  available (it is an optional dependency, listed in `Suggests`).

- **Linux x86_64 musl (Alpine Linux) support.** The pre-built static
  fallback now provides a `vtk-X.Y.Z-linux-musl-x86_64.tar.gz` archive
  built inside an Alpine 3.22 container via `docker run` on the GitHub
  Actions runner (the `container:` job directive was not used because
  GitHub Actions’ Node.js runtime is glibc-linked and crashes on musl).
  The `configure` script detects musl by inspecting `ldd --version`
  output and automatically downloads the correct archive; no user action
  is required. This fixes installation on the CRAN musl check platform
  (`x86_64-pc-linux-musl`, Alpine Linux).

  The following extra CMake flags are set for the musl build to avoid
  X11 and rendering dependencies unavailable on the headless Alpine
  runner: `-DVTK_USE_X=OFF -DVTK_MODULE_ENABLE_VTK_RenderingOpenGL2=NO`.

- **Linux aarch64 support.** The pre-built static fallback now provides
  a `vtk-X.Y.Z-linux-aarch64.tar.gz` archive built on
  `ubuntu-24.04-arm`. The `configure` script detects the host
  architecture and downloads the correct archive automatically, so no
  user action is required.

- **Test coverage raised from ~48% to 100%.** New tinytest coverage
  exercises the `filter_libs()` module filtering and every branch of
  [`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
  and its internals (`rvtk_use_package`, `rvtk_write_file`,
  `rvtk_use_git_ignore`, `rvtk_rel_path`), including the base-R fallback
  messaging branches. The package now reports 100% line coverage under
  `covr::package_coverage()`.

#### Bug fixes

- **[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
  links the full bundled VTK by default (`modules = NULL`).** Downstream
  packages were failing to install or load on macOS and Linux with
  undefined-symbol errors such as
  `symbol not found: __ZN17vtkCellGridReader3NewEv` whenever they used a
  VTK feature outside rvtk’s curated 18- or 24-module default list. The
  pre-built bundles have always contained the full VTK library (161
  static archives), so the default is now to link **all** of them.
  Because the archives are static and the linker extracts only the
  object files a package references, linking everything adds no runtime
  code a package does not use. Restricting via `modules` is now purely
  an optimisation for link time and package size (closing issue
  [\#14](https://github.com/astamm/rvtk/issues/14) for good:
  `vtkParallelDIY`, `vtkParallelCore`, `vtkFiltersHyperTree`,
  `vtkIOCellGrid`, `vtkIOPLY`, … are all available with the default).

- **`configure`: `mktemp` incompatibility with BusyBox.** The temporary
  file for the pre-built archive download was created with a dotted
  suffix (`/tmp/vtk-prebuilt.XXXXXX.tar.gz`), which BusyBox `mktemp`
  rejects with `Invalid argument`. The suffix has been removed; the file
  is renamed internally before extraction.

- **`modules` argument for
  [`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md) and
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md).**
  Both linker-flag functions now accept a `modules` character vector
  that restricts linking to the named VTK modules (e.g.
  `c("vtkIOLegacy", "vtkCommonCore")`). When `NULL` (the default) all
  available modules are included, preserving backward compatibility.

  Restricting the list is an *optimisation* (shorter link times, smaller
  downstream packages), not a safety requirement: since the macOS static
  link no longer uses `-all_load` (see the next bullet), the only
  objects pulled from the pre-built archives are those your code
  actually references, so linking all 161 modules by default cannot drag
  `AppKit`-only symbols such as `_NSEventTrackingRunLoopMode` into a
  downstream `.so`. Packages that want a smaller build can pass only the
  modules they need:

  ``` sh
  VTK_LIBS="$("${R_HOME}/bin/Rscript" --vanilla -e "rvtk::LdFlagsFile(
    path    = 'src/vtk_libs.rsp',
    modules = c('vtkIOLegacy', 'vtkCommonCore', ...)
  )")"
  ```

- **macOS static link no longer uses `-Wl,-all_load`.** The pre-built
  static bundle (and the Windows-cross-compile path on macOS) previously
  linked with `-all_load`, which force-loads *every* object file from
  each selected static library. When a downstream package restricts
  linking to a subset of VTK modules, `-all_load` could still drag in an
  object file from a kept library that references a symbol whose
  defining module is not in the subset (e.g. `vtkCellGridReader::New()`
  from a module such as `vtkIOCellGrid`), causing an undefined-symbol
  failure at `dlopen()` time on macOS’s flat namespace. The default
  linker resolution is now used instead, which only pulls the objects
  actually needed — matching the ELF `--start-group` behaviour on Linux.
  Affects packages such as **riot** that [failed to install / load on
  macOS CI](https://github.com/tractoverse/tractoverse/actions) with
  `symbol not found in flat namespace '__ZN17vtkCellGridReader3NewEv'`.

#### Internal changes

- New internal helper `filter_libs()` implements the module-name
  matching used by all three platform branches of `read_vtk_conf()`.
- The optional-`cli`/interactive prompting decisions in
  [`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
  are now routed through small internal wrappers (`rvtk_has_cli()`,
  `rvtk_interactive()`, `rvtk_readline()`) so the messaging and
  overwrite branches can be unit-tested.

#### Documentation

- **Pre-built ABI constraints documented** (issue
  [\#15](https://github.com/astamm/rvtk/issues/15)). The pre-built
  static libraries are compiled with GCC and `libstdc++`. Downstream
  packages built with Clang `-stdlib=libc++` may fail to load with
  `__try_use_facet` undefined; packages built with newer GCC versions
  than the build toolchain may fail with `__cxa_call_terminate`. The
  README now documents that the archives are GCC / libstdc++ builds and
  recommends matching the compiler or linking against a system VTK
  installation.
- **macOS deployment target raised** (issue
  [\#16](https://github.com/astamm/rvtk/issues/16)). The pre-built macOS
  archives are now built with `-DCMAKE_OSX_DEPLOYMENT_TARGET=13.0`
  (previously they carried `LC_BUILD_VERSION minos 26.0`, which prevents
  loading on older macOS). The GitHub Actions workflow sets this for
  both the arm64 and x86_64 macOS jobs.
- **Valgrind report documented** (issue
  [\#17](https://github.com/astamm/rvtk/issues/17)). VTK’s pipeline
  internals allocate objects that valgrind reports as “definitely lost”
  (~1.5 KB) even in a minimal downstream consumer; this is inherent to
  the static libraries and does not indicate a leak in downstream code.
  An optional suppression file is shipped at `inst/valgrind/vtk.supp`
  and documented in the README / vignette.

## rvtk 0.1.3

CRAN release: 2026-05-11

#### New features

- **Windows VTK discovery** (`configure.win` rewritten). The package now
  searches for a system VTK installation on Windows before falling back
  to the pre-built libraries. Detection order:
  1.  `VTK_DIR` environment variable.
  2.  Rtools45 `pacman` (queries installed packages; never installs
      automatically).
  3.  Common Rtools45 / MSYS2 prefixes
      (`/x86_64-w64-mingw32.static.posix`, `/ucrt64`, `/mingw64`, …).
  4.  Automatic download of pre-built libraries (fallback — see below).
      Both static (`.a`) and shared (`.dll.a` import libs + DLLs) system
      installations are accepted.
- **Windows shared-DLL support** (`configure.win`, `tools/winlibs.R`,
  `R/vtk.R`, `R/zzz.R`). Windows now fully supports shared VTK
  libraries:
  - System or pacman/MSYS2 installations that provide `.dll.a` import
    libs are accepted and used directly.
  - A pre-built shared-DLL build (`vtk-X.Y.Z-shared-posix-x64.zip`) is
    available as an alternative to the existing static build. Select it
    by setting `VTK_LINK_TYPE=shared` before installing **rvtk**
    (default is `static`).
  - VTK DLLs are staged in rvtk’s own `inst/vtk-dlls/`. An `.onLoad`
    hook prepends that directory to `PATH` via
    [`Sys.setenv()`](https://rdrr.io/r/base/Sys.setenv.html) when rvtk
    is loaded, making the DLLs visible to all downstream packages that
    declare `Imports: rvtk` without any manual PATH manipulation. The
    original `PATH` is restored in `.onUnload()`. Downstream packages do
    **not** receive a copy of the DLLs — they piggyback on rvtk’s staged
    directory at run time.
- **`build-vtk-libs.yml`**: new `build-windows-shared` CI job produces
  `vtk-X.Y.Z-shared-posix-x64.zip` alongside the existing static
  archive.

#### Bug fixes

- **Unix pre-built static libraries survive `R CMD build`**
  (`configure`, `R/vtk.R`, `cleanup`). The pre-built archive is now
  extracted to `inst/prebuilt/` so that headers and static libraries
  ship inside the installed package. `read_vtk_conf()` resolves the
  actual paths at run time via
  `system.file("prebuilt", package = "rvtk")`, mirroring the Windows
  approach and surviving `R CMD build` temp-dir cycles.

#### Internal

- Removed dead variable `lib_root` from `tools/winlibs.R` (assigned but
  never read).
- Removed dead variable `all_libs_full` from the Windows static branch
  of `read_vtk_conf()` in `R/vtk.R` (assigned but never read;
  `lib_flags` is built entirely from `-l` short names).
- New CI workflow (`.github/workflows/downstream-check.yaml`) builds and
  checks a minimal downstream package against rvtk across all supported
  platform × VTK-strategy combinations (system, pre-built static,
  pre-built shared).

## rvtk 0.1.2

Re-submission addressing CRAN reviewer feedback on v0.1.1.

#### Changes

- **DESCRIPTION:** Software names (`'VTK'`, `'Homebrew'`,
  `'pkg-config'`, `'Rtools45'`) are now consistently quoted with single
  quotes in the Title, Description, and SystemRequirements fields, per
  CRAN policy. Function calls such as
  [`rvtk::CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md)
  are no longer wrapped in single quotes.
- **[`CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md),
  [`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md),
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md):**
  Replaced [`cat()`](https://rdrr.io/r/base/cat.html) with
  [`writeLines()`](https://rdrr.io/r/base/writeLines.html) and added
  [`invisible()`](https://rdrr.io/r/base/invisible.html) returns so
  functions behave in a more idiomatic R style while still allowing
  shell command-substitution capture.
- **`tools/winlibs.R`:** The Windows VTK zip is now extracted to a
  temporary directory
  ([`tempfile()`](https://rdrr.io/r/base/tempfile.html)) before being
  copied into `inst/windows/`. This avoids writing intermediate files to
  the package source tree (home filespace) during installation.
- **Examples:** All exported functions now have small, executable
  `@examples` entries.
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
  writes to [`tempdir()`](https://rdrr.io/r/base/tempfile.html) in its
  example.
- **Tests:** Test suite expanded to 100% line coverage of the
  non-platform- specific code paths on all platforms; Windows-specific
  branches
  ([`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
  response-file path, `read_vtk_conf()` Windows resolver) are exercised
  by the existing R-hub Windows CI jobs.

## rvtk 0.1.1

The planned CRAN submission of v0.1.0 was cancelled after downstream
package developers reported linker errors when building against the
pre-built Windows VTK libraries. Two root causes were identified and
fixed:

1.  **Wrong toolchain.** The Windows VTK zip was compiled with the
    Rtools45 UCRT64 toolchain (`/ucrt64/bin/gcc`), which uses a dynamic
    C runtime and emits DLL-import symbols (`__imp_fseeko64`,
    `__imp_ftello64`, …). However, `R CMD INSTALL` links R packages with
    the `x86_64-w64-mingw32.static.posix` toolchain, which is fully
    static. The mismatch caused undefined references to `nanosleep64`,
    `ftime64`, `__imp_fseeko64`, and `__imp_ftello64`. The GitHub
    Actions workflow now builds the Windows VTK zip with the
    `x86_64-w64-mingw32.static.posix` compiler, matching the toolchain
    that downstream packages use.

2.  **Command-line length overflow.** The full set of VTK `-l` linker
    flags exceeds the 8 191-character Windows command-line limit,
    causing the linker to silently drop flags at the end of the list. A
    new function `LdFlagsFile(path)` writes all flags to a response file
    and returns the short `@path` token that both GNU ld and LLVM lld
    support. Downstream packages should call
    `LdFlagsFile('src/vtk_libs.rsp')` from their `configure` /
    `configure.win` script instead of
    [`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md).

#### Changes

- **New function** `LdFlagsFile(path)`: writes VTK linker flags to a
  response file and returns `@path` for use in `Makevars`. Preferred
  over [`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md)
  on all platforms to avoid the Windows command-line length limit.
- Windows pre-built VTK libraries are now compiled with the
  `x86_64-w64-mingw32.static.posix` toolchain (Rtools45), matching the
  toolchain used by `R CMD INSTALL` for CRAN packages.
- Windows system libraries appended to `PKG_LIBS` reduced to `-lgdi32`
  only; the UCRT64-specific `-lwinpthread -lmingwex -lucrtbase` flags
  are no longer needed because the static.posix sysroot resolves POSIX
  symbols internally.
- README updated to document
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md),
  explain the rationale, provide a unified `configure` example valid on
  all platforms, and correct the Windows toolchain description.

## rvtk 0.1.0

- Initial CRAN submission.
- Bundles VTK 9.5.2 pre-built static libraries (`.a`) for Windows
  (Rtools45 UCRT x64), macOS arm64, macOS x86_64, and Linux x86_64,
  distributed via GitHub Releases and built with GitHub Actions.
- VTK discovery strategy on macOS and Linux (in priority order):
  1.  User-supplied `VTK_DIR` environment variable.
  2.  Homebrew (macOS only).
  3.  `pkg-config`.
  4.  Well-known system prefixes (`/usr`, `/usr/local`) (Linux only).
  5.  Automatic download of pre-built static libraries from
      <https://github.com/astamm/rvtk/releases> as a fallback.
- On Windows, pre-built UCRT64 static libraries are always downloaded
  automatically from <https://github.com/astamm/rvtk/releases>.
- **Windows limitation:** `netcdf` and `libproj` are not available in
  the Rtools45 UCRT64 environment. The following VTK modules are
  therefore disabled in the Windows pre-built libraries: `VTK_IONetCDF`,
  `VTK_IOHDF`, `VTK_GeovisCore`, `VTK_RenderingCore`. Downstream
  packages requiring these modules cannot be built on Windows with
  **rvtk**’s pre-built libraries.
- Downstream packages can retrieve compiler and linker flags via
  [`rvtk::CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md)
  and
  [`rvtk::LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md).
