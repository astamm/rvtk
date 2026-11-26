# Set up a downstream package to use rvtk

A [usethis](https://usethis.r-lib.org/)-style helper that configures a
downstream R package to link against VTK via **rvtk**. It performs the
following steps:

- Adds `rvtk` to the `Imports` field of `DESCRIPTION`.

- Writes `src/Makevars` that queries compiler and linker flags at
  install time by calling `tools/configure.R`.

- Writes `src/Makevars.win` with the Windows-specific `$(shell ...)`
  syntax that does the same.

- Writes `tools/configure.R` that calls
  [`CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md)
  and
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
  with the requested VTK modules.

- Adds `src/vtk_libs.rsp` to `.gitignore` (it is generated at install
  time and must not be committed).

- Creates `R/rvtk_imports.R` with a minimal `@importFrom rvtk` roxygen
  tag so that `R CMD check` does not complain about **rvtk** being
  listed in `Imports` without any function import in the R code.

After running `use_rvtk()` the downstream package is fully configured:
VTK compiler and linker flags are resolved automatically at
`R CMD INSTALL` time on all platforms without any shell `configure` /
`configure.win` scripts.

## Usage

``` r
use_rvtk(modules = NULL, path = ".")
```

## Arguments

- modules:

  A character vector of VTK module names to link against, or `NULL` (the
  default) to link the full set of VTK modules bundled with **rvtk**.
  These are passed to
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
  in the generated `tools/configure.R`. The pre-built archives are
  static libraries, so the linker extracts only the object files
  actually referenced by your code: linking everything by default cannot
  fail with "missing module" symbols (e.g. the `vtkParallelDIY` /
  `vtkIOCellGrid` failures seen with older curated defaults), and
  passing a subset such as `c("vtkIOLegacy", "vtkCommonCore")` is an
  optimisation that reduces link time and keeps the resulting binary
  smaller for packages that use only part of VTK.

- path:

  Path to the root of the downstream package. Defaults to the current
  working directory.

## Value

Invisibly, the normalised path to the package root. Called primarily for
its side effects.

## See also

[`CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md),
[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)

## Examples

``` r
# Configure a minimal package in a temporary directory
pkg <- file.path(tempdir(), "mypkg")
dir.create(pkg, recursive = TRUE)
writeLines(c(
  "Package: mypkg",
  "Title: My Package",
  "Description: A package that links against VTK.",
  "Version: 0.0.1"
), file.path(pkg, "DESCRIPTION"))
use_rvtk(path = pkg)
#> ✔ Added rvtk to Imports in DESCRIPTION.
#> ✔ Writing src/Makevars.
#> ✔ Writing src/Makevars.win.
#> ✔ Writing tools/configure.R.
#> ✔ Adding "src/vtk_libs.rsp" to .gitignore.
#> ✔ Writing R/rvtk_imports.R.
#> ✔ Package mypkg is now configured to link against VTK via rvtk.
list.files(pkg, recursive = TRUE)
#> [1] "DESCRIPTION"       "R/rvtk_imports.R"  "src/Makevars"     
#> [4] "src/Makevars.win"  "tools/configure.R"
unlink(pkg, recursive = TRUE)
```
