<template>
  <div class="max-w-3xl pb-20 pt-3">
    <div class="space-y-4">
      <div
        v-for="(post, index) in posts"
        :key="post.id"
        class="transform transition-all duration-300"
        :style="{
          animationDelay: `${index * 0.05}s`,
          animation: `fadeIn 0.5s ease-out forwards`,
        }"
      >
        <!-- Post Card -->
        <div
          class="bg-white rounded-xl border border-gray-200 overflow-hidden transition-all duration-300"
        >
          <div class=" sm:px-3 py-4 sm:py-5">
            <!-- Post Header -->
            <BusinessNetworkPostHeader
              :post="post"
              :user="user"
              @toggle-follow="toggleFollow"
              @toggle-dropdown="toggleDropdown"
              @toggle-save="toggleSave"
              @copy-link="copyLink"
            />

            <!-- Post Title -->
            <NuxtLink
              :to="`/business-network/posts/${post.id}`"
              class="block text-sm sm:text-base font-semibold mb-1 hover:text-blue-600 transition-colors px-2"
            >
              {{ post.title }}
            </NuxtLink>

            <!-- Tags -->
            <div
              v-if="post?.post_tags?.length > 0"
              class="flex flex-wrap gap-1 mb-2 px-2"
            >
              <span
                v-for="(tag, idx) in post?.post_tags"
                :key="idx"
                class="text-xs bg-blue-100 text-blue-600 px-2 py-0.5 rounded-full"
              >
                #{{ tag.tag }}
              </span>
            </div>

            <!-- Post Content -->
            <div class="mb-2 min-w-full px-2">
              <p
                :class="[
                  `text-xs sm:text-sm text-gray-800`,
                  !post.showFullDescription && `line-clamp-4`,
                ]"
                v-html="post.content"
              ></p>
              <button
                v-if="post?.content?.length > 160"
                class="text-xs sm:text-sm text-blue-600 font-medium mt-1"
                @click="toggleDescription(post)"
              >
                {{
                  post.showFullDescription ? $t("read_less") : $t("read_more")
                }}
              </button>
            </div>

            <!-- Media Gallery -->
            <BusinessNetworkPostMediaGallery
              v-if="post?.post_media?.length > 0"
              :post="post"
              @open-media="openMedia"
            />

            <!-- Post Actions -->
            <BusinessNetworkPostActions
              :post="post"
              :user="user"
              @toggle-like="toggleLike"
              @open-likes-modal="openLikesModal"
              @open-comments-modal="openCommentsModal"
              @share-post="sharePost"
              @toggle-save="toggleSave"
            />

            <!-- Comments Preview -->
            <BusinessNetworkPostComments
              v-if="post?.post_comments?.length > 0"
              :post="post"
              :user="user"
              @open-comments-modal="openCommentsModal"
              @edit-comment="editComment"
              @delete-comment="deleteComment"
              @cancel-edit-comment="cancelEditComment"
              @save-edit-comment="saveEditComment"
            />

            <!-- Add Comment Input -->
            <BusinessNetworkPostCommentInput
              v-if="user"
              :post="post"
              :user="user"
              :show-mentions="showMentions"
              :mention-suggestions="mentionSuggestions"
              :active-mention-index="activeMentionIndex"
              :mention-input-position="mentionInputPosition"
              @add-comment="addComment"
              @handle-comment-input="handleCommentInput"
              @handle-mention-keydown="handleMentionKeydown"
              @select-mention="selectMention"
            />
          </div>
        </div>

        <!-- Sponsored Products Section -->
        <BusinessNetworkProductSection
          v-if="(index + 1) % randomInterval === 0"
          :products="getRandomProducts(index % 2 === 0 ? 3 : 2)"
        />
      </div>

      <div v-if="loading" class="flex justify-center py-6">
        <div class="h-6 w-6 animate-spin text-blue-600">
          <Loader2 />
        </div>
      </div>

      <div
        v-if="!loading && posts?.length === 0"
        class="flex flex-col items-center justify-center py-12 text-center"
      >
        <p class="text-gray-500 mb-2">{{ $t("no_post_available") }}</p>
      </div>
    </div>

    <!-- Media Viewer Component -->
    <BusinessNetworkMediaViewer
      :active-media="activeMedia"
      :active-post="activePost"
      :active-media-index="activeMediaIndex"
      :media-comment-text="mediaCommentText"
      @update:media-comment-text="mediaCommentText = $event"
      :user="user"
      @close-media="closeMedia"
      @navigate-media="navigateMedia"
      @toggle-media-like="toggleMediaLike"
      @open-media-likes-modal="openMediaLikesModal"
      @add-media-comment="addMediaComment"
      @edit-media-comment="editMediaComment"
      @delete-media-comment="deleteMediaComment"
    />

    <!-- All Modals -->
    <BusinessNetworkPostModals
      ref="modalsRef"
      :active-likes-post="activeLikesPost"
      :active-comments-post="activeCommentsPost"
      :active-media-likes="activeMediaLikes"
      :media-liked-users="mediaLikedUsers"
      :comment-to-delete="commentToDelete"
      :user="user"
      :show-mentions="showMentions"
      :mention-suggestions="mentionSuggestions"
      :active-mention-index="activeMentionIndex"
      :mention-input-position="mentionInputPosition"
      @close-likes-modal="activeLikesPost = null"
      @toggle-user-follow="toggleUserFollow"
      @close-comments-modal="activeCommentsPost = null"
      @handle-comment-input="handleCommentInput"
      @handle-mention-keydown="handleMentionKeydown"
      @add-comment="addComment"
      @close-media-likes-modal="activeMediaLikes = null"
      @cancel-delete-comment="commentToDelete = null"
      @confirm-delete-comment="confirmDeleteComment"
      @edit-comment="editComment"
      @delete-comment="deleteComment"
      @cancel-edit-comment="cancelEditComment"
      @save-edit-comment="saveEditComment"
    />

    <!-- Create Post Modal -->
    <BusinessNetworkCreatePost
      :createPostContent="createPostContent"
      :createPostCategories="createPostCategories"
      :isSubmitting="isSubmitting"
      :isCreatePostOpen="isCreatePostOpen"
      :createPostTitle="createPostTitle"
    />
  </div>
