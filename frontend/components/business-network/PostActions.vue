<template>  <div
    class="flex items-center justify-between px-2 border-t border-gray-200/70 dark:border-slate-700/50 mt-2 mb-1 max-w-2xl mx-auto"
  >
    <!-- Left Side Actions: Like, Comment, Share -->
    <div class="flex items-center space-x-4">
      <!-- Like button with counter -->
      <div class="flex items-center group">        <button
          class="p-1.5 pt-3 rounded-full transition-colors disabled:opacity-60 relative"
          @click="$emit('toggle-like', post)"
          :disabled="post.isLikeLoading"
          title="Like"
        >
          <!-- Loading state -->
          <div v-if="post.isLikeLoading" class="h-5 w-5">
            <Loader2
              class="h-5 w-5 text-rose-400 dark:text-rose-300 animate-spin"
            />
          </div>          <!-- Heart icon with modern styling -->
          <div v-else class="relative">

            <UIcon
              :name="post.post_likes?.find((like) => like.user === user?.user?.id) ? 'i-heroicons-heart-solid' : 'i-heroicons-heart'"
              :class="[
                'size-5 transition-colors',
                post.post_likes?.find((like) => like.user === user?.user?.id)
                  ? 'text-rose-500 dark:text-rose-400'
                  : 'text-gray-600 dark:text-gray-500 group-hover:text-rose-500 dark:group-hover:text-rose-400',
              ]"
            />
          </div>
        </button>
        
        <!-- Like counter (small) -->
        <span 
          @click="$emit('open-likes-modal', post)" 
          class="text-base ml-1 text-gray-600 dark:text-gray-500 cursor-pointer hover:text-rose-600 dark:hover:text-rose-400"
        >
          {{ formatCount(post?.post_likes?.length || 0) }}
        </span>
      </div>

      <!-- Comment button with counter -->
      <div class="flex items-center group">        <button
          class="p-1.5 pt-3 rounded-full transition-colors"
          @click="$emit('open-comments-modal', post)"
          title="Comment"
        ><div class="relative">
            <UIcon
              name="i-heroicons-chat-bubble-oval-left"
              class="size-5 text-gray-600 dark:text-gray-500 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
            />
          </div>
        </button>
        
        <!-- Comment counter (small) -->
        <span 
          @click="$emit('open-comments-modal', post)" 
          class="text-base ml-1 text-gray-600 dark:text-gray-500 cursor-pointer hover:text-blue-600 dark:hover:text-blue-400"
        >
          {{ formatCount(post?.post_comments?.length || 0) }}
        </span>
      </div>      <!-- Share button (icon only) -->
      <div class="flex items-center group">
        <button
          class="p-1.5 pt-3 rounded-full transition-colors"
          @click="$emit('share-post', post)"
          title="Share"
        >
          <div class="relative">
            <UIcon
              name="ion-paper-plane-outline"
              class="size-5 text-gray-600 dark:text-gray-500 group-hover:text-emerald-600 dark:group-hover:text-emerald-500 transition-colors"
            />
          </div>
        </button>
      </div>
    </div>

    <!-- Right Side: Save Button -->    <button
      class="p-1.5 rounded-full transition-colors"
      @click="$emit('toggle-save', post)"
      title="Save"
    ><div class="relative">

        <UIcon
          :name="(post.isSaved || savedPosts.some((i) => i.post === post.id && i.user === user?.user?.id)) ? 'i-heroicons-bookmark-solid' : 'i-heroicons-bookmark'"
          :class="[
            'h-5 w-5 transition-colors',
            post.isSaved ||
            savedPosts.some(
              (i) => i.post === post.id && i.user === user?.user?.id
            )
              ? 'text-indigo-600 dark:text-indigo-400'
              : 'text-gray-600 dark:text-gray-500 group-hover:text-indigo-500 dark:group-hover:text-indigo-400',
          ]"
        />
      </div>
    </button>
  </div>
</template>

<script setup>
import {
  Loader2
} from "lucide-vue-next";

const { post } = defineProps({
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
const { user } = useAuth();
const { get } = useApi();
const savedPosts = ref([]);

/**
 * Format large numbers to compact format (1k, 1.1k, etc.)
 * @param {number} count - The number to format
 * @returns {string} - Formatted number
 */
function formatCount(count) {
  if (count < 1000) {
    return count.toString();
  } else if (count < 10000) {
    // For 1000-9999, show with one decimal (1.1k, 9.9k)
    return (count / 1000).toFixed(1) + "k";
  } else {
    // For 10000+, show without decimal (10k, 11k, etc)
    return Math.floor(count / 1000) + "k";
  }
}

async function getSavedPosts() {
  const { data } = await get(`/bn/posts/save/`);
  if (data) savedPosts.value = data;
  if (
    !post.isSaved &&
    savedPosts.value.some(
      (i) => i.post === post.id && i.user === user.value.user?.id
    )
  )
    post.isSaved = true;
}
await getSavedPosts();
</script>

<style scoped>
/* Premium heartbeat animation */
.animate-heartbeat-premium {
  animation: heartbeat-premium 0.6s cubic-bezier(0.15, 0.8, 0.4, 1);
}

@keyframes heartbeat-premium {
  0% {
    transform: scale(1);
  }
  25% {
    transform: scale(1.2);
  }
  50% {
    transform: scale(1);
  }
  75% {
    transform: scale(1.1);
  }
  100% {
    transform: scale(1);
  }
}

/* Premium hover scale effect */
.hover\:scale-105:hover {
  transform: scale(1.05);
}

/* Premium animations for enhanced UX */
@keyframes ping-premium {
  0% {
    transform: scale(0.8);
    opacity: 0.8;
  }
  50% {
    transform: scale(1.5);
    opacity: 0.3;
  }
  100% {
    transform: scale(1.8);
    opacity: 0;
  }
}

@keyframes pulse-premium {
  0% {
    opacity: 0.3;
    transform: scale(1);
  }
  50% {
    opacity: 0.6;
    transform: scale(1.3);
  }
  100% {
    opacity: 0.3;
    transform: scale(1);
  }
}

.animate-ping-premium {
  animation: ping-premium 1.5s cubic-bezier(0, 0, 0.2, 1) infinite;
}

.animate-pulse-premium {
  animation: pulse-premium 1.8s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>
