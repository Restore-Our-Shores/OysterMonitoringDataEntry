mod_event_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(
      col_widths = c(3, 3, 3, 3),
      dateInput(ns("monitoring_date"), span("Date", class = "required-label"), value = Sys.Date()),
      textInput(ns("monitoring_time"), "Time", placeholder = "HH:MM"),
      textInput(ns("project"), span("Project", class = "required-label"), value = "BZ Oyster Monitoring"),
      textInput(ns("site"), span("Reef site", class = "required-label"), placeholder = "Site name")
    ),
    layout_columns(
      col_widths = c(6, 3, 3),
      textInput(ns("observers"), span("Observers", class = "required-label"), placeholder = "Separate multiple names with commas"),
      numericInput(ns("water_temperature_c"), "Water temperature (\u00b0C)", value = NA, min = -5, max = 50, step = .1),
      numericInput(ns("salinity_ppt"), "Salinity (ppt)", value = NA, min = 0, max = 60, step = .1)
    ),
    textAreaInput(ns("event_notes"), notes_label("Event notes"), width = "100%", rows = 2,
                  placeholder = "Weather, access conditions, or visit-level context")
  )
}

mod_event_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    reactive({
      list(
        monitoring_date = as.character(input$monitoring_date),
        monitoring_time = trimws(input$monitoring_time %||% ""),
        project = trimws(input$project %||% ""),
        site = trimws(input$site %||% ""),
        observers = trimws(input$observers %||% ""),
        water_temperature_c = input$water_temperature_c %||% NA_real_,
        salinity_ppt = input$salinity_ppt %||% NA_real_,
        event_notes = trimws(input$event_notes %||% "")
      )
    })
  })
}

