<template>  <div
    class="flex items-center justify-between pt-3.5 pb-1.5 border-t border-gray-200/70 dark:border-slate-700/50 mb-4 max-w-2xl mx-auto"
  >
    <!-- Left Side Actions: Like, Comment, Share -->
    <div class="flex items-center space-x-4">
      <!-- Like button with counter -->
      <div class="flex items-center group">
        <button
          class="p-1.5 rounded-full hover:bg-rose-50/80 dark:hover:bg-rose-900/20 transition-all duration-300 disabled:opacity-60 transform hover:scale-105 relative"
          @click="$emit('toggle-like', post)"
          :disabled="post.isLikeLoading"
          title="Like"
        >
          <!-- Loading state -->
          <div v-if="post.isLikeLoading" class="h-5 w-5">
            <Loader2
              class="h-5 w-5 text-rose-400 dark:text-rose-300 animate-spin"
            />
          </div>

          <!-- Heart icon with premium effects -->
          <div v-else class="relative">
            <!-- Pulse effect for liked posts - enhanced effect -->
            <div
              v-if="
                post.post_likes?.find((like) => like?.user === user?.user?.id)
              "
              class="absolute inset-0 rounded-full bg-rose-500/30 animate-ping-premium opacity-80"
            ></div>

            <Heart
              :class="[
                'size-5 transition-all duration-300',
                post.post_likes?.find((like) => like.user === user?.user?.id)
                  ? 'text-rose-500 dark:text-rose-400 fill-rose-500 dark:fill-rose-400 animate-heartbeat-premium'
                  : 'text-rose-400 dark:text-rose-300 group-hover:text-rose-500 dark:group-hover:text-rose-400',
              ]"
            />
          </div>
        </button>
        
        <!-- Like counter (small) -->
        <span 
          @click="$emit('open-likes-modal', post)" 
          class="text-xs ml-1 text-gray-600 dark:text-gray-400 cursor-pointer hover:text-rose-600 dark:hover:text-rose-400"
        >
          {{ formatCount(post?.post_likes?.length || 0) }}
        </span>
      </div>

      <!-- Comment button with counter -->
      <div class="flex items-center group">
        <button
          class="p-1.5 rounded-full hover:bg-blue-50/80 dark:hover:bg-blue-900/20 transition-all duration-300 transform hover:scale-105"
          @click="$emit('open-comments-modal', post)"
          title="Comment"
        >
          <div class="relative">
            <MessageCircle
              class="size-5 text-blue-500/90 dark:text-blue-400/90 group-hover:text-blue-600 dark:group-hover:text-blue-300 transition-colors duration-300"
            />
            <!-- Enhanced glow effect on hover -->
            <div
              class="absolute inset-0 rounded-full bg-blue-400/0 group-hover:bg-blue-400/30 blur-md transition-opacity duration-300 -z-10 opacity-0 group-hover:opacity-100"
            ></div>
          </div>
        </button>
        
        <!-- Comment counter (small) -->
        <span 
          @click="$emit('open-comments-modal', post)" 
          class="text-xs ml-1 text-gray-600 dark:text-gray-400 cursor-pointer hover:text-blue-600 dark:hover:text-blue-400"
        >
          {{ formatCount(post?.post_comments?.length || 0) }}
        </span>
      </div>

      <!-- Share button (icon only) -->
      <button
        class="p-1.5 rounded-full hover:bg-emerald-50/80 dark:hover:bg-emerald-900/20 transition-all duration-300 transform hover:scale-105"
        @click="$emit('share-post', post)"
        title="Share"
      >
        <div class="relative">
          <Share2
            class="h-5 w-5 text-emerald-500/90 dark:text-emerald-400/90 group-hover:text-emerald-600 dark:group-hover:text-emerald-300 transition-colors duration-300"
          />
          <!-- Enhanced glow effect on hover -->
          <div
            class="absolute inset-0 rounded-full bg-emerald-400/0 group-hover:bg-emerald-400/30 blur-md transition-opacity duration-300 -z-10 opacity-0 group-hover:opacity-100"
          ></div>
        </div>
      </button>
    </div>

    <!-- Right Side: Save Button -->
    <button
      class="p-1.5 rounded-full hover:bg-indigo-50/80 dark:hover:bg-indigo-900/20 transition-all duration-300 transform hover:scale-105"
      @click="$emit('toggle-save', post)"
      title="Save"
    >
      <div class="relative">
        <!-- Enhanced pulse effect for saved posts -->
        <div
          v-if="
            post.isSaved ||
            savedPosts.some(
              (i) => i.post === post.id && i.user === user?.user?.id
            )
          "
          class="absolute inset-0 rounded-full bg-indigo-500/30 animate-pulse-premium opacity-80"
        ></div>

        <Bookmark
          :class="[
            'h-5 w-5 transition-all duration-300',
            post.isSaved ||
            savedPosts.some(
              (i) => i.post === post.id && i.user === user?.user?.id
            )
              ? 'text-indigo-600 dark:text-indigo-400 fill-indigo-600 dark:fill-indigo-400'
              : 'text-gray-600 dark:text-gray-400 group-hover:text-indigo-500 dark:group-hover:text-indigo-300',
          ]"
        />
        <!-- Enhanced glow effect on hover -->
        <div
          class="absolute inset-0 rounded-full bg-indigo-400/0 group-hover:bg-indigo-400/30 blur-md transition-opacity duration-300 -z-10 opacity-0 group-hover:opacity-100"
        ></div>
      </div>
    </button>
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
