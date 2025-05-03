<template>
  <div class="max-w-3xl pb-20 pt-3">
    <div class="space-y-4">
      <!-- Loop through posts and insert sponsored products after every 5 posts -->
      <template v-for="(post, index) in posts" :key="post.id">
        <!-- Post Card -->
        <div
          class="transform transition-all duration-300 bg-white rounded-xl border border-gray-200 overflow-hidden"
          :style="{
            animationDelay: `${index * 0.05}s`,
            animation: `fadeIn 0.5s ease-out forwards`,
          }"
        >
          <div class="sm:px-3 py-4 sm:py-5">
            <!-- Post Header -->
            <BusinessNetworkPostHeader
              :post="post?.post_details ? post.post_details : post"
              :user="user"
              @toggle-follow="toggleFollow"
              @toggle-dropdown="toggleDropdown"
              @toggle-save="toggleSave"
              @copy-link="copyLink"
            />

            <!-- Post Title -->
            <NuxtLink
              :to="`/business-network/posts/${
                post?.post ? post.post : post.id
              }`"
              class="block text-sm sm:text-base font-semibold mb-1 hover:text-blue-600 transition-colors px-2"
            >
              {{ post?.post_details ? post.post_details.title : post.title }}
            </NuxtLink>

            <!-- Tags -->
            <div
              v-if="
                post?.post_details
                  ? post.post_details?.post_tags?.length > 0
                  : post?.post_tags?.length > 0
              "
              class="flex flex-wrap gap-1 mb-2 px-2"
            >
              <span
                v-for="(tag, idx) in post?.post_details
                  ? post.post_details?.post_tags
                  : post?.post_tags"
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
                  `text-base text-gray-800`,
                  !post.showFullDescription && `line-clamp-4`,
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
                class="text-sm text-blue-600 font-medium mt-1"
                @click="toggleDescription(post)"
              >
                {{
                  post.showFullDescription ? $t("read_less") : $t("read_more")
                }}
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

        <!-- Sponsored Products Section - Show after every 5th post -->
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
watch(() => props.posts, (newPosts) => {
  if (newPosts && newPosts.length > 0) {
    processPosts(); // Process posts when they change
  }
}, { deep: true });

// ...remaining functions unchanged...
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
