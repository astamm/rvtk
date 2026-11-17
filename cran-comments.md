## New submission

This is a new submission of the package update from v0.1.3 to v0.2.0 (first
submission of this version; not a resubmission of a rejected package).

## Summary of the update

* VTK version bumped from 9.5.2 to 9.7.2.
* Six additional VTK modules are now bundled by default: `VTK_IOGeometry`,
  `VTK_FiltersCore`, `VTK_FiltersGeneral`, `VTK_FiltersGeometry`,
  `VTK_FiltersModeling`, and `VTK_FiltersExtraction`.
* Test coverage raised to 100% (line coverage) with new tests exercising the
  module-filtering logic and every branch of `use_rvtk()`.
* New vignette documenting how downstream R packages link against VTK through
  rvtk, both manually and via `use_rvtk()`.

## All issues raised in the CRAN check results are resolved

The check results at
<https://cran.r-project.org/web/checks/check_results_rvtk.html> show all 13
standard flavors with status OK for v0.1.3, and two entries under "Additional
issues": linux-arm64 and musl. Both are resolved in 0.2.0 and are now covered
by a dedicated CI workflow (`.github/workflows/prebuilt-audit.yaml`) that
replicates each checker's environment and proves the fix by installing the
package and compiling, linking, and running a real C++ program against the
downloaded pre-built archives:

1. **linux-arm64** (`r-devel/linux-arm64-checks`): `ERROR: Unsupported Linux
   architecture 'aarch64'.` The v0.1.3 `configure` had no aarch64 branch.
   0.2.0 downloads `vtk-9.7.2-linux-aarch64.tar.gz` (ELF aarch64, glibc) when
   no system VTK is found on aarch64 Linux. The `arm64-ubuntu` leg of the
   `prebuilt-audit` workflow runs on an arm64 runner in
   `ghcr.io/r-devel/rcheckserver/ubuntu:latest` — the exact image used by
   CRAN's linux-arm64 checker — and verifies the aarch64 archive is selected,
   the tinytest suite passes (118 tests), and a VTK 9.7.2 C++ program links
   and runs.

2. **Alpine / musl** (`bastistician/Rcheck`): v0.1.3 downloaded the glibc
   x86_64 archive on musl systems (no musl branch existed) and the download
   failed with `mktemp: : Invalid argument` because the template
   `mktemp /tmp/vtk-prebuilt.XXXXXX.tar.gz` does not end in `XXXXXX` (busybox
   rejects it). 0.2.0 selects `vtk-9.7.2-linux-musl-x86_64.tar.gz` on musl
   (detected with the POSIX-portable `getconf GNU_LIBC_VERSION` probe) and
   uses a valid `mktemp` template. The `musl-alpine` leg of `prebuilt-audit`
   runs in `ghcr.io/bastistician/rcheck-musl:latest` (Alpine 3.24, R built
   against musl), asserts that the new libc probe identifies musl, verifies
   the musl archive is selected, runs the tinytest suite (118 tests), and
   links and runs a VTK 9.7.2 C++ program.

## R CMD check results

0 errors | 0 warnings | 0 notes (locally, on macOS arm64).

### Platforms checked

* **CRAN standard flavors (13)** — all OK on v0.1.3 (the version currently
  listed by CRAN):
  * r-devel-linux-x86_64-debian-clang, r-devel-linux-x86_64-debian-gcc,
    r-devel-linux-x86_64-fedora-clang, r-devel-linux-x86_64-fedora-gcc
  * r-devel-windows-x86_64
  * r-patched-linux-x86_64
  * r-release-linux-x86_64, r-release-macos-arm64, r-release-macos-x86_64,
    r-release-windows-x86_64
  * r-oldrel-macos-arm64, r-oldrel-macos-x86_64, r-oldrel-windows-x86_64
* **R-hub (33 platforms)** — `R CMD check` run on: linux, m1-san, windows,
  macos-arm64, atlas, c23, clang16, clang17, clang18, clang19, clang20,
  clang21, clang22, clang-asan, clang-ubsan, donttest, gcc13, gcc14, gcc15,
  gcc16, gcc-asan, intel, lto, mkl, nold, noremap, nosuggests, ubuntu-clang,
  ubuntu-gcc12, ubuntu-next, ubuntu-release, valgrind. 32 of 33 completed
  cleanly; the `macos` (R-devel) job was cancelled by the 24-hour workflow
  limit of the R-hub Intel macOS checker. macOS x86_64 is additionally covered
  by CRAN's own `r-release-macos-x86_64` and `r-oldrel-macos-x86_64` checkers
  (both OK) and by the CI matrix below.
* **GitHub Actions CI (this package)** — `R CMD check` on macOS (arm64;
  system VTK and pre-built), Windows (system VTK and pre-built), and Linux
  (release, oldrel-1, and devel; system VTK and pre-built), 8 matrix legs.
  Also run on every push/PR: pkgdown, test coverage, and `R CMD check`.
* **Downstream integration checks** — `downstream-check` builds and checks a
  minimal downstream R package (compiled against rvtk via `use_rvtk()` and a
  hand-written manual setup, asserted byte-identical) on 18 matrix legs
  covering system, prebuilt-static, prebuilt-shared, and built-shared VTK on
  macOS, Windows, and Linux. `riot-check` installs and checks the real
  downstream package `riot` on 11 matrix legs and round-trips riot's VTK
  bundle files.
* **prebuilt-audit (CRAN checker environments)** — the two container legs
  described above: Linux aarch64 (CRAN's arm64 checker image) and Linux x86_64
  musl (bastistician's `rcheck-musl` image). Both force the pre-built VTK
  fallback, verify the correct archive is selected per OS/arch/libc, run the
  full tinytest suite, and compile, link, and run a C++ program against the
  real archives.

## Notes

* The package downloads pre-built VTK 9.7.2 libraries at install time from
  <https://github.com/astamm/rvtk/releases/tag/v9.7.2> when no suitable system
  VTK installation is found.
* Pre-built binaries are provided for Windows (Rtools45 static.posix x64,
  static and shared), macOS arm64, macOS x86_64, Linux x86_64 (glibc),
  Linux x86_64 (musl / Alpine), and Linux aarch64.
* The installed package does not contain compiled code
  (`NeedsCompilation: no`); it ships pre-built VTK libraries that downstream
  packages link against at build time.
* Since v0.1.3 both CRAN-flagged platforms (linux-arm64 and musl) are
  exercised on every push and PR via the `prebuilt-audit` workflow.
