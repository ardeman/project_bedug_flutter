// Serves the static site from site/dist. On the home pages it also hands the
// phone mock the visitor's approximate location from Cloudflare's IP
// geolocation, so site/static/live.js can show that place's prayer times, and
// counts the visit by where it came from (scripts/site_visits.py reads the
// counts). No IP address, cookie or identifier is stored.

// Instagram's in-app browser sends one of these as the referrer.
const sourceByReferrerHost = {
  "instagram.com": "instagram",
  "l.instagram.com": "instagram",
  "www.instagram.com": "instagram",
  "threads.net": "threads",
  "www.threads.net": "threads",
  "l.threads.net": "threads",
  "facebook.com": "facebook",
  "l.facebook.com": "facebook",
  "m.facebook.com": "facebook",
  "lm.facebook.com": "facebook",
  "www.facebook.com": "facebook",
  "t.co": "x",
};

// Keeps a stored label short and plain, whatever a link or referrer carries.
const maxSourceLength = 40;

// A link's utm_* tag, cleaned to a short plain label ("" when missing).
export function utmTag(url, name) {
  const value = url.searchParams.get(name) || "";
  return value.toLowerCase().replace(/[^a-z0-9._-]/g, "").slice(0, maxSourceLength);
}

export function visitSource(url, referrer) {
  const tagged = utmTag(url, "utm_source");
  if (tagged) return tagged;
  if (!referrer) return "direct";
  let host;
  try {
    host = new URL(referrer).hostname.toLowerCase();
  } catch {
    return "direct";
  }
  if (host === url.hostname) return "internal";
  return sourceByReferrerHost[host] || host.slice(0, maxSourceLength);
}

function countVisit(request, env) {
  // Missing in `wrangler dev` without the binding, and in tests.
  if (!env.VISITS || request.method !== "GET") return;
  const url = new URL(request.url);
  try {
    env.VISITS.writeDataPoint({
      // Host first, so preview URLs can be left out of the counts.
      blobs: [
        url.hostname,
        url.pathname,
        visitSource(url, request.headers.get("referer")),
        request.cf?.country || "",
        utmTag(url, "utm_medium"),
        utmTag(url, "utm_campaign"),
      ],
      doubles: [1],
    });
  } catch {
    // Counting must never break the page.
  }
}

export default {
  async fetch(request, env) {
    const response = await env.ASSETS.fetch(request);
    const cf = request.cf;
    const isHtml = (response.headers.get("content-type") || "").startsWith("text/html");
    if (isHtml && response.ok) countVisit(request, env);
    if (!isHtml || !cf || cf.latitude == null || cf.longitude == null || !cf.timezone) {
      return response;
    }

    const live = new HTMLRewriter()
      .on(".phone", {
        element(el) {
          el.setAttribute("data-lat", String(cf.latitude));
          el.setAttribute("data-lon", String(cf.longitude));
          el.setAttribute("data-tz", cf.timezone);
          if (cf.city) el.setAttribute("data-city", cf.city);
        },
      })
      .transform(response);

    // The page now differs per visitor, so no shared cache or ETag reuse.
    const headers = new Headers(live.headers);
    headers.set("Cache-Control", "private, no-cache");
    headers.delete("ETag");
    return new Response(live.body, { status: live.status, headers });
  },
};
