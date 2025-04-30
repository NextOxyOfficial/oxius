<template>
  <div class="p-4 border-t border-gray-200 dark:border-gray-700">
    <!-- Blocked user message -->
    <div v-if="isUserBlocked" class="text-center py-2 text-red-500 dark:text-red-400">
      You have blocked this user. Unblock to send messages.
    </div>
    
    <!-- Media preview -->
    <div v-if="mediaPreview" class="mb-3 p-2 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-between">
      <div class="flex items-center">
        <div class="w-12 h-12 rounded-lg bg-gray-200 dark:bg-gray-600 overflow-hidden flex items-center justify-center mr-3">
          <img v-if="mediaPreviewType === 'image'" :src="mediaPreview" class="w-full h-full object-cover" />
          <file-icon v-else-if="mediaPreviewType === 'file'" class="w-6 h-6 text-gray-500 dark:text-gray-400" />
          <mic-icon v-else-if="mediaPreviewType === 'voice'" class="w-6 h-6 text-primary-500" />
        </div>
        <div>
          <p class="text-sm font-medium text-gray-900 dark:text-white">
            {{ mediaPreviewType === 'voice' ? 'Voice Message' : mediaFileName }}
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            {{ mediaPreviewType === 'voice' ? formatVoiceDuration(voiceRecordingDuration) : mediaFileSize }}
          </p>
        </div>
      </div>
      <button @click="$emit('cancel-media-upload')" class="text-gray-500 hover:text-gray-700 dark:hover:text-gray-300">
        <x-icon class="w-5 h-5" />
      </button>
    </div>

    <!-- Voice recording indicator -->
    <div v-if="isRecordingVoice" class="mb-3 p-2 bg-red-50 dark:bg-red-900/20 rounded-lg">
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <div class="w-8 h-8 rounded-full bg-red-500 flex items-center justify-center text-white animate-pulse mr-3">
            <mic-icon class="w-5 h-5" />
          </div>
          <div>
            <p class="text-sm font-medium text-gray-900 dark:text-white">Recording voice message</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">{{ formatVoiceDuration(voiceRecordingDuration) }}</p>
          </div>
        </div>
        <div class="flex space-x-2">
          <button 
            @click="$emit('cancel-voice-recording')" 
            class="p-2 bg-gray-200 dark:bg-gray-700 rounded-full text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
          >
            <x-icon class="w-5 h-5" />
          </button>
          <button 
            @click="$emit('stop-voice-recording')" 
            class="p-2 bg-primary-500 rounded-full text-white hover:bg-primary-600"
          >
            <check-icon class="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>

    <!-- Upload progress -->
    <div v-if="isUploading" class="mb-3 p-2 bg-gray-100 dark:bg-gray-700 rounded-lg">
      <div class="flex justify-between items-center mb-1">
        <span class="text-sm text-gray-700 dark:text-gray-300">Uploading...</span>
        <span class="text-sm text-gray-700 dark:text-gray-300">{{ uploadProgress }}%</span>
      </div>
      <div class="w-full bg-gray-200 dark:bg-gray-600 rounded-full h-2">
        <div 
          class="bg-primary-500 h-2 rounded-full transition-all duration-300" 
          :style="{ width: `${uploadProgress}%` }"
        ></div>
      </div>
    </div>

    <div class="flex items-end flex-wrap" v-if="!isUserBlocked">
      <!-- Attachments -->
      <div class="flex space-x-2 mr-2">
        <label class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition cursor-pointer">
          <input 
            type="file" 
            class="hidden" 
            @change="$emit('handle-file-upload', $event)"
            accept="image/*,video/*,audio/*,.pdf,.doc,.docx,.xls,.xlsx,.txt"
          />
          <paperclip-icon class="w-5 h-5" />
        </label>
        <label class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition cursor-pointer">
          <input 
            type="file" 
            class="hidden" 
            @change="$emit('handle-image-upload', $event)"
            accept="image/*"
          />
          <image-icon class="w-5 h-5" />
        </label>
        <button 
          @click="$emit('start-voice-recording')" 
          :disabled="isRecordingVoice"
          class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition"
        >
          <mic-icon class="w-5 h-5" />
        </button>
      </div>

      <!-- Text input -->
      <div class="w-full relative max-sm:order-2">
        <textarea 
          :value="modelValue"
          @input="$emit('update:modelValue', $event.target.value)"
          @keydown.enter.prevent="$emit('send-message')"
          @keydown="$emit('handle-keydown', $event)"
          placeholder="Type a message..." 
          rows="1" 
          ref="messageInput"
          class="w-full py-3 px-4 bg-gray-100 dark:bg-gray-700 rounded-2xl text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none transition-all"
          :style="{ height: textareaHeight + 'px' }"
        ></textarea>
        
        <!-- Mention suggestions -->
        <div 
          v-if="showMentionSuggestions && mentionSuggestions.length > 0"
          class="absolute bottom-full left-0 mb-1 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 max-h-48 w-64 overflow-y-auto z-20"
        >
          <div 
            v-for="suggestion in mentionSuggestions" 
            :key="suggestion.id"
            @click="$emit('select-mention', suggestion)"
            class="flex items-center p-2 hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer"
            :class="{'bg-gray-50 dark:bg-gray-700': suggestion.id === selectedMentionId}"
          >
            <img 
              :src="suggestion.avatar" 
              :alt="suggestion.name" 
              class="w-6 h-6 rounded-full object-cover" 
            />
            <div class="ml-2">
              <div class="text-sm font-medium text-gray-900 dark:text-white">{{ suggestion.name }}</div>
              <div class="text-xs text-gray-500 dark:text-gray-400">{{ suggestion.status }}</div>
            </div>
          </div>
        </div>
        <!-- Send button -->
      <button 
        @click="$emit('send-message')" 
        :disabled="!canSendMessage"
        :class="[
          'absolute right-3 top-2 rounded-full transition-all',
          canSendMessage 
            ? 'text-white shadow-md hover:bg-primary-600 active:scale-95' 
            : 'text-gray-500 dark:text-gray-400 cursor-not-allowed'
        ]"
      >
        <send-icon class="w-5 h-5" />
      </button>
        <!-- Emoji button -->
        <div class="absolute bottom-3 right-10">
          <button 
            @click="$emit('toggle-emoji-picker')" 
            class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
          >
            <smile-icon class="w-5 h-5" />
          </button>
        </div>
      </div>

      
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { 
  Paperclip as PaperclipIcon,
  Image as ImageIcon,
  Mic as MicIcon,
  Smile as SmileIcon,
  Send as SendIcon,
  Check as CheckIcon,
  File as FileIcon,
  X as XIcon
} from 'lucide-vue-next';

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  isUserBlocked: {
    type: Boolean,
    default: false
  },
  mediaPreview: {
    type: String,
    default: null
  },
  mediaPreviewType: {
    type: String,
    default: null
  },
  mediaFileName: {
    type: String,
    default: ''
  },
  mediaFileSize: {
    type: String,
    default: ''
  },
  isUploading: {
    type: Boolean,
    default: false
  },
  uploadProgress: {
    type: Number,
    default: 0
  },
  isRecordingVoice: {
    type: Boolean,
    default: false
  },
  voiceRecordingDuration: {
    type: Number,
    default: 0
  },
  mentionSuggestions: {
    type: Array,
    default: () => []
  },
  showMentionSuggestions: {
    type: Boolean,
    default: false
  },
  selectedMentionId: {
    type: [Number, String],
    default: null
  },
  textareaHeight: {
    type: Number,
    default: 40
  }
});

const emit = defineEmits([
  'update:modelValue',
  'send-message',
  'handle-input',
  'handle-keydown',
  'select-mention',
  'toggle-emoji-picker',
  'add-emoji',
  'start-voice-recording',
  'stop-voice-recording',
  'cancel-voice-recording',
  'handle-file-upload',
  'handle-image-upload',
  'cancel-media-upload'
]);

const messageInput = ref(null);

const canSendMessage = computed(() => {
  return props.modelValue.trim() !== '';
});

const formatVoiceDuration = (seconds) => {
  if (!seconds) return '0:00';
  
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

onMounted(() => {
  if (messageInput.value) {
    messageInput.value.focus();
  }
});
</script>