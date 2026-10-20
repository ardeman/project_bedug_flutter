// Serves the static site from site/dist. On the home pages it also hands the
// phone mock the visitor's approximate location from Cloudflare's IP
// geolocation, so site/static/live.js can show that place's prayer times.
// Nothing is stored or logged.

export default {
  async fetch(request, env) {
    const response = await env.ASSETS.fetch(request);
    const cf = request.cf;
    const isHtml = (response.headers.get("content-type") || "").startsWith("text/html");
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
