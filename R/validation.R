is_blank <- function(x) {
  is.null(x) || length(x) == 0 || is.na(x) || !nzchar(trimws(as.character(x)))
}

validate_event <- function(event) {
  errors <- character()
  if (is_blank(event$monitoring_date)) errors <- c(errors, "Monitoring date is required.")
  if (is_blank(event$project)) errors <- c(errors, "Project is required.")
  if (is_blank(event$site)) errors <- c(errors, "Reef site is required.")
  if (is_blank(event$observers)) errors <- c(errors, "At least one observer is required.")
  errors
}

validate_observation <- function(obs) {
  errors <- character()
  warnings <- character()
  if (is_blank(obs$module_number)) errors <- c(errors, "Module number is required.")
  if (is_blank(obs$transect_point)) errors <- c(errors, "Transect point is required.")
  if (is_blank(obs$reef_type)) errors <- c(errors, "Reef type is required.")

  counts <- unlist(obs[names(COVER_FIELDS)], use.names = TRUE)
  if (any(is.na(counts))) {
    errors <- c(errors, "All five cover counts are required.")
  } else {
    if (any(counts < 0 | counts > 50)) errors <- c(errors, "Cover counts must be between 0 and 50.")
    if (sum(counts) != 50) {
      warnings <- c(warnings, sprintf("Cover counts total %s rather than 50. Confirm this before adding the observation.", sum(counts)))
    }
  }

  numeric_values <- unlist(obs[c(
    "depth_waterward_cm", "depth_top_cm", "depth_shoreward_cm",
    "sediment_waterward_cm", "sediment_top_cm", "sediment_shoreward_cm",
    "visible_live_oysters_1", "visible_live_oysters_2"
  )], use.names = FALSE)
  if (any(!is.na(numeric_values) & numeric_values < 0)) errors <- c(errors, "Measurements and counts cannot be negative.")
  list(errors = unique(errors), warnings = unique(warnings))
}

validate_oyster_sample <- function(sample, sizes) {
  errors <- character()
  if (is_blank(sample$module_number)) errors <- c(errors, "Module number is required.")
  if (is_blank(sample$transect_point)) errors <- c(errors, "Transect point is required.")
  if (length(sizes) != 50L || any(is.na(sizes))) errors <- c(errors, "All 50 shell sizes are required.")
  if (any(!is.na(sizes) & sizes <= 0)) errors <- c(errors, "Shell sizes must be greater than 0 mm.")
  numeric_values <- unlist(sample[c("total_oysters", "mortality_boxes", "oysters_through_unit", "bridging_within_unit", "volume_gallons", "anoxic_shell_percent")], use.names = FALSE)
  if (any(!is.na(numeric_values) & numeric_values < 0)) errors <- c(errors, "Counts, volume, and percentages cannot be negative.")
  if (!is.na(sample$anoxic_shell_percent) && sample$anoxic_shell_percent > 100) errors <- c(errors, "Anoxic shell percentage cannot exceed 100.")
  if (!is.na(sample$total_oysters) && sample$total_oysters < 50) errors <- c(errors, "Total oysters cannot be less than the 50 measured oysters.")
  unique(errors)
}

validate_structural_observation <- function(obs) {
  errors <- character()
  if (is_blank(obs$module_number)) errors <- c(errors, "Module number is required.")
  if (is_blank(obs$transect_point)) errors <- c(errors, "Transect point is required.")
  if (is_blank(obs$structure_type)) errors <- c(errors, "Structure type is required.")
  values <- unlist(obs[grep("^(depth|sediment)_", names(obs), value = TRUE)], use.names = FALSE)
  if (any(!is.na(values) & values < 0)) errors <- c(errors, "Depth and sediment measurements cannot be negative.")
  unique(errors)
}

new_uuid <- function() {
  if (requireNamespace("uuid", quietly = TRUE)) return(uuid::UUIDgenerate())
  paste0(format(Sys.time(), "%Y%m%d%H%M%OS6"), "-", sprintf("%08x", sample.int(.Machine$integer.max, 1)))
}
