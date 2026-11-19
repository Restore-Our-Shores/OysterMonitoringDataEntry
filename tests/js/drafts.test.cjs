const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');

function browser(failStorage = false) {
  const handlers = {}, events = {}, sent = [], store = new Map(), elements = [];
  const document = {querySelectorAll: () => elements, querySelector: () => null,
    getElementById: id => elements.find(x => x.id === id)};
  const $ = el => ({on: (name, fn) => events[name] = fn, trigger: () => {},
    hasClass: name => !!el.date && name === 'shiny-date-input',
    find: () => ({bsDatepicker: (action, value) => { assert.equal(action, 'update'); el.value = value; }})});
  const Shiny = {addCustomMessageHandler: (name, fn) => {
    assert.equal(fn.length, 1, 'Shiny custom message handlers must accept one argument');
    handlers[name] = fn;
  },
    setInputValue: (name, value) => sent.push({name, value})};
  const localStorage = {getItem: key => store.get(key), removeItem: key => store.delete(key),
    setItem: (key, value) => { if (failStorage) throw Error('quota'); store.set(key, value); }};
  vm.runInNewContext(fs.readFileSync('inst/app/www/drafts.js', 'utf8'), {
    window: {location: {pathname: '/test'}, addEventListener() {}}, document, $, Shiny,
    localStorage, setInterval() {}, clearInterval() {}, Date, Object
  });
  return {handlers, events, sent, store, elements};
}

test('finalized draft snapshots are persisted without requiring a storage backend', () => {
  const b = browser();
  b.handlers['draft-save']({text: 'finalized'});
  assert.equal([...b.store.values()][0], 'finalized');
  assert.equal(b.sent.length, 0);
});

test('browser storage failures show a backup notice without disabling CSV downloads', () => {
  const b = browser(true);
  b.handlers['draft-save']({text: 'finalized'});
  assert.ok(b.sent.find(x => x.name === 'draft_storage_error'));
});

test('finalized events lock editing while keeping review controls available', () => {
  const b = browser();
  b.elements.push({id: 'event-site'}, {id: 'measured-add_sample'}, {id: 'review-submit'});
  b.handlers['submission-lock'](true);
  assert.equal(b.elements[0].disabled, true);
  assert.equal(b.elements[1].disabled, true);
  assert.equal(b.elements[2].disabled, undefined);
  b.handlers['submission-lock'](false);
  assert.equal(b.elements[0].disabled, false);
});

test('startup advertises an existing draft without replacing it', () => {
  const b = browser();
  b.store.set('rosoyster.draft.v1:/test', 'prior-work');
  b.events['shiny:connected']();
  assert.equal(b.sent[0].value.text, 'prior-work');
  assert.equal([...b.store.values()][0], 'prior-work');
  b.handlers['draft-clear']();
  assert.equal(b.store.size, 0);
});

test('date recovery uses the datepicker binding shipped by Shiny', () => {
  const b = browser();
  b.elements.push({id: 'event-monitoring_date', date: true});
  b.handlers['draft-restore-inputs']({'event-monitoring_date': '2026-11-10'});
  assert.equal(b.elements[0].value, '2026-11-10');
  assert.equal(b.sent.length, 0, 'restoration must not overwrite typed binding events');
});
