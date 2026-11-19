// Optional end-to-end acceptance test. Install playwright-core under tmp/browser-testing.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {chromium} = require(path.resolve('tmp/browser-testing/node_modules/playwright-core'));
const baseURL = process.env.ACCEPTANCE_URL || 'http://127.0.0.1:8766';
const report = {checks: [], browserErrors: [], failedResponses: []};
const check = name => { report.checks.push(name); console.log('PASS:', name); };
const exportDir = path.resolve('tmp/acceptance-workbooks');
fs.mkdirSync(exportDir, {recursive: true});

(async () => {
  const browser = await chromium.launch({headless: true,
    executablePath: process.env.ACCEPTANCE_BROWSER || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'});
  let debugPage;
  try {
    const context = await browser.newContext({viewport: {width: 1440, height: 1000}, acceptDownloads: true});
    await context.addInitScript(() => {
      try { localStorage.setItem('rosoyster.draft.v1:' + window.location.pathname, 'prior-work'); } catch (_) {}
    });
    const page = await context.newPage();
    debugPage = page;
    page.on('pageerror', error => report.browserErrors.push(error.message));
    page.on('response', response => { if (response.status() >= 400) report.failedResponses.push({url: response.url(), status: response.status()}); });
    const connected = async p => p.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.$socket && Shiny.shinyapp.$socket.readyState === 1);
    const choose = async (p, id, value) => p.locator(`#${id}`).evaluate((el, v) => {
      if (el.selectize) el.selectize.setValue(v); else { el.value = v; el.dispatchEvent(new Event('change', {bubbles: true})); }
    }, value);
    const nav = async (p, value) => {
      const link = p.locator(`#main_nav a[data-value="${value}"]`);
      if (!await link.isVisible()) await p.getByRole('button', {name: 'Toggle navigation'}).click();
      await link.click();
    };
    const reviewTab = async (p, title) => p.locator(`#review-review_tables a[data-value="${title}"]`).click();
    let expectedDate;
    const fillEvent = async (p, site) => {
      expectedDate = (await p.locator('#event-monitoring_date input').inputValue()).slice(0, 8) + '10';
      await p.locator('#event-monitoring_date input').click();
      await p.locator('.datepicker-dropdown:visible .datepicker-days td.day:not(.old):not(.new)').filter({hasText: /^10$/}).click();
      assert.equal(await p.locator('#event-monitoring_date input').inputValue(), expectedDate);
      await p.locator('#event-site').fill(site);
      await p.locator('#event-observers').fill('Synthetic acceptance test');
      await p.locator('#event-monitoring_time').fill('09:30');
      await p.locator('#event-event_notes').fill('Synthetic data only; browser acceptance');
    };
    const addVisual = async (p, module, type) => {
      await nav(p, 'visual_survey');
      await p.locator('#visual-module_number').fill(module);
      await choose(p, 'visual-transect_point', 'W');
      await choose(p, 'visual-reef_type', 'Bag');
      await choose(p, 'visual-module_type', type);
      for (const field of ['live_oysters_count', 'sav_count', 'fouling_count', 'substrate_count', 'sediment_count']) await p.locator(`#visual-${field}`).fill('10');
      await p.locator('#visual-notes').fill('First observation; second observation');
      await p.locator('#visual-add_observation').click();
      await p.locator('#visual-staged_count').filter({hasText: '1 observation(s) staged'}).waitFor();
    };
    const save = async p => {
      await nav(p, 'review_submit');
      await p.locator('#review-submit').click();
      await p.getByRole('heading', {name: 'Download finalized data', exact: true}).waitFor({timeout: 30000});
      assert.equal(await p.locator('a.workbook-download').count(), 1);
      return await p.locator('#review-summary code').textContent();
    };
    const downloadCSV = async (p, name) => {
      if (!await p.locator(`#review-download_${name}`).isVisible()) await p.getByText('Optional: individual CSV files', {exact: true}).click();
      const waiting = p.waitForEvent('download');
      await p.locator(`#review-download_${name}`).click();
      const file = await waiting;
      const destination = path.join(exportDir, file.suggestedFilename());
      await file.saveAs(destination);
      assert.equal(await file.failure(), null);
      assert.ok(fs.statSync(destination).size > 0);
      return destination;
    };
    let workbookNumber = 0;
    const downloadWorkbook = async p => {
      const waiting = p.waitForEvent('download');
      await p.locator('#review-download_workbook').click();
      const file = await waiting;
      assert.match(file.suggestedFilename(), /[.]xlsx$/);
      const destination = path.join(exportDir, `${++workbookNumber}_${file.suggestedFilename()}`);
      await file.saveAs(destination);
      assert.equal(await file.failure(), null);
      assert.equal(fs.readFileSync(destination).subarray(0, 2).toString(), 'PK');
      return destination;
    };

    await page.goto(baseURL, {waitUntil: 'networkidle'});
    await connected(page);
    assert.match(await page.title(), /Oyster Reef Monitoring/);
    check('deployment entry point starts and browser connects without JavaScript errors');
    assert.equal(await page.locator('.draft-controls,#draft_status,#download_draft,#upload_draft').count(), 0);
    assert.equal(await page.locator('script[src*="drafts.js"]').count(), 0);
    assert.equal((await page.locator('body').innerText()).includes('A saved browser draft is available'), false);
    check('draft and backup controls stay absent even when a browser draft already exists');
    await fillEvent(page, 'Synthetic Reef A');
    await nav(page, 'measured_oysters');
    await page.locator('#measured-module_number').fill('M1');
    await choose(page, 'measured-transect_point', 'W');
    await page.locator('#measured-total_oysters').fill('3');
    for (let i = 0; i < 3; ++i) {
      await page.locator('#measured-shell_height_mm').fill(String(21 + i));
      await page.locator('#measured-add_measurement').click();
      await page.locator('#measured-measurement_progress').filter({hasText: `${i + 1} (up to 50)`}).waitFor();
    }
    await page.locator('#measured-notes').fill('Short sample; only three shells present');
    await page.locator('#measured-add_sample').click();
    await page.locator('#measured-staged_count').filter({hasText: '1 sample(s) staged'}).waitFor();
    check('three-shell sample stages successfully in the real browser');
    await addVisual(page, 'M1', 'bags');
    check('bags module type and semicolon notes stage successfully');
    await page.locator('.notes-info:visible').last().focus();
    await page.getByRole('tooltip').filter({hasText: 'Separate individual notes with a semicolon (;).'}).waitFor();
    check('notes information hint is keyboard accessible');
    await nav(page, 'structural_monitoring');
    await page.locator('#structural-module_number').fill('M1');
    await choose(page, 'structural-transect_point', 'T');
    await choose(page, 'structural-structure_type', 'Corral');
    const depthFields = ['waterward_sediment', 'waterward_shell', 'top_shell', 'shoreward_shell', 'shoreward_sediment'];
    for (let i = 0; i < depthFields.length; ++i) await page.locator(`#structural-depth_${depthFields[i]}_cm`).fill(String(10 + i));
    await page.locator('#structural-notes').fill('Corral inspection; synthetic observations');
    await page.locator('#structural-add_observation').click();
    await page.locator('#structural-staged_count').filter({hasText: '1 structural observation(s) staged'}).waitFor();
    await nav(page, 'review_submit');
    await reviewTab(page, 'Shell sample totals');
    await page.locator('#review-table_Oyster_Samples').filter({hasText: 'Short sample'}).waitFor();
    await reviewTab(page, 'Visual observations');
    await page.locator('#review-table_Visual_Observations').filter({hasText: 'bags'}).waitFor();
    await reviewTab(page, 'Structural observations');
    await page.locator('#review-table_Structural_Observations').filter({hasText: 'Corral'}).waitFor();
    check('Corral dynamic fields and full-data review tabs render');

    const receipt = await save(page);
    assert.match(receipt, /^[0-9a-f-]{36}$/i);
    report.firstReceipt = receipt;
    report.workbookFiles = [await downloadWorkbook(page)];
    assert.equal(await page.locator('#measured-total_oysters').isDisabled(), true);
    check('finalization locks the snapshot and one event workbook downloads');
    report.workbookFiles.push(await downloadWorkbook(page));
    check('repeated workbook downloads remain available for the same event');
    const previousCSV = fs.readFileSync(await downloadCSV(page, 'Events'), 'utf8');
    assert.ok(previousCSV.includes(receipt));
    check('individual CSV downloads remain available as an optional alternative');
    // Exercise the real workbook fetch and writing logic without an OS picker.
    await page.evaluate(() => {
      window.__workbookSavedSize = 0;
      window.showSaveFilePicker = async () => ({createWritable: async () => {
        let bytes;
        return {write: async blob => { bytes = await blob.arrayBuffer(); }, close: async () => { window.__workbookSavedSize = bytes.byteLength; }, abort: async () => {}};
      }});
    });
    await page.locator('.workbook-save-as').click();
    await page.locator('.workbook-save-status').filter({hasText: 'Event workbook saved'}).waitFor();
    assert.ok(await page.evaluate(() => window.__workbookSavedSize > 1000));
    check('choose-save-location fetches an actual workbook and writes it to a simulated file handle');

    const secondContext = await browser.newContext({viewport: {width: 390, height: 844}, isMobile: true, hasTouch: true});
    const second = await secondContext.newPage();
    second.on('pageerror', error => report.browserErrors.push(error.message));
    await second.goto(baseURL, {waitUntil: 'networkidle'});
    await connected(second);
    await fillEvent(second, 'Mobile Synthetic Reef');
    await addVisual(second, 'Mobile1', 'gabion');
    report.mobileReceipt = await save(second);
    report.mobileWorkbook = await downloadWorkbook(second);
    await second.screenshot({path: 'tmp/acceptance-mobile.png', fullPage: true});
    assert.equal(await second.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth + 1), true);
    check('a mobile-sized browser finalizes and downloads an event without horizontal page overflow');

    const concurrentContexts = await Promise.all([browser.newContext(), browser.newContext()]);
    const concurrentPages = await Promise.all(concurrentContexts.map(c => c.newPage()));
    for (const p of concurrentPages) p.on('pageerror', error => report.browserErrors.push(error.message));
    await Promise.all(concurrentPages.map(p => p.goto(baseURL, {waitUntil: 'networkidle'})));
    await Promise.all(concurrentPages.map(connected));
    await Promise.all(concurrentPages.map((p, i) => fillEvent(p, `Synthetic Concurrent Reef ${i + 1}`)));
    await Promise.all(concurrentPages.map((p, i) => addVisual(p, `C${i + 1}`, i ? 'gabion' : 'bags')));
    report.concurrentReceipts = await Promise.all(concurrentPages.map(save));
    assert.notEqual(report.concurrentReceipts[0], report.concurrentReceipts[1]);
    report.concurrentWorkbooks = await Promise.all(concurrentPages.map(downloadWorkbook));
    check('independent browser sessions finalize and download separate workbooks');
    await Promise.all(concurrentContexts.map(c => c.close()));
    await page.locator('#review-edit').click();
    await page.waitForFunction(() => !document.getElementById('event-site').disabled);
    await nav(page, 'event_information');
    await page.locator('#event-site').fill('Revised Synthetic Reef');
    const revised = await save(page);
    assert.notEqual(revised, receipt);
    report.revisedWorkbook = await downloadWorkbook(page);
    report.revisedReceipt = revised;
    check('returning to editing preserves records and revised finalization produces a new export ID');
    assert.equal(await page.evaluate(() => localStorage.getItem('rosoyster.draft.v1:' + window.location.pathname)), 'prior-work');
    assert.deepEqual(report.browserErrors, []);
    assert.deepEqual(report.failedResponses, []);
    check('no browser exceptions or HTTP resource failures');
    await context.close();
    await secondContext.close();
  } catch (error) {
    report.failure = error.message;
    if (debugPage && !debugPage.isClosed()) {
      await debugPage.screenshot({path: 'tmp/acceptance-failure.png', fullPage: true});
      report.visibleText = await debugPage.locator('body').innerText();
    }
    throw error;
  } finally {
    fs.writeFileSync('tmp/browser-acceptance-report.json', JSON.stringify(report, null, 2));
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