</template>

<script setup>
import {
  Search,
  X,
  Clock,
  ArrowRight,
  Heart,
  MessageCircle,
  Share2,
  Bookmark,
  Check,
  UserPlus,
  MoreHorizontal,
  Link2,
  Flag,
  Send,
  Plus,
  Home,
  Bell,
  User,
  BarChart2,
  Download,
  ChevronLeft,
  ChevronRight,
  Loader2,
  ImageIcon,
  Smile,
  Paperclip,
  Tag,
  UserX,
} from "lucide-vue-next";

// Props
const props = defineProps({
  posts: {
    type: Array,
    default: () => [],
  },
  id: {
    type: String,
    required: true,
  },
});

// Get auth and API utilities
const { user } = useAuth();
const { post, del, put, get } = useApi();
const toast = useToast();

// State
const loading = ref(false);
const isSearchOpen = ref(false);

const searchInputRef = ref(null);
const activeMedia = ref(null);
const activePost = ref(null);
const activeMediaIndex = ref(0);
const mediaCommentText = ref("");
const isCreatePostOpen = ref(false);
const createPostTitle = ref("");
const createPostContent = ref("");
const createPostCategories = ref([]);
const categoryInput = ref("");
const showEmojiPicker = ref(false);
const selectedMedia = ref([]);
const fileInputRef = ref(null);
const isSubmitting = ref(false);
const activeLikesPost = ref(null);
const activeCommentsPost = ref(null);
const activeMediaLikes = ref(null);
const mediaLikedUsers = ref([]);
const commentToDelete = ref(null);
const postWithCommentToDelete = ref(null);
const modalsRef = ref(null);

