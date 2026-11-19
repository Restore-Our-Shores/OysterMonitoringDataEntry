# Legacy draft utilities retained for possible future use. The application does
# not currently mount these controls, start draft_server(), or load drafts.js.
draft_controls_ui <- function() {
  div(class = "container-xl py-2 draft-controls",
    div(class = "d-flex flex-wrap gap-2 align-items-center",
      span("Drafts are saved in this browser. Download a backup before changing devices.", class = "help-note"),
      downloadButton("download_draft", "Download draft"),
      actionButton("recover_draft", "Recover browser draft", class = "btn-outline-secondary"),
      actionButton("new_draft", "Start a new draft", class = "btn-outline-secondary"),
      tags$details(tags$summary("Import a backup"),
        fileInput("upload_draft", "Draft backup (.json)", accept = ".json"))),
    textOutput("draft_status"))
}

draft_input_ids <- function() {
  c(paste0("event-", c("monitoring_date", "monitoring_time", "project", "site", "observers", "water_temperature_c", "salinity_ppt", "event_notes")),
    paste0("visual-", setdiff(names(empty_observations()), "observation_id")),
    paste0("measured-", c(setdiff(names(empty_oyster_samples()), "sample_id"), "shell_height_mm",
      paste0("count_", names(COUNT_SPECIES)), paste0("present_", names(PRESENCE_SPECIES)))),
    paste0("structural-", setdiff(names(empty_structural_observations()), "structural_observation_id")))
}

draft_state <- function(input, visual, measured, structural, submission) {
  raw <- reactiveValuesToList(input)
  # Action-button counters and upload metadata must never be replayed.
  raw <- raw[intersect(names(raw), draft_input_ids())]
  raw <- lapply(raw, function(value) if (inherits(value, "Date")) as.character(value) else value)
  list(version = 1L, inputs = raw, visual = visual$observations(),
    measured = list(samples = measured$samples(), measurements = measured$measurements(),
      species = measured$species(), sizes = measured$sizes()),
    structural = structural$observations(), submission = submission())
}

encode_draft <- function(state) as.character(jsonlite::serializeJSON(state, digits = NA))

decode_draft <- function(text) {
  if (!is.character(text) || length(text) != 1L || nchar(text, type = "bytes") > 5e6) stop("Draft backup is too large or invalid.")
  state <- jsonlite::unserializeJSON(text)
  if (!is.list(state) || !identical(state$version, 1L) || !is.list(state$inputs) || !is.list(state$measured)) stop("Unsupported draft backup.")
  # Unsent drafts from 0.2.0 predate the optional visual module type.
  if (is.data.frame(state$visual) &&
      identical(names(state$visual), setdiff(names(empty_observations()), "module_type"))) {
    state$visual$module_type <- rep("", nrow(state$visual))
  }
  if (!all(names(state$inputs) %in% draft_input_ids()) || anyDuplicated(names(state$inputs)) ||
      any(vapply(state$inputs, function(x) !is.null(x) && (!is.atomic(x) || length(x) > 1L || is.object(x)), logical(1)))) stop("Draft contains unsupported form controls.")
  frames <- list(state$visual, state$measured$samples, state$measured$measurements, state$measured$species, state$structural)
  prototypes <- list(empty_observations(), empty_oyster_samples(), empty_oyster_measurements(), empty_species_observations(), empty_structural_observations())
  for (i in seq_along(frames)) {
    x <- frames[[i]]
    if (!is.data.frame(x) || !identical(names(x), names(prototypes[[i]])) || nrow(x) > 10000L ||
        any(vapply(x, function(column) !is.atomic(column) || is.object(column), logical(1)))) stop("Draft contains an invalid monitoring table.")
    for (name in names(x)) {
      expected <- prototypes[[i]][[name]]
      # Shiny sends blank numeric fields as logical NA. Only coerce a column
      # when every value is missing; populated values must still match the schema.
      if (is.numeric(expected) && is.logical(x[[name]]) && all(is.na(x[[name]]))) {
        x[[name]] <- if (is.integer(expected)) rep(NA_integer_, nrow(x)) else rep(NA_real_, nrow(x))
      }
      if ((is.character(expected) && !is.character(x[[name]])) ||
          (is.numeric(expected) && !is.numeric(x[[name]])) ||
          (is.logical(expected) && !is.logical(x[[name]]))) stop("Draft table columns have incompatible types.")
    }
    frames[[i]] <- x
  }
  state$visual <- frames[[1]]
  state$measured$samples <- frames[[2]]
  state$measured$measurements <- frames[[3]]
  state$measured$species <- frames[[4]]
  state$structural <- frames[[5]]
  if (!is.numeric(state$measured$sizes) || length(state$measured$sizes) > 50L ||
      any(!is.finite(state$measured$sizes) | state$measured$sizes <= 0)) stop("Draft contains invalid shell measurements.")
  if (!is.null(state$submission)) {
    args <- c("event", "visual_observations", "oyster_samples", "oyster_measurements", "species_observations", "structural_observations")
    if (!is.list(state$submission) || !identical(names(state$submission), args)) stop("Draft contains an invalid pending submission.")
    old_visual <- state$submission$visual_observations
    if (nrow(old_visual) && !"module_type" %in% names(old_visual)) {
      old_visual$module_type <- ""
      state$submission$visual_observations <- old_visual[names(export_schema()$Visual_Observations)]
    }
    tables <- state$submission
    names(tables) <- names(export_schema())
    validate_submission(tables)
  }
  state
}

