test_that("finalized exports preserve relationships and stable IDs without a backend", {
  withr::local_envvar(c(STORAGE_BACKEND = "google_sheets", APP_ENV = "production",
    GOOGLE_SHEET_ID = NA, GOOGLE_SERVICE_ACCOUNT_JSON = NA, GOOGLE_SERVICE_ACCOUNT_FILE = NA))
  payload <- fixture_payload()
  tables <- prepare_exports(payload)
  expect_identical(tables, prepare_exports(payload))
  expect_identical(tables$Events$event_id, payload$event$event_id)
  expect_identical(tables$Events$submission_status, "finalized")
  expect_identical(tables$Visual_Observations$event_id, tables$Events$event_id)
  expect_identical(names(tables), names(export_schema()))
  expect_s3_class(run_app(), "shiny.appobj")
})

test_that("each data type exports a correctly quoted UTF-8 CSV, including empty tables", {
  payload <- fixture_payload()
  payload$visual_observations$notes <- 'First note; second note, "quoted"\nAnother line'
  tables <- prepare_exports(payload)
  root <- tempfile(); dir.create(root)
  for (name in names(tables)) {
    path <- file.path(root, export_filename(tables, name))
    write_export_csv(tables[[name]], path)
    data <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
    expect_identical(names(data), names(export_schema()[[name]]))
    expect_equal(nrow(data), nrow(tables[[name]]))
    if (name == "Visual_Observations") expect_identical(data$notes, payload$visual_observations$notes)
  }
  expect_length(list.files(root), 6)
})

test_that("CSV filenames are safe and repeated downloads describe the same event", {
  payload <- fixture_payload()
  payload$event$site <- "Reef / A: West"
  tables <- prepare_exports(payload)
  filename <- export_filename(tables, "Events")
  expect_false(grepl("[/\\\\:]", filename))
  expect_match(filename, tables$Events$event_id, fixed = TRUE)
  expect_identical(filename, export_filename(tables, "Events"))
})
