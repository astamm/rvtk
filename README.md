
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rvtk

<!-- badges: start -->

[![R-CMD-check](https://github.com/astamm/rvtk/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/astamm/rvtk/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/astamm/rvtk/graph/badge.svg)](https://app.codecov.io/gh/astamm/rvtk)
<!-- badges: end -->

**rvtk** is an infrastructure package that makes the [Visualization
Toolkit (VTK)](https://vtk.org/) available to other R packages that need
to link against it. It provides three utility functions — `CppFlags()`,
`LdFlags()`, and `VtkVersion()` — that return the correct compiler and
linker flags for however VTK was found or installed on the current
machine.

## How VTK is located

On macOS and Linux the package runs a `configure` script at install time
that tries each of the following strategies in order, stopping as soon
as one succeeds:

1.  The environment variable `VTK_DIR` (path to a VTK build or install
    tree).
2.  [Homebrew](https://brew.sh/) (`brew --prefix vtk`).
3.  `pkg-config` (`vtk-9.5`, `vtk-9.4`, …, `vtk-9.1`).
4.  Common system prefixes (`/usr/local`, `/usr`, `/opt/local`).
5.  Download pre-built static libraries from
    <https://github.com/astamm/rvtk/releases>.

On Windows, pre-built UCRT64 static libraries are always downloaded
automatically from the same URL.

> **Windows limitation:** The Rtools45 UCRT64 environment does not
> provide `netcdf` or `libproj`. Consequently, the following VTK modules
> are **disabled** in the Windows pre-built libraries: `VTK_IONetCDF`,
> `VTK_IOHDF`, `VTK_GeovisCore`, `VTK_RenderingCore`. Downstream
> packages that require any of these modules cannot currently be built
> on Windows with the pre-built libraries supplied by **rvtk**.

Configuration results are stored in `inst/vtk.conf` and read at run time
by `CppFlags()`, `LdFlags()`, and `VtkVersion()`.

## Installation

``` r
# install.packages("pak")
pak::pak("astamm/rvtk")
```

A system VTK installation (≥ 9.1.0) is not required: if none is found
the package downloads pre-built static libraries automatically.

## Usage for downstream package developers

Add **rvtk** to the `Imports` field of your `DESCRIPTION`:

    Imports: rvtk

Then call `rvtk::CppFlags()` and `rvtk::LdFlags()` from your
`src/Makevars` (macOS / Linux):

``` makefile
PKG_CPPFLAGS = $(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript" -e "rvtk::CppFlags()")
PKG_LIBS     = $(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript" -e "rvtk::LdFlags()")
```

And from `src/Makevars.win` (Windows):

``` makefile
PKG_CPPFLAGS = $(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript.exe" -e "rvtk::CppFlags()")
PKG_LIBS     = $(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript.exe" -e "rvtk::LdFlags()")
```

You can verify the detected installation at any time:

``` r
library(rvtk)
CppFlags()
#> -isystem/opt/homebrew/opt/vtk/include/vtk-9.5
LdFlags()
#> -L/opt/homebrew/opt/vtk/lib -lvtkIOLegacy-9.5 -lvtkIOXML-9.5 -lvtkIOCore-9.5 -lvtkCommonCore-9.5 -lvtkCommonDataModel-9.5 -lvtksys-9.5
VtkVersion()
#> [1] "9.5.0"
```
