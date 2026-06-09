/**
 * Tells the backend which AdsyConnect chat the user is currently viewing, so it
 * skips the push notification for messages they can already see. Heartbeats
 * while the chat stays open (the backend treats a session as "left" after a
 * freshness window), and clears on leave / tab-hide / page-unload.
 */
export function useActiveChat() {
  const { post } = useApi()

  let heartbeat: ReturnType<typeof setInterval> | null = null
  let current: string | null = null

  const report = async (chatroomId: string | null) => {
    try {
      if (chatroomId) {
        await post('/adsyconnect/set-active-chat/', { chatroom_id: chatroomId })
      } else {
        await post('/adsyconnect/clear-active-chat/', {})
      }
    } catch (e) {
      // non-blocking
    }
  }

  const onVisibility = () => {
    if (!current) return
    if (document.hidden) {
      report(null) // tab hidden -> not actively viewing, allow push
    } else {
      report(current) // back in view
    }
  }

  const onUnload = () => {
    // Best-effort clear when the tab/browser closes.
    try {
      const url = useRuntimeConfig().public.apiBase || ''
      navigator.sendBeacon?.(`${url}/adsyconnect/clear-active-chat/`)
    } catch (e) {
      // ignore
    }
  }

  const enterChat = (chatroomId: string) => {
    if (!chatroomId) return
    current = chatroomId
    report(chatroomId)
    if (heartbeat) clearInterval(heartbeat)
    // Refresh well within the backend freshness window so an open chat never
    // looks "stale".
    heartbeat = setInterval(() => {
      if (current) report(current)
    }, 60_000)
    if (process.client) {
      document.addEventListener('visibilitychange', onVisibility)
      window.addEventListener('beforeunload', onUnload)
    }
  }

  const leaveChat = () => {
    const had = current
    current = null
    if (heartbeat) {
      clearInterval(heartbeat)
      heartbeat = null
    }
    if (process.client) {
      document.removeEventListener('visibilitychange', onVisibility)
      window.removeEventListener('beforeunload', onUnload)
    }
    if (had) report(null)
  }

  return { enterChat, leaveChat }
}
