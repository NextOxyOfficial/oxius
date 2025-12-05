<template>
  <USlideover v-model="isOpen" :ui="{ width: 'max-w-md', padding: 'p-0', background: 'bg-transparent' }">
    <!-- Spacer to clear the fixed header -->
    <div class="h-[70px] sm:h-[80px] flex-shrink-0"></div>
    
    <div class="flex flex-col flex-1 bg-white rounded-t-2xl overflow-hidden shadow-2xl">
      <!-- Header -->
      <div 
        class="bg-gradient-to-r from-green-500 to-green-600 text-white flex items-center justify-between py-4 px-4 rounded-t-2xl"
      >
        <div class="flex items-center space-x-3">
          <div class="relative">
            <img
              :src="user?.image || user?.avatar || defaultPlaceholder"
              :alt="user?.name || user?.first_name"
              class="w-11 h-11 rounded-full object-cover border-2 border-white/40 shadow-md"
              @error="handleImageError"
            />
          </div>
          <div>
            <div class="flex items-center gap-1.5 flex-wrap">
              <p class="font-semibold text-base">{{ user?.name }}</p>
              <!-- Verified Badge -->
              <UIcon
                v-if="user?.kyc"
                name="i-heroicons-check-badge-solid"
                class="w-4 h-4 text-white"
              />
              <!-- Pro Badge -->
              <span 
                v-if="user?.is_pro" 
                class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white shadow-sm"
              >
                PRO
              </span>
            </div>
            <span v-if="user?.profession" class="text-xs text-white/80 mt-0.5">{{ user.profession }}</span>
          </div>
        </div>
        <button
          @click="close"
          class="p-2.5 hover:bg-white/20 rounded-full transition-colors"
        >
          <UIcon name="i-heroicons-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <!-- Loading State -->
      <div v-if="isLoadingMessages" class="flex-1 flex items-center justify-center bg-gray-50">
        <div class="text-center">
          <div class="w-10 h-10 border-3 border-green-500 border-t-transparent rounded-full animate-spin mx-auto mb-3"></div>
          <p class="text-sm text-gray-500">Loading messages...</p>
        </div>
      </div>

      <!-- Messages -->
      <div
        v-else
        ref="messagesContainer"
        class="flex-1 overflow-y-auto p-4 space-y-3 messages-container bg-gray-50"
        @click="handleContainerClick"
      >
        <div v-if="messages.length === 0" class="flex items-center justify-center h-full">
          <div class="text-center py-8">
            <img 
              :src="chatIconPath" 
              alt="Chat" 
              class="w-20 h-20 mx-auto mb-4 opacity-60"
            />
            <p class="text-gray-600 font-medium">No messages yet</p>
            <p class="text-sm text-gray-400 mt-1">Start the conversation!</p>
          </div>
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="message in messages"
            :key="message.id"
            class="flex items-end gap-2 group/msg"
            :class="isOwnMessage(message) ? 'justify-end' : 'justify-start'"
          >
            <!-- Avatar for received messages -->
            <div v-if="!isOwnMessage(message)" class="flex-shrink-0 mb-1">
              <img
                :src="user?.image || user?.avatar || defaultPlaceholder"
                :alt="user?.name || user?.first_name"
                class="w-7 h-7 rounded-full object-cover ring-2 ring-white shadow-sm"
                @error="handleImageError"
              />
            </div>

            <!-- Message Actions (for own text messages only - shown outside) -->
            <div 
              v-if="isOwnMessage(message) && !message.is_deleted && message.message_type === 'text'" 
              class="flex-shrink-0 opacity-0 group-hover/msg:opacity-100 transition-opacity self-center"
              @click.stop
            >
              <div class="relative">
                <button
                  @click.stop="toggleMessageMenu(message.id)"
                  class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-full transition-colors"
                >
                  <UIcon name="i-heroicons-ellipsis-vertical" class="w-4 h-4" />
                </button>
                <!-- Dropdown Menu -->
                <div
                  v-if="activeMessageMenu === message.id"
                  class="absolute right-0 bottom-full mb-1 w-32 bg-white rounded-lg shadow-lg border border-gray-200 z-50 overflow-hidden"
                  @click.stop
                >
                  <button
                    @click.stop="startEditMessage(message)"
                    class="w-full px-3 py-2 text-left text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2"
                  >
                    <UIcon name="i-heroicons-pencil" class="w-4 h-4" />
                    Edit
                  </button>
                  <button
                    @click.stop="confirmDeleteMessage(message)"
                    class="w-full px-3 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                  >
                    <UIcon name="i-heroicons-trash" class="w-4 h-4" />
                    Delete
                  </button>
                </div>
              </div>
            </div>

            <div
              class="max-w-[75%] rounded-2xl shadow-sm transition-all duration-200 hover:shadow-md overflow-hidden"
              :class="[
                isOwnMessage(message) ? 'rounded-br-sm' : 'rounded-bl-sm',
                (message.message_type === 'image' || message.message_type === 'video') && !message.is_deleted
                  ? '' 
                  : (isOwnMessage(message) ? 'bg-gradient-to-br from-green-500 to-green-600 text-white' : 'bg-white text-gray-800 border border-gray-100')
              ]"
            >
              <!-- Deleted Message (check first before any content) -->
              <div v-if="message.is_deleted" class="px-3.5 py-2">
                <p class="text-[13px] italic opacity-60">Message deleted</p>
              </div>

              <!-- Image Message -->
              <div v-else-if="message.message_type === 'image' && message.media_url" class="relative group rounded-2xl overflow-hidden">
                <img
                  :src="message.media_url"
                  :alt="message.file_name || 'Image'"
                  class="w-full h-auto max-h-64 object-cover cursor-pointer transition-transform duration-300 group-hover:scale-105"
                  @click.stop="openMediaViewer(message)"
                />
                <div 
                  class="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-all duration-300 flex items-center justify-center cursor-pointer"
                  @click.stop="openMediaViewer(message)"
                >
                  <div class="opacity-0 flex group-hover:opacity-100 transition-opacity duration-300 p-2 bg-black/50 rounded-full">
                    <UIcon name="i-heroicons-magnifying-glass-plus" class="w-5 h-5 text-white" />
                  </div>
                </div>
                <!-- Delete button for own media messages -->
                <button
                  v-if="isOwnMessage(message) && !message.is_deleted"
                  @click.stop="confirmDeleteMessage(message)"
                  class="absolute top-2 right-2 p-1.5 bg-black/50 hover:bg-red-500 rounded-full opacity-0 group-hover:opacity-100 transition-all duration-300"
                >
                  <UIcon name="i-heroicons-trash" class="w-4 h-4 text-white" />
                </button>
                <!-- Time overlay on image -->
                <div class="absolute bottom-2 right-2 flex items-center gap-1 bg-black/50 rounded-full px-2 py-0.5">
                  <span class="text-[10px] text-white/90">{{ formatMessageTime(message.created_at) }}</span>
                  <UIcon 
                    v-if="isOwnMessage(message)"
                    :name="message.is_read ? 'i-heroicons-check-circle-solid' : 'i-heroicons-check'"
                    class="w-3 h-3 text-white/90"
                  />
                </div>
              </div>

              <!-- Video Message -->
              <div v-else-if="message.message_type === 'video' && message.media_url" class="relative group rounded-2xl overflow-hidden">
                <video
                  :src="message.media_url"
                  class="w-full h-auto max-h-64 object-cover"
                  controls
                  preload="metadata"
                >
                  Your browser does not support the video tag.
                </video>
                <!-- Delete button for own video messages -->
                <button
                  v-if="isOwnMessage(message) && !message.is_deleted"
                  @click.stop="confirmDeleteMessage(message)"
                  class="absolute top-2 right-2 p-1.5 bg-black/50 hover:bg-red-500 rounded-full opacity-0 group-hover:opacity-100 transition-all duration-300 z-10"
                >
                  <UIcon name="i-heroicons-trash" class="w-4 h-4 text-white" />
                </button>
                <!-- Time overlay on video -->
                <div class="absolute bottom-2 right-2 flex items-center gap-1 bg-black/50 rounded-full px-2 py-0.5">
                  <span class="text-[10px] text-white/90">{{ formatMessageTime(message.created_at) }}</span>
                  <UIcon 
                    v-if="isOwnMessage(message)"
                    :name="message.is_read ? 'i-heroicons-check-circle-solid' : 'i-heroicons-check'"
                    class="w-3 h-3 text-white/90"
                  />
                </div>
              </div>

              <!-- Document Message -->
              <div v-else-if="message.message_type === 'document' && message.media_url" class="px-3 py-2.5">
                <div class="flex items-center gap-3">
                  <div class="flex-shrink-0 p-2 rounded-lg" :class="isOwnMessage(message) ? 'bg-white/20' : 'bg-gray-100'">
                    <UIcon name="i-heroicons-document-text" class="w-6 h-6" :class="isOwnMessage(message) ? 'text-white' : 'text-gray-600'" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium truncate">{{ message.file_name || 'Document' }}</p>
                    <p class="text-[10px] opacity-60">{{ formatFileSize(message.file_size) }}</p>
                  </div>
                  <a
                    :href="message.media_url"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex-shrink-0 p-2 rounded-full transition-colors"
                    :class="isOwnMessage(message) ? 'hover:bg-white/20' : 'hover:bg-gray-100'"
                  >
                    <UIcon name="i-heroicons-arrow-down-tray" class="w-4 h-4" />
                  </a>
                </div>
                <div class="mt-1.5 flex items-center justify-end gap-1">
                  <span class="text-[10px] opacity-50">{{ formatMessageTime(message.created_at) }}</span>
                  <UIcon 
                    v-if="isOwnMessage(message)"
                    :name="message.is_read ? 'i-heroicons-check-circle-solid' : 'i-heroicons-check'"
                    class="w-3 h-3"
                    :class="message.is_read ? 'text-white/80' : 'text-white/50'"
                  />
                </div>
              </div>

              <!-- Text Message -->
              <div v-else class="px-3.5 py-2">
                <p class="text-[13px] leading-relaxed whitespace-pre-wrap break-words" v-html="linkifyText(message.content)"></p>
                <div class="mt-1 flex items-center justify-end gap-1">
                  <span v-if="message.is_edited" class="text-[10px] opacity-50 italic">edited</span>
                  <span class="text-[10px] opacity-50">{{ formatMessageTime(message.created_at) }}</span>
                  <UIcon 
                    v-if="isOwnMessage(message)"
                    :name="message.is_read ? 'i-heroicons-check-circle-solid' : 'i-heroicons-check'"
                    class="w-3 h-3"
                    :class="message.is_read ? 'text-white/80' : 'text-white/50'"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Edit Message Modal -->
      <UModal v-model="showEditModal" :ui="{ width: 'max-w-md' }">
        <div class="p-4">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Edit Message</h3>
            <button @click="showEditModal = false" class="p-1 hover:bg-gray-100 rounded-full">
              <UIcon name="i-heroicons-x-mark" class="w-5 h-5 text-gray-500" />
            </button>
          </div>
          <textarea
            v-model="editMessageContent"
            rows="3"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent resize-none"
            placeholder="Edit your message..."
          ></textarea>
          <div class="flex justify-end gap-2 mt-4">
            <UButton color="gray" variant="ghost" @click="showEditModal = false">Cancel</UButton>
            <UButton 
              color="green" 
              @click="saveEditMessage" 
              :loading="isEditingMessage"
              :disabled="!editMessageContent.trim()"
            >
              Save
            </UButton>
          </div>
        </div>
      </UModal>

      <!-- Delete Confirmation Modal -->
      <UModal v-model="showDeleteModal" :ui="{ width: 'max-w-sm' }">
        <div class="p-4 text-center">
          <div class="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center mx-auto mb-4">
            <UIcon name="i-heroicons-trash" class="w-6 h-6 text-red-600" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">Delete Message?</h3>
          <p class="text-sm text-gray-500 mb-4">This message will be deleted for everyone. This cannot be undone.</p>
          <div class="flex justify-center gap-3">
            <UButton color="gray" variant="ghost" @click="showDeleteModal = false">Cancel</UButton>
            <UButton color="red" @click="deleteMessage" :loading="isDeletingMessage">Delete</UButton>
          </div>
        </div>
      </UModal>

      <!-- Message Input -->
      <div class="p-3 bg-white border-t border-gray-200 safe-area-bottom">
        <!-- Upload Progress -->
        <div v-if="isUploadingAttachment" class="mb-3 px-3 py-2 bg-green-50 rounded-lg border border-green-100">
          <div class="flex items-center space-x-2">
            <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-green-500"></div>
            <p class="text-sm text-green-700">Uploading...</p>
          </div>
        </div>

        <div class="flex items-center space-x-2">
          <!-- Attachment Button -->
          <div class="relative">
            <button
              @click="showAttachmentOptions = !showAttachmentOptions"
              :disabled="isUploadingAttachment"
              class="p-2.5 text-gray-500 hover:text-green-600 hover:bg-green-50 rounded-full transition-colors disabled:opacity-50"
            >
              <UIcon name="i-heroicons-paper-clip" class="w-5 h-5" />
            </button>

            <!-- Attachment Options -->
            <div
              v-if="showAttachmentOptions"
              class="absolute bottom-full left-0 mb-2 w-56 bg-white rounded-xl shadow-lg border border-gray-200 z-50 overflow-hidden"
            >
              <div class="p-3">
                <div class="flex items-center justify-between mb-2">
                  <h3 class="text-sm font-semibold text-gray-900">Send Attachment</h3>
                  <button @click="showAttachmentOptions = false" class="p-1 hover:bg-gray-100 rounded-full">
                    <UIcon name="i-heroicons-x-mark" class="w-4 h-4 text-gray-400" />
                  </button>
                </div>
                <div class="grid grid-cols-2 gap-2">
                  <button @click="pickImage" class="flex flex-col items-center p-3 hover:bg-green-50 rounded-lg transition-colors">
                    <div class="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center mb-1">
                      <UIcon name="i-heroicons-photo" class="w-5 h-5 text-green-600" />
                    </div>
                    <span class="text-xs text-gray-600">Photo</span>
                  </button>
                  <button @click="pickVideo" class="flex flex-col items-center p-3 hover:bg-purple-50 rounded-lg transition-colors">
                    <div class="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center mb-1">
                      <UIcon name="i-heroicons-video-camera" class="w-5 h-5 text-purple-600" />
                    </div>
                    <span class="text-xs text-gray-600">Video</span>
                  </button>
                  <button @click="pickDocument" class="flex flex-col items-center p-3 hover:bg-blue-50 rounded-lg transition-colors">
                    <div class="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center mb-1">
                      <UIcon name="i-heroicons-document" class="w-5 h-5 text-blue-600" />
                    </div>
                    <span class="text-xs text-gray-600">Document</span>
                  </button>
                  <button @click="pickCamera" class="flex flex-col items-center p-3 hover:bg-orange-50 rounded-lg transition-colors">
                    <div class="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center mb-1">
                      <UIcon name="i-heroicons-camera" class="w-5 h-5 text-orange-600" />
                    </div>
                    <span class="text-xs text-gray-600">Camera</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Hidden file inputs -->
          <input ref="imageInput" type="file" accept="image/*" class="hidden" @change="handleImageUpload" />
          <input ref="videoInput" type="file" accept="video/*" class="hidden" @change="handleVideoUpload" />
          <input ref="documentInput" type="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.txt" class="hidden" @change="handleDocumentUpload" />
          <input ref="cameraInput" type="file" accept="image/*" capture="environment" class="hidden" @change="handleImageUpload" />

          <!-- Text Input -->
          <input
            v-model="newMessage"
            @keydown.enter="sendTextMessage"
            type="text"
            placeholder="Type a message..."
            :disabled="isUploadingAttachment"
            class="flex-1 px-4 py-2.5 text-sm bg-gray-100 rounded-full focus:ring-2 focus:ring-green-400 focus:outline-none border-0 focus:bg-white transition-all placeholder:text-gray-400"
          />

          <!-- Send Button -->
          <button
            @click="sendTextMessage"
            :disabled="!newMessage.trim() || isSending || isUploadingAttachment"
            class="p-2.5 flex bg-gradient-to-r from-green-500 to-green-600 text-white rounded-full hover:from-green-600 hover:to-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm hover:shadow-md"
          >
            <UIcon v-if="isSending" name="i-heroicons-arrow-path" class="w-5 h-5 animate-spin" />
            <UIcon v-else name="i-heroicons-paper-airplane" class="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>

    <!-- Image Viewer Modal -->
    <UModal v-model="showImageViewer" :ui="{ width: 'max-w-4xl' }">
      <div class="relative bg-black">
        <button
          @click="showImageViewer = false"
          class="absolute top-4 right-4 z-10 p-2 bg-black/50 hover:bg-black/70 rounded-full transition-colors"
        >
          <UIcon name="i-heroicons-x-mark" class="w-6 h-6 text-white" />
        </button>
        <img
          :src="viewingImageUrl"
          alt="Full size image"
          class="w-full h-auto max-h-[90vh] object-contain"
        />
      </div>
    </UModal>
  </USlideover>
