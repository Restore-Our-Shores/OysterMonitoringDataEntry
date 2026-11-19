# Deployment and maintainer handoff

## Version 0.4.1: one workbook per event

Deploy the complete package sources with root app.R. The application creates one Excel workbook per finalized sampling event. It does not connect to Google Sheets or write permanent submission files. No backend credentials or environment variables are required. Obsolete backend/Google variables can be removed from hosting settings.

The maintaining group should own the deployment and repository. Configure app access for the intended monitoring team. Replace maintainer@example.org in DESCRIPTION with the actual contact before handoff, and confirm ownership/redistribution terms.

## Build and deploy

```r
renv::restore()
```

```powershell
Rscript --vanilla scripts/check.R
Rscript --vanilla scripts/check_deployment.R
node --test tests/js/form-state.test.cjs tests/js/workbook-downloads.test.cjs
Rscript --vanilla scripts/build_and_check.R
```

For Posit Connect or shinyapps.io:

```r
source("scripts/deployment_files.R")
rsconnect::deployApp(appDir = ".", appPrimaryDoc = "app.R", appFiles = deployment_files())
```

For Git-backed deployment, generate the manifest without publishing:

```r
Sys.setenv(WRITE_DEPLOY_MANIFEST = "true")
source("scripts/prepare_deploy.R")
```

Commit the manifest, sources and lockfile. Configure the host to run app.R. The explicit bundle excludes field data, test artifacts, credentials and the installed library. writexl generates workbooks on the server; Microsoft Excel is not required on the server or to download the file. golem::run_dev() uses inst/golem-config.yml for development.

### Connect Cloud: missing dependency file

If publishing reports that `manifest.json` or `renv.lock` is required, check the Git commit shown in the publish log. Connect Cloud reads the committed files from GitHub; files that exist only on your computer are unavailable to the publisher. The failed deployment of commit `07721b3` predates both dependency files.

Keep `manifest.json` and `renv.lock` beside the root `app.R`, and commit and push them together with the application sources they describe. The current app also requires `DESCRIPTION`, `NAMESPACE`, `LICENSE`, `R/`, `inst/` and `man/`; publishing only the dependency files with the old app sources does not publish the current application. Review the Git changes before committing. `.gitignore` must retain its `!manifest.json` exception because it otherwise ignores JSON files.

After pushing, republish the updated branch with `app.R` as its primary file. Confirm the new publish log names the new commit rather than `07721b3`. Connect Cloud gives `manifest.json` precedence when both dependency files exist, so regenerate the manifest after changing application files or dependencies.

The deployment check verifies manifest file checksums, locked package versions and app startup from an isolated copy of the published files. `.gitattributes` keeps text files in LF format on Windows and Linux so manifest checksums remain consistent after Git checkout. GitHub Actions runs this check on Linux. R 4.5.1 is specified in both dependency files and the CI workflow; it is within Connect Cloud's supported R versions.

For Connect Cloud, select repository `Restore-Our-Shores/OysterMonitoringDataEntry`, branch `main`, and primary file `app.R` in the repository root. Automatic publishing requires that the Connect Cloud GitHub App has access to this repository and that republishing on push is enabled. Repository checks do not confirm the private hosting settings or a successful hosted deployment; inspect the new publish log and test the hosted workbook download after publishing.

## Workbook contract

Every event produces one .xlsx file named with the monitoring date, site and Event ID. It has exactly six sheets, in this order:

1. Events
2. Visual_Observations
3. Oyster_Samples
4. Oyster_Measurements
5. Species_Observations
6. Structural_Observations

Each sheet represents one future database table. Headers start in row 1 and use the existing stable column names; there are no cover sheets, formulas, totals or decorative rows inside the datasets. Unused sheets still contain their headers. export_schema() defines the expected columns and R types. Use explicit types when importing to the future database, especially for empty columns.

UUIDs and module identifiers are stored as text. Numeric measurements remain numeric, presence/absence remains logical, and missing values are blank. Dates remain ISO date strings. event_id links every observation to Events; sample_id links shell measurements and species to Oyster_Samples. The historical submitted_at column records finalization time; submission_status is finalized. A content hash identifies the finalized data.

Repeated downloads retain the same data and Event ID. Returning to editing preserves entered records; finalizing a revision creates a new Event ID and filename. When combining event files, use IDs to detect repeated imports and choose the intended revision instead of importing every file indiscriminately.

## Save workflow

After finalizing, users can inspect all data in the six on-screen tabs and select Download event workbook (.xlsx). The browser controls the save folder. Choose save location uses showSaveFilePicker where supported on desktop HTTPS/localhost, suggesting the event filename. If that API is unavailable, the normal download button remains available. Test cancellation and actual browser permissions on the hosted app.

Optional individual CSV downloads remain under a collapsed section for specialist imports. The main workflow downloads one workbook, rather than six files. No permanent copy is saved on the hosting server: users must retain the workbook before closing or refreshing. Draft/backup controls and browser draft persistence are currently disabled; existing browser backups are left untouched.

## Hosted acceptance

1. Finalize a complete event with a short shell sample, visual/module type and structural records. Inspect the six views and download one workbook.
2. Open the workbook and verify exact sheet names, column headers, row counts, notes, dates, shell numbering and shared IDs. Also verify an event that leaves some sheets empty.
3. Download twice; verify the same contents and Event ID. Revise and re-finalize; verify the new filename/ID and revised contents.
4. Exercise Choose save location in a supported desktop browser and cancel the dialog once. Test the ordinary download and mobile save controls on the team's actual devices.
5. Verify independent users produce separate event workbooks. Keep optional CSV downloads available for workflows that need them.

Dependency updates should be followed by scripts/lock_dependencies.R, checks, manifest regeneration and hosted acceptance. Keep the prior commit for rollback. Historical local submission files and already-downloaded CSVs are left untouched.
