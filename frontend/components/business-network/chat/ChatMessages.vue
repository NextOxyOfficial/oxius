<template>
  <div 
    ref="messagesContainer" 
    class="flex-1 p-4 overflow-y-auto"
    :class="{ 'bg-chat-pattern': true }"
  >
    <!-- AdsyAi welcome message -->
    <div v-if="isAdsyAiChat" class="mb-8 max-w-md mx-auto bg-white dark:bg-gray-800 rounded-xl shadow-md p-4 border border-gray-200 dark:border-gray-700">
      <div class="flex items-center mb-3">
        <div class="w-10 h-10 rounded-full bg-gradient-to-r from-purple-500 to-indigo-600 flex items-center justify-center text-white">
          <bot-icon class="w-6 h-6" />
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-semibold text-gray-900 dark:text-white">AdsyAi Assistant</h3>
          <p class="text-xs text-green-500">Always ready to help</p>
        </div>
      </div>
      <p class="text-sm text-gray-700 dark:text-gray-300">
        👋 Hi there! I'm AdsyAi, your personal assistant. I can help you with:
      </p>
      <ul class="mt-2 space-y-1 text-sm text-gray-700 dark:text-gray-300">
        <li class="flex items-center">
          <book-open-icon class="w-4 h-4 mr-2 text-primary-500" />
          <span>Study resources and academic questions</span>
        </li>
        <li class="flex items-center">
          <briefcase-icon class="w-4 h-4 mr-2 text-primary-500" />
          <span>Business advice and professional development</span>
        </li>
        <li class="flex items-center">
          <help-circle-icon class="w-4 h-4 mr-2 text-primary-500" />
          <span>General information and everyday questions</span>
        </li>
      </ul>
      <p class="mt-3 text-sm text-gray-700 dark:text-gray-300">
        How can I assist you today? Just type your question below!
      </p>
    </div>

    <!-- Group welcome message -->
    <div v-else-if="activeChat.isGroup && messages.length === 0" class="mb-8 max-w-md mx-auto bg-white dark:bg-gray-800 rounded-xl shadow-md p-4 border border-gray-200 dark:border-gray-700">
      <div class="flex items-center mb-3">
        <div class="w-10 h-10 rounded-full bg-gray-200 dark:bg-gray-700 relative">
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
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-semibold text-gray-900 dark:text-white">{{ activeChat.name }}</h3>
          <p class="text-xs text-gray-500 dark:text-gray-400">{{ activeChat.members ? activeChat.members.length : 0 }} members</p>
        </div>
      </div>
      <p class="text-sm text-gray-700 dark:text-gray-300">
        👋 Welcome to the group! You can:
      </p>
      <ul class="mt-2 space-y-1 text-sm text-gray-700 dark:text-gray-300">
        <li class="flex items-center">
          <at-sign-icon class="w-4 h-4 mr-2 text-primary-500" />
          <span>Mention members using @username</span>
        </li>
        <li class="flex items-center">
          <image-icon class="w-4 h-4 mr-2 text-primary-500" />
          <span>Share photos, files, and voice messages</span>
        </li>
        <li class="flex items-center">
          <users-icon class="w-4 h-4 mr-2 text-primary-500" />
          <span>View group info and members</span>
        </li>
      </ul>
      <p class="mt-3 text-sm text-gray-700 dark:text-gray-300">
        Start chatting with the group below!
      </p>
    </div>

    <!-- New messages divider -->
    <div v-if="showNewMessagesDivider" class="flex justify-center my-4">
      <div class="bg-primary-100 dark:bg-primary-900 text-primary-600 dark:text-primary-200 text-xs px-3 py-1 rounded-full">
        New messages
      </div>
    </div>

    <!-- Date separator -->
    <div class="flex justify-center my-4">
      <div class="text-xs text-gray-500 dark:text-gray-400 px-3 py-1 bg-gray-100 dark:bg-gray-700 rounded-full">
        Today
      </div>
    </div>

    <!-- Load more messages -->
    <div v-if="hasMoreMessages" class="flex justify-center my-2">
      <button 
        @click="$emit('load-more')" 
        :disabled="loadingMoreMessages" 
        class="text-xs text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 transition"
      >
        <div v-if="loadingMoreMessages" class="flex items-center">
          <loader-icon class="w-3 h-3 mr-1 animate-spin" />
          Loading...
        </div>
        <span v-else>Load previous messages</span>
      </button>
    </div>

    <!-- Messages -->
    <div 
      v-for="(message, index) in messages" 
      :key="message.id"
      :class="[
        'mb-4 max-w-[75%]',
        message.sender === 'me' ? 'ml-auto' : ''
      ]"
    >
      <!-- Time break -->
      <div 
        v-if="shouldShowTimeSeparator(message, index)"
        class="flex justify-center w-full my-2"
      >
        <div class="text-xs text-gray-500 dark:text-gray-400">
          {{ formatMessageTime(message.timestamp) }}
        </div>
      </div>

      <div 
        :class="[
          'flex', 
          message.sender === 'me' ? 'justify-end' : 'justify-start'
        ]"
      >
        <!-- Show avatar for group chats or direct messages from others -->
        <div 
          v-if="message.sender !== 'me' && (!messages[index - 1] || messages[index - 1].sender !== message.sender)"
          class="mr-2 self-end mb-1"
        >
          <img 
            :src="getSenderAvatar(message)" 
            class="w-8 h-8 rounded-full object-cover" 
            :alt="getSenderName(message)"
          />
        </div>
        <div 
          :class="[
            'rounded-3xl py-2 px-4 shadow-sm break-words',
            message.sender === 'me' 
              ? 'bg-primary-500 text-white message-sent' 
              : 'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200 message-received',
            message.sender === 'me' && message.isNew ? 'animate-pop-in' : ''
          ]"
        >
          <!-- Sender name in group chat -->
          <div 
            v-if="activeChat.isGroup && message.sender !== 'me' && (!messages[index - 1] || messages[index - 1].sender !== message.sender)" 
            class="text-xs font-medium mb-1"
            :class="message.sender === 'me' ? 'text-white/80' : 'text-primary-500 dark:text-primary-400'"
          >
            {{ getSenderName(message) }}
          </div>

          <!-- Message content -->
          <div v-if="message.type === 'text'" v-html="formatMessageWithMentions(message.content)"></div>

          <!-- Image message -->
          <div v-else-if="message.type === 'image'" class="rounded-2xl overflow-hidden">
            <img 
              :src="message.content" 
              class="max-w-[240px] max-h-[240px] object-cover rounded-2xl cursor-pointer hover:opacity-90 transition"
              alt="Shared image"
              @click="openMediaViewer(message)"
            />
          </div>

          <!-- File message -->
          <div v-else-if="message.type === 'file'" class="flex items-center bg-white dark:bg-gray-800 rounded-lg p-2">
            <file-icon class="w-8 h-8 text-primary-500" />
            <div class="ml-2">
              <p class="text-xs font-medium text-gray-900 dark:text-white">{{ message.fileName }}</p>
              <p class="text-xs text-gray-500 dark:text-gray-400">{{ message.fileSize }}</p>
            </div>
            <download-icon class="w-4 h-4 ml-2 text-gray-500 dark:text-gray-400 cursor-pointer hover:text-primary-500 dark:hover:text-primary-400 transition" />
          </div>

          <!-- Voice message -->
          <div v-else-if="message.type === 'voice'" class="flex items-center bg-white dark:bg-gray-800 rounded-lg p-2 w-full">
            <button 
              @click="playVoiceMessage(message)"
              class="w-8 h-8 rounded-full bg-primary-500 flex items-center justify-center text-white mr-2"
            >
              <play-icon class="w-4 h-4" />
            </button>
            <div class="flex-1">
              <div class="w-full h-2 bg-gray-200 dark:bg-gray-600 rounded-full overflow-hidden">
                <div 
                  class="h-full bg-primary-500 rounded-full"
                  :style="{ width: '0%' }"
                ></div>
              </div>
              <div class="flex justify-between mt-1">
                <span class="text-xs text-gray-500 dark:text-gray-400">{{ formatVoiceDuration(message.duration) }}</span>
                <span class="text-xs text-gray-500 dark:text-gray-400">Voice message</span>
              </div>
            </div>
          </div>

          <!-- Message metadata -->
          <div 
            :class="[
              'flex items-center justify-end mt-1 text-xs',
              message.sender === 'me' ? 'text-white/80' : 'text-gray-500 dark:text-gray-400'
            ]"
          >
            <span>{{ formatMessageTime(message.timestamp) }}</span>
            <div v-if="message.sender === 'me'" class="ml-1">
              <check-icon v-if="message.status === 'sent'" class="w-3 h-3" />
              <check-circle-icon v-if="message.status === 'delivered'" class="w-3 h-3" />
              <div v-if="message.status === 'read'" class="flex text-primary-300">
                <check-circle-icon class="w-3 h-3" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Typing indicator -->
    <div v-if="isTyping" class="flex items-end mb-4 max-w-[75%]">
      <img 
        :src="activeChat.avatar" 
        class="w-8 h-8 rounded-full object-cover mr-2 mb-1" 
        :alt="activeChat.name"
      />
      <div class="bg-gray-100 dark:bg-gray-700 rounded-3xl py-3 px-4">
        <div class="typing-indicator">
          <span></span>
          <span></span>
          <span></span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, watch } from 'vue';
