# Restore Our Shores — Oyster Reef Monitoring

`rosoyster` is a golem/Shiny R package for field entry, review and Excel workbook download of oyster reef monitoring events. Version 0.4.1 uses a download-only workflow and requires no Google account, spreadsheet, credentials or storage backend.

## Run locally

Use R 4.5.1 or a compatible newer R release. From the project directory:

```r
install.packages("renv") # first setup only
renv::restore()
golem::run_dev()
```

The standard development command uses `inst/golem-config.yml`. You can also run `source("dev/run_dev.R")` directly. An installed package can be launched with `rosoyster::run_app()`. The root `app.R` loads the package sources for deployment.

## Review and download

1. Enter event details and stage visual observations, shell samples and structural observations. Shell samples accept 1 to 50 measurements. Notes can be separated with semicolons.
2. Open **Review & Download**. All six data types have full-data views, including every individual shell measurement and associated-species record.
3. Select **Finalize event**. Validation runs and the event is frozen with a stable Event ID. Entered records remain visible.
4. Select **Download event workbook (.xlsx)** to save one file containing all six data types. The filename includes the monitoring date, site and Event ID. Optional individual CSV downloads are in a collapsed section.
5. Select **Return to editing** to revise the records, then finalize and download the revised workbook again. A revised finalization gets a new Event ID; repeated downloads of the same finalized event retain its ID and content.

The six sheets are Events, Visual_Observations, Oyster_Samples, Oyster_Measurements, Species_Observations and Structural_Observations. Shared Event IDs and sample IDs link the sheets. Every workbook includes all six sheets, even when some have only headers. Column names start in row 1 and stay consistent for future database imports. `export_schema()` is the canonical schema.

**Save location:** **Choose save location** opens a Save As picker in supported desktop browsers over HTTPS or localhost. The workbook download button works through normal browser download controls in other browsers; configure the browser to ask where to save the file when needed. The app cannot choose a directory on a user's computer through a server-side path selector.

No finalized data is written to a database or permanent server file. Download the workbook before closing the application.

Draft and backup controls and browser draft persistence are currently disabled. Keep the workbook before closing or refreshing the app.

## Checks

```powershell
Rscript --vanilla scripts/check.R
node --test tests/js/form-state.test.cjs tests/js/workbook-downloads.test.cjs
Rscript --vanilla scripts/build_and_check.R
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for deployment and browser save behavior, and [DEPLOYMENT_TEST_RESULTS.md](DEPLOYMENT_TEST_RESULTS.md) for acceptance results and repeatable browser tests.
