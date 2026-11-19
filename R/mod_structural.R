mod_structural_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(col_widths = c(4, 4, 4),
      textInput(ns("module_number"), span("Module number", class = "required-label")),
      selectInput(ns("transect_point"), span("Transect point", class = "required-label"), choices = c("Select..." = "", TRANSECT_POINTS)),
      selectInput(ns("structure_type"), span("Structure type", class = "required-label"), choices = c("Select..." = "", STRUCTURE_TYPES))),
    uiOutput(ns("depth_fields")), h5("Sediment accrual"),
    layout_columns(col_widths = c(4, 4, 4),
      numericInput(ns("sediment_waterward_cm"), "Waterward (cm)", value = NA, min = 0, step = .1),
      numericInput(ns("sediment_top_cm"), "Top (cm)", value = NA, min = 0, step = .1),
      numericInput(ns("sediment_shoreward_cm"), "Shoreward (cm)", value = NA, min = 0, step = .1)),
    h5("Condition"),
    layout_columns(col_widths = c(4, 4, 4), checkboxInput(ns("damage_observed"), "Damage observed"),
      checkboxInput(ns("macroalgae_observed"), "Macroalgae observed"), checkboxInput(ns("materials_missing"), "Materials missing")),
    textAreaInput(ns("notes"), notes_label("Structural notes"), width = "100%", rows = 3, placeholder = "Describe damage, macroalgae, missing materials, or other conditions"),
    uiOutput(ns("messages")),
    div(class = "d-flex justify-content-between align-items-center sticky-actions",
      span(textOutput(ns("staged_count"), inline = TRUE), class = "help-note"),
      actionButton(ns("add_observation"), "Add structural observation", class = "btn-primary btn-lg")))
}

mod_structural_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    observations <- reactiveVal(empty_structural_observations())
    output$depth_fields <- renderUI({
      req(input$structure_type)
      if (identical(input$structure_type, "Corral")) {
        tagList(h5("Depth \u2014 Corral positions"), p("Measure W, WS, TS, SS, and S as shown on the Corral topsheet.", class = "help-note"),
          layout_columns(col_widths = c(2, 2, 3, 2, 3),
            numericInput(session$ns("depth_waterward_sediment_cm"), "W: waterward sediment (cm)", NA, min = 0, step = .1),
            numericInput(session$ns("depth_waterward_shell_cm"), "WS: waterward shell (cm)", NA, min = 0, step = .1),
            numericInput(session$ns("depth_top_shell_cm"), "TS: top-center shell (cm)", NA, min = 0, step = .1),
            numericInput(session$ns("depth_shoreward_shell_cm"), "SS: shoreward shell (cm)", NA, min = 0, step = .1),
            numericInput(session$ns("depth_shoreward_sediment_cm"), "S: shoreward sediment (cm)", NA, min = 0, step = .1)))
      } else {
        tagList(h5("Depth \u2014 Bag/Gabion positions"), p("Bag and Gabion use the same Waterward, Top, and Shoreward fields.", class = "help-note"),
          layout_columns(col_widths = c(4, 4, 4),
            numericInput(session$ns("depth_waterward_sediment_cm"), "Waterward (cm)", NA, min = 0, step = .1),
            numericInput(session$ns("depth_top_shell_cm"), "Top (cm)", NA, min = 0, step = .1),
            numericInput(session$ns("depth_shoreward_sediment_cm"), "Shoreward (cm)", NA, min = 0, step = .1)))
      }
    })
    value <- function(id) input[[id]] %||% NA_real_
    current <- reactive({
      is_corral <- identical(input$structure_type, "Corral")
      list(
      structural_observation_id = new_uuid(), module_number = trimws(input$module_number %||% ""), transect_point = input$transect_point %||% "", structure_type = input$structure_type %||% "",
      depth_waterward_sediment_cm = value("depth_waterward_sediment_cm"), depth_waterward_shell_cm = if (is_corral) value("depth_waterward_shell_cm") else NA_real_,
      depth_top_shell_cm = value("depth_top_shell_cm"), depth_shoreward_shell_cm = if (is_corral) value("depth_shoreward_shell_cm") else NA_real_,
      depth_shoreward_sediment_cm = value("depth_shoreward_sediment_cm"), sediment_waterward_cm = value("sediment_waterward_cm"),
      sediment_top_cm = value("sediment_top_cm"), sediment_shoreward_cm = value("sediment_shoreward_cm"),
      damage_observed = isTRUE(input$damage_observed), macroalgae_observed = isTRUE(input$macroalgae_observed),
      materials_missing = isTRUE(input$materials_missing), notes = trimws(input$notes %||% ""))
    })
    output$staged_count <- renderText(sprintf("%d structural observation(s) staged", nrow(observations())))
    reset_form <- function() {
      updateTextInput(session, "module_number", value = ""); updateSelectInput(session, "transect_point", selected = ""); updateSelectInput(session, "structure_type", selected = "")
      for (id in c("sediment_waterward_cm", "sediment_top_cm", "sediment_shoreward_cm")) updateNumericInput(session, id, value = NA)
      for (id in c("damage_observed", "macroalgae_observed", "materials_missing")) updateCheckboxInput(session, id, value = FALSE)
      updateTextAreaInput(session, "notes", value = "")
    }
    observeEvent(input$add_observation, {
      obs <- current(); errors <- validate_structural_observation(obs); output$messages <- renderUI(NULL)
      if (length(errors)) { output$messages <- renderUI(div(class = "alert alert-danger", tags$ul(lapply(errors, tags$li)))); return() }
      observations(rbind(observations(), as.data.frame(obs, stringsAsFactors = FALSE)))
      showNotification("Structural observation added to the review queue.", type = "message"); reset_form()
    })
    clear_all <- function() observations(empty_structural_observations())
    list(observations = reactive(observations()), clear_all = clear_all,
      restore = function(rows) observations(rows))
  })
}
