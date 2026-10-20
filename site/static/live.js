// Brings the home page's phone mock to life: today's prayer times for the
// visitor's approximate location (added by site/worker.js), the next prayer,
// the Hijri date and a ticking countdown, calculated as the app does
// (Kemenag RI with the adhan library, Umm al-Qura Hijri dates). Without the
// location or without scripts, the static Jakarta mock stays.

import { CalculationMethod, Coordinates, Madhab, PrayerTimes } from "./vendor/adhan.esm.min.js";

const phone = document.querySelector(".phone[data-lat][data-tz]");
if (phone) start(phone);

function start(phone) {
  const tz = phone.dataset.tz;
  const coords = new Coordinates(Number(phone.dataset.lat), Number(phone.dataset.lon));
  // Kemenag RI, the app's default: Fajr 20°, Isha 18°, Shafi'i Asr.
  const params = CalculationMethod.Other();
  params.fajrAngle = 20;
  params.ishaAngle = 18;
  params.madhab = Madhab.Shafi;

  const rows = [...phone.querySelectorAll(".phone-list li")];
  const names = rows.map((li) => li.querySelector("span").textContent);
  const place = phone.querySelector(".phone-place").lastChild;
  const hijri = phone.querySelector(".phone-hijri");
  const months = JSON.parse(hijri.dataset.months);
  const nextName = phone.querySelector(".phone-name");
  const count = phone.querySelector(".phone-count");
  const city = phone.dataset.city || place.textContent;

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
    timeZone: tz,
  });
  const umalqura = new Intl.DateTimeFormat("en-u-ca-islamic-umalqura-nu-latn", {
    year: "numeric",
    month: "numeric",
    day: "numeric",
    timeZone: tz,
  });

  // The calendar date at the visitor's location, as numbers.
  const partsOf = (format, date) =>
    Object.fromEntries(
      format
        .formatToParts(date)
        .filter((p) => p.type !== "literal")
        .map((p) => [p.type, parseInt(p.value, 10)]),
    );

  // The five times on the location's calendar day that `date` falls on.
  const timesOn = (date) => {
    const { year, month, day } = partsOf(gregorian, date);
    const t = new PrayerTimes(coords, new Date(year, month - 1, day), params);
    return [t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha];
  };

  const two = (n) => String(n).padStart(2, "0");

  place.textContent = city;

  const render = () => {
    const now = new Date();
    const today = timesOn(now);
    let index = today.findIndex((t) => t > now);
    // After Isha, count down to the next day's Fajr.
    const next = index >= 0 ? today[index] : timesOn(new Date(now.getTime() + 864e5))[0];
    if (index < 0) index = 0;

    rows.forEach((li, i) => {
      li.querySelector("time").textContent = clock.format(today[i]);
      li.classList.toggle("now", i === index);
    });
    nextName.textContent = names[index];

    const h = partsOf(umalqura, now);
    hijri.textContent = `${h.day} ${months[h.month - 1]} ${h.year}`;

    const left = Math.max(0, Math.floor((next - now) / 1000));
    count.textContent = `${two(Math.floor(left / 3600))}:${two(Math.floor(left / 60) % 60)}:${two(left % 60)}`;

    phone.setAttribute(
      "aria-label",
      phone.dataset.label.replace("{place}", city).replace("{next}", names[index]),
    );
  };

  render();
  setInterval(render, 1000);
}
