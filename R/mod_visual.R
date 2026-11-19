cover_input <- function(ns, id, label) {
  numericInput(ns(id), label, value = 0, min = 0, max = 50, step = 1)
}

measurement_triplet <- function(ns, prefix, title) {
  tagList(
    h5(title),
    layout_columns(
      col_widths = c(4, 4, 4),
      numericInput(ns(paste0(prefix, "_waterward_cm")), "Waterward (cm)", value = NA, min = 0, step = .1),
      numericInput(ns(paste0(prefix, "_top_cm")), "Top (cm)", value = NA, min = 0, step = .1),
      numericInput(ns(paste0(prefix, "_shoreward_cm")), "Shoreward (cm)", value = NA, min = 0, step = .1)
    )
  )
}

mod_visual_ui <- function(id) {
  ns <- NS(id)
  tagList(
    layout_columns(
      col_widths = c(3, 3, 3, 3),
      textInput(ns("module_number"), span("Module number", class = "required-label")),
      selectInput(ns("transect_point"), span("Transect point", class = "required-label"),
                  choices = c("Select..." = "", TRANSECT_POINTS)),
      selectInput(ns("reef_type"), span("Reef type", class = "required-label"),
                  choices = c("Select..." = "", REEF_TYPES)),
      selectInput(ns("module_type"), "Module type", choices = c("Select..." = "", MODULE_TYPES))
    ),
    h5("Quadrat cover counts", class = "mt-2"),
    p("Enter the number of intercept points, out of 50, assigned to each category.", class = "help-note"),
    layout_columns(
      col_widths = c(2, 2, 2, 3, 3),
      cover_input(ns, "live_oysters_count", "Live oysters"),
      cover_input(ns, "sav_count", "SAV / algae"),
      cover_input(ns, "fouling_count", "Fouling"),
      cover_input(ns, "substrate_count", "Bare substrate"),
      cover_input(ns, "sediment_count", "Sediment")
    ),
    uiOutput(ns("cover_total")),
    hr(),
    layout_columns(
      col_widths = c(6, 6),
      measurement_triplet(ns, "depth", "Depth measurements"),
      measurement_triplet(ns, "sediment", "Sediment accrual")
    ),
    layout_columns(
      col_widths = c(3, 3, 6),
      numericInput(ns("visible_live_oysters_1"), "Visible live oysters \u2014 count 1", value = NA, min = 0, step = 1),
      numericInput(ns("visible_live_oysters_2"), "Visible live oysters \u2014 count 2", value = NA, min = 0, step = 1),
      textAreaInput(ns("notes"), notes_label("Observation notes"), rows = 2, width = "100%")
    ),
    uiOutput(ns("messages")),
    div(
      class = "d-flex justify-content-between align-items-center sticky-actions",
      span(textOutput(ns("staged_count"), inline = TRUE), class = "help-note"),
      actionButton(ns("add_observation"), "Add observation", class = "btn-primary btn-lg")
    )
  )
}

mod_visual_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    observations <- reactiveVal(empty_observations())
    pending_warning_signature <- reactiveVal(NULL)

    current_observation <- reactive({
      as.list(data.frame(
        observation_id = new_uuid(),
        module_number = trimws(input$module_number %||% ""),
        transect_point = input$transect_point %||% "",
        reef_type = input$reef_type %||% "",
        live_oysters_count = input$live_oysters_count %||% NA_real_,
        sav_count = input$sav_count %||% NA_real_,
        fouling_count = input$fouling_count %||% NA_real_,
        substrate_count = input$substrate_count %||% NA_real_,
        sediment_count = input$sediment_count %||% NA_real_,
        depth_waterward_cm = input$depth_waterward_cm %||% NA_real_,
        depth_top_cm = input$depth_top_cm %||% NA_real_,
        depth_shoreward_cm = input$depth_shoreward_cm %||% NA_real_,
        sediment_waterward_cm = input$sediment_waterward_cm %||% NA_real_,
        sediment_top_cm = input$sediment_top_cm %||% NA_real_,
        sediment_shoreward_cm = input$sediment_shoreward_cm %||% NA_real_,
        visible_live_oysters_1 = input$visible_live_oysters_1 %||% NA_real_,
        visible_live_oysters_2 = input$visible_live_oysters_2 %||% NA_real_,
        notes = trimws(input$notes %||% ""),
        module_type = input$module_type %||% "",
        stringsAsFactors = FALSE
      ))
    })

    cover_sum <- reactive(sum(c(
      input$live_oysters_count, input$sav_count, input$fouling_count,
      input$substrate_count, input$sediment_count
    ), na.rm = TRUE))

    output$cover_total <- renderUI({
      total <- cover_sum()
      color <- if (identical(total, 50)) "success" else "warning"
      div(class = paste("alert", paste0("alert-", color), "py-2"), strong("Cover total: "), total, " / 50")
    })

    output$staged_count <- renderText(sprintf("%d observation(s) staged", nrow(observations())))

    reset_observation <- function() {
      updateTextInput(session, "module_number", value = "")
      updateSelectInput(session, "transect_point", selected = "")
      updateSelectInput(session, "reef_type", selected = "")
      updateSelectInput(session, "module_type", selected = "")
      for (id in names(COVER_FIELDS)) updateNumericInput(session, id, value = 0)
      for (id in c(
        "depth_waterward_cm", "depth_top_cm", "depth_shoreward_cm",
        "sediment_waterward_cm", "sediment_top_cm", "sediment_shoreward_cm",
        "visible_live_oysters_1", "visible_live_oysters_2"
      )) updateNumericInput(session, id, value = NA)
      updateTextAreaInput(session, "notes", value = "")
      pending_warning_signature(NULL)
    }

    observeEvent(input$add_observation, {
      obs <- current_observation()
      result <- validate_observation(obs)
      output$messages <- renderUI(NULL)
      if (length(result$errors)) {
        output$messages <- renderUI(div(class = "alert alert-danger", tags$ul(lapply(result$errors, tags$li))))
        return()
      }

      signature <- paste(unlist(obs[setdiff(names(obs), "observation_id")]), collapse = "|")
      if (length(result$warnings) && !identical(pending_warning_signature(), signature)) {
        pending_warning_signature(signature)
        output$messages <- renderUI(div(
          class = "alert alert-warning",
          tags$ul(lapply(result$warnings, tags$li)),
          strong("Review the warning, then select Add observation again to confirm.")
        ))
        return()
      }

      observations(rbind(observations(), as.data.frame(obs, stringsAsFactors = FALSE)))
      showNotification("Observation added to the review queue.", type = "message")
      reset_observation()
    })

    clear_all <- function() observations(empty_observations())
    list(observations = reactive(observations()), clear_all = clear_all,
      restore = function(rows) observations(rows))
  })
}
