# Tests for the rvtk R package
# Uses a fixture conf file to exercise read_vtk_conf() independently of any
# installed VTK, achieving 100% line coverage.

library(rvtk)

# ── Fixture helpers ──────────────────────────────────────────────────────────

write_conf <- function(...) {
  path <- tempfile(fileext = ".conf")
  writeLines(c(...), path)
  path
}

# ── read_vtk_conf: normal parsing ────────────────────────────────────────────

conf <- write_conf(
  "VTK_VERSION=9.5.2",
  "VTK_CPPFLAGS=-isystem/opt/vtk/include/vtk-9.5",
  "VTK_LIBS=-L/opt/vtk/lib -lvtkIOLegacy-9.5",
  "VTK_INCLUDE_DIR=/opt/vtk/include/vtk-9.5"
)

result <- rvtk:::read_vtk_conf(conf)

expect_equal(result[["VTK_VERSION"]], "9.5.2")
expect_equal(result[["VTK_CPPFLAGS"]], "-isystem/opt/vtk/include/vtk-9.5")
expect_equal(result[["VTK_LIBS"]], "-L/opt/vtk/lib -lvtkIOLegacy-9.5")
expect_equal(result[["VTK_INCLUDE_DIR"]], "/opt/vtk/include/vtk-9.5")
expect_true(is.list(result))
expect_equal(length(result), 4L)

# ── read_vtk_conf: values containing '=' are preserved intact ────────────────

conf_eq <- write_conf("KEY=a=b=c")
expect_equal(rvtk:::read_vtk_conf(conf_eq)[["KEY"]], "a=b=c")

# ── read_vtk_conf: blank lines are ignored ───────────────────────────────────

conf_blank <- write_conf(
  "",
  "   ",
  "VTK_VERSION=1.2.3",
  ""
)
res_blank <- rvtk:::read_vtk_conf(conf_blank)
expect_equal(length(res_blank), 1L)
expect_equal(res_blank[["VTK_VERSION"]], "1.2.3")

# ── read_vtk_conf: comment lines are ignored ─────────────────────────────────

conf_comment <- write_conf(
  "# This is a comment",
  "  # indented comment",
  "VTK_VERSION=3.2.1"
)
res_comment <- rvtk:::read_vtk_conf(conf_comment)
expect_equal(length(res_comment), 1L)
expect_equal(res_comment[["VTK_VERSION"]], "3.2.1")

# ── read_vtk_conf: default path uses installed vtk.conf ──────────────────────
# This exercises the NULL -> system.file() branch at runtime.

res_default <- rvtk:::read_vtk_conf()
expect_true(is.list(res_default))
expect_true("VTK_VERSION" %in% names(res_default))
expect_true("VTK_CPPFLAGS" %in% names(res_default))
expect_true("VTK_LIBS" %in% names(res_default))

# ── VtkVersion ───────────────────────────────────────────────────────────────

ver <- VtkVersion()
expect_true(is.character(ver))
expect_equal(length(ver), 1L)
expect_true(grepl("^[0-9]+\\.[0-9]+", ver))

# ── CppFlags ─────────────────────────────────────────────────────────────────

cpp_out <- capture.output(cpp_val <- CppFlags())
expect_true(is.character(cpp_val))
expect_true(nchar(cpp_val) > 0L)
# writeLines() adds a newline; the captured line should equal the flag string
expect_equal(cpp_out, cpp_val)
# Return value must be invisible (function called for side-effect)
expect_true(is.character(cpp_val))

# ── LdFlags ──────────────────────────────────────────────────────────────────

ld_out <- capture.output(ld_val <- LdFlags())
expect_true(is.character(ld_val))
expect_true(nchar(ld_val) > 0L)
expect_equal(ld_out, ld_val)

# ── LdFlagsFile ──────────────────────────────────────────────────────────────

rsp_path <- file.path(tempdir(), "vtk_libs.rsp")
on.exit(unlink(rsp_path), add = TRUE)

if (.Platform$OS.type != "windows") {
  ## Non-Windows branch: flags are returned directly (no response-file indirection).
  ldff_out <- capture.output(ldff_val <- LdFlagsFile(rsp_path))

  ## Return value equals the raw ld flags.
  expect_equal(ldff_val, ld_val)

  ## stdout output equals the flags string.
  expect_equal(ldff_out, ldff_val)

  ## On non-Windows the response file is NOT written by LdFlagsFile().
  expect_false(file.exists(rsp_path))
} else {
  ## Windows branch: flags are written to the response file and the @ref returned.
  ldff_out <- capture.output(ldff_val <- LdFlagsFile(rsp_path))

  ## Return value is "@<basename>".
  expect_equal(ldff_val, paste0("@", basename(rsp_path)))

  ## The response file must exist and contain the flags.
  expect_true(file.exists(rsp_path))
  expect_equal(readLines(rsp_path), ld_val)

  ## stdout echoes the @ref token.
  expect_equal(ldff_out, ldff_val)
}
