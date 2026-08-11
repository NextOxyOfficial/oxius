import { ref, computed, nextTick } from 'vue'
import { useToast } from '#ui/composables/useToast'
import { syncMessages } from '~/utils/chatMessageSync'
import { POLL_INTERVALS, shouldPoll } from '~/utils/pollingPlan'
import {
  eventTouchesChatList,
  messagesAfterEvent,
  presenceFromEvent,
  typingFromEvent,
} from '~/utils/chatSocketEvents'

/**
 * AdsyConnect Chat Composable
 * Uses API polling for real-time updates
 * 
 * IMPORTANT: State is defined OUTSIDE the function to be shared across all components
 */

// Shared state - defined outside the function so it's shared across all usages
const chatRooms = ref([])
const activeChat = ref(null)
const messages = ref([])
const newMessage = ref('')
const isLoading = ref(false)
const isLoadingMessages = ref(false)
const onlineUsers = ref(new Map()) // Track online user IDs with their status
const otherUserOnline = ref(false) // Is the other user in active chat online?
const lastOnlineCheck = ref(null) // Track last online check time
const currentUserId = ref(null) // Store current user ID for message identification

// Polling intervals
let pollingInterval = null
let onlineStatusInterval = null
let heartbeatInterval = null // Heartbeat to keep user online
let chatRoomsPollingInterval = null // Poll for new chat rooms/messages in list
let headerPollingInterval = null // Poll for unread count in headers (global)
let visibilityCatchUpInstalled = false // one listener per page, not per caller
let disconnectSocket = null // teardown for the chat websocket
let socketConnected = null // ref from the socket composable
let socketIdleTick = 0 // how many message polls the socket has let us skip
const otherUserTyping = ref(false) // driven by the socket, polled as a fallback

