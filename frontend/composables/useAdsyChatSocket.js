/**
 * The web's chat websocket.
 *
 * The mobile app has had this from the start; the web had nothing and leaned
 * entirely on polling — messages every 3s, the chat list every 5s, presence
 * every 5s. That is both slow (a reply takes up to three seconds to appear)
 * and expensive (the chat list is the heaviest endpoint in AdsyConnect).
 *
 * The socket is the same `ws/chat/<user_id>/` the app connects to, so there is
 * no new server surface: the events, the auth and the reconnect behaviour are
 * all already proven. Polling stays, slowed right down, as the safety net for
 * a socket that will not open — corporate proxies still block them.
 */

const RECONNECT_CEILING_MS = 8000
const CLOSE_CODES_NOT_WORTH_RETRYING = [4001, 4003, 4004, 1008]

export function useAdsyChatSocket() {
  const runtimeConfig = useRuntimeConfig()
  const socket = useState('adsy-chat-socket', () => null)
  const connectionState = useState('adsy-chat-socket-state', () => 'idle')
  const lastEvent = useState('adsy-chat-last-event', () => null)

  const buildUrl = async () => {
    const { getValidToken, user } = useAuth()
    const userId = user.value?.user?.id || user.value?.id
    if (!userId) return null

    const token = (await getValidToken()) || useCookie('adsyclub-jwt').value
    if (!token) return null

    const baseUrl = runtimeConfig.public.baseURL || ''
    const wsBase = baseUrl.startsWith('https://')
      ? baseUrl.replace('https://', 'wss://')
      : baseUrl.replace('http://', 'ws://')
    return `${wsBase}/ws/chat/${userId}/?token=${encodeURIComponent(token)}`
  }

  /**
   * Open the socket. Returns a disconnect function.
   *
   * [onMessage] receives every decoded frame — new_message, group_message,
   * message_edited, message_deleted, message_reaction, typing_status,
   * message_read, user_online_status, bn_notification, and the call events.
   */
  const connect = (onMessage) => {
    if (typeof window === 'undefined') return () => {}

    let attempts = 0
    let reconnectTimer = null
    let shouldReconnect = true

    const open = async () => {
      connectionState.value = attempts > 0 ? 'reconnecting' : 'connecting'
      const url = await buildUrl()
      if (!url) {
        // Not signed in, or no token yet. Polling carries the chat until the
        // caller tries again.
        connectionState.value = 'failed'
        return
      }

      let ws
      try {
        ws = new WebSocket(url)
      } catch (error) {
        connectionState.value = 'failed'
        return
      }
      socket.value = ws

      ws.onopen = () => {
        attempts = 0
        connectionState.value = 'connected'
      }

      ws.onmessage = (event) => {
        let payload
        try {
          payload = JSON.parse(event.data)
        } catch (error) {
          return
        }
        // connection_ready is the server saying the socket works; it carries
        // nothing a screen needs, but it is what lets polling back off.
        lastEvent.value = payload
        try {
          onMessage?.(payload)
        } catch (error) {
          console.error('chat socket handler failed:', error)
        }
      }

      ws.onerror = () => {
        connectionState.value = 'error'
      }

      ws.onclose = (event) => {
        socket.value = null
        if (!shouldReconnect) {
          connectionState.value = 'closed'
          return
        }
        // A rejected token or a mismatched user id will be rejected again.
        if (CLOSE_CODES_NOT_WORTH_RETRYING.includes(event.code)) {
          connectionState.value = 'failed'
          return
        }
        attempts += 1
        connectionState.value = 'reconnecting'
        reconnectTimer = setTimeout(
          open,
          Math.min(1000 * attempts, RECONNECT_CEILING_MS)
        )
      }
    }

    open()

    return () => {
      shouldReconnect = false
      if (reconnectTimer) clearTimeout(reconnectTimer)
      try {
        socket.value?.close()
      } catch (error) {
        // Already gone.
      }
      socket.value = null
      connectionState.value = 'closed'
    }
  }

  const isConnected = computed(() => connectionState.value === 'connected')

  const send = (payload) => {
    if (socket.value?.readyState === WebSocket.OPEN) {
      socket.value.send(JSON.stringify(payload))
      return true
    }
    return false
  }

  return { connect, send, isConnected, connectionState, lastEvent }
}
