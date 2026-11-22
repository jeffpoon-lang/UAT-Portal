# Keep-alive Worker

A Cloudflare Worker that requests `https://uat-portal-ur56.onrender.com/up` every 10 minutes, so the Render free-tier service never goes to sleep and nobody sees the cold-start loading page.

## Why it stays free

- **Cloudflare:** cron triggers are included in the Workers free plan, and 144 short runs a day is a tiny fraction of its limits.
- **Render:** a free web service that never sleeps runs for about 744 hours a month, which fits inside the 750 free instance hours each workspace gets. **This only works while UAT Portal is the only free web service in the workspace.** With a second free service, the workspace runs out of hours before the month ends and Render suspends every free service until the next month.
- **Neon:** `/up` is Rails' health check and never queries the database, so Neon still suspends when nobody uses the app. The first real request after a quiet spell waits about a second for Neon to wake.

## Deploy

With Wrangler (needs a Cloudflare API token made from the "Edit Cloudflare Workers" template):

```bash
cd ops/keepalive
CLOUDFLARE_API_TOKEN=... CLOUDFLARE_ACCOUNT_ID=... npx wrangler@4 deploy
```

Or by hand in the Cloudflare dashboard:

1. Workers & Pages → Create → Worker. Name it `uat-portal-keepalive`.
2. Replace the code with `src/index.js` and deploy.
3. Settings → Variables: add `TARGET_URL` = `https://uat-portal-ur56.onrender.com/up`.
4. Settings → Triggers → Cron Triggers: add `*/10 * * * *`.

## Check it works

- Workers & Pages → `uat-portal-keepalive` → Logs shows `ping 200` every 10 minutes. Rails doesn't log `/up` requests (`silence_healthcheck_path`), so Render's logs stay quiet.
- After an hour with no visitors, the site should open straight away.

## Try it locally

```bash
cd ops/keepalive
npx wrangler@4 dev --test-scheduled
curl "http://localhost:8787/__scheduled?cron=*/10+*+*+*+*"
```

## Stop it

Delete the Worker, or remove its cron trigger. If the app moves to a paid Render plan, which never sleeps, the Worker is no longer needed.
