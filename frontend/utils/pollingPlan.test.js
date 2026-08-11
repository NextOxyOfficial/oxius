import { strict as assert } from 'node:assert'
import { describe, it } from 'node:test'

import { POLL_INTERVALS, requestsPerMinute, shouldPoll } from './pollingPlan.js'

describe('shouldPoll', () => {
  it('polls a visible tab', () => {
    assert.equal(shouldPoll({ visibilityState: 'visible', hidden: false }), true)
  })

  it('does not poll a hidden tab', () => {
    assert.equal(shouldPoll({ visibilityState: 'hidden', hidden: true }), false)
  })

  it('falls back to .hidden when visibilityState is missing', () => {
    assert.equal(shouldPoll({ hidden: true }), false)
    assert.equal(shouldPoll({ hidden: false }), true)
  })

  it('polls when there is no document at all (SSR, tests)', () => {
    assert.equal(shouldPoll(null), true)
  })

  it('treats a prerendering tab as pollable, not hidden', () => {
    // Only 'hidden' means nobody can see it; 'prerender' is on its way in.
    assert.equal(shouldPoll({ visibilityState: 'prerender' }), true)
  })
})

describe('the cost of the plan', () => {
  it('is far below the 56 requests a minute it replaced', () => {
    const perMinute = requestsPerMinute()
    assert.ok(
      perMinute < 32,
      `${perMinute} requests/minute is not an improvement on 56`
    )
  })

  it('does not poll the expensive chat list more than 4 times a minute', () => {
    // The chat list was measured at 311 queries and 589ms for 51 rooms. Every
    // 5s meant ~3,700 queries a minute per open tab.
    assert.ok(60000 / POLL_INTERVALS.chatRooms <= 4)
  })

  it('keeps messages fast, because that is the felt latency', () => {
    // Until web chat moves onto the websocket, this interval IS how long a
    // reply takes to appear.
    assert.ok(POLL_INTERVALS.messages <= 3000)
  })

  it('heartbeats well inside the 90-second staleness window', () => {
    assert.ok(POLL_INTERVALS.heartbeat <= 45000)
  })

  it('has no interval fast enough to be an accident', () => {
    for (const [name, ms] of Object.entries(POLL_INTERVALS)) {
      assert.ok(ms >= 3000, `${name} polls every ${ms}ms`)
    }
  })
})
