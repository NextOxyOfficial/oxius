<template>
    <div class="flex h-screen bg-gray-100 dark:bg-gray-900 overflow-hidden" :class="{ 'floating-mode': isFloating }">
      <!-- Sidebar Component -->
      <BusinessNetworkChatSidebar 
        :friends="friends"
        :groups="groups"
        :searchQuery="searchQuery"
        :activeChat="activeChat"
        :isSearching="isSearching"
        :isLoadingMore="isLoadingMore"
        :isSidebarOpen="isSidebarOpen"
        @toggle-sidebar="isSidebarOpen = !isSidebarOpen"
        @select-conversation="selectConversation"
        @search="handleSearch"
        @update-search-query="searchQuery = $event"
        @start-adsyai-chat="startAdsyAiChat"
        @show-new-conversation="showNewConversationModal = true"
        @show-create-group="showCreateGroupModal = true"
      />
  
      <!-- Main chat area -->
      <div class="flex-1 flex flex-col bg-white dark:bg-gray-800 transition-all duration-300 ease-in-out">
        <!-- Chat header -->
        <div class="p-4 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center">
          <div class="flex items-center">
            <!-- Mobile menu button (inside header) -->
            <button 
              @click="isSidebarOpen = !isSidebarOpen" 
              class="md:hidden mr-2 p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-500 dark:text-gray-400"
            >
              <menu-icon class="w-5 h-5" />
            </button>
  
            <div class="relative">
              <!-- Group avatar for group chats -->
              <div v-if="activeChat.isGroup" class="w-10 h-10 rounded-full bg-gray-200 dark:bg-gray-700 relative">
                <div class="absolute top-0 left-0 w-6 h-6 rounded-full overflow-hidden border-2 border-white dark:border-gray-800">
                  <img 
                    :src="activeChat.members && activeChat.members[0] ? activeChat.members[0].avatar : 'https://randomuser.me/api/portraits/men/32.jpg'" 
                    class="w-full h-full object-cover"
                    alt="Member"
                  />
                </div>
                <div class="absolute bottom-0 right-0 w-6 h-6 rounded-full overflow-hidden border-2 border-white dark:border-gray-800">
                  <img 
                    :src="activeChat.members && activeChat.members[1] ? activeChat.members[1].avatar : 'https://randomuser.me/api/portraits/women/44.jpg'" 
                    class="w-full h-full object-cover"
                    alt="Member"
                  />
                </div>
                <div v-if="activeChat.members && activeChat.members.length > 2" class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-5 h-5 rounded-full bg-primary-500 flex items-center justify-center text-white text-xs font-medium">
                  +{{ activeChat.members.length - 2 }}
                </div>
              </div>
              
              <!-- Regular avatar for direct chats -->
              <img 
                v-else
                :src="activeChat.avatar" 
                :alt="activeChat.name" 
                class="w-10 h-10 rounded-full object-cover"
              />
              <div 
                v-if="!activeChat.isGroup"
                :class="[
                  'absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white dark:border-gray-800',
                  activeChat.online ? 'bg-green-500' : 'bg-gray-300 dark:bg-gray-500'
                ]"
              ></div>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-semibold text-gray-900 dark:text-white flex items-center">
                {{ activeChat.name }}
                <span v-if="activeChat.isGroup" class="ml-2 text-xs text-gray-500 dark:text-gray-400">
                  {{ activeChat.members ? activeChat.members.length : 0 }} members
                </span>
              </h3>
              <p v-if="!activeChat.isGroup" class="text-xs text-gray-500 dark:text-gray-400">
                {{ activeChat.online ? 'Online' : 'Last seen ' + activeChat.lastSeen }}
              </p>
              <p v-else class="text-xs text-gray-500 dark:text-gray-400">
                Created {{ formatGroupCreationDate(activeChat.createdAt) }}
              </p>
            </div>
          </div>
          <div class="flex space-x-2">
            <button 
              v-if="!activeChat.isGroup"
              @click="startAudioCall" 
              class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition"
            >
              <phone-icon class="w-5 h-5" />
            </button>
            <button 
              v-if="!activeChat.isGroup"
              @click="startVideoCall" 
              class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition"
            >
              <video-icon class="w-5 h-5" />
            </button>
            <button 
              v-if="activeChat.isGroup"
              @click="showGroupInfo = true" 
              class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition"
            >
              <users-icon class="w-5 h-5" />
            </button>
            <button 
              @click="showUserActions = !showUserActions" 
              class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition relative"
            >
              <more-horizontal-icon class="w-5 h-5" />
              
              <!-- User actions dropdown -->
              <div 
                v-if="showUserActions" 
                class="absolute right-0 top-full mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-10"
              >
                <div class="py-1">
                  <button 
                    v-if="!activeChat.isGroup"
                    @click="viewProfile"
                    class="w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    View Profile
                  </button>
                  <button 
                    @click="showMediaGallery = true"
                    class="w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    Media Gallery
                  </button>
                  <button 
                    v-if="activeChat.isGroup && isGroupAdmin"
                    @click="showEditGroupModal = true"
                    class="w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    Edit Group
                  </button>
                  <button 
                    v-if="activeChat.isGroup && isGroupAdmin"
                    @click="showAddMembersModal = true"
                    class="w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    Add Members
                  </button>
                  <button 
                    v-if="activeChat.isGroup"
                    @click="leaveGroup"
                    class="w-full text-left px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    Leave Group
                  </button>
                  <button 
                    v-if="!activeChat.isGroup"
                    @click="toggleBlockUser"
                    class="w-full text-left px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    {{ isUserBlocked ? 'Unblock User' : 'Block User' }}
                  </button>
                </div>
              </div>
            </button>
          </div>
        </div>
  
        <!-- Messages Component -->
        <BusinessNetworkChatMessages
          :messages="displayedMessages"
          :isTyping="isTyping"
          :activeChat="activeChat"
          :isAdsyAiChat="isAdsyAiChat"
          :showNewMessagesDivider="showNewMessagesDivider"
          :hasMoreMessages="hasMoreMessages"
          :loadingMoreMessages="loadingMoreMessages"
          @load-more="loadMoreMessages"
          @select-message="selectMessage"
        />
  
        <!-- Input Component -->
        <BusinessNetworkChatInput
          v-model="newMessage"
          :isUserBlocked="isUserBlocked"
          :mediaPreview="mediaPreview"
          :mediaPreviewType="mediaPreviewType"
          :mediaFileName="mediaFileName"
          :mediaFileSize="mediaFileSize"
          :isUploading="isUploading"
          :uploadProgress="uploadProgress"
          :isRecordingVoice="isRecordingVoice"
          :voiceRecordingDuration="voiceRecordingDuration"
          :mentionSuggestions="mentionSuggestions"
          :showMentionSuggestions="showMentionSuggestions"
          :selectedMentionId="selectedMentionId"
          :textareaHeight="textareaHeight"
          @send-message="sendMessage"
          @handle-input="handleInput"
          @handle-keydown="handleKeyDown"
          @select-mention="selectMentionSuggestion"
          @toggle-emoji-picker="toggleEmojiPicker"
          @add-emoji="addEmoji"
          @start-voice-recording="startVoiceRecording"
          @stop-voice-recording="stopVoiceRecording"
          @cancel-voice-recording="cancelVoiceRecording"
          @handle-file-upload="handleFileUpload"
          @handle-image-upload="handleImageUpload"
          @cancel-media-upload="cancelMediaUpload"
        />
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref, computed, onMounted, nextTick, watch, onUnmounted } from 'vue';
  
  import { 
    Menu as MenuIcon,
    Phone as PhoneIcon,
    Video as VideoIcon,
    Users as UsersIcon,
    MoreHorizontal as MoreHorizontalIcon,
    X as XIcon
  } from 'lucide-vue-next';
