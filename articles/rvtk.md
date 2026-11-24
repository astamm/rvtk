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

Static `.a` libraries are preferred over shared `.dll.a` import
libraries at the same prefix; if only shared libraries are available,
rvtk accepts them and stages the VTK DLLs itself so downstream packages
need no extra configuration.

### Compatibility matrix

The pre-built fallback is available for the following platform ×
strategy combinations; a system VTK installation (≥ 9.1.0) found via
`VTK_DIR`, `pkg-config`, Homebrew, or pacman is always preferred when
present.

| Platform | Pre-built fallback | Notes |
|----|----|----|
| macOS arm64 | static `.a` | Apple Clang / libc++ |
| macOS x86_64 | static `.a` | Apple Clang / libc++ |
| Linux x86_64 (glibc) | static `.a` | GCC / libstdc++ |
| Linux x86_64 (glibc, libc++) | static `.a` | Clang `-stdlib=libc++` (selected by `configure`; see ABI note) |
| Linux x86_64 (musl / Alpine) | static `.a` | headless build: `VTK_USE_X=OFF`, `RenderingOpenGL2=NO` |
| Linux aarch64 | static `.a` |  |
| Windows x64 | static `.a` (default) or shared DLLs (`VTK_LINK_TYPE=shared`) |  |

On Windows the modules `VTK_IONetCDF`, `VTK_IOHDF`, and `VTK_GeovisCore`
are disabled because `netcdf` and `libproj` are not available in the
Rtools45 `static.posix` sysroot; downstream packages requiring them
cannot be built on Windows with rvtk’s pre-built libraries.

### Bundled VTK modules

The pre-built bundles are built with `VTK_BUILD_ALL_MODULES=OFF` and the
following modules explicitly enabled (VTK resolves and includes all
transitive dependencies automatically):

| Module | Purpose |
|----|----|
| `VTK_IOLegacy` | Legacy VTK file format reader/writer (`.vtk`) |
| `VTK_IOXML` | XML-based VTK file formats (`.vtp`, `.vtu`, `.vts`, …) |
| `VTK_IOCore` | Core I/O infrastructure shared by all I/O modules |
| `VTK_IOGeometry` | Readers/writers for common geometric formats (`.ply`, `.stl`, …) |
| `VTK_FiltersCore` | Core algorithmic filters (threshold, transform points, …) |
| `VTK_FiltersGeneral` | General-purpose filters (append, clip, decimate, …) |
| `VTK_FiltersGeometry` | Filters that modify or convert dataset geometry |
| `VTK_FiltersModeling` | Filters for geometric modeling and meshing |
| `VTK_FiltersExtraction` | Filters that extract subsets of data |
| `VTK_CommonCore` | Core data structures, object model, logging |
| `VTK_CommonDataModel` | Datasets, cells, point/cell data arrays |

Each module’s transitive dependencies are resolved automatically by
CMake — for `VTK_FiltersExtraction` that includes `VTK_ParallelDIY`,
`VTK_ParallelCore`, `VTK_FiltersHyperTree`, and `VTK_FiltersStatistics`
— and the resulting bundle ships as 161 static archives on each platform
(every I/O reader, every filter group, rendering, imaging, …; only
`IOJSON`, `IOGDAL`, and `GUISupportQt` are absent).

### Pre-built ABI compatibility

Each pre-built archive is compiled with the platform’s default C++
toolchain, so downstream packages must link with a compatible C++
runtime. VTK headers pull in `<vector>`, `<string>`, etc., and the
statically linked archives embed the C++ standard library symbols they
reference (in particular the third-party objects such as `libvtkscn`
that are always linked), so mixing runtimes at load time fails with an
undefined symbol:

- **Linux x86_64 (glibc).** Two variants are shipped: the default
  archive is compiled with **GCC and libstdc++**; a second archive,
  suffixed `-linux-x86_64-libcxx`, is compiled with Clang
  `-stdlib=libc++` for toolchains that target libc++ (CRAN’s
  `r-devel-linux-x86_64-fedora-clang` flavor compiles packages with
  clang and defaults to libc++). rvtk’s `configure` detects which
  standard library the build compiler targets and downloads the matching
  archive automatically; a manual install can force the choice with
  `CXX` (or `R_MAKEVARS_USER`).
- **macOS.** The archives are compiled with the default Apple Clang
  toolchain, which targets **libc++** (symbols land in the `std::__1`
  namespace). Do not force `-stdlib=libstdc++` when linking them: the
  libstdc++-built objects will not interoperate.
- **Much newer GCC than the build toolchain.** Even a matching
  libstdc++/GCC pairing can fail if the downstream compiler release
  changed the `libstdc++` ABI stub; the failure shows up at load time as
  an undefined `__cxa_call_terminate`. Match the compiler generation, or
  install a system VTK (via Homebrew, apt, …) and rvtk will link that
  instead.
- **Musl/Alpine and Windows.** Built with the platform’s native C++
  toolchain (musl’s GCC libstdc++; Rtools45 MinGW on Windows); link with
  the matching R toolchain for the platform.