// Mention state
const mentionSearchText = ref("");
const mentionSuggestions = ref([]);
const showMentions = ref(false);
const mentionInputPosition = ref(null);
const activeMentionIndex = ref(0);

// Sponsored Products
const allProducts = ref([]);
const shuffledProducts = ref([]);
const isLoadingProducts = ref(false);
const randomInterval = ref(5 + Math.floor(Math.random() * 4)); // Random interval between 5-8

// Main methods
const toggleFollow = async (currentPost) => {
  try {
    const response = await post(`/bn/posts/${currentPost.id}/follow/`, {
      user_id: user?.user?.id,
    });
    if (response && response.data) {
      console.log("Follow toggled successfully:", response.data);
    } else {
      console.error("Failed to toggle follow:", response);
    }
  } catch (error) {
    console.error("Error toggling follow:", error);
  }
};

// Toggle user follow
const toggleUserFollow = (user) => {
  user.isFollowing = !user.isFollowing;
};

// Toggle like
const toggleLike = async (currentPost) => {
  // Check if user is logged in
  if (!user?.value?.user?.id) {
    toast.add({ title: "Please login to like posts" });
    return;
  }

  // Prevent multiple clicks
  if (currentPost.isLikeLoading) return;
  currentPost.isLikeLoading = true;

  // Store the original state to revert in case of API error
  const wasLiked = currentPost.post_likes?.some(
    (like) => like.user === user.value?.user?.id
  );

  try {
    if (wasLiked) {
      // Optimistically update UI first
      currentPost.post_likes = currentPost.post_likes.filter(
        (like) => like.user !== user.value?.user?.id
      );

      // Then make API call
      const response = await del(`/bn/posts/${currentPost.id}/unlike/`);

      // Check if API call failed
      if (!response) {
        // Revert UI if API fails
        if (
          !currentPost.post_likes.some(
            (like) => like.user === user.value?.user?.id
          )
        ) {
          currentPost.post_likes.push({
            user: user.value?.user?.id,
            user_details: {
              name: user.value?.user?.name,
              image: user.value?.user?.image,
            },
          });
        }
      }
    } else {
      // Optimistically update UI first
      if (!currentPost.post_likes) {
        currentPost.post_likes = [];
      }

      currentPost.post_likes.push({
        user: user.value?.user?.id,
        user_details: {
          name: user.value?.user?.name,
          image: user.value?.user?.image,
        },
      });

      // Then make API call
      const response = await post(`/bn/posts/${currentPost.id}/like/`);
      if (!response) {
        // Revert UI if API fails
        currentPost.post_likes = currentPost.post_likes.filter(
          (like) => like.user !== user.value?.user?.id
        );
      }
    }
  } catch (error) {
    console.error("Error toggling like:", error);
    // Revert UI on error
    if (wasLiked) {
      // Re-add like if we were removing it
      if (
        !currentPost.post_likes.some(
          (like) => like.user === user.value?.user?.id
        )
      ) {
        currentPost.post_likes.push({
          user: user.value?.user?.id,
          user_details: {
            name: user.value?.user?.name,
            image: user.value?.user?.image,
          },
        });
      }
    } else {
      // Remove like if we were adding it
      currentPost.post_likes = currentPost.post_likes.filter(
        (like) => like.user !== user.value?.user?.id
      );
    }
    toast.add({
      title: "Error",
      description: "Failed to update like",
      color: "red",
    });
  } finally {
    currentPost.isLikeLoading = false;
  }
};

