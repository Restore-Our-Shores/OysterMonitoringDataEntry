TRANSECT_POINTS <- c("Waterward" = "W", "Top" = "T", "Shoreward" = "S")
REEF_TYPES <- c("Bag", "Gabion", "Corral", "Other")
STRUCTURE_TYPES <- c("Bag", "Gabion", "Corral")
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

COUNT_SPECIES <- c(flatworms = "Flatworms", crown_conch = "Crown Conch", oyster_drills = "Oyster Drills", boring_sponge_impacted = "Live oysters impacted by boring sponge")

PRESENCE_SPECIES <- c(
  mud_crabs = "Mud crabs", green_porcelain_crabs = "Green porcelain crabs", stone_crabs = "Stone crabs",
  goby = "Goby", blenny = "Blenny", skilletfish = "Skilletfish", oyster_toadfish = "Oyster toadfish",
  snapping_shrimp = "Snapping shrimp", polychaetes = "Polychaetes", amphipods = "Amphipods", isopods = "Isopods",
  ivory_barnacles = "Ivory barnacles", slipper_shells = "Slipper shells", bryozoans = "Bryozoans", tube_worms = "Tube worms",
  sea_squirts = "Sea squirts", anemones = "Anemones", ribbed_mussels = "Ribbed mussels", freshwater_mussels = "Freshwater mussels",
  branching_sponge = "Branching sponge", encrusting_sponge = "Encrusting sponge", boring_sponge = "Boring sponge",
  raspberry_tunicate = "Raspberry tunicate", red_orange_tunicate = "Red/orange tunicate", algae = "Algae",
  hermit_crabs = "Hermit crabs", recent_oyster_box = "Recent oyster box", small_unknown_gastropod = "Small unknown gastropod",
  mangrove_oyster_evidence = "Mangrove oyster evidence"
)

empty_oyster_samples <- function() data.frame(
  sample_id = character(), module_number = character(), transect_point = character(), total_oysters = integer(),
  mortality_boxes = integer(), oysters_through_unit = integer(), bridging_within_unit = integer(), volume_gallons = numeric(),
  anoxic_shell_percent = numeric(), fouling_load = character(), notes = character(), stringsAsFactors = FALSE)

empty_oyster_measurements <- function() data.frame(
  sample_id = character(), oyster_number = integer(), shell_height_mm = numeric(), stringsAsFactors = FALSE)

empty_species_observations <- function() data.frame(
  sample_id = character(), species_code = character(), species_label = character(), observation_type = character(),
  present = logical(), count = integer(), stringsAsFactors = FALSE)

empty_structural_observations <- function() data.frame(
  structural_observation_id = character(), module_number = character(), transect_point = character(), structure_type = character(),
  depth_waterward_sediment_cm = numeric(), depth_waterward_shell_cm = numeric(), depth_top_shell_cm = numeric(),
  depth_shoreward_shell_cm = numeric(), depth_shoreward_sediment_cm = numeric(), sediment_waterward_cm = numeric(),
  sediment_top_cm = numeric(), sediment_shoreward_cm = numeric(), damage_observed = logical(), macroalgae_observed = logical(),
  materials_missing = logical(), notes = character(), stringsAsFactors = FALSE)
