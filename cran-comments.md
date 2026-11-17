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
