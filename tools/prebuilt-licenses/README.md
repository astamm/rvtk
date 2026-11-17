# Prebuilt VTK third-party license notices

Every pre-built VTK archive redistributed by the rvtk project bundles a copy
of this directory under `licenses/` inside the package archive and inside the
installed package (as `inst/prebuilt/licenses/`). The archive build workflow
(`.github/workflows/build-vtk-libs.yml`) copies `tools/prebuilt-licenses/`
unchanged into each generated archive as `licenses/`.

These notices cover the third-party components compiled into (or shipped as
headers inside) the pre-built VTK static libraries. Each notice records the
component's license text verbatim and cites the exact upstream source path in
VTK at the version tagged v9.7.2 (commit
`0558d4d4e4bc86c4b4bf7af2f2488011a4de9e0f`, the dereferenced commit for the
`v9.7.2` annotated tag).

## Component index

| Component | VTK source path | License | Notice file |
|---|---|---|---|
| CGNS | `ThirdParty/cgns/vtkcgns` | zlib/libpng (BSD-like) | `LICENSE-vtkcgns.txt` |
| diy2 | `ThirdParty/diy2/vtkdiy2` | BSD-3 (LBNL) | `LICENSE-vtkdiy2.txt` |
| Eigen | `ThirdParty/eigen/vtkeigen` | MPL-2.0, BSD, LGPL-2.1+ (headers only; no MINPACK shipped) | `LICENSE-vtkeigen.txt` |
| Expat | `ThirdParty/expat/vtkexpat` | MIT | `LICENSE-vtkexpat.txt` |
| ExprTk | `ThirdParty/exprtk/vtkexprtk` | MIT | `LICENSE-vtkexprtk.txt` |
| ExodusII | `ThirdParty/exodusII/vtkexodusII` | BSD-3 (Sandia/NTESS) | `LICENSE-vtkexodusii.txt` |
| fast_float | `ThirdParty/fast_float/vtkfast_float` | MIT (headers only) | `LICENSE-vtkfast_float.txt` |
| fmt | `ThirdParty/fmt/vtkfmt` | MIT (+ optional exception) | `LICENSE-vtkfmt.txt` |
| FreeType | `ThirdParty/freetype/vtkfreetype` | FTL / GPLv2 dual | `LICENSE-vtkfreetype.txt` |
| gl2ps | `ThirdParty/gl2ps/vtkgl2ps` | GL2PS / LGPL-2.1 | `LICENSE-vtkgl2ps.txt` |
| glad | `ThirdParty/glad/vtkglad` | MIT + Khronos | `LICENSE-vtkglad.txt` |
| HDF5 | `ThirdParty/hdf5/vtkhdf5` | BSD-style (HDF Group/NCSA) + LBNL | `LICENSE-vtkhdf5.txt` |
| IOSS | `ThirdParty/ioss/vtkioss` | BSD-3 (Sandia/NTESS) | `LICENSE-vtkioss.txt` |
| JsonCpp | `ThirdParty/jsoncpp/vtkjsoncpp` | Public domain / MIT dual | `LICENSE-vtkjsoncpp.txt` |
| KissFFT | `ThirdParty/kissfft/vtkkissfft` | BSD-3 | `LICENSE-vtkkissfft.txt` |
| libharu | `ThirdParty/libharu/vtklibharu` | zlib-style | `LICENSE-vtklibharu.txt` |
| libjpeg-turbo | `ThirdParty/jpeg/vtkjpeg` | IJG / BSD-3 / zlib | `LICENSE-libjpeg-turbo.txt` (pre-existing) |
| libproj | `ThirdParty/libproj/vtklibproj` | MIT | `LICENSE-vtklibproj.txt` |
| libtiff | `ThirdParty/tiff/vtktiff` | BSD-style (Sam Leffler/SGI) | `LICENSE-libtiff.txt` (pre-existing) |
| libxml2 | `ThirdParty/libxml2/vtklibxml2` | MIT | `LICENSE-vtklibxml2.txt` |
| Loguru | `ThirdParty/loguru/vtkloguru` | public domain / Unlicense-style | `LICENSE-vtkloguru.txt` |
| LZ4 | `ThirdParty/lz4/vtklz4` | BSD-2 | `LICENSE-vtklz4.txt` |
| liblzma / XZ | `ThirdParty/lzma/vtklzma` | 0BSD (public domain; only liblzma shipped) | `LICENSE-vtklzma.txt` |
| MetaIO | `Utilities/MetaIO/vtkmetaio` | BSD-3 (Insight Software Consortium) | `LICENSE-vtkmetaio.txt` |
| netCDF | `ThirdParty/netcdf/vtknetcdf` | BSD-3 (UCAR/Unidata) | `LICENSE-vtknetcdf.txt` |
| nlohmann/json | `ThirdParty/nlohmannjson/vtknlohmannjson` | MIT (headers only) | `LICENSE-vtknlohmannjson.txt` |
| Ogg | `ThirdParty/ogg/vtkogg` | BSD-3 (Xiph.org) | `LICENSE-vtkogg.txt` |
| libpng | `ThirdParty/png/vtkpng` | PNG Reference Library license | `LICENSE-vtkpng.txt` |
| pugixml | `ThirdParty/pugixml/vtkpugixml` | MIT | `LICENSE-vtkpugixml.txt` |
| scn | `ThirdParty/scn/vtkscn` | Apache-2.0 + Boost-1.0 (nanorange) | `LICENSE-vtkscn.txt` |
| SQLite | `ThirdParty/sqlite` | public domain (blessing) | `LICENSE-vtksqlite.txt` |
| tao::pegtl | `ThirdParty/pegtl/vtkpegtl` | MIT (symbols in shipped libs; headers not installed) | `LICENSE-vtkpegtl.txt` |
| Theora | `ThirdParty/theora/vtktheora` | BSD-3 (Xiph.org) + VP3 patent non-assertion | `LICENSE-vtktheora.txt` |
| vtkToken | `ThirdParty/token/vtktoken` | BSD-3 (Kitware) | `LICENSE-vtktoken.txt` |
| utf8 | `ThirdParty/utf8/vtkutf8` | BSL-1.0 (headers only) | `LICENSE-vtkutf8.txt` |
| Verdict | `ThirdParty/verdict/vtkverdict` | BSD-3 (Sandia/NTESS) | `LICENSE-vtkverdict.txt` (pre-existing) |
| zlib | `ThirdParty/zlib/vtkzlib` | zlib | `LICENSE-vtkzlib.txt` |

