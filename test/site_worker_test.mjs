import assert from 'node:assert/strict';
import test from 'node:test';

import { utmTag, visitSource } from '../site/worker.js';

const home = (query = '') => new URL(`https://bedug.ardeman.com/${query}`);

test('a utm_source tag wins and is cleaned', () => {
  assert.equal(visitSource(home('?utm_source=Instagram'), 'https://l.facebook.com/'), 'instagram');
  assert.equal(visitSource(home('?utm_source=<b>x</b>'), null), 'bxb');
  assert.equal(visitSource(home(`?utm_source=${'a'.repeat(80)}`), null).length, 40);
});

test('known referrers map to a source name', () => {
  assert.equal(visitSource(home(), 'https://l.instagram.com/?u=x'), 'instagram');
  assert.equal(visitSource(home(), 'https://www.threads.net/@x'), 'threads');
  assert.equal(visitSource(home(), 'https://t.co/abc'), 'x');
});

test('other referrers keep their host; none is direct', () => {
  assert.equal(visitSource(home(), 'https://www.google.com/'), 'www.google.com');
  assert.equal(visitSource(home(), 'https://bedug.ardeman.com/en/privacy/'), 'internal');
  assert.equal(visitSource(home(), null), 'direct');
  assert.equal(visitSource(home(), 'not a url'), 'direct');
});

test('utm_medium and utm_campaign are cleaned labels, empty when missing', () => {
  const url = home('?utm_source=instagram&utm_medium=Social&utm_campaign=bio%20link');
  assert.equal(utmTag(url, 'utm_medium'), 'social');
  assert.equal(utmTag(url, 'utm_campaign'), 'biolink');
  assert.equal(utmTag(home(), 'utm_campaign'), '');
});
