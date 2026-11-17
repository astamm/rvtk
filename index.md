# rvtk

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

[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
writes `src/Makevars`, `src/Makevars.win`, and `tools/configure.R` so
that the compiler and linker flags are resolved at install time via
[`rvtk::CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md)
and
[`rvtk::LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md).
Everything can also be set up by hand — the two approaches produce
identical files.

Pre-built libraries are provided for macOS (arm64 and x86_64), Linux
(x86_64 glibc, x86_64 musl/Alpine, and aarch64), and Windows (static or
shared DLLs).

**See the [vignette](https://astamm.github.io/rvtk/articles/rvtk.md) for
full details:** how VTK is located on each platform (with the
compatibility matrix), which VTK modules are bundled, manually writing
the build files, restricting linking with the `modules` argument, and
verifying that linking worked.

## Quick start

``` r

# Install rvtk (from CRAN, or the development version)
install.packages("rvtk")
# pak::pak("astamm/rvtk")

# From the root of your downstream package:
rvtk::use_rvtk()
```

Then use
[`rvtk::CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md),
[`rvtk::LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md),
[`rvtk::LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md),
and
[`rvtk::VtkVersion()`](https://astamm.github.io/rvtk/reference/VtkVersion.md)
in your build scripts or `configure` when you need finer control.

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

- [Function reference](https://astamm.github.io/rvtk/reference/index.md)
- [Vignette: linking downstream R packages to
  VTK](https://astamm.github.io/rvtk/articles/rvtk.md)
- [VTK](https://vtk.org/)
