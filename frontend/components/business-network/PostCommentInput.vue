<template>
  <div
    class="flex items-center gap-2.5 mt-4 pt-3 border-t border-gray-100/60 dark:border-slate-700/40 px-2"
  >
    <!-- User avatar with enhanced styling -->
    <div class="relative group">
      <img
        :src="user?.user?.image"
        alt="Your avatar"
        class="size-9 rounded-full object-cover border-2 border-white dark:border-slate-700 shadow-sm group-hover:shadow-md transition-all duration-300"
      />
      <!-- Subtle glow effect on hover -->
      <div
        class="absolute inset-0 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-blue-500/10 blur-md -z-10"
      ></div>
    </div>

    <!-- Comment input with glassmorphism -->
    <div class="flex-1 relative">
      <div class="relative group">
        <!-- <input
          type="text"
          placeholder="Add a comment..."
          class="w-full text-sm py-2.5 pr-12 pl-4 bg-gray-50/80 dark:bg-slate-800/70 border border-gray-200/70 dark:border-slate-700/50 rounded-full focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-400/40 shadow-sm hover:shadow-sm focus:shadow-md transition-all duration-300 backdrop-blur-[2px] text-gray-700 dark:text-gray-200 placeholder-gray-500 dark:placeholder-gray-400"
          v-model="post.commentText"
          @keyup.enter="$emit('add-comment', post)"
          @focus="post.showCommentInput = true"
          @input="$emit('handle-comment-input', $event, post)"
          @keydown="$emit('handle-mention-keydown', $event, post)"
        /> -->
        <textarea
          ref="commentTextarea"
          v-model="post.commentText"
          placeholder="Add a comment..."
          rows="1"
          class="w-full text-sm py-2.5 pr-28 pl-4 bg-gray-50/80 dark:bg-slate-800/70 border border-gray-200/70 dark:border-slate-700/50 rounded-full focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-400/40 shadow-sm hover:shadow-sm focus:shadow-md transition-all duration-300 backdrop-blur-[2px] text-gray-700 dark:text-gray-200 placeholder-gray-500 dark:placeholder-gray-400 resize-none overflow-y-auto leading-5 max-h-[6.5rem] no-scrollbar"
          @input="
            autoResize();
            $emit('handle-comment-input', $event, post);
          "
          @focus="post.showCommentInput = true"
          @keydown="$emit('handle-mention-keydown', $event, post)"
        ></textarea>

        <!-- Subtle gradient line under input on focus -->
        <div
          class="absolute bottom-0 left-4 right-4 h-0.5 bg-gradient-to-r from-blue-500/0 via-blue-500/50 to-blue-500/0 transform scale-x-0 group-focus-within:scale-x-100 transition-transform duration-300"
        ></div>
      </div>

      <!-- Action buttons with premium styling -->
      <div
        v-if="post.commentText"
        class="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center space-x-1.5"
      >
        <button
          class="p-1.5 rounded-full text-gray-400 hover:text-gray-500 dark:text-gray-500 dark:hover:text-gray-300 hover:bg-gray-100/80 dark:hover:bg-slate-700/80 transition-all duration-300"
          @click="post.commentText = ''"
          aria-label="Clear comment"
        >
          <UIcon name="i-heroicons-x-mark" class="h-4 w-4" />
        </button>
        <button
          class="p-1.5 rounded-full bg-blue-500/90 hover:bg-blue-600 text-white shadow-sm hover:shadow transform hover:scale-105 transition-all duration-300"
          @click="$emit('add-comment', post)"
          aria-label="Post comment"
        >
          <Send class="h-3.5 w-3.5" />
          <!-- Subtle glow effect -->
          <div
            class="absolute inset-0 rounded-full bg-blue-400/50 blur-md opacity-0 hover:opacity-60 transition-opacity duration-300 -z-10"
          ></div>
        </button>
        <button
          class="p-1.5 rounded-full text-gray-400 hover:text-gray-500 dark:text-gray-500 dark:hover:text-gray-300 hover:bg-gray-100/80 dark:hover:bg-slate-700/80 transition-all duration-300"
          aria-label="Clear comment"
        >
          <UIcon
            name="i-material-symbols-light-featured-seasonal-and-gifts"
            class="h-4 w-4"
          />
        </button>
      </div>

      <!-- Mention suggestions dropdown with enhanced glassmorphism -->
      <div
        v-if="
          showMentions &&
          mentionSuggestions.length > 0 &&
          post === mentionInputPosition?.post
        "
        class="absolute left-0 bottom-full mb-2 w-64 bg-white/90 dark:bg-slate-800/90 backdrop-blur-md rounded-lg shadow-xl border border-gray-100/50 dark:border-slate-700/50 z-20 max-h-56 overflow-y-auto animate-fade-in-up premium-shadow"
      >
        <div class="pt-1 pb-1">
          <!-- Header with subtle styling -->
          <div
            class="px-3 py-1.5 text-xs font-medium text-gray-500 dark:text-gray-400 border-b border-gray-100/80 dark:border-slate-700/80"
          >
            Mention someone
          </div>

          <div class="py-1">
            <div
              v-for="(user, index) in mentionSuggestions"
              :key="user.id"
              @click="$emit('select-mention', user, post)"
              :class="[
                'flex items-center px-3 py-2 cursor-pointer transition-colors duration-200',
                index === activeMentionIndex
                  ? 'bg-blue-50/80 dark:bg-blue-900/30'
                  : 'hover:bg-gray-50/80 dark:hover:bg-slate-700/80',
              ]"
            >
              <!-- User avatar in mentions -->
              <div class="relative">
                <img
                  :src="user?.follower_details?.image"
                  :alt="user?.follower_details?.name"
                  class="w-8 h-8 rounded-full mr-2.5 border border-gray-200/70 dark:border-slate-700/70 object-cover"
                />
                <!-- Verified badge if applicable -->
                <div
                  v-if="user?.follower_details?.kyc"
                  class="absolute -bottom-0.5 -right-0.5 bg-blue-500 rounded-full w-3 h-3 border border-white dark:border-slate-800 flex items-center justify-center"
                >
                  <UIcon name="i-heroicons-check" class="w-2 h-2 text-white" />
                </div>
              </div>

              <!-- User name with subtle styling -->
              <div class="flex flex-col">
                <span
                  class="text-sm font-medium text-gray-800 dark:text-gray-200"
                >
                  {{ user?.follower_details?.name }}
                </span>
                <span
                  class="text-xs text-gray-500 dark:text-gray-400"
                  v-if="user?.follower_details?.profession"
                >
                  {{ user?.follower_details?.profession }}
                </span>
              </div>
            </div>
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

function autoResize() {
  const el = this.$refs?.post.commentText;
  if (el) {
    el.style.height = "auto";
    el.style.height = Math.min(el.scrollHeight, 104) + "px"; // 3 lines ~ 104px
  }
}

defineEmits([
  "add-comment",
  "handle-comment-input",
  "handle-mention-keydown",
  "select-mention",
]);
</script>

<style scoped>
/* Premium shadow for dropdown */
.premium-shadow {
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08), 0 2px 8px rgba(0, 0, 0, 0.06),
    0 0 1px rgba(0, 0, 0, 0.08);
}

.dark .premium-shadow {
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.2), 0 2px 8px rgba(0, 0, 0, 0.15),
    0 0 1px rgba(255, 255, 255, 0.05);
}

/* Animation for mention dropdown */
.animate-fade-in-up {
  animation: fadeInUp 0.2s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
/* Hide scrollbar for Chrome, Safari and Opera */
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
/* Hide scrollbar for IE, Edge and Firefox */
.no-scrollbar {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}
</style>
