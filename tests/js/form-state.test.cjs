const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function app() {
  const handlers = {}, calls = [];
  const elements = [{id: 'event-site'}, {id: 'measured-add_sample'},
    {id: 'visual-module_type', selectize: {disable: () => calls.push('disable'), enable: () => calls.push('enable')}},
    {id: 'review-download_workbook'}];
  vm.runInNewContext(fs.readFileSync('inst/app/www/form-state.js', 'utf8'), {
    Shiny: {addCustomMessageHandler: (name, fn) => { assert.equal(fn.length, 1); handlers[name] = fn; }},
    document: {querySelectorAll: () => elements}
  });
  return {handlers, elements, calls};
}

test('finalization locks entry controls while leaving workbook downloads available', () => {
  const x = app(); x.handlers['submission-lock'](true);
  assert.equal(x.elements[0].disabled, true);
  assert.equal(x.elements[1].disabled, true);
  assert.equal(x.elements[3].disabled, undefined);
  assert.deepEqual(x.calls, ['disable']);
});
test('returning to editing re-enables entry controls', () => {
  const x = app(); x.handlers['submission-lock'](true); x.handlers['submission-lock'](false);
  assert.equal(x.elements[0].disabled, false);
  assert.deepEqual(x.calls, ['disable', 'enable']);
});
