<template>
  <div class="max-h-[30vh] overflow-y-auto mb-3">
    <h4 class="text-md font-medium text-gray-600 mb-2">Comments</h4>
    <div class="space-y-2 px-2">
      <div
        v-for="comment in mediaComments"
        :key="comment.id"
        class="flex items-start space-x-2"
      >
        <div class="flex items-start space-x-2 w-full">
          <NuxtLink
            :to="`/business-network/profile/${comment.author_details.id}`"
          >
            <img
              v-if="comment.author_details.image"
              :src="comment.author_details.image"
              alt="User"
              class="w-6 h-6 rounded-full cursor-pointer"
            />
            <img
              v-else
              src="/static/frontend/images/placeholder.jpg"
              alt="User"
              class="w-6 h-6 rounded-full cursor-pointer"
            />
          </NuxtLink>
          <div class="flex-1">
            <div class="bg-gray-50 rounded-lg p-2">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-1.5">
                  <NuxtLink
                    :to="`/business-network/profile/${comment.author_details.id}`"
                    class="text-sm font-medium hover:underline"
                  >
                    {{ comment.author_details.name }}
                  </NuxtLink>
                  <!-- Verified Badge -->
                  <div
                    v-if="comment.author_details.kyc"
                    class="text-blue-500 flex items-center"
                  >
                    <UIcon name="i-mdi-check-decagram" class="w-3 h-3" />
                  </div>
                </div>

                <!-- Edit/Delete buttons - show only if currentUserId matches comment author -->
                <div
                  v-if="currentUserId === comment.author_details.id"
                  class="flex space-x-1"
                >
                  <button
                    @click="handleEditComment(comment)"
                    class="text-gray-600 hover:text-blue-600"
                    title="Edit comment"
                  >
                    <UIcon name="i-heroicons-pencil-square" class="w-4 h-4" />
                  </button>
                  <button
                    @click="handleDeleteComment(comment)"
                    class="text-gray-600 hover:text-red-600"
                    title="Delete comment"
                  >
                    <UIcon name="i-heroicons-trash" class="w-4 h-4" />
                  </button>
                </div>
              </div>

              <!-- Editable comment -->
              <div v-if="editingComment && editingComment.id === comment.id">
                <textarea
                  v-model="editText"
                  class="w-full mt-1 text-sm border border-gray-200 rounded p-2 focus:outline-none focus:ring-1 focus:ring-blue-500"
                  rows="2"
                  ref="editTextareaRef"
                  @keydown.enter.prevent="saveEdit"
                ></textarea>
                <div class="flex justify-end mt-1 space-x-2">
                  <button
                    @click="cancelEdit"
                    class="text-xs text-gray-600 hover:underline"
                  >
                    Cancel
                  </button>
                  <button
                    @click="saveEdit"
                    class="text-xs bg-blue-600 text-white rounded px-2 py-1 hover:bg-blue-700"
                    :disabled="!editText.trim()"
                  >
                    Save
                  </button>
                </div>
              </div>
              <p v-else class="text-sm mt-1" v-html="processMentionsInComment(comment.content)" style="word-break: break-word"></p>
            </div>
            <div class="flex items-center mt-1 space-x-3">
              <span class="text-sm text-gray-600">{{
                formatTimeAgo(comment.created_at)
              }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Comment input area -->
    <div v-if="showCommentInput" class="mt-3 flex items-center gap-2">
      <input
        type="text"
        v-model="newComment"
        placeholder="Add a comment..."
        class="flex-1 border border-gray-200 rounded-full px-3 py-1.5 text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
        @keydown.enter.prevent="submitComment"
        ref="commentInputRef"
      />
      <button
        @click="submitComment"
        class="text-blue-500 hover:text-blue-700"
        :disabled="!newComment.trim()"
      >
        <UIcon name="i-heroicons-paper-airplane" class="w-5 h-5" />
      </button>
    </div>

    <!-- View all comments button -->
    <div v-if="mediaComments.length > 3 && !showAllComments" class="mt-2">
      <button
        @click="openAllCommentsModal"
        class="text-sm text-blue-600 hover:underline"
      >
        View all {{ mediaComments.length }} comments
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted } from "vue";

// Import the mentions composable
const { processMentionsAsHTML, setupMentionClickHandlers } = useMentions();

const props = defineProps({
  mediaComments: {
    type: Array,
    required: true,
  },
  showCommentInput: {
    type: Boolean,
    default: false,
  },
  showAllComments: {
    type: Boolean,
    default: false,
  },
  currentUserId: {
    type: [String, Number],
    default: null,
  },
});

const newComment = ref("");
const editingComment = ref(null);
const editText = ref("");
const commentInputRef = ref(null);
const editTextareaRef = ref(null);

const emit = defineEmits([
  "edit-comment",
  "delete-comment",
  "add-comment",
  "view-all-comments",
]);

const submitComment = () => {
  if (newComment.value.trim()) {
    emit("add-comment", newComment.value);
    newComment.value = "";
  }
};

const openAllCommentsModal = () => {
  emit("view-all-comments");
};

const handleEditComment = (comment) => {
  editingComment.value = comment;
  editText.value = comment.content;

  // Focus the textarea after it's rendered
  nextTick(() => {
    if (editTextareaRef.value) {
      editTextareaRef.value.focus();
    }
  });
};

const handleDeleteComment = (comment) => {
  emit("delete-comment", comment);
};

const saveEdit = () => {
  if (editText.value.trim() && editingComment.value) {
    emit("edit-comment", {
      ...editingComment.value,
      content: editText.value.trim(),
    });
    cancelEdit();
  }
};

const cancelEdit = () => {
  editingComment.value = null;
  editText.value = "";
};

// Focus the comment input when component is mounted and showCommentInput is true
onMounted(() => {
  if (props.showCommentInput && commentInputRef.value) {
    commentInputRef.value.focus();
  }
  // Setup mention click handlers
  setupMentionClickHandlers();
});

// Process mentions in comments to make them clickable
const processMentionsInComment = (content) => {
  return processMentionsAsHTML(content);
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
