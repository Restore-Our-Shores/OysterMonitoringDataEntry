test_that("draft backups preserve partial measurements and frozen submission IDs", {
  p <- fixture_payload()
  state <- list(version = 1L, inputs = list("event-site" = "Test reef"),
    visual = p$visual_observations[names(empty_observations())],
    measured = list(samples = empty_oyster_samples(), measurements = empty_oyster_measurements(),
      species = empty_species_observations(), sizes = c(20, 21, 22)),
    structural = empty_structural_observations(), submission = p)
  restored <- decode_draft(encode_draft(state))
  expect_identical(restored, state)
  # Shiny embeds objects of class "json" verbatim; browser storage needs a string.
  wire <- jsonlite::fromJSON(jsonlite::toJSON(list(text = encode_draft(state)),
    auto_unbox = TRUE, json_verbatim = TRUE))
  expect_type(wire$text, "character")
  expect_identical(decode_draft(wire$text), state)
  expect_identical(restored$submission$event$event_id, p$event$event_id)
  legacy <- state
  legacy$visual$module_type <- NULL
  expect_identical(decode_draft(encode_draft(legacy))$visual$module_type, "")
  legacy$submission <- NULL
  upgraded <- decode_draft(encode_draft(legacy))
  expect_identical(upgraded$visual$module_type, "")
  expect_identical(upgraded$visual$observation_id, state$visual$observation_id)
  missing_numbers <- state
  missing_numbers$visual$depth_waterward_cm <- NA
  missing_numbers$visual$visible_live_oysters_1 <- NA
  recovered <- decode_draft(encode_draft(missing_numbers))
  expect_identical(recovered$visual$depth_waterward_cm, NA_real_)
  expect_identical(recovered$visual$visible_live_oysters_1, NA_integer_)
  state$version <- 2L
  expect_error(decode_draft(encode_draft(state)), "Unsupported")
})

test_that("visual warning confirmation stages one observation", {
  shiny::testServer(mod_visual_server, args = list(id = "visual"), {
    session$setInputs(module_number = "M1", transect_point = "W", reef_type = "Bag",
      live_oysters_count = 9, sav_count = 10, fouling_count = 10, substrate_count = 10, sediment_count = 10,
      depth_waterward_cm = NA_real_, depth_top_cm = NA_real_, depth_shoreward_cm = NA_real_,
      sediment_waterward_cm = NA_real_, sediment_top_cm = NA_real_, sediment_shoreward_cm = NA_real_,
      visible_live_oysters_1 = NA_real_, visible_live_oysters_2 = NA_real_, notes = "")
    session$setInputs(add_observation = 1)
    expect_equal(nrow(observations()), 0)
    session$setInputs(add_observation = 2)
    expect_equal(nrow(observations()), 1)
  })
})
