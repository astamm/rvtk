.onLoad <- function(libname, pkgname) {
  if (.Platform$OS.type == "windows") {
    ## When VTK was linked dynamically the DLLs live alongside the package's
    ## own compiled DLL (libs/<arch>/ after R CMD INSTALL).  Prepend that
    ## directory to PATH so Windows DLL search finds them without the user
    ## having to configure PATH manually.
    dll_dir <- system.file(
      "libs",
      .Platform$r_arch,
      package = pkgname,
      lib.loc = libname
    )
    if (nzchar(dll_dir) && file.exists(dll_dir)) {
      vtk_dlls <- list.files(
        dll_dir,
        pattern = "^vtk.*\\.dll$",
        full.names = FALSE
      )
      if (length(vtk_dlls) > 0L) {
        Sys.setenv(PATH = paste(dll_dir, Sys.getenv("PATH"), sep = ";"))
      }
    }
  }
}
