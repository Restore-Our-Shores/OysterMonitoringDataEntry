storage_backend <- function() {
  backend <- tolower(Sys.getenv("STORAGE_BACKEND", "local"))
  if (!backend %in% c("local", "google_sheets")) stop("STORAGE_BACKEND must be 'local' or 'google_sheets'.")
  backend
}

append_csv_rows <- function(path, rows) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  exists <- file.exists(path)
  utils::write.table(
    rows,
    file = path,
    sep = ",",
    row.names = FALSE,
    col.names = !exists,
    append = exists,
    qmethod = "double",
    na = ""
  )
}

google_authenticate <- local({
  authenticated <- FALSE
  function() {
    if (authenticated) return(invisible(TRUE))
    credentials_json <- Sys.getenv("GOOGLE_SERVICE_ACCOUNT_JSON", "")
    credentials_path <- Sys.getenv("GOOGLE_SERVICE_ACCOUNT_FILE", "")

    if (nzchar(credentials_json)) {
      tmp <- tempfile(fileext = ".json")
      writeLines(credentials_json, tmp, useBytes = TRUE)
      on.exit(unlink(tmp), add = TRUE)
      googlesheets4::gs4_auth(path = tmp)
    } else if (nzchar(credentials_path)) {
      googlesheets4::gs4_auth(path = credentials_path)
    } else {
      stop("Google Sheets storage requires GOOGLE_SERVICE_ACCOUNT_JSON or GOOGLE_SERVICE_ACCOUNT_FILE.")
    }
    authenticated <<- TRUE
    invisible(TRUE)
  }
})

save_submission <- function(event, observations) {
  stopifnot(nrow(event) == 1L, nrow(observations) > 0L)
  backend <- storage_backend()

  if (identical(backend, "local")) {
    append_csv_rows(file.path("data", "events.csv"), event)
    append_csv_rows(file.path("data", "visual_observations.csv"), observations)
    return(invisible(list(backend = backend, event_id = event$event_id)))
  }

  if (!requireNamespace("googlesheets4", quietly = TRUE)) stop("The googlesheets4 package is required.")
  sheet_id <- Sys.getenv("GOOGLE_SHEET_ID", "")
  if (!nzchar(sheet_id)) stop("GOOGLE_SHEET_ID is required for Google Sheets storage.")
  google_authenticate()

  # Event status makes an interrupted multi-tab submission discoverable and recoverable.
  event$submission_status <- "pending"
  googlesheets4::sheet_append(sheet_id, event, sheet = "Events")
  googlesheets4::sheet_append(sheet_id, observations, sheet = "Visual_Observations")
  event$submission_status <- "complete"
  googlesheets4::range_write(
    sheet_id,
    data = event,
    sheet = "Events",
    range = paste0("A", nrow(googlesheets4::read_sheet(sheet_id, sheet = "Events", col_types = "c")) + 1L),
    col_names = FALSE
  )
  invisible(list(backend = backend, event_id = event$event_id))
}
