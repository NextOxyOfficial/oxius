// Run with: npm test  (Node's built-in runner — no framework needed)
import { strict as assert } from 'node:assert'
import { describe, it } from 'node:test'

import { messagesFingerprint, syncMessages } from './chatMessageSync.js'

const msg = (id, extra = {}) => ({
  id,
  content: `m${id}`,
  message_type: 'text',
  is_read: false,
  is_deleted: false,
  is_edited: false,
  ...extra,
})

describe('the changes the old length check could not see', () => {
  it('notices an edit', () => {
    const before = [msg(1), msg(2)]
    const after = [msg(1), msg(2, { content: 'fixed typo', is_edited: true })]
    const { changed, messages } = syncMessages(before, after)
    assert.equal(changed, true)
    assert.equal(messages[1].content, 'fixed typo')
  })

  it('notices a soft-delete, which makes the list no longer', () => {
    const before = [msg(1), msg(2)]
    const after = [msg(1), msg(2, { is_deleted: true, content: '' })]
    assert.equal(syncMessages(before, after).changed, true)
  })

  it('notices a delete that drops a message from the list entirely', () => {
    assert.equal(syncMessages([msg(1), msg(2)], [msg(1)]).changed, true)
  })

  it('notices a reaction', () => {
    const before = [msg(1, { reactions: {} })]
    const after = [msg(1, { reactions: { '❤️': ['u1'] } })]
    assert.equal(syncMessages(before, after).changed, true)
  })

  it('notices a reaction changing count', () => {
    const before = [msg(1, { reactions: { '❤️': ['u1'] } })]
    const after = [msg(1, { reactions: { '❤️': ['u1', 'u2'] } })]
    assert.equal(syncMessages(before, after).changed, true)
  })

  it('notices a read receipt', () => {
    const before = [msg(1)]
    const after = [msg(1, { is_read: true, read_at: '2026-08-11T10:00:00Z' })]
    assert.equal(syncMessages(before, after).changed, true)
  })

  it('notices the exact case that used to freeze the thread', () => {
    // One message deleted, one new one arrives: the counts match, so the old
    // `newMessages.length > messages.length` check saw nothing and the thread
    // stopped updating.
    const before = [msg(1), msg(2)]
    const after = [msg(1), msg(3)]
    const { changed, messages } = syncMessages(before, after)
    assert.equal(changed, true)
    assert.deepEqual(messages.map((m) => m.id), [1, 3])
  })
})

describe('not re-rendering for nothing', () => {
  it('an identical list is not a change', () => {
    const before = [msg(1), msg(2)]
    const { changed, messages } = syncMessages(before, [msg(1), msg(2)])
    assert.equal(changed, false)
    // Same array back, so the caller assigns nothing.
    assert.equal(messages, before)
  })

  it('absent and null read the same', () => {
    const before = [{ id: 1, content: 'hi' }]
    const after = [{ id: 1, content: 'hi', media_url: null, edited_at: null }]
    assert.equal(syncMessages(before, after).changed, false)
  })

  it('reaction order is not a change', () => {
    const before = [msg(1, { reactions: { '❤️': ['u1'], '👍': ['u2'] } })]
    const after = [msg(1, { reactions: { '👍': ['u2'], '❤️': ['u1'] } })]
    assert.equal(syncMessages(before, after).changed, false)
  })

  it('a new message is a change', () => {
    assert.equal(syncMessages([msg(1)], [msg(1), msg(2)]).changed, true)
  })
})

describe('a message the user just sent', () => {
  it('survives a poll that has not seen it yet', () => {
    const pending = { temp_id: 't1', content: 'just sent', sender: { id: 'me' } }
    const before = [msg(1), pending]
    const { changed, messages } = syncMessages(before, [msg(1)])
    // Nothing visible changed: the polled list plus the pending row is what
    // was already on screen.
    assert.equal(changed, false)
    assert.equal(messages.at(-1).temp_id, 't1')
  })

  it('is replaced, not duplicated, once the server confirms it', () => {
    const pending = { temp_id: 't1', id: 9, content: 'just sent' }
    const before = [msg(1), pending]
    const { messages } = syncMessages(before, [msg(1), msg(9, { content: 'just sent' })])
    assert.deepEqual(messages.map((m) => m.id), [1, 9])
    assert.equal(messages.filter((m) => m.temp_id === 't1').length, 0)
  })

  it('stays on the end while another poll brings other traffic', () => {
    const pending = { temp_id: 't1', content: 'mine' }
    const { changed, messages } = syncMessages([msg(1), pending], [msg(1), msg(2)])
    assert.equal(changed, true)
    assert.deepEqual(messages.map((m) => m.id ?? m.temp_id), [1, 2, 't1'])
  })
})

describe('bad input does not break the thread', () => {
  it('a failed fetch (null) leaves the list alone', () => {
    const before = [msg(1)]
    const { changed, messages } = syncMessages(before, null)
    assert.equal(changed, false)
    assert.equal(messages, before)
  })

  it('an empty screen filling up is a change', () => {
    assert.equal(syncMessages([], [msg(1)]).changed, true)
  })

  it('an empty response after a cleared chat is a change', () => {
    assert.equal(syncMessages([msg(1)], []).changed, true)
  })

  it('fingerprinting junk does not throw', () => {
    assert.equal(messagesFingerprint(null), '')
    assert.equal(typeof messagesFingerprint([null, 5, 'x']), 'string')
  })
})