## Kitware-originated modules (no separate notice required)

The following modules are original VTK/Kitware code (not third-party), so they
carry VTK's own BSD-3-Clause license and are not given separate notices here:

- **KWSys** (`Utilities/KWSys/vtksys`, built as `libvtksys`) — Kitware
  System Library; Copyright 2000-2016 Kitware, Inc. (`Copyright.txt`).
- **vtkDICOMParser** (`Utilities/DICOMParser`, built as `libvtkDICOMParser`)
  — DICOM parser; Copyright (c) 2003 Matt Turek (`Copyright.txt`).
- **MetaIO** is sometimes treated as VTK-originated too (it lives under
  `Utilities/`), but it is copyrighted by the Insight Software Consortium and
  is therefore given its own notice above.
- **vtkx11** (`Utilities/X11`, built as `libvtkx11`) — a thin VTK module that
  only wraps the system X11 library; it ships only `vtkX11Functions.h` and no
  third-party source, so it needs no separate notice.

The kwiml headers (`vtkkwiml/abi.h`, `vtkkwiml/int.h`) are also Kitware's own
utility code (`Utilities/KWIML`).

## Bundling check for the R build

The `build-vtk-libs.yml` workflow copies this whole directory into each
release archive; `configure` extracts the archive into `inst/prebuilt/`,
preserving the `licenses/` subdirectory in the installed package. The
components listed above were verified present in the shipped archives:
161 static libraries and ~3250 headers per archive, with the third-party
libraries carrying the `libvtk` prefix. Headers absent from the archive for
pegtl (compiled-in symbols only) and the header-only components are noted in
their individual notices. No code from the excluded ThirdParty components
(cli11, fides, h5hut, mpi4py, viskores, vpic, vtkm, xdmf2, xdmf3) is present
in the archives.
