app_server <- function(input, output, session) {
  event <- mod_event_server("event")
  visual <- mod_visual_server("visual")
  measured <- mod_measured_server("measured")
  structural <- mod_structural_server("structural")
  submission <- reactiveVal(NULL)
  mod_review_server("review", event, visual, measured, structural, submission)

  observeEvent(input$go_visual, {
    bslib::nav_select("main_nav", selected = "visual_survey", session = session)
  })

  observeEvent(input$go_review, {
    bslib::nav_select("main_nav", selected = "review_submit", session = session)
  })

  observeEvent(input$go_measured, {
    bslib::nav_select("main_nav", selected = "measured_oysters", session = session)
  })

  observeEvent(input$go_structural, {
    bslib::nav_select("main_nav", selected = "structural_monitoring", session = session)
  })
}

