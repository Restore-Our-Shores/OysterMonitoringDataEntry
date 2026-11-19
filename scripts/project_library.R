# Allow --vanilla checks to find an already-restored project library.
version <- paste(R.version$major, strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1], sep = ".")
libraries <- Sys.glob(file.path("renv", "library", "*", paste0("R-", version), "*"))
if (length(libraries)) .libPaths(c(libraries, .libPaths()))
