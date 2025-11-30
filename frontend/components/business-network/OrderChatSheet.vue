<template>
  <!-- Chat Modal/Sheet -->
  <ClientOnly>
    <Teleport to="body">
      <!-- Overlay -->
      <Transition name="fade">
        <div 
          v-if="isOpen" 
          class="fixed inset-0 bg-black/50 z-50"
          @click="closeSheet"
        ></div>
      </Transition>
      
      <!-- Modal Container - Centered on desktop, bottom sheet on mobile -->
      <Transition name="slide-up">
        <div 
          v-if="isOpen"
          class="fixed z-50 bg-white shadow-2xl flex flex-col
                 bottom-0 left-0 right-0 rounded-t-2xl max-h-[85vh]
                 sm:bottom-auto sm:left-1/2 sm:right-auto sm:top-1/2 sm:-translate-x-1/2 sm:-translate-y-1/2
                 sm:rounded-2xl sm:w-[520px] sm:max-h-[680px]
                 lg:w-[580px] lg:max-h-[720px]"
          @click.stop
        >
          <!-- Handle Bar (mobile only) -->
          <div class="flex justify-center pt-3 pb-2 sm:hidden">
            <div class="w-12 h-1.5 bg-gray-300 rounded-full"></div>
          </div>
          
          <!-- Header -->
          <div class="px-4 py-3 border-b border-gray-100 bg-gradient-to-r from-purple-50 to-indigo-50 sm:rounded-t-2xl">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3 cursor-pointer" @click="navigateToProfile">
                <div class="relative">
                  <img
                    :src="otherUser?.avatar || '/images/placeholder.jpg'"
                    :alt="otherUser?.name"
                    class="w-10 h-10 rounded-full object-cover ring-2 ring-white shadow-sm hover:ring-purple-300 transition-all"
                  />
                  <div class="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-white rounded-full"></div>
                </div>
                <div>
                  <div class="flex items-center gap-1.5">
                    <h3 class="text-base font-semibold text-gray-900 hover:text-purple-600 transition-colors">
                      {{ otherUser?.name || 'Chat' }}
                    </h3>
                    <!-- Pro Badge -->
                    <span 
                      v-if="otherUser?.is_pro" 
                      class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white"
                    >
                      PRO
                    </span>
                    <!-- Verified Badge -->
                    <UIcon 
                      v-if="otherUser?.is_verified" 
                      name="i-heroicons-check-badge-solid" 
                      class="w-4 h-4 text-blue-500" 
                    />
                  </div>
                  <p class="text-xs text-gray-500">
                    Order #{{ orderNumber }}
                  </p>
                </div>
              </div>
              <button 
                @click="closeSheet"
                class="p-2 hover:bg-white/50 rounded-full transition-colors"
              >
                <UIcon name="i-heroicons-x-mark" class="w-5 h-5 text-gray-500" />
              </button>
            </div>
          </div>
          
          <!-- Messages Area -->
          <div 
            ref="messagesContainer"
            class="flex-1 overflow-y-auto p-4 bg-gray-50 messages-container"
            style="min-height: 280px; max-height: calc(85vh - 200px);"
          >
            <!-- Loading State -->
            <div v-if="isLoadingMessages" class="flex justify-center items-center h-full">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500"></div>
            </div>
            
            <!-- Empty State -->
            <div v-else-if="messages.length === 0" class="flex flex-col justify-center items-center h-full text-center py-8">
              <img 
                src="/images/chat_icon.png" 
                alt="Chat"
                class="w-16 h-16 opacity-30 mb-4"
              />
              <p class="text-gray-400 text-sm">No messages yet</p>
              <p class="text-gray-400 text-xs mt-1">Start the conversation about this order</p>
            </div>
            
            <!-- Messages List -->
            <div v-else class="space-y-1.5">
              <template v-for="message in messages" :key="message.id">
                <!-- System Message -->
                <div v-if="isSystemMessage(message)" class="flex justify-center my-3">
                  <div class="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-2 rounded-full text-xs text-center max-w-[90%]">
                    <span class="whitespace-pre-wrap">{{ message.content }}</span>
                    <span class="text-amber-500 ml-2 text-[10px]">{{ formatTimeAgo(message.created_at) }}</span>
                  </div>
                </div>
                
                <!-- Regular Message -->
                <div
                  v-else
                  class="flex items-end gap-1.5"
                  :class="isMyMessage(message) ? 'justify-end' : 'justify-start'"
                >
                  <!-- Avatar for received messages -->
                  <div v-if="!isMyMessage(message)" class="flex-shrink-0 mb-0.5">
                    <img
                      :src="otherUser?.avatar || '/images/placeholder.jpg'"
                      :alt="otherUser?.name"
                      class="w-6 h-6 rounded-full object-cover"
                    />
                  </div>
                  
                  <!-- Message Content -->
                  <div
                    class="max-w-[78%] rounded-xl overflow-hidden"
                    :class="isMyMessage(message) 
                      ? 'bg-purple-500 text-white rounded-br-sm' 
                      : 'bg-white text-gray-800 border border-gray-200 rounded-bl-sm'"
                  >
                  <!-- Image Message -->
                  <div v-if="message.media_url && message.message_type === 'image'" class="relative group">
                    <img
                      :src="message.media_url"
                      :alt="message.file_name || 'Image'"
                      class="w-full h-auto max-h-40 object-cover cursor-pointer"
                      @click.stop="openImageViewer(message.media_url)"
                    />
                  </div>
                  
                  <!-- Video Message -->
                  <div v-else-if="message.media_url && message.message_type === 'video'" class="relative">
                    <video
                      :src="message.media_url"
                      class="w-full h-auto max-h-40 object-cover"
                      controls
                      preload="metadata"
                    ></video>
                  </div>
                  
                  <!-- Document Message -->
                  <div v-else-if="message.media_url && message.message_type === 'document'" class="px-2.5 py-2">
                    <a
                      :href="message.media_url"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="flex items-center gap-2"
                      @click.stop
                    >
                      <UIcon name="i-heroicons-document-text" class="w-5 h-5 flex-shrink-0" :class="isMyMessage(message) ? 'text-white/80' : 'text-gray-500'" />
                      <div class="flex-1 min-w-0">
                        <p class="text-xs font-medium truncate">{{ message.file_name || 'Document' }}</p>
                        <p class="text-[9px] opacity-60">{{ formatFileSize(message.file_size) }}</p>
                      </div>
                      <UIcon name="i-heroicons-arrow-down-tray" class="w-3.5 h-3.5 flex-shrink-0 opacity-60" />
                    </a>
                  </div>
                  
                  <!-- Text Content -->
                  <div v-if="message.content" class="px-3 py-1.5">
                    <p class="text-[13px] leading-snug whitespace-pre-wrap">{{ message.content }}</p>
                  </div>
                  
                  <!-- Time & Read Status -->
                  <div class="px-3 pb-1 flex items-center justify-end gap-1">
                    <span 
                      class="text-[9px]"
                      :class="isMyMessage(message) ? 'text-white/60' : 'text-gray-400'"
                    >
                      {{ formatTimeAgo(message.created_at) }}
                    </span>
                    <UIcon 
                      v-if="isMyMessage(message)"
                      :name="message.is_read ? 'i-heroicons-check-circle-solid' : 'i-heroicons-check'"
                      class="w-2.5 h-2.5"
                      :class="message.is_read ? 'text-blue-300' : 'text-white/40'"
                    />
                  </div>
                </div>
                </div>
              </template>
            </div>
          </div>
          
          <!-- Selected File Preview -->
          <div v-if="selectedFile" class="px-4 py-2 border-t border-gray-100 bg-gray-50">
            <div class="flex items-center gap-3">
              <div class="relative">
                <img 
                  v-if="selectedFileType === 'image'"
                  :src="selectedFilePreview" 
                  alt="Selected" 
                  class="h-14 w-14 object-cover rounded-lg"
                />
                <div v-else class="h-14 w-14 bg-purple-100 rounded-lg flex items-center justify-center">
                  <UIcon 
                    :name="selectedFileType === 'video' ? 'i-heroicons-video-camera' : 'i-heroicons-document'" 
                    class="w-6 h-6 text-purple-600" 
                  />
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-gray-900 truncate">{{ selectedFile.name }}</p>
                <p class="text-xs text-gray-500">{{ formatFileSize(selectedFile.size) }}</p>
              </div>
              <button
                @click="removeSelectedFile"
                class="p-2 text-red-500 hover:bg-red-50 rounded-full transition-colors"
              >
                <UIcon name="i-heroicons-x-mark" class="w-5 h-5" />
              </button>
            </div>
          </div>
          
          <!-- Input Area -->
          <div class="px-3 py-2 border-t border-gray-100 bg-white sm:rounded-b-2xl">
            <!-- Upload Progress -->
            <div v-if="isUploading" class="mb-2 px-2 py-1.5 bg-purple-50 rounded-lg border border-purple-100">
              <div class="flex items-center space-x-2">
                <div class="animate-spin rounded-full h-3 w-3 border-b-2 border-purple-500"></div>
                <p class="text-xs text-purple-700">Uploading...</p>
              </div>
            </div>
            
            <div class="flex items-center gap-1.5">
              <!-- Attachment Button -->
              <div class="relative">
                <button
                  @click="showAttachmentMenu = !showAttachmentMenu"
                  class="p-2 text-gray-400 hover:text-purple-600 hover:bg-purple-50 rounded-full transition-colors flex-shrink-0"
                  :disabled="isSending || isUploading"
                >
                  <UIcon name="i-heroicons-paper-clip" class="w-5 h-5" />
                </button>
                
                <!-- Attachment Options Dropdown -->
                <div
                  v-if="showAttachmentMenu"
                  class="absolute bottom-full left-0 mb-2 w-48 bg-white rounded-xl shadow-lg border border-gray-200 z-50 overflow-hidden"
                >
                  <div class="p-2">
                    <div class="flex items-center justify-between mb-2 px-1">
                      <span class="text-xs font-semibold text-gray-700">Attach</span>
                      <button
                        @click="showAttachmentMenu = false"
                        class="p-0.5 hover:bg-gray-100 rounded-full"
                      >
                        <UIcon name="i-heroicons-x-mark" class="w-3.5 h-3.5 text-gray-400" />
                      </button>
                    </div>
                    
                    <div class="grid grid-cols-4 gap-1">
                      <button @click="pickImage" class="flex flex-col items-center p-2 rounded-lg hover:bg-purple-50 transition-colors group">
                        <div class="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center group-hover:bg-purple-200">
                          <UIcon name="i-heroicons-photo" class="w-4 h-4 text-purple-600" />
                        </div>
                        <span class="text-[10px] text-gray-600 mt-1">Photo</span>
                      </button>
                      
                      <button @click="pickVideo" class="flex flex-col items-center p-2 rounded-lg hover:bg-red-50 transition-colors group">
                        <div class="w-8 h-8 bg-red-100 rounded-lg flex items-center justify-center group-hover:bg-red-200">
                          <UIcon name="i-heroicons-video-camera" class="w-4 h-4 text-red-600" />
                        </div>
                        <span class="text-[10px] text-gray-600 mt-1">Video</span>
                      </button>
                      
                      <button @click="pickDocument" class="flex flex-col items-center p-2 rounded-lg hover:bg-green-50 transition-colors group">
                        <div class="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center group-hover:bg-green-200">
                          <UIcon name="i-heroicons-document" class="w-4 h-4 text-green-600" />
                        </div>
                        <span class="text-[10px] text-gray-600 mt-1">File</span>
                      </button>
                      
                      <button @click="pickCamera" class="flex flex-col items-center p-2 rounded-lg hover:bg-blue-50 transition-colors group">
                        <div class="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center group-hover:bg-blue-200">
                          <UIcon name="i-heroicons-camera" class="w-4 h-4 text-blue-600" />
                        </div>
                        <span class="text-[10px] text-gray-600 mt-1">Camera</span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Hidden File Inputs -->
              <input ref="imageInput" type="file" accept="image/*" class="hidden" @change="handleImageSelect" />
              <input ref="videoInput" type="file" accept="video/*" class="hidden" @change="handleVideoSelect" />
              <input ref="documentInput" type="file" accept=".pdf,.doc,.docx,.txt,.zip,.rar,.xls,.xlsx" class="hidden" @change="handleDocumentSelect" />
              <input ref="cameraInput" type="file" accept="image/*" capture="environment" class="hidden" @change="handleCameraCapture" />
              
              <!-- Message Input -->
              <div class="flex-1 min-w-0">
                <input
                  v-model="newMessage"
                  type="text"
                  @keypress.enter="sendMessage"
                  placeholder="Type a message..."
                  class="w-full px-3 py-2 text-sm bg-gray-100 rounded-full focus:ring-2 focus:ring-purple-400 focus:outline-none border-0 focus:bg-white transition-all placeholder:text-gray-400"
                  :disabled="isSending || isUploading"
                />
              </div>
              
              <!-- Send Button -->
              <button
                @click="sendMessage"
                :disabled="(!newMessage.trim() && !selectedFile) || isSending || isUploading"
                class="flex-shrink-0 w-9 h-9 rounded-full bg-gradient-to-r from-purple-500 to-purple-600 text-white flex items-center justify-center hover:from-purple-600 hover:to-purple-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-sm"
              >
                <UIcon v-if="isSending" name="i-heroicons-arrow-path" class="w-4 h-4 animate-spin" />
                <UIcon v-else name="i-heroicons-paper-airplane-solid" class="w-4 h-4 -rotate-45" />
              </button>
            </div>
          </div>
        </div>
      </Transition>
      
      <!-- Image Viewer Modal -->
      <Transition
        enter-active-class="transition-opacity duration-300"
        leave-active-class="transition-opacity duration-300"
        enter-from-class="opacity-0"
        leave-to-class="opacity-0"
      >
        <div
          v-if="showImageViewer"
          class="fixed inset-0 z-[9999] bg-black/95 flex flex-col items-center justify-center"
          @click="closeImageViewer"
        >
          <!-- Close Button - Fixed Top Right -->
          <button
            @click.stop="closeImageViewer"
            class="fixed top-20 right-4 z-[10000] w-10 h-10 bg-gray-800 hover:bg-gray-700 rounded-full transition-all duration-200 hover:scale-105 shadow-xl flex items-center justify-center border border-gray-600"
            title="Close (ESC)"
          >
            <UIcon name="i-heroicons-x-mark" class="w-5 h-5 text-white" />
          </button>
          
          <!-- Header Label -->
          <div class="fixed top-20 left-4 z-[10000] text-white text-sm font-medium flex items-center gap-2 bg-gray-800 px-4 py-2 rounded-full shadow-xl border border-gray-600">
            <UIcon name="i-heroicons-photo" class="w-4 h-4 text-purple-400" />
            <span>Image Preview</span>
          </div>

          <!-- Image Container -->
          <div 
            class="flex-1 flex items-center justify-center p-8 w-full"
            @click.stop
          >
            <div class="relative max-w-4xl w-full">
              <img
                :src="imageViewerUrl"
                alt="Chat image"
                class="max-h-[80vh] max-w-full mx-auto object-contain rounded-xl shadow-2xl"
                @click.stop
              />
              
              <!-- Download Button -->
              <a
                :href="imageViewerUrl"
                :download="'order-chat-image-' + Date.now()"
                class="absolute bottom-4 left-4 p-3 bg-black/70 hover:bg-black/90 rounded-full transition-all duration-200 hover:scale-110 shadow-lg group"
                @click.stop
                title="Download image"
              >
                <UIcon name="i-heroicons-arrow-down-tray" class="w-5 h-5 text-white group-hover:text-purple-400 transition-colors" />
              </a>
            </div>
          </div>

          <!-- Footer hint -->
          <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-4">
            <p class="text-center text-white/60 text-xs">
              Click anywhere or press ESC to close
            </p>
          </div>
        </div>
      </Transition>
    </Teleport>
  </ClientOnly>
