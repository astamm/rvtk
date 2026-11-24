# VTK modules available in this installation

Returns the VTK modules that the installation detected at configure time
can link against. With the pre-built archives this is the full module
list shipped (recorded in `inst/vtk_modules.txt`); with a system VTK it
is derived from the static libraries and linker flags recorded in
`vtk.conf`.

## Usage

``` r
available_modules()
```

## Value

A character vector of available VTK module names, e.g.
`c("vtkCommonCore", "vtkIOLegacy", ...)`, sorted.

## Details

This lets downstream packages fail fast at install time when a module
they require is missing from a system VTK installation, with a hint to
compile VTK with that module or fall back to the pre-built archives
(which ship all modules).

## See also

[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md)

## Examples

``` r
mods <- available_modules()
```
