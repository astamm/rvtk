# Tests for the use_rvtk() helper and its internals.
# The helper is pure base R with optional `cli` messaging. Because the
# cli-vs-base branches are decided by the real availability of `cli`, we mock
# the internal rvtk_has_cli() wrapper (see R/use_rvtk.R) to exercise the base-R
# branches too. testthat's with_mocked_bindings() is used where available; the
# realistic cli branches are covered whenever `cli` is installed.

library(rvtk)

can_mock <- requireNamespace("testthat", quietly = TRUE)

# ── Fixture helpers ──────────────────────────────────────────────────────────

## Minimal valid DESCRIPTION used as a base fixture by most tests.
base_desc <- c(
  "Package: fakepkg",
  "Title: A Fake Package",
  "Version: 0.0.1",
  "License: MIT + file LICENSE"
)

## Write the given DESCRIPTION lines into a temp package root and return root.
write_pkg <- function(desc = base_desc) {
  root <- tempfile("rvtk_pkg_")
  dir.create(root, recursive = TRUE)
  writeLines(desc, file.path(root, "DESCRIPTION"))
  root
}

# ── rvtk_rel_path ────────────────────────────────────────────────────────────
# The helper strips root/ from path when path lives under root, and returns
# path unchanged otherwise. It compares against normalizePath(root) (and uses
# .Platform$file.sep), so we build inputs from normalized temp paths to stay
# platform-robust (Windows drives/separators, macOS /var -> /private/var, etc.).

rel_root <- tempfile("rvtk_rel_root_")
dir.create(rel_root, recursive = TRUE)
rel_root <- normalizePath(rel_root)

## A path under root is made relative to root.
rel_inside <- rvtk:::rvtk_rel_path(
  file.path(rel_root, "src", "Makevars"),
  rel_root
)
expect_identical(rel_inside, file.path("src", "Makevars"))

## A path not under root is returned unchanged.
rel_outside_path <- file.path(normalizePath(tempdir()), "file.txt")
expect_identical(
  rvtk:::rvtk_rel_path(rel_outside_path, rel_root),
  rel_outside_path
)

## A path equal to root+sep (empty remainder) is handled without error.
expect_identical(
  rvtk:::rvtk_rel_path(paste0(rel_root, .Platform$file.sep), rel_root),
  ""
)

# ── rvtk_has_cli returns a logical (cli installed on the repr environment) ──

expect_true(is.logical(rvtk:::rvtk_has_cli()))

# ── rvtk_use_package: no DESCRIPTION -> error ────────────────────────────────

empty_root <- tempfile("rvtk_nopkg_")
dir.create(empty_root)
expect_error(rvtk:::rvtk_use_package(empty_root))

if (can_mock) {
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    .package = "rvtk",
    expect_error(rvtk:::rvtk_use_package(empty_root))
  )
}

# ── rvtk_use_package: no Imports, Description, no License -> insert at end ──

pkg_1 <- write_pkg(c(
  "Package: fakepkg",
  "Title: A Fake Package",
  "Description: Some text that is long",
  "    enough to be a description."
))
rvtk:::rvtk_use_package(pkg_1)
lines_1 <- readLines(file.path(pkg_1, "DESCRIPTION"))
expect_true(any(grepl("^Imports: rvtk$", lines_1)))
expect_equal(lines_1[length(lines_1)], "Imports: rvtk")

# ── rvtk_use_package: no Imports, Description + License -> insert after Desc ─

pkg_2 <- write_pkg(base_desc)
rvtk:::rvtk_use_package(pkg_2)
lines_2 <- readLines(file.path(pkg_2, "DESCRIPTION"))
lic_pos <- grep("^License:", lines_2)
expect_true(any(grepl("^Imports: rvtk$", lines_2)))
# Imports must be adjacent above License
expect_equal(lines_2[lic_pos - 1L], "Imports: rvtk")

# ── rvtk_use_package: no Imports, no Description, has License -> before License

pkg_3 <- write_pkg(c(
  "Package: fakepkg",
  "Title: A Fake Package",
  "Version: 0.0.1",
  "License: MIT + file LICENSE"
))
rvtk:::rvtk_use_package(pkg_3)
lines_3 <- readLines(file.path(pkg_3, "DESCRIPTION"))
expect_true(any(grepl("^Imports: rvtk$", lines_3)))
lic_pos3 <- grep("^License:", lines_3)
expect_equal(lines_3[lic_pos3 - 1L], "Imports: rvtk")

