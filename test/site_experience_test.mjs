import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

const source = readFileSync(new URL('../site/static/experience.js', import.meta.url), 'utf8');

function setup({ reduced = false, observers = true, hash = '' } = {}) {
  const events = {};
  const observersCreated = [];
  const animations = [];
  const motion = { matches: reduced, addEventListener: (_, fn) => { events.motion = fn; } };
  function element(id) {
    return {
      id, hash: `#${id}`, attributes: {},
      setAttribute(key, value) { this.attributes[key] = value; },
      removeAttribute(key) { delete this.attributes[key]; },
      animate(frames, options) {
        const animation = { frames, options, cancelled: false, finished: new Promise(() => {}), cancel() { this.cancelled = true; } };
        animations.push(animation);
        return animation;
      },
    };
  }
  const hero = element('hero');
  const feature = element('features');
  const download = element('download');
  const links = [element('features'), element('download')];
  const summary = { focused: false, focus() { this.focused = true; } };
  const language = { open: true, contains: target => target === summary, querySelector: () => summary };
  const document = {
    querySelectorAll(selector) {
      if (selector.startsWith('.hero-copy')) return [hero];
      if (selector.startsWith('.top-nav')) return links;
      return [feature];
    },
    querySelector: () => language,
    getElementById: id => ({ features: feature, download })[id],
    addEventListener: (name, fn) => { events[name] = fn; },
  };
  class Observer {
    constructor(callback) { this.callback = callback; this.targets = new Set(); observersCreated.push(this); }
    observe(target) { this.targets.add(target); }
    unobserve(target) { this.targets.delete(target); }
  }
  const window = { matchMedia: () => motion, location: { hash }, scrollY: 0 };
  if (observers) window.IntersectionObserver = Observer;
  runInNewContext(source, { window, document, IntersectionObserver: Observer });
  return { events, motion, animations, observersCreated, hero, feature, download, links, language, summary };
}

test('reduced motion skips entrances and scroll animations', () => {
  const s = setup({ reduced: true });
  s.observersCreated[0].callback([{ target: s.feature, isIntersecting: true }]);
  assert.equal(s.animations.length, 0);
  assert.equal(s.observersCreated[0].targets.size, 0);
});

test('reveals once and cancels running motion when the preference changes', () => {
  const s = setup();
  assert.equal(s.animations.length, 1);
  const observer = s.observersCreated[0];
  observer.callback([{ target: s.feature, isIntersecting: false }]);
  assert.equal(s.animations.length, 1);
  observer.callback([{ target: s.feature, isIntersecting: true }]);
  assert.equal(s.animations.length, 2);
  assert.equal(observer.targets.has(s.feature), false);
  s.motion.matches = true;
  s.events.motion();
  assert.ok(s.animations.every(a => a.cancelled));
});

test('section navigation follows visibility and clears stale selection', () => {
  const s = setup();
  const observer = s.observersCreated[1];
  observer.callback([{ target: s.feature, isIntersecting: true }]);
  assert.equal(s.links[0].attributes['aria-current'], 'location');
  observer.callback([{ target: s.feature, isIntersecting: false }, { target: s.download, isIntersecting: true }]);
  assert.equal(s.links[0].attributes['aria-current'], undefined);
  assert.equal(s.links[1].attributes['aria-current'], 'location');
  observer.callback([{ target: s.download, isIntersecting: false }]);
  assert.equal(s.links[1].attributes['aria-current'], undefined);
});

test('language menu dismisses outside or with Escape and restores keyboard focus', () => {
  const s = setup();
  s.events.click({ target: s.summary });
  assert.equal(s.language.open, true);
  s.events.click({ target: {} });
  assert.equal(s.language.open, false);
  s.language.open = true;
  s.events.keydown({ key: 'Escape' });
  assert.equal(s.language.open, false);
  assert.equal(s.summary.focused, true);
});

test('older browsers and deep links retain navigation without entrance motion', () => {
  const s = setup({ observers: false, hash: '#download' });
  assert.equal(s.animations.length, 0);
  assert.equal(s.observersCreated.length, 0);
  s.events.keydown({ key: 'Escape' });
  assert.equal(s.language.open, false);
});
