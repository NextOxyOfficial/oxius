/**
 * Turning a chat socket frame into a state change.
 *
 * Kept apart from the composable and from the socket itself so the rules —
 * which event touches which list, and when nothing should change — are plain
 * data in, plain data out, and can be tested without a browser or a server.
 *
 * The server's vocabulary (see adsyconnect/consumers.py):
 *   new_message · group_message · message_edited · message_deleted
 *   message_reaction · typing_status · message_read · user_online_status
 *   connection_ready · incoming_call · call_status · bn_notification
 */
import { syncMessages } from './chatMessageSync.js'

/** Events that carry a whole message for the open conversation. */
const MESSAGE_EVENTS = new Set([
  'new_message',
  'message_edited',
  'message_deleted',
])

/**
 * Apply one frame to the open conversation's message list.
 *
 * Returns `{ changed, messages }` with the same contract as syncMessages: when
 * nothing applies, `changed` is false and the array passed in comes back
 * untouched so the caller assigns nothing.
 */
export function messagesAfterEvent(current, event, activeChatId) {
  const list = Array.isArray(current) ? current : []
  if (!event || typeof event !== 'object' || !activeChatId) {
    return { changed: false, messages: list }
  }

  if (MESSAGE_EVENTS.has(event.type)) {
    const message = event.message
    if (!message || typeof message !== 'object') {
      return { changed: false, messages: list }
    }
    // Every frame arrives on the user's own channel, for all their chats.
    const room = message.chatroom ?? message.chatroom_id
    if (String(room) !== String(activeChatId)) {
      return { changed: false, messages: list }
    }

    const id = message.id === undefined ? null : String(message.id)
    const index = id === null
      ? -1
      : list.findIndex((m) => String(m.id) === id)

    // An edit or a delete replaces in place; a new message goes on the end.
    // Reusing syncMessages keeps one definition of "did anything visible
    // change" and preserves a message the user has sent but the server has
    // not confirmed.
    const merged = index >= 0
      ? list.map((m, i) => (i === index ? message : m))
      : [...list, message]
    return syncMessages(list, merged)
  }

  if (event.type === 'message_reaction') {
    const id = event.message_id === undefined ? null : String(event.message_id)
    if (id === null) return { changed: false, messages: list }
    const index = list.findIndex((m) => String(m.id) === id)
    if (index < 0) return { changed: false, messages: list }
    const merged = list.map((m, i) =>
      i === index ? { ...m, reactions: event.reactions } : m
    )
    return syncMessages(list, merged)
  }

  if (event.type === 'message_read') {
    const ids = new Set(
      [
        ...(Array.isArray(event.message_ids) ? event.message_ids : []),
        ...(event.message_id ? [event.message_id] : []),
      ].map(String)
    )
    if (!ids.size) return { changed: false, messages: list }
    const merged = list.map((m) =>
      ids.has(String(m.id))
        ? { ...m, is_read: true, read_at: event.read_at ?? m.read_at }
        : m
    )
    return syncMessages(list, merged)
  }

  return { changed: false, messages: list }
}

/**
 * Does this frame mean the chat LIST is stale?
 *
 * A message in a conversation the user is not looking at changes that row's
 * preview and unread badge, and the list is the expensive endpoint — so it is
 * worth being precise about when to refetch it rather than doing so on every
 * frame.
 */
export function eventTouchesChatList(event, activeChatId) {
  if (!event || typeof event !== 'object') return false
  if (event.type === 'group_message') return true
  if (!MESSAGE_EVENTS.has(event.type)) return false

  const message = event.message
  if (!message || typeof message !== 'object') return false
  const room = message.chatroom ?? message.chatroom_id
  // The open conversation's own row is kept in step locally; anything else
  // needs the server's version of the list.
  if (activeChatId && String(room) === String(activeChatId)) {
    // ...except a NEW message, which moves the row to the top and changes its
    // preview.
    return event.type === 'new_message'
  }
  return true
}

/**
 * Whether this frame says the other person in the open chat is typing.
 * Returns null when the event says nothing about it.
 */
export function typingFromEvent(event, activeChatId, myUserId) {
  if (!event || event.type !== 'typing_status') return null
  if (!activeChatId) return null
  if (String(event.chatroom_id ?? '') !== String(activeChatId)) return null
  if (myUserId && String(event.user_id) === String(myUserId)) return null
  return Boolean(event.is_typing)
}

/**
 * Whether this frame changes the presence of the person in the open chat.
 * Returns null when it does not apply.
 */
export function presenceFromEvent(event, otherUserId) {
  if (!event || event.type !== 'user_online_status') return null
  if (!otherUserId) return null
  if (String(event.user_id) !== String(otherUserId)) return null
  return Boolean(event.is_online)
}
