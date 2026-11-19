source("scripts/project_library.R")
pkgload::load_all(quiet = TRUE)
options(sass.cache = file.path(tempdir(), "rosoyster-sass"))
shiny::runApp(run_app(), host = "127.0.0.1", port = 8765, launch.browser = interactive())
