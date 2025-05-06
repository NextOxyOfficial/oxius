<template>
  <div class="space-y-2.5 px-2 pt-1">
    <!-- See all comments button with smaller hover effect -->
    <button
      v-if="post?.post_comments?.length > 3"
      class="flex items-center text-sm text-blue-600 dark:text-blue-400 font-medium hover:text-blue-700 dark:hover:text-blue-300 transition-colors duration-300 group"
      @click="$emit('open-comments-modal', post)"
    >
      <UIcon
        name="i-heroicons-chat-bubble-left-ellipsis"
        class="mr-1.5 w-4 h-4 group-hover:scale-105 transition-transform duration-300"
      />
      See all {{ post?.post_comments?.length }} comments
    </button>

    <!-- Comments with premium glassmorphism design -->
    <div
      v-for="(comment, index) in [...post.post_comments].slice(0, 3).reverse()"
      :key="comment.id"
      class="flex items-start space-x-2.5"
      :style="{
        animationDelay: `${index * 0.1}s`,
        animation: `fadeInUp 0.4s ease-out forwards`,
      }"
    >
      <div class="flex items-start space-x-2.5 w-full">
        <NuxtLink :to="`/business-network/profile/${comment?.author}`">
          <div class="relative group">
            <img
              :src="comment.author_details?.image"
              :alt="comment.author_details?.name"
              class="w-8 h-8 rounded-full mt-0.5 cursor-pointer object-cover border border-gray-200/70 dark:border-slate-700/70 shadow-sm group-hover:shadow-md transition-all duration-300"
            />
          </div>
        </NuxtLink>

        <div class="flex-1">
          <div
            class="bg-gray-50/80 dark:bg-slate-800/70 backdrop-blur-[2px] rounded-xl pb-2 pt-0.5 px-3 shadow-sm border border-gray-100/50 dark:border-slate-700/50"
          >
            <div class="flex items-center justify-between mb-0.5">
              <div class="flex items-center gap-1">
                <NuxtLink
                  :to="`/business-network/profile/${comment.author}`"
                  class="text-base font-medium text-gray-800 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
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
              <div
                v-if="comment.author === user?.user?.id"
                class="flex items-center pl-3"
              >
                <button
                  type="button"
                  @click.prevent="editComment(post, comment)"
                  class="p-1 rounded-full text-gray-500 dark:text-gray-400 hover:bg-blue-50/70 dark:hover:bg-blue-900/30 hover:text-blue-600 dark:hover:text-blue-400 transition-all"
                >
                  <UIcon name="i-heroicons-pencil-square" class="size-3.5" />
                </button>
                <button
                  type="button"
                  @click.prevent="deleteComment(post, comment)"
                  class="p-1 rounded-full text-gray-500 dark:text-gray-400 hover:bg-red-50/70 dark:hover:bg-red-900/30 hover:text-red-600 dark:hover:text-red-400 transition-all flex items-center justify-center"
                  :disabled="comment.isDeleting"
                >
                  <Loader2
                    v-if="comment.isDeleting"
                    class="h-3.5 w-3.5 animate-spin text-red-500"
                  />
                  <UIcon v-else name="i-heroicons-trash" class="size-3.5" />
                </button>
              </div>
            </div>

            <!-- Comment editing form with glassmorphism -->
            <div v-if="comment.isEditing">
              <textarea
                :id="`comment-edit-${comment.id}`"
                v-model="comment.editText"
                class="w-full text-sm p-2 bg-white/90 dark:bg-slate-700/90 border border-blue-200/70 dark:border-blue-700/50 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-500/50 dark:focus:ring-blue-400/50 backdrop-blur-sm shadow-sm transition-all duration-300"
                rows="2"
              ></textarea>
              <div class="flex justify-end space-x-2 mt-2">
                <button
                  type="button"
                  @click.prevent="$emit('cancel-edit-comment', comment)"
                  class="text-xs text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 px-3 py-1.5 rounded-lg hover:bg-gray-100/80 dark:hover:bg-gray-700/80 transition-colors"
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
              <!-- Gift comment with premium styling -->
              <div v-if="comment?.is_gift_comment" class="gift-comment">
                <div class="gift-badge">
                  <div class="diamond-container">
                    <span class="diamond-amount">{{ comment?.diamond_amount }}</span>
                    <span class="diamond-icon">💎</span>
                  </div>
                </div>
                <div class="sparkle-container">
                  <div class="sparkle" v-for="i in 5" :key="i"></div>
                </div>
                <p class="gift-text">{{ comment?.content }}</p>
              </div>
              <!-- Regular comment -->
              <p v-else class="text-base sm:text-sm text-gray-800 dark:text-gray-200" style="word-break: break-word">
                {{ comment?.content }}
              </p>
            </div>
          </div>

          <!-- Timestamp with premium styling -->
          <div class="flex items-center mt-1 pl-1">
            <UIcon
              name="i-heroicons-clock"
              class="w-3 h-3 text-gray-400 dark:text-gray-500 mr-1"
            />
            <span class="text-sm text-gray-500 dark:text-gray-400">
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

const emit = defineEmits([
  "open-comments-modal",
  "edit-comment",
  "delete-comment",
  "cancel-edit-comment",
  "save-edit-comment",
]);

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
</script>

<style scoped>
/* Animation for comments */
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

