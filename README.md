# Restore Our Shores — Oyster Reef Monitoring

First-draft R Shiny data-entry application for ECZF Restore Our Shores oyster reef monitoring.

## Current scope

The prototype implements the **Visual (Edit)** protocol from `BZ Oyster Monitoring Sheets.xlsx`:

- Shared monitoring-event metadata
- Repeatable module/transect observations
- Quadrat cover counts out of 50
- Depth and sediment-accrual measurements
- Visible-live-oyster counts and notes
- Review, validation, and submission receipt
- Stable event and observation UUIDs

Detailed 50-oyster sampling and corral/bag/gabion structural monitoring are intentionally deferred to later modules.

## Run locally

From the project directory:

```r
shiny::runApp()
```

Development submissions default to:

- `data/events.csv`
- `data/visual_observations.csv`

These files are ignored by Git.

## Google Sheets configuration

Create a Google spreadsheet containing tabs named exactly:

- `Events`
- `Visual_Observations`

Share that spreadsheet with the Google service account. Configure these environment variables in the deployment platform:

```text
STORAGE_BACKEND=google_sheets
GOOGLE_SHEET_ID=<spreadsheet-id>
GOOGLE_SERVICE_ACCOUNT_JSON=<complete service-account JSON document>
```

For local development, `GOOGLE_SERVICE_ACCOUNT_FILE` can instead point to a credential JSON file outside the repository. Never commit credential files.

The first row of each Google Sheet tab must match the columns produced by the app. The simplest setup is to make a local test submission and use the resulting CSV headers when creating the tabs.

## Connect Cloud deployment

1. Commit the application to a GitHub repository.
2. Create a Shiny deployment in Posit Connect Cloud.
3. Add the three variables above as secret/environment variables.
4. Deploy first against a test spreadsheet owned by the project.
5. Verify one complete event before using the production spreadsheet.

## Checks

```powershell
Rscript scripts/smoke_test.R
```

