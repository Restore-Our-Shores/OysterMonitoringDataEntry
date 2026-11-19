test_that("an event workbook has exactly six standard sheets, including header-only sheets", {
  tables <- prepare_exports(fixture_payload())
  path <- tempfile(fileext = ".xlsx")
  write_event_workbook(tables, path)
  expect_identical(readxl::excel_sheets(path), names(export_schema()))
  for (name in names(tables)) {
    data <- suppressMessages(readxl::read_xlsx(path, sheet = name, col_types = "text"))
    expect_identical(names(data), names(tables[[name]]))
    expect_equal(nrow(data), nrow(tables[[name]]))
  }
  expect_identical(readxl::read_xlsx(path, sheet = "Events")$event_id, tables$Events$event_id)
  expect_match(workbook_filename(tables), "[.]xlsx$")
  expect_match(workbook_filename(tables), tables$Events$event_id, fixed = TRUE)
})

test_that("workbooks preserve literal notes and text identifiers without adding formulas", {
  payload <- fixture_payload()
  payload$visual_observations$module_number <- "001"
  payload$visual_observations$notes <- '=A1; "quoted", first note\nSecond note'
  tables <- prepare_exports(payload)
  path <- tempfile(fileext = ".xlsx")
  write_event_workbook(tables, path)
  data <- readxl::read_xlsx(path, sheet = "Visual_Observations")
  expect_identical(data$module_number, "001")
  expect_identical(data$notes, payload$visual_observations$notes)
  expect_equal(data$live_oysters_count, 10)
  archive <- tempfile(); dir.create(archive)
  utils::unzip(path, exdir = archive)
  xml <- paste(readLines(file.path(archive, "xl", "worksheets", "sheet2.xml"), warn = FALSE), collapse = "")
  expect_false(grepl("<f[ >]", xml))
})

test_that("repeated workbook downloads retain stable table contents", {
  tables <- prepare_exports(fixture_payload())
  first <- tempfile(fileext = ".xlsx"); second <- tempfile(fileext = ".xlsx")
  write_event_workbook(tables, first); write_event_workbook(tables, second)
  for (name in names(tables)) expect_identical(
    readxl::read_xlsx(first, sheet = name, col_types = "text"),
    readxl::read_xlsx(second, sheet = name, col_types = "text"))
  expect_error(write_event_workbook(tables[-1], tempfile(fileext = ".xlsx")), "six standard sheets")
})
