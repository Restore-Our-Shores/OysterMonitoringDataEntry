package_source <- function() {
  # Stage only package sources; never traverse the local dependency library,
  # field data, Git history, or credentials while building a release.
  stage <- tempfile("rosoyster-source-")
  dir.create(stage)
  files <- c("DESCRIPTION", "NAMESPACE", "LICENSE", "R", "inst", "man", "tests")
  if (!all(file.copy(files, stage, recursive = TRUE))) stop("Could not stage package sources.")
  stage
}
