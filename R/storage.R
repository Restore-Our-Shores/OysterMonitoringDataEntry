empty_event <- function() data.frame(
  event_id = character(), monitoring_date = character(), monitoring_time = character(),
  project = character(), site = character(), observers = character(), water_temperature_c = numeric(),
  salinity_ppt = numeric(), event_notes = character(), protocol = character(), submitted_at = character(),
  submission_status = character(), payload_hash = character(), stringsAsFactors = FALSE)

#' Workbook and CSV export schemas
#' @return A named list of zero-row data frames, in export column order.
#' @export
export_schema <- function() {
  attach <- function(x) { x$event_id <- character(); x$submitted_at <- character(); x }
  list(Events = empty_event(), Visual_Observations = attach(empty_observations()),
    Oyster_Samples = attach(empty_oyster_samples()), Oyster_Measurements = attach(empty_oyster_measurements()),
    Species_Observations = attach(empty_species_observations()), Structural_Observations = attach(empty_structural_observations()))
}

prepare_exports <- function(payload) {
  expected <- c("event", "visual_observations", "oyster_samples", "oyster_measurements", "species_observations", "structural_observations")
  if (!is.list(payload) || !identical(names(payload), expected)) stop("Invalid finalized event.")
  tables <- payload
  schema <- export_schema()
  names(tables) <- names(schema)
  validate_submission(tables)
  tables$Events$submission_status <- "finalized"
  tables$Events$payload_hash <- ""
  for (name in names(tables)) {
    if (!nrow(tables[[name]])) tables[[name]] <- schema[[name]]
    if (!identical(names(tables[[name]]), names(schema[[name]]))) stop(paste("Invalid column order for", name))
  }
  tables$Events$payload_hash <- digest::digest(as.character(jsonlite::toJSON(tables,
    dataframe = "rows", auto_unbox = TRUE, na = "null", null = "null", digits = NA)),
    algo = "sha256", serialize = FALSE)
  tables
}

event_filename_prefix <- function(tables) {
  event <- tables$Events
  site <- gsub("[^A-Za-z0-9_-]+", "_", event$site)
  site <- substr(site, 1L, 60L)
  paste0(event$monitoring_date, "_", site, "_", event$event_id)
}

export_filename <- function(tables, name) {
  stopifnot(name %in% names(export_schema()))
  paste0(event_filename_prefix(tables), "_", tolower(name), ".csv")
}

workbook_filename <- function(tables) paste0(event_filename_prefix(tables), ".xlsx")

write_event_workbook <- function(tables, path) {
  schema <- export_schema()
  if (!identical(names(tables), names(schema))) stop("The event workbook must contain all six standard sheets.")
  for (name in names(schema)) {
    if (!identical(names(tables[[name]]), names(schema[[name]]))) stop(paste("Invalid workbook columns for", name))
  }
  writexl::write_xlsx(tables, path = path, col_names = TRUE, format_headers = TRUE)
  invisible(path)
}

write_export_csv <- function(data, path) {
  utils::write.csv(data, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  invisible(path)
}
