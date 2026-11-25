# Testing rvtk with downstream packages

``` r

library(rvtk)
```

## Scope and audience

The [rvtk](https://astamm.github.io/rvtk/articles/rvtk.md) vignette is
written for *downstream package authors*: it explains how to link an R
package against VTK through rvtk. This vignette is written for **rvtk
maintainers** (and for curious downstream authors who want to know what
the CI badge really checks). It describes how rvtk tests itself against
*other packages* that consume it, and how the pre-built VTK archives are
validated before they are published.

The guarantees on offer are deliberately layered:

1.  **A minimal, scaffolded consumer**
    ([`downstream-check.yaml`](https://github.com/astamm/rvtk/blob/main/.github/workflows/downstream-check.yaml))
    proves that the two setup strategies produce identical build
    configuration, on every supported platform and VTK strategy.
2.  **A real-world consumer**
    ([`riot-check.yaml`](https://github.com/astamm/rvtk/blob/main/.github/workflows/riot-check.yaml))
    proves that an actual package (`riot`, the original motivation for
    rvtk) installs, links, and round-trips its real VTK files.
3.  **CRAN-checker environments**
    ([`prebuilt-audit.yaml`](https://github.com/astamm/rvtk/blob/main/.github/workflows/prebuilt-audit.yaml))
    replicate the exact containers CRAN uses for Linux aarch64 and musl,
    where hosted GitHub runners cannot exercise the archives.
4.  **Archive-level gates** inside
    [`build-vtk-libs.yml`](https://github.com/astamm/rvtk/blob/main/.github/workflows/build-vtk-libs.yml)
    run before any archive is packaged: a whole-archive link, a macOS
    deployment-target check, and a libc++-ABI check.

## The minimal consumer: `downstream-check.yaml`

File: `.github/workflows/downstream-check.yaml` (604 lines;
workflow-level `cache-version: downstream-check-v1`).

The workflow scaffolds a throwaway R package from scratch with
`usethis::create_package()` + `usethis::use_cpp11()`, attaches VTK by
the two strategies described in the rvtk vignette, and asserts they
produce **byte-identical** `src/Makevars`, `src/Makevars.win`, and
`tools/configure.R` (the reference files are written to a neutral
`REF_DIR` so every matrix leg compares against the same baseline). It
then runs `R CMD check` on the scaffolded package.

### The matrix

Twenty matrix legs (`.github/workflows/downstream-check.yaml:55–103`):

| OS | VTK strategy (× attach strategy) |
|----|----|
| macOS (release) | system, prebuilt-static, built-shared (× manual / `use_rvtk`) |
| Windows (release) | system, prebuilt-static, prebuilt-shared (× manual / `use_rvtk`) |
| Linux (release) | system, prebuilt-static, built-shared (× manual / `use_rvtk`) |
| Linux (release) | prebuilt-static-**libcxx** (× manual / `use_rvtk`) |

The three VTK strategies mirror what a downstream package can encounter:

- **system** — VTK installed from the OS package manager (Homebrew, apt,
  Rtools45 pacman), shared libraries.
- **prebuilt-static / prebuilt-shared** — rvtk downloads its pre-built
  archives (`static` by default; `VTK_LINK_TYPE=shared` selects the
  Windows shared-DLL build).
- **built-shared** — VTK configured from source with
  `BUILD_SHARED_LIBS=ON` and a curated 17-module list, installed into
  the runner (cached with `cache-version: downstream-check-v1`). This
  leg proves rvtk’s flags work against a shared VTK on the *non*-Windows
  platforms too.

### The smoke test

The placeholder C++ file created by `use_cpp11()` is replaced by a small
program (`downstream-check.yaml:318–362`) that deliberately spans
several VTK modules so a single missing `-l` flag fails the link:

- `vtkPolyData` — CommonDataModel
- `vtkPLYReader` — IOPLY
- `vtkPNGReader` — IOImage
- `vtkSphereSource` — FiltersSources
- `vtkExtractGeometry` — FiltersExtraction

(`vtkCellGridReader` / `IOCellGrid` is covered by the `prebuilt-audit`
legs.)

### The fedora-clang / libc++ legs

Two legs force the `clang++ -stdlib=libc++` toolchain through
`R_MAKEVARS_USER`, so rvtk’s configure detects libc++ and selects the
`*-linux-x86_64-libcxx` archive. They then assert
(`downstream-check.yaml:252–278`) that:

- `VTK_STDLIB` in `vtk.conf` is exactly `libc++`; and
- the *downloaded* `libvtkscn` archive is free of the libstdc++-ABI
  symbols (`__try_use_facet`, `__cxa_call_terminate`) that made 0.2.0
  unloadable on CRAN’s `r-devel-linux-x86_64-fedora-clang` flavor (rvtk
  issue \#15).

The checked-in comment at lines 78–84 of the workflow explains why this
matters: CRAN compiles R packages with clang defaulting to libc++, which
cannot `dlopen` a GCC/libstdc++-built archive.

## The real consumer: `riot-check.yaml`

File: `.github/workflows/riot-check.yaml` (299 lines; workflow-level
`cache-version: riot-check-v1`).

`riot` (tractoverse/riot) is the canonical real-world consumer of rvtk:
its C++ reads and writes VTK bundle files (`.vtk`, `.vtp`). It was the
package whose CI failures originally motivated rvtk’s pre-built
archives, its module-linked flags, and the ABI guards, so it is the
natural end-to-end test. Unlike `downstream-check`, this workflow does
**not** scaffold a fake package: it checks out riot’s dev branch,
installs it against the checked-out rvtk, and proves the link by
processing riot’s real shipped files.

### The matrix

Eleven legs (`riot-check.yaml:63–75`):

| OS                | R        | VTK strategy                             |
|-------------------|----------|------------------------------------------|
| macOS (release)   | release  | system, prebuilt-static, built-shared    |
| Windows (release) | release  | system, prebuilt-static, prebuilt-shared |
| Linux             | devel    | prebuilt-static                          |
| Linux             | release  | system, prebuilt-static, built-shared    |
| Linux             | oldrel-1 | prebuilt-static                          |

### Version pinning

`riot`’s DESCRIPTION declares `Imports: rvtk` and
`Remotes: astamm/rvtk`. To stop pak from silently pulling
`astamm/rvtk@main`, the workflow installs the local checkout explicitly
(`riot-check.yaml:218–222`):

``` r

pak::pkg_install(c("local::riot", "local::."), upgrade = FALSE, dependencies = TRUE)
```

and then **asserts** (`riot-check.yaml:228–236`) that the installed rvtk
version equals the checked-out version, failing loudly if a silent
downgrade would mask a regression.

### The real file round-trip

The workflow reads riot’s legacy `.vtk` and XML `.vtp` bundles
(`UF_left.vtk` / `UF_left.vtp`) with `read_bundle()`, writes one back
with `write_bundle()`, and re-reads it (`riot-check.yaml:244–261`). This
exercises exactly the VTK classes riot links against
(`vtkPolyDataReader`, `vtkXMLPolyDataReader`, `vtkPolyDataWriter`,
`vtkXMLPolyDataWriter`) — a stronger guarantee than a synthetic smoke
test, and it exercises the writer path as well.

It then runs `rcmdcheck::rcmdcheck()` on riot (a clean source build
through riot’s own `Makevars` → `tools/configure.R` → rvtk flag
resolution) and riot’s tinytest suite.

## CRAN checker environments: `prebuilt-audit.yaml`

File: `.github/workflows/prebuilt-audit.yaml` (244 lines).

Three of the eight archives — darwin-x86_64, linux-aarch64, and musl —
cannot be exercised on hosted GitHub runners (`build-vtk-libs.yml`
itself notes this for the musl job, which has to run
`docker run alpine:3.22` rather than a `container:` job because Actions’
Node.js runtime is glibc-linked). The `prebuilt-audit` workflow
replicates the two CRAN checker environments that use those archives:

1.  **Linux aarch64** (`prebuilt-audit.yaml:36–131`) — runs on
    `ubuntu-24.04-arm` inside
    `ghcr.io/r-devel/rcheckserver/ubuntu:latest`, the exact image CRAN’s
    linux-arm64 checker uses. It builds the rvtk source tarball,
    installs it, asserts the aarch64 archive was selected, runs the
    tinytest suite, then compiles, links, and runs a C++ program against
    the real archives (this is where `vtkCellGridReader` / `IOCellGrid`
    is baked into the smoke test).
2.  **Linux x86_64 musl** (`prebuilt-audit.yaml:140–244`) — runs inside
    `ghcr.io/bastistician/rcheck-musl:latest` (Alpine, R built against
    musl). Same recipe, asserting the musl archive is selected and that
    the busybox `mktemp` guard from 0.2.0’s fix still holds.

These legs exercise the configure-time *download* path (plain git
fetch + `R CMD build`/`INSTALL`), which the other workflows only reach
through
[`pak::local_install()`](https://pak.r-lib.org/reference/local_install.html).

## How the archives themselves are validated

`build-vtk-libs.yml` (1177 lines) publishes the archives, but it also
runs two quality gates on every build before packaging (plus the
musl-specific guards):

- **Whole-archive link check** (Linux job,
  `build-vtk-libs.yml:641–672`): an empty `main` linked with
  `-Wl,--whole-archive` over *every* static library, forcing every
  member object to resolve. This catches any internally inconsistent or
  dead module, including inter-module references that a consumer’s
  selective link would never pull in.
- **macOS deployment-target check** (`build-vtk-libs.yml:427–455` and
  `533–561`): `otool -l` dumps `LC_BUILD_VERSION` for every member
  object of every static library and asserts `minos == 13.0`, the
  `CMAKE_OSX_DEPLOYMENT_TARGET` passed to configure. This is the
  regression guard for rvtk issue \#16 (archives built on macOS 26
  runners carried `minos 26.0` and warned when linked into R packages
  targeting older macOS).
- **libc++-ABI check** (libcxx job, `build-vtk-libs.yml:844–885`): the
  same `__try_use_facet` / `__cxa_call_terminate` scan that
  `downstream-check` re-runs on the downloaded archive, asserted
  *before* packaging (rvtk issue \#15).
- **musl-specific guards**: the Alpine build patches a viskores
  preprocessor test (`build-vtk-libs.yml:945`) and builds loguru with
  `-DLOGURU_STACKTRACES=0` (`build-vtk-libs.yml:986`) because
  `LOGURU_STACKTRACES` on POSIX pulls in glibc-only backtrace symbols.

### What is *not* covered by CI

- The **system-VTK** behavior is only tested for the distributions the
  hosted runners provide (Homebrew on macOS, apt on Ubuntu, Rtools45 on
  Windows); CRAN’s own 13-flavor checks cover the rest.
- **Memory checkers**: `R CMD check`’s Valgrind leg reports ~1.5 KB
  “definitely lost” inside VTK’s pipeline internals (`vtkInformation`,
  pipeline executives). This is inherent to the statically linked build
  and is suppressed with the shipped `inst/valgrind/vtk.supp` (see the
  “Memory checkers” section of the rvtk vignette); the pre-built
  distribution does not add a Valgrind clean-run gate.

## Module-availability coverage

Every archive ships a `vtk_modules.txt` recording the exact module set
it was built with, and
[`available_modules()`](https://astamm.github.io/rvtk/reference/available_modules.md)
reports it at run time. The `downstream-check` smoke test links modules
from five different kits (Common*, IO*, Filters*, …) to prove the
multi-module link works; the `prebuilt-audit` legs add a sixth
(`IOCellGrid`). The full 160-library set (110 VTK kit modules,
`libvtksys`, 23 viskores libraries, and 26 third-party libraries) is
exercised as a* whole\* by the whole-archive link check at build time,
and per-archive selection is asserted in both `prebuilt-audit` legs.

## Summary

This is the integration-testing pyramid rvtk relies on:

- **many cheap assertions** on a scaffolded consumer across every
  platform × VTK-strategy combination (`downstream-check`, 20 legs);
- **real-world proof** on the package that motivated rvtk (`riot-check`,
  11 legs);
- **environment-exact** replication of the CRAN checkers no hosted
  runner can reach (`prebuilt-audit`, 2 legs); and
- **build-time gates** that refuse to publish an archive that would fail
  any of the above (`build-vtk-libs`).

If you are writing a downstream package, the practical takeaway is: the
strongest guarantee comes from the `riot-check` workflow — a real
package with real VTK files. Add the same kind of round-trip test to
your own package, and run it against both a system VTK and rvtk’s
pre-built static archives.
