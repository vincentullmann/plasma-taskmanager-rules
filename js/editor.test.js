'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const R = require('../package/contents/code/rules.js');
const E = require('../package/contents/code/editor.js');

const base = () => ({ version: 1, rules: [
  { name: 'a', enabled: true, conditions: { appId: { exact: 'x' } }, actions: { fontColor: '#ff0000' } },
  { name: 'b', enabled: true, conditions: { title: { glob: '*' }, exe: { regex: 'z' } }, actions: {} },
  { name: 'c', enabled: false, conditions: { name: { exact: 'n' } }, actions: { icon: 'i' } },
] });
const names = c => c.rules.map(r => r.name);

test('addRule appends a valid, inert rule and does not mutate input', () => {
  const c = base();
  const n = E.addRule(c);
  assert.equal(c.rules.length, 3);
  assert.equal(n.rules.length, 4);
  assert.equal(R.validate(n).ok, true);
  assert.equal(n.rules[3].enabled, true);
});

test('removeRule', () => {
  assert.deepEqual(names(E.removeRule(base(), 1)), ['a', 'c']);
  assert.deepEqual(names(E.removeRule(base(), 9)), ['a', 'b', 'c']);
});

test('moveRule reorders and clamps at the ends', () => {
  assert.deepEqual(names(E.moveRule(base(), 0, 1)), ['b', 'a', 'c']);
  assert.deepEqual(names(E.moveRule(base(), 2, -1)), ['a', 'c', 'b']);
  assert.deepEqual(names(E.moveRule(base(), 0, -1)), ['a', 'b', 'c']);
  assert.deepEqual(names(E.moveRule(base(), 2, 1)), ['a', 'b', 'c']);
});

test('setRuleProp: name and enabled', () => {
  const n = E.setRuleProp(E.setRuleProp(base(), 0, 'name', 'z'), 2, 'enabled', true);
  assert.equal(n.rules[0].name, 'z');
  assert.equal(n.rules[2].enabled, true);
});

test('conditionList flattens in order for display', () => {
  assert.deepEqual(E.conditionList(base().rules[1]), [
    { field: 'title', type: 'glob', value: '*', caseSensitive: false },
    { field: 'exe', type: 'regex', value: 'z', caseSensitive: false },
  ]);
});

test('addCondition picks the first unused field; none left -> unchanged', () => {
  let c = E.addCondition(base(), 0);
  assert.deepEqual(Object.keys(c.rules[0].conditions), ['appId', 'title']);
  c = E.addCondition(E.addCondition(E.addCondition(c, 0), 0), 0);
  assert.deepEqual(Object.keys(c.rules[0].conditions), ['appId', 'title', 'name', 'exe']);
});

test('setCondition edits type/value/caseSensitive, keeping order', () => {
  let c = E.setCondition(base(), 1, 'title', { type: 'regex', value: '^a', caseSensitive: true });
  assert.deepEqual(c.rules[1].conditions.title, { regex: '^a', caseSensitive: true });
  assert.deepEqual(Object.keys(c.rules[1].conditions), ['title', 'exe']);
  c = E.setCondition(c, 1, 'title', { type: 'exact', value: 'q', caseSensitive: false });
  assert.deepEqual(c.rules[1].conditions.title, { exact: 'q' });
});

test('changeConditionField renames keeping position; refuses a taken field', () => {
  let c = E.changeConditionField(base(), 1, 'title', 'name');
  assert.deepEqual(Object.keys(c.rules[1].conditions), ['name', 'exe']);
  assert.deepEqual(c.rules[1].conditions.name, { glob: '*' });
  c = E.changeConditionField(base(), 1, 'title', 'exe');
  assert.deepEqual(Object.keys(c.rules[1].conditions), ['title', 'exe']);
});

test('removeCondition', () => {
  const c = E.removeCondition(base(), 1, 'title');
  assert.deepEqual(Object.keys(c.rules[1].conditions), ['exe']);
});

test('setAction sets and clears (empty / undefined removes)', () => {
  let c = E.setAction(base(), 1, 'icon', 'firefox');
  assert.equal(c.rules[1].actions.icon, 'firefox');
  c = E.setAction(c, 1, 'icon', '');
  assert.equal('icon' in c.rules[1].actions, false);
  c = E.setAction(base(), 0, 'fontColor', undefined);
  assert.equal('fontColor' in c.rules[0].actions, false);
});

test('regexError: empty for valid, readable message for invalid', () => {
  assert.equal(E.regexError('^a+$'), '');
  assert.match(E.regexError('('), /./);
});

test('conditionError: only regex values can be wrong', () => {
  assert.equal(E.conditionError({ type: 'glob', value: '(' }), '');
  assert.equal(E.conditionError({ type: 'regex', value: '(' }) !== '', true);
  assert.equal(E.conditionError({ type: 'regex', value: 'a' }), '');
});

test('colorError: accepts #RRGGBB / #AARRGGBB and empty', () => {
  assert.equal(E.colorError(''), '');
  assert.equal(E.colorError('#ff0000'), '');
  assert.equal(E.colorError('#80ff0000'), '');
  assert.notEqual(E.colorError('red'), '');
  assert.notEqual(E.colorError('#12'), '');
});

test('every operation keeps a valid config valid', () => {
  let c = base();
  c = E.addRule(c); c = E.moveRule(c, 3, -2); c = E.addCondition(c, 0);
  c = E.setCondition(c, 0, 'title', { type: 'regex', value: 'a|b', caseSensitive: true });
  c = E.setAction(c, 0, 'background', '#33ff8800');
  assert.equal(R.validate(c).ok, true, JSON.stringify(R.validate(c).errors));
});

test('addRuleFor matches the window by app id, else name, else title', () => {
  const w = { appId: 'app', name: 'App', title: 'T' };
  let c = E.addRuleFor(base(), w);
  assert.deepEqual(c.rules[3].conditions, { appId: { exact: 'app' } });
  assert.ok(R.validate(c).ok);
  assert.deepEqual(E.addRuleFor(base(), { name: 'App', title: 'T' }).rules[3].conditions, { name: { exact: 'App' } });
  assert.deepEqual(E.addRuleFor(base(), { title: 'T' }).rules[3].conditions, { title: { exact: 'T' } });
  assert.equal(base().rules.length, 3);
});
