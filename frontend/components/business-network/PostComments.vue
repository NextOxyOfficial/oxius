<template>
  <div class="space-y-2.5 px-2 pt-1">
    <!-- Top gift comment pinned section - Shows only the highest diamond gift -->
    <div v-if="highestGiftComment" class="mb-3">
      <div class="flex items-center gap-2 mb-1.5">
        <UIcon name="i-heroicons-star" class="w-3.5 h-3.5 text-amber-500" />
        <span class="text-xs font-medium text-gray-600 dark:text-gray-600"
          >Top Gift</span
        >
      </div>
      <div class="flex items-start space-x-2.5 w-full">
        <NuxtLink
          :to="`/business-network/profile/${highestGiftComment?.author}`"
        >
          <div class="relative group">
            <div
              class="absolute inset-0 rounded-full bg-gradient-to-br from-amber-400 to-pink-500 opacity-50 blur-sm animate-pulse"
            ></div>
            <img
              :src="highestGiftComment.author_details?.image || placeholderPath"
              :alt="highestGiftComment.author_details?.name"
              class="w-8 h-8 rounded-full mt-0.5 cursor-pointer object-cover border-2 border-amber-300 dark:border-amber-500/80 shadow-sm group-hover:shadow-sm transition-all duration-300 relative z-10"
            />
          </div>
        </NuxtLink>

        <div class="flex-1">
          <div
            class="bg-gradient-to-r from-amber-50/80 to-pink-50/80 dark:from-amber-900/20 dark:to-pink-900/20 backdrop-blur-[2px] rounded-xl pb-2 pt-0.5 px-3 shadow-sm border border-amber-200/50 dark:border-amber-700/30"
          >
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-1">
                <NuxtLink
                  :to="`/business-network/profile/${highestGiftComment.author}`"
                  class="text-sm text-gray-800 dark:text-gray-300 hover:text-amber-600 dark:hover:text-amber-400 transition-colors"
                >
                  {{ highestGiftComment.author_details?.name }}
                </NuxtLink>
                <!-- Verified Badge -->
                <div
                  v-if="highestGiftComment.author_details?.kyc"
                  class="text-blue-500 flex items-center"
                >
                  <UIcon name="i-mdi-check-decagram" class="w-3 h-3" />
                </div>
              </div>
            </div>

            <!-- Gift content with sender info -->
            <div class="gift-comment-premium">
              <div class="gift-label flex gap-1 mb-1">
                <UIcon name="i-heroicons-gift" class="w-4 h-4 text-pink-500 mt-0.5 mr-1" />
                <span
                  class="text-sm font-medium text-pink-600 dark:text-pink-400"
                >
                  Sent {{ highestGiftComment?.diamond_amount }} diamonds to
                  {{ post?.author_details?.name || post?.author?.name }}
                </span>
              </div>

              <!-- Gift message if available -->
              <div class="gift-message-container">
                <p class="gift-message-text">
                  {{ extractGiftMessage(highestGiftComment?.content) }}
                </p>
              </div>
            </div>
          </div>

          <!-- Timestamp with premium styling -->
          <div class="flex items-center mt-1 pl-1">
            <UIcon
              name="i-heroicons-clock"
              class="w-3 h-3 text-gray-600 dark:text-gray-600 mr-1"
            />
            <span class="text-sm text-gray-600 dark:text-gray-600">
              {{ formatTimeAgo(highestGiftComment?.created_at) }}
            </span>
          </div>
        </div>
      </div>
    </div>    <!-- See all comments button with smaller hover effect -->
    <button
      v-if="(post?.comment_count || 0) > 3"
      class="flex items-center text-sm text-blue-600 dark:text-blue-400 font-medium hover:text-blue-700 dark:hover:text-blue-300 transition-colors duration-300 group"
      @click="$emit('open-comments-modal', post)"
    >
      <UIcon
        name="i-heroicons-chat-bubble-left-ellipsis"
        class="mr-1.5 w-4 h-4 group-hover:scale-105 transition-transform duration-300"
      />
      See all {{ post?.comment_count || 0 }} comments
    </button>

    <!-- Comments with premium glassmorphism design -->
    <div
      v-for="(comment, index) in displayedComments"
      :key="comment.id"
      class="flex items-start space-x-2.5"
    >
      <div class="flex items-start space-x-2.5 w-full">
        <NuxtLink :to="`/business-network/profile/${comment?.author}`">
          <div class="relative group">
            <img
              :src="comment.author_details?.image || placeholderPath"
              :alt="comment.author_details?.name"
              class="w-8 h-8 rounded-full mt-0.5 cursor-pointer object-cover border border-gray-200/70 dark:border-slate-700/70 shadow-sm group-hover:shadow-sm transition-all duration-300"
            />
          </div>
        </NuxtLink>

        <div class="flex-1">
          <div
            class="bg-gray-50/80 dark:bg-slate-800/70 backdrop-blur-[2px] rounded-xl pb-1 pt-0.5 px-3 shadow-sm border border-gray-100/50 dark:border-slate-700/50"
          >
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-1">
                <NuxtLink
                  :to="`/business-network/profile/${comment.author}`"
                  class="text-base font-medium text-gray-800 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                >
                  {{ comment.author_details?.name }}
                </NuxtLink>
                <!-- Verified Badge -->
                <div
                  v-if="comment.author_details?.kyc"
                  class="text-blue-500 flex items-center"
                >
                  <UIcon name="i-mdi-check-decagram" class="w-3 h-3" />
                </div>
              </div>

              <!-- Only edit/delete buttons for comment owner - Fixing action buttons -->
              <div v-if="comment.author === user?.user?.id" class="relative">
                <button
                  type="button"
                  @click.stop="toggleDropdown(comment)"
                  class="p-1.5 rounded-full text-gray-600 dark:text-gray-600 hover:bg-gray-100/80 dark:hover:bg-slate-700/80 transition-all"
                  aria-label="Comment options"
                >
                  <UIcon
                    name="i-heroicons-ellipsis-horizontal"
                    class="size-4"
                  />
                </button>

                <!-- Dropdown menu -->
                <div
                  v-if="comment.showDropdown"
                  class="absolute right-8 -top-1 mt-1 w-36 bg-white/95 dark:bg-slate-800/95 rounded-lg shadow-sm border border-gray-100/50 dark:border-slate-700/50 z-50 transition-all duration-200 origin-top-right"
                  @click.stop
                >
                  <div class="py-1">
                    <button
                      @click.stop="
                        editComment(post, comment);
                        comment.showDropdown = false;
                      "
                      class="flex items-center w-full px-4 py-2 text-sm text-gray-800 dark:text-gray-300 hover:bg-blue-50/50 dark:hover:bg-blue-900/20 transition-colors"
                    >
                      <UIcon
                        name="i-heroicons-pencil-square"
                        class="h-4 w-4 mr-2 text-blue-600 dark:text-blue-400"
                      />
                      <span>Edit</span>
                    </button>

                    <button
                      @click.stop="
                        deleteComment(post, comment);
                        comment.showDropdown = false;
                      "
                      class="flex items-center w-full px-4 py-2 text-sm text-gray-800 dark:text-gray-300 hover:bg-red-50/50 dark:hover:bg-red-900/20 transition-colors"
                      :disabled="comment.isDeleting"
                    >
                      <div v-if="comment.isDeleting" class="mr-2">
                        <Loader2 class="h-4 w-4 text-red-500 animate-spin" />
                      </div>
                      <UIcon
                        v-else
                        name="i-heroicons-trash"
                        class="h-4 w-4 mr-2 text-red-500 dark:text-red-400"
                      />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>

                <!-- Click outside directive to close dropdown -->
                <div
                  v-if="comment.showDropdown"
                  class="fixed inset-0 z-10"
                  @click="comment.showDropdown = false"
                ></div>
              </div>
            </div>

            <!-- Comment editing form with glassmorphism -->
            <div v-if="comment.isEditing">
              <textarea
                :id="`comment-edit-${comment.id}`"
                v-model="comment.editText"
                class="w-full text-base p-2 bg-white/90 dark:bg-slate-700/90 border border-blue-200/70 dark:border-blue-700/50 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-500/50 dark:focus:ring-blue-400/50 backdrop-blur-sm shadow-sm transition-all duration-300"
                rows="2"
              ></textarea>
              <div class="flex justify-end space-x-2 mt-2">
                <button
                  type="button"
                  @click.prevent="$emit('cancel-edit-comment', comment)"
                  class="text-xs text-gray-600 dark:text-gray-600 hover:text-gray-800 dark:hover:text-gray-300 px-3 py-1.5 rounded-lg hover:bg-gray-100/80 dark:hover:bg-gray-700/80 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  @click.prevent="saveEditComment(post, comment)"
                  class="text-xs bg-gradient-to-r from-blue-500 to-blue-600 dark:from-blue-600 dark:to-blue-700 text-white rounded-lg px-3 py-1.5 hover:from-blue-600 hover:to-blue-700 dark:hover:from-blue-500 dark:hover:to-blue-600 disabled:opacity-50 shadow-sm hover:shadow transition-all flex items-center justify-center gap-1.5"
                  :disabled="
                    !comment.editText?.trim() ||
                    comment.editText === comment.content ||
                    comment.isSaving
                  "
                >
                  <Loader2
                    v-if="comment.isSaving"
                    class="h-3 w-3 animate-spin"
                  />
                  <span v-if="comment.isSaving">Saving...</span>
                  <span v-else>Save</span>
                </button>
              </div>
            </div>

            <!-- Comment content with premium styling and special gift display -->
            <div v-else>
              <!-- Gift comment with enhanced styling -->
              <div v-if="comment?.is_gift_comment" class="gift-comment">
                <!-- "Sent X diamonds" label -->
                <div class="gift-sender-info flex items-center gap-1">
                  <UIcon
                    name="material-symbols:diamond-outline"
                    class="w-4 h-4 text-pink-500"
                  />
                  <span
                    class="text-sm font-medium text-pink-600 dark:text-pink-400"
                  >
                    Sent {{ comment?.diamond_amount }} diamonds to
                    {{ post?.author_details?.name || post?.author?.name }}
                  </span>
                </div>

                <!-- Gift message content with improved styling -->
                <div class="gift-content">
                  <p class="gift-message-text">
                    {{ extractGiftMessage(comment?.content) }}
                  </p>
                </div>
              </div>              
              <!-- Regular comment with mention processing -->
              <div
                v-else
                class="text-sm text-gray-800 dark:text-gray-300"
                style="word-break: break-word"
                v-html="processMentionsInComment(comment?.content)"
              ></div>
            </div>
          </div>

          <!-- Timestamp with premium styling -->
          <div class="flex items-center mt-1 pl-1">
            <UIcon
              name="i-heroicons-clock"
              class="w-3 h-3 text-gray-600 dark:text-gray-600 mr-1"
            />
            <span class="text-sm text-gray-600 dark:text-gray-600">
              {{ formatTimeAgo(comment?.created_at) }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Loader2 } from "lucide-vue-next";
