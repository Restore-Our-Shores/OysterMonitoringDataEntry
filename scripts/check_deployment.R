# Validate the dependency files and launch from only the published sources.
source("scripts/project_library.R")
source("scripts/deployment_files.R")
options(sass.cache = file.path(tempdir(), "rosoyster-deployment-sass"))
manifest <- jsonlite::read_json("manifest.json", simplifyVector = FALSE)
lock <- jsonlite::read_json("renv.lock", simplifyVector = FALSE)
files <- deployment_files()
stopifnot(
  identical(manifest$metadata$appmode, "shiny"),
  identical(manifest$platform, lock$R$Version),
  setequal(names(manifest$files), files),
  all(file.exists(files))
)
for (path in files) {
  if (!identical(unname(tools::md5sum(path)), manifest$files[[path]]$checksum)) {
    stop("Stale manifest checksum: ", path, "; regenerate manifest.json.")
  }
}
for (package in names(manifest$packages)) {
  record <- manifest$packages[[package]]
  stopifnot(identical(record$description$Version, lock$Packages[[package]]$Version))
  if (!record$Source %in% c("CRAN", "Bioconductor", "github", "gitlab", "bitbucket", "git")) {
    stop("Review deployment package source: ", package, " (", record$Source, ")")
  }
}

bundle <- tempfile("rosoyster-deployment-")
dir.create(bundle)
for (path in files) {
  target <- file.path(bundle, path)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(path, target))
}
local({
  previous <- setwd(bundle)
  on.exit(setwd(previous))
  app <- source("app.R", local = new.env(parent = globalenv()))$value
  stopifnot(inherits(app, "shiny.appobj"))
  html <- htmltools::renderTags(get("app_ui", asNamespace("rosoyster"))(NULL))
  stopifnot(grepl("www/workbook-downloads.js", paste(html$html, html$head), fixed = TRUE))
})
cat("Deployment manifest, locked versions and isolated app bundle passed.\n")
