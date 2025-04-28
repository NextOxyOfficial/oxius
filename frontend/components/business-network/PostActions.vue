<template>
  <div
    class="flex items-center justify-between pt-2 border-t border-gray-100 mb-3"
  >
    <div class="flex items-center space-x-4">
      <div class="flex items-center space-x-1">
        <!-- Update like button with loading state -->
        <button
          class="p-1 rounded-full hover:bg-gray-100 transition-colors disabled:opacity-50"
          @click="$emit('toggle-like', post)"
          :disabled="post.isLikeLoading"
        >
          <div
            v-if="post.isLikeLoading"
            class="animate-pulse h-4 w-4"
          >
            <Loader2 class="h-4 w-4 text-gray-400 animate-spin" />
          </div>
          <Heart
            v-else
            :class="[
              'h-4 w-4',
              post.post_likes?.find(
                (like) => like.user === user?.user?.id
              )
                ? 'text-red-500 fill-red-500'
                : 'text-gray-500',
            ]"
          />
        </button>
        <button
          class="text-sm text-gray-600 hover:underline"
          @click="$emit('open-likes-modal', post)"
        >
          {{ post?.post_likes?.length }} likes
        </button>
      </div>
      <button
        class="flex items-center space-x-1"
        @click="$emit('open-comments-modal', post)"
      >
        <MessageCircle class="h-4 w-4 text-gray-500" />
        <span class="text-sm text-gray-600"
          >{{ post?.post_comments?.length }} comments</span
        >
      </button>
      <button
        class="flex items-center space-x-1"
        @click="$emit('share-post', post)"
      >
        <Share2 class="h-4 w-4 text-gray-500" />
        <span class="text-sm text-gray-600">Share</span>
      </button>
      <button
        class="flex items-center space-x-1"
        @click="$emit('toggle-save', post)"
      >
        <Bookmark
          :class="[
            'h-4 w-4',
            post.isSaved
              ? 'text-blue-600 fill-blue-600'
              : 'text-gray-500',
          ]"
        />
        <span class="text-sm text-gray-600">Save</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { Heart, MessageCircle, Share2, Bookmark, Loader2 } from 'lucide-vue-next';

defineProps({
  post: {
    type: Object,
    required: true
  },
  user: {
    type: Object,
    default: null
  }
});

defineEmits(['toggle-like', 'open-likes-modal', 'open-comments-modal', 'share-post', 'toggle-save']);
</script>
