/**
 * Reconciling a polled message list with what is already on screen.
 *
 * The web chat used to decide "did anything change?" by comparing list
 * LENGTHS. Every change that keeps the count identical was therefore
 * invisible: an edit, a reaction, a read receipt, a soft-delete (which
 * actually makes the list shorter, so it was ignored too). Delete one message
 * and receive another in the same window and the counts match exactly —
 * nothing updated at all.
 *
 * It also assigned the polled array straight over the top of the local one,
 * which threw away a message the user had just sent and that the server had
 * not acknowledged yet. Worse, sendMessage() then looked for its temporary
 * row by temp_id to swap in the real one, found nothing, and dropped the real
 * message on the floor — the sender's own message vanished until the next
 * poll happened to include it.
 *
 * Both are decided here, on plain data, so they can be tested without a
 * browser or a server.
 */

/** Fields whose change the user can actually see. */
const TRACKED = [
  'content',
  'display_content',
  'is_deleted',
  'is_edited',
  'edited_at',
  'is_read',
  'read_at',
  'media_url',
  'thumbnail_url',
  'message_type',
]

/**
 * A compact string that changes whenever anything visible about the list
 * changes — order, membership, or any tracked field of any message.
 */
export function messagesFingerprint(list) {
  if (!Array.isArray(list)) return ''
  return list
    .map((m) => {
      if (!m || typeof m !== 'object') return String(m)
      const id = m.id ?? m.temp_id ?? ''
      const parts = [id]
      for (const key of TRACKED) {
        // Absent and null must not read as different, or every poll of a
        // message with no media would look like a change.
        parts.push(m[key] === undefined || m[key] === null ? '' : String(m[key]))
      }
      parts.push(reactionsFingerprint(m.reactions))
      return parts.join('')
    })
    .join('')
}

/**
 * Reactions arrive as an object or list keyed by emoji. Order is not
 * meaningful, so it is sorted — otherwise two identical states could look
 * different and trigger a pointless re-render on every poll.
 */
function reactionsFingerprint(reactions) {
  if (!reactions) return ''
  if (Array.isArray(reactions)) {
    return reactions
      .map((r) =>
        r && typeof r === 'object'
          ? `${r.emoji ?? ''}:${r.count ?? (Array.isArray(r.user_ids) ? r.user_ids.length : '')}`
          : String(r)
      )
      .sort()
      .join(',')
  }
  if (typeof reactions === 'object') {
    return Object.keys(reactions)
      .sort()
      .map((emoji) => {
        const value = reactions[emoji]
        const count = Array.isArray(value)
          ? value.length
          : value && typeof value === 'object'
            ? (value.count ?? (Array.isArray(value.user_ids) ? value.user_ids.length : ''))
            : value
        return `${emoji}:${count}`
      })
      .join(',')
  }
  return String(reactions)
}

/**
 * Merge a freshly fetched list into what is on screen.
 *
 * Returns `{ changed, messages }`. When nothing visible differs, `changed` is
 * false and `messages` is the array that was passed in — the caller assigns
 * nothing and Vue re-renders nothing.
 *
 * Messages the user has sent but the server has not confirmed (they carry a
 * `temp_id` and no `id`) are kept on the end. They are the newest thing in
 * the conversation by definition, and dropping them is what made a sent
 * message flicker out of existence.
 */
export function syncMessages(current, incoming) {
  const currentList = Array.isArray(current) ? current : []
  if (!Array.isArray(incoming)) {
    return { changed: false, messages: currentList }
  }

  const confirmed = new Set()
  for (const m of incoming) {
    if (m && m.id !== undefined && m.id !== null) confirmed.add(String(m.id))
  }

  const pending = currentList.filter(
    (m) =>
      m &&
      m.temp_id !== undefined &&
      (m.id === undefined || m.id === null || !confirmed.has(String(m.id)))
  )

  const merged = pending.length ? [...incoming, ...pending] : incoming
  const changed = messagesFingerprint(merged) !== messagesFingerprint(currentList)
  return { changed, messages: changed ? merged : currentList }
}