</template>

<script setup>
const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  user: {
    type: Object,
    required: true
  },
  chatroomId: {
    type: [String, Number],
    default: null
  }
})

const emit = defineEmits(['update:modelValue'])
const toast = useToast()
const { user: currentUser } = useAuth()
const { get, post, patch, del } = useApi()
const { chatIconPath } = useStaticAssets()

// Default placeholder image - use a data URI for guaranteed availability
const defaultPlaceholder = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%239CA3AF"%3E%3Cpath d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/%3E%3C/svg%3E'

// Handle broken image by falling back to placeholder
const handleImageError = (event) => {
  event.target.src = defaultPlaceholder
}

// State
const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const messages = ref([])
const newMessage = ref('')
const isLoadingMessages = ref(false)
const isSending = ref(false)
const messagesContainer = ref(null)

// Attachment state
const showAttachmentOptions = ref(false)
const isUploadingAttachment = ref(false)
const imageInput = ref(null)
const videoInput = ref(null)
const documentInput = ref(null)
const cameraInput = ref(null)

// Image viewer state
const showImageViewer = ref(false)
const viewingImageUrl = ref('')

// Edit/Delete state
const activeMessageMenu = ref(null)
const showEditModal = ref(false)
const showDeleteModal = ref(false)
const editingMessage = ref(null)
const editMessageContent = ref('')
const isEditingMessage = ref(false)
const isDeletingMessage = ref(false)
const messageToDelete = ref(null)

