mod_measured_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(col_widths = c(6, 6),
      textInput(ns("module_number"), span("Module number", class = "required-label")),
      selectInput(ns("transect_point"), span("Transect point", class = "required-label"), choices = c("Select…" = "", TRANSECT_POINTS))),
    h5("Shell measurements"),
    p("Enter each shell height in millimeters and select Add measurement. Pressing Enter also adds the value.", class = "help-note"),
    uiOutput(ns("measurement_progress")),
    div(class = "shell-entry-row",
      numericInput(ns("shell_height_mm"), "Next shell height (mm)", value = NA, min = 0.1, step = 0.1),
      actionButton(ns("add_measurement"), "Add measurement", class = "btn-primary"),
      actionButton(ns("undo_measurement"), "Undo last", class = "btn-outline-secondary"),
      actionButton(ns("clear_measurements"), "Clear measurements", class = "btn-outline-danger")),
    tags$script(HTML(sprintf("document.addEventListener('keydown', function(e) { if (e.target.id === '%s' && e.key === 'Enter') { e.preventDefault(); document.getElementById('%s').click(); } });", ns("shell_height_mm"), ns("add_measurement")))),
    uiOutput(ns("measurement_message")),
    div(class = "table-wrap shell-measurements-table", tableOutput(ns("measurements_table"))),
    hr(), h5("Sample totals and condition"),
    layout_columns(col_widths = 3,
      numericInput(ns("total_oysters"), "Total oysters (including the 50)", value = NA, min = 50, step = 1),
      numericInput(ns("mortality_boxes"), "Mortality (oyster boxes)", value = NA, min = 0, step = 1),
      numericInput(ns("oysters_through_unit"), "Oysters through unit", value = NA, min = 0, step = 1),
      numericInput(ns("bridging_within_unit"), "Bridging within unit", value = NA, min = 0, step = 1),
      numericInput(ns("volume_gallons"), "Volume estimate (gallons)", value = NA, min = 0, step = 0.1),
      numericInput(ns("anoxic_shell_percent"), "Anoxic shell (%)", value = NA, min = 0, max = 100, step = 1),
      selectInput(ns("fouling_load"), "Fouling load", choices = c("Select…" = "", "Low", "Medium", "High"))),
    hr(), h5("Associated species — counts"),
    p("Enter a count for these four observations only.", class = "help-note"),
    div(class = "count-grid", lapply(names(COUNT_SPECIES), function(code) numericInput(ns(paste0("count_", code)), COUNT_SPECIES[[code]], value = 0, min = 0, step = 1))),
    h5("Associated species — presence/absence", class = "mt-3"),
    p("Check each species or observation that is present; unchecked means No.", class = "help-note"),
    div(class = "species-grid", lapply(names(PRESENCE_SPECIES), function(code) checkboxInput(ns(paste0("present_", code)), PRESENCE_SPECIES[[code]], value = FALSE))),
    textAreaInput(ns("notes"), "Sample notes", width = "100%", rows = 2), uiOutput(ns("messages")),
    div(class = "d-flex justify-content-between align-items-center sticky-actions",
      span(textOutput(ns("staged_count"), inline = TRUE), class = "help-note"),
      actionButton(ns("add_sample"), "Add 50-oyster sample", class = "btn-primary btn-lg")))
}

