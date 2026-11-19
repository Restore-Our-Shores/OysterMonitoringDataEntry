# Serve exactly the deployment files for isolated CSV browser acceptance tests.
source("scripts/project_library.R")
source("scripts/deployment_files.R")
root <- normalizePath(".", winslash = "/")
dir.create("tmp", showWarnings = FALSE)
bundle <- tempfile("acceptance-bundle-", tmpdir = file.path(root, "tmp"))
dir.create(bundle)
for (path in deployment_files()) {
  target <- file.path(bundle, path)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(path, target)) stop(paste("Could not copy", path))
}
options(sass.cache = file.path(tempdir(), "rosoyster-sass"))
setwd(bundle)
shiny::runApp(".", host = "127.0.0.1", port = 8766, launch.browser = FALSE)