// Polling
let pollingInterval = null

// Computed for current user ID (user object is nested)
const currentUserId = computed(() => currentUser.value?.user?.id || currentUser.value?.id)

// Methods
const isOwnMessage = (message) => {
  if (!message?.sender?.id || !currentUserId.value) return false
  // Use string comparison to handle type mismatch (number vs string)
  return String(message.sender.id) === String(currentUserId.value)
}

const formatMessageTime = (timestamp) => {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  const now = new Date()
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)
  
  if (diffInSeconds < 60) return 'Just now'
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`
  
  // Same day
  if (date.toDateString() === now.toDateString()) {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }
  
  return date.toLocaleDateString([], { month: 'short', day: 'numeric' })
}

const formatFileSize = (bytes) => {
  if (!bytes) return ''
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
}

const linkifyText = (text) => {
  if (!text) return ''
  const urlRegex = /(https?:\/\/[^\s]+)/g
  return text.replace(urlRegex, '<a href="$1" target="_blank" rel="noopener noreferrer" class="underline hover:no-underline">$1</a>')
}

const openMediaViewer = (message) => {
  if (message.media_url) {
    viewingImageUrl.value = message.media_url
    showImageViewer.value = true
  }
}

const loadMessages = async () => {
  if (!props.chatroomId) return
  
  isLoadingMessages.value = true
  try {
    const { data, error } = await get(`/adsyconnect/messages/?chatroom=${props.chatroomId}`)
    if (data && !error) {
      messages.value = data.results || data || []
      await nextTick()
      scrollToBottom()
      // Mark messages as read
      markMessagesAsRead()
    }
  } catch (error) {
    console.error('Error loading messages:', error)
  } finally {
    isLoadingMessages.value = false
  }
}

const markMessagesAsRead = async () => {
  if (!props.chatroomId) return
  try {
    await post(`/adsyconnect/chatrooms/${props.chatroomId}/mark_as_read/`, {})
  } catch (error) {
    // Silently handle
  }
}

const sendTextMessage = async () => {
  if (!newMessage.value.trim() || !props.chatroomId || isSending.value) return
  
  isSending.value = true
  const messageContent = newMessage.value.trim()
  newMessage.value = ''
  
  // Optimistic update
  const tempMessage = {
    id: Date.now(),
    content: messageContent,
    sender: { id: currentUserId.value },
    message_type: 'text',
    created_at: new Date().toISOString(),
    is_read: false
  }
  messages.value.push(tempMessage)
  scrollToBottom()
  
  try {
    const { data, error } = await post('/adsyconnect/messages/', {
      chatroom: props.chatroomId,
      receiver: props.user?.id,
      message_type: 'text',
      content: messageContent
    })
    
    if (data && !error) {
      const index = messages.value.findIndex(m => m.id === tempMessage.id)
      if (index !== -1) {
        messages.value[index] = data
      }
    }
  } catch (error) {
    console.error('Error sending message:', error)
    messages.value = messages.value.filter(m => m.id !== tempMessage.id)
    toast.add({
      title: 'Failed to send message',
      color: 'red',
      timeout: 3000,
    })
  } finally {
    isSending.value = false
  }
}

// Attachment handling
const pickImage = () => {
  showAttachmentOptions.value = false
  imageInput.value?.click()
}

const pickVideo = () => {
  showAttachmentOptions.value = false
  videoInput.value?.click()
}

const pickDocument = () => {
  showAttachmentOptions.value = false
  documentInput.value?.click()
}

const pickCamera = () => {
  showAttachmentOptions.value = false
  cameraInput.value?.click()
}

const handleImageUpload = (event) => {
  const file = event.target.files?.[0]
  if (file) sendMediaMessage(file, 'image')
  event.target.value = ''
}

const handleVideoUpload = (event) => {
  const file = event.target.files?.[0]
  if (file) sendMediaMessage(file, 'video')
  event.target.value = ''
}

const handleDocumentUpload = (event) => {
  const file = event.target.files?.[0]
  if (file) sendMediaMessage(file, 'document')
  event.target.value = ''
}

const sendMediaMessage = async (file, messageType) => {
  if (!props.chatroomId) return
  
  isUploadingAttachment.value = true
  
  try {
    const formData = new FormData()
    formData.append('chatroom', props.chatroomId)
    formData.append('receiver', props.user?.id)
    formData.append('message_type', messageType)
    formData.append('media_file', file)
    formData.append('file_name', file.name)
    
    // Don't set Content-Type header for FormData - browser sets it automatically with boundary
    const { data, error } = await post('/adsyconnect/messages/', formData)
    
    if (data && !error) {
      messages.value.push(data)
      scrollToBottom()
      toast.add({
        title: 'Sent',
        description: `${messageType === 'image' ? 'Photo' : messageType === 'video' ? 'Video' : 'File'} sent successfully`,
        color: 'green',
        timeout: 2000,
      })
    } else {
      throw new Error('Upload failed')
    }
  } catch (error) {
    console.error('Error uploading:', error)
    toast.add({
      title: 'Failed to upload',
      description: 'Please try again',
      color: 'red',
      timeout: 3000,
    })
  } finally {
    isUploadingAttachment.value = false
  }
}

const scrollToBottom = (smooth = false) => {
  nextTick(() => {
    if (messagesContainer.value) {
      if (smooth) {
        messagesContainer.value.scrollTo({
          top: messagesContainer.value.scrollHeight,
          behavior: 'smooth'
        })
      } else {
        messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
      }
    }
  })
}

// Edit/Delete methods
const toggleMessageMenu = (messageId) => {
  activeMessageMenu.value = activeMessageMenu.value === messageId ? null : messageId
}

const startEditMessage = (message) => {
  editingMessage.value = message
  editMessageContent.value = message.content
  activeMessageMenu.value = null
  showEditModal.value = true
}

const saveEditMessage = async () => {
  if (!editingMessage.value || !editMessageContent.value.trim()) return
  
  isEditingMessage.value = true
  try {
    const { data, error } = await patch(`/adsyconnect/messages/${editingMessage.value.id}/edit/`, {
      content: editMessageContent.value.trim()
    })
    
    if (data && !error) {
      // Update message in local state
      const index = messages.value.findIndex(m => m.id === editingMessage.value.id)
      if (index !== -1) {
        messages.value[index] = { ...messages.value[index], ...data }
      }
      showEditModal.value = false
      editingMessage.value = null
      editMessageContent.value = ''
      toast.add({
        title: 'Message edited',
        color: 'green',
        timeout: 2000,
      })
    } else {
      throw new Error('Failed to edit message')
    }
  } catch (error) {
    console.error('Error editing message:', error)
    toast.add({
      title: 'Failed to edit message',
      color: 'red',
      timeout: 3000,
    })
  } finally {
    isEditingMessage.value = false
  }
}

const confirmDeleteMessage = (message) => {
  messageToDelete.value = message
  activeMessageMenu.value = null
  showDeleteModal.value = true
}

const deleteMessage = async () => {
  if (!messageToDelete.value) return
  
  isDeletingMessage.value = true
  try {
    const { data, error } = await del(`/adsyconnect/messages/${messageToDelete.value.id}/`)
    
    if (!error) {
      // Update message in local state to show as deleted
      const index = messages.value.findIndex(m => m.id === messageToDelete.value.id)
      if (index !== -1) {
        if (data) {
          messages.value[index] = { ...messages.value[index], ...data }
        } else {
          messages.value[index].is_deleted = true
        }
      }
      showDeleteModal.value = false
      toast.add({
        title: 'Message deleted',
        color: 'green',
        timeout: 2000,
      })
    } else {
      throw new Error('Failed to delete message')
    }
  } catch (error) {
    console.error('Error deleting message:', error)
    toast.add({
      title: 'Failed to delete message',
      color: 'red',
      timeout: 3000,
    })
  } finally {
    isDeletingMessage.value = false
    messageToDelete.value = null
  }
}

// Close menu when clicking outside
const closeMenuOnClickOutside = () => {
  activeMessageMenu.value = null
}

const startPolling = () => {
  if (pollingInterval) clearInterval(pollingInterval)
  
  // Poll for new messages every 3 seconds
  pollingInterval = setInterval(async () => {
    if (props.chatroomId && isOpen.value) {
      try {
        const { data, error } = await get(`/adsyconnect/messages/?chatroom=${props.chatroomId}`)
        if (data && !error) {
          const newMessages = data.results || data || []
          if (newMessages.length > messages.value.length) {
            messages.value = newMessages
            scrollToBottom()
          }
        }
      } catch (error) {
        // Silently handle
      }
    }
  }, 3000)
}

const stopPolling = () => {
  if (pollingInterval) {
    clearInterval(pollingInterval)
    pollingInterval = null
  }
}

const close = () => {
  isOpen.value = false
}

// Watch for open state
watch(isOpen, async (newValue) => {
  if (newValue && props.chatroomId) {
    await loadMessages()
    startPolling()
    // Ensure scroll to bottom after DOM is fully rendered
    await nextTick()
    scrollToBottom()
    // Additional scroll after a short delay to handle any async rendering
    setTimeout(() => scrollToBottom(), 100)
    setTimeout(() => scrollToBottom(), 300)
  } else {
    stopPolling()
    // Reset all menu/modal states when closing
    activeMessageMenu.value = null
  }
})

// Watch for modal close to reset states
watch(showEditModal, (newValue) => {
  if (!newValue) {
    editingMessage.value = null
    editMessageContent.value = ''
  }
})

watch(showDeleteModal, (newValue) => {
  if (!newValue) {
    messageToDelete.value = null
  }
})

// Close menu when clicking on messages container
const handleContainerClick = () => {
  activeMessageMenu.value = null
}

// Watch for new messages and scroll to bottom
watch(messages, (newMessages, oldMessages) => {
  if (newMessages.length > (oldMessages?.length || 0)) {
    scrollToBottom(true)
  }
}, { deep: true })

// Cleanup on unmount
onUnmounted(() => {
  stopPolling()
})
</script>

<style scoped>
/* Hide scrollbar but keep functionality */
.messages-container {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}

.messages-container::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Opera */
}

.safe-area-bottom {
  padding-bottom: calc(env(safe-area-inset-bottom, 0px) + 0.75rem);
}
</style>