</template>

<script setup>
import { ref, watch, nextTick, onMounted, onUnmounted } from 'vue';

const props = defineProps({
  isOpen: { type: Boolean, default: false },
  orderId: { type: String, default: '' },
  orderNumber: { type: String, default: '' },
  otherUser: { type: Object, default: () => ({}) },
  currentUserId: { type: String, default: '' }
});

const emit = defineEmits(['update:isOpen', 'close', 'messages-read', 'new-message']);

// Router for navigation
const router = useRouter();

// Check if message is a system message (no sender)
const isSystemMessage = (message) => {
  return !message?.sender && !message?.sender_id;
};

// Check if message is from current user
const isMyMessage = (message) => {
  // System messages are not from current user
  if (isSystemMessage(message)) return false;
  
  if (!props.currentUserId) return false;
  
  // Handle both cases: sender as object with id, or sender as direct id
  const senderId = message?.sender?.id || message?.sender;
  if (!senderId) return false;
  
  // Compare as strings to handle UUID comparison
  return String(senderId) === String(props.currentUserId);
};

// Navigate to user's business network profile
const navigateToProfile = () => {
  if (props.otherUser?.id) {
    closeSheet();
    router.push(`/business-network/profile/${props.otherUser.id}`);
  }
};

// State
const messages = ref([]);
const newMessage = ref('');
const isLoadingMessages = ref(false);
const isSending = ref(false);
const isUploading = ref(false);
const messagesContainer = ref(null);

