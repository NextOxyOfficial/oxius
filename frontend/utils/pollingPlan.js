/**
 * How often the web chat is allowed to ask the server anything.
 *
 * Measured before this existed: one open tab made about 56 requests a minute —
 * messages every 3s, the chat list every 5s, the other person's presence every
 * 5s, a heartbeat POST every 5s and the header's unread count every 10s. The
 * chat list is the most expensive endpoint in AdsyConnect, so polling it every
 * five seconds was the single heaviest thing the web client did. None of it
 * stopped when the tab was in the background, so a forgotten tab kept the
 * whole set running all day.
 *
 * The numbers live here, in one place, so they can be reasoned about and
 * tested rather than being scattered across five setInterval calls.
 */

/** Milliseconds between polls, per concern. */
export const POLL_INTERVALS = {
  // The only real-time path the web has until chat moves onto the socket, so
  // this one stays fast — it IS the latency the user feels.
  messages: 3000,
  // The expensive one. The open conversation is covered by `messages`, so this
  // only needs to notice new conversations and other rooms' unread counts.
  chatRooms: 15000,
  // Presence changes are now pushed server-side on connect, disconnect and
  // the heartbeat transition, so this is a safety net rather than the source.
  onlineStatus: 20000,
  // The server treats presence as stale after 90s, so 30s keeps a wide margin
  // and matches what the mobile app sends.
  heartbeat: 30000,
  // A number in the corner of the screen. It does not need to be to the second.
  headerUnread: 30000,
}

/**
 * Whether a timer tick should do anything.
 *
 * Nobody is reading a hidden tab, so every request it makes is waste — and it
 * is the case that lasts longest, because tabs are abandoned rather than
 * closed. Anything other than a browser (SSR, a test) polls normally.
 */
export function shouldPoll(doc = typeof document === 'undefined' ? null : document) {
  if (!doc) return true
  if (typeof doc.visibilityState === 'string') {
    return doc.visibilityState !== 'hidden'
  }
  return doc.hidden !== true
}

/**
 * Requests per minute this plan makes while a tab is visible, for one open
 * conversation. Exists so the cost is something you can assert on rather than
 * something you have to add up by hand.
 */
export function requestsPerMinute(intervals = POLL_INTERVALS) {
  return Object.values(intervals).reduce(
    (total, ms) => total + 60000 / ms,
    0
  )
}
