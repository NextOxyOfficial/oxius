// AdsyConnect Chat System Composable
export const useAdsyConnect = () => {
  const api = useApi()
  const { user } = useAuth()

  // State management
  const chatRooms = ref<ChatRoom[]>([])
  const activeChat = ref<ChatRoom | null>(null)
  const messages = ref<Message[]>([])
  const onlineUsers = ref<Set<string>>(new Set())
  const typingUsers = ref<Map<string, string>>(new Map())
  const unreadCount = ref(0)
  const isLoading = ref(false)
  const isConnected = ref(false)

  // WebSocket connection for real-time features
  let ws: WebSocket | null = null
  const wsUrl = useRuntimeConfig().public.wsURL || 'ws://localhost:8000'

  // Types
  interface ChatRoom {
    id: string
    user1: User
    user2: User
    created_at: string
    updated_at: string
    last_message_at: string
    last_message_preview: string | null
    is_blocked: boolean
    blocked_by: User | null
    blocked_at: string | null
    unread_count: number
    other_user: User
  }

  interface Message {
    id: string
    chatroom: string
    sender: User
    receiver: User
    message_type: 'text' | 'image' | 'video' | 'document' | 'voice'
    content: string | null
    media_file: string | null
    media_thumbnail: string | null
    file_name: string | null
    file_size: number | null
    voice_duration: number | null
    is_read: boolean
    read_at: string | null
    is_deleted: boolean
    deleted_at: string | null
    created_at: string
    updated_at: string
  }

  interface User {
    id: string
    username: string
    first_name: string
    last_name: string
    email: string
    profile_picture: string | null
    is_online: boolean
    last_seen: string
  }

  interface OnlineStatus {
    user: string
    is_online: boolean
    last_seen: string
  }

  interface TypingStatus {
    chatroom: string
    user: string
    is_typing: boolean
  }

  // WebSocket Management
  const connectWebSocket = () => {
    if (!user.value || ws?.readyState === WebSocket.OPEN) return

    try {
      ws = new WebSocket(`${wsUrl}/ws/chat/${user.value.id}/`)
      
      ws.onopen = () => {
        console.log('✅ AdsyConnect WebSocket connected')
        isConnected.value = true
        updateOnlineStatus(true)
      }

      ws.onmessage = (event) => {
        const data = JSON.parse(event.data)
        handleWebSocketMessage(data)
      }

      ws.onclose = () => {
        console.log('❌ AdsyConnect WebSocket disconnected')
        isConnected.value = false
        // Attempt to reconnect after 3 seconds
        setTimeout(connectWebSocket, 3000)
      }

      ws.onerror = (error) => {
        console.error('🚨 AdsyConnect WebSocket error:', error)
      }
    } catch (error) {
      console.error('Failed to connect WebSocket:', error)
    }
  }

  const disconnectWebSocket = () => {
    if (ws) {
      ws.close()
      ws = null
      isConnected.value = false
    }
  }

  const handleWebSocketMessage = (data: any) => {
    switch (data.type) {
      case 'new_message':
        handleNewMessage(data.message)
        break
      case 'message_read':
        handleMessageRead(data.message_id)
        break
      case 'user_online':
        handleUserOnline(data.user_id)
        break
      case 'user_offline':
        handleUserOffline(data.user_id)
        break
      case 'typing_start':
        handleTypingStart(data.chatroom_id, data.user_id)
        break
      case 'typing_stop':
        handleTypingStop(data.chatroom_id, data.user_id)
        break
    }
  }

  // API Methods
  const fetchChatRooms = async () => {
    try {
      isLoading.value = true
      const { data, error } = await api.get('/adsyconnect/chatrooms/')
      
      if (error) {
        throw new Error(error.message || 'Failed to fetch chat rooms')
      }

      chatRooms.value = data || []
      calculateUnreadCount()
      return data
    } catch (error) {
      console.error('Error fetching chat rooms:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const getOrCreateChatRoom = async (userId: string) => {
    try {
      const { data, error } = await api.post('/adsyconnect/chatrooms/get_or_create/', {
        user_id: userId
      })

      if (error) {
        throw new Error(error.message || 'Failed to create chat room')
      }

      // Add to chat rooms if not exists
      const existingIndex = chatRooms.value.findIndex(room => room.id === data.id)
      if (existingIndex === -1) {
        chatRooms.value.unshift(data)
      } else {
        chatRooms.value[existingIndex] = data
      }

      return data
    } catch (error) {
      console.error('Error creating chat room:', error)
      throw error
    }
  }

  const fetchMessages = async (chatRoomId: string, page = 1) => {
    try {
      const { data, error } = await api.get(`/adsyconnect/messages/?chatroom=${chatRoomId}&page=${page}`)
      
      if (error) {
        throw new Error(error.message || 'Failed to fetch messages')
      }

      if (page === 1) {
        messages.value = data.results || []
      } else {
        messages.value = [...(data.results || []), ...messages.value]
      }

      return data
    } catch (error) {
      console.error('Error fetching messages:', error)
      throw error
    }
  }

  const sendMessage = async (chatRoomId: string, content: string, messageType: string = 'text') => {
    try {
      const messageData = {
        chatroom: chatRoomId,
        message_type: messageType,
        content: content
      }

      const { data, error } = await api.post('/adsyconnect/messages/', messageData)
      
      if (error) {
        throw new Error(error.message || 'Failed to send message')
      }

      // Add message to local state
      messages.value.push(data)
      
      // Update chat room's last message
      updateChatRoomLastMessage(chatRoomId, data)

      // Send via WebSocket for real-time delivery
      if (ws?.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'send_message',
          message: data
        }))
      }

      return data
    } catch (error) {
      console.error('Error sending message:', error)
      throw error
    }
  }

  const sendMediaMessage = async (chatRoomId: string, file: File, messageType: string) => {
    try {
      const formData = new FormData()
      formData.append('chatroom', chatRoomId)
      formData.append('message_type', messageType)
      formData.append('media_file', file)
      formData.append('file_name', file.name)
      formData.append('file_size', file.size.toString())

      const { data, error } = await api.post('/adsyconnect/messages/', formData)
      
      if (error) {
        throw new Error(error.message || 'Failed to send media')
      }

      messages.value.push(data)
      updateChatRoomLastMessage(chatRoomId, data)

      return data
    } catch (error) {
      console.error('Error sending media message:', error)
      throw error
    }
  }

  const markMessageAsRead = async (messageId: string) => {
    try {
      const { data, error } = await api.patch(`/adsyconnect/messages/${messageId}/mark_as_read/`, {})
      
      if (error) {
        console.error('Error marking message as read:', error)
        return
      }

      // Update local message state
      const messageIndex = messages.value.findIndex(msg => msg.id === messageId)
      if (messageIndex !== -1) {
        messages.value[messageIndex].is_read = true
        messages.value[messageIndex].read_at = new Date().toISOString()
      }

      return data
    } catch (error) {
      console.error('Error marking message as read:', error)
    }
  }

  const markChatAsRead = async (chatRoomId: string) => {
    try {
      const { data, error } = await api.post(`/adsyconnect/chatrooms/${chatRoomId}/mark_as_read/`, {})
      
      if (error) {
        console.error('Error marking chat as read:', error)
        return
      }

      // Update unread count
      const chatIndex = chatRooms.value.findIndex(room => room.id === chatRoomId)
      if (chatIndex !== -1) {
        chatRooms.value[chatIndex].unread_count = 0
      }
      
      calculateUnreadCount()
      return data
    } catch (error) {
      console.error('Error marking chat as read:', error)
    }
  }

  const deleteMessage = async (messageId: string) => {
    try {
      const { data, error } = await api.del(`/adsyconnect/messages/${messageId}/`)
      
      if (error) {
        throw new Error(error.message || 'Failed to delete message')
      }

      // Update local state
      const messageIndex = messages.value.findIndex(msg => msg.id === messageId)
      if (messageIndex !== -1) {
        messages.value[messageIndex].is_deleted = true
        messages.value[messageIndex].content = 'Message deleted'
      }

      return data
    } catch (error) {
      console.error('Error deleting message:', error)
      throw error
    }
  }

  const blockUser = async (userId: string, reason?: string) => {
    try {
      const { data, error } = await api.post('/adsyconnect/blocked-users/', {
        blocked: userId,
        reason: reason
      })
      
      if (error) {
        throw new Error(error.message || 'Failed to block user')
      }

      return data
    } catch (error) {
      console.error('Error blocking user:', error)
      throw error
    }
  }

  const unblockUser = async (userId: string) => {
    try {
      const { data, error } = await api.del(`/adsyconnect/blocked-users/${userId}/`)
      
      if (error) {
        throw new Error(error.message || 'Failed to unblock user')
      }

      return data
    } catch (error) {
      console.error('Error unblocking user:', error)
      throw error
    }
  }

  const reportMessage = async (messageId: string, reason: string, description?: string) => {
    try {
      const { data, error } = await api.post('/adsyconnect/reports/', {
        message: messageId,
        reason: reason,
        description: description
      })
      
      if (error) {
        throw new Error(error.message || 'Failed to report message')
      }

      return data
    } catch (error) {
      console.error('Error reporting message:', error)
      throw error
    }
  }

  const updateOnlineStatus = async (isOnline: boolean) => {
    try {
      const { data, error } = await api.patch('/adsyconnect/online-status/', {
        is_online: isOnline
      })
      
      if (error) {
        console.error('Error updating online status:', error)
        return
      }

      return data
    } catch (error) {
      console.error('Error updating online status:', error)
    }
  }

  const sendTypingStatus = async (chatRoomId: string, isTyping: boolean) => {
    try {
      if (ws?.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'typing_status',
          chatroom_id: chatRoomId,
          is_typing: isTyping
        }))
      }
    } catch (error) {
      console.error('Error sending typing status:', error)
    }
  }

  // Helper Methods
  const handleNewMessage = (message: Message) => {
    // Add to messages if in active chat
    if (activeChat.value?.id === message.chatroom) {
      messages.value.push(message)
      // Auto-mark as read if chat is active
      markMessageAsRead(message.id)
    }

    // Update chat room
    updateChatRoomLastMessage(message.chatroom, message)
    calculateUnreadCount()
  }

  const handleMessageRead = (messageId: string) => {
    const messageIndex = messages.value.findIndex(msg => msg.id === messageId)
    if (messageIndex !== -1) {
      messages.value[messageIndex].is_read = true
      messages.value[messageIndex].read_at = new Date().toISOString()
    }
  }

  const handleUserOnline = (userId: string) => {
    onlineUsers.value.add(userId)
  }

  const handleUserOffline = (userId: string) => {
    onlineUsers.value.delete(userId)
  }

  const handleTypingStart = (chatRoomId: string, userId: string) => {
    if (activeChat.value?.id === chatRoomId && userId !== user.value?.id) {
      typingUsers.value.set(chatRoomId, userId)
    }
  }

  const handleTypingStop = (chatRoomId: string, userId: string) => {
    typingUsers.value.delete(chatRoomId)
  }

  const updateChatRoomLastMessage = (chatRoomId: string, message: Message) => {
    const chatIndex = chatRooms.value.findIndex(room => room.id === chatRoomId)
    if (chatIndex !== -1) {
      chatRooms.value[chatIndex].last_message_at = message.created_at
      chatRooms.value[chatIndex].last_message_preview = getMessagePreview(message)
      
      // Move to top
      const chat = chatRooms.value.splice(chatIndex, 1)[0]
      chatRooms.value.unshift(chat)
    }
  }

  const getMessagePreview = (message: Message): string => {
    if (message.is_deleted) return 'Message deleted'
    
    switch (message.message_type) {
      case 'text':
        return message.content?.substring(0, 50) + (message.content && message.content.length > 50 ? '...' : '') || ''
      case 'image':
        return '📷 Photo'
      case 'video':
        return '🎥 Video'
      case 'voice':
        return '🎤 Voice message'
      case 'document':
        return `📄 ${message.file_name || 'Document'}`
      default:
        return 'Message'
    }
  }

  const calculateUnreadCount = () => {
    unreadCount.value = chatRooms.value.reduce((total, room) => total + (room.unread_count || 0), 0)
  }

  const isUserOnline = (userId: string): boolean => {
    return onlineUsers.value.has(userId)
  }

  const isUserTyping = (chatRoomId: string): boolean => {
    return typingUsers.value.has(chatRoomId)
  }

  const formatMessageTime = (timestamp: string): string => {
    const date = new Date(timestamp)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    
    if (diff < 60000) return 'Just now'
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`
    if (diff < 604800000) return `${Math.floor(diff / 86400000)}d ago`
    
    return date.toLocaleDateString()
  }

  // Lifecycle
  onMounted(() => {
    if (user.value) {
      connectWebSocket()
      fetchChatRooms()
    }
  })

  onUnmounted(() => {
    disconnectWebSocket()
    updateOnlineStatus(false)
  })

  // Watch for user changes
  watch(user, (newUser) => {
    if (newUser) {
      connectWebSocket()
      fetchChatRooms()
    } else {
      disconnectWebSocket()
      chatRooms.value = []
      messages.value = []
      activeChat.value = null
    }
  })

  return {
    // State
    chatRooms: readonly(chatRooms),
    activeChat: readonly(activeChat),
    messages: readonly(messages),
    onlineUsers: readonly(onlineUsers),
    typingUsers: readonly(typingUsers),
    unreadCount: readonly(unreadCount),
    isLoading: readonly(isLoading),
    isConnected: readonly(isConnected),

    // Methods
    fetchChatRooms,
    getOrCreateChatRoom,
    fetchMessages,
    sendMessage,
    sendMediaMessage,
    markMessageAsRead,
    markChatAsRead,
    deleteMessage,
    blockUser,
    unblockUser,
    reportMessage,
    updateOnlineStatus,
    sendTypingStatus,
    
    // Utilities
    isUserOnline,
    isUserTyping,
    formatMessageTime,
    getMessagePreview,
    
    // WebSocket
    connectWebSocket,
    disconnectWebSocket,

    // Setters for component use
    setActiveChat: (chat: ChatRoom | null) => { activeChat.value = chat },
    clearMessages: () => { messages.value = [] }
  }
}
