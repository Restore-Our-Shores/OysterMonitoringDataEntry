mod_review_ui <- function(id) {
  ns <- NS(id)
  div(class = "container-xl py-4",
    h1("Review and submit"), p("Check the visit summary and all staged monitoring data before submission.", class = "lead"),
    uiOutput(ns("summary")),
    card(class = "section-card mt-3", card_header("Visual survey"), card_body(div(class = "table-wrap", tableOutput(ns("visual_table"))))),
    card(class = "section-card mt-3", card_header("50 measured oysters"), card_body(div(class = "table-wrap", tableOutput(ns("samples_table"))))),
    card(class = "section-card mt-3", card_header("Structural monitoring"), card_body(div(class = "table-wrap", tableOutput(ns("structural_table"))))),
    uiOutput(ns("validation_messages")),
    div(class = "d-flex flex-wrap justify-content-between gap-2 mt-3",
      actionButton(ns("discard_all"), "Discard all staged data", class = "btn-outline-danger"),
      actionButton(ns("submit"), "Submit monitoring event", class = "btn-success btn-lg")))
}

mod_review_server <- function(id, event, visual, measured, structural) {
  moduleServer(id, function(input, output, session) {
    output$summary <- renderUI({
      e <- event(); visual_rows <- nrow(visual$observations()); sample_rows <- nrow(measured$samples()); structural_rows <- nrow(structural$observations())
      layout_columns(col_widths = c(3, 3, 2, 2, 2),
        div(class = "metric", strong(if (is_blank(e$monitoring_date)) "—" else e$monitoring_date), "Date"),
        div(class = "metric", strong(if (is_blank(e$site)) "—" else e$site), "Site"),
        div(class = "metric", strong(visual_rows), "Visual"), div(class = "metric", strong(sample_rows), "50-oyster samples"),
        div(class = "metric", strong(structural_rows), "Structural"))
    })
    output$visual_table <- renderTable({
      obs <- visual$observations()
      if (!nrow(obs)) return(data.frame(Status = "No visual observations staged."))
      data.frame(Module = obs$module_number, Transect = obs$transect_point, `Reef type` = obs$reef_type,
        `Cover total` = rowSums(obs[names(COVER_FIELDS)], na.rm = TRUE), Notes = obs$notes, check.names = FALSE)
    }, striped = TRUE, hover = TRUE, spacing = "s")
    output$samples_table <- renderTable({
      samples <- measured$samples()
      if (!nrow(samples)) return(data.frame(Status = "No 50-oyster samples staged."))
      size_summary <- aggregate(shell_height_mm ~ sample_id, measured$measurements(), function(x) sprintf("%.1f–%.1f (mean %.1f)", min(x), max(x), mean(x)))
      merged <- merge(samples, size_summary, by = "sample_id", all.x = TRUE, sort = FALSE)
      data.frame(Module = merged$module_number, Transect = merged$transect_point, `Measurements (mm)` = merged$shell_height_mm,
        `Total oysters` = merged$total_oysters, `Fouling load` = merged$fouling_load, Notes = merged$notes, check.names = FALSE)
    }, striped = TRUE, hover = TRUE, spacing = "s")
    output$structural_table <- renderTable({
      obs <- structural$observations()
      if (!nrow(obs)) return(data.frame(Status = "No structural observations staged."))
      data.frame(Module = obs$module_number, Transect = obs$transect_point, `Structure type` = obs$structure_type,
        Damage = ifelse(obs$damage_observed, "Yes", "No"), Macroalgae = ifelse(obs$macroalgae_observed, "Yes", "No"),
        `Materials missing` = ifelse(obs$materials_missing, "Yes", "No"), Notes = obs$notes, check.names = FALSE)
    }, striped = TRUE, hover = TRUE, spacing = "s")

    clear_all <- function() { visual$clear_all(); measured$clear_all(); structural$clear_all() }
    observeEvent(input$discard_all, showModal(modalDialog(title = "Discard all staged data?", "This removes all visual, measured-oyster, and structural records waiting for submission.",
      footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_discard"), "Discard", class = "btn-danger")))))
    observeEvent(input$confirm_discard, { clear_all(); removeModal(); showNotification("All staged data discarded.", type = "warning") })

    observeEvent(input$submit, {
      e <- event(); visual_rows <- visual$observations(); samples <- measured$samples(); measurements <- measured$measurements()
      species <- measured$species(); structural_rows <- structural$observations(); errors <- validate_event(e)
      if (nrow(visual_rows) + nrow(samples) + nrow(structural_rows) == 0L) errors <- c(errors, "Add at least one monitoring record before submitting.")
      if (length(errors)) { output$validation_messages <- renderUI(div(class = "alert alert-danger", tags$ul(lapply(errors, tags$li)))); return() }
      event_id <- new_uuid(); submitted_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
      event_row <- data.frame(event_id = event_id, monitoring_date = e$monitoring_date, monitoring_time = e$monitoring_time,
        project = e$project, site = e$site, observers = e$observers, water_temperature_c = e$water_temperature_c,
        salinity_ppt = e$salinity_ppt, event_notes = e$event_notes, protocol = "oyster_reef_monitoring", submitted_at = submitted_at, stringsAsFactors = FALSE)
      attach_event <- function(rows) { if (nrow(rows)) { rows$event_id <- event_id; rows$submitted_at <- submitted_at }; rows }
      visual_rows <- attach_event(visual_rows); samples <- attach_event(samples); measurements <- attach_event(measurements)
      species <- attach_event(species); structural_rows <- attach_event(structural_rows)
      tryCatch({
        result <- save_submission(event_row, visual_rows, samples, measurements, species, structural_rows); clear_all(); output$validation_messages <- renderUI(NULL)
        showModal(modalDialog(title = "Submission saved", p("The monitoring event and all staged records were saved successfully."),
          p(strong("Event ID: "), code(result$event_id)), p(strong("Storage: "), result$backend), easyClose = TRUE, footer = modalButton("Done")))
      }, error = function(err) output$validation_messages <- renderUI(div(class = "alert alert-danger",
        strong("The submission was not completed. Your staged data remain available. "), span(conditionMessage(err)))))
    })
  })
}
