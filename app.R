# Launch the ShinyApp (Do not remove this comment)
# Deploy the whole package directory, following DEPLOYMENT.md.
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options(golem.app.prod = TRUE)
rosoyster::run_app()
