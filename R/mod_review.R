mod_review_ui <- function(id) {
  ns <- NS(id)
  div(
    class = "container-xl py-4",
    h1("Review and submit"),
    p("Check the visit summary and staged observations before writing the submission.", class = "lead"),
    uiOutput(ns("summary")),
    card(
      class = "section-card mt-3",
      card_header("Staged visual observations"),
      card_body(
        div(class = "table-wrap", tableOutput(ns("observations_table"))),
        uiOutput(ns("validation_messages")),
        div(
          class = "d-flex flex-wrap justify-content-between gap-2 mt-3",
          actionButton(ns("discard_all"), "Discard staged observations", class = "btn-outline-danger"),
          actionButton(ns("submit"), "Submit monitoring event", class = "btn-success btn-lg")
        )
      )
    )
  )
}

mod_review_server <- function(id, event, observations, clear_observations) {
  moduleServer(id, function(input, output, session) {
    output$summary <- renderUI({
      e <- event()
      obs <- observations()
      layout_columns(
        col_widths = c(3, 3, 3, 3),
        div(class = "metric", strong(if (is_blank(e$monitoring_date)) "—" else e$monitoring_date), "Date"),
        div(class = "metric", strong(if (is_blank(e$site)) "—" else e$site), "Site"),
        div(class = "metric", strong(nrow(obs)), "Observations"),
        div(class = "metric", strong(length(unique(obs$module_number))), "Modules")
      )
    })

    output$observations_table <- renderTable({
      obs <- observations()
      if (!nrow(obs)) return(data.frame(Status = "No observations have been staged."))
      data.frame(
        Module = obs$module_number,
        Transect = obs$transect_point,
        `Reef type` = obs$reef_type,
        `Cover total` = rowSums(obs[names(COVER_FIELDS)], na.rm = TRUE),
        `Visible live oysters` = rowSums(obs[c("visible_live_oysters_1", "visible_live_oysters_2")], na.rm = TRUE),
        Notes = obs$notes,
        check.names = FALSE
      )
    }, striped = TRUE, hover = TRUE, bordered = FALSE, spacing = "s")

    observeEvent(input$discard_all, {
      showModal(modalDialog(
        title = "Discard staged observations?",
        "This removes the observations currently waiting for submission.",
        footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_discard"), "Discard", class = "btn-danger"))
      ))
    })

    observeEvent(input$confirm_discard, {
      clear_observations()
      removeModal()
      showNotification("Staged observations discarded.", type = "warning")
    })

    observeEvent(input$submit, {
      e <- event()
      obs <- observations()
      errors <- validate_event(e)
      if (!nrow(obs)) errors <- c(errors, "Add at least one visual observation.")

      if (length(errors)) {
        output$validation_messages <- renderUI(div(class = "alert alert-danger", tags$ul(lapply(errors, tags$li))))
        return()
      }

      event_id <- new_uuid()
      submitted_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
      event_row <- data.frame(
        event_id = event_id,
        monitoring_date = e$monitoring_date,
        monitoring_time = e$monitoring_time,
        project = e$project,
        site = e$site,
        observers = e$observers,
        water_temperature_c = e$water_temperature_c,
        salinity_ppt = e$salinity_ppt,
        event_notes = e$event_notes,
        protocol = "visual_survey",
        submitted_at = submitted_at,
        stringsAsFactors = FALSE
      )
      obs$event_id <- event_id
      obs$submitted_at <- submitted_at

      tryCatch({
        result <- save_submission(event_row, obs)
        clear_observations()
        output$validation_messages <- renderUI(NULL)
        showModal(modalDialog(
          title = "Submission saved",
          tags$p("The monitoring event and its observations were saved successfully."),
          tags$p(tags$strong("Event ID: "), tags$code(result$event_id)),
          tags$p(tags$strong("Storage: "), result$backend),
          easyClose = TRUE,
          footer = modalButton("Done")
        ))
      }, error = function(err) {
        output$validation_messages <- renderUI(div(
          class = "alert alert-danger",
          strong("The submission was not completed. Your staged observations remain available. "),
          span(conditionMessage(err))
        ))
      })
    })
  })
}

