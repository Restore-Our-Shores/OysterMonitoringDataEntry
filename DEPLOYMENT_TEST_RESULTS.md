# Workbook workflow test results

## Connect Cloud repository verification — 2026-11-19

- All 114 R assertions and seven JavaScript tests passed again; R CMD check completed with status OK.
- The deployment check passed: all published file checksums match, all 87 manifest package versions match `renv.lock`, and the app starts and renders from an isolated copy of the deployment files.
- Both dependency files specify R 4.5.1 and sit beside the root `app.R`. The regenerated manifest records CRAN repository URLs.
- The package-check script now selects the appropriate R executable for Windows or Linux. GitHub Actions also checks the deployment bundle.
- `.rscignore` no longer excludes the dependency manifest. `.gitattributes` keeps deployment text files in LF format across Windows and Linux.

These checks validate the repository and local deployment bundle. A successful hosted publish, private Connect Cloud configuration, and native Save As permissions require verification on Connect Cloud.

## Previous browser acceptance

Tested 2026-11-17 against rosoyster 0.4.1 with R 4.5.1 and isolated headless Microsoft Edge sessions.

The draft/backup section and saved-draft notices are removed. Browser draft persistence is disabled. Existing browser backups are left untouched, and legacy draft utilities remain unmounted in the source for possible future use.

## Validation

- 114 R assertions pass with no test failures or warnings.
- Seven active JavaScript tests cover entry-form locking and workbook save behavior.
- Browser acceptance covers absence of draft controls with an old browser draft already present, data entry, three-shell samples, notes hints, full-data review, workbook download, repeat downloads, optional CSVs, mobile layout/downloads, independent events and revisions.
- The event workbook retains all six consistently named worksheets, row-1 headers and shared identifiers. Header-only unused sheets remain present.
- Existing browser backup data was verified unchanged by the new workflow.

Native Save As permissions still require a check on the hosted HTTPS application; the automated save-location test fetches a real workbook and writes it to a simulated file handle. No production data was modified.

## Repeat

```powershell
Rscript --vanilla scripts/check.R
Rscript --vanilla scripts/check_deployment.R
node --test tests/js/form-state.test.cjs tests/js/workbook-downloads.test.cjs
Rscript --vanilla scripts/build_and_check.R
```

For browser acceptance, install playwright-core under tmp/browser-testing. Start Rscript --vanilla scripts/run_acceptance_app.R in one terminal, then run node scripts/browser_acceptance.cjs and Rscript --vanilla scripts/verify_acceptance_workbooks.R in another. Test downloads, screenshots and reports are under ignored tmp/.

Users should download the event workbook before closing or refreshing the app. There is no permanent server-side event store and no active draft recovery interface.
