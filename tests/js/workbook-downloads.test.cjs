const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');

function setup({supported = true, cancel = false, fetchFailure = false, writeFailure = false} = {}) {
  let click, written, aborted = false, pickerOptions;
  const status = {textContent: ''};
  const link = {href: '/download/workbook', dataset: {filename: 'event.xlsx'}, getAttribute: () => '/download/workbook'};
  const card = {querySelector: selector => selector === '.workbook-save-status' ? status : link};
  const button = {disabled: false, parentElement: {parentElement: card}};
  const picker = async options => {
    pickerOptions = options;
    if (cancel) throw Object.assign(Error('canceled'), {name: 'AbortError'});
    return {createWritable: async () => ({
      write: async contents => { if (writeFailure) throw Error('disk full'); written = contents; },
      close: async () => {}, abort: async () => { aborted = true; }
    })};
  };
  vm.runInNewContext(fs.readFileSync('inst/app/www/workbook-downloads.js', 'utf8'), {
    document: {addEventListener: (name, fn) => { assert.equal(name, 'click'); click = fn; }},
    window: supported ? {showSaveFilePicker: picker} : {},
    fetch: async () => ({ok: !fetchFailure, headers: {get: () => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}, blob: async () => 'xlsx-binary'})
  });
  return {run: () => click({target: {closest: () => button}}), status, button,
    result: () => ({written, aborted, pickerOptions})};
}

test('save-as writes one workbook and suggests the event filename', async () => {
  const x = setup(); await x.run();
  assert.equal(x.result().written, 'xlsx-binary');
  assert.equal(x.result().pickerOptions.suggestedName, 'event.xlsx');
  assert.match(x.status.textContent, /workbook saved/);
  assert.equal(x.button.disabled, false);
});
test('unsupported browsers retain the normal workbook download', async () => {
  const x = setup({supported: false}); await x.run();
  assert.equal(x.result().written, undefined);
  assert.match(x.status.textContent, /Download event workbook/);
});
test('canceling the save dialog writes nothing', async () => {
  const x = setup({cancel: true}); await x.run();
  assert.equal(x.result().written, undefined);
  assert.match(x.status.textContent, /canceled/);
});
test('failed workbook fetching does not write a file', async () => {
  const x = setup({fetchFailure: true}); await x.run();
  assert.equal(x.result().written, undefined);
  assert.match(x.status.textContent, /could not be saved/);
});
test('failed writes abort the stream and retain retry controls', async () => {
  const x = setup({writeFailure: true}); await x.run();
  assert.equal(x.result().aborted, true);
  assert.match(x.status.textContent, /could not be saved/);
  assert.equal(x.button.disabled, false);
});
