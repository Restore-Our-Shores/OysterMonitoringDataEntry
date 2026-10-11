shell_size_input <- function(ns, number) {
  numericInput(ns(paste0("shell_", number)), paste("Oyster", number), value = NA, min = 0.1, step = 0.1)
}

mod_measured_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(col_widths = c(6, 6),
      textInput(ns("module_number"), span("Module number", class = "required-label")),
      selectInput(ns("transect_point"), span("Transect point", class = "required-label"), choices = c("Select…" = "", TRANSECT_POINTS))),
    h5("Shell height (mm)"),
    p("Enter exactly 50 shell measurements. All fields are required before the sample can be staged.", class = "help-note"),
    uiOutput(ns("measurement_progress")),
    div(class = "measurement-grid", lapply(seq_len(50), function(i) shell_size_input(ns, i))),
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
    sizes <- reactive(vapply(seq_len(50), function(i) input[[paste0("shell_", i)]] %||% NA_real_, numeric(1)))
    output$measurement_progress <- renderUI({
      complete <- sum(!is.na(sizes()))
      div(class = paste("alert py-2", if (complete == 50) "alert-success" else "alert-info"), strong("Completed: "), complete, " / 50")
    })
    output$staged_count <- renderText(sprintf("%d sample(s) staged", nrow(samples())))
    current_sample <- reactive(list(
      sample_id = new_uuid(), module_number = trimws(input$module_number %||% ""), transect_point = input$transect_point %||% "",
      total_oysters = as.integer(input$total_oysters), mortality_boxes = as.integer(input$mortality_boxes),
      oysters_through_unit = as.integer(input$oysters_through_unit), bridging_within_unit = as.integer(input$bridging_within_unit),
      volume_gallons = input$volume_gallons, anoxic_shell_percent = input$anoxic_shell_percent,
      fouling_load = input$fouling_load %||% "", notes = trimws(input$notes %||% "")))
    reset_form <- function() {
      updateTextInput(session, "module_number", value = ""); updateSelectInput(session, "transect_point", selected = "")
      for (i in seq_len(50)) updateNumericInput(session, paste0("shell_", i), value = NA)
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
