#' Run the oyster reef monitoring application
#' @param ... Options passed to golem.
#' @param options Shiny application options.
#' @return A Shiny application.
#' @export
run_app <- function(..., options = list()) {
  golem::with_golem_options(
    app = shiny::shinyApp(ui = app_ui, server = app_server, options = options),
    golem_opts = list(...)
  )
}

