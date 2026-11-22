// Cron-only Worker: it has no fetch handler and no public URL.
// /up is Rails' health check. It doesn't touch the database, so Neon
// can still suspend while the web service stays awake.
export default {
  async scheduled(_event, env, ctx) {
    ctx.waitUntil(ping(env.TARGET_URL));
  },
};

async function ping(url) {
  const started = Date.now();
  try {
    const res = await fetch(url, {
      headers: { "user-agent": "uat-portal-keepalive" },
      signal: AbortSignal.timeout(25_000),
    });
    console.log(`ping ${res.status} in ${Date.now() - started} ms`);
  } catch (err) {
    // The first ping after a sleep can time out while Render boots the
    // container. The next one, 10 minutes later, finds it awake.
    console.warn(`ping failed after ${Date.now() - started} ms: ${err.message}`);
  }
}
