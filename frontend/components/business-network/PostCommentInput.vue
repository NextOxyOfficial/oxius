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
        @input="$emit('handle-comment-input', $event, post)"
        @keydown="$emit('handle-mention-keydown', $event, post)"
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

      <!-- Mention suggestions dropdown -->
      <div
        v-if="
          showMentions &&
          mentionSuggestions.length > 0 &&
          post === mentionInputPosition?.post
        "
        class="absolute left-0 bottom-full mb-1 w-64 bg-white rounded-lg shadow-lg border border-gray-200 z-20 max-h-48 overflow-y-auto"
      >
        <div class="py-1">
          <div
            v-for="(user, index) in mentionSuggestions"
            :key="user.id"
            @click="$emit('select-mention', user, post)"
            :class="[
              'flex items-center px-3 py-2 cursor-pointer hover:bg-gray-100',
              index === activeMentionIndex ? 'bg-gray-100' : '',
            ]"
          >
            <img
              :src="user.image"
              :alt="user.name"
              class="w-7 h-7 rounded-full mr-2"
            />
            <span class="text-sm font-medium">{{ user.name }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Send } from "lucide-vue-next";

defineProps({
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

defineEmits([
  "add-comment",
  "handle-comment-input",
  "handle-mention-keydown",
  "select-mention",
]);
</script>