# ── rvtk_use_package: Imports exists, rvtk absent -> append ─────────────────

pkg_4 <- write_pkg(c(
  "Package: fakepkg",
  "Title: A Fake Package",
  "Version: 0.0.1",
  "License: MIT + file LICENSE",
  "Imports:",
  "    utils"
))
rvtk:::rvtk_use_package(pkg_4)
lines_4 <- readLines(file.path(pkg_4, "DESCRIPTION"))
expect_true(any(grepl("^    rvtk$", lines_4)))
expect_true(any(grepl("^    utils,$", lines_4)))

# ── rvtk_use_package: Imports exists, rvtk present -> skip (no change) ──────

pkg_5 <- write_pkg(c(
  "Package: fakepkg",
  "Title: A Fake Package",
  "Version: 0.0.1",
  "License: MIT + file LICENSE",
  "Imports: rvtk"
))
before_5 <- readLines(file.path(pkg_5, "DESCRIPTION"))
rvtk:::rvtk_use_package(pkg_5)
after_5 <- readLines(file.path(pkg_5, "DESCRIPTION"))
expect_identical(after_5, before_5)

# ── rvtk_write_file: parent dir created, file written ───────────────────────

root_w <- tempfile("rvtk_w_")
dir.create(root_w)
wpath <- file.path(root_w, "nested", "new.txt")
rvtk:::rvtk_write_file(wpath, "hello", root = root_w)
expect_true(file.exists(wpath))
expect_equal(readLines(wpath), "hello")

# ── rvtk_write_file: existing file, non-interactive -> skip (not overwritten)

existing <- file.path(root_w, "keep.txt")
writeLines("original", existing)
if (can_mock) {
  testthat::with_mocked_bindings(
    rvtk_interactive = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_write_file(existing, "new-content", root = root_w)
  )
} else {
  rvtk:::rvtk_write_file(existing, "new-content", root = root_w)
}
expect_equal(readLines(existing), "original")

# ── rvtk_write_file: existing file, interactive, answer "n" -> skip ─────────

if (can_mock) {
  testthat::with_mocked_bindings(
    rvtk_interactive = function() TRUE,
    rvtk_readline = function(prompt) "n",
    .package = "rvtk",
    rvtk:::rvtk_write_file(existing, "new-content", root = root_w)
  )
  expect_equal(readLines(existing), "original")
}

# ── rvtk_write_file: existing file, interactive, answer "y" -> overwrite ────

overwrite_t <- tempfile("rvtk_ow_")
dir.create(overwrite_t)
owpath <- file.path(overwrite_t, "ow.txt")
writeLines("old", owpath)
if (can_mock) {
  testthat::with_mocked_bindings(
    rvtk_interactive = function() TRUE,
    rvtk_readline = function(prompt) "yes",
    .package = "rvtk",
    rvtk:::rvtk_write_file(owpath, "new", root = overwrite_t)
  )
  expect_equal(readLines(owpath), "new")
}

# ── rvtk_use_git_ignore: no .gitignore -> created ───────────────────────────

root_g1 <- tempfile("rvtk_g1_")
dir.create(root_g1)
rvtk:::rvtk_use_git_ignore("src/vtk_libs.rsp", root = root_g1)
gi_1 <- readLines(file.path(root_g1, ".gitignore"))
expect_equal(gi_1, "src/vtk_libs.rsp")

# ── rvtk_use_git_ignore: pattern present -> skip (no duplicate) ─────────────

root_g2 <- tempfile("rvtk_g2_")
dir.create(root_g2)
writeLines("src/vtk_libs.rsp", file.path(root_g2, ".gitignore"))
rvtk:::rvtk_use_git_ignore("src/vtk_libs.rsp", root = root_g2)
expect_equal(readLines(file.path(root_g2, ".gitignore")), "src/vtk_libs.rsp")

# ── rvtk_use_git_ignore: pattern absent -> appended ─────────────────────────

root_g3 <- tempfile("rvtk_g3_")
dir.create(root_g3)
writeLines("*.o", file.path(root_g3, ".gitignore"))
rvtk:::rvtk_use_git_ignore("src/vtk_libs.rsp", root = root_g3)
expect_equal(
  readLines(file.path(root_g3, ".gitignore")),
  c("*.o", "src/vtk_libs.rsp")
)

