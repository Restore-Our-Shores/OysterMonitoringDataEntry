source("scripts/project_library.R")
pkgload::load_all(quiet = TRUE)
report <- jsonlite::fromJSON("tmp/browser-acceptance-report.json")
read_tables <- function(path) {
  stopifnot(identical(readxl::excel_sheets(path), names(export_schema())))
  tables <- stats::setNames(lapply(names(export_schema()), function(name) {
    data <- readxl::read_xlsx(path, sheet = name, col_types = "text")
    stopifnot(identical(names(data), names(export_schema()[[name]])))
    data
  }), names(export_schema()))
  for (table in tables) if (nrow(table)) stopifnot(all(table$event_id == tables$Events$event_id))
  tables
}
original <- read_tables(report$workbookFiles[[1]])
stopifnot(identical(vapply(original, nrow, integer(1)), c(Events = 1L, Visual_Observations = 1L,
  Oyster_Samples = 1L, Oyster_Measurements = 3L, Species_Observations = 33L, Structural_Observations = 1L)),
  original$Events$event_id == report$firstReceipt,
  original$Visual_Observations$module_type == "bags",
  as.numeric(original$Oyster_Samples$total_oysters) == 3,
  identical(as.integer(original$Oyster_Measurements$oyster_number), 1:3),
  identical(as.numeric(original$Oyster_Measurements$shell_height_mm), as.numeric(21:23)),
  all(original$Oyster_Measurements$sample_id == original$Oyster_Samples$sample_id),
  all(original$Species_Observations$sample_id == original$Oyster_Samples$sample_id))
for (path in report$workbookFiles[-1]) stopifnot(identical(read_tables(path), original))
mobile <- read_tables(report$mobileWorkbook)
stopifnot(mobile$Events$event_id == report$mobileReceipt, mobile$Events$site == "Mobile Synthetic Reef")
for (i in seq_along(report$concurrentWorkbooks)) {
  tables <- read_tables(report$concurrentWorkbooks[[i]])
  stopifnot(tables$Events$event_id == report$concurrentReceipts[[i]],
    tables$Events$site == paste("Synthetic Concurrent Reef", i),
    nrow(tables$Oyster_Measurements) == 0L)
}
revised <- read_tables(report$revisedWorkbook)
stopifnot(revised$Events$event_id == report$revisedReceipt,
  revised$Events$event_id != report$firstReceipt, revised$Events$site == "Revised Synthetic Reef")
cat("Downloaded workbooks verified: six exact sheets/headers, row counts, text IDs, sample links, repeated downloads, mobile events, independent events and revisions.\n")