import { 
  BookOpen as BookOpenIcon,
  Briefcase as BriefcaseIcon,
  HelpCircle as HelpCircleIcon,
  AtSign as AtSignIcon,
  Image as ImageIcon,
  Users as UsersIcon,
  Bot as BotIcon,
  Loader as LoaderIcon,
  Check as CheckIcon,
  CheckCircle as CheckCircleIcon,
  File as FileIcon,
  Download as DownloadIcon,
  Play as PlayIcon
} from 'lucide-vue-next';

const props = defineProps({
  messages: {
    type: Array,
    required: true
  },
  isTyping: {
    type: Boolean,
    default: false
  },
  activeChat: {
    type: Object,
    required: true
  },
  isAdsyAiChat: {
    type: Boolean,
    default: false
  },
  showNewMessagesDivider: {
    type: Boolean,
    default: false
  },
  hasMoreMessages: {
    type: Boolean,
    default: true
  },
  loadingMoreMessages: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['load-more', 'select-message']);

const messagesContainer = ref(null);

// Methods
const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
};

const shouldShowTimeSeparator = (message, index) => {
  if (index === 0) return false;
  
  const prevMessage = props.messages[index - 1];
  const currentTime = new Date(message.timestamp);
  const prevTime = new Date(prevMessage.timestamp);
  
  return currentTime - prevTime > 10 * 60 * 1000; // 10 minutes
};

