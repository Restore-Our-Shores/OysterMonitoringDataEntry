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

sample_row <- as.list(empty_oyster_samples()[1, ])
sample_row$module_number <- "M-01"
sample_row$transect_point <- "W"
sample_row$total_oysters <- 50L
stopifnot(length(validate_oyster_sample(sample_row, rep(25, 49))) > 0)
stopifnot(length(validate_oyster_sample(sample_row, rep(25, 50))) == 0)
stopifnot(length(COUNT_SPECIES) == 4L, length(PRESENCE_SPECIES) > 0L)

structural_row <- as.list(empty_structural_observations()[1, ])
structural_row$module_number <- "M-01"
structural_row$transect_point <- "T"
for (structure_type in c("Bag", "Gabion", "Corral")) {
  structural_row$structure_type <- structure_type
  stopifnot(length(validate_structural_observation(structural_row)) == 0)
}

files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(c("app.R", files), function(path) parse(file = path)))
cat("Smoke tests passed.\n")