import { BusinessNetworkChatSidebar } from '#components';
  
  // Current user ID (for demo purposes)
  const currentUserId = 0;
  
  // State
  const newMessage = ref('');
  const activeChat = ref({
    id: 1,
    name: 'Sarah Thompson',
    avatar: 'https://randomuser.me/api/portraits/women/44.jpg',
    lastMessage: 'Perfect! Looking forward to our meeting tomorrow.',
    time: '2m ago',
    unread: 0,
    online: true,
    lastSeen: '2 hours ago',
    status: 'Product Designer'
  });
  const isEmojiPickerOpen = ref(false);
  const isTyping = ref(false);
  const messagesContainer = ref(null);
  const messageInput = ref(null);
  const textareaHeight = ref(40);
  const loadingMoreMessages = ref(false);
  const hasMoreMessages = ref(true);
  const showNewMessagesDivider = ref(false);
  const isSidebarOpen = ref(true);
  const searchQuery = ref('');
  const isSearching = ref(false);
  const isLoadingMore = ref(false);
  const showUserActions = ref(false);
  const isUserBlocked = ref(false);
  const showNewConversationModal = ref(false);
  const newConversationSearch = ref('');
  const isSearchingUsers = ref(false);
  const selectedUser = ref(null);
  const showMediaGallery = ref(false);
  const mediaGalleryTab = ref('images');
  const mediaViewerOpen = ref(false);
  const viewedMedia = ref(null);
  const isAdsyAiChat = ref(false);
  const mediaPreview = ref(null);
  const mediaPreviewType = ref(null);
  const mediaFileName = ref('');
  const mediaFileSize = ref('');
  const isUploading = ref(false);
  const uploadProgress = ref(0);
  const showCreateGroupModal = ref(false);
  
  // Group chat state
  const showGroupInfo = ref(false);
  const showAddMembersModal = ref(false);
  const showEditGroupModal = ref(false);
  
  // Mention state
  const showMentionSuggestions = ref(false);
  const mentionSuggestions = ref([]);
  const selectedMentionId = ref(null);
  
  // Voice recording state
  const isRecordingVoice = ref(false);
  const voiceRecordingDuration = ref(0);
  
  // Sample friends data
  const friends = ref([
    {
      id: 1,
      name: 'Sarah Thompson',
      avatar: 'https://randomuser.me/api/portraits/women/44.jpg',
      lastMessage: 'Perfect! Looking forward to our meeting tomorrow.',
      time: '2m ago',
      unread: 0,
      online: true,
      lastSeen: '2 hours ago',
      status: 'Product Designer'
    },
    {
      id: 2,
      name: 'Michael Chen',
      avatar: 'https://randomuser.me/api/portraits/men/41.jpg',
      lastMessage: 'Could you send me those design files we discussed?',
      time: '25m ago',
      unread: 3,
      online: false,
      lastSeen: '5 hours ago',
      status: 'Frontend Developer'
    },
    // More friends...
  ]);
  
  // Sample groups data
  const groups = ref([
    {
      id: 'group-1',
      name: 'Design Team',
      isGroup: true,
      lastMessage: 'David: The latest mockups look great!',
      time: 'Yesterday',
      unread: 0,
      createdBy: 'Sarah Thompson',
      createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      description: 'Group for design discussions and feedback',
      members: [
        {
          id: 0,
          name: 'Alex Johnson',
          avatar: 'https://randomuser.me/api/portraits/men/32.jpg',
          online: true,
          status: 'You',
          isAdmin: true
        },
        // More members...
      ]
    },
    // More groups...
  ]);
  
  // Sample messages
  const messages = ref([
    {
      id: 1,
      sender: 'other',
      senderId: 1,
      content: 'Hi Alex! Hope you\'re doing well. Do you have time to catch up on the project today?',
      type: 'text',
      timestamp: new Date(Date.now() - 60 * 60 * 1000),
      status: 'read'
    },
    // More messages...
  ]);
  
  // Computed properties
  const displayedMessages = computed(() => {
    if (!activeChat.value) return [];
    return messages.value.filter(message => message.senderId === activeChat.value.id || message.senderId === currentUserId);
  });
  
  const isGroupChat = computed(() => {
    return activeChat.value && activeChat.value.isGroup;
  });
  
  const isGroupAdmin = computed(() => {
    if (!activeChat.value || !activeChat.value.members) return false;
    const member = activeChat.value.members.find(m => m.id === currentUserId);
    return member ? member.isAdmin : false;
  });
  
  // Methods
  const handleSearch = () => {
    isSearching.value = true;
    setTimeout(() => {
      isSearching.value = false;
    }, 500);
  };
  
  const selectConversation = (id) => {
    const foundFriend = friends.value.find(f => f.id === id);
    const foundGroup = groups.value.find(g => g.id === id);
    
    if (foundFriend) {
      activeChat.value = foundFriend;
      isAdsyAiChat.value = false;
    } else if (foundGroup) {
      activeChat.value = foundGroup;
      isAdsyAiChat.value = false;
    }
    
    isSidebarOpen.value = false;
    showUserActions.value = false;
  };
  
  const startAdsyAiChat = () => {
    isAdsyAiChat.value = true;
    activeChat.value = {
      id: 'adsyai',
      name: 'AdsyAi Assistant',
      avatar: 'https://randomuser.me/api/portraits/lego/1.jpg',
      online: true,
      lastSeen: 'Always online'
    };
    messages.value = [];
    isSidebarOpen.value = false;
  };
  
  const formatGroupCreationDate = (date) => {
    if (!date) return '';
    return new Date(date).toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    });
  };
  
  const sendMessage = () => {
    if (!newMessage.value.trim()) return;
    
    const newMsg = {
      id: messages.value.length + 1,
      sender: 'me',
      senderId: currentUserId,
      content: newMessage.value,
      type: 'text',
      timestamp: new Date(),
      status: 'sent',
      isNew: true
    };
    
    messages.value.push(newMsg);
    newMessage.value = '';
    
    // Simulate reply
    if (!isAdsyAiChat.value && !isUserBlocked.value) {
      isTyping.value = true;
      setTimeout(() => {
        isTyping.value = false;
        messages.value.push({
          id: messages.value.length + 1,
          sender: 'other',
          senderId: activeChat.value.id,
          content: 'Thanks for your message! I\'ll get back to you soon.',
          type: 'text',
          timestamp: new Date(),
          status: 'delivered'
        });
      }, 2000);
    }
  };
  
  const loadMoreMessages = () => {
    loadingMoreMessages.value = true;
    setTimeout(() => {
      loadingMoreMessages.value = false;
      hasMoreMessages.value = false;
    }, 1500);
  };
  
  const selectMessage = (message) => {
    // Handle message selection
  };
  
  const handleInput = (e) => {
    adjustTextareaHeight();
  };
  
  const handleKeyDown = (e) => {
    // Handle keydown events
  };
  
  const adjustTextareaHeight = () => {
    if (!messageInput.value) return;
    
    messageInput.value.style.height = 'auto';
    messageInput.value.style.height = `${messageInput.value.scrollHeight}px`;
    textareaHeight.value = messageInput.value.scrollHeight;
  };
  
  const toggleEmojiPicker = () => {
    isEmojiPickerOpen.value = !isEmojiPickerOpen.value;
  };
  
  const addEmoji = (emoji) => {
    newMessage.value += emoji;
    isEmojiPickerOpen.value = false;
  };
  
  const selectMentionSuggestion = (suggestion) => {
    // Handle mention suggestion selection
  };
  
  const startVoiceRecording = () => {
    isRecordingVoice.value = true;
    voiceRecordingDuration.value = 0;
  };
  
  const stopVoiceRecording = () => {
    isRecordingVoice.value = false;
  };
  
  const cancelVoiceRecording = () => {
    isRecordingVoice.value = false;
  };
  
  const handleFileUpload = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    mediaFileName.value = file.name;
    mediaFileSize.value = formatFileSize(file.size);
    mediaPreviewType.value = 'file';
    mediaPreview.value = URL.createObjectURL(file);
    
    simulateUpload();
  };
  
  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    mediaFileName.value = file.name;
    mediaFileSize.value = formatFileSize(file.size);
    mediaPreviewType.value = 'image';
    mediaPreview.value = URL.createObjectURL(file);
    
    simulateUpload();
  };
  
  const simulateUpload = () => {
    isUploading.value = true;
    uploadProgress.value = 0;
    
    const interval = setInterval(() => {
      uploadProgress.value += 10;
      if (uploadProgress.value >= 100) {
        clearInterval(interval);
        isUploading.value = false;
      }
    }, 300);
  };
  
  const cancelMediaUpload = () => {
    mediaPreview.value = null;
    mediaPreviewType.value = null;
    mediaFileName.value = '';
    mediaFileSize.value = '';
    isUploading.value = false;
  };
  
  const formatFileSize = (bytes) => {
    if (bytes < 1024) return bytes + ' B';
    else if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
    else if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + ' MB';
    else return (bytes / 1073741824).toFixed(1) + ' GB';
  };
  
  const viewProfile = () => {
    // View user profile
  };
  
  const toggleBlockUser = () => {
    isUserBlocked.value = !isUserBlocked.value;
    showUserActions.value = false;
  };
  
  const leaveGroup = () => {
    // Leave group implementation
  };
  
  const startAudioCall = () => {
    // Start audio call implementation
  };
  
  const startVideoCall = () => {
    // Start video call implementation
  };
  
  // Lifecycle hooks
  onMounted(() => {
    adjustTextareaHeight();
  });
  const props = defineProps({
  isFloating: {
    type: Boolean,
    default: false
  }
});