// File inputs
const imageInput = ref(null);
const videoInput = ref(null);
const documentInput = ref(null);
const cameraInput = ref(null);

// Selected file state
const selectedFile = ref(null);
const selectedFilePreview = ref('');
const selectedFileType = ref(''); // 'image', 'video', 'document'

// Attachment menu
const showAttachmentMenu = ref(false);

// Image viewer
const showImageViewer = ref(false);
const imageViewerUrl = ref('');

// Polling interval
let pollingInterval = null;

// Composables
const { get, post } = useApi();
const toast = useToast();

// Close sheet
const closeSheet = () => {
  emit('update:isOpen', false);
  emit('close');
  stopPolling();
  removeSelectedFile();
  showAttachmentMenu.value = false;
};

// File picker functions
const pickImage = () => {
  showAttachmentMenu.value = false;
  imageInput.value?.click();
};

const pickVideo = () => {
  showAttachmentMenu.value = false;
  videoInput.value?.click();
};

const pickDocument = () => {
  showAttachmentMenu.value = false;
  documentInput.value?.click();
};

const pickCamera = () => {
  showAttachmentMenu.value = false;
  cameraInput.value?.click();
};

// File handlers
const handleImageSelect = (event) => {
  const file = event.target.files?.[0];
  if (file) {
    if (file.size > 10 * 1024 * 1024) {
      toast.add({ title: 'File too large', description: 'Please select an image under 10MB', color: 'red' });
      return;
    }
    selectedFile.value = file;
    selectedFileType.value = 'image';
    selectedFilePreview.value = URL.createObjectURL(file);
  }
  if (imageInput.value) imageInput.value.value = '';
};