// Toggle media like
const toggleMediaLike = async () => {
  if (!activeMedia.value) return;
  if (!user.value) {
    toast.add({ title: "Please login to like media" });
    return;
  }

  // Prevent multiple clicks
  if (activeMedia.value.isLikeLoading) return;
  activeMedia.value.isLikeLoading = true;

  // Store the original state to revert in case of API error
  const wasLiked = activeMedia.value.media_likes?.some(
    (like) => like.user === user.value?.user?.id
  );

  try {
    if (wasLiked) {
      // Optimistically update UI first
      activeMedia.value.media_likes = activeMedia.value.media_likes.filter(
        (like) => like.user !== user.value?.user?.id
      );

      // Then make API call
      const response = await del(`/bn/media/${activeMedia.value.id}/unlike/`);

      // Check if API call failed
      if (!response) {
        // Revert UI if API fails
        if (
          !activeMedia.value.media_likes.some(
            (like) => like.user === user.value?.user?.id
          )
        ) {
          activeMedia.value.media_likes.push({
            user: user.value?.user?.id,
            user_details: {
              name: user.value?.user?.name,
              image: user.value?.user?.image,
            },
          });
        }
      }

      // Update likedBy array if used for UI
      if (activeMedia.value.likedBy) {
        activeMedia.value.likedBy = activeMedia.value.likedBy.filter(
          (u) => u.id !== (user.value?.user?.id || "current-user")
        );
      }
    } else {
      // Optimistically update UI first
      if (!activeMedia.value.media_likes) {
        activeMedia.value.media_likes = [];
      }

      activeMedia.value.media_likes.push({
        user: user.value?.user?.id,
        user_details: {
          name: user.value?.user?.name,
          image: user.value?.user?.image,
        },
      });

      // Then make API call
      const response = await post(`/bn/media/${activeMedia.value.id}/like/`);

      // Check if API call failed
      if (!response) {
        // Revert UI if API fails
        activeMedia.value.media_likes = activeMedia.value.media_likes.filter(
          (like) => like.user !== user.value?.user?.id
        );
      }

      // Update likedBy array if used for UI
      if (!activeMedia.value.likedBy) {
        activeMedia.value.likedBy = [];
      }

      activeMedia.value.likedBy?.unshift({
        id: user.value?.user?.id || "current-user",
        fullName: user.value?.user?.name || "You",
        image:
          user.value?.user?.image ||
          "/images/placeholder.jpg?height=40&width=40",
        isFollowing: false,
      });
    }
  } catch (error) {
    console.error("Error toggling media like:", error);

    // Revert UI on error
    if (wasLiked) {
      // Re-add like if we were removing it
      if (
        !activeMedia.value.media_likes.some(
          (like) => like.user === user.value?.user?.id
        )
      ) {
        activeMedia.value.media_likes.push({
          user: user.value?.user?.id,
          user_details: {
            name: user.value?.user?.name,
            image: user.value?.user?.image,
          },
        });
      }
    } else {
      // Remove like if we were adding it
      activeMedia.value.media_likes = activeMedia.value.media_likes.filter(
        (like) => like.user !== user.value?.user?.id
      );
    }

    // Show error notification
    toast.add({
      title: "Error",
      description: "Failed to update like",
      color: "red",
      timeout: 3000,
    });
  } finally {
    // Reset loading state
    activeMedia.value.isLikeLoading = false;
  }
};

// Toggle save
const toggleSave = (post) => {
  post.isSaved = !post.isSaved;
  post.showDropdown = false;
};

// Toggle dropdown
const toggleDropdown = (post) => {
  // Close all other dropdowns first
  props.posts.forEach((p) => {
    if (p.id !== post.id) p.showDropdown = false;
  });

  post.showDropdown = !post.showDropdown;
};

// Toggle description
const toggleDescription = (post) => {
  post.showFullDescription = !post.showFullDescription;
};

// Copy link
const copyLink = (post) => {
  const postUrl = `${window.location.origin}/post/${post.id}`;
  navigator.clipboard.writeText(postUrl);
  toast.add({ title: "Link copied to clipboard" });
  post.showDropdown = false;
};

// Share post
const sharePost = (post) => {
  const postUrl = `${window.location.origin}/post/${post.slug}`;

  if (navigator.share && navigator.canShare) {
    navigator
      .share({
        title: post.title,
        text:
          post.content.substring(0, 100) +
          (post.content.length > 100 ? "..." : ""),
        url: postUrl,
      })
      .catch((error) => console.error("Error sharing:", error));
  } else {
    toast.add({ title: `Share URL: ${postUrl}` });
  }
};