import { computed, onMounted } from "vue";

// Import the mentions composable
const { processMentionsAsHTML, setupMentionClickHandlers } = useMentions();

const props = defineProps({
  post: {
    type: Object,
    required: true,
  },
  user: {
    type: Object,
    default: null,
  },
});

// Define placeholder path for consistent usage
const placeholderPath = '/static/frontend/images/placeholder.jpg';

const emit = defineEmits([
  "open-comments-modal",
  "edit-comment",
  "delete-comment",
  "cancel-edit-comment",
  "save-edit-comment",
]);

// Find the comment with highest diamond amount for pinning at the top
const highestGiftComment = computed(() => {
  // Only if we have any gift comments
  if (!props.post?.post_comments?.length) return null;

  // Find all gift comments and sort by diamond amount
  const giftComments = props.post.post_comments.filter(
    (comment) => comment.is_gift_comment
  );

  if (giftComments.length === 0) return null;

  // Sort by diamond amount in descending order and return the highest
  return [...giftComments].sort(
    (a, b) => b.diamond_amount - a.diamond_amount
  )[0];
});

// Filter out the highest gift comment from regular comments to avoid duplication
const displayedComments = computed(() => {
  if (!props.post?.post_comments?.length) return [];

  let comments = [...props.post.post_comments];

  // If there's a highest gift comment, remove it from the regular comments list
  if (highestGiftComment.value) {
    comments = comments.filter(
      (comment) => comment.id !== highestGiftComment.value.id
    );
  }

  // Return up to 3 most recent comments (excluding the pinned one)
  return comments.slice(0, 3).reverse();
});

