# Build an optional installable package archive and deployment manifest.
source("scripts/project_library.R")
source("scripts/check.R")
source("scripts/package_source.R")
archive <- pkgbuild::build(package_source(), dest_path = normalizePath("."), binary = FALSE, vignettes = FALSE, manual = FALSE)
cat("Built deployment archive:", archive, "\n")
if (identical(Sys.getenv("WRITE_DEPLOY_MANIFEST"), "true")) {
  source("scripts/deployment_files.R")
  rsconnect::writeManifest(appDir = ".", appPrimaryDoc = "app.R", appFiles = deployment_files())
}