draft_server <- function(input, session, event, visual, measured, structural, submission) {
  output <- session$output
  available <- reactiveVal(NULL)
  ready <- reactiveVal(FALSE)
  status <- reactiveVal("")
  state <- reactive(draft_state(input, visual, measured, structural, submission))
  output$draft_status <- renderText(status())
  snapshot <- debounce(state, 250)
  observeEvent(input$draft_found, {
    existing <- input$draft_found$text
    if (is.character(existing) && nzchar(existing)) {
      available(existing)
      status("A saved browser draft is available. Select Recover browser draft to restore it.")
    } else ready(TRUE)
  })
  observe({
    s <- snapshot()
    if (!ready()) return()
    session$sendCustomMessage("draft-save", list(text = encode_draft(s)))
  })
  # Preserve the finalized snapshot for recovery without clearing staged records.
  observeEvent(submission(), {
    if (!ready()) {
      status("Your finalized CSVs are ready. Recover the previous browser draft or select Start a new draft to replace that browser backup.")
      return()
    }
    session$sendCustomMessage("submission-lock", TRUE)
    session$sendCustomMessage("draft-save", list(text = encode_draft(isolate(state()))))
  }, ignoreNULL = TRUE)
  restore <- function(text) {
    tryCatch({
      s <- decode_draft(text)
      visual$restore(s$visual); measured$restore(s$measured); structural$restore(s$structural)
      submission(s$submission)
      session$sendCustomMessage("draft-restore-inputs", s$inputs)
      session$sendCustomMessage("submission-lock", !is.null(s$submission))
      ready(TRUE); available(NULL)
      status("Draft recovered. Review your records before submitting.")
    }, error = function(err) status(paste("Draft recovery failed:", conditionMessage(err))))
  }
  observeEvent(input$recover_draft, {
    if (is.null(available())) { status("No saved browser draft is available."); return() }
    showModal(modalDialog(title = "Recover saved draft?", "This replaces the current form and staged records with the saved draft.",
      footer = tagList(modalButton("Cancel"), actionButton("confirm_recover_draft", "Recover draft"))))
  })
  observeEvent(input$confirm_recover_draft, { removeModal(); restore(available()) })
  observeEvent(input$new_draft, {
    showModal(modalDialog(title = "Replace the browser backup?",
      "Download any backup you need first. This replaces the saved browser draft with your current form and staged records.",
      footer = tagList(modalButton("Cancel"), actionButton("confirm_new_draft", "Use current draft"))))
  })
  observeEvent(input$confirm_new_draft, {
    removeModal(); available(NULL); ready(TRUE); status("Your current draft will be saved in this browser.")
  })
  observeEvent(input$upload_draft, {
    file <- input$upload_draft
    if (is.null(file)) return()
    if (file$size > 5e6) { status("Draft backup exceeds 5 MB."); return() }
    candidate <- paste(readLines(file$datapath, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    tryCatch({ decode_draft(candidate); available(candidate)
      showModal(modalDialog(title = "Import draft backup?", "This replaces the current form and staged records.",
        footer = tagList(modalButton("Cancel"), actionButton("confirm_recover_draft", "Import draft"))))
    }, error = function(err) status(paste("Invalid backup:", conditionMessage(err))))
  })
  output$download_draft <- downloadHandler(
    filename = function() paste0("oyster-monitoring-draft-", Sys.Date(), ".json"),
    contentType = "application/json",
    content = function(file) writeLines(encode_draft(isolate(state())), file, useBytes = TRUE))
  observeEvent(input$draft_storage_error, status("Browser draft storage is unavailable. Download a backup to preserve your work."))
}
