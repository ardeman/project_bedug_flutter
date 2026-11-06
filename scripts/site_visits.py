#!/usr/bin/env python3
"""Shows how many home-page visits bedug.ardeman.com had, by source.

The site's Worker (site/worker.js) counts each home-page visit in the Workers
Analytics Engine dataset `bedug_site_visits`, labelled with its `utm_source`
or, without one, the referrer (Instagram, Facebook, ...) or "direct".

Needs CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_ANALYTICS_TOKEN (a token with the
"Account Analytics: Read" permission) in the environment.
The token has its own name because wrangler reads CLOUDFLARE_API_TOKEN, and a
read-only token there would break `wrangler dev` and deploys.

    python3 scripts/site_visits.py              # last 30 days, by source
    python3 scripts/site_visits.py --days 7 --by country --source instagram
    python3 scripts/site_visits.py --source instagram --by campaign   # bio vs posts
"""

import argparse
import json
import os
import re
import sys
import urllib.request

DATASET = "bedug_site_visits"
HOST = "bedug.ardeman.com"
# The Worker writes blobs as host, path, source, country, utm_medium, utm_campaign.
COLUMNS = {
    "source": "blob3",
    "medium": "blob5",
    "campaign": "blob6",
    "path": "blob2",
    "country": "blob4",
    "day": "toStartOfDay(timestamp)",
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--days", type=int, default=30, help="how far back to count (Analytics Engine keeps 90 days)")
    parser.add_argument("--by", choices=COLUMNS, default="source", help="what to group the visits by")
    parser.add_argument("--source", help="count only visits from this source, e.g. instagram")
    args = parser.parse_args()

    account = os.environ.get("CLOUDFLARE_ACCOUNT_ID")
    token = os.environ.get("CLOUDFLARE_ANALYTICS_TOKEN")
    if not account or not token:
        print("Set CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_ANALYTICS_TOKEN (Account Analytics: Read).", file=sys.stderr)
        return 1

    where = f"blob1 = '{HOST}' AND timestamp > NOW() - INTERVAL '{max(1, args.days)}' DAY"
    if args.source:
        if not re.fullmatch(r"[a-z0-9._-]+", args.source):
            print("--source takes letters, digits, '.', '_' or '-'.", file=sys.stderr)
            return 1
        where += f" AND blob3 = '{args.source}'"
    group = COLUMNS[args.by]
    order = "label" if args.by == "day" else "visits DESC"
    # Analytics Engine samples heavy traffic; _sample_interval scales it back.
    sql = (
        f"SELECT {group} AS label, SUM(_sample_interval) AS visits FROM {DATASET} "
        f"WHERE {where} GROUP BY label ORDER BY {order} FORMAT JSON"
    )

    request = urllib.request.Request(
        f"https://api.cloudflare.com/client/v4/accounts/{account}/analytics_engine/sql",
        data=sql.encode(),
        headers={"Authorization": f"Bearer {token}"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request) as response:
            rows = json.load(response)["data"]
    except urllib.error.HTTPError as error:
        print(f"Cloudflare answered {error.code}: {error.read().decode()[:300]}", file=sys.stderr)
        return 1

    if not rows:
        print(f"No visits in the last {args.days} days.")
        return 0
    width = max(len(str(row["label"]) or "-") for row in rows)
    total = 0
    for row in rows:
        visits = int(float(row["visits"]))
        total += visits
        print(f"{str(row['label']) or '-':<{width}}  {visits:>7}")
    print(f"{'total':<{width}}  {total:>7}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
