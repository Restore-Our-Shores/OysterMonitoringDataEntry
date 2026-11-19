source("scripts/project_library.R")
Sys.setenv(R_LIBS_USER = normalizePath(.libPaths()[1], winslash = "/"), RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
if (.Platform$OS.type == "windows") {
  Sys.setenv(LC_ALL = "C", LC_COLLATE = "C", LC_CTYPE = "C", LC_MONETARY = "C", LC_TIME = "C", LANG = "C")
}
source("scripts/package_source.R")
stage <- package_source()
archive <- pkgbuild::build(stage, dest_path = normalizePath("."), binary = FALSE, vignettes = FALSE, manual = FALSE)
r_binary <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "R.exe" else "R")
status <- system2(r_binary, c("CMD", "check", "--no-manual", "--no-build-vignettes", basename(archive)))
if (status != 0L) stop("R CMD check failed; inspect rosoyster.Rcheck/00check.log")
log <- readLines("rosoyster.Rcheck/00check.log", warn = FALSE)
if (any(grepl("WARNING|ERROR", log))) stop("Package check reported warnings or errors; inspect rosoyster.Rcheck/00check.log")