// Media methods
const openMedia = (post, index) => {
  activePost.value = post;
  activeMediaIndex.value = index;
  activeMedia.value = post.post_media[index];
};

const closeMedia = () => {
  activeMedia.value = null;
  activePost.value = null;
};

const navigateMedia = (direction) => {
  if (!activePost.value || !activeMedia.value) return;

  const currentIndex = activeMediaIndex.value;
  const totalMedia = activePost.value.post_media.length;

  if (direction === "prev") {
    activeMediaIndex.value = (currentIndex - 1 + totalMedia) % totalMedia;
  } else {
    activeMediaIndex.value = (currentIndex + 1) % totalMedia;
  }

  activeMedia.value = activePost.value.post_media[activeMediaIndex.value];
};

// Modal methods
const openLikesModal = (post) => {
  activeLikesPost.value = post;
};

const openCommentsModal = (post) => {
  activeCommentsPost.value = post;

  // Wait for DOM update then scroll to bottom
  nextTick(() => {
    scrollToLatestComment();
  });
};

const scrollToLatestComment = () => {
  if (modalsRef.value?.commentsContainerRef) {
    modalsRef.value.commentsContainerRef.scrollTop =
      modalsRef.value.commentsContainerRef.scrollHeight;
  }
};

const openMediaLikesModal = () => {
  if (!activeMedia.value || !activeMedia.value.likedBy) return;

  mediaLikedUsers.value = activeMedia.value.likedBy;
  activeMediaLikes.value = activeMedia.value;
};

// Comment methods
const addComment = async (currentPost) => {
  // Check if user is logged in
  if (!user?.value?.user?.id) {
    toast.add({ title: "Please login to comment" });
    return;
  }

  if (!currentPost?.commentText?.trim()) return;

  // Set loading state
  currentPost.isCommentLoading = true;

  const commentText = currentPost.commentText.trim();

  // Create a temporary comment to show immediately
  const tempComment = {
    id: `temp-${Date.now()}`,
    author: user.value.user.id,
    content: commentText,
    created_at: new Date().toISOString(),
    author_details: {
      name: user.value.user.name,
      image: user.value.user.image,
      kyc: user.value.user.kyc || false,
    },
    // Add needed properties for UI
    isEditing: false,
    isDeleting: false,
    isSaving: false,
  };

  // Add to UI immediately
  if (!currentPost.post_comments) {
    currentPost.post_comments = [];
  }

  // Add to beginning of array for newest first
  currentPost.post_comments.unshift(tempComment);

  // Clear input field
  currentPost.commentText = "";

  // Scroll to the latest comment if in modal view
  if (currentPost === activeCommentsPost.value) {
    nextTick(() => {
      scrollToLatestComment();
    });
  }

  try {
    // Make API call to add comment
    const response = await post(`/bn/posts/${currentPost.id}/comments/`, {
      content: commentText,
    });

    // If successful, replace temp comment with real one from API
    if (response.data) {
      const index = currentPost.post_comments.findIndex(
        (c) => c.id === tempComment.id
      );
      if (index !== -1) {
        // Replace with actual comment data from API
        currentPost.post_comments[index] = response.data;
      }

      // Show success toast
      toast.add({
        description: "Comment posted!",
        color: "green",
        timeout: 3000,
      });
    } else {
      // Remove temp comment if API failed
      currentPost.post_comments = currentPost.post_comments.filter(
        (comment) => comment.id !== tempComment.id
      );
      console.error("Failed to add comment:", response);

      // Show error toast
      toast.add({
        title: "Error",
        description: "Failed to post comment",
        color: "red",
        timeout: 3000,
      });
    }
  } catch (error) {
    // Remove temp comment on error
    currentPost.post_comments = currentPost.post_comments.filter(
      (comment) => comment.id !== tempComment.id
    );
    console.error("Error adding comment:", error);

    // Show error toast
    toast.add({
      title: "Error",
      description:
        "Failed to post comment: " + (error.message || "Unknown error"),
      color: "red",
      timeout: 5000,
    });
  } finally {
    // Reset loading state
    currentPost.isCommentLoading = false;
  }
};

