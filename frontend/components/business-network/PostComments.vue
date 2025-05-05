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

            <!-- Comment content with premium styling -->
            <p
              v-else
              class="text-base sm:text-sm text-gray-800 dark:text-gray-200"
              style="word-break: break-word"
            >
              {{ comment?.content }}
            </p>
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
    return `${diffInSeconds} ${diffInSeconds === 1 ? "second" : "seconds"} ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} ${diffInMinutes === 1 ? "minute" : "minutes"} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} ${diffInHours === 1 ? "hour" : "hours"} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${diffInMonths} ${diffInMonths === 1 ? "month" : "months"} ago`;
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
</style>