Releases after the macOS archives were rebuilt with
`-DCMAKE_OSX_DEPLOYMENT_TARGET=13.0` are compatible with macOS 13 and
newer.

### Valgrind

A minimal downstream program that reads a VTK file reports ~1.5 KB
“definitely lost” under valgrind, allocated inside VTK’s pipeline
internals (`vtkInformation`, pipeline executives — see the rhub valgrind
findings on the **riot** downstream check). This is inherent to the
statically linked VTK build and does not indicate a leak in downstream
code. A suppression file is shipped at `inst/valgrind/vtk.supp`; point
valgrind at it (or set `_R_CHECK_VALGRIND_SUPPRESSIONS_=` for
`R CMD check`’s valgrind leg) to get a clean report.

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
writes can also be written by hand, exactly as documented below (the
README’s “Manual setup” section also walks through it). The files are:

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

vtk_modules <- NULL

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

The pre-built bundles shipped with rvtk contain the full VTK library
(161 static archives on each platform: every I/O reader, every filter
group, rendering, imaging, …). By default
[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)
links **all** of them:

``` r

modules = NULL
```

This is safe because the archives are static libraries and the linker
extracts only the object files your code actually references — linking
everything does not mean your final binary contains every VTK feature.
It also means a downstream package can never fail with a “module missing
from the default list” error (earlier releases curated a fixed 18- or
24-module default, and any package using a module outside it — for
example the `vtkParallelDIY` / `vtkIOCellGrid` dependencies of
`vtkFiltersExtraction`, or `vtkIOPLY` for PLY files — failed at link or
load time with an undefined-symbol error).

Passing a subset of modules is an *optimisation*, not a requirement. It
reduces link time and keeps the compiled package smaller, which is worth
it for packages that use only a small part of VTK:

``` r

rvtk::use_rvtk(
  modules = c(
    "vtkIOLegacy",
    "vtkCommonCore",
    "vtkCommonDataModel"
  )
)
```

When you restrict the list, make sure every module your code uses
(including transitive dependencies such as `vtkParallelDIY` and
`vtkIOCellGrid`) is included. If you set up files manually, set the
`vtk_modules` variable in `tools/configure.R` to `NULL` (all modules) or
your chosen subset.