const editComment = (post, comment) => {
  if (!post || !comment || !user?.value?.user?.id) return;

  // Set editing mode and store original text for cancellation
  comment.isEditing = true;
  comment.editText = comment.content;

  // Focus on textarea after Vue updates the DOM
  nextTick(() => {
    const textarea = document.querySelector(`#comment-edit-${comment.id}`);
    if (textarea) {
      textarea.focus();
    }
  });
};

const cancelEditComment = (comment) => {
  comment.isEditing = false;
  comment.editText = null;
};

const saveEditComment = async (currentPost, comment) => {
  if (!comment.editText?.trim() || comment.editText === comment.content) {
    cancelEditComment(comment);
    return;
  }

  // Add saving state
  comment.isSaving = true;
  const originalContent = comment.content;

  try {
    // Optimistically update UI
    comment.content = comment.editText.trim();
    comment.isEditing = false;

    // Make API call to update comment
    const response = await put(`/bn/comments/${comment.id}/`, {
      content: comment.editText.trim(),
    });

    if (!response || !response.data) {
      // Revert on failure
      comment.content = originalContent;
      console.error("Failed to update comment");
      // Show error toast
      toast.add({
        title: "Error",
        description: "Failed to update comment",
        color: "red",
        timeout: 3000,
      });
    } else {
      // Show success toast
      toast.add({
        title: "Success",
        description: "Comment updated successfully",
        color: "green",
        timeout: 3000,
      });
    }
  } catch (error) {
    // Revert on error
    comment.content = originalContent;
    console.error("Error updating comment:", error);
    // Show error toast
    toast.add({
      title: "Error",
      description:
        "Failed to update comment: " + (error.message || "Unknown error"),
      color: "red",
      timeout: 5000,
    });
  } finally {
    // Always reset the saving state
    comment.isSaving = false;
  }
};

const deleteComment = (post, comment) => {
  commentToDelete.value = comment;
  postWithCommentToDelete.value = post;
};

const confirmDeleteComment = async () => {
  if (
    !commentToDelete.value ||
    !postWithCommentToDelete.value ||
    !user?.value?.user?.id
  )
    return;

  const comment = commentToDelete.value;
  const post = postWithCommentToDelete.value;

  // Set loading state
  comment.isDeleting = true;

  try {
    // Close modal first
    commentToDelete.value = null;
    postWithCommentToDelete.value = null;

    // Make API call to delete comment
    const response = await del(`/bn/comments/${comment.id}/`);

    // On success, remove from UI
    if (response) {
      // Update the UI by filtering out the deleted comment
      post.post_comments = post.post_comments.filter(
        (c) => c.id !== comment.id
      );
      console.log("Comment deleted successfully");

      // Show success toast
      toast.add({
        title: "Success",
        description: "Comment deleted successfully",
        color: "green",
        timeout: 3000,
      });
    } else {
      console.error("Failed to delete comment - API returned no response");

      // Show error toast
      toast.add({
        title: "Error",
        description: "Failed to delete comment",
        color: "red",
        timeout: 3000,
      });
    }
  } catch (error) {
    console.error("Error deleting comment:", error);

    // Show error toast
    toast.add({
      title: "Error",
      description:
        "Failed to delete comment: " + (error.message || "Unknown error"),
      color: "red",
      timeout: 5000,
    });
  } finally {
    // Reset loading state if the comment still exists
    if (comment) {
      comment.isDeleting = false;
    }
  }
};

