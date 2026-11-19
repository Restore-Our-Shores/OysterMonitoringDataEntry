# A project profile overrides R's user profile, including CI's CRAN mirror.
options(repos = c(CRAN = Sys.getenv("RSPM", unset = "https://cloud.r-project.org")))

if (interactive()) {
  if (!nzchar(Sys.getenv("RENV_PATHS_ROOT"))) {
    Sys.setenv(RENV_PATHS_ROOT = file.path(getwd(), "renv", "local"))
  }
  source("renv/activate.R")
}