const handleVideoSelect = (event) => {
  const file = event.target.files?.[0];
  if (file) {
    if (file.size > 50 * 1024 * 1024) {
      toast.add({ title: 'File too large', description: 'Please select a video under 50MB', color: 'red' });
      return;
    }
    selectedFile.value = file;
    selectedFileType.value = 'video';
    selectedFilePreview.value = '';
  }
  if (videoInput.value) videoInput.value.value = '';
};

const handleDocumentSelect = (event) => {
  const file = event.target.files?.[0];
  if (file) {
    if (file.size > 25 * 1024 * 1024) {
      toast.add({ title: 'File too large', description: 'Please select a file under 25MB', color: 'red' });
      return;
    }
    selectedFile.value = file;
    selectedFileType.value = 'document';
    selectedFilePreview.value = '';
  }
  if (documentInput.value) documentInput.value.value = '';
};

const handleCameraCapture = (event) => {
  const file = event.target.files?.[0];
  if (file) {
    selectedFile.value = file;
    selectedFileType.value = 'image';
    selectedFilePreview.value = URL.createObjectURL(file);
  }
  if (cameraInput.value) cameraInput.value.value = '';
};

const removeSelectedFile = () => {
  if (selectedFilePreview.value) {
    URL.revokeObjectURL(selectedFilePreview.value);
  }
  selectedFile.value = null;
  selectedFilePreview.value = '';
  selectedFileType.value = '';
};

