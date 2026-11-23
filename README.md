

<!-- README.md is generated from README.qmd. Please edit that file -->

# rvtk <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/astamm/rvtk/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/astamm/rvtk/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/astamm/rvtk/graph/badge.svg)](https://app.codecov.io/gh/astamm/rvtk)
[![pkgdown](https://github.com/astamm/rvtk/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/astamm/rvtk/actions/workflows/pkgdown.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/rvtk)](https://CRAN.R-project.org/package=rvtk)
<!-- badges: end -->

**rvtk** is an infrastructure package for R package developers: it makes
the [Visualization Toolkit (VTK)](https://vtk.org/) available to R
packages that need to link against it from C++. Your users never install
VTK themselves — rvtk finds a system VTK when one is present and
otherwise downloads pre-built libraries automatically at install time.

Add `Imports: rvtk` to your `DESCRIPTION`, then configure your package
in one step from the package root:

``` r
rvtk::use_rvtk()
```

`use_rvtk()` writes `src/Makevars`, `src/Makevars.win`, and
`tools/configure.R` so that the compiler and linker flags are resolved
at install time via `rvtk::CppFlags()` and `rvtk::LdFlagsFile()`.
Everything can also be set up by hand — the two approaches produce
identical files.

Pre-built libraries are provided for macOS (arm64 and x86_64), Linux
(x86_64 glibc, x86_64 musl/Alpine, aarch64, and a clang `-stdlib=libc++`
variant of x86_64 glibc), and Windows (static or shared DLLs). rvtk’s
`configure` script detects the compiler’s C++ standard library and picks
the matching Linux archive automatically.

> **ABI compatibility of the pre-built libraries.** The pre-built
> archives are compiled with **GCC and libstdc++** (on Windows, the
> Rtools45 `static.posix` MinGW toolchain), except for the dedicated
> Linux x86_64 **libc++** archive built with Clang. Downstream packages
> should use a matching toolchain: linking the libstdc++ archive with
> Clang `-stdlib=libc++` fails to load with an undefined
> `__try_use_facet` symbol, and linking with a much newer GCC than the
> build toolchain may fail with `__cxa_call_terminate`. On Linux x86_64,
> `configure` detects which standard library the compiler targets and
> downloads the matching archive; on other platforms, install a system
> VTK (e.g. via Homebrew or apt) if your toolchain cannot match the
> bundled one.

**See the [vignette](https://astamm.github.io/rvtk/articles/rvtk.html)
for full details:** how VTK is located on each platform (with the
compatibility matrix), which VTK modules are bundled, manually writing
the build files, restricting linking with the `modules` argument, and
verifying that linking worked.

## Valgrind

A minimal downstream program that reads a VTK file reports ~1.5 KB
“definitely lost” under valgrind, allocated inside VTK’s pipeline
internals (`vtkInformation` / pipeline executives). This is inherent to
the statically-linked VTK build and is not a leak in your code. A
suppression file is shipped at `inst/valgrind/vtk.supp`; point valgrind
at it (or set `_R_CHECK_VALGRIND_SUPPRESSIONS_` for `R CMD check`’s
valgrind leg) to get a clean report.

## Quick start

``` r
# Install rvtk (from CRAN, or the development version)
install.packages("rvtk")
# pak::pak("astamm/rvtk")

# From the root of your downstream package:
rvtk::use_rvtk()
```

Then use `rvtk::CppFlags()`, `rvtk::LdFlags()`, `rvtk::LdFlagsFile()`,
and `rvtk::VtkVersion()` in your build scripts or `configure` when you
need finer control.

## Installation

``` r
# from CRAN
install.packages("rvtk")

# development version
# install.packages("pak")
pak::pak("astamm/rvtk")
```

A system VTK installation (≥ 9.1.0) is not required: if none is found
the package downloads pre-built libraries automatically.

## Links

- [Function
  reference](https://astamm.github.io/rvtk/reference/index.html)
- [Vignette: linking downstream R packages to
  VTK](https://astamm.github.io/rvtk/articles/rvtk.html)
- [VTK](https://vtk.org/)
