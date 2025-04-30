<template>
  <div
    class="flex items-center justify-center pt-3 pb-1 border-t border-gray-200 mb-4 max-w-2xl mx-auto"
  >
    <div class="flex items-center space-x-2 w-full justify-center">
      <div class="flex items-center space-x-1.5 group">
        <!-- Like button with enhanced styling and transitions -->
        <button
          class="p-1.5 rounded-full hover:bg-rose-50 transition-all duration-200 disabled:opacity-60 transform hover:scale-105"
          @click="$emit('toggle-like', post)"
          :disabled="post.isLikeLoading"
        >
          <div v-if="post.isLikeLoading" class="h-5 w-5">
            <Loader2 class="h-5 w-5 text-gray-400 animate-spin" />
          </div>
          <Heart
            v-else
            :class="[
              'h-5 w-5 transition-colors duration-300',
              post.post_likes?.find((like) => like.user === user?.user?.id)
                ? 'text-red-500 fill-red-500 animate-heartbeat'
                : 'text-rose-400 group-hover:text-red-500',
            ]"
          />
        </button>
        <button
          class="text-sm text-gray-700 hover:text-gray-900 transition-colors duration-200"
          @click="$emit('open-likes-modal', post)"
        >
          {{ post?.post_likes?.length }} Likes
        </button>
      </div>

      <button
        class="flex items-center space-x-1.5 group sm:px-2 py-1 rounded-lg hover:bg-blue-50 transition-all duration-200 transform hover:scale-102"
        @click="$emit('open-comments-modal', post)"
      >
        <MessageCircle
          class="h-5 w-5 text-blue-400 group-hover:text-blue-500 transition-colors duration-200"
        />
        <span
          class="text-sm text-gray-700 group-hover:text-gray-900 transition-colors duration-200"
        >
          {{ post?.post_comments?.length }} Comments
        </span>
      </button>

      <button
        class="flex items-center space-x-1.5 group sm:px-2 py-1 rounded-lg hover:bg-green-50 transition-all duration-200 transform hover:scale-102"
        @click="$emit('share-post', post)"
      >
        <Share2
          class="h-5 w-5 text-emerald-400 group-hover:text-green-500 transition-colors duration-200"
        />
        <span
          class="text-sm text-gray-700 group-hover:text-gray-900 transition-colors duration-200"
          >Share</span
        >
      </button>

      <button
        class="flex items-center space-x-1.5 group sm:px-2 py-1 rounded-lg hover:bg-indigo-50 transition-all duration-200 transform hover:scale-102"
        @click="$emit('toggle-save', post)"
      >
        <Bookmark
          :class="[
            'h-5 w-5 transition-colors duration-300',
            post.isSaved
              ? 'text-indigo-600 fill-indigo-600'
              : 'text-gray-600 group-hover:text-indigo-400',
          ]"
        />
        <span
          class="text-sm font-medium text-gray-700 group-hover:text-gray-900 transition-colors duration-200"
          >Save</span
        >
      </button>
    </div>
  </div>
</template>

<script setup>
import {
  Heart,
  MessageCircle,
  Share2,
  Bookmark,
  Loader2,
} from "lucide-vue-next";

defineProps({
  post: {
    type: Object,
    required: true,
  },
  user: {
    type: Object,
    default: null,
  },
});

defineEmits([
  "toggle-like",
  "open-likes-modal",
  "open-comments-modal",
  "share-post",
  "toggle-save",
]);
</script>

<style scoped>
.animate-heartbeat {
  animation: heartbeat 0.5s ease-in-out;
}

@keyframes heartbeat {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.2);
  }
}

/* Micro scale for hover effect */
.hover\:scale-102:hover {
  transform: scale(1.02);
}

.hover\:scale-105:hover {
  transform: scale(1.05);
}
</style>
