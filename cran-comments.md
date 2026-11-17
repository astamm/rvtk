## Resubmission

This is a resubmission of the package update from v0.1.3 to v0.2.0.

## Summary of the update

* VTK version bumped from 9.5.2 to 9.7.2.
* Six additional VTK modules are now bundled by default: `VTK_IOGeometry`,
  `VTK_FiltersCore`, `VTK_FiltersGeneral`, `VTK_FiltersGeometry`,
  `VTK_FiltersModeling`, and `VTK_FiltersExtraction`.
* Test coverage raised to 100% (line coverage) with new tests exercising the
  module-filtering logic and every branch of `use_rvtk()`.
* New vignette documenting how downstream R packages link against VTK through
  rvtk, both manually and via `use_rvtk()`.

## CRAN check failures reported on v0.1.3 (addressed in 0.2.0)

Two failures reported by CRAN on v0.1.3 are resolved in 0.2.0, with evidence
provided by the `prebuilt-audit` workflow (`.github/workflows/prebuilt-audit.yaml`),
which replicates both external-checker environments, forces the pre-built VTK
fallback, runs the package tests, and compiles and links a C++ program against
the downloaded archives:

1. **linux-arm64** (`r-devel/linux-arm64-checks`): `ERROR: Unsupported Linux
   architecture 'aarch64'.`  The v0.1.3 `configure` had no aarch64 branch.
   0.2.0 downloads `vtk-9.7.2-linux-aarch64.tar.gz` (ELF aarch64, glibc) when
   no system VTK is found on aarch64 Linux.  The `arm64-ubuntu` leg runs on an
   arm64 runner in `ghcr.io/r-devel/rcheckserver/ubuntu:latest` — the exact
   image used by CRAN's linux-arm64 checker.

2. **Alpine / musl** (`bastistician/Rcheck`): v0.1.3 downloaded the glibc
   x86_64 archive on musl systems (no musl branch existed) and the download
   failed with `mktemp: : Invalid argument` because the template
   `mktemp /tmp/vtk-prebuilt.XXXXXX.tar.gz` does not end in `XXXXXX` (busybox
   rejects it).  0.2.0 selects `vtk-9.7.2-linux-musl-x86_64.tar.gz` on musl
   (detected with the POSIX-portable `getconf GNU_LIBC_VERSION` probe) and uses
   a valid `mktemp` template.  The `musl-alpine` leg installs in
   `ghcr.io/bastistician/rcheck-musl:latest` and also asserts that the new libc
   probe correctly identifies musl.

## R CMD check results

0 errors | 0 warnings | 0 notes (locally, on macOS arm64).
R CMD check is also run in CI on macOS, Windows, and Linux (release, oldrel-1,
and devel) via GitHub Actions.

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
