import { ref, computed, nextTick } from 'vue'
import { useToast } from '#ui/composables/useToast'

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

// Polling interval
let pollingInterval = null

export const useAdsyChat = () => {
  const toast = useToast()
  const { get, post } = useApi()

  const updateChatRoomLastMessage = (message) => {
    const chatRoom = chatRooms.value.find(chat => chat.id === message.chatroom)
    if (chatRoom) {
      chatRoom.last_message_at = message.created_at
      chatRoom.last_message_preview = message.content || 'Media message'
      
      // Move to top of list
      const index = chatRooms.value.indexOf(chatRoom)
      if (index > 0) {
        chatRooms.value.splice(index, 1)
        chatRooms.value.unshift(chatRoom)
      }
    }
  }

  // API functions
  const loadChatRooms = async () => {
    console.log('loadChatRooms called')
    isLoading.value = true
    try {
      const { data, error } = await get('/adsyconnect/chatrooms/')
      console.log('loadChatRooms response:', data, 'error:', error)
      if (data && !error) {
        chatRooms.value = data.results || data || []
        console.log('chatRooms loaded:', chatRooms.value.length, 'rooms')
      }
    } catch (error) {
      console.error('Error loading chat rooms:', error)
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
      console.error('Error loading messages:', error)
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

    const tempId = Date.now().toString()
    const tempMessage = {
      temp_id: tempId,
      content: newMessage.value.trim(),
      sender: { id: 'current_user' },
      created_at: new Date().toISOString(),
      is_read: false
    }

    // Add temporary message to UI
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
        }
        
        // Update chat room last message
        updateChatRoomLastMessage(data)
        scrollToBottom()
      } else {
        throw new Error('Failed to send message')
      }
    } catch (error) {
      console.error('Error sending message:', error)
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

  const selectChat = async (chat) => {
    console.log('useAdsyChat.selectChat called with:', chat)
    
    if (!chat || !chat.id) {
      console.error('Invalid chat passed to selectChat:', chat)
      return
    }
    
    activeChat.value = chat
    console.log('activeChat set to:', activeChat.value)
    
    await loadMessages(chat.id)
    // Ensure scroll to bottom after chat selection
    setTimeout(() => scrollToBottom(true), 300)
    
    // Start polling for new messages
    startPolling()
    
    console.log('selectChat completed, activeChat:', activeChat.value)
  }
  
  const startPolling = () => {
    if (pollingInterval) clearInterval(pollingInterval)
    
    pollingInterval = setInterval(async () => {
      if (activeChat.value) {
        try {
          const { data, error } = await get(`/adsyconnect/messages/?chatroom=${activeChat.value.id}`)
          if (data && !error) {
            const newMessages = data.results || data || []
            
            // Only update if we have new messages
            if (newMessages.length > messages.value.length) {
              messages.value = newMessages
              scrollToBottom()
            }
          }
        } catch (error) {
          // Silently handle polling errors
        }
      }
    }, 5000) // Poll every 5 seconds
  }
  
  const stopPolling = () => {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
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

    // Methods
    loadChatRooms,
    loadMessages,
    sendMessage,
    selectChat,
    scrollToBottom,
    startPolling,
    stopPolling
  }
}