// Media comment methods
const addMediaComment = async () => {
  // Check if user is logged in
  if (!user?.value?.user?.id || !activeMedia.value) {
    toast.add({ title: "Please login to comment" });
    return;
  }

  if (!mediaCommentText.value.trim()) return;

  // Store comment text and clear input immediately for better UX
  const commentText = mediaCommentText.value.trim();
  mediaCommentText.value = "";

  // Create a temporary comment to show immediately
  const tempComment = {
    id: `temp-${Date.now()}`,
    author: user.value.user.id,
    content: commentText,
    created_at: new Date().toISOString(),
    author_details: {
      id: user.value.user.id,
      name: user.value.user.name,
      image: user.value.user.image,
      kyc: user.value.user.kyc || false,
    },
    isDeleting: false,
  };

  // Add to UI immediately
  if (!activeMedia.value.media_comments) {
    activeMedia.value.media_comments = [];
  }

  activeMedia.value.media_comments.unshift(tempComment);

  try {
    // Make API call to add comment
    const response = await post(`/bn/media/${activeMedia.value.id}/comments/`, {
      content: commentText,
    });

    // If successful, replace temp comment with real one from API
    if (response.data) {
      const index = activeMedia.value.media_comments.findIndex(
        (c) => c.id === tempComment.id
      );
      if (index !== -1) {
        // Replace with actual comment data from API
        activeMedia.value.media_comments[index] = response.data;
      }

      // Show success toast
      toast.add({
        title: "Comment posted",
        color: "green",
        timeout: 3000,
      });
    } else {
      // Remove temp comment if API failed
      activeMedia.value.media_comments =
        activeMedia.value.media_comments.filter(
          (comment) => comment.id !== tempComment.id
        );

      // Show error toast
      toast.add({
        title: "Error",
        description: "Failed to post comment",
        color: "red",
        timeout: 3000,
      });
    }
  } catch (error) {
    console.error("Error adding media comment:", error);

    // Remove temp comment on error
    activeMedia.value.media_comments = activeMedia.value.media_comments.filter(
      (comment) => comment.id !== tempComment.id
    );

    // Show error toast
    toast.add({
      title: "Error",
      description:
        "Failed to post comment: " + (error.message || "Unknown error"),
      color: "red",
      timeout: 5000,
    });
  }
};

const editMediaComment = (comment) => {
  if (!comment || !user?.value?.user?.id) return;

  // Set editing mode and store original text for cancellation
  comment.isEditing = true;
  comment.editText = comment.content;

  // Focus on textarea after Vue updates the DOM
  nextTick(() => {
    const textarea = document.querySelector(
      `#media-comment-edit-${comment.id}`
    );
    if (textarea) {
      textarea.focus();
    }
  });
};

const deleteMediaComment = (comment) => {
  if (!comment || !user?.value?.user?.id) return;

  // Set the comment to delete
  mediaCommentToDelete.value = comment;
};

// Implement mention handling functions
const handleCommentInput = (e, currentPost) => {
  const input = e.target;
  const text = input.value;
  const cursorPosition = input.selectionStart;

  // Check if we're typing a mention
  const textBeforeCursor = text.slice(0, cursorPosition);
  const mentionMatch = textBeforeCursor.match(/(?:^|\s)@(\w*)$/);

  if (mentionMatch) {
    // Extract the search text after @
    const searchText = mentionMatch[1].toLowerCase();
    mentionSearchText.value = searchText;

    // Store input position info
    mentionInputPosition.value = { post: currentPost, input: input };

    // Search for users matching the text
    searchMentionUsers(searchText);

    // Show mention dropdown
    showMentions.value = true;
    activeMentionIndex.value = 0;
  } else {
    // Hide mentions when not typing @
    showMentions.value = false;
  }
};

const searchMentionUsers = async (searchText) => {
  try {
    // Replace with your actual user search API
    const response = await post(`/bn/users/search/`, {
      search: searchText,
      limit: 5,
    });

    if (response?.data) {
      mentionSuggestions.value = response.data;
    } else {
      // Fallback to mock data for testing
      mentionSuggestions.value = [
        { id: 1, name: "John Smith", image: "https://via.placeholder.com/40" },
        { id: 2, name: "Jane Doe", image: "https://via.placeholder.com/40" },
        { id: 3, name: "James Brown", image: "https://via.placeholder.com/40" },
      ].filter((user) =>
        user.name.toLowerCase().includes(searchText.toLowerCase())
      );
    }
  } catch (error) {
    console.error("Error searching users:", error);
    mentionSuggestions.value = [];
  }
};

