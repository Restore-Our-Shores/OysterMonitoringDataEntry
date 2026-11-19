test_that("finalization retains all records for viewing and repeated exports until editing resumes", {
  shiny::testServer(app_server, {
    session$setInputs(draft_found = list(text = "", nonce = 1))
    values <- list(
      "event-monitoring_date" = as.Date("2026-11-16"), "event-monitoring_time" = "09:30",
      "event-project" = "Test", "event-site" = "Test reef", "event-observers" = "Test observer",
      "event-water_temperature_c" = NULL, "event-salinity_ppt" = NULL, "event-event_notes" = "",
      "visual-module_number" = "M1", "visual-transect_point" = "W", "visual-reef_type" = "Bag", "visual-module_type" = "bags",
      "visual-live_oysters_count" = 10, "visual-sav_count" = 10, "visual-fouling_count" = 10,
      "visual-substrate_count" = 10, "visual-sediment_count" = 10,
      "visual-notes" = "First note; second note")
    do.call(session$setInputs, values)
    session$setInputs(`visual-add_observation` = 1)
    session$setInputs(`review-submit` = 1)
    finalized <- submission()
    expect_true(valid_uuid(finalized$event$event_id))
    expect_equal(nrow(visual$observations()), 1)
    original <- prepare_exports(finalized)
    session$setInputs(`review-submit` = 2)
    expect_identical(submission(), finalized)
    session$setInputs(`event-site` = "Changed form")
    expect_identical(prepare_exports(submission()), original)
    restored <- decode_draft(encode_draft(draft_state(input, visual, measured, structural, submission)))
    expect_identical(prepare_exports(restored$submission), original)
    session$setInputs(`review-edit` = 1)
    expect_null(submission())
    expect_equal(nrow(visual$observations()), 1)
    session$setInputs(`review-submit` = 3)
    expect_identical(submission()$event$site, "Changed form")
    expect_false(identical(submission()$event$event_id, finalized$event$event_id))
  })
})

test_that("draft imports cannot replay action-button inputs", {
  state <- list(version = 1L, inputs = list("review-submit" = 1),
    visual = empty_observations(), measured = list(samples = empty_oyster_samples(),
      measurements = empty_oyster_measurements(), species = empty_species_observations(), sizes = numeric()),
    structural = empty_structural_observations(), submission = NULL)
  expect_error(decode_draft(encode_draft(state)), "unsupported form controls")
})
