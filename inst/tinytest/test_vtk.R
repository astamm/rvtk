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

cpp <- capture.output(CppFlags())
expect_true(is.character(cpp))
expect_true(nchar(paste(cpp, collapse = "")) > 0L)

# ── LdFlags ──────────────────────────────────────────────────────────────────

ld <- capture.output(LdFlags())
expect_true(is.character(ld))
expect_true(nchar(paste(ld, collapse = "")) > 0L)