// Image viewer functions
const openImageViewer = (url) => {
  imageViewerUrl.value = url;
  showImageViewer.value = true;
  document.addEventListener('keydown', handleImageViewerKeydown);
};

const closeImageViewer = () => {
  showImageViewer.value = false;
  imageViewerUrl.value = '';
  document.removeEventListener('keydown', handleImageViewerKeydown);
};

const handleImageViewerKeydown = (event) => {
  if (event.key === 'Escape') {
    closeImageViewer();
  }
};

// Format file size
const formatFileSize = (bytes) => {
  if (!bytes) return '';
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  if (bytes === 0) return '0 Bytes';
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
};

// Format time
const formatTime = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  return date.toLocaleTimeString('en-US', { 
    hour: 'numeric', 
    minute: '2-digit',
    hour12: true 
  });
};

// Format time ago
const formatTimeAgo = (dateString) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now - date;
  const diffSecs = Math.floor(diffMs / 1000);
  const diffMins = Math.floor(diffSecs / 60);
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);
  
  if (diffSecs < 60) return 'now';
  if (diffMins < 60) return `${diffMins}m`;
  if (diffHours < 24) return `${diffHours}h`;
  if (diffDays < 7) return `${diffDays}d`;
  
  // For older messages, show date
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

// Scroll to bottom
const scrollToBottom = (smooth = false) => {
  nextTick(() => {
    setTimeout(() => {
      if (messagesContainer.value) {
        if (smooth) {
          messagesContainer.value.scrollTo({
            top: messagesContainer.value.scrollHeight,
            behavior: 'smooth'
          });
        } else {
          messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
        }
      }
    }, 100);
  });
};