# ── use_rvtk(): end-to-end on a fresh package ────────────────────────────────

pkg_e2e <- write_pkg(base_desc)

## Suppress the success message during the test.
e2e_out <- capture.output(
  use_rvtk(path = pkg_e2e),
  type = "message"
)

expect_true(file.exists(file.path(pkg_e2e, "DESCRIPTION")))
expect_true(any(grepl(
  "^.*rvtk.*$",
  readLines(file.path(pkg_e2e, "DESCRIPTION"))
)))
expect_true(file.exists(file.path(pkg_e2e, "src", "Makevars")))
expect_true(file.exists(file.path(pkg_e2e, "src", "Makevars.win")))
expect_true(file.exists(file.path(pkg_e2e, "tools", "configure.R")))
expect_true(file.exists(file.path(pkg_e2e, "R", "rvtk_imports.R")))
expect_true(any(grepl(
  "src/vtk_libs\\.rsp",
  readLines(file.path(pkg_e2e, ".gitignore"))
)))

## The returned value is the normalised package root (a character of length 1).
res_e2e <- capture.output(ret <- use_rvtk(path = pkg_e2e), type = "message")
expect_true(is.character(ret))
expect_equal(length(ret), 1L)

## configure.R embeds the requested VTK modules.
conf_script <- readLines(file.path(pkg_e2e, "tools", "configure.R"))
expect_true(any(grepl('vtkIOLegacy', conf_script)))
expect_true(any(grepl('vtkIOGeometry', conf_script)))
expect_true(any(grepl('vtkFiltersCore', conf_script)))
expect_true(any(grepl('vtkCommonCore', conf_script)))

## A second call on the same package runs without error (rvtk already present).
expect_silent(use_rvtk(path = pkg_e2e))

## make_vtk via a custom modules vector is threaded through configure.R.
pkg_mods <- write_pkg(base_desc)
use_rvtk(path = pkg_mods, modules = c("vtkIOLegacy", "vtkCommonCore"))
conf_mods <- readLines(file.path(pkg_mods, "tools", "configure.R"))
expect_true(any(grepl('"vtkIOLegacy"', conf_mods)))
expect_true(any(grepl('"vtkCommonCore"', conf_mods)))
expect_false(any(grepl('"vtkIOGeometry"', conf_mods)))

# ─────────────────────────────────────────────────────────────────────────────
# Base-R messaging branches (mocked rvtk_has_cli = FALSE).
# When `cli` is installed the cli branches run by default; these tests mock the
# internal wrapper to also exercise the plain-`message()` fallbacks.
# ─────────────────────────────────────────────────────────────────────────────

