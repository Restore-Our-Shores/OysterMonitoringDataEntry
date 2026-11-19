test_that("invalid and fractional counts are rejected without truncation", {
  p <- fixture_payload()
  obs <- as.list(p$visual_observations)
  obs$live_oysters_count <- 9.5
  expect_match(paste(validate_observation(obs)$errors, collapse = " "), "whole numbers")
  obs$live_oysters_count <- Inf
  expect_gt(length(validate_observation(obs)$errors), 0)
  event <- as.list(p$event); event$salinity_ppt <- 100
  expect_match(paste(validate_event(event), collapse = " "), "Salinity")
  event$monitoring_time <- "25:10"
  expect_match(paste(validate_event(event), collapse = " "), "Time")
  sample <- as.list(empty_oyster_samples()[1, ]); sample$module_number <- "M1"; sample$transect_point <- "W"
  expect_match(paste(validate_oyster_sample(sample, rep(25, 50)), collapse = " "), "Total oysters")
  sample$total_oysters <- 50
  expect_length(validate_oyster_sample(sample, rep(25, 50)), 0)
  sample$total_oysters <- 3
  expect_length(validate_oyster_sample(sample, c(20, 21, 22)), 0)
  expect_gt(length(validate_oyster_sample(sample, numeric())), 0)
  expect_gt(length(validate_oyster_sample(sample, rep(25, 51))), 0)
  expect_gt(length(validate_oyster_sample(sample, rep(25, 4))), 0)
  expect_gt(length(validate_oyster_sample(sample, c(Inf, rep(25, 49)))), 0)
})

test_that("visual module type accepts only the offered choices or a blank", {
  obs <- as.list(fixture_payload()$visual_observations)
  for (type in c("", "bags", "gabion")) {
    obs$module_type <- type
    expect_length(validate_observation(obs)$errors, 0)
  }
  obs$module_type <- "other"
  expect_gt(length(validate_observation(obs)$errors), 0)
})

test_that("submission validation enforces event relationships and UUIDs", {
  tables <- fixture_tables()
  expect_silent(validate_submission(tables))
  tables$Visual_Observations$event_id <- new_uuid()
  expect_error(validate_submission(tables), "do not match")
  tables <- fixture_tables(); tables$Events$event_id <- "../../outside"
  expect_error(validate_submission(tables), "Invalid monitoring event ID")
})