// Load messages
const loadMessages = async (markAsRead = true) => {
  if (!props.orderId) return;
  
  isLoadingMessages.value = true;
  try {
    const { data, error } = await get(`/workspace/orders/${props.orderId}/messages/`);
    
    if (data && !error) {
      const newMessages = data.results || data || [];
      
      // Count unread messages before marking as read
      const unreadCount = newMessages.filter(m => 
        !m.is_read && 
        String(m.sender?.id || m.sender) !== String(props.currentUserId)
      ).length;
      
      messages.value = newMessages;
      scrollToBottom();
      
      // Mark messages as read and emit event
      if (markAsRead && unreadCount > 0) {
        await markMessagesAsRead();
        emit('messages-read', { orderId: props.orderId, count: unreadCount });
      }
    }
  } catch (err) {
    console.error('Error loading messages:', err);
  } finally {
    isLoadingMessages.value = false;
  }
};

// Mark messages as read
const markMessagesAsRead = async () => {
  if (!props.orderId) return;
  
  try {
    await post(`/workspace/orders/${props.orderId}/messages/mark-read/`);
  } catch (err) {
    // Silently handle - not critical
  }
};

// Send message
const sendMessage = async () => {
  const hasText = newMessage.value.trim();
  const hasFile = selectedFile.value;
  
  if ((!hasText && !hasFile) || isSending.value || isUploading.value || !props.orderId) return;
  
  const messageContent = newMessage.value.trim();
  const fileToSend = selectedFile.value;
  const fileType = selectedFileType.value;
  
  // Optimistic update
  const tempMessage = {
    id: `temp-${Date.now()}`,
    content: messageContent,
    sender: { id: props.currentUserId },
    created_at: new Date().toISOString(),
    is_read: false,
    media_url: selectedFilePreview.value || null,
    message_type: fileType || 'text',
    file_name: fileToSend?.name || null
  };
  messages.value.push(tempMessage);
  newMessage.value = '';
  removeSelectedFile();
  scrollToBottom();
  
  isSending.value = true;
  if (fileToSend) isUploading.value = true;
  
  try {
    let response;
    
    if (fileToSend) {
      // Send with FormData for file upload
      const formData = new FormData();
      formData.append('content', messageContent);
      formData.append('media', fileToSend);
      formData.append('message_type', fileType);
      
      response = await post(`/workspace/orders/${props.orderId}/messages/create/`, formData);
    } else {
      // Send text only
      response = await post(`/workspace/orders/${props.orderId}/messages/create/`, {
        content: messageContent
      });
    }
    
    const { data, error } = response;
    
    if (data && !error) {
      // Replace temp message with real one
      const index = messages.value.findIndex(m => m.id === tempMessage.id);
      if (index !== -1) {
        messages.value[index] = data;
      }
    } else {
      // Remove temp message on error
      messages.value = messages.value.filter(m => m.id !== tempMessage.id);
      toast.add({
        title: 'Error',
        description: 'Failed to send message',
        color: 'red'
      });
    }
  } catch (err) {
    console.error('Error sending message:', err);
    messages.value = messages.value.filter(m => m.id !== tempMessage.id);
    toast.add({
      title: 'Error',
      description: 'Failed to send message',
      color: 'red'
    });
  } finally {
    isSending.value = false;
    isUploading.value = false;
  }
};

