TRANSECT_POINTS <- c("Waterward" = "W", "Top" = "T", "Shoreward" = "S")
REEF_TYPES <- c("Bag", "Gabion", "Corral", "Other")
COVER_FIELDS <- c(
  live_oysters_count = "Live oysters",
  sav_count = "SAV / algae",
  fouling_count = "Fouling organisms",
  substrate_count = "Bare substrate",
  sediment_count = "Sediment"
)

empty_observations <- function() {
  data.frame(
    observation_id = character(),
    module_number = character(),
    transect_point = character(),
    reef_type = character(),
    live_oysters_count = integer(),
    sav_count = integer(),
    fouling_count = integer(),
    substrate_count = integer(),
    sediment_count = integer(),
    depth_waterward_cm = numeric(),
    depth_top_cm = numeric(),
    depth_shoreward_cm = numeric(),
    sediment_waterward_cm = numeric(),
    sediment_top_cm = numeric(),
    sediment_shoreward_cm = numeric(),
    visible_live_oysters_1 = integer(),
    visible_live_oysters_2 = integer(),
    notes = character(),
    stringsAsFactors = FALSE
  )
}

