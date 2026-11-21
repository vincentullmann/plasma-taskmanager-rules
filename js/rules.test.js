'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const R = require('../package/contents/code/rules.js');

const cfg = (...rules) => ({ version: 1, rules });
const rule = (conditions, actions = { fontColor: '#ff0000' }, extra = {}) =>
  ({ name: 'r', enabled: true, conditions, actions, ...extra });
const win = (o = {}) => ({ title: 'T', appId: 'app', name: 'App', exe: '/usr/bin/app', ...o });
const load = (c, opts) => {
  const res = R.compile(c, opts);
  assert.ok(res.ok, JSON.stringify(res.errors));
  return res.engine;
};

test('validate: accepts the spec example', () => {
  const res = R.validate({
    version: 1,
    rules: [{
      name: 'Work Slack', enabled: true,
      conditions: { appId: { glob: '*slack*' }, title: { regex: '\\[work\\]' }, exe: { exact: '/usr/bin/slack' } },
      actions: { icon: '~/icons/slack-work.svg', fontColor: '#ff8800', background: '#33ff8800' },
    }],
  });
  assert.deepEqual(res, { ok: true, errors: [] });
});

test('validate: readable errors', () => {
  const cases = [
    [null, /config must be an object/],
    [{ version: 2, rules: [] }, /version must be 1/],
    [{ version: 1 }, /rules must be an array/],
    [cfg(5), /rules\[0\] must be an object/],
    [cfg({ name: 'x', enabled: true, conditions: {}, actions: {} }), /rules\[0\] \("x"\).*at least one condition/],
    [cfg(rule({ foo: { exact: 'a' } })), /unknown condition field "foo"/],
    [cfg(rule({ title: 'a' })), /title.*must be an object/],
    [cfg(rule({ title: { exact: 'a', glob: 'b' } })), /title.*exactly one of exact, regex, glob/],
    [cfg(rule({ title: {} })), /title.*exactly one of exact, regex, glob/],
    [cfg(rule({ title: { exact: 3 } })), /title.exact must be a string/],
    [cfg(rule({ title: { regex: '(' } })), /title.regex is not a valid regular expression/],
    [cfg(rule({ title: { exact: 'a', caseSensitive: 'yes' } })), /caseSensitive must be a boolean/],
    [cfg(rule({ title: { exact: 'a' } }, { fontColor: 'red' })), /fontColor must be #RRGGBB or #AARRGGBB/],
    [cfg(rule({ title: { exact: 'a' } }, { background: '#12345' })), /background must be #RRGGBB or #AARRGGBB/],
    [cfg(rule({ title: { exact: 'a' } }, { icon: 3 })), /icon must be a string/],
    [cfg(rule({ title: { exact: 'a' } }, {}, { enabled: 'yes' })), /enabled must be a boolean/],
    [cfg(rule({ title: { exact: 'a' } }, {}, { name: 4 })), /name must be a string/],
  ];
  for (const [input, re] of cases) {
    const res = R.validate(input);
    assert.equal(res.ok, false, JSON.stringify(input));
    assert.ok(res.errors.some(e => re.test(e)), `${re} not in ${JSON.stringify(res.errors)}`);
  }
});

test('validate: reports every error, not only the first', () => {
  const res = R.validate(cfg(rule({ foo: { exact: 'a' } }), rule({ title: { regex: '(' } })));
  assert.equal(res.errors.length, 2);
});

test('parse: invalid JSON gives readable error', () => {
  const res = R.parse('{ nope');
  assert.equal(res.ok, false);
  assert.match(res.errors[0], /invalid JSON/);
});

test('parse: valid text returns config', () => {
  const res = R.parse(JSON.stringify(cfg(rule({ title: { exact: 'a' } }))));
  assert.equal(res.ok, true);
  assert.equal(res.config.rules.length, 1);
});

test('exact matches whole string only, case-insensitive by default', () => {
  const e = load(cfg(rule({ appId: { exact: 'Firefox' } })));
  assert.equal(R.evaluate(e, win({ appId: 'firefox' })).fontColor, '#ff0000');
  assert.deepEqual(R.evaluate(e, win({ appId: 'firefox-esr' })), {});
});

test('caseSensitive opts in', () => {
  const e = load(cfg(rule({ appId: { exact: 'Firefox', caseSensitive: true } })));
  assert.deepEqual(R.evaluate(e, win({ appId: 'firefox' })), {});
  assert.equal(R.evaluate(e, win({ appId: 'Firefox' })).fontColor, '#ff0000');
});

test('regex is a search (unanchored), case-insensitive by default', () => {
  const e = load(cfg(rule({ title: { regex: '\\[work\\]' } })));
  assert.equal(R.evaluate(e, win({ title: 'Chat [WORK] - Slack' })).fontColor, '#ff0000');
  assert.deepEqual(R.evaluate(e, win({ title: 'Chat [home]' })), {});
});

test('regex respects anchors and caseSensitive', () => {
  const e = load(cfg(rule({ title: { regex: '^Foo', caseSensitive: true } })));
  assert.equal(R.evaluate(e, win({ title: 'Foo bar' })).fontColor, '#ff0000');
  assert.deepEqual(R.evaluate(e, win({ title: 'foo bar' })), {});
  assert.deepEqual(R.evaluate(e, win({ title: 'x Foo' })), {});
});

test('glob: * and ? wildcards match the whole string; other chars are literal', () => {
  const e = load(cfg(rule({ appId: { glob: '*slack*' } }), rule({ title: { glob: 'a.b?' } }, { icon: 'x' })));
  assert.equal(R.evaluate(e, win({ appId: 'com.Slack.Slack' })).fontColor, '#ff0000');
  assert.deepEqual(R.evaluate(e, win({ appId: 'zoom', title: 'axbc' })), {});
  assert.equal(R.evaluate(e, win({ appId: 'zoom', title: 'a.bc' })).icon.name, 'x');
  assert.deepEqual(R.evaluate(e, win({ appId: 'zoom', title: 'a.b' })), {});
});

test('glob: regex metacharacters in pattern are escaped', () => {
  const e = load(cfg(rule({ title: { glob: '(1)+[x]' } })));
  assert.equal(R.evaluate(e, win({ title: '(1)+[x]' })).fontColor, '#ff0000');
  assert.deepEqual(R.evaluate(e, win({ title: '1x' })), {});
});

test('glob: multiline titles are matched as a whole', () => {
  const e = load(cfg(rule({ title: { glob: 'a*b' } })));
  assert.equal(R.evaluate(e, win({ title: 'a\nb' })).fontColor, '#ff0000');
});

test('all four fields can be matched', () => {
  const e = load(cfg(rule({
    title: { exact: 'T' }, appId: { exact: 'app' }, name: { exact: 'App' }, exe: { exact: '/usr/bin/app' },
  })));
  assert.equal(R.evaluate(e, win()).fontColor, '#ff0000');
  assert.deepEqual(R.evaluate(e, win({ exe: '/other' })), {});
});

test('conditions are ANDed', () => {
  const e = load(cfg(rule({ appId: { exact: 'app' }, title: { exact: 'nope' } })));
  assert.deepEqual(R.evaluate(e, win()), {});
});

test('missing window fields are treated as empty string', () => {
  const e = load(cfg(rule({ exe: { exact: '/usr/bin/app' } })));
  assert.deepEqual(R.evaluate(e, { title: 'T' }), {});
});

test('disabled rules are skipped', () => {
  const e = load(cfg(rule({ appId: { exact: 'app' } }, { fontColor: '#111111' }, { enabled: false })));
  assert.deepEqual(R.evaluate(e, win()), {});
});

test('enabled defaults to true when omitted', () => {
  const r = rule({ appId: { exact: 'app' } });
  delete r.enabled;
  const e = load(cfg(r));
  assert.equal(R.evaluate(e, win()).fontColor, '#ff0000');
});

test('merge: all matching rules apply; later overrides earlier per field', () => {
  const e = load(cfg(
    rule({ appId: { exact: 'app' } }, { icon: 'a', fontColor: '#111111', background: '#22222222' }),
    rule({ title: { exact: 'T' } }, { fontColor: '#333333' }),
    rule({ title: { exact: 'zzz' } }, { fontColor: '#444444' }),
  ));
  const out = R.evaluate(e, win());
  assert.equal(out.icon.name, 'a');
  assert.equal(out.fontColor, '#333333');
  assert.equal(out.background, '#22222222');
});

test('icon: theme name vs path, ~ expanded', () => {
  assert.deepEqual(R.resolveIcon('firefox', '/home/u'), { name: 'firefox' });
  assert.deepEqual(R.resolveIcon('/opt/i.svg', '/home/u'), { path: '/opt/i.svg' });
  assert.deepEqual(R.resolveIcon('~/icons/a.svg', '/home/u'), { path: '/home/u/icons/a.svg' });
  assert.deepEqual(R.resolveIcon('~/icons/a.svg', '/home/u/'), { path: '/home/u/icons/a.svg' });
  assert.deepEqual(R.resolveIcon('~', '/home/u'), { path: '/home/u' });
  assert.deepEqual(R.resolveIcon('~x', '/home/u'), { name: '~x' });
});

test('evaluate resolves icon using compile option home', () => {
  const e = load(cfg(rule({ appId: { exact: 'app' } }, { icon: '~/i.svg' })), { home: '/h' });
  assert.deepEqual(R.evaluate(e, win()).icon, { path: '/h/i.svg' });
});

test('regexes are compiled once per config load, not per evaluate', () => {
  const RealRegExp = globalThis.RegExp;
  let count = 0;
  globalThis.RegExp = new Proxy(RealRegExp, { construct(t, args) { count++; return new t(...args); } });
  try {
    const e = load(cfg(rule({ title: { regex: 'a' } }), rule({ appId: { glob: 'x*' } })));
    const after = count;
    for (let i = 0; i < 50; i++) R.evaluate(e, win({ title: 'a' + i }));
    assert.equal(count, after);
  } finally { globalThis.RegExp = RealRegExp; }
});

test('compile refuses an invalid config', () => {
  const res = R.compile({ version: 1, rules: [rule({ title: { regex: '(' } })] });
  assert.equal(res.ok, false);
  assert.ok(res.errors.length > 0);
});

test('defaultConfig is valid and empty', () => {
  assert.deepEqual(R.validate(R.defaultConfig()), { ok: true, errors: [] });
  assert.deepEqual(R.defaultConfig().rules, []);
});

test('applyText: valid text yields new state and clears error', () => {
  const prev = R.initialState();
  const next = R.applyText(prev, JSON.stringify(cfg(rule({ appId: { exact: 'app' } }))), { home: '/h' });
  assert.equal(next.error, '');
  assert.equal(next.config.rules.length, 1);
  assert.equal(R.evaluate(next.engine, win()).fontColor, '#ff0000');
});

test('applyText: invalid JSON keeps last good state and exposes error', () => {
  const good = R.applyText(R.initialState(), JSON.stringify(cfg(rule({ appId: { exact: 'app' } }))));
  const bad = R.applyText(good, '{ oops');
  assert.match(bad.error, /invalid JSON/);
  assert.equal(bad.engine, good.engine);
  assert.equal(bad.config, good.config);
});

test('applyText: schema error keeps last good state and lists errors', () => {
  const good = R.applyText(R.initialState(), JSON.stringify(cfg(rule({ appId: { exact: 'app' } }))));
  const bad = R.applyText(good, JSON.stringify(cfg(rule({ title: { regex: '(' } }))));
  assert.match(bad.error, /not a valid regular expression/);
  assert.equal(bad.engine, good.engine);
});

test('applyText: recovers once the file is fixed', () => {
  const s1 = R.applyText(R.initialState(), 'nope');
  const s2 = R.applyText(s1, JSON.stringify(cfg(rule({ appId: { exact: 'app' } }))));
  assert.equal(s2.error, '');
  assert.equal(s2.config.rules.length, 1);
});

test('initialState: empty engine matches nothing', () => {
  const s = R.initialState();
  assert.equal(s.error, '');
  assert.deepEqual(R.evaluate(s.engine, win()), {});
});

test('serialize: pretty JSON with trailing newline that parses back', () => {
  const c = cfg(rule({ appId: { exact: 'app' } }));
  const text = R.serialize(c);
  assert.ok(text.endsWith('\n'));
  assert.deepEqual(JSON.parse(text), c);
});

test('iconSource: theme name passes through, path becomes a file URL', () => {
  assert.equal(R.iconSource({ name: 'firefox' }), 'firefox');
  assert.equal(R.iconSource({ path: '/opt/a b.svg' }), 'file:///opt/a%20b.svg');
  assert.equal(R.iconSource(undefined), '');
});

test('matchingRules: indexes of rules matching the window, disabled included', () => {
  const c = cfg(rule({ appId: { exact: 'app' } }), rule({ appId: { exact: 'other' } }), rule({ name: { exact: 'App' } }, {}, { enabled: false }));
  assert.deepEqual(R.matchingRules(c, win()), [0, 2]);
  assert.deepEqual(R.matchingRules(c, win({ appId: 'zzz', name: 'Q' })), []);
});
