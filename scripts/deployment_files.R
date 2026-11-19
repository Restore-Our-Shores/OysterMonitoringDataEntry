deployment_files <- function() c("app.R", "DESCRIPTION", "NAMESPACE", "LICENSE", "renv.lock",
  list.files(c("R", "inst", "man"), recursive = TRUE, full.names = TRUE))
