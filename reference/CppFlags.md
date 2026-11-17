# Compiler flags for packages linking against VTK

Returns the C pre-processor flags (`-I` paths) required to compile C++
code that includes VTK headers. Intended to be called from a downstream
package's `configure` or `configure.win` script:

## Usage

``` r
CppFlags()
```

## Value

A single character string of compiler flags, written to stdout (so that
it can be captured by shell command substitution in `configure`) and
returned invisibly.

## Details

    VTK_CPPFLAGS="$("${R_HOME}/bin/Rscript" --vanilla -e "rvtk::CppFlags()")"

For the recommended one-call setup of a downstream package, see
[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md); it
wires this function (and
[`LdFlagsFile()`](https://astamm.github.io/rvtk/reference/LdFlagsFile.md))
into the package's build files automatically.

## See also

[`use_rvtk()`](https://astamm.github.io/rvtk/reference/use_rvtk.md)

## Examples

``` r
flags <- CppFlags()
#> -isystem/home/runner/work/_temp/Library/rvtk/prebuilt/include/vtk-9.7
```
