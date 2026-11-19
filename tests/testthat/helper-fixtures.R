fixture_payload <- function() {
  e <- list(event_id = new_uuid(), monitoring_date = "2026-11-16", monitoring_time = "09:30",
    project = "Test project", site = "Test reef", observers = "Test observer", water_temperature_c = 22,
    salinity_ppt = 25, event_notes = "Test only", protocol = "oyster_reef_monitoring", submitted_at = "2026-11-16T09:30:00-0500")
  v <- as.list(empty_observations()[1, ])
  v$observation_id <- new_uuid(); v$module_number <- "M1"; v$transect_point <- "W"; v$reef_type <- "Bag"
  for (name in names(COVER_FIELDS)) v[[name]] <- 10
  v$notes <- "=A1"
  v$event_id <- e$event_id; v$submitted_at <- e$submitted_at
  list(event = as.data.frame(e, stringsAsFactors = FALSE), visual_observations = as.data.frame(v, stringsAsFactors = FALSE),
    oyster_samples = empty_oyster_samples(), oyster_measurements = empty_oyster_measurements(),
    species_observations = empty_species_observations(), structural_observations = empty_structural_observations())
}

fixture_tables <- function(payload = fixture_payload()) {
  names(payload) <- names(export_schema())
  payload
}
