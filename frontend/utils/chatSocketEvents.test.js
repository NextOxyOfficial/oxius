import { strict as assert } from 'node:assert'
import { describe, it } from 'node:test'

import {
  eventTouchesChatList,
  messagesAfterEvent,
  presenceFromEvent,
  typingFromEvent,
} from './chatSocketEvents.js'

const ROOM = 'room-1'
const OTHER = 'room-2'

const msg = (id, extra = {}) => ({
  id,
  chatroom: ROOM,
  content: `m${id}`,
  message_type: 'text',
  is_read: false,
  is_deleted: false,
  ...extra,
})

describe('a message arriving', () => {
  it('is appended to the open conversation', () => {
    const { changed, messages } = messagesAfterEvent(
      [msg(1)],
      { type: 'new_message', message: msg(2) },
      ROOM
    )
    assert.equal(changed, true)
    assert.deepEqual(messages.map((m) => m.id), [1, 2])
  })

  it('for another conversation is ignored', () => {
    const before = [msg(1)]
    const { changed, messages } = messagesAfterEvent(
      before,
      { type: 'new_message', message: { ...msg(2), chatroom: OTHER } },
      ROOM
    )
    assert.equal(changed, false)
    assert.equal(messages, before)
  })

  it('twice does not duplicate it', () => {
    // The socket and the safety poll can both deliver the same message.
    const after = messagesAfterEvent(
      [msg(1)],
      { type: 'new_message', message: msg(2) },
      ROOM
    ).messages
    const again = messagesAfterEvent(
      after,
      { type: 'new_message', message: msg(2) },
      ROOM
    )
    assert.equal(again.changed, false)
    assert.deepEqual(again.messages.map((m) => m.id), [1, 2])
  })

  it('does not wipe out a message the user just sent', () => {
    const pending = { temp_id: 't1', chatroom: ROOM, content: 'mine' }
    const { messages } = messagesAfterEvent(
      [msg(1), pending],
      { type: 'new_message', message: msg(2) },
      ROOM
    )
    assert.equal(messages.at(-1).temp_id, 't1')
  })
})

describe('an edit or a delete', () => {
  it('replaces the message in place', () => {
    const { changed, messages } = messagesAfterEvent(
      [msg(1), msg(2)],
      {
        type: 'message_edited',
        message: msg(2, { content: 'fixed', is_edited: true }),
      },
      ROOM
    )
    assert.equal(changed, true)
    assert.equal(messages.length, 2)
    assert.equal(messages[1].content, 'fixed')
  })

  it('marks a deleted message rather than adding a second copy', () => {
    const { messages } = messagesAfterEvent(
      [msg(1), msg(2)],
      { type: 'message_deleted', message: msg(2, { is_deleted: true }) },
      ROOM
    )
    assert.equal(messages.length, 2)
    assert.equal(messages[1].is_deleted, true)
  })

  it('for a message not on screen is appended, not dropped', () => {
    // Editing something above the loaded window: better to show it than to
    // silently discard the server's news.
    const { changed, messages } = messagesAfterEvent(
      [msg(2)],
      { type: 'message_edited', message: msg(1, { content: 'older' }) },
      ROOM
    )
    assert.equal(changed, true)
    assert.equal(messages.length, 2)
  })
})

describe('reactions and read receipts', () => {
  it('a reaction updates that message only', () => {
    const { changed, messages } = messagesAfterEvent(
      [msg(1), msg(2)],
      { type: 'message_reaction', message_id: 2, reactions: { '❤️': ['u1'] } },
      ROOM
    )
    assert.equal(changed, true)
    assert.deepEqual(messages[1].reactions, { '❤️': ['u1'] })
    assert.equal(messages[0].reactions, undefined)
  })

  it('a reaction on a message not loaded changes nothing', () => {
    const before = [msg(1)]
    const result = messagesAfterEvent(
      before,
      { type: 'message_reaction', message_id: 99, reactions: {} },
      ROOM
    )
    assert.equal(result.changed, false)
    assert.equal(result.messages, before)
  })

  it('a read receipt marks the listed messages read', () => {
    const { changed, messages } = messagesAfterEvent(
      [msg(1), msg(2)],
      {
        type: 'message_read',
        message_ids: [1, 2],
        read_at: '2026-08-11T10:00:00Z',
      },
      ROOM
    )
    assert.equal(changed, true)
    assert.ok(messages.every((m) => m.is_read))
    assert.equal(messages[0].read_at, '2026-08-11T10:00:00Z')
  })

  it('a read receipt for nothing in particular is ignored', () => {
    const before = [msg(1)]
    assert.equal(
      messagesAfterEvent(before, { type: 'message_read' }, ROOM).changed,
      false
    )
  })
})

