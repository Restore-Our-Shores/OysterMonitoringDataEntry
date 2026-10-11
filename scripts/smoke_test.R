source("R/constants.R")
source("R/validation.R")
source("R/storage.R")

stopifnot(length(validate_event(list(
  monitoring_date = "2026-10-11",
  project = "BZ Oyster Monitoring",
  site = "Test Reef",
  observers = "Test Observer"
))) == 0)

obs <- as.list(empty_observations()[1, ])
obs$module_number <- "M-01"
obs$transect_point <- "W"
obs$reef_type <- "Bag"
obs$live_oysters_count <- 10L
obs$sav_count <- 10L
obs$fouling_count <- 10L
obs$substrate_count <- 10L
obs$sediment_count <- 10L
result <- validate_observation(obs)
stopifnot(length(result$errors) == 0, length(result$warnings) == 0)

files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(c("app.R", files), function(path) parse(file = path)))
cat("Smoke tests passed.\n")

