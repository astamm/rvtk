# rvtk 0.1.0

* Initial CRAN submission.
* Bundles VTK 9.5.2 pre-built static libraries (`.a`) for Windows (Rtools45
  UCRT x64), macOS arm64, macOS x86_64, and Linux x86_64, distributed via
  GitHub Releases and built with GitHub Actions.
* VTK discovery strategy on macOS and Linux (in priority order):
  1. User-supplied `VTK_DIR` environment variable.
  2. Homebrew (macOS only).
  3. `pkg-config`.
  4. Well-known system prefixes (`/usr`, `/usr/local`) (Linux only).
  5. Automatic download of pre-built static libraries from
     <https://github.com/astamm/rvtk/releases> as a fallback.
* On Windows, pre-built UCRT64 static libraries are always downloaded
  automatically from <https://github.com/astamm/rvtk/releases>.
* **Windows limitation:** `netcdf` and `libproj` are not available in the
  Rtools45 UCRT64 environment. The following VTK modules are therefore
  disabled in the Windows pre-built libraries: `VTK_IONetCDF`, `VTK_IOHDF`,
  `VTK_GeovisCore`, `VTK_RenderingCore`. Downstream packages requiring these
  modules cannot be built on Windows with **rvtk**'s pre-built libraries.
* Downstream packages can retrieve compiler and linker flags via
  `rvtk::CppFlags()` and `rvtk::LdFlags()`.
