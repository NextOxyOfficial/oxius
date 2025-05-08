<template>
  <div class="max-w-3xl pb-8 pt-3">
    <div class="space-y-6">
      <!-- Loop through posts and insert sponsored products after every 5 posts -->
      <template v-for="(post, index) in posts" :key="post.id">
        <!-- Post Card with glassmorphism effect -->
        <div
          class="transform transition-all duration-300 bg-white/90 dark:bg-slate-800/90 rounded-xl border border-gray-200/50 dark:border-gray-700/50 overflow-hidden backdrop-blur-md shadow-sm hover:shadow-sm dark:shadow-slate-800/20"
          :style="{
            animationDelay: `${index * 0.05}s`,
            animation: `fadeIn 0.5s ease-out forwards`,
            backgroundImage:
              'radial-gradient(circle at top right, rgba(255, 255, 255, 0.1), transparent 70%), linear-gradient(to bottom right, rgba(255, 255, 255, 0.05), transparent)',
          }"
        >
          <div class="sm:px-4 pb-5 pt-0">
            <!-- Post Header -->
            <BusinessNetworkPostHeader
              :post="post?.post_details ? post.post_details : post"
              :user="user"
              @toggle-follow="toggleFollow"
              @toggle-dropdown="toggleDropdown"
              @toggle-save="toggleSave"
              @copy-link="copyLink"
            />

            <!-- Post Title with enhanced styling -->
            <NuxtLink
              :to="`/business-network/posts/${
                post?.post ? post.post : post.id
              }`"
              class="block text-sm sm:text-base font-semibold mb-1.5 hover:text-blue-600 transition-colors px-2 text-gray-800 dark:text-white hover:underline decoration-blue-500/50 decoration-2 underline-offset-2"
            >
              {{ post?.post_details ? post.post_details.title : post.title }}
            </NuxtLink>

            <!-- Tags with premium styling -->
            <div
              v-if="
                post?.post_details
                  ? post.post_details?.post_tags?.length > 0
                  : post?.post_tags?.length > 0
              "
              class="flex flex-wrap gap-1.5 mb-3 px-2"
            >
              <span
                v-for="(tag, idx) in post?.post_details
                  ? post.post_details?.post_tags
                  : post?.post_tags"
                :key="idx"
                class="text-xs bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/30 dark:to-blue-800/30 text-blue-600 dark:text-blue-400 px-2.5 py-0.5 rounded-full shadow-sm border border-blue-200/30 dark:border-blue-700/30 hover:shadow-md transition-all duration-300 transform hover:scale-105"
              >
                #{{ tag.tag }}
              </span>
            </div>

            <!-- Post Content with improved styling -->
            <div class="mb-3 min-w-full px-2">
              <p
                :class="[
                  'text-base text-gray-700 dark:text-gray-200 leading-relaxed',
                  !post.showFullDescription && 'line-clamp-4',
                ]"
                v-html="
                  post?.post_details ? post.post_details.content : post.content
                "
              ></p>
              <button
                v-if="
                  post?.post_details
                    ? post.post_details.content?.length > 160
                    : post.content?.length > 160
                "
                class="text-sm text-blue-600 dark:text-blue-400 font-medium mt-1.5 hover:text-blue-700 dark:hover:text-blue-300 transition-colors flex items-center"
                @click="toggleDescription(post)"
              >
                <span>{{
                  post.showFullDescription ? $t("read_less") : $t("read_more")
                }}</span>
                <UIcon
                  :name="
                    post.showFullDescription
                      ? 'i-heroicons-chevron-up'
                      : 'i-heroicons-chevron-down'
                  "
                  class="ml-1 w-4 h-4"
                />
              </button>
            </div>

            <!-- Media Gallery -->
            <BusinessNetworkPostMediaGallery
              v-if="
                post?.post_details
                  ? post.post_details.post_media.length > 0
                  : post?.post_media?.length > 0
              "
              :post="post.post_details ? post.post_details : post"
              @open-media="openMedia"
            />

            <!-- Post Actions -->
            <BusinessNetworkPostActions
              :post="post.post_details ? post.post_details : post"
              :user="user"
              @toggle-like="toggleLike"
              @open-likes-modal="openLikesModal"
              @open-comments-modal="openCommentsModal"
              @share-post="sharePost"
              @toggle-save="toggleSave"
            />

            <!-- Comments Preview -->
            <BusinessNetworkPostComments
              v-if="
                post?.post_details
                  ? post.post_details.post_comments.length > 0
                  : post?.post_comments?.length > 0
              "
              :post="post.post_details ? post.post_details : post"
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
              :post="post.post_details ? post.post_details : post"
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

        <!-- Sponsored Products Section - Show after every 5th post with enhanced design -->
        <BusinessNetworkProductSection
          v-if="(index + 1) % 5 === 0 || (index === 0 && posts.length === 1)"
          :key="`sponsored-${index}`"
          :products="getRandomProducts(3)"
          class="mt-4 transform transition-all duration-300"
          :style="{
            animationDelay: `${(index + 1) * 0.05}s`,
            animation: `fadeIn 0.5s ease-out forwards`,
          }"
        />
      </template>

      <!-- Loading spinner with premium styling -->
      <div v-if="loading" class="flex justify-center py-8">
        <div class="relative">
          <div class="h-10 w-10 animate-spin text-blue-600">
            <Loader2 class="h-10 w-10" />
          </div>
          <div
            class="absolute inset-0 animate-ping-sm opacity-70 rounded-full bg-blue-400/20 h-10 w-10"
          ></div>
        </div>
      </div>

      <!-- Empty state with better styling -->
      <div
        v-if="!loading && posts?.length === 0"
        class="flex flex-col items-center justify-center py-12 text-center bg-gray-50/50 dark:bg-slate-800/50 backdrop-blur-sm rounded-xl border border-gray-100 dark:border-slate-700/50 shadow-md"
      >
        <UIcon
          name="i-heroicons-document-text"
          class="w-12 h-12 text-gray-300 dark:text-gray-600 mb-3"
        />
        <p class="text-gray-500 dark:text-gray-400 mb-2 font-medium">
          {{ $t("no_post_available") }}
        </p>
        <p class="text-gray-400 dark:text-gray-500 text-sm">
          Check back later for new updates
        </p>
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
import { Loader2 } from "lucide-vue-next";

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
const mediaCommentToDelete = ref(null);

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
const productCache = ref(new Map()); // Cache for product display consistency

// Function to get random products with caching for consistent batch display
const getRandomProducts = (count = 3) => {
  if (allProducts.value.length === 0) {
    return [];
  }

  // Generate a cache key based on the current view
  const cacheKey = `batch-${Math.floor(Date.now() / 10000)}`; // Changes every 10 seconds

  // Check if we already have products for this batch in cache
  if (!productCache.value.has(cacheKey)) {
    // If not in cache, create a new random selection
    const shuffled = [...allProducts.value].sort(() => 0.5 - Math.random());
    productCache.value.set(cacheKey, shuffled);

    // Limit cache size to prevent memory issues
    if (productCache.value.size > 10) {
      const oldestKey = productCache.value.keys().next().value;
      productCache.value.delete(oldestKey);
    }
  }

  // Get products from cache
  const cachedProducts = productCache.value.get(cacheKey);
  return cachedProducts.slice(0, count);
};

// Pre-process posts to ensure they have necessary details
const processPosts = () => {
  // ...existing code...
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

// Initialize
onMounted(() => {
  fetchProducts();
  processPosts(); // Process posts when component mounts
});

// Watch for changes in the posts prop
watch(
  () => props.posts,
  (newPosts) => {
    if (newPosts && newPosts.length > 0) {
      processPosts(); // Process posts when they change
    }
  },
  { deep: true }
);

// Toggle post description expand/collapse
const toggleDescription = (post) => {
  post.showFullDescription = !post.showFullDescription;
};

// Handle post interactions
const toggleFollow = async (post) => {
  const authorId = post.author_details?.id;
  if (!authorId) return;

  try {
    const isFollowing = post.author_details.is_following;
    const endpoint = `/bn/follow/${authorId}/`;

    if (isFollowing) {
      const { data } = await del(endpoint);
      post.author_details.is_following = false;
      toast.add({ title: "Unfollowed user", color: "gray" });
    } else {
      const { data } = await post(endpoint);
      post.author_details.is_following = true;
      toast.add({ title: "Following user", color: "blue" });
    }
  } catch (error) {
    console.error("Error toggling follow:", error);
    toast.add({
      title: "Failed to update follow status",
      color: "red",
    });
  }
};

const toggleDropdown = (clickedPost) => {
  // Close other dropdowns
  props.posts.forEach((p) => {
    if (p.id !== clickedPost.id) p.showDropdown = false;
  });
  // Toggle this dropdown
  clickedPost.showDropdown = !clickedPost.showDropdown;
};

const toggleSave = async (postToSave) => {
  if (!user.value?.user) {
    toast.add({
      title: "You must be logged in to save posts",
    });
    return;
  }
  try {
    const endpoint = `/bn/posts/${postToSave.id}/save/`;
    const postIsSaved = postToSave.isSaved;

    if (postIsSaved) {
      await del(endpoint);
      postToSave.isSaved = false;
      toast.add({ title: "Post removed from saved items", color: "gray" });
    } else {
      await post(endpoint);
      postToSave.isSaved = true;
      toast.add({ title: "Post saved", color: "green" });
    }
  } catch (error) {
    console.error("Error saving post:", error);
    toast.add({
      title: "Failed to save post",
      color: "red",
    });
  }
};

const copyLink = (postToCopy) => {
  const postUrl = `${window.location.origin}/business-network/posts/${postToCopy.id}`;
  navigator.clipboard.writeText(postUrl);
  toast.add({
    title: "Link copied to clipboard",
  });
};

// Like functionality
const toggleLike = async (postToLike) => {
  if (!user.value?.user) {
    toast.add({
      title: "Please log in to like posts",
    });
    return;
  }
  if (postToLike.isLikeLoading) return;

  postToLike.isLikeLoading = true;

  try {
    const currentUserId = user.value?.user?.id;
    const isLiked = postToLike.post_likes?.some(
      (like) => like.user === currentUserId
    );

    if (isLiked) {
      // Use the unlike endpoint when already liked
      const endpoint = `/bn/posts/${postToLike.id}/unlike/`;
      await del(endpoint);

      // Remove user from likes
      postToLike.post_likes = postToLike.post_likes.filter(
        (like) => like.user !== currentUserId
      );

      // Update like count for UI if needed
      if (postToLike.likes_count !== undefined) {
        postToLike.likes_count = Math.max(0, (postToLike.likes_count || 0) - 1);
      }
    } else {
      // Use the like endpoint when not yet liked
      const endpoint = `/bn/posts/${postToLike.id}/like/`;
      const { data } = await post(endpoint);

      // Add new like data to the post
      if (!postToLike.post_likes) {
        postToLike.post_likes = [];
      }
      postToLike.post_likes.push(data);

      // Update like count for UI if needed
      if (postToLike.likes_count !== undefined) {
        postToLike.likes_count = (postToLike.likes_count || 0) + 1;
      }
    }
  } catch (error) {
    console.error("Error toggling like:", error);
    toast.add({
      title: "Failed to update like status",
      color: "red",
    });
  } finally {
    postToLike.isLikeLoading = false;
  }
};

// Comment functionality
const addComment = async (postToComment) => {
  if (!postToComment.commentText?.trim() || postToComment.isCommentLoading) {
    return;
  }
  console.log("add", postToComment);
  postToComment.isCommentLoading = true;

  try {
    const endpoint = `/bn/posts/${postToComment.id}/comments/`;
    const { data } = await post(endpoint, {
      content: postToComment.commentText,
    });

    // Initialize post_comments array if it doesn't exist
    if (!postToComment.post_comments) {
      postToComment.post_comments = [];
    }

    // Add the new comment to the beginning
    postToComment.post_comments.unshift(data);

    // Clear the comment text
    postToComment.commentText = "";

    // Close mentions dropdown if open
    showMentions.value = false;
  } catch (error) {
    console.error("Error adding comment:", error);
    toast.add({
      title: "Failed to add comment",
      color: "red",
    });
  } finally {
    postToComment.isCommentLoading = false;
  }
};

// Handle mentions and comment input
const handleCommentInput = (event, targetPost) => {
  targetPost.commentText = event.target.value;

  // Check for mention character (@)
  const cursorPos = event.target.selectionStart;
  const textBeforeCursor = targetPost.commentText.substring(0, cursorPos);
  const mentionMatch = textBeforeCursor.match(/@(\w*)$/);

  if (mentionMatch) {
    mentionSearchText.value = mentionMatch[1];
    showMentions.value = true;
    mentionInputPosition.value = {
      post: targetPost,
      startPos: cursorPos - mentionMatch[0].length,
      endPos: cursorPos,
    };

    // Search for users matching the mention text
    searchMentions(mentionSearchText.value);
  } else {
    showMentions.value = false;
  }
};

const handleMentionKeydown = (event, targetPost) => {
  if (!showMentions.value) return;

  // Handle arrow keys for mention selection
  if (event.key === "ArrowDown") {
    event.preventDefault();
    activeMentionIndex.value =
      (activeMentionIndex.value + 1) % mentionSuggestions.value.length;
  } else if (event.key === "ArrowUp") {
    event.preventDefault();
    activeMentionIndex.value =
      activeMentionIndex.value <= 0
        ? mentionSuggestions.value.length - 1
        : activeMentionIndex.value - 1;
  } else if (event.key === "Enter" && showMentions.value) {
    event.preventDefault();
    const selectedUser = mentionSuggestions.value[activeMentionIndex.value];
    if (selectedUser) {
      selectMention(selectedUser, targetPost);
    }
  } else if (event.key === "Escape") {
    showMentions.value = false;
  }
};

// Search for users to mention
const searchMentions = async (query) => {
  if (!query) {
    mentionSuggestions.value = [];
    return;
  }

  try {
    const { data } = await get(`/bn/mentions/?search=${query}`);
    mentionSuggestions.value = data || [];
    activeMentionIndex.value = 0;
  } catch (error) {
    console.error("Error searching mentions:", error);
    mentionSuggestions.value = [];
  }
};

const selectMention = (user, targetPost) => {
  if (!mentionInputPosition.value) return;

  const { startPos, endPos } = mentionInputPosition.value;
  const beforeMention = targetPost.commentText.substring(0, startPos);
  const afterMention = targetPost.commentText.substring(endPos);

  // Replace the mention with the user's name
  targetPost.commentText = `${beforeMention}@${user.follower_details.name} ${afterMention}`;

  // Reset mention state
  showMentions.value = false;
  mentionSuggestions.value = [];
};

// Modal handling
const openLikesModal = (postToView) => {
  activeLikesPost.value = postToView;
};

const openCommentsModal = (postToView) => {
  activeCommentsPost.value = postToView;

  // Set timeout to scroll to end of comments once modal is visible
  setTimeout(() => {
    if (modalsRef.value?.commentsContainerRef) {
      modalsRef.value.commentsContainerRef.scrollTop = 0;
    }
  }, 100);
};

const toggleUserFollow = async (userToFollow) => {
  try {
    const userId = userToFollow.user;

    if (userToFollow.isFollowing) {
      await del(`/bn/users/${userId}/unfollow/`);
      userToFollow.isFollowing = false;
    } else {
      await post(`/bn/users/${userId}/follow/`);
      userToFollow.isFollowing = true;
    }
  } catch (error) {
    console.error("Error toggling user follow:", error);
  }
};

// Media viewer functions
const openMedia = (postWithMedia, media) => {
  activeMedia.value = media;
  activePost.value = postWithMedia;
  activeMediaIndex.value = postWithMedia.post_media.findIndex(
    (m) => m.id === media.id
  );
};

const closeMedia = () => {
  activeMedia.value = null;
  activePost.value = null;
  activeMediaIndex.value = 0;
  mediaCommentText.value = "";
};

const navigateMedia = (direction) => {
  if (!activePost.value || !activePost.value.post_media) return;

  const totalMedia = activePost.value.post_media.length;

  if (direction === "next") {
    activeMediaIndex.value = (activeMediaIndex.value + 1) % totalMedia;
  } else {
    activeMediaIndex.value =
      (activeMediaIndex.value - 1 + totalMedia) % totalMedia;
  }

  activeMedia.value = activePost.value.post_media[activeMediaIndex.value];
};

const toggleMediaLike = async () => {
  if (!activeMedia.value) return;

  try {
    const endpoint = `/bn/media/${activeMedia.value.id}/like/`;
    const isLiked = activeMedia.value.media_likes?.some(
      (like) => like.user === user.value?.user?.id
    );

    if (isLiked) {
      await del(endpoint);
      // Remove user from likes
      activeMedia.value.media_likes = activeMedia.value.media_likes.filter(
        (like) => like.user !== user.value?.user?.id
      );
    } else {
      const { data } = await post(endpoint);
      // Add new like data
      if (!activeMedia.value.media_likes) {
        activeMedia.value.media_likes = [];
      }
      activeMedia.value.media_likes.push(data);
    }
  } catch (error) {
    console.error("Error toggling media like:", error);
  }
};

const openMediaLikesModal = () => {
  if (!activeMedia.value) return;

  activeMediaLikes.value = activeMedia.value;
  // Set liked users for the modal
  mediaLikedUsers.value = activeMedia.value.media_likes.map((like) => ({
    id: like.user_details.id,
    image: like.user_details.image,
    fullName: like.user_details.name,
    isFollowing: like.user_details.is_following,
  }));
};

const addMediaComment = async () => {
  if (!mediaCommentText.value.trim() || !activeMedia.value) return;

  try {
    const endpoint = `/bn/media/${activeMedia.value.id}/comments/`;
    const { data } = await post(endpoint, {
      content: mediaCommentText.value,
    });

    // Initialize media_comments array if it doesn't exist
    if (!activeMedia.value.media_comments) {
      activeMedia.value.media_comments = [];
    }

    // Add the new comment
    activeMedia.value.media_comments.push(data);

    // Clear the comment text
    mediaCommentText.value = "";
  } catch (error) {
    console.error("Error adding media comment:", error);
    toast.add({
      title: "Failed to add comment",
      color: "red",
    });
  }
};

const editMediaComment = async (comment) => {
  mediaCommentToDelete = comment;
};

const deleteMediaComment = async (comment) => {
  mediaCommentToDelete = comment;

  try {
    await del(`/bn/media-comments/${comment.id}/`);

    // Remove the comment from the list
    if (activeMedia.value && activeMedia.value.media_comments) {
      activeMedia.value.media_comments =
        activeMedia.value.media_comments.filter((c) => c.id !== comment.id);
    }

    mediaCommentToDelete = null;
  } catch (error) {
    console.error("Error deleting media comment:", error);
    toast.add({
      title: "Failed to delete comment",
      color: "red",
    });
  }
};

// Post comment edit/delete functions
const editComment = async (post, comment) => {
  // Make sure we initialize editText if it doesn't exist
  if (!comment.editText) {
    comment.editText = comment.content;
  }
  comment.isEditing = true;

  // try {
  //   // Set the comment text to the editText
  //   comment.content = comment.editText;
  //   const res = await put(`/bn/comments/${comment.id}/`, {
  //     ...comment,
  //     content: comment.editText,
  //   });
  //   if (res.data) {
  //     toast.add({
  //       title: "Comment edited successfully",
  //     });
  //   }
  // } catch (error) {
  //   console.error("Error editing comment:", error);
  //   toast.add({
  //     title: "Failed to edit comment",
  //   });
  // }
};

const deleteComment = (post, comment) => {
  commentToDelete.value = comment;
  postWithCommentToDelete.value = post;
};

const confirmDeleteComment = async () => {
  if (!commentToDelete.value || !postWithCommentToDelete.value) return;

  try {
    commentToDelete.value.isDeleting = true;

    await del(`/bn/comments/${commentToDelete.value.id}/`);

    // Remove the comment from the list
    if (
      postWithCommentToDelete.value &&
      postWithCommentToDelete.value.post_comments
    ) {
      postWithCommentToDelete.value.post_comments =
        postWithCommentToDelete.value.post_comments.filter(
          (c) => c.id !== commentToDelete.value.id
        );
    }

    toast.add({
      title: "Comment deleted",
    });
  } catch (error) {
    console.error("Error deleting comment:", error);
    toast.add({
      title: "Failed to delete comment",
      color: "red",
    });
  } finally {
    commentToDelete.value = null;
    postWithCommentToDelete.value = null;
  }
};

const cancelEditComment = (comment) => {
  comment.isEditing = false;
  comment.editText = ""; // Reset edit text
};

const saveEditComment = async (post, comment) => {
  if (!comment.editText?.trim()) return;

  comment.isSaving = true;

  try {
    const { data } = await put(`/bn/comments/${comment.id}/`, {
      ...comment,
      content: comment.editText,
    });

    // Update the comment content
    comment.content = data?.content;
    comment.isEditing = false;
    comment.editText = "";

    toast.add({
      title: "Comment updated",
      color: "green",
    });
  } catch (error) {
    console.error("Error updating comment:", error);
    toast.add({
      title: "Failed to update comment",
      color: "red",
    });
  } finally {
    comment.isSaving = false;
  }
};

// Post sharing function
const sharePost = (postToShare) => {
  const postUrl = `${window.location.origin}/business-network/posts/${postToShare.id}`;

  if (navigator.share) {
    navigator
      .share({
        title: postToShare.title,
        text: "Check out this post on Business Network",
        url: postUrl,
      })
      .catch((error) => console.log("Error sharing", error));
  } else {
    navigator.clipboard.writeText(postUrl);
    toast.add({
      title: "Link copied to clipboard",
      color: "blue",
    });
  }
};
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

@keyframes pulse {
  0%,
  100% {
    opacity: 0.5;
    transform: scale(1);
  }
  50% {
    opacity: 1;
    transform: scale(1.05);
  }
}

@keyframes ping-slow {
  0% {
    transform: scale(0.95);
    opacity: 1;
  }
  75%,
  100% {
    transform: scale(1.2);
    opacity: 0;
  }
}

@keyframes ping-sm {
  0% {
    transform: scale(0.95);
    opacity: 0.8;
  }
  75%,
  100% {
    transform: scale(1.15);
    opacity: 0;
  }
}

/* Add frosted glass effect base classes */
.glass-effect {
  @apply backdrop-blur-md bg-white/80 dark:bg-slate-800/80 border border-white/20 dark:border-slate-700/20 shadow-lg;
}

.premium-shadow {
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.05), 0 2px 6px rgba(0, 0, 0, 0.05),
    0 0 1px rgba(0, 0, 0, 0.1);
}

.dark .premium-shadow {
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15), 0 2px 6px rgba(0, 0, 0, 0.2),
    0 0 1px rgba(255, 255, 255, 0.05);
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
