<template>
  <div class="max-w-3xl pb-8">
    <!-- Gold Sponsors Slider -->
    <GoldSponsorsSlider class="mb-6" />

    <div class="space-y-6">
      <!-- Loop through posts and insert sponsored products after every 5 posts -->
      <template v-for="(post, index) in posts" :key="post.id">
        <!-- Post Card with glassmorphism effect -->
        <div
          :class="[
            'transform transition-all duration-300 bg-white/90 dark:bg-slate-800/90 rounded-xl overflow-hidden backdrop-blur-md shadow-sm hover:shadow-sm dark:shadow-slate-800/20',
            post.hasMatchingHashtag
              ? 'border-blue-300 border-2'
              : 'border border-gray-200/50 dark:border-gray-700/50',
          ]"
          :style="{
            animationDelay: `${index * 0.05}s`,
            animation: `fadeIn 0.5s ease-out forwards`,
            backgroundImage:
              'radial-gradient(circle at top right, rgba(255, 255, 255, 0.1), transparent 70%), linear-gradient(to bottom right, rgba(255, 255, 255, 0.05), transparent)',
          }"
        >
          <!-- Hashtag search indicator -->
          <div
            v-if="
              searchQuery &&
              searchQuery.startsWith('#') &&
              post.hasMatchingHashtag
            "
            class="absolute top-0 right-0 bg-blue-600 text-white px-2 py-1 text-xs font-medium rounded-bl"
          >
            <span class="flex items-center">
              <span class="mr-1">#</span>
              <span>{{ searchQuery.substring(1) }}</span>
            </span>
          </div>
          <div class=" pb-5 pt-0">
            <!-- Post Header -->
            <BusinessNetworkPostHeader
              :post="post?.post_details ? post.post_details : post"
              :user="user"
              @toggle-follow="toggleFollow"
              @toggle-dropdown="toggleDropdown"
              @toggle-save="toggleSave"
              @copy-link="copyLink"
              @post-updated="handlePostUpdate"
            />

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

            <!-- Tags with clean styling -->
            <div
              v-if="
                post?.post_details
                  ? post.post_details?.post_tags?.length > 0
                  : post?.post_tags?.length > 0
              "
              class="flex flex-wrap gap-1.5 mb-2 px-2"
            >
              <NuxtLink
                v-for="(tag, idx) in post?.post_details
                  ? post.post_details?.post_tags
                  : post?.post_tags"
                :key="idx"
                :to="`/business-network/search-results/${encodeURIComponent(
                  '#'
                )}${encodeURIComponent(tag.tag)}`"
                :class="[
                  'text-sm px-2 py-0.5 rounded-full transition-colors hashtag',
                  searchQuery &&
                  (searchQuery === '#' + tag.tag || searchQuery === tag.tag)
                    ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 font-medium border border-blue-200 dark:border-blue-700'
                    : 'text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300',
                ]"
              >
                #{{ tag.tag }}
              </NuxtLink>
            </div>
            <!-- Post Title with enhanced styling -->
            <NuxtLink
              :to="`/business-network/posts/${
                post?.post ? post.post : post.id
              }`"
              class="block text-base font-medium mb-1.5 hover:text-blue-600 transition-colors sm:px-4 px-2 text-gray-800 dark:text-white hover:underline decoration-blue-500/50 decoration-2 underline-offset-2"
            >
              {{ post?.post_details ? post.post_details.title : post.title }}
            </NuxtLink>
            <!-- Enhanced match indicators to show which fields matched the search -->
            <div
              v-if="searchQuery && searchQuery.trim() !== ''"
              class="flex flex-wrap gap-1.5 px-2 mb-2"
            >
              <span
                v-for="field in detectMatchedFields(
                  post?.post_details ? post.post_details : post
                )"
                :key="field"
                class="text-xs px-2 py-0.5 rounded-full flex items-center"
                :class="{
                  'bg-blue-100 text-blue-700 border border-blue-200':
                    field === 'author',
                  'bg-green-100 text-green-700 border border-green-200':
                    field === 'title',
                  'bg-yellow-100 text-yellow-700 border border-yellow-200':
                    field === 'content',
                  'bg-purple-100 text-purple-700 border border-purple-200':
                    field === 'hashtag',
                }"
              >
                <span v-if="field === 'author'" class="flex items-center">
                  <svg
                    class="h-3 w-3 mr-1"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                  </svg>
                  <span>Name Match</span>
                </span>
                <span v-else-if="field === 'title'" class="flex items-center">
                  <svg
                    class="h-3 w-3 mr-1"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path
                      d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"
                    ></path>
                    <path
                      d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"
                    ></path>
                  </svg>
                  <span>Title match</span>
                </span>
                <span v-else-if="field === 'content'" class="flex items-center">
                  <svg
                    class="h-3 w-3 mr-1"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path
                      d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0-2 2h12a2 2 0 0 0 2-2V8z"
                    ></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                    <polyline points="10 9 9 9 8 9"></polyline>
                  </svg>
                  <span>Content match</span>
                </span>
                <span v-else-if="field === 'hashtag'" class="flex items-center">
                  <svg
                    class="h-3 w-3 mr-1"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <line x1="4" y1="9" x2="20" y2="9"></line>
                    <line x1="4" y1="15" x2="20" y2="15"></line>
                    <line x1="10" y1="3" x2="8" y2="21"></line>
                    <line x1="16" y1="3" x2="14" y2="21"></line>
                  </svg>
                  <span>Hashtag match</span>
                </span>
              </span>
            </div>
            <!-- Post Content with improved styling and enhanced search term highlighting -->
            <div class="mb-3 min-w-full px-2">
              <!-- Enhanced title highlighting for search results -->
              <h3
                v-if="
                  searchQuery &&
                  (post?.post_details ? post.post_details.title : post.title)
                "
                class="text-sm font-medium text-gray-900 dark:text-gray-100 mb-1.5"
                v-html="
                  highlightSearchTerms(
                    post?.post_details ? post.post_details.title : post.title,
                    'title'
                  )
                "
              ></h3>

              <!-- Content with better highlighting -->
              <p
                :class="[
                  'text-base text-gray-800 dark:text-gray-300 leading-relaxed',
                  !post.showFullDescription && 'line-clamp-4',
                ]"
                v-html="
                  highlightSearchTerms(
                    post?.post_details
                      ? post.post_details.content
                      : post.content,
                    'content'
                  )
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

            <!-- Comments Preview -->
            <BusinessNetworkPostComments
              v-if="
                post?.post_details
                  ? (post.post_details.comment_count || 0) > 0
                  : (post?.comment_count || 0) > 0
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
              @add-comment="addComment"
              @handle-comment-input="handleCommentInput"
              @handle-mention-keydown="handleMentionKeydown"
              @select-mention="selectMention"
              @gift-sent="$emit('gift-sent', $event)"
            />
          </div>
        </div>
        <!-- User Suggestions Section - Show after every 10th post -->
        <BusinessNetworkUserSuggestions
          v-if="(index + 1) % 10 === 0 && user?.user?.id"
          :key="`suggestions-${index}`"
          :current-user-id="user?.user?.id"
          class="mt-4 transform transition-all duration-300"
          :style="{
            animationDelay: `${(index + 1) * 0.05}s`,
            animation: `fadeIn 0.5s ease-out forwards`,
          }"
        />

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
        v-if="!loading && posts?.length === 0 && !id"
        class="flex flex-col items-center justify-center py-12 text-center bg-gray-50/50 dark:bg-slate-800/50 backdrop-blur-sm rounded-xl border border-gray-100 dark:border-slate-700/50 shadow-sm"
      >
        <UIcon
          name="i-heroicons-document-text"
          class="w-12 h-12 text-gray-400 dark:text-gray-600 mb-3"
        />
        <p class="text-gray-600 dark:text-gray-600 mb-2 font-medium">
          No Post Available
        </p>
        <p class="text-gray-600 dark:text-gray-600 text-sm">
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
      :is-loading-more-comments="isLoadingMoreComments"
      :has-more-comments="
        activeCommentsPost
          ? commentsPagination[activeCommentsPost.id]?.hasMore || false
          : false
      "
      @close-likes-modal="activeLikesPost = null"
      @toggle-user-follow="toggleUserFollow"
      @close-comments-modal="closeCommentsModal"
      @handle-comment-input="handleCommentInput"
      @handle-mention-keydown="handleMentionKeydown"
      @add-comment="addComment"
      @load-more-comments="loadMoreComments"
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
import GoldSponsorsSlider from "./GoldSponsorsSlider.vue";
import BusinessNetworkUserSuggestions from "./UserSuggestions.vue";

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
  searchQuery: {
    type: String,
    default: "",
  },
});

// Emits
const emit = defineEmits(["gift-sent"]);

// Get auth and API utilities
const { user } = useAuth();
const { post, del, put, get } = useApi();
const toast = useToast();

// Highlight search terms in post content
const highlightSearchTerms = (content, fieldType = "content") => {
  if (!content || !props.searchQuery || props.searchQuery.trim() === "")
    return content;

  let searchText = props.searchQuery;

  // Handle hashtag searches
  if (searchText.startsWith("#")) {
    searchText = searchText.substring(1);
  }

  // Don't attempt highlighting if search term is too short
  if (searchText.length < 2) return content;

  try {
    // Escape special regex characters to prevent errors
    const escapedSearchText = searchText.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`(${escapedSearchText})`, "gi");

    // Use different highlight colors based on field type
    let highlightClass = "";
    switch (fieldType) {
      case "title":
        highlightClass =
          "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300";
        break;
      case "author":
        highlightClass =
          "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300";
        break;
      case "hashtag":
        highlightClass =
          "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300";
        break;
      case "content":
      default:
        highlightClass =
          "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300";
    }

    return content.replace(
      regex,
      `<span class="${highlightClass} px-0.5 rounded">$1</span>`
    );
  } catch (e) {
    console.error("Error highlighting search terms:", e);
    return content;
  }
};

// Detect which fields match the search query
const detectMatchedFields = (post) => {
  if (!props.searchQuery || props.searchQuery.trim() === "") return [];

  let searchText = props.searchQuery;

  // Handle hashtag searches
  if (searchText.startsWith("#")) {
    searchText = searchText.substring(1);
  }

  const matches = [];
  const regex = new RegExp(searchText, "i");

  // Check post title
  if (post.title && regex.test(post.title)) {
    matches.push("title");
  }

  // Check post content
  if (post.content && regex.test(post.content)) {
    matches.push("content");
  }

  // Check author name
  if (post.author_details) {
    const authorName =
      post.author_details.first_name + " " + post.author_details.last_name;
    if (regex.test(authorName) || regex.test(post.author_details.username)) {
      matches.push("author");
    }
  }

  // Check hashtags
  if (post.post_tags && post.post_tags.some((tag) => regex.test(tag.tag))) {
    matches.push("hashtag");
  }

  return matches;
};

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

// Comments pagination state
const commentsPagination = ref({});
const isLoadingMoreComments = ref(false);

// Initialize comments pagination for a post
const initCommentsPage = (postId) => {
  if (!commentsPagination.value[postId]) {
    commentsPagination.value[postId] = {
      currentPage: 1,
      hasMore: true,
      isLoading: false,
    };
  }
};

// Load comments for a specific post
const loadCommentsForPost = async (postId, page = 1, replace = false) => {
  if (!postId) return;

  // Initialize pagination if it doesn't exist
  if (!commentsPagination.value[postId]) {
    initCommentsPage(postId);
  }

  try {
    commentsPagination.value[postId].isLoading = true;
    isLoadingMoreComments.value = true;

    const requestParams = {
      page: page,
      page_size: 10,
    };

    // Build URL with query parameters manually since the get function doesn't support params
    const queryString = new URLSearchParams(requestParams).toString();
    const requestUrl = `/bn/posts/${postId}/comments/?${queryString}`;

    const response = await get(requestUrl);

    const data = response.data || response;

    // Find the post in our posts array
    const post = props.posts.find((p) => p.id === postId);
    if (post) {
      if (replace || page === 1) {
        // Initial load: reverse order to show newest comments at bottom
        post.post_comments = (data.results || []).reverse();
      } else {
        // Load more (older comments): The API returns them in descending order (newest first)
        // We need to reverse them first, then prepend to show oldest at top
        const olderComments = data.results || [];
        const previousCount = post.post_comments?.length || 0;

        // Reverse the older comments so they're in oldest-first order
        const olderCommentsReversed = olderComments.reverse();

        // Filter out any duplicate comments to prevent duplication
        const existingCommentIds = new Set(
          post.post_comments?.map((c) => c.id) || []
        );
        const newUniqueComments = olderCommentsReversed.filter(
          (comment) => !existingCommentIds.has(comment.id)
        );

        // Prepend the older comments (they should appear before the existing comments)
        post.post_comments = [
          ...newUniqueComments,
          ...(post.post_comments || []),
        ];
      }

      // Update the post's comment count
      if (data.count !== undefined) {
        post.comment_count = data.count;
      }
    }

    // Update pagination state
    commentsPagination.value[postId].currentPage = page;
    commentsPagination.value[postId].hasMore = !!data.next;
    commentsPagination.value[postId].isLoading = false;
  } catch (error) {
    console.error("Error loading comments:", error);
    commentsPagination.value[postId].isLoading = false;
  } finally {
    isLoadingMoreComments.value = false;
  }
};

// Load more comments
const loadMoreComments = async (eventData) => {
  const postId = eventData.postId || activeCommentsPost.value?.id;

  if (!postId) {
    return;
  }

  // Get the correct next page from pagination state
  const pagination = commentsPagination.value[postId];

  if (!pagination) {
    initCommentsPage(postId);
    return;
  }

  if (!pagination.hasMore) {
    return;
  }

  if (pagination.isLoading) {
    return;
  }

  const nextPage = pagination.currentPage + 1;

  await loadCommentsForPost(postId, nextPage, false);
};

// Close comments modal and reset state
const closeCommentsModal = () => {
  activeCommentsPost.value = null;
};

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
    } else {
      const { data } = await post(endpoint);
      post.author_details.is_following = true;
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

// Handle post update from PostHeader component
const handlePostUpdate = (updatedPost) => {
  // Find the post in the posts array and update it
  const postIndex = props.posts.findIndex((p) => p.id === updatedPost.id);
  if (postIndex !== -1) {
    // Update the post in the array
    props.posts[postIndex] = { ...props.posts[postIndex], ...updatedPost };

    // If the post has post_details, update that too
    if (props.posts[postIndex].post_details) {
      props.posts[postIndex].post_details = {
        ...props.posts[postIndex].post_details,
        ...updatedPost,
      };
    }
  }

  // Also check if it's a single post display
  if (props.posts.length === 1 && props.posts[0].id === updatedPost.id) {
    props.posts[0] = { ...props.posts[0], ...updatedPost };
  }
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
      (like) =>
        like &&
        (like.user === currentUserId ||
          like.user === String(currentUserId) ||
          like.user === Number(currentUserId))
    );

    if (isLiked) {
      // Use the unlike endpoint when already liked
      const endpoint = `/bn/posts/${postToLike.id}/unlike/`;
      await del(endpoint); // Remove user from likes (with null safety and type flexibility)
      postToLike.post_likes = postToLike.post_likes.filter(
        (like) =>
          like &&
          like.user !== currentUserId &&
          like.user !== String(currentUserId) &&
          like.user !== Number(currentUserId)
      );

      // Update like count for UI if needed
      if (postToLike.likes_count !== undefined) {
        postToLike.likes_count = Math.max(0, (postToLike.likes_count || 0) - 1);
      }
    } else {
      // Use the like endpoint when not yet liked
      const endpoint = `/bn/posts/${postToLike.id}/like/`;
      try {
        const { data } = await post(endpoint);

        // Add new like data to the post
        if (!postToLike.post_likes) {
          postToLike.post_likes = [];
        }

        // Ensure we have valid like data before pushing
        if (data && data.user) {
          postToLike.post_likes.push(data);
        } else {
          // Fallback: create like object with current user info
          postToLike.post_likes.push({
            user: currentUserId,
            created_at: new Date().toISOString(),
          });
        }

        // Update like count for UI if needed
        if (postToLike.likes_count !== undefined) {
          postToLike.likes_count = (postToLike.likes_count || 0) + 1;
        }
      } catch (likeError) {
        // Handle specific case where user already liked the post
        if (likeError.response?.status === 400) {
          // The user has already liked this post, update the UI accordingly
          if (!postToLike.post_likes) {
            postToLike.post_likes = [];
          }

          // Check if the like already exists in the local data
          const existingLike = postToLike.post_likes.find(
            (like) =>
              like &&
              (like.user === currentUserId ||
                like.user === String(currentUserId) ||
                like.user === Number(currentUserId))
          );

          if (!existingLike) {
            // Add the like to local state since it exists on the server
            postToLike.post_likes.push({
              user: currentUserId,
              created_at: new Date().toISOString(),
            });

            if (postToLike.likes_count !== undefined) {
              postToLike.likes_count = (postToLike.likes_count || 0) + 1;
            }
          }

          // Show a different message for this case
          toast.add({
            title: "Post already liked",
            description: "This post was already in your liked posts",
            color: "blue",
          });

          return; // Exit early to avoid rethrowing the error
        }

        // Re-throw other errors to be handled by the outer catch block
        throw likeError;
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
  postToComment.isCommentLoading = true;

  try {
    const endpoint = `/bn/posts/${postToComment.id}/comments/`;
    const { data } = await post(endpoint, {
      content: postToComment.commentText,
    });

    // Initialize post_comments array if it doesn't exist
    if (!postToComment.post_comments) {
      postToComment.post_comments = [];
    } // Ensure the new comment has proper author details
    if (data && !data.author_details && user.value?.user) {
      data.author_details = {
        id: user.value.user.id,
        name:
          user.value.user.name ||
          `${user.value.user.first_name || ""} ${
            user.value.user.last_name || ""
          }`.trim(),
        image: user.value.user.image,
        kyc: user.value.user.kyc,
        is_pro: user.value.user.is_pro,
        is_topcontributor: user.value.user.is_topcontributor,
      };
    }

    // Also ensure the comment has the author field
    if (data && !data.author && user.value?.user) {
      data.author = user.value.user.id;
    }

    // Ensure the comment has a created_at timestamp if missing
    if (data && !data.created_at) {
      data.created_at = new Date().toISOString();
    }

    // Add the new comment to the beginning
    postToComment.post_comments.unshift(data);

    // Update the comment count
    if (postToComment.comment_count !== undefined) {
      postToComment.comment_count = (postToComment.comment_count || 0) + 1;
    }

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
  // CRITICAL FIX: Don't interfere with PostCommentInput's mention management  // The PostCommentInput component now handles its own text and mentions
  // Only handle the parent's mention dropdown logic if needed

  // Check for mention character (@) for parent's mention dropdown (if used)
  const cursorPos = event.target.selectionStart;
  const textBeforeCursor = event.target.value.substring(0, cursorPos);
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
const openLikesModal = async (postToView) => {
  // Set the post first so modal opens immediately
  activeLikesPost.value = postToView;

  try {
    // Fetch fresh likes data with updated follow status
    const response = await get(`/bn/posts/${postToView.id}/like/`);
    if (response.data && response.data.results) {
      // Update the post's likes with fresh data that includes current follow status
      postToView.post_likes = response.data.results;
      // Trigger reactivity update
      activeLikesPost.value = { ...postToView };
    }
  } catch (error) {
    console.error("Error fetching updated likes data:", error);
    // Modal will still work with existing data if API call fails
  }
};

const openCommentsModal = async (postToView) => {
  activeCommentsPost.value = postToView;

  // Reset pagination for this post to ensure clean state
  commentsPagination.value[postToView.id] = {
    currentPage: 0, // Start at 0 so first load will be page 1
    hasMore: true,
    isLoading: false,
  };

  // Always load initial 10 comments with pagination (replace existing)
  await loadCommentsForPost(postToView.id, 1, true);

  // Set timeout to scroll to top (recent comments) once modal is visible
  setTimeout(() => {
    if (modalsRef.value?.commentsContainerRef) {
      modalsRef.value.commentsContainerRef.scrollTop = 0;
    }
  }, 100);
};

const toggleUserFollow = async (userToFollow) => {
  try {
    const userId = userToFollow.user;
    const newFollowStatus = !userToFollow.user_details.isFollowing;

    if (userToFollow.user_details.isFollowing) {
      await del(`/bn/users/${userId}/unfollow/`);
    } else {
      await post(`/bn/users/${userId}/follow/`);
    }

    // Update the follow status in the current modal
    userToFollow.user_details.isFollowing = newFollowStatus;

    // Also update all posts' likes data to keep everything in sync
    props.posts.forEach((post) => {
      if (post.post_likes && Array.isArray(post.post_likes)) {
        post.post_likes.forEach((like) => {
          if (like.user === userId && like.user_details) {
            like.user_details.isFollowing = newFollowStatus;
          }
        });
      }
    });
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

const navigateMedia = (direction, index) => {
  if (!activePost.value || !activePost.value.post_media) return;

  const totalMedia = activePost.value.post_media.length;

  // If an index is directly provided (for serial view selection)
  if (typeof index === "number") {
    activeMediaIndex.value = index;
  }
  // For next/prev navigation
  else if (direction === "next") {
    activeMediaIndex.value = (activeMediaIndex.value + 1) % totalMedia;
  } else if (direction === "prev") {
    activeMediaIndex.value =
      (activeMediaIndex.value - 1 + totalMedia) % totalMedia;
  } else if (direction === "select") {
    // This case is for direct selection, but index is required
    console.warn("Index is required for 'select' direction");
    return;
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
};

const deleteComment = (post, comment) => {
  commentToDelete.value = comment;
  postWithCommentToDelete.value = post;
};

const confirmDeleteComment = async () => {
  if (!commentToDelete.value || !postWithCommentToDelete.value) return;

  try {
    commentToDelete.value.isDeleting = true;

    await del(`/bn/comments/${commentToDelete.value.id}/`); // Remove the comment from the list
    if (
      postWithCommentToDelete.value &&
      postWithCommentToDelete.value.post_comments
    ) {
      postWithCommentToDelete.value.post_comments =
        postWithCommentToDelete.value.post_comments.filter(
          (c) => c.id !== commentToDelete.value.id
        );

      // Update the comment count
      if (
        postWithCommentToDelete.value.comment_count !== undefined &&
        postWithCommentToDelete.value.comment_count > 0
      ) {
        postWithCommentToDelete.value.comment_count -= 1;
      }
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
      .catch((error) => console.error("Error sharing", error));
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
  backdrop-filter: blur(8px);
  background-color: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

.dark .glass-effect {
  background-color: rgba(30, 41, 59, 0.8);
  border: 1px solid rgba(51, 65, 85, 0.2);
}

.premium-shadow {
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.05), 0 2px 6px rgba(0, 0, 0, 0.05),
    0 0 1px rgba(0, 0, 0, 0.1);
}

.dark .premium-shadow {
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15), 0 2px 6px rgba(0, 0, 0, 0.2),
    0 0 1px rgba(255, 255, 255, 0.05);
}

/* Hashtag styling */
.hashtag {
  position: relative;
  text-decoration: none;
  cursor: pointer;
}

.hashtag:hover {
  text-decoration: underline;
}

.hashtag:hover::after {
  content: "";
  position: absolute;
  bottom: -1px;
  left: 5%;
  width: 90%;
  height: 1px;
  background-color: currentColor;
  transform-origin: center;
  transition: transform 0.2s ease;
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