describe('frames that are not about messages', () => {
  for (const type of [
    'connection_ready',
    'pong',
    'user_online_status',
    'typing_status',
    'incoming_call',
    'call_status',
    'bn_notification',
  ]) {
    it(`${type} leaves the thread alone`, () => {
      const before = [msg(1)]
      const result = messagesAfterEvent(before, { type }, ROOM)
      assert.equal(result.changed, false)
      assert.equal(result.messages, before)
    })
  }

  it('junk does not throw', () => {
    assert.equal(messagesAfterEvent([msg(1)], null, ROOM).changed, false)
    assert.equal(messagesAfterEvent([msg(1)], { type: 'new_message' }, ROOM).changed, false)
    assert.equal(messagesAfterEvent(null, { type: 'new_message', message: msg(1) }, ROOM).changed, true)
  })

  it('no open conversation means nothing to apply', () => {
    assert.equal(
      messagesAfterEvent([msg(1)], { type: 'new_message', message: msg(2) }, null).changed,
      false
    )
  })
})

describe('when the expensive chat list needs refetching', () => {
  it('a message in another conversation does', () => {
    assert.equal(
      eventTouchesChatList(
        { type: 'new_message', message: { id: 5, chatroom: OTHER } },
        ROOM
      ),
      true
    )
  })

  it('a new message in the open conversation does — it moves the row', () => {
    assert.equal(
      eventTouchesChatList(
        { type: 'new_message', message: { id: 5, chatroom: ROOM } },
        ROOM
      ),
      true
    )
  })

  it('an edit in the open conversation does not', () => {
    assert.equal(
      eventTouchesChatList(
        { type: 'message_edited', message: { id: 5, chatroom: ROOM } },
        ROOM
      ),
      false
    )
  })

  it('a group message does', () => {
    assert.equal(eventTouchesChatList({ type: 'group_message' }, ROOM), true)
  })

  it('typing, presence and calls do not', () => {
    for (const type of ['typing_status', 'user_online_status', 'call_status']) {
      assert.equal(eventTouchesChatList({ type }, ROOM), false)
    }
  })
})

describe('typing and presence', () => {
  it('typing in the open chat from the other person applies', () => {
    assert.equal(
      typingFromEvent(
        { type: 'typing_status', chatroom_id: ROOM, user_id: 'them', is_typing: true },
        ROOM,
        'me'
      ),
      true
    )
  })

  it('my own typing is not shown back to me', () => {
    assert.equal(
      typingFromEvent(
        { type: 'typing_status', chatroom_id: ROOM, user_id: 'me', is_typing: true },
        ROOM,
        'me'
      ),
      null
    )
  })

  it('typing in another conversation is ignored', () => {
    assert.equal(
      typingFromEvent(
        { type: 'typing_status', chatroom_id: OTHER, user_id: 'them', is_typing: true },
        ROOM,
        'me'
      ),
      null
    )
  })

  it('a group typing frame does not drive the 1:1 bubble', () => {
    // Group frames carry group_id and a null chatroom_id.
    assert.equal(
      typingFromEvent(
        { type: 'typing_status', chatroom_id: null, group_id: 'g1', user_id: 'them', is_typing: true },
        ROOM,
        'me'
      ),
      null
    )
  })

  it('presence for the person on screen applies', () => {
    assert.equal(
      presenceFromEvent(
        { type: 'user_online_status', user_id: 'them', is_online: true },
        'them'
      ),
      true
    )
    assert.equal(
      presenceFromEvent(
        { type: 'user_online_status', user_id: 'them', is_online: false },
        'them'
      ),
      false
    )
  })

  it('presence for anybody else is ignored', () => {
    assert.equal(
      presenceFromEvent(
        { type: 'user_online_status', user_id: 'someone', is_online: true },
        'them'
      ),
      null
    )
  })
})
