# Linking downstream R packages to VTK

``` r

library(rvtk)
```

## What rvtk does

rvtk is an *infrastructure* package: it does not itself build VTK meshes
or render scenes. Instead, it makes the [Visualization Toolkit
(VTK)](https://vtk.org/) available to **other R packages** that need to
link against it from C++. If you are writing an R package with native
code that `#include`s VTK headers and calls VTK classes, rvtk gives you
four things:

1.  **A universally installed VTK.** Headers and libraries are found in
    a system VTK installation when one exists, and are otherwise
    downloaded at install time as pre-built static libraries — so your
    users do not need to install VTK themselves.
2.  **Compiler flags** —
    [`rvtk::CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md)
    returns the `-I` (include) paths.
3.  **Linker flags** —
    [`rvtk::LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md)
    (and its response-file variant
    [`rvtk::LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md))
    returns the `-L`/`-l` arguments.
4.  **Automated setup** —
    [`rvtk::use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
    writes all the build-time glue files for you.

This vignette explains how VTK is located on each platform, what files a
downstream package needs, how the two setup strategies
([`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
versus hand-written files) relate, and how to verify that linking
actually worked.

## How rvtk finds VTK

rvtk’s own `configure` script runs at *install time* and writes the
result to `inst/vtk.conf`. The strategies differ by platform.

### macOS and Linux

1.  The environment variable `VTK_DIR` (path to a VTK build/install
    tree).
2.  [Homebrew](https://brew.sh/) (`brew --prefix vtk`) — macOS only.
3.  `pkg-config` (`vtk-9.7`, `vtk-9.6`, `vtk-9.5`, …, `vtk-9.1`).
4.  Well-known system prefixes (`/usr`, `/usr/local`) — Linux only.
5.  Download pre-built static libraries from
    <https://github.com/astamm/rvtk/releases> as a fallback.

### Windows

`configure.win` tries, in order:

1.  The environment variable `VTK_DIR`.
2.  Rtools45 `pacman` (queries installed packages; never installs
    automatically).
3.  Common Rtools45 / MSYS2 prefixes
    (`/x86_64-w64-mingw32.static.posix`, `/ucrt64`, `/mingw64`, …).
4.  Download pre-built libraries (static `.a` by default, or shared DLLs
    when `VTK_LINK_TYPE=shared` is set before installation).

Once rvtk is installed,
[`CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md),
[`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md),
[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md),
and
[`VtkVersion()`](https://astamm.github.io/rvtk/reference/VtkVersion.md)
read `vtk.conf` and report whatever VTK was found:

``` r

VtkVersion()
#> [1] "9.7.2"
CppFlags()
#> -isystem/home/runner/work/_temp/Library/rvtk/prebuilt/include/vtk-9.7
```

The exact flags depend on the detected VTK strategy: system shared
libraries on macOS/Linux, `.a` archives in the pre-built tree, `.dll.a`
import libraries + DLLs on Windows, etc. Your downstream package never
has to figure this out itself — it simply calls back into rvtk.

## The two setup strategies

There are two equivalent ways to configure a downstream package. They
produce **byte-identical files** (this equivalence is asserted in rvtk’s
own CI on every platform and VTK strategy).

### Strategy A — `use_rvtk()`

The recommended one-call approach, in the spirit of `usethis`:

``` r

# from the root of your package (e.g. yourpackage/)
rvtk::use_rvtk()
```

This does the following, in order:

1.  Adds `rvtk` to the `Imports` field of `DESCRIPTION`.
2.  Writes `src/Makevars` (macOS/Linux build rules).
3.  Writes `src/Makevars.win` (Windows build rules).
4.  Writes `tools/configure.R`, a small R helper that resolves the flags
    at install time.
5.  Adds `src/vtk_libs.rsp` to `.gitignore` (the response file is
    generated at install time and must not be committed).
6.  Creates `R/rvtk_imports.R` with a minimal `@importFrom rvtk` roxygen
    tag so that `R CMD check` does not warn about an unused `Imports`
    entry.

If some of these files already exist,
[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md) asks
before overwriting in an interactive session and skips them silently
otherwise.

### Strategy B — manual setup

Everything
[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
writes can also be written by hand, exactly as documented in the README
“Manual setup” section. The files are:

**`DESCRIPTION`** — declare the dependency:

    Imports: rvtk

**`src/Makevars`**:

``` makefile
PKG_CPPFLAGS = `"$(R_HOME)/bin/Rscript" ../tools/configure.R --cppflags`
PKG_LIBS = `"$(R_HOME)/bin/Rscript" ../tools/configure.R --libs`
```

**`src/Makevars.win`**:

``` makefile
PKG_CPPFLAGS = $(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript" ../tools/configure.R --cppflags)
PKG_LIBS = $(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript" ../tools/configure.R --libs)
```

**`tools/configure.R`**:

``` r

args <- commandArgs(trailingOnly = TRUE)
flag <- if (length(args)) args[1L] else "--cppflags"

vtk_modules <- c(
  "vtkIOLegacy",
  "vtkIOXML",
  "vtkIOXMLParser",
  "vtkIOCore",
  "vtkIOGeometry",
  "vtkFiltersCore",
  "vtkFiltersGeneral",
  "vtkFiltersGeometry",
  "vtkFiltersModeling",
  "vtkFiltersExtraction",
  "vtkCommonCore",
  "vtkCommonDataModel",
  "vtkCommonExecutionModel",
  "vtkCommonMath",
  "vtkCommonMisc",
  "vtkCommonSystem",
  "vtkCommonTransforms",
  "vtksys"
)

if (flag == "--cppflags") {
  rvtk::CppFlags()
} else if (flag == "--libs") {
  rvtk::LdFlagsFile(path = "vtk_libs.rsp", modules = vtk_modules)
}
```

**`.gitignore`** — add `src/vtk_libs.rsp`.

**`R/rvtk_imports.R`** — import at least one rvtk function so that
`R CMD check` sees the `Imports` entry as used:

``` r

#' @importFrom rvtk CppFlags LdFlagsFile
NULL
```

### How the build-time resolution works

There is no shell `configure` script in the downstream package. Instead,
the `Makevars` files shell out to `Rscript` at compile time:

``` sh
"$(R_HOME)/bin/Rscript" ../tools/configure.R --cppflags
```

`tools/configure.R` is the only file that knows about rvtk’s functions;
it prints the flags to standard output, and Make captures them into
`PKG_CPPFLAGS` / `PKG_LIBS`. This redirection through `Rscript` is
exactly how the flags stay correct no matter where VTK was found — the R
session doing the compilation has the same library paths as the rvtk
installation being linked against.

On Windows the Make syntax is different
(`$(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript" …)`) because GNU make on
Windows needs the `$(shell …)` form and the `R_ARCH_BIN` subdirectory.

The `--libs` path calls
[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md),
not [`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md),
because the full set of VTK `-l` flags can exceed the 8 191-character
Windows command-line limit. On Windows the flags are written to
`src/vtk_libs.rsp` and `PKG_LIBS` receives the short token
`@vtk_libs.rsp`. On macOS and Linux the raw flags are returned directly.

## Choosing the VTK modules to link against

The pre-built bundles shipped with rvtk contain far more than the
modules you are likely to use (I/O, filtering, and core modules plus
their transitive dependencies). By default
[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
links the following set:

``` r

c(
  "vtkIOLegacy",
  "vtkIOXML",
  "vtkIOXMLParser",
  "vtkIOCore",
  "vtkIOGeometry",
  "vtkFiltersCore",
  "vtkFiltersGeneral",
  "vtkFiltersGeometry",
  "vtkFiltersModeling",
  "vtkFiltersExtraction",
  "vtkCommonCore",
  "vtkCommonDataModel",
  "vtkCommonExecutionModel",
  "vtkCommonMath",
  "vtkCommonMisc",
  "vtkCommonSystem",
  "vtkCommonTransforms",
  "vtksys"
)
#>  [1] "vtkIOLegacy"             "vtkIOXML"               
#>  [3] "vtkIOXMLParser"          "vtkIOCore"              
#>  [5] "vtkIOGeometry"           "vtkFiltersCore"         
#>  [7] "vtkFiltersGeneral"       "vtkFiltersGeometry"     
#>  [9] "vtkFiltersModeling"      "vtkFiltersExtraction"   
#> [11] "vtkCommonCore"           "vtkCommonDataModel"     
#> [13] "vtkCommonExecutionModel" "vtkCommonMath"          
#> [15] "vtkCommonMisc"           "vtkCommonSystem"        
#> [17] "vtkCommonTransforms"     "vtksys"
```

Restricting linking to only the modules you need is strongly recommended
when you use the **pre-built static bundle on macOS**. The bundle is
built as a collection of static archives, and the linker (with R’s
default `-undefined dynamic_lookup`) resolves symbols lazily at load
time rather than at build time. If a kept library contains an object
file that references a symbol from a module that is *not* in your
requested set, that object can be dragged in and the missing symbol
shows up only when the package is loaded:

    symbol not found in flat namespace '__ZN17vtkCellGridReader3NewEv'

For example, the pre-built libraries contain modules (such as I/O
readers) that are not part of the default module list; linking too
broadly can pull in an object referencing one of them. Because the
pre-built libraries are static archives on macOS/Linux, the fixed module
list in `tools/configure.R` is what prevents this. Pass only the modules
your code actually uses:

``` r

rvtk::use_rvtk(
  modules = c(
    "vtkIOLegacy",
    "vtkCommonCore",
    "vtkCommonDataModel"
  )
)
```

This also keeps link time down and reduces the size of your compiled
code. With a system shared VTK installation, the loader resolves symbols
at run time and the full `modules = NULL` set is fine.

If you set up files manually, edit the `vtk_modules` vector in
`tools/configure.R` the same way.

The `modules` argument is also accepted directly by
[`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md) and
[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
if you need finer control in your own build scripts:

``` r

# flags for just the I/O + core modules
LdFlags(modules = c("vtkIOLegacy", "vtkCommonCore", "vtkCommonDataModel"))
#> -Wl,--start-group /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkcgns-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkCommonCore-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkCommonDataModel-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkexodusII-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkexpat-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkfmt-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkfreetype-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkgl2ps-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkglad-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkhdf5_hl-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkhdf5-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkIOLegacy-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkioss-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkjpeg-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkjsoncpp-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkkissfft-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklibharu-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklibproj-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklibxml2-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkloguru-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklz4-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklzma-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkmetaio-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtknetcdf-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkogg-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkpng-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkpugixml-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkscn-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtksqlite-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtksys-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtktheora-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtktiff-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtktoken-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkverdict-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkx11-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkzlib-9.7.a -Wl,--end-group
```

## Writing the C++ that uses VTK

A minimal `src/code.cpp` that exercises the link looks like this:

``` cpp
// src/code.cpp
#include <cpp11.hpp>
#include <vtkNew.h>
#include <vtkPolyData.h>

[[cpp11::register]]
int vtk_poly_data_npoints() {
  vtkNew<vtkPolyData> pd;
  return static_cast<int>(pd->GetNumberOfPoints());
}
```

Include the headers exactly as the VTK include directory is laid out in
the detected installation (e.g. `vtk-9.7`). `-isystem` (from
[`CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md) on
macOS/Linux) makes these includes searchable without turning their
content into warnings.

If you use `cpp11` (as in rvtk’s own downstream CI), run
[`cpp11::cpp_register()`](https://cpp11.r-lib.org/reference/cpp_register.html)
after adding your functions. **Note:** `cpp_register()` copies only the
function name, return type, and arguments into `R/cpp11.R` — roxygen
tags such as `#' @export` must live in a separate R file for the wrapper
function you export, or the function will not appear in `NAMESPACE`.

## Shared VTK on Windows

If rvtk is installed with `VTK_LINK_TYPE=shared` (or a system
installation provides only shared libraries), downstream packages link
against `.dll.a` import libraries and load the VTK DLLs at run time from
rvtk’s `inst/vtk-dlls/` (prepended to `PATH` by rvtk’s `.onLoad` hook).
Two consequences for package authors:

1.  **Version sync matters.** Your package is compiled against the
    specific VTK version shipped with the rvtk installed at compile
    time. If rvtk is updated to a new VTK version, your package must be
    **recompiled** against the new rvtk to match the new DLL names
    (e.g. `vtkCommonCore-9.8.dll`).
2.  **DLL footprint lives in rvtk only.** Downstream packages do not
    receive a copy of the DLLs; they rely on rvtk’s staged directory at
    run time.

For CRAN submissions the **static pre-built build is recommended**: it
is self-contained inside your package binary and has no run-time
coupling to rvtk’s DLLs.

## Verifying that linking worked

Before submitting your package, run a full `R CMD check`; then load the
installed package in a fresh session and call the C++ entry point:

``` r

# in a fresh R session, after R CMD INSTALL
library(yourpackage)
yourpackage::vtk_poly_data_npoints() # expect 0: a brand-new vtkPolyData has no points
```

If the package builds but fails to load with an undefined-symbol error,
the usual cause is a module being referenced by the code but missing
from the `modules` vector, or a symbol being dragged in from a module
outside the requested set (e.g. `vtkCellGridReader` when `vtkIOCellGrid`
is not listed). Narrow the module list to exactly what the code uses and
rebuild.

## Summary

- rvtk locates VTK at install time and exposes the resulting flags
  through
  [`CppFlags()`](https://astamm.github.io/rvtk/reference/CppFlags.md),
  [`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md),
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md),
  and
  [`VtkVersion()`](https://astamm.github.io/rvtk/reference/VtkVersion.md).
- [`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
  writes every build-time file for a downstream package; the same files
  can be written manually, byte-for-byte identically.
- Use the `modules` argument to link only what you need — especially
  with the macOS static bundle.
- Prefer
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
  on Windows to avoid the command-line length limit.
- For CRAN, prefer the static pre-built build; for Windows shared
  builds, keep rvtk and the downstream package in lockstep.
