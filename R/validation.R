is_blank <- function(x) {
  is.null(x) || length(x) != 1L || is.na(x) || !nzchar(trimws(as.character(x)))
}

valid_number <- function(x, minimum = 0, maximum = Inf, integer = FALSE, required = FALSE) {
  if (is.null(x) || length(x) != 1L || is.na(x)) return(!required)
  is.numeric(x) && is.finite(x) && x >= minimum && x <= maximum && (!integer || x == floor(x))
}

validate_event <- function(event) {
  errors <- character()
  for (field in c("monitoring_date", "project", "site", "observers")) {
    if (is_blank(event[[field]])) errors <- c(errors, paste(gsub("_", " ", field), "is required."))
  }
  if (!is_blank(event$monitoring_date) && (is.na(suppressWarnings(as.Date(event$monitoring_date, format = "%Y-%m-%d"))) ||
      !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", event$monitoring_date))) errors <- c(errors, "Enter a valid monitoring date.")
  if (!is_blank(event$monitoring_time) && !grepl("^([01][0-9]|2[0-3]):[0-5][0-9]$", event$monitoring_time)) errors <- c(errors, "Time must use HH:MM (24-hour time).")
  if (!valid_number(event$water_temperature_c, -5, 50)) errors <- c(errors, "Water temperature must be between -5 and 50 C.")
  if (!valid_number(event$salinity_ppt, 0, 60)) errors <- c(errors, "Salinity must be between 0 and 60 ppt.")
  unique(errors)
}

validate_location <- function(obs) {
  errors <- character()
  if (is_blank(obs$module_number)) errors <- c(errors, "Module number is required.")
  if (is_blank(obs$transect_point) || !obs$transect_point %in% unname(TRANSECT_POINTS)) errors <- c(errors, "Select a valid transect point.")
  errors
}

validate_observation <- function(obs) {
  errors <- validate_location(obs)
  warnings <- character()
  if (is_blank(obs$reef_type) || !obs$reef_type %in% REEF_TYPES) errors <- c(errors, "Select a valid reef type.")
  if (!is_blank(obs$module_type) && !obs$module_type %in% MODULE_TYPES) errors <- c(errors, "Select bags or gabion for module type.")
  counts <- obs[names(COVER_FIELDS)]
  if (!all(vapply(counts, valid_number, logical(1), maximum = 50, integer = TRUE, required = TRUE))) {
    errors <- c(errors, "All five cover counts must be whole numbers between 0 and 50.")
  } else if (sum(unlist(counts)) != 50) {
    warnings <- sprintf("Cover counts total %s rather than 50. Confirm this before adding the observation.", sum(unlist(counts)))
  }
  measures <- obs[grep("^(depth|sediment)_.*cm$", names(obs), value = TRUE)]
  if (!all(vapply(measures, valid_number, logical(1)))) errors <- c(errors, "Measurements must be finite and nonnegative.")
  counts <- obs[c("visible_live_oysters_1", "visible_live_oysters_2")]
  if (!all(vapply(counts, valid_number, logical(1), integer = TRUE))) errors <- c(errors, "Oyster counts must be nonnegative whole numbers.")
  list(errors = unique(errors), warnings = warnings)
}

validate_oyster_sample <- function(sample, sizes) {
  errors <- validate_location(sample)
  if (length(sizes) < 1L || length(sizes) > 50L || !is.numeric(sizes) || any(!is.finite(sizes) | sizes <= 0)) errors <- c(errors, "Enter 1 to 50 finite shell heights greater than 0 mm.")
  if (!valid_number(sample$total_oysters, max(1L, length(sizes)), integer = TRUE, required = TRUE)) errors <- c(errors, "Total oysters is required and must be a whole number at least as large as the number of measured shells.")
  counts <- sample[c("mortality_boxes", "oysters_through_unit", "bridging_within_unit")]
  if (!all(vapply(counts, valid_number, logical(1), integer = TRUE))) errors <- c(errors, "Sample counts must be nonnegative whole numbers.")
  if (!valid_number(sample$volume_gallons)) errors <- c(errors, "Volume must be finite and nonnegative.")
  if (!valid_number(sample$anoxic_shell_percent, 0, 100)) errors <- c(errors, "Anoxic shell percentage must be between 0 and 100.")
  if (!is_blank(sample$fouling_load) && !sample$fouling_load %in% c("Low", "Medium", "High")) errors <- c(errors, "Select a valid fouling load.")
  unique(errors)
}

validate_structural_observation <- function(obs) {
  errors <- validate_location(obs)
  if (is_blank(obs$structure_type) || !obs$structure_type %in% STRUCTURE_TYPES) errors <- c(errors, "Select a valid structure type.")
  values <- obs[grep("^(depth|sediment)_", names(obs), value = TRUE)]
  if (!all(vapply(values, valid_number, logical(1)))) errors <- c(errors, "Depth and sediment measurements must be finite and nonnegative.")
  unique(errors)
}

new_uuid <- function() uuid::UUIDgenerate()
valid_uuid <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && grepl("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", x)

validate_submission <- function(tables) {
  event <- tables$Events
  if (!is.data.frame(event) || nrow(event) != 1L || !valid_uuid(event$event_id)) stop("Invalid monitoring event ID.")
  errors <- validate_event(as.list(event))
  if (sum(vapply(tables[c("Visual_Observations", "Oyster_Samples", "Structural_Observations")], nrow, integer(1))) == 0L) errors <- c(errors, "Add at least one monitoring record.")
  for (name in names(tables)[-1]) {
    rows <- tables[[name]]
    if (nrow(rows) && (!all(rows$event_id == event$event_id) || anyNA(rows$event_id))) errors <- c(errors, "Observation event IDs do not match.")
  }
  validate_rows <- function(rows, fun) {
    unlist(lapply(seq_len(nrow(rows)), function(i) fun(as.list(rows[i, , drop = FALSE]))), use.names = FALSE)
  }
  errors <- c(errors, validate_rows(tables$Visual_Observations, function(x) validate_observation(x)$errors),
    validate_rows(tables$Structural_Observations, validate_structural_observation))
  samples <- tables$Oyster_Samples
  measures <- tables$Oyster_Measurements
  species <- tables$Species_Observations
  for (name in c("Visual_Observations", "Oyster_Samples", "Structural_Observations")) {
    rows <- tables[[name]]
    if (nrow(rows)) {
      ids <- rows[[names(rows)[1]]]
      if (anyDuplicated(ids) || !all(vapply(ids, valid_uuid, logical(1)))) errors <- c(errors, "Observation IDs must be unique UUIDs.")
    }
  }
  if (nrow(measures) && !all(measures$sample_id %in% samples$sample_id)) errors <- c(errors, "Shell measurements refer to an unknown sample.")
  if (nrow(species) && !all(species$sample_id %in% samples$sample_id)) errors <- c(errors, "Species observations refer to an unknown sample.")
  for (i in seq_len(nrow(samples))) {
    sample <- samples[i, , drop = FALSE]
    m <- measures[measures$sample_id == sample$sample_id, , drop = FALSE]
    errors <- c(errors, validate_oyster_sample(as.list(sample), m$shell_height_mm))
    if (anyNA(m$oyster_number) || !is.numeric(m$oyster_number) ||
        !identical(as.numeric(sort(m$oyster_number)), as.numeric(seq_len(nrow(m))))) errors <- c(errors, "Shell measurement numbers must be consecutive whole numbers starting at 1.")
    s <- species[species$sample_id == sample$sample_id, , drop = FALSE]
    if (anyDuplicated(s$species_code) || !setequal(s$species_code, c(names(COUNT_SPECIES), names(PRESENCE_SPECIES)))) errors <- c(errors, "Each sample must include every associated-species observation once.")
    count_rows <- s$species_code %in% names(COUNT_SPECIES)
    if (!all(vapply(as.list(s$count[count_rows]), valid_number, logical(1), integer = TRUE, required = TRUE))) errors <- c(errors, "Species counts must be nonnegative whole numbers.")
    if (!is.logical(s$present) || anyNA(s$present[!count_rows])) errors <- c(errors, "Species presence must be Yes or No.")
    if (anyNA(s$observation_type) || !all(s$observation_type[count_rows] == "count") ||
        !all(s$observation_type[!count_rows] == "presence")) errors <- c(errors, "Species observation types are invalid.")
  }
  if (length(errors)) stop(paste(unique(errors), collapse = " "))
  invisible(TRUE)
}