// Extract clean gift message from content
const extractGiftMessage = (content) => {
  if (!content) return "";

  // Remove common prefixes like "Sent X diamonds as a gift! ✨"
  if (content.includes("diamonds as a gift")) {
    return content.replace(/^Sent \d+ diamonds as a gift! ✨/, "").trim();
  }

  return content;
};

// Direct helper functions for comment actions
const editComment = (post, comment) => {
  // Initialize edit text if not already set
  if (!comment.editText) {
    comment.editText = comment.content;
  }

  // Set editing state
  comment.isEditing = true;

  // Emit event for parent components
  emit("edit-comment", post, comment);
};

const deleteComment = (post, comment) => {
  // Emit delete event to parent
  emit("delete-comment", post, comment);
};

const saveEditComment = (post, comment) => {
  // Emit save event to parent
  emit("save-edit-comment", post, comment);
};

// Format time ago function
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${Math.abs(diffInSeconds)} ${
      diffInSeconds === 1 ? "second" : "seconds"
    } ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${Math.abs(diffInMinutes)} ${
      diffInMinutes === 1 ? "minute" : "minutes"
    } ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${Math.abs(diffInHours)} ${
      diffInHours === 1 ? "hour" : "hours"
    } ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${Math.abs(diffInDays)} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${Math.abs(diffInMonths)} ${
    diffInMonths === 1 ? "month" : "months"
  } ago`;
};

// Toggle dropdown visibility
const toggleDropdown = (comment) => {
  // First, close all other dropdowns
  if (props.post?.post_comments) {
    props.post.post_comments.forEach((c) => {
      if (c.id !== comment.id) {
        c.showDropdown = false;
      }
    });
  }

  // Toggle this dropdown
  if (comment.showDropdown === undefined) {
    comment.showDropdown = true;
  } else {
    comment.showDropdown = !comment.showDropdown;
  }
};

// Process mentions in comments to make them clickable
const processMentionsInComment = (content) => {
  return processMentionsAsHTML(content);
};

// Setup mention click handlers when component mounts
onMounted(() => {
  setupMentionClickHandlers();
});
</script>

<style scoped>
/* Premium Gift Comment Styling */
.gift-comment {
  @apply relative my-2 p-3 rounded-xl overflow-hidden bg-gradient-to-r from-pink-100/90 via-pink-50/80 to-fuchsia-100/70 border border-pink-200/60 shadow-sm transition-all duration-300;
}

.dark .gift-comment {
  @apply from-pink-900/30 via-pink-800/25 to-fuchsia-900/30 border-pink-700/40;
}

.gift-comment:hover {
  @apply -translate-y-0.5 shadow-sm;
}

/* Gift sender info styling */
.gift-sender-info {
  @apply text-xs text-pink-600 dark:text-pink-400;
}

/* Gift message styling */
.gift-message-text {
  @apply text-base leading-relaxed text-gray-800 dark:text-gray-300 mt-1;
}

/* Top Gift Comment Styling */
.gift-comment-premium {
  @apply relative p-3 rounded-xl overflow-hidden border-pink-300/40 shadow-sm transition-all duration-300;
  background: linear-gradient(
    135deg,
    rgba(253, 242, 248, 0.9) 0%,
    rgba(249, 168, 212, 0.15) 50%,
    rgba(253, 242, 248, 0.7) 100%
  );
}

.dark .gift-comment-premium {
  @apply border-pink-700/40;
  background: linear-gradient(
    135deg,
    rgba(131, 24, 67, 0.3) 0%,
    rgba(219, 39, 119, 0.2) 50%,
    rgba(131, 24, 67, 0.3) 100%
  );
}
</style>
