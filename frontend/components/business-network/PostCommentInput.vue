<template>
  <div class="flex items-center gap-2 mt-3 pt-2 border-t border-gray-100 px-2">
    <img
      :src="user?.user?.image"
      alt="Your avatar"
      class="size-9 rounded-full"
    />
    <!-- Update the comment input -->
    <div class="flex-1 relative">
      <input
        type="text"
        placeholder="Add a comment..."
        class="w-full text-sm py-1.5 pr-10 pl-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600 transition-all"
        v-model="post.commentText"
        @keyup.enter="$emit('add-comment', post)"
        @focus="post.showCommentInput = true"
        @input="handleInput($event, post)"
        @keydown="handleMentionKeydown($event, post)"
      />
      <div
        v-if="post.commentText"
        class="absolute right-2 top-1/2 -translate-y-1/2 flex items-center space-x-1"
      >
        <button
          class="p-1 text-gray-400 hover:text-gray-500 transition-colors"
          @click="post.commentText = ''"
          aria-label="Clear comment"
        >
          <UIcon name="i-heroicons-x-mark" class="h-4 w-4" />
        </button>
        <button
          class="p-1 text-blue-600 hover:text-blue-700 transition-colors"
          @click="$emit('add-comment', post)"
          aria-label="Post comment"
        >
          <Send class="h-4 w-4" />
        </button>
      </div>

      <!-- Mention suggestions dropdown from database users -->
      <div
        v-if="showLocalMentions && dbMentionSuggestions.length > 0"
        class="absolute left-0 bottom-full mb-1 w-64 bg-white rounded-lg shadow-lg border border-gray-200 z-20 max-h-48 overflow-y-auto"
      >
        <div v-if="isLoadingMentions" class="p-3 text-center">
          <UIcon name="i-heroicons-arrow-path" class="animate-spin h-4 w-4 inline-block" />
          <span class="text-sm text-gray-500 ml-2">Loading users...</span>
        </div>
        <div v-else class="py-1">
          <div
            v-for="(user, index) in dbMentionSuggestions"
            :key="user.id"
            @click="selectMention(user, post)"
            :class="[
              'flex items-center px-3 py-2 cursor-pointer hover:bg-gray-100',
              index === localActiveMentionIndex ? 'bg-gray-100' : '',
            ]"
          >
            <img
              :src="user.image || user.avatar || '/avatar.png'"
              :alt="user.name || user.fullname"
              class="w-7 h-7 rounded-full mr-2"
            />
            <div class="flex flex-col">
              <span class="text-sm font-medium">{{ user.name || user.fullname }}</span>
              <span class="text-xs text-gray-500 truncate" v-if="user.username">@{{ user.username }}</span>
            </div>
            <!-- Verified badge if applicable -->
            <UIcon 
              v-if="user.kyc" 
              name="i-mdi-check-decagram" 
              class="ml-auto text-blue-500 w-3.5 h-3.5" 
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Send } from "lucide-vue-next";
import { ref, watch } from 'vue';
import { useDebounceFn } from '@vueuse/core';

const emit = defineEmits([
  "add-comment",
  "handle-comment-input",
  "handle-mention-keydown",
  "select-mention",
]);

const props = defineProps({
  post: {
    type: Object,
    required: true,
  },
  user: {
    type: Object,
    required: true,
  },
  showMentions: {
    type: Boolean,
    default: false,
  },
  mentionSuggestions: {
    type: Array,
    default: () => [],
  },
  activeMentionIndex: {
    type: Number,
    default: 0,
  },
  mentionInputPosition: {
    type: Object,
    default: null,
  },
});

// Local state for mention suggestions
const showLocalMentions = ref(false);
const dbMentionSuggestions = ref([]);
const localActiveMentionIndex = ref(0);
const currentMentionQuery = ref('');
const isLoadingMentions = ref(false);
const { get } = useApi();

// Debounced function to search for users
const searchUsers = useDebounceFn(async (query) => {
  if (!query || query.length < 1) {
    dbMentionSuggestions.value = [];
    showLocalMentions.value = false;
    return;
  }
  
  isLoadingMentions.value = true;
  
  try {
    // Call your API to search for users
    const response = await get(`/persons/search/?search=${encodeURIComponent(query)}`);
    
    if (response && response.data) {
      // Depending on your API response format
      dbMentionSuggestions.value = Array.isArray(response.data) 
        ? response.data 
        : (response.data.results || []);
    }
    
    // Show dropdown if we have suggestions
    showLocalMentions.value = dbMentionSuggestions.value.length > 0;
  } catch (error) {
    console.error('Error fetching user mentions:', error);
    dbMentionSuggestions.value = [];
  } finally {
    isLoadingMentions.value = false;
  }
}, 300);

// Parse input for mentions
function handleInput(event, post) {
  emit('handle-comment-input', event, post);
  
  const text = post.commentText || '';
  const mentionMatch = text.match(/@(\w*)$/);
  
  if (mentionMatch) {
    const query = mentionMatch[1];
    currentMentionQuery.value = query;
    searchUsers(query);
  } else {
    showLocalMentions.value = false;
  }
}

// Handle keyboard navigation in mention dropdown
function handleMentionKeydown(event, post) {
  emit('handle-mention-keydown', event, post);
  
  if (!showLocalMentions.value) return;
  
  if (event.key === 'ArrowDown') {
    event.preventDefault();
    localActiveMentionIndex.value = (localActiveMentionIndex.value + 1) % dbMentionSuggestions.value.length;
  } else if (event.key === 'ArrowUp') {
    event.preventDefault();
    localActiveMentionIndex.value = (localActiveMentionIndex.value - 1 + dbMentionSuggestions.value.length) % dbMentionSuggestions.value.length;
  } else if (event.key === 'Enter' && showLocalMentions.value) {
    event.preventDefault();
    selectMention(dbMentionSuggestions.value[localActiveMentionIndex.value], post);
  } else if (event.key === 'Escape') {
    showLocalMentions.value = false;
  }
}

// Select a mention from the dropdown
function selectMention(user, post) {
  const text = post.commentText || '';
  const mentionRegex = /@(\w*)$/;
  const updatedText = text.replace(mentionRegex, `@${user.username || user.name} `);
  
  post.commentText = updatedText;
  showLocalMentions.value = false;
  emit('select-mention', user, post);
}

// Close mentions dropdown when clicking outside
onClickOutside(document.body, () => {
  showLocalMentions.value = false;
});

// Reset active index when suggestions change
watch(dbMentionSuggestions, () => {
  localActiveMentionIndex.value = 0;
});
</script>
