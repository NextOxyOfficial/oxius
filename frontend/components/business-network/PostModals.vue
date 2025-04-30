<template>
  <!-- Likes Modal -->
  <div>
    <Teleport to="body">
      <div
        v-if="activeLikesPost"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="$emit('close-likes-modal')"
      >
        <div
          class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden"
          @click.stop
        >
          <div class="p-4 sm:p-5 border-b border-gray-200">
            <div class="flex items-center justify-between mb-1">
              <h3 class="font-semibold">Liked by</h3>
              <button @click="$emit('close-likes-modal')">
                <X class="h-5 w-5" />
              </button>
            </div>
            <p class="text-sm text-gray-600 truncate">
              {{ activeLikesPost.title }}
            </p>
          </div>
          <div class="overflow-y-auto max-h-[60vh]">
            <div
              v-for="user in activeLikesPost.post_likes"
              :key="user.id"
              class="flex items-center justify-between p-4 sm:p-5 border-b border-gray-100"
            >
              <div class="flex items-center space-x-3">
                <NuxtLink :to="`/business-network/profile/${user.user}`">
                  <img
                    :src="
                      user.user_details.image || '/static/frontend/avatar.png'
                    "
                    :alt="user.user_details.name"
                    class="w-10 h-10 rounded-full cursor-pointer"
                  />
                </NuxtLink>
                <div>
                  <NuxtLink
                    :to="`/business-network/profile/${user.user}`"
                    class="font-medium hover:underline"
                  >
                    {{ user.user_details.name }}
                  </NuxtLink>
                  <p class="text-sm text-gray-500">
                    @{{
                      user.user_details.name.toLowerCase().replace(/\s+/g, "")
                    }}
                  </p>
                </div>
              </div>
              <button
                v-if="user"
                :class="[
                  'text-sm h-7 rounded-full px-3 flex items-center gap-1',
                  user.isFollowing
                    ? 'border border-gray-200 text-gray-800'
                    : 'bg-blue-600 text-white',
                ]"
                @click.stop="$emit('toggle-user-follow', user)"
              >
                <component
                  :is="user.isFollowing ? Check : UserPlus"
                  class="h-3 w-3"
                />
                {{ user.isFollowing ? "Following" : "Follow" }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Comments Modal -->
    <Teleport to="body">
      <div
        v-if="activeCommentsPost"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="$emit('close-comments-modal')"
      >
        <div
          class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden"
          @click.stop
        >
          <div class="p-4 sm:p-5 border-b border-gray-200">
            <div class="flex items-center justify-between mb-1">
              <h3 class="font-semibold">Comments</h3>
              <button @click="$emit('close-comments-modal')">
                <X class="h-5 w-5" />
              </button>
            </div>
            <p class="text-sm text-gray-600 truncate">
              {{ activeCommentsPost.title }}
            </p>
          </div>
          <div
            ref="commentsContainerRef"
            class="overflow-y-auto max-h-[60vh] p-3 sm:p-5 space-y-3"
          >
            <div
              v-for="comment in [...activeCommentsPost.post_comments].reverse()"
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
                    <div class="flex items-center justify-between mb-1">
                      <div class="flex items-center gap-1.5">
                        <NuxtLink
                          :to="`/business-network/profile/${comment?.author}`"
                          class="text-sm font-medium hover:underline"
                        >
                          {{ comment.author_details.name }}
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
                        class="flex items-center space-x-1"
                      >
                        <button
                          @click="
                            $emit('edit-comment', activeCommentsPost, comment)
                          "
                          class="px-0.5 pt-1 text-gray-500 hover:text-blue-600"
                        >
                          <UIcon
                            name="i-heroicons-pencil-square"
                            class="size-4"
                          />
                        </button>
                        <button
                          @click="
                            $emit('delete-comment', activeCommentsPost, comment)
                          "
                          class="px-0.5 text-gray-500 hover:text-red-600 flex items-center"
                          :disabled="comment.isDeleting"
                        >
                          <Loader2
                            v-if="comment.isDeleting"
                            class="h-4 w-4 animate-spin text-red-500"
                          />
                          <UIcon
                            v-else
                            name="i-heroicons-trash"
                            class="size-4"
                          />
                        </button>
                      </div>
                    </div>
                    <!-- Editable comment content -->
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
                          @click="
                            $emit(
                              'save-edit-comment',
                              activeCommentsPost,
                              comment
                            )
                          "
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
                      {{ comment.content }}
                    </p>
                  </div>
                  <div class="flex items-center mt-1 space-x-3">
                    <span class="text-sm text-gray-500">
                      {{ formatTimeAgo(comment.created_at) }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="p-4 sm:p-5 border-t border-gray-200">
            <div class="flex items-center gap-2">
              <img
                :src="user?.user?.image"
                :alt="user?.user?.name"
                class="w-6 h-6 rounded-full"
              />
              <div class="flex-1 relative">
                <input
                  type="text"
                  placeholder="Add a comment..."
                  class="w-full text-sm py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600"
                  v-model="activeCommentsPost.commentText"
                  @input="
                    $emit('handle-comment-input', $event, activeCommentsPost)
                  "
                  @keydown="
                    $emit('handle-mention-keydown', $event, activeCommentsPost)
                  "
                  @keyup.enter="
                    !showMentions && $emit('add-comment', activeCommentsPost)
                  "
                  @click.stop
                />
                <!-- Mention suggestions dropdown -->
                <!-- ...existing mentions dropdown code... -->
                <button
                  v-if="activeCommentsPost.commentText"
                  class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-600 flex items-center gap-1"
                  @click.stop="$emit('add-comment', activeCommentsPost)"
                  :disabled="activeCommentsPost.isCommentLoading"
                >
                  <Loader2
                    v-if="activeCommentsPost.isCommentLoading"
                    class="h-5 w-5 animate-spin"
                  />
                  <Send v-else class="h-3 w-3" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Media Likes Modal -->
    <Teleport to="body">
      <div
        v-if="activeMediaLikes"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="$emit('close-media-likes-modal')"
      >
        <div
          class="bg-white rounded-lg max-w-md w-full max-h-[80vh] overflow-hidden"
          @click.stop
        >
          <div
            class="p-4 sm:p-5 border-b border-gray-200 flex items-center justify-between"
          >
            <h3 class="font-semibold">Liked by</h3>
            <button @click="$emit('close-media-likes-modal')">
              <X class="h-5 w-5" />
            </button>
          </div>
          <div class="overflow-y-auto max-h-[60vh]">
            <div
              v-for="(user, index) in mediaLikedUsers"
              :key="index"
              class="flex items-center justify-between p-4 sm:p-5 border-b border-gray-100"
            >
              <div class="flex items-center space-x-3">
                <img
                  :src="user.image"
                  :alt="user.name"
                  class="w-10 h-10 rounded-full"
                />
                <div>
                  <NuxtLink
                    :to="`/business-network/profile/${user.id}`"
                    class="font-medium hover:underline"
                  >
                    {{ user.fullName }}
                  </NuxtLink>
                  <p class="text-sm text-gray-500">
                    @{{ user.fullName.toLowerCase().replace(/\s+/g, "") }}
                  </p>
                </div>
              </div>
              <button
                v-if="user.id !== 'current-user'"
                :class="[
                  'text-sm h-7 rounded-full px-3 flex items-center gap-1',
                  user.isFollowing
                    ? 'border border-gray-200 text-gray-800'
                    : 'bg-blue-600 text-white',
                ]"
                @click.stop="$emit('toggle-user-follow', user)"
              >
                <component
                  :is="user.isFollowing ? Check : UserPlus"
                  class="h-3 w-3"
                />
                {{ user.isFollowing ? "Following" : "Follow" }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Delete Comment Modal -->
    <Teleport to="body">
      <div
        v-if="commentToDelete"
        class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
        @click="$emit('cancel-delete-comment')"
      >
        <div class="bg-white rounded-lg max-w-sm w-full p-4" @click.stop>
          <h3 class="text-lg font-semibold mb-2">Delete Comment</h3>
          <p class="text-gray-600 mb-4">
            Are you sure you want to delete this comment? This action cannot be
            undone.
          </p>
          <div class="flex justify-end space-x-2">
            <button
              @click="$emit('cancel-delete-comment')"
              class="px-4 py-2 border border-gray-200 text-gray-800 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              @click="$emit('confirm-delete-comment')"
              class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
            >
              Delete
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { X, Check, UserPlus, Loader2, Send } from "lucide-vue-next";

defineProps({
  activeLikesPost: {
    type: Object,
    default: null,
  },
  activeCommentsPost: {
    type: Object,
    default: null,
  },
  activeMediaLikes: {
    type: Object,
    default: null,
  },
  mediaLikedUsers: {
    type: Array,
    default: () => [],
  },
  commentToDelete: {
    type: Object,
    default: null,
  },
  user: {
    type: Object,
    default: null,
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

// Export a reference to the comments container for scrolling
const commentsContainerRef = ref(null);

defineEmits([
  "close-likes-modal",
  "toggle-user-follow",
  "close-comments-modal",
  "handle-comment-input",
  "handle-mention-keydown",
  "add-comment",
  "close-media-likes-modal",
  "cancel-delete-comment",
  "confirm-delete-comment",
  "edit-comment",
  "delete-comment",
  "cancel-edit-comment",
  "save-edit-comment",
]);

defineExpose({ commentsContainerRef });

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
