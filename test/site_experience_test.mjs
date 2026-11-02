import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';

const source = readFileSync(new URL('../site/static/experience.js', import.meta.url), 'utf8');

function setup({ reduced = false, observers = true, hash = '', scrollY = 0, home = true } = {}) {
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
  const header = { classes: new Set(), inert: false, classList: { toggle(name, value) { if (value) header.classes.add(name); else header.classes.delete(name); } } };
  const hero = element('hero');
  const feature = element('features');
  const download = element('download');
  const links = [element('features'), element('download')];
  const chapterLinks = [element('feature-quran'), element('feature-dzikir')];
  const menuScrolls = [];
  const menu = { getBoundingClientRect: () => ({ left: 20, right: 370, width: 350 }), scrollBy: options => menuScrolls.push(options) };
  for (const link of chapterLinks) {
    link.parentElement = menu;
    link.rect = { left: 28, right: 250, width: 222 };
    link.getBoundingClientRect = () => link.rect;
  }
  const chapters = { 'feature-quran': element('feature-quran'), 'feature-dzikir': element('feature-dzikir') };
  const summary = { focused: false, focus() { this.focused = true; } };
  const language = { open: true, contains: target => target === summary, querySelector: () => summary };
  const document = {
    querySelectorAll(selector) {
      if (selector.startsWith('.hero-copy')) return [hero];
      if (selector.startsWith('.top-nav')) return links;
      if (selector.startsWith('.feature-links')) return chapterLinks;
      return [feature];
    },
    querySelector: selector => selector === '.top-home' ? (home ? header : null) : language,
    getElementById: id => ({ features: feature, download, ...chapters })[id],
    addEventListener: (name, fn) => { events[name] = fn; },
  };
  class Observer {
    constructor(callback) { this.callback = callback; this.targets = new Set(); observersCreated.push(this); }
    observe(target) { this.targets.add(target); }
    unobserve(target) { this.targets.delete(target); }
  }
  const window = { matchMedia: () => motion, location: { hash }, scrollY, addEventListener: (name, fn) => { events['window-' + name] = fn; } };
  if (observers) window.IntersectionObserver = Observer;
  runInNewContext(source, { window, document, IntersectionObserver: Observer });
  return { events, window, header, motion, animations, observersCreated, hero, feature, download, links, chapterLinks, chapters, menuScrolls, language, summary };
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


test('chapter navigation tracks the visible app screen independently of main navigation', () => {
  const s = setup();
  s.observersCreated[1].callback([{ target: s.feature, isIntersecting: true }]);
  const observer = s.observersCreated[2];
  const quran = s.chapters['feature-quran'];
  const dzikir = s.chapters['feature-dzikir'];
  assert.equal(observer.targets.size, 2);
  observer.callback([{ target: quran, isIntersecting: true }]);
  assert.equal(s.chapterLinks[0].attributes['aria-current'], 'location');
  observer.callback([{ target: quran, isIntersecting: false }, { target: dzikir, isIntersecting: true }]);
  assert.equal(s.chapterLinks[0].attributes['aria-current'], undefined);
  assert.equal(s.chapterLinks[1].attributes['aria-current'], 'location');
  assert.equal(s.links[0].attributes['aria-current'], 'location');
  observer.callback([{ target: dzikir, isIntersecting: false }]);
  assert.equal(s.chapterLinks[1].attributes['aria-current'], undefined);
});

test('home navigation appears after scrolling and hides again at the top', () => {
  const s = setup();
  assert.equal(s.header.inert, true);
  assert.equal(s.header.classes.has('is-at-top'), true);
  s.window.scrollY = 80;
  s.events['window-scroll']();
  assert.equal(s.header.inert, false);
  assert.equal(s.header.classes.has('is-at-top'), false);
  s.window.scrollY = 0;
  s.events['window-scroll']();
  assert.equal(s.header.inert, true);
});

test('restored scroll positions show the header and inner pages retain regular navigation', () => {
  assert.equal(setup({ scrollY: 500 }).header.inert, false);
  assert.equal(setup({ home: false }).events['window-scroll'], undefined);
});


test('active clipped chapters scroll only the menu, in both text directions', () => {
  for (const [left, right] of [[300, 550], [-180, 70]]) {
    const s = setup();
    s.chapterLinks[1].rect = { left, right, width: right - left };
    const observer = s.observersCreated[2];
    const entry = { target: s.chapters['feature-dzikir'], isIntersecting: true };
    observer.callback([entry]);
    assert.equal(s.menuScrolls.length, 1);
    assert.equal(s.menuScrolls[0].left, left - 20 - (350 - (right - left)) / 2);
    assert.equal(s.menuScrolls[0].behavior, 'smooth');
    assert.equal(s.menuScrolls[0].top, undefined);
    observer.callback([entry]);
    assert.equal(s.menuScrolls.length, 1);
  }
});

test('visible tabs stay put and reduced motion scrolls clipped tabs immediately', () => {
  const s = setup({ reduced: true });
  const observer = s.observersCreated[2];
  observer.callback([{ target: s.chapters['feature-quran'], isIntersecting: true }]);
  assert.equal(s.menuScrolls.length, 0);
  s.chapterLinks[1].rect = { left: 300, right: 550, width: 250 };
  observer.callback([
    { target: s.chapters['feature-quran'], isIntersecting: false },
    { target: s.chapters['feature-dzikir'], isIntersecting: true },
  ]);
  assert.equal(s.menuScrolls[0].behavior, 'instant');
});