const formatMessageTime = (timestamp) => {
  if (!timestamp) return '';
  
  const date = new Date(timestamp);
  return date.toLocaleTimeString('en-US', { 
    hour: '2-digit', 
    minute: '2-digit' 
  });
};

const formatVoiceDuration = (seconds) => {
  if (!seconds) return '0:00';
  
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const getSenderAvatar = (message) => {
  if (props.activeChat.isGroup && message.sender !== 'me') {
    const sender = props.activeChat.members?.find(m => m.id === message.senderId);
    return sender?.avatar || 'https://randomuser.me/api/portraits/lego/1.jpg';
  }
  
  return props.activeChat.avatar || 'https://randomuser.me/api/portraits/lego/1.jpg';
};

const getSenderName = (message) => {
  if (message.sender === 'me') return 'You';
  
  if (props.activeChat.isGroup) {
    const sender = props.activeChat.members?.find(m => m.id === message.senderId);
    return sender?.name || 'Unknown User';
  }
  
  return props.activeChat.name || 'Unknown User';
};

const formatMessageWithMentions = (content) => {
  if (!content) return '';
  
  // Replace @mentions with styled spans
  return content.replace(/@(\w+)/g, '<span class="text-primary-500 dark:text-primary-400 font-medium">@$1</span>');
};

const openMediaViewer = (message) => {
  emit('select-message', message);
};

const playVoiceMessage = (message) => {
  // Voice message playback logic would go here
  console.log('Playing voice message:', message.id);
};

// Lifecycle hooks
onMounted(() => {
  scrollToBottom();
});

watch(() => props.messages.length, () => {
  nextTick(() => {
    scrollToBottom();
  });
});

watch(() => props.isTyping, (newVal) => {
  if (newVal) {
    nextTick(() => {
      scrollToBottom();
    });
  }
});
</script>

<style scoped>
.animate-pop-in {
  animation: pop-in 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

@keyframes pop-in {
  0% {
    opacity: 0;
    transform: scale(0.8);
  }
  100% {
    opacity: 1;
    transform: scale(1);
  }
}
</style>