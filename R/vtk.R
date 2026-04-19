#' Compiler flags for packages linking against VTK
#'
#' Returns the C pre-processor flags (`-I` paths) required to compile C++ code
#' that includes VTK headers.  Intended to be called from a downstream
#' package's `src/Makevars` or `src/Makevars.win`:
#'
#' ```makefile
#' PKG_CPPFLAGS = $(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript" -e "rvtk::CppFlags()")
#' ```
#'
#' @return A single character string of compiler flags, printed to stdout (so
#'   that it can be captured by `$(shell ...)` in a `Makefile`).
#' @export
CppFlags <- function() {
  cat(read_vtk_conf()[["VTK_CPPFLAGS"]])
}

#' Linker flags for packages linking against VTK
#'
#' Returns the linker flags (`-L` paths and `-l` library names) required to
#' link C++ code against VTK.  Intended to be called from a downstream
#' package's `src/Makevars` or `src/Makevars.win`:
#'
#' ```makefile
#' PKG_LIBS = $(shell "$(R_HOME)/bin$(R_ARCH_BIN)/Rscript" -e "rvtk::LdFlags()")
#' ```
#'
#' @return A single character string of linker flags, printed to stdout (so
#'   that it can be captured by `$(shell ...)` in a `Makefile`).
#' @export
LdFlags <- function() {
  cat(read_vtk_conf()[["VTK_LIBS"]])
}

#' VTK version used by this package
#'
#' @return A character string with the VTK version, e.g. `"9.3.1"`.
#' @export
VtkVersion <- function() {
  read_vtk_conf()[["VTK_VERSION"]]
}

# Internal helper -------------------------------------------------------

read_vtk_conf <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file("vtk.conf", package = "rvtk", mustWork = TRUE)
  }
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines)) & !startsWith(trimws(lines), "#")]
  parsed <- strsplit(lines, "=", fixed = TRUE)
  vals <- vapply(parsed, function(x) paste(x[-1], collapse = "="), character(1))
  keys <- vapply(parsed, `[[`, character(1), 1)
  stats::setNames(as.list(vals), keys)
}
