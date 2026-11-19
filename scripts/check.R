# Run from the repository root. Works before renv activation on this workstation.
source("scripts/project_library.R")
library(shiny)
pkgload::load_all(quiet = TRUE)
testthat::test_local(stop_on_failure = TRUE)
stopifnot(inherits(run_app(), "shiny.appobj"))
cat("Package tests and app construction passed.\n")
