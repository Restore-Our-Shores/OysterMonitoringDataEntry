export_titles <- function() c(Events = "Event information", Visual_Observations = "Visual observations",
  Oyster_Samples = "Shell sample totals", Oyster_Measurements = "Individual shell measurements",
  Species_Observations = "Associated species", Structural_Observations = "Structural observations")

mod_review_ui <- function(id) {
  ns <- NS(id)
  div(class = "container-xl py-4",
    h1("Review and download"),
    p("Review your records, then finalize the event to download one Excel workbook containing all six data types.", class = "lead"),
    uiOutput(ns("summary")), uiOutput(ns("validation_messages")),
    div(class = "d-flex flex-wrap gap-2 my-3",
      actionButton(ns("submit"), "Finalize event", class = "btn-success btn-lg"),
      actionButton(ns("edit"), "Return to editing", class = "btn-outline-primary"),
      actionButton(ns("discard_all"), "Discard staged records", class = "btn-outline-danger")),
    uiOutput(ns("export_controls")), uiOutput(ns("review_tables")))
}

mod_review_server <- function(id, event, visual, measured, structural, submission) {
  moduleServer(id, function(input, output, session) {
    staged_payload <- function() {
      e <- event()
      errors <- validate_event(e)
      if (length(errors)) stop(paste(errors, collapse = " "))
      event_id <- new_uuid()
      submitted_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
      event_row <- data.frame(event_id = event_id, monitoring_date = e$monitoring_date, monitoring_time = e$monitoring_time,
        project = e$project, site = e$site, observers = e$observers, water_temperature_c = e$water_temperature_c,
        salinity_ppt = e$salinity_ppt, event_notes = e$event_notes, protocol = "oyster_reef_monitoring", submitted_at = submitted_at,
        stringsAsFactors = FALSE)
      attach <- function(rows) {
        if (nrow(rows)) { rows$event_id <- event_id; rows$submitted_at <- submitted_at }
        rows
      }
      list(event = event_row, visual_observations = attach(visual$observations()),
        oyster_samples = attach(measured$samples()), oyster_measurements = attach(measured$measurements()),
        species_observations = attach(measured$species()), structural_observations = attach(structural$observations()))
    }

    final_tables <- reactive({ req(submission()); prepare_exports(submission()) })
    displayed_tables <- reactive({
      if (!is.null(submission())) return(final_tables())
      e <- lapply(event(), function(value) if (length(value)) value else NA)
      list(Events = as.data.frame(e, stringsAsFactors = FALSE), Visual_Observations = visual$observations(),
        Oyster_Samples = measured$samples(), Oyster_Measurements = measured$measurements(),
        Species_Observations = measured$species(), Structural_Observations = structural$observations())
    })

    output$summary <- renderUI({
      if (is.null(submission())) {
        div(class = "alert alert-info", "These records are still editable. Finalize when you are ready to export.")
      } else {
        div(class = "alert alert-success", strong("Event finalized. "),
          "Review all six data types below and download the event workbook. ",
          strong("Event ID: "), code(submission()$event$event_id),
          p("Your data have not been sent to a database. Keep the downloaded workbook before closing the app."))
      }
    })
    output$review_tables <- renderUI({
      titles <- export_titles()
      do.call(navset_card_tab, lapply(names(titles), function(name) {
        nav_panel(titles[[name]], div(class = "table-wrap", tableOutput(session$ns(paste0("table_", name)))))
      }))
    })
    for (name in names(export_titles())) local({
      key <- name
      output[[paste0("table_", key)]] <- renderTable({
        data <- displayed_tables()[[key]]
        if (!nrow(data)) return(data.frame(Status = "No records entered for this data type."))
        data
      }, striped = TRUE, hover = TRUE, spacing = "s", digits = 3)
      output[[paste0("download_", key)]] <- downloadHandler(
        filename = function() export_filename(final_tables(), key), contentType = "text/csv; charset=utf-8",
        content = function(file) write_export_csv(final_tables()[[key]], file))
    })
    output$download_workbook <- downloadHandler(
      filename = function() workbook_filename(final_tables()),
      contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      content = function(file) write_event_workbook(final_tables(), file))
    output$export_controls <- renderUI({
      req(submission())
      tables <- final_tables()
      div(class = "card p-3 my-3",
        h2("Download finalized data"),
        p("One workbook per event, with six consistently named sheets. Empty data types still include their column headers."),
        div(class = "d-flex flex-wrap gap-2 mb-2",
          downloadButton(session$ns("download_workbook"), "Download event workbook (.xlsx)",
            class = "workbook-download btn-primary btn-lg", `data-filename` = workbook_filename(tables)),
          tags$button(type = "button", class = "btn btn-outline-primary workbook-save-as", "Choose save location")),
        p("Your browser controls the download location. Choose save location opens a file picker in supported desktop browsers over HTTPS or localhost; otherwise use the workbook download button.", class = "help-note"),
        tags$p(class = "workbook-save-status", role = "status", `aria-live` = "polite"),
        tags$details(tags$summary("Optional: individual CSV files"),
          div(class = "d-flex flex-wrap gap-2 mt-2", lapply(names(export_titles()), function(name) {
            downloadButton(session$ns(paste0("download_", name)),
              sprintf("%s (%d)", export_titles()[[name]], nrow(tables[[name]])), class = "csv-download")
          }))))
    })

    observeEvent(input$submit, {
      if (!is.null(submission())) return()
      tryCatch({
        payload <- staged_payload()
        prepare_exports(payload)
        submission(payload)
        output$validation_messages <- renderUI(NULL)
        session$sendCustomMessage("submission-lock", TRUE)
        showNotification("Event finalized. Your event workbook is ready.", type = "message")
      }, error = function(err) {
        output$validation_messages <- renderUI(div(class = "alert alert-danger", conditionMessage(err)))
      })
    })
    observeEvent(input$edit, {
      submission(NULL)
      session$sendCustomMessage("submission-lock", FALSE)
      output$validation_messages <- renderUI(NULL)
    })
    observeEvent(input$discard_all, {
      if (!is.null(submission())) {
        showNotification("Return to editing before discarding records. Download your finalized files first.", type = "warning")
        return()
      }
      showModal(modalDialog(title = "Discard staged records?", "This removes all staged visual, shell, and structural records.",
        footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_discard"), "Discard", class = "btn-danger"))))
    })
    observeEvent(input$confirm_discard, {
      if (!is.null(submission())) return()
      visual$clear_all(); measured$clear_all(); structural$clear_all()
      removeModal()
    })
  })
}
