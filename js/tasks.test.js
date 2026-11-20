'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const T = require('../package/contents/code/tasks.js');

test('dropIndex: cell under the pointer, clamped', () => {
  assert.equal(T.dropIndex(0, 100, 4), 0);
  assert.equal(T.dropIndex(99, 100, 4), 0);
  assert.equal(T.dropIndex(100, 100, 4), 1);
  assert.equal(T.dropIndex(250, 100, 4), 2);
  assert.equal(T.dropIndex(-30, 100, 4), 0);
  assert.equal(T.dropIndex(9999, 100, 4), 3);
  assert.equal(T.dropIndex(50, 100, 0), 0);
  assert.equal(T.dropIndex(50, 0, 4), 0);
});

test('audioBadge: hidden without audio; icon reflects mute state', () => {
  const hidden = { visible: false, icon: '', muted: false };
  assert.deepEqual(T.audioBadge({ hasAudio: false, playing: false, muted: false }), hidden);
  assert.deepEqual(T.audioBadge({ hasAudio: true, playing: false, muted: false }), hidden);   // idle stream
  assert.deepEqual(T.audioBadge({ hasAudio: true, playing: true, muted: false }),
    { visible: true, icon: 'audio-volume-high', muted: false });
  assert.deepEqual(T.audioBadge({ hasAudio: true, playing: true, muted: true }),
    { visible: true, icon: 'audio-volume-muted', muted: true });
  assert.deepEqual(T.audioBadge({ hasAudio: true, playing: false, muted: true }),
    { visible: true, icon: 'audio-volume-muted', muted: true });   // stays visible so it can be unmuted
});

test('progressFraction: -1 when not shown, else clamped 0..1', () => {
  assert.equal(T.progressFraction({ visible: false, value: 0.5 }), -1);
  assert.equal(T.progressFraction({ visible: true, value: 0.25 }), 0.25);
  assert.equal(T.progressFraction({ visible: true, value: 7 }), 1);
  assert.equal(T.progressFraction({ visible: true, value: -2 }), 0);
  assert.equal(T.progressFraction({ visible: true, value: NaN }), -1);
  assert.equal(T.progressFraction(undefined), -1);
});
