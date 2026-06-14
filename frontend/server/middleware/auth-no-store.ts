/**
 * Never let an intermediary (Cloudflare/proxy) cache an authenticated SSR page.
 *
 * A logged-in user's rendered HTML embeds their private data — and the auth
 * token — in the Nuxt payload. If a "cache everything" edge rule stored that
 * page and replayed it to another visitor, the second user would be silently
 * logged in as the first (the account-switch / data-leak bug seen when going
 * verification → settings). Marking every logged-in request `no-store` keeps
 * those personalized responses out of any shared cache, while anonymous pages
 * stay cacheable.
 */
export default defineEventHandler((event) => {
  const cookie = getRequestHeader(event, 'cookie') || ''
  const auth = getRequestHeader(event, 'authorization') || ''

  const isAuthed =
    !!auth ||
    /(?:^|;\s*)adsyclub-jwt=[^;]/.test(cookie) ||
    /(?:^|;\s*)adsyclub-refresh=[^;]/.test(cookie) ||
    /(?:^|;\s*)sessionid=[^;]/.test(cookie)

  if (isAuthed) {
    setResponseHeader(event, 'Cache-Control', 'no-store, no-cache, private, max-age=0')
    setResponseHeader(event, 'Vary', 'Cookie, Authorization')
  }
})
