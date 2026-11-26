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

## Which VTK modules are available

The pre-built archives bundle **all VTK modules that can be built
without external dependencies** (160 static libraries, including the
Viskores acceleration modules). Downstream packages can opt in to link
against only the modules they need — pass the `modules` argument to
[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md) or
[`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md)/[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
to reduce link time and storage footprint:

``` r

# link only what your C++ code uses
rvtk::use_rvtk(modules = c("CommonCore", "CommonDataModel", "IOLegacy"))
```

With a system VTK installation, rvtk records which modules are available
on that machine and **hard-fails at install time** if a downstream
package requests a module that is not present — instead of failing later
with a confusing linker error.
[`rvtk::available_modules()`](https://astamm.github.io/rvtk/reference/available_modules.md)
lists the modules of the VTK that rvtk resolved to.

**See the [vignette](https://astamm.github.io/rvtk/articles/rvtk.html)
for full details:** how VTK is located on each platform (with the
compatibility matrix), which VTK modules are bundled, manually writing
the build files, and restricting linking with the `modules` argument.

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

- [Function
  reference](https://astamm.github.io/rvtk/reference/index.html)
- [Vignette: linking downstream R packages to
  VTK](https://astamm.github.io/rvtk/articles/rvtk.html)
- [Vignette: integration testing with downstream
  packages](https://astamm.github.io/rvtk/articles/rvtk-integration.html)
- [VTK](https://vtk.org/)
