// Brings the home page's phone mock to life as the app's prayer-times screen:
// today's times for the visitor's approximate location (added by
// site/worker.js, or Jakarta when it isn't known), the next prayer and its
// countdown, the day strip and the Hijri date, calculated as the app does
// (Kemenag RI with the adhan library, Umm al-Qura Hijri dates). Without
// scripts, the static Jakarta mock stays.

import "./experience.js";

import { CalculationMethod, Coordinates, Madhab, PrayerTimes } from "./vendor/adhan.esm.min.js";

// Monas, central Jakarta: the place the static mock shows.
const JAKARTA = { lat: -6.1754, lon: 106.8272, tz: "Asia/Jakarta" };

const phone = document.querySelector(".phone");
if (phone) start(phone);

function start(phone) {
  const known = phone.dataset.lat && phone.dataset.tz;
  const tz = known ? phone.dataset.tz : JAKARTA.tz;
  const coords = known
    ? new Coordinates(Number(phone.dataset.lat), Number(phone.dataset.lon))
    : new Coordinates(JAKARTA.lat, JAKARTA.lon);
  // Kemenag RI, the app's default: Fajr 20°, Isha 18°, Shafi'i Asr.
  const params = CalculationMethod.Other();
  params.fajrAngle = 20;
  params.ishaAngle = 18;
  params.madhab = Madhab.Shafi;

  const t = JSON.parse(phone.dataset.strings);
  const $ = (selector) => phone.querySelector(selector);
  const rows = [...phone.querySelectorAll(".app-list li")];
  const names = rows.map((li) => li.querySelector(".app-pname").textContent);
  const days = [...phone.querySelectorAll(".app-strip li")];
  const place = $(".app-place span");
  // Without a city, the time zone's city is closer than Jakarta.
  const city = known
    ? phone.dataset.city || tz.split("/").pop().replaceAll("_", " ")
    : place.textContent;

  const clock = new Intl.DateTimeFormat("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
    timeZone: tz,
  });
  const gregorian = new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "numeric",
    day: "numeric",
    weekday: "short",
    timeZone: tz,
  });
  const umalqura = new Intl.DateTimeFormat("en-u-ca-islamic-umalqura-nu-latn", {
    year: "numeric",
    month: "numeric",
    day: "numeric",
    timeZone: tz,
  });
  const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  // The calendar date at the location, as numbers (weekday 0 is Sunday).
  const partsOf = (format, date) =>
    Object.fromEntries(
      format
        .formatToParts(date)
        .filter((p) => p.type !== "literal")
        .map((p) => [p.type, p.type === "weekday" ? WEEKDAYS.indexOf(p.value) : parseInt(p.value, 10)]),
    );

  // The five times on the location's calendar day that `date` falls on.
  const timesOn = (date) => {
    const { year, month, day } = partsOf(gregorian, date);
    const times = new PrayerTimes(coords, new Date(year, month - 1, day), params);
    return [times.fajr, times.dhuhr, times.asr, times.maghrib, times.isha];
  };

  const fill = (format, values) => format.replace(/\{(\w+)\}/g, (_, key) => values[key]);
  const two = (n) => String(n).padStart(2, "0");

  place.textContent = city;

  const render = () => {
    const now = new Date();
    const today = timesOn(now);
    let index = today.findIndex((time) => time > now);
    // After Isha, count down to the next day's Fajr, as the app does.
    const next = index >= 0 ? today[index] : timesOn(new Date(now.getTime() + 864e5))[0];
    if (index < 0) index = 0;

    rows.forEach((li, i) => {
      li.querySelector("time").textContent = clock.format(today[i]);
      li.classList.toggle("next", i === index);
    });
    $(".app-name").textContent = names[index];
    $(".app-next time").textContent = clock.format(next);

    const left = Math.max(0, Math.floor((next - now) / 1000));
    $(".app-count span").textContent =
      `${two(Math.floor(left / 3600))}:${two(Math.floor(left / 60) % 60)}:${two(left % 60)}`;

    // Two days either side of today, today in the middle.
    days.forEach((li, i) => {
      const d = partsOf(gregorian, new Date(now.getTime() + (i - 2) * 864e5));
      li.querySelector("span").textContent = t.weekdays_short[d.weekday];
      li.querySelector("b").textContent = d.day;
      const month = li.querySelector("small");
      if (month) month.textContent = t.months_short[d.month - 1];
    });
    const d = partsOf(gregorian, now);
    $(".app-date strong").textContent = fill(t.date_format, {
      weekday: t.weekdays[d.weekday],
      month: t.months[d.month - 1],
      day: d.day,
    });
    const h = partsOf(umalqura, now);
    $(".app-date span").textContent = fill(t.hijri_format, {
      day: h.day,
      month: t.hijri_months[h.month - 1],
      year: h.year,
    });

    phone.setAttribute(
      "aria-label",
      phone.dataset.label.replace("{place}", city).replace("{next}", names[index]),
    );
  };

  render();
  setInterval(render, 1000);
}