/* Premium Gift Comment Styling */
.gift-comment {
  position: relative;
  margin: 0.5rem 0;
  padding: 0.75rem 1rem;
  background: linear-gradient(135deg, #fff1f9 0%, #fffafd 50%, #f0f7ff 100%);
  border-radius: 12px;
  border: 1px solid rgba(255, 192, 203, 0.3);
  overflow: hidden;
  transform-origin: center;
  box-shadow: 
    0 4px 15px -3px rgba(255, 105, 180, 0.15),
    0 2px 6px -2px rgba(142, 68, 173, 0.1),
    inset 0 1px 2px rgba(255, 255, 255, 0.7);
  transition: all 0.3s ease;
  animation: giftPulse 3s infinite ease-in-out;
}

.dark .gift-comment {
  background: linear-gradient(135deg, rgba(85, 10, 70, 0.4) 0%, rgba(61, 15, 79, 0.4) 50%, rgba(20, 30, 90, 0.4) 100%);
  border: 1px solid rgba(255, 105, 180, 0.15);
  box-shadow: 
    0 4px 15px -3px rgba(255, 105, 180, 0.2),
    0 2px 6px -2px rgba(142, 68, 173, 0.15),
    inset 0 1px 2px rgba(255, 255, 255, 0.05);
}

.gift-comment:hover {
  transform: translateY(-2px) scale(1.01);
  box-shadow: 
    0 6px 20px -3px rgba(255, 105, 180, 0.25),
    0 4px 8px -2px rgba(142, 68, 173, 0.15),
    inset 0 1px 2px rgba(255, 255, 255, 0.7);
}

/* Diamond Badge */
.gift-badge {
  position: absolute;
  top: -10px;
  right: 10px;
  z-index: 5;
}

.diamond-container {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 40px;
  height: 24px;
  background: linear-gradient(135deg, #ff73c8 0%, #b08fff 100%);
  border-radius: 12px;
  padding: 2px 10px;
  box-shadow: 0 2px 6px rgba(255, 105, 180, 0.35);
  transform-style: preserve-3d;
  transform: perspective(100px) rotateX(5deg);
  animation: floatBadge 3s ease-in-out infinite;
}

.dark .diamond-container {
  background: linear-gradient(135deg, #ff4db2 0%, #9c66ff 100%);
  box-shadow: 0 2px 8px rgba(255, 105, 180, 0.5);
}

.diamond-amount {
  font-weight: bold;
  font-size: 12px;
  color: white;
  margin-right: 2px;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.diamond-icon {
  font-size: 12px;
  margin-left: 1px;
  filter: drop-shadow(0 1px 1px rgba(0, 0, 0, 0.2));
}

/* Gift Text */
.gift-text {
  position: relative;
  font-size: 0.9375rem;
  font-weight: 500;
  line-height: 1.4;
  color: #8046a5;
  margin-top: 0.5rem;
  margin-bottom: 0.25rem;
  word-break: break-word;
  text-shadow: 0 1px 1px rgba(255, 255, 255, 0.7);
  z-index: 2;
}

.dark .gift-text {
  color: #da9eff;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
}

/* Sparkling Animation */
.sparkle-container {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  overflow: hidden;
  pointer-events: none;
  z-index: 1;
}

.sparkle {
  position: absolute;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #fff;
  box-shadow: 0 0 10px 2px rgba(255, 192, 203, 0.8);
  opacity: 0;
}

.sparkle:nth-child(1) {
  top: 20%;
  left: 10%;
  animation: sparkleAnimation 4s infinite 0.5s;
}

.sparkle:nth-child(2) {
  top: 60%;
  left: 85%;
  animation: sparkleAnimation 5s infinite 1s;
}

.sparkle:nth-child(3) {
  top: 30%;
  left: 60%;
  animation: sparkleAnimation 4.5s infinite 1.5s;
}

.sparkle:nth-child(4) {
  top: 70%;
  left: 20%;
  animation: sparkleAnimation 6s infinite 2s;
}

.sparkle:nth-child(5) {
  top: 10%;
  left: 90%;
  animation: sparkleAnimation 5s infinite 2.5s;
}

/* Animations */
@keyframes giftPulse {
  0% {
    box-shadow: 0 4px 15px -3px rgba(255, 105, 180, 0.15), 0 2px 6px -2px rgba(142, 68, 173, 0.1), inset 0 1px 2px rgba(255, 255, 255, 0.7);
  }
  50% {
    box-shadow: 0 4px 20px -3px rgba(255, 105, 180, 0.25), 0 2px 8px -2px rgba(142, 68, 173, 0.15), inset 0 1px 3px rgba(255, 255, 255, 0.8);
  }
  100% {
    box-shadow: 0 4px 15px -3px rgba(255, 105, 180, 0.15), 0 2px 6px -2px rgba(142, 68, 173, 0.1), inset 0 1px 2px rgba(255, 255, 255, 0.7);
  }
}

@keyframes floatBadge {
  0%, 100% {
    transform: perspective(100px) rotateX(5deg) translateY(0px);
  }
  50% {
    transform: perspective(100px) rotateX(5deg) translateY(-3px);
  }
}

@keyframes sparkleAnimation {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  20% {
    transform: scale(1.2);
    opacity: 0.8;
  }
  40% {
    transform: scale(0.9);
    opacity: 0.5;
  }
  60% {
    transform: scale(1.2);
    opacity: 0.8;
  }
  80% {
    transform: scale(0.5);
    opacity: 0.3;
  }
  100% {
    transform: scale(0);
    opacity: 0;
  }
}
</style>
