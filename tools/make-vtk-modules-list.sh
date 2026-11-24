#!/usr/bin/env bash
#
# Generate vtk_modules.txt for a release archive from the installed VTK
# libraries.  Lists one VTK module per line: the library stem (sans `lib`
# prefix, extension, and version suffix), restricted to the `vtk<Module>`
# convention modules plus `vtksys` — mirroring rvtk::vtk_conf_modules(), the
# fallback that derives the module list from vtk.conf for system VTK
# installations.  Bundled third-party libraries (libvtkzlib, libvtkexpat,
# viskores_*, ...) are intentionally excluded so the file is consistent with
# the module list reported for a system VTK.
#
# Usage: make-vtk-modules-list.sh <install-lib-dir> <output-path>
#   <install-lib-dir>  directory containing the built libraries (.a, or
#                      .dll.a for the Windows shared build)
#   <output-path>      where to write the sorted module list
set -euo pipefail

lib_dir="$1"
out="$2"

find "${lib_dir}" -maxdepth 1 -type f \
  \( -name '*.a' -o -name '*.dll.a' \) \
  -exec basename {} \; \
| sed -E 's/^lib//; s/\.a$//; s/\.dll$//; s/-[0-9].*$//' \
| grep -E '^(vtk[A-Z]|vtksys)' \
| sort -u > "${out}"

# Sanity: the file must contain at least the common core modules.
for m in vtkCommonCore vtkCommonDataModel vtkIOCore vtkIOXML vtkIOLegacy; do
  if ! grep -qx "${m}" "${out}"; then
    echo "make-vtk-modules-list.sh: missing expected module ${m} in ${out}" >&2
    exit 1
  fi
done
echo "Wrote ${out} with $(wc -l < "${out}" | tr -d ' ') modules"