// Rest of your script stays the same
  </script>
  
  <style>
  .bg-chat-pattern {
    background-color: rgba(240, 240, 240, 0.6);
    background-image: url('data:image/svg+xml;charset=utf-8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" opacity="0.2"><circle cx="12" cy="12" r="1.5" fill="%23999"/></svg>');
    background-size: 20px 20px;
  }
  
  .dark .bg-chat-pattern {
    background-color: rgba(30, 30, 30, 0.6);
    background-image: url('data:image/svg+xml;charset=utf-8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" opacity="0.1"><circle cx="12" cy="12" r="1.5" fill="%23777"/></svg>');
  }
  
  .typing-indicator {
    display: flex;
    align-items: center;
  }
  
  .typing-indicator span {
    height: 8px;
    width: 8px;
    margin: 0 1px;
    background-color: #606060;
    border-radius: 50%;
    display: inline-block;
    animation: typing 1s infinite ease-in-out;
  }
  
  .dark .typing-indicator span {
    background-color: #a0a0a0;
  }
  
  .typing-indicator span:nth-child(1) {
    animation-delay: 0s;
  }
  
  .typing-indicator span:nth-child(2) {
    animation-delay: 0.2s;
  }
  
  .typing-indicator span:nth-child(3) {
    animation-delay: 0.4s;
  }
  
  @keyframes typing {
    0% {
      transform: translateY(0);
    }
    50% {
      transform: translateY(-5px);
    }
    100% {
      transform: translateY(0);
    }
  }
  /* Add these styles at the end of your existing styles */

/* When used in floating mode */
.floating-mode {
  height: 100%;
  max-height: 100%;
  overflow: hidden;
}

.floating-mode .chat-messages-container {
  max-height: calc(100% - 120px);
}

/* Make responsive adjustments */
@media (max-width: 640px) {
  .floating-mode {
    border-radius: 12px 12px 0 0;
    max-height: 80vh;
    height: 80vh;
  }
}
  </style>