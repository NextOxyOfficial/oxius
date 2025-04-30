<template>
  <div class="space-y-2 px-2">
    <!-- See all comments button moved to the top -->
    <button
      v-if="post?.post_comments?.length > 3"
      class="text-sm text-blue-600 font-medium"
      @click="$emit('open-comments-modal', post)"
    >
      See all {{ post?.post_comments?.length }} comments
    </button>

    <!-- Comments in reverse order (oldest first, newest last) -->
    <div
      v-for="comment in [...post.post_comments].slice(0, 3).reverse()"
      :key="comment.id"
      class="flex items-start space-x-2"
    >
      <div class="flex items-start space-x-2">
        <NuxtLink :to="`/business-network/profile/${comment?.author}`">
          <img
            :src="comment.author_details?.image"
            :alt="comment.author_details?.name"
            class="w-8 h-8 rounded-full mt-0.5 cursor-pointer"
          />
        </NuxtLink>
        <div class="flex-1">
          <div class="bg-gray-50 rounded-lg pt-1 px-2">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-1">
                <NuxtLink
                  :to="`/business-network/profile/${comment.author}`"
                  class="text-sm font-medium hover:underline"
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

              <!-- Only edit/delete buttons for comment owner -->
              <div
                v-if="comment.author === user?.user?.id"
                class="flex items-center pl-3"
              >
                <button
                  @click="$emit('edit-comment', comment)"
                  class="px-0.5 pt-1 text-gray-500 hover:text-blue-600"
                >
                  <UIcon name="i-heroicons-pencil-square" class="size-3.5" />
                </button>
                <button
                  @click="$emit('delete-comment', comment)"
                  class="px-0.5 text-gray-500 hover:text-red-600 flex items-center"
                  :disabled="comment.isDeleting"
                >
                  <Loader2
                    v-if="comment.isDeleting"
                    class="h-4 w-4 animate-spin text-red-500"
                  />
                  <UIcon v-else name="i-heroicons-trash" class="size-3.5" />
                </button>
              </div>
            </div>
            <!-- Comment Content -->
            <div v-if="comment.isEditing">
              <textarea
                :id="`comment-edit-${comment.id}`"
                v-model="comment.editText"
                class="w-full text-sm p-2 border border-gray-200 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                rows="2"
              ></textarea>
              <div class="flex justify-end space-x-2 mt-1">
                <button
                  @click="$emit('cancel-edit-comment', comment)"
                  class="text-xs text-gray-500 hover:underline"
                >
                  Cancel
                </button>
                <button
                  @click="$emit('save-edit-comment', comment)"
                  class="text-xs bg-blue-600 text-white rounded-md px-3 py-1 hover:bg-blue-700 disabled:opacity-50 flex items-center justify-center gap-1.5"
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
            <p v-else class="text-sm" style="word-break: break-word">
              {{ comment?.content }}
            </p>
          </div>
          <span class="text-sm text-gray-500 mt-1 inline-block">
            {{ formatTimeAgo(comment?.created_at) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Loader2 } from "lucide-vue-next";

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
  "open-comments-modal",
  "edit-comment",
  "delete-comment",
  "cancel-edit-comment",
  "save-edit-comment",
]);

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