const selectMention = (user, currentPost) => {
  if (!mentionInputPosition.value || !mentionInputPosition.value.input) return;

  const input = mentionInputPosition.value.input;
  const text = input.value;
  const cursorPosition = input.selectionStart;

  // Find the start of the mention
  const textBeforeCursor = text.slice(0, cursorPosition);
  const atIndex = textBeforeCursor.lastIndexOf("@");

  // Replace the @searchText with the selected user
  const newText =
    text.slice(0, atIndex) +
    `@${user.name.replace(/\s+/g, "")} ` +
    text.slice(cursorPosition);

  // Update the input value
  currentPost.commentText = newText;

  // Close the mentions dropdown
  showMentions.value = false;

  // Move cursor after the inserted mention
  nextTick(() => {
    if (input) {
      const newPosition = atIndex + user.name.replace(/\s+/g, "").length + 2; // +2 for @ and space
      input.setSelectionRange(newPosition, newPosition);
      input.focus();
    }
  });
};

const handleMentionKeydown = (e, currentPost) => {
  if (!showMentions.value || mentionSuggestions.value.length === 0) return;

  // Arrow down
  if (e.key === "ArrowDown") {
    e.preventDefault(); // Prevent cursor movement
    activeMentionIndex.value =
      (activeMentionIndex.value + 1) % mentionSuggestions.value.length;
  }

  // Arrow up
  else if (e.key === "ArrowUp") {
    e.preventDefault(); // Prevent cursor movement
    activeMentionIndex.value =
      (activeMentionIndex.value - 1 + mentionSuggestions.value.length) %
      mentionSuggestions.value.length;
  }

  // Enter or Tab to select
  else if ((e.key === "Enter" || e.key === "Tab") && showMentions.value) {
    e.preventDefault();
    selectMention(
      mentionSuggestions.value[activeMentionIndex.value],
      currentPost
    );
  }

  // Escape to cancel
  else if (e.key === "Escape") {
    showMentions.value = false;
  }
};

// Product methods
const fetchProducts = async () => {
  isLoadingProducts.value = true;
  try {
    const { data } = await get("/all-products/");
    if (
      data &&
      (Array.isArray(data) || (data.results && Array.isArray(data.results)))
    ) {
      allProducts.value = Array.isArray(data) ? data : data.results;
      shuffledProducts.value = getRandomProducts();
    } else {
      console.error("Unexpected product data format:", data);
      allProducts.value = [];
    }
  } catch (error) {
    console.error("Error fetching products:", error);
    allProducts.value = [];
  } finally {
    isLoadingProducts.value = false;
  }
};

// Function to get random products
const getRandomProducts = (count = 3) => {
  if (allProducts.value.length === 0) {
    return [];
  }

  const shuffled = [...allProducts.value].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count); // Return exactly 'count' random products
};

// Additional methods for component functionality as needed
// ...

// Initialize
onMounted(() => {
  fetchProducts();

  // Implement infinite scroll (if needed)
  window.addEventListener("scroll", () => {
    if (
      window.innerHeight + window.scrollY >= document.body.offsetHeight - 500 &&
      !loading.value
    ) {
      // loadMorePosts(); (implementation would be needed)
    }
  });
});

// Expose methods that might be called from parent components
defineExpose({
  refreshPosts: async () => {
    try {
      const response = await get("/bn/posts/");
      // Handle the response appropriately
    } catch (error) {
      console.error("Failed to refresh posts:", error);
    }
  },
});
</script>

<style scoped>
.border-l-3 {
  border-left-width: 3px;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Add viewport control for mobile */
@media (max-width: 640px) {
  /* Ensure no overflowing content */
  .min-w-full {
    min-width: auto;
    width: 100%;
  }

  /* Fix horizontal scrolling issues */
  div,
  p,
  span {
    max-width: 100%;
    word-wrap: break-word;
    overflow-wrap: break-word;
  }
}
</style>
