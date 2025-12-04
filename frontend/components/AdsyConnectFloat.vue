<template>
  <div v-if="user" class="fixed bottom-6 right-6 z-50">
    <!-- Floating Chat Button -->
    <button
      v-if="!showMiniChat"
      @click="toggleMiniChat"
      class="relative flex items-center justify-center w-14 h-14 bg-gradient-to-br from-green-500 to-green-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105"
      :class="{ 'animate-bounce': hasNewMessages }"
    >
      <UIcon name="i-heroicons-chat-bubble-left-right" class="w-6 h-6" />
      
      <!-- Unread Badge -->
      <div
        v-if="unreadCount > 0"
        class="absolute -top-2 -right-2 flex items-center justify-center w-6 h-6 bg-red-500 text-white text-xs font-bold rounded-full border-2 border-white"
      >
        {{ unreadCount > 99 ? '99+' : unreadCount }}
      </div>
    </button>

    <!-- Mini Chat Window -->
    <div
      v-if="showMiniChat"
      class="bg-white rounded-lg shadow-xl border border-gray-200 w-80 h-96 flex flex-col overflow-hidden"
    >
      <!-- Header -->
      <div class="bg-gradient-to-r from-green-500 to-green-600 text-white p-3 flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <UIcon name="i-heroicons-chat-bubble-left-right" class="w-5 h-5" />
          <span class="font-medium">AdsyConnect</span>
        </div>
        <div class="flex items-center space-x-1">
          <button
            @click="openFullChat"
            class="p-1 hover:bg-white/20 rounded transition-colors"
            title="Open full chat"
          >
            <UIcon name="i-heroicons-arrows-pointing-out" class="w-4 h-4" />
          </button>
          <button
            @click="toggleMiniChat"
            class="p-1 hover:bg-white/20 rounded transition-colors"
          >
            <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
          </button>
        </div>
      </div>

      <!-- Chat List or Active Chat -->
      <div v-if="!activeMiniChat" class="flex-1 overflow-y-auto">
        <!-- Recent Chats -->
        <div class="p-2">
          <div class="text-xs font-medium text-gray-500 mb-2 px-2">Recent Chats</div>
          
          <div v-if="isLoading" class="space-y-2">
            <div v-for="i in 3" :key="i" class="flex items-center space-x-2 p-2">
              <div class="w-8 h-8 bg-gray-200 rounded-full animate-pulse"></div>
              <div class="flex-1 space-y-1">
                <div class="h-3 bg-gray-200 rounded animate-pulse"></div>
                <div class="h-2 bg-gray-200 rounded w-2/3 animate-pulse"></div>
              </div>
            </div>
          </div>

          <div v-else-if="recentChats.length === 0" class="text-center py-8">
            <UIcon name="i-heroicons-chat-bubble-left-right" class="w-8 h-8 text-gray-300 mx-auto mb-2" />
            <p class="text-sm text-gray-500">No recent chats</p>
          </div>

          <div v-else class="space-y-1">
            <div
              v-for="chat in recentChats.slice(0, 5)"
              :key="chat.id"
              @click="selectMiniChat(chat)"
              class="flex items-center space-x-2 p-2 hover:bg-gray-50 rounded cursor-pointer"
            >
              <div class="relative">
                <img
                  :src="chat.other_user.avatar || chat.other_user.image || defaultPlaceholder"
                  :alt="chat.other_user.first_name"
                  class="w-8 h-8 rounded-full object-cover"
                  @error="handleImageError"
                />
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center justify-between">
                  <p class="text-sm font-medium text-gray-900 truncate">
                    {{ chat.other_user.first_name }} {{ chat.other_user.last_name }}
                  </p>
                  <div v-if="chat.unread_count > 0" class="w-2 h-2 bg-green-500 rounded-full"></div>
                </div>
                <p class="text-xs text-gray-500 truncate">
                  {{ chat.last_message_preview || 'No messages' }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="border-t border-gray-100 p-2">
          <button
            @click="openFullChat"
            class="w-full flex items-center justify-center space-x-2 py-2 text-sm text-green-600 hover:bg-green-50 rounded transition-colors"
          >
            <UIcon name="i-heroicons-plus" class="w-4 h-4" />
            <span>New Chat</span>
          </button>
        </div>
      </div>

      <!-- Active Mini Chat -->
      <div v-else class="flex-1 flex flex-col">
        <!-- Chat Header -->
        <div class="p-3 border-b border-gray-200 bg-gray-50">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-2">
              <button
                @click="activeMiniChat = null"
                class="p-1 hover:bg-gray-200 rounded transition-colors"
              >
                <UIcon name="i-heroicons-arrow-left" class="w-4 h-4" />
              </button>
              <img
                :src="activeMiniChat.other_user.avatar || activeMiniChat.other_user.image || defaultPlaceholder"
                :alt="activeMiniChat.other_user.first_name"
                class="w-6 h-6 rounded-full object-cover"
                @error="handleImageError"
              />
              <div>
                <p class="text-sm font-medium text-gray-900">
                  {{ activeMiniChat.other_user.first_name }} {{ activeMiniChat.other_user.last_name }}
                </p>
                <p v-if="activeMiniChat.other_user.profession" class="text-xs text-gray-500 truncate">
                  {{ activeMiniChat.other_user.profession }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Messages -->
        <div class="flex-1 overflow-y-auto p-2 space-y-2" ref="miniMessagesContainer">
          <div v-if="miniMessages.length === 0" class="text-center py-4">
            <p class="text-xs text-gray-500">No messages yet</p>
          </div>

          <div v-for="message in miniMessages" :key="message.id" class="flex" :class="{ 'justify-end': message.sender.id === user?.id }">
            <div class="max-w-xs">
              <div
                class="px-2 py-1 rounded text-xs"
                :class="message.sender.id === user?.id 
                  ? 'bg-green-500 text-white' 
                  : 'bg-gray-100 text-gray-900'"
              >
                <p v-if="message.message_type === 'text' && !message.is_deleted">
                  {{ message.content }}
                </p>
                <p v-else-if="message.is_deleted" class="italic opacity-75">
                  Message deleted
                </p>
                <p v-else class="italic">
                  {{ getMessageTypeLabel(message.message_type) }}
                </p>
              </div>
              <p class="text-xs text-gray-400 mt-1" :class="{ 'text-right': message.sender.id === user?.id }">
                {{ formatMessageTime(message.created_at) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Message Input -->
        <div class="p-2 border-t border-gray-200">
          <div class="flex items-center space-x-2">
            <input
              v-model="miniMessageText"
              @keydown.enter="sendMiniMessage"
              type="text"
              placeholder="Type a message..."
              class="flex-1 px-2 py-1 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-green-500 focus:border-transparent"
            />
            <button
              @click="sendMiniMessage"
              :disabled="!miniMessageText.trim()"
              class="p-1 bg-green-500 text-white rounded hover:bg-green-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <UIcon name="i-heroicons-paper-airplane" class="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Type definitions for chat data
interface ChatUser {
  id: string | number
  username?: string
  first_name?: string
  last_name?: string
  avatar?: string
  image?: string
  is_pro?: boolean
  kyc?: boolean
  profession?: string
}

interface ChatRoom {
  id: string | number
  other_user: ChatUser
  unread_count: number
  last_message_preview?: string
  last_message_at?: string
}

// Composables
const { user } = useAuth()
const { get, post } = useApi()
const {
  chatRooms,
  unreadCount,
  isLoading,
  loadChatRooms,
  loadMessages,
  sendMessage: sendChatMessage,
  startChatRoomsPolling,
  stopPolling,
} = useAdsyChat()

// Cast chatRooms to proper type for template usage
const typedChatRooms = computed(() => chatRooms.value as ChatRoom[])

// Default placeholder image - use a data URI for guaranteed availability
const defaultPlaceholder = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%239CA3AF"%3E%3Cpath d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/%3E%3C/svg%3E'

// Handle broken image by falling back to placeholder
const handleImageError = (event: Event) => {
  const target = event.target as HTMLImageElement
  target.src = defaultPlaceholder
}

// State
const showMiniChat = ref(false)
const activeMiniChat = ref<any>(null)
const miniMessages = ref<any[]>([])
const miniMessageText = ref('')
const miniMessagesContainer = ref<HTMLElement>()
const hasNewMessages = ref(false)

// Computed
const recentChats = computed((): ChatRoom[] => {
  return (chatRooms.value as ChatRoom[]).slice(0, 5)
})

const formatMessageTime = (timestamp: string) => {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  const now = new Date()
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)
  
  if (diffInSeconds < 60) return 'Just now'
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`
  return date.toLocaleDateString()
}

// Methods
const toggleMiniChat = async () => {
  showMiniChat.value = !showMiniChat.value
  if (showMiniChat.value) {
    if (recentChats.value.length === 0) {
      await loadChatRooms()
    }
    // Start periodic refresh for new messages
    startChatRoomsPolling()
  }
  hasNewMessages.value = false
}

const openFullChat = () => {
  navigateTo('/inbox')
}

const selectMiniChat = async (chat: any) => {
  activeMiniChat.value = chat
  miniMessages.value = []
  
  try {
    const { data, error } = await get(`/adsyconnect/messages/?chatroom=${chat.id}`)
    if (data && !error) {
      const messages = data?.results || data || []
      miniMessages.value = Array.isArray(messages) ? messages.slice(-10) : []
      scrollMiniToBottom()
    }
  } catch (error) {
    console.error('Error loading mini chat:', error)
  }
}

const sendMiniMessage = async () => {
  if (!miniMessageText.value.trim() || !activeMiniChat.value) return
  
  try {
    const { data, error } = await post('/adsyconnect/messages/', {
      chatroom: activeMiniChat.value.id,
      receiver: activeMiniChat.value.other_user?.id,
      message_type: 'text',
      content: miniMessageText.value.trim(),
    })
    if (data && !error) {
      miniMessages.value.push(data)
      miniMessageText.value = ''
      scrollMiniToBottom()
    }
  } catch (error) {
    console.error('Error sending mini message:', error)
  }
}

const scrollMiniToBottom = () => {
  nextTick(() => {
    if (miniMessagesContainer.value) {
      miniMessagesContainer.value.scrollTop = miniMessagesContainer.value.scrollHeight
    }
  })
}

const getMessageTypeLabel = (type: string): string => {
  const labels = {
    image: '📷 Photo',
    video: '🎥 Video',
    document: '📄 Document',
    voice: '🎤 Voice'
  }
  return labels[type as keyof typeof labels] || 'Message'
}

// Watch for unread count changes to show notification
watch(unreadCount, (newCount, oldCount) => {
  if (newCount > oldCount && !showMiniChat.value) {
    hasNewMessages.value = true
  }
})

// Load initial data
onMounted(async () => {
  if (user.value) {
    await loadChatRooms()
    // Start polling for new messages
    startChatRoomsPolling()
  }
})

// Cleanup on unmount - stopPolling handles all intervals
onUnmounted(() => {
  stopPolling()
})
</script>

<style scoped>
/* Custom scrollbar for mini chat */
.overflow-y-auto::-webkit-scrollbar {
  width: 4px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: #f1f5f9;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 2px;
}

.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>