The `modules` argument is also accepted directly by
[`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md) and
[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
if you need finer control in your own build scripts:

``` r

# flags for just the I/O + core modules
LdFlags(modules = c("vtkIOLegacy", "vtkCommonCore", "vtkCommonDataModel"))
#> -Wl,--start-group /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_cont_testing-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_cont-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_clean_grid-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_connected_components-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_contour-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_core-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_density_estimate-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_entity_extraction-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_field_conversion-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_field_transform-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_flow-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_geometry_refinement-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_image_processing-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_mesh_info-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_multi_block-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_resampling-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_uncertainty-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_vector_analysis-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_filter_zfp-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_io-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_source-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskores_worklet-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libviskoresdiympi_nompi.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkCommonCore-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkCommonDataModel-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkexpat-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkfmt-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkfreetype-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkgl2ps-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkglad-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkIOLegacy-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkjpeg-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkjsoncpp-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkkissfft-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklibharu-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklibxml2-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkloguru-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklz4-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtklzma-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkmetaio-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkogg-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkpng-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkpugixml-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkscn-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtksqlite-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtksys-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtktheora-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtktiff-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtktoken-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkverdict-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkvpic-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkx11-9.7.a /home/runner/work/_temp/Library/rvtk/prebuilt/lib/libvtkzlib-9.7.a -Wl,--end-group
```

### Module availability

Since rvtk 0.3.0,
[`LdFlags()`](https://astamm.github.io/rvtk/reference/LdFlags.md) and
[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
validate the requested modules by default (`check = TRUE`): if a module
is not available in the detected VTK installation, configuration fails
immediately with an actionable error listing the missing modules and the
available set, instead of surfacing much later as a confusing linker
error.

Use
[`available_modules()`](https://astamm.github.io/rvtk/reference/available_modules.md)
to see exactly which modules the installation can link against:

``` r

# modules available in this VTK installation (pre-built archives ship the
# complete set recorded in vtk_modules.txt; system VTK is derived from the
# recorded linker flags)
available_modules()
#>   [1] "vtkAcceleratorsVTKmCore"        "vtkAcceleratorsVTKmDataModel"  
#>   [3] "vtkAcceleratorsVTKmFilters"     "vtkChartsCore"                 
#>   [5] "vtkCommonCache"                 "vtkCommonColor"                
#>   [7] "vtkCommonComputationalGeometry" "vtkCommonCore"                 
#>   [9] "vtkCommonDataModel"             "vtkCommonExecutionModel"       
#>  [11] "vtkCommonMath"                  "vtkCommonMisc"                 
#>  [13] "vtkCommonSystem"                "vtkCommonTransforms"           
#>  [15] "vtkDICOMParser"                 "vtkDomainsChemistry"           
#>  [17] "vtkFiltersAMR"                  "vtkFiltersCellGrid"            
#>  [19] "vtkFiltersCore"                 "vtkFiltersExtraction"          
#>  [21] "vtkFiltersFlowPaths"            "vtkFiltersGeneral"             
#>  [23] "vtkFiltersGeneric"              "vtkFiltersGeometry"            
#>  [25] "vtkFiltersGeometryPreview"      "vtkFiltersHybrid"              
#>  [27] "vtkFiltersHyperTree"            "vtkFiltersImaging"             
#>  [29] "vtkFiltersMeshing"              "vtkFiltersModeling"            
#>  [31] "vtkFiltersParallel"             "vtkFiltersParallelDIY2"        
#>  [33] "vtkFiltersParallelImaging"      "vtkFiltersPoints"              
#>  [35] "vtkFiltersProgrammable"         "vtkFiltersReduction"           
#>  [37] "vtkFiltersSelection"            "vtkFiltersSMP"                 
#>  [39] "vtkFiltersSources"              "vtkFiltersStatistics"          
#>  [41] "vtkFiltersTemporal"             "vtkFiltersTensor"              
#>  [43] "vtkFiltersTexture"              "vtkFiltersTopology"            
#>  [45] "vtkFiltersVerdict"              "vtkImagingColor"               
#>  [47] "vtkImagingCore"                 "vtkImagingFourier"             
#>  [49] "vtkImagingGeneral"              "vtkImagingHybrid"              
#>  [51] "vtkImagingMath"                 "vtkImagingMorphological"       
#>  [53] "vtkImagingSources"              "vtkImagingStatistics"          
#>  [55] "vtkImagingStencil"              "vtkInfovisCore"                
#>  [57] "vtkInfovisLayout"               "vtkInteractionImage"           
#>  [59] "vtkInteractionStyle"            "vtkInteractionWidgets"         
#>  [61] "vtkIOAsynchronous"              "vtkIOAvmesh"                   
#>  [63] "vtkIOCellGrid"                  "vtkIOChemistry"                
#>  [65] "vtkIOCityGML"                   "vtkIOCore"                     
#>  [67] "vtkIOEngys"                     "vtkIOEnSight"                  
#>  [69] "vtkIOExport"                    "vtkIOExportPDF"                
#>  [71] "vtkIOFDS"                       "vtkIOGeoJSON"                  
#>  [73] "vtkIOGeometry"                  "vtkIOImage"                    
#>  [75] "vtkIOImport"                    "vtkIOInfovis"                  
#>  [77] "vtkIOLANLX3D"                   "vtkIOLegacy"                   
#>  [79] "vtkIOLSDyna"                    "vtkIOMotionFX"                 
#>  [81] "vtkIOMovie"                     "vtkIOOggTheora"                
#>  [83] "vtkIOOMF"                       "vtkIOPLY"                      
#>  [85] "vtkIOSegY"                      "vtkIOSQL"                      
#>  [87] "vtkIOTecplotTable"              "vtkIOVideo"                    
#>  [89] "vtkIOVPIC"                      "vtkIOXML"                      
#>  [91] "vtkIOXMLParser"                 "vtkParallelCore"               
#>  [93] "vtkParallelDIY"                 "vtkRenderingAnnotation"        
#>  [95] "vtkRenderingContext2D"          "vtkRenderingCore"              
#>  [97] "vtkRenderingFreeType"           "vtkRenderingGridAxes"          
#>  [99] "vtkRenderingHyperTreeGrid"      "vtkRenderingImage"             
#> [101] "vtkRenderingLabel"              "vtkRenderingLOD"               
#> [103] "vtkRenderingSceneGraph"         "vtkRenderingVolume"            
#> [105] "vtkRenderingVtkJS"              "vtksys"                        
#> [107] "vtkTestingDataModel"            "vtkTestingGenericBridge"       
#> [109] "vtkTestingIOSQL"                "vtkWebGLExporter"              
#> [111] "vtkWrappingTools"
```

With the pre-built archives this is the full module set the bundle was
built with (every VTK module except a deny-list of modules that pull in
unavailable external dependencies). With a system VTK it reflects that
installation, so a request for a module the system VTK does not provide
fails fast. Pass `check = FALSE` only if you intentionally link against
whatever the installation provides.

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
the cause is a symbol being dragged in from a module outside the
*requested* `modules` subset (older rvtk versions curated a fixed
default list, so e.g. `vtkCellGridReader` failed to resolve when
`vtkIOCellGrid` was not listed). With the default `modules = NULL` this
cannot happen. If you restricted the list, widen it back to `NULL` or
add the module that defines the missing symbol, then rebuild.

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
- By default the full bundled VTK is linked; use the `modules` argument
  only to restrict linking when you want shorter link times or smaller
  packages.
- Prefer
  [`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)
  on Windows to avoid the command-line length limit.
- For CRAN, prefer the static pre-built build; for Windows shared
  builds, keep rvtk and the downstream package in lockstep.