export const useAdsyChat = () => {
  const toast = useToast()
  const { get, post } = useApi()
  
  // Get current user ID from auth
  const { user } = useAuth()
  
  // Update current user ID when available
  const updateCurrentUserId = () => {
    const userId = user.value?.user?.id || user.value?.id
    if (userId) {
      currentUserId.value = userId
    }
  }

  // Reply messages embed their context as
  //   `<↩️> (uuid) Sender: quoted preview\n\nActual message`.
  // The realtime websocket sends the raw content, so strip the header here the
  // same way the backend get_preview() does — otherwise the chat list would
  // briefly leak the raw "(uuid) Sender:" header until the next reload.
  const cleanReplyPreview = (content) => {
    if (!content) return content
    const text = content.replace(/^\s+/, '')
    const prefixes = ['↩️', 'â†©ï¸', '↩']
    const matched = prefixes.find(p => text.startsWith(p))
    if (!matched) return content
    const sepIndex = text.indexOf('\n\n')
    if (sepIndex !== -1) {
      const body = text.slice(sepIndex + 2).trim()
      if (body) return body
    }
    let rest = text.slice(matched.length).trim()
    if (rest.startsWith('(')) {
      const close = rest.indexOf(')')
      if (close !== -1) rest = rest.slice(close + 1).trim()
    }
    const colon = rest.indexOf(':')
    if (colon !== -1) rest = rest.slice(colon + 1).trim()
    return rest || 'Reply'
  }

  const updateChatRoomLastMessage = (message) => {
    const chatRoom = chatRooms.value.find(chat => chat.id === message.chatroom)
    if (chatRoom) {
      chatRoom.last_message_at = message.created_at
      chatRoom.last_message_preview = cleanReplyPreview(message.content) || 'Media message'
      
      // Move to top of list
      const index = chatRooms.value.indexOf(chatRoom)
      if (index > 0) {
        chatRooms.value.splice(index, 1)
        chatRooms.value.unshift(chatRoom)
      }
    }
  }

  // API functions
  const loadChatRooms = async (fetchOnlineStatus = true) => {
    // Ensure we have current user ID for message identification
    updateCurrentUserId()
    
    isLoading.value = true
    try {
      const { data, error } = await get('/adsyconnect/chatrooms/')
      if (data && !error) {
        chatRooms.value = data.results || data || []
        
        // Fetch online status for all other users in chat rooms
        if (fetchOnlineStatus && chatRooms.value.length > 0) {
          const userIds = chatRooms.value
            .map(chat => chat.other_user?.id)
            .filter(id => id)
          if (userIds.length > 0) {
            await fetchOnlineStatusForUsers(userIds)
          }
        }
      }
    } catch (error) {
      toast.add({
        title: 'Error',
        description: 'Failed to load chat rooms',
        color: 'red',
        timeout: 3000,
      })
    } finally {
      isLoading.value = false
    }
  }

  // Silent refresh for polling - doesn't show loading state
  const refreshChatRoomsSilently = async () => {
    try {
      const { data, error } = await get('/adsyconnect/chatrooms/')
      if (data && !error) {
        const newChatRooms = data.results || data || []
        
        // Merge new data while preserving local state (is_online, unread_count for active chat)
        newChatRooms.forEach(newChat => {
          const existingChat = chatRooms.value.find(c => c.id === newChat.id)
          if (existingChat) {
            // Preserve is_online status from our polling
            if (existingChat.other_user?.is_online !== undefined) {
              newChat.other_user = newChat.other_user || {}
              newChat.other_user.is_online = existingChat.other_user.is_online
            }
            // If this is the active chat, keep unread_count at 0 (user is viewing it)
            if (activeChat.value?.id === newChat.id) {
              newChat.unread_count = 0
            }
          }
        })
        
        // Check if there are meaningful changes (new messages for non-active chats, new chats)
        const hasChanges = newChatRooms.some((newChat) => {
          const existingChat = chatRooms.value.find(c => c.id === newChat.id)
          if (!existingChat) return true // New chat room
          // Only count as change if it's not the active chat and has new messages
          if (activeChat.value?.id !== newChat.id) {
            return existingChat.last_message_at !== newChat.last_message_at
          }
          return false
        })
        
        if (hasChanges || newChatRooms.length !== chatRooms.value.length) {
          chatRooms.value = newChatRooms
        }
      }
    } catch (error) {
      // Silently handle polling errors
    }
  }

  const loadMessages = async (chatRoomId) => {
    if (!chatRoomId) return
    
    isLoadingMessages.value = true
    try {
      const { data, error } = await get(`/adsyconnect/messages/?chatroom=${chatRoomId}`)
      if (data && !error) {
        messages.value = data.results || data || []
        await nextTick()
        // Force scroll to bottom after loading messages
        setTimeout(() => scrollToBottom(true), 200)
      }
    } catch (error) {
      toast.add({
        title: 'Error',
        description: 'Failed to load messages',
        color: 'red',
        timeout: 3000,
      })
    } finally {
      isLoadingMessages.value = false
    }
  }

  const sendMessage = async () => {
    if (!newMessage.value.trim() || !activeChat.value) return

    // Ensure we have current user ID
    updateCurrentUserId()
    
    const tempId = Date.now().toString()
    const tempMessage = {
      temp_id: tempId,
      content: newMessage.value.trim(),
      sender: { id: currentUserId.value }, // Use actual user ID for proper message alignment
      message_type: 'text',
      created_at: new Date().toISOString(),
      is_read: false
    }

    // Add temporary message to UI immediately (shows on right side)
    messages.value.push(tempMessage)
    const messageContent = newMessage.value.trim()
    newMessage.value = ''
    scrollToBottom()

    // Send via API
    try {
      const { data, error } = await post('/adsyconnect/messages/', {
        chatroom: activeChat.value.id,
        receiver: activeChat.value.other_user?.id,
        message_type: 'text',
        content: messageContent,
      })

      if (data && !error) {
        // Replace temp message with real message
        const index = messages.value.findIndex(m => m.temp_id === tempId)
        if (index !== -1) {
          messages.value[index] = data
        } else if (!messages.value.some(m => String(m.id) === String(data.id))) {
          // The temporary row is gone — a poll landed in the window between
          // sending and the reply. Dropping the real message here is what
          // made the sender's own message disappear until a later poll
          // happened to include it.
          messages.value.push(data)
        }
        
        // Update chat room last message
        updateChatRoomLastMessage(data)
        scrollToBottom()
      } else {
        throw new Error('Failed to send message')
      }
    } catch (error) {
      // Remove failed message
      messages.value = messages.value.filter(m => m.temp_id !== tempId)
      toast.add({
        title: 'Error',
        description: 'Failed to send message',
        color: 'red',
        timeout: 3000,
      })
    }
  }

  // Get or create chat room with a specific user
  const getOrCreateChatRoom = async (userId) => {
    try {
      const { data, error } = await post('/adsyconnect/chatrooms/get_or_create/', {
        user_id: userId
      })
      if (data && !error) {
        return data
      }
      throw new Error('Failed to get or create chat room')
    } catch (error) {
      console.error('Error getting or creating chat room:', error)
      throw error
    }
  }

  const selectChat = async (chat) => {
    if (!chat || !chat.id) return
    
    activeChat.value = chat
    
    // Clear unread count for this chat immediately in UI
    const chatRoom = chatRooms.value.find(c => c.id === chat.id)
    if (chatRoom && chatRoom.unread_count > 0) {
      chatRoom.unread_count = 0
      
      // Mark messages as read on the server (endpoint is mark_as_read with underscore)
      try {
        await post(`/adsyconnect/chatrooms/${chat.id}/mark_as_read/`, {})
      } catch (error) {
        // Silently handle - UI already updated
      }
    }
    
    await loadMessages(chat.id)
    // Ensure scroll to bottom after chat selection
    setTimeout(() => scrollToBottom(true), 300)
    
    // Start polling for new messages
    startPolling()
  }
  
  // Coming back to a tab must feel instant. The intervals skip their ticks
  // while it is hidden, so without this the user would stare at a stale thread
  // for up to one full interval after switching back.
  const installVisibilityCatchUp = () => {
    if (visibilityCatchUpInstalled) return
    if (typeof document === 'undefined') return
    visibilityCatchUpInstalled = true
    document.addEventListener('visibilitychange', () => {
      if (!shouldPoll()) return
      if (activeChat.value) loadMessagesQuietly(activeChat.value.id)
      refreshChatRoomsSilently()
    })
  }

  // The polling body, reusable for the catch-up above so a returning tab does
  // not wait for the next tick.
  const loadMessagesQuietly = async (chatRoomId) => {
    if (!chatRoomId) return
    try {
      const { data, error } = await get(`/adsyconnect/messages/?chatroom=${chatRoomId}`)
      if (!data || error) return
      const { changed, messages: merged } = syncMessages(
        messages.value, data.results || data || []
      )
      if (changed) {
        const somethingArrived = merged.length > messages.value.length
        messages.value = merged
        if (somethingArrived) scrollToBottom()
      }
    } catch (error) {
      // A catch-up that fails just leaves the next tick to do it.
    }
  }

  /**
   * Open the chat websocket, the same one the mobile app uses.
   *
   * Until this existed the web had no realtime path at all: a reply took up to
   * three seconds to appear and the chat list — the heaviest endpoint in
   * AdsyConnect — was refetched every five. Polling stays as the fallback for
   * a socket that cannot open, which is why the intervals below still exist.
   */
  const startSocket = () => {
    if (disconnectSocket) return
    const { connect, isConnected } = useAdsyChatSocket()
    socketConnected = isConnected
    disconnectSocket = connect((event) => {
      const activeId = activeChat.value?.id
      updateCurrentUserId()

      const { changed, messages: merged } = messagesAfterEvent(
        messages.value, event, activeId
      )
      if (changed) {
        const arrived = merged.length > messages.value.length
        messages.value = merged
        if (arrived) scrollToBottom()
      }

      if (eventTouchesChatList(event, activeId)) {
        refreshChatRoomsSilently()
      }

      const typing = typingFromEvent(event, activeId, currentUserId.value)
      if (typing !== null) otherUserTyping.value = typing

      const presence = presenceFromEvent(
        event, activeChat.value?.other_user?.id
      )
      if (presence !== null) {
        otherUserOnline.value = presence
        if (activeChat.value?.other_user) {
          activeChat.value.other_user.is_online = presence
        }
      }
    })
  }

  const stopSocket = () => {
    if (!disconnectSocket) return
    disconnectSocket()
    disconnectSocket = null
  }

  /** True when the socket is carrying the conversation. */
  const socketIsLive = () => Boolean(socketConnected?.value)

  const startPolling = () => {
    startSocket()
    installVisibilityCatchUp()
    if (pollingInterval) clearInterval(pollingInterval)
    if (chatRoomsPollingInterval) clearInterval(chatRoomsPollingInterval)
    
    // Poll for new messages in active chat
    pollingInterval = setInterval(() => {
      // Nobody is reading a hidden tab, and a forgotten one used to poll all
      // day. The visibilitychange listener catches up when it returns.
      if (!shouldPoll()) return
      // With the socket live this is only a safety net for a frame the socket
      // dropped, so it runs every fourth tick instead of every one.
      if (socketIsLive()) {
        socketIdleTick = (socketIdleTick + 1) % 4
        if (socketIdleTick !== 0) return
      } else {
        socketIdleTick = 0
      }
      if (activeChat.value) loadMessagesQuietly(activeChat.value.id)
    }, POLL_INTERVALS.messages)
    
    // Poll for new chat rooms / incoming messages (for recipient to see new messages)
    chatRoomsPollingInterval = setInterval(async () => {
      if (!shouldPoll()) return
      await refreshChatRoomsSilently()
    }, POLL_INTERVALS.chatRooms)

    // Start online status polling
    startOnlineStatusPolling()
  }
  
  // Start only chat rooms polling (without active chat)
  const startChatRoomsPolling = () => {
    if (chatRoomsPollingInterval) clearInterval(chatRoomsPollingInterval)
    
    // Poll for new chat rooms / incoming messages
    chatRoomsPollingInterval = setInterval(async () => {
      if (!shouldPoll()) return
      await refreshChatRoomsSilently()
    }, POLL_INTERVALS.chatRooms)
  }
  
  // Start header polling for unread count (used by headers when not in AdsyConnect tab)
  const startHeaderPolling = () => {
    // Don't start if already running
    if (headerPollingInterval) return
    
    // Poll for unread count every 10 seconds
    headerPollingInterval = setInterval(async () => {
      if (!shouldPoll()) return
      await refreshChatRoomsSilently()
    }, POLL_INTERVALS.headerUnread)
  }
  
  // Stop header polling
  const stopHeaderPolling = () => {
    if (headerPollingInterval) {
      clearInterval(headerPollingInterval)
      headerPollingInterval = null
    }
  }
  
  const startOnlineStatusPolling = () => {
    if (onlineStatusInterval) clearInterval(onlineStatusInterval)
    if (heartbeatInterval) clearInterval(heartbeatInterval)
    
    // Update own online status immediately
    updateOnlineStatus(true)
    
    // Check other user's online status immediately
    checkOtherUserOnlineStatus()
    
    // Poll for other user's online status every 5 seconds (more responsive)
    onlineStatusInterval = setInterval(() => {
      if (!shouldPoll()) return
      if (activeChat.value?.other_user?.id) {
        checkOtherUserOnlineStatus()
      }
    }, POLL_INTERVALS.onlineStatus)
    
    // Heartbeat to keep user online - every 5 seconds
    heartbeatInterval = setInterval(() => {
      // The heartbeat is the one thing worth sending from a hidden tab: it is
      // what keeps the user online while they read something else. Every 30s,
      // against a 90s staleness window on the server.
      updateOnlineStatus(true)
    }, POLL_INTERVALS.heartbeat)
  }
  
  const checkOtherUserOnlineStatus = async () => {
    if (!activeChat.value?.other_user?.id) return
    
    try {
      const otherUserId = activeChat.value.other_user.id
      const { data, error } = await get(`/adsyconnect/online-status/?user_ids[]=${otherUserId}`)
      
      lastOnlineCheck.value = new Date()
      
      if (data && !error) {
        const statusList = Array.isArray(data) ? data : (data.results || [])
        
        // Find user status - check multiple possible field names
        const userStatus = statusList.find(s => {
          const statusUserId = s.user?.id || s.user_id || s.user
          return String(statusUserId) === String(otherUserId)
        })
        
        if (userStatus) {
          const isOnline = userStatus.is_online === true
          
          // Check if last_seen is recent (within 120 seconds) as additional validation
          if (userStatus.last_seen) {
            const lastSeen = new Date(userStatus.last_seen)
            const now = new Date()
            const diffSeconds = (now - lastSeen) / 1000
            // If last_seen is more than 120 seconds ago, consider offline
            otherUserOnline.value = isOnline && diffSeconds < 120
          } else {
            otherUserOnline.value = isOnline
          }
          
          // Update the chat room's other_user online status with proper reactivity
          if (activeChat.value?.other_user) {
            activeChat.value = {
              ...activeChat.value,
              other_user: {
                ...activeChat.value.other_user,
                is_online: otherUserOnline.value
              }
            }
          }
          
          // Also update in chatRooms list with proper reactivity
          const chatIndex = chatRooms.value.findIndex(c => c.id === activeChat.value?.id)
          if (chatIndex !== -1 && chatRooms.value[chatIndex]?.other_user) {
            chatRooms.value[chatIndex] = {
              ...chatRooms.value[chatIndex],
              other_user: {
                ...chatRooms.value[chatIndex].other_user,
                is_online: otherUserOnline.value
              }
            }
          }
          
          // Store in onlineUsers map
          onlineUsers.value.set(String(otherUserId), otherUserOnline.value)
        } else {
          otherUserOnline.value = false
          onlineUsers.value.set(String(otherUserId), false)
        }
      }
    } catch (error) {
      console.error('Error checking online status:', error)
      // Don't change status on error - keep last known state
    }
  }
  
  const updateOnlineStatus = async (isOnline = true) => {
    try {
      await post('/adsyconnect/online-status/update_status/', {
        is_online: isOnline
      })
    } catch (error) {
      // Silently handle - not critical but log for debugging
      console.error('Error updating online status:', error)
    }
  }
  
  const stopPolling = () => {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
    }
    if (onlineStatusInterval) {
      clearInterval(onlineStatusInterval)
      onlineStatusInterval = null
    }
    if (heartbeatInterval) {
      clearInterval(heartbeatInterval)
      heartbeatInterval = null
    }
    if (chatRoomsPollingInterval) {
      clearInterval(chatRoomsPollingInterval)
      chatRoomsPollingInterval = null
    }
    // The socket goes with the page. Leaving it open would keep receiving
    // frames for a screen that no longer exists.
    stopSocket()
    // Set user as offline when leaving chat
    updateOnlineStatus(false)
    otherUserOnline.value = false
    otherUserTyping.value = false
  }
  
  // Check if a specific user is online
  const isUserOnline = (userId) => {
    if (!userId) return false
    const userIdStr = String(userId)
    
    // Check if this is the active chat's other user
    if (activeChat.value?.other_user?.id && String(activeChat.value.other_user.id) === userIdStr) {
      return otherUserOnline.value
    }
    
    // Check from onlineUsers map
    return onlineUsers.value.get(userIdStr) === true
  }
  
  // Fetch online status for multiple users (for chat list)
  const fetchOnlineStatusForUsers = async (userIds) => {
    if (!userIds || userIds.length === 0) return
    
    try {
      const queryParams = userIds.map(id => `user_ids[]=${id}`).join('&')
      const { data, error } = await get(`/adsyconnect/online-status/?${queryParams}`)
      
      if (data && !error) {
        const statusList = Array.isArray(data) ? data : (data.results || [])
        
        // First, mark all requested users as offline (default)
        userIds.forEach(id => {
          onlineUsers.value.set(String(id), false)
        })
        
        // Then update with actual status from API
        statusList.forEach(status => {
          const userId = status.user?.id || status.user_id || status.user
          if (userId) {
            const isOnline = status.is_online === true
            // Validate with last_seen - use 120 seconds threshold for tolerance
            if (status.last_seen) {
              const lastSeen = new Date(status.last_seen)
              const now = new Date()
              const diffSeconds = (now - lastSeen) / 1000
              onlineUsers.value.set(String(userId), isOnline && diffSeconds < 120)
            } else {
              onlineUsers.value.set(String(userId), isOnline)
            }
          }
        })
        
        // Update chatRooms with online status - create new object for reactivity
        chatRooms.value = chatRooms.value.map(chat => {
          if (chat.other_user?.id) {
            const isOnline = onlineUsers.value.get(String(chat.other_user.id)) === true
            return {
              ...chat,
              other_user: {
                ...chat.other_user,
                is_online: isOnline
              }
            }
          }
          return chat
        })
      }
    } catch (error) {
      console.error('Error fetching online status for users:', error)
    }
  }

  const markMessageAsRead = async (messageId) => {
    try {
      await post(`/adsyconnect/messages/${messageId}/mark_read/`, {})
    } catch (error) {
      // Silently handle - not critical
    }
  }

  const scrollToBottom = (force = false) => {
    nextTick(() => {
      const messagesContainer = document.querySelector('.messages-container') || 
                               document.querySelector('[class*="overflow-y-auto"]') ||
                               document.querySelector('.flex-1.overflow-y-auto')
      if (messagesContainer) {
        messagesContainer.scrollTop = messagesContainer.scrollHeight
        
        if (force) {
          setTimeout(() => {
            messagesContainer.scrollTop = messagesContainer.scrollHeight
          }, 100)
        }
      }
    })
  }

  // Computed properties
  const unreadCount = computed(() => {
    if (!Array.isArray(chatRooms.value)) return 0
    return chatRooms.value.reduce((count, chat) => {
      return count + (chat.unread_count || 0)
    }, 0)
  })

  return {
    // State
    chatRooms,
    activeChat,
    messages,
    newMessage,
    isLoading,
    isLoadingMessages,
    unreadCount,
    otherUserOnline,
    onlineUsers,
    currentUserId,

    // Methods
    loadChatRooms,
    loadMessages,
    sendMessage,
    selectChat,
    scrollToBottom,
    otherUserTyping,
    stopSocket,
    startPolling,
    stopPolling,
    isUserOnline,
    updateOnlineStatus,
    getOrCreateChatRoom,
    fetchOnlineStatusForUsers,
    startOnlineStatusPolling,
    startChatRoomsPolling,
    startHeaderPolling,
    stopHeaderPolling,
    refreshChatRoomsSilently,
    updateCurrentUserId
  }
}
