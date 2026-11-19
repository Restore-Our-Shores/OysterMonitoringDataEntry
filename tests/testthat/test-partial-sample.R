test_that("a sample with three shells stages and passes linked submission validation", {
  shiny::testServer(mod_measured_server, args = list(id = "measured"), {
    session$setInputs(module_number = "M1", transect_point = "W", total_oysters = 3,
      mortality_boxes = NA_real_, oysters_through_unit = NA_real_, bridging_within_unit = NA_real_,
      volume_gallons = NA_real_, anoxic_shell_percent = NA_real_, fouling_load = "", notes = "First note; second note")
    for (i in seq_len(3)) session$setInputs(shell_height_mm = 20 + i, add_measurement = i)
    session$setInputs(add_sample = 1)
    expect_equal(nrow(samples()), 1)
    expect_identical(measurements()$oyster_number, 1:3)
    expect_equal(measurements()$shell_height_mm, 21:23)
    expect_identical(samples()$notes, "First note; second note")
    tables <- fixture_tables()
    attach <- function(x) {
      x$event_id <- tables$Events$event_id
      x$submitted_at <- tables$Events$submitted_at
      x
    }
    tables$Oyster_Samples <- attach(samples())
    tables$Oyster_Measurements <- attach(measurements())
    tables$Species_Observations <- attach(species())
    expect_silent(validate_submission(tables))
    tables$Oyster_Measurements$oyster_number[3] <- 2L
    expect_error(validate_submission(tables), "consecutive whole numbers")
  })
})