// Start polling for new messages
const startPolling = () => {
  if (pollingInterval) clearInterval(pollingInterval);
  
  pollingInterval = setInterval(async () => {
    if (props.isOpen && props.orderId) {
      try {
        const { data, error } = await get(`/workspace/orders/${props.orderId}/messages/`);
        if (data && !error) {
          const newMessages = data.results || data || [];
          const currentCount = messages.value.filter(m => !String(m.id).startsWith('temp-')).length;
          
          if (newMessages.length > currentCount) {
            // Check for new messages from other user
            const newFromOther = newMessages.filter(m => 
              !messages.value.find(existing => existing.id === m.id) &&
              String(m.sender?.id || m.sender) !== String(props.currentUserId)
            );
            
            messages.value = newMessages;
            scrollToBottom(true);
            
            // Mark new messages as read since chat is open
            if (newFromOther.length > 0) {
              await markMessagesAsRead();
              emit('messages-read', { orderId: props.orderId, count: newFromOther.length });
            }
          }
        }
      } catch (err) {
        // Silently handle polling errors
      }
    }
  }, 3000); // Poll every 3 seconds for more responsive chat
};

// Stop polling
const stopPolling = () => {
  if (pollingInterval) {
    clearInterval(pollingInterval);
    pollingInterval = null;
  }
};

// Watch for open state
watch(() => props.isOpen, async (isOpen) => {
  if (isOpen) {
    await loadMessages();
    // Ensure scroll to bottom after messages are rendered
    scrollToBottom();
    startPolling();
  } else {
    stopPolling();
  }
}, { immediate: true });

// Cleanup on unmount
onUnmounted(() => {
  stopPolling();
});
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Mobile: slide up from bottom */
.slide-up-enter-active,
.slide-up-leave-active {
  transition: transform 0.3s ease, opacity 0.3s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(100%);
  opacity: 0;
}

/* Desktop: scale and fade */
@media (min-width: 640px) {
  .slide-up-enter-from,
  .slide-up-leave-to {
    transform: translate(-50%, -50%) scale(0.95);
    opacity: 0;
  }
  
  .slide-up-enter-active,
  .slide-up-leave-active {
    transition: transform 0.2s ease, opacity 0.2s ease;
  }
}

textarea {
  max-height: 120px;
  overflow-y: auto;
}

.messages-container {
  scrollbar-width: thin;
  scrollbar-color: #d1d5db transparent;
}

.messages-container::-webkit-scrollbar {
  width: 6px;
}

.messages-container::-webkit-scrollbar-track {
  background: transparent;
}

.messages-container::-webkit-scrollbar-thumb {
  background-color: #d1d5db;
  border-radius: 3px;
}
</style>