mod_measured_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    samples <- reactiveVal(empty_oyster_samples()); measurements <- reactiveVal(empty_oyster_measurements()); species <- reactiveVal(empty_species_observations())
    sizes <- reactiveVal(numeric())
    output$measurement_progress <- renderUI({
      complete <- length(sizes())
      div(class = paste("alert py-2", if (complete == 50) "alert-success" else "alert-info"), strong("Completed: "), complete, " / 50")
    })
    output$measurements_table <- renderTable({
      values <- c(sizes(), rep(NA_real_, 50 - length(sizes())))
      result <- as.data.frame(matrix(values, nrow = 5, ncol = 10, byrow = TRUE), check.names = FALSE)
      names(result) <- as.character(seq_len(10))
      result
    }, rownames = FALSE, na = "—", striped = TRUE, bordered = TRUE, spacing = "s", digits = 1)
    output$staged_count <- renderText(sprintf("%d sample(s) staged", nrow(samples())))
    observeEvent(input$add_measurement, {
      value <- input$shell_height_mm
      if (length(sizes()) >= 50L) { output$measurement_message <- renderUI(div(class = "alert alert-warning py-2", "All 50 measurements have already been entered.")); return() }
      if (is.null(value) || is.na(value) || value <= 0) { output$measurement_message <- renderUI(div(class = "alert alert-danger py-2", "Enter a shell height greater than 0 mm.")); return() }
      sizes(c(sizes(), value)); updateNumericInput(session, "shell_height_mm", value = NA); output$measurement_message <- renderUI(NULL)
    })
    observeEvent(input$undo_measurement, {
      if (length(sizes())) sizes(head(sizes(), -1)); output$measurement_message <- renderUI(NULL)
    })
    observeEvent(input$clear_measurements, { sizes(numeric()); output$measurement_message <- renderUI(NULL) })
    current_sample <- reactive(list(
      sample_id = new_uuid(), module_number = trimws(input$module_number %||% ""), transect_point = input$transect_point %||% "",
      total_oysters = as.integer(input$total_oysters), mortality_boxes = as.integer(input$mortality_boxes),
      oysters_through_unit = as.integer(input$oysters_through_unit), bridging_within_unit = as.integer(input$bridging_within_unit),
      volume_gallons = input$volume_gallons, anoxic_shell_percent = input$anoxic_shell_percent,
      fouling_load = input$fouling_load %||% "", notes = trimws(input$notes %||% "")))
    reset_form <- function() {
      updateTextInput(session, "module_number", value = ""); updateSelectInput(session, "transect_point", selected = "")
      sizes(numeric()); updateNumericInput(session, "shell_height_mm", value = NA)
      for (id in c("total_oysters", "mortality_boxes", "oysters_through_unit", "bridging_within_unit", "volume_gallons", "anoxic_shell_percent")) updateNumericInput(session, id, value = NA)
      updateSelectInput(session, "fouling_load", selected = "")
      for (code in names(COUNT_SPECIES)) updateNumericInput(session, paste0("count_", code), value = 0)
      for (code in names(PRESENCE_SPECIES)) updateCheckboxInput(session, paste0("present_", code), value = FALSE)
      updateTextAreaInput(session, "notes", value = "")
    }
    observeEvent(input$add_sample, {
      sample <- current_sample(); errors <- validate_oyster_sample(sample, sizes()); output$messages <- renderUI(NULL)
      if (length(errors)) { output$messages <- renderUI(div(class = "alert alert-danger", tags$ul(lapply(errors, tags$li)))); return() }
      sample_id <- sample$sample_id; samples(rbind(samples(), as.data.frame(sample, stringsAsFactors = FALSE)))
      measurements(rbind(measurements(), data.frame(sample_id = sample_id, oyster_number = seq_len(50), shell_height_mm = sizes(), stringsAsFactors = FALSE)))
      count_rows <- data.frame(sample_id, species_code = names(COUNT_SPECIES), species_label = unname(COUNT_SPECIES), observation_type = "count", present = NA, count = vapply(names(COUNT_SPECIES), function(code) as.integer(input[[paste0("count_", code)]] %||% 0), integer(1)), stringsAsFactors = FALSE)
      presence_rows <- data.frame(sample_id, species_code = names(PRESENCE_SPECIES), species_label = unname(PRESENCE_SPECIES), observation_type = "presence", present = vapply(names(PRESENCE_SPECIES), function(code) isTRUE(input[[paste0("present_", code)]]), logical(1)), count = NA_integer_, stringsAsFactors = FALSE)
      species(rbind(species(), count_rows, presence_rows)); showNotification("50-oyster sample added to the review queue.", type = "message"); reset_form()
    })
    clear_all <- function() { samples(empty_oyster_samples()); measurements(empty_oyster_measurements()); species(empty_species_observations()) }
    list(samples = reactive(samples()), measurements = reactive(measurements()), species = reactive(species()), clear_all = clear_all)
  })
}