if (can_mock) {
  ## use_rvtk(): base success message
  pkg_b0 <- write_pkg(base_desc)
  suppress_output <- capture.output(
    testthat::with_mocked_bindings(
      rvtk_has_cli = function() FALSE,
      .package = "rvtk",
      use_rvtk(path = pkg_b0)
    ),
    type = "message"
  )
  expect_true(file.exists(file.path(pkg_b0, "src", "Makevars")))

  ## rvtk_use_package: no Description, no License -> insert at end (base msg)
  pkg_b1 <- write_pkg(c(
    "Package: fakepkg",
    "Title: A Fake Package",
    "Version: 0.0.1"
  ))
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_use_package(pkg_b1)
  )
  expect_true(any(grepl(
    "^Imports: rvtk$",
    readLines(file.path(pkg_b1, "DESCRIPTION"))
  )))

  ## rvtk_use_package: no-Imports insert, base message
  pkg_b2 <- write_pkg(base_desc)
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_use_package(pkg_b2)
  )
  expect_true(any(grepl(
    "^Imports: rvtk$",
    readLines(file.path(pkg_b2, "DESCRIPTION"))
  )))

  ## rvtk_use_package: rvtk already in Imports, base skip message
  pkg_b3 <- write_pkg(c(
    "Package: fakepkg",
    "Title: A Fake Package",
    "Version: 0.0.1",
    "License: MIT + file LICENSE",
    "Imports: rvtk"
  ))
  before_b3 <- readLines(file.path(pkg_b3, "DESCRIPTION"))
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_use_package(pkg_b3)
  )
  expect_identical(readLines(file.path(pkg_b3, "DESCRIPTION")), before_b3)

  ## rvtk_use_package: append branch, base message
  pkg_b4 <- write_pkg(c(
    "Package: fakepkg",
    "Title: A Fake Package",
    "Version: 0.0.1",
    "License: MIT + file LICENSE",
    "Imports:",
    "    utils"
  ))
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_use_package(pkg_b4)
  )
  expect_true(any(grepl(
    "^    rvtk$",
    readLines(file.path(pkg_b4, "DESCRIPTION"))
  )))

  ## rvtk_write_file: new file, base "Writing" message
  root_bw <- tempfile("rvtk_bw_")
  dir.create(root_bw)
  bp <- file.path(root_bw, "nested", "b.txt")
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_write_file(bp, "hi", root = root_bw)
  )
  expect_equal(readLines(bp), "hi")

  ## rvtk_write_file: existing file, non-interactive, base skip message
  bexist <- file.path(root_bw, "keep.txt")
  writeLines("orig", bexist)
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    rvtk_interactive = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_write_file(bexist, "new", root = root_bw)
  )
  expect_equal(readLines(bexist), "orig")

  ## rvtk_write_file: interactive, answer not y/n, base skip message
  bint <- tempfile("rvtk_bint_")
  dir.create(bint)
  bintf <- file.path(bint, "f.txt")
  writeLines("old", bintf)
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    rvtk_interactive = function() TRUE,
    rvtk_readline = function(prompt) "no",
    .package = "rvtk",
    rvtk:::rvtk_write_file(bintf, "new", root = bint)
  )
  expect_equal(readLines(bintf), "old")

  ## rvtk_use_git_ignore: pattern present, base skip message
  root_bg <- tempfile("rvtk_bg_")
  dir.create(root_bg)
  writeLines("src/vtk_libs.rsp", file.path(root_bg, ".gitignore"))
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_use_git_ignore("src/vtk_libs.rsp", root = root_bg)
  )
  expect_equal(readLines(file.path(root_bg, ".gitignore")), "src/vtk_libs.rsp")

  ## rvtk_use_git_ignore: pattern absent, base "Adding" message
  root_bg2 <- tempfile("rvtk_bg2_")
  dir.create(root_bg2)
  writeLines("*.o", file.path(root_bg2, ".gitignore"))
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    .package = "rvtk",
    rvtk:::rvtk_use_git_ignore("src/vtk_libs.rsp", root = root_bg2)
  )
  expect_equal(
    readLines(file.path(root_bg2, ".gitignore")),
    c("*.o", "src/vtk_libs.rsp")
  )
}

# ── rvtk_write_file: interactive prompt, real readline at EOF ────────────────
# In a non-interactive subprocess (covr / Rscript) stdin is at EOF and the real
# readline() returns "" without blocking, exercising the prompt-construction
# lines (cli::col_yellow prompt and its base fallback) and the real
# rvtk_readline() body. Guarded to skip interactive test consoles, where the
# real readline() would block waiting for input.

if (can_mock && !interactive()) {
  real_readline_root <- tempfile("rvtk_realrl_")
  dir.create(real_readline_root)
  rl_f <- file.path(real_readline_root, "f.txt")
  writeLines("old", rl_f)
  testthat::with_mocked_bindings(
    rvtk_interactive = function() TRUE,
    .package = "rvtk",
    rvtk:::rvtk_write_file(rl_f, "new", root = real_readline_root)
  )
  ## readline() at EOF returns "", which is not "y"/"yes", so the file is kept.
  expect_equal(readLines(rl_f), "old")
}

if (can_mock && !interactive()) {
  ## Base-R prompt fallback within the interactive overwrite prompt (259).
  real_readline_root2 <- tempfile("rvtk_realrl2_")
  dir.create(real_readline_root2)
  rl_f2 <- file.path(real_readline_root2, "f.txt")
  writeLines("old", rl_f2)
  testthat::with_mocked_bindings(
    rvtk_has_cli = function() FALSE,
    rvtk_interactive = function() TRUE,
    .package = "rvtk",
    rvtk:::rvtk_write_file(rl_f2, "new", root = real_readline_root2)
  )
  expect_equal(readLines(rl_f2), "old")
}
