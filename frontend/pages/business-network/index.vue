<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl flex-1">
    <!-- Lazyloader component to display while initial posts are loading -->
    <template v-if="loading && !loadingMore && allPosts.length === 0">
      <div class="p-4">
        <div class="flex justify-center items-center mb-6">
          <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
        </div>
        <!-- Skeleton loaders for posts -->
        <div
          v-for="i in 3"
          :key="i"
          class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4"
        >
          <div class="flex items-center space-x-3 mb-4">
            <div class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"></div>
            <div class="flex-1 space-y-2">
              <div class="h-4 bg-gray-200 rounded animate-pulse w-1/4"></div>
              <div class="h-3 bg-gray-200 rounded animate-pulse w-1/5"></div>
            </div>
          </div>
          <div class="space-y-2 mb-4">
            <div class="h-4 bg-gray-200 rounded animate-pulse w-3/4"></div>
            <div class="h-3 bg-gray-200 rounded animate-pulse w-full"></div>
            <div class="h-3 bg-gray-200 rounded animate-pulse w-5/6"></div>
          </div>
          <div class="h-40 bg-gray-200 rounded animate-pulse mb-4"></div>
          <div class="flex justify-between">
            <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
            <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
            <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
          </div>
        </div>
      </div>
    </template>

    <!-- Actual posts displayed after loading -->
    <BusinessNetworkPost
      v-if="!loading || allPosts.length > 0"
      :posts="displayedPosts"
      :id="user?.user?.id"
      @gift-sent="handleGiftSent"
      @post-updated="handlePostUpdate"
    />

    <!-- Load more indicator with skeletons for better UX -->
    <div v-if="loadingMore && !loading" class="pb-6">
      <!-- Skeleton loader for loading more posts -->
      <div
        class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4"
      >
        <div class="flex items-center space-x-3 mb-4">
          <div class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"></div>
          <div class="flex-1 space-y-2">
            <div class="h-4 bg-gray-200 rounded animate-pulse w-1/4"></div>
            <div class="h-3 bg-gray-200 rounded animate-pulse w-1/5"></div>
          </div>
        </div>
        <div class="space-y-2 mb-4">
          <div class="h-4 bg-gray-200 rounded animate-pulse w-3/4"></div>
          <div class="h-3 bg-gray-200 rounded animate-pulse w-full"></div>
          <div class="h-3 bg-gray-200 rounded animate-pulse w-5/6"></div>
        </div>
        <div class="h-40 bg-gray-200 rounded animate-pulse mb-4"></div>
        <div class="flex justify-between">
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
        </div>
      </div>
    </div>

    <!-- End of feed indicator - shows when all posts are loaded -->
    <div
      v-if="!loading && !loadingMore && !hasMore && allPosts.length > 0"
      class="flex flex-col items-center justify-center py-8 text-center"
    >
      <!-- Decorative line -->
      <div class="w-16 h-0.5 bg-gradient-to-r from-gray-200 via-gray-400 to-gray-200 rounded-full mb-6"></div>
      
      <div
        class="w-14 h-14 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center mb-4 shadow-lg shadow-blue-500/30"
      >
        <Check class="h-7 w-7 text-white" />
      </div>
      <h3 class="text-base font-semibold text-gray-800 mb-1">
        You're all caught up!
      </h3>
      <p class="text-sm text-gray-500 mb-6 max-w-md">
        You've seen all {{ allPosts.length }} posts in your feed
      </p>
      <button
        @click="loadRecentPosts"
        class="flex items-center gap-2 px-4 py-2 text-sm border border-gray-300 text-gray-600 rounded-full hover:bg-gray-50 transition-colors mb-2"
      >
        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        <span>Refresh for new posts</span>
      </button>
      <button
        @click="scrollToTop"
        class="flex items-center gap-2 px-4 py-2 text-sm text-gray-500 hover:text-gray-700 transition-colors"
      >
        <ChevronUp class="h-4 w-4" />
        <span>Back to top</span>
      </button>
    </div>

    <!-- No posts message -->
    <div
      v-if="!loading && !loadingMore && allPosts.length === 0"
      class="flex flex-col items-center justify-center py-12 text-center"
    >
      <p class="text-gray-600 mb-2">{{ $t("no_post_available") }}</p>
    </div>

    <!-- Add the create post component with event listener -->
    <BusinessNetworkCreatePost @post-created="handleNewPost" />

    <!-- Search Overlay -->
    <Teleport to="body">
      <div
        v-if="isSearchOpen"
        class="fixed inset-0 bg-black/50 z-[9999] flex items-center justify-center p-4"
        @click="isSearchOpen = false"
      >
        <div
          class="bg-white rounded-lg w-full max-w-2xl max-h-[80vh] overflow-hidden"
          @click.stop
        >
          <div class="p-4 border-b border-gray-200 sticky top-0 bg-white">
            <div class="flex items-center gap-3">
              <div class="relative flex-1">
                <div
                  class="absolute inset-y-0 left-3 flex items-center pointer-events-none"
                >
                  <Search class="h-5 w-5 text-gray-600" />
                </div>
                <input
                  ref="searchInputRef"
                  type="text"
                  placeholder="Search business network..."
                  class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-600 focus:border-transparent"
                  v-model="searchQuery"
                />
              </div>
              <button
                class="p-2 rounded-full hover:bg-gray-100"
                @click="isSearchOpen = false"
              >
                <X class="h-5 w-5" />
              </button>
            </div>
          </div>

          <div class="p-3 border-b border-gray-200">
            <h3 class="text-sm font-medium text-gray-600 mb-2">
              Filter by Category
            </h3>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="category in availableCategories"
                :key="category"
                class="text-xs px-3 py-1 rounded-full transition-colors"
                :class="
                  selectedCategories.includes(category)
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                "
                @click="toggleCategory(category)"
              >
                {{ category }}
              </button>
            </div>
          </div>

          <div class="overflow-y-auto max-h-[calc(90vh-142px)]">
            <div v-if="searchResults.length > 0" class="p-4">
              <ul class="space-y-3">
                <li v-for="(result, index) in searchResults" :key="index">
                  <button
                    class="flex items-center gap-3 w-full p-3 hover:bg-gray-50 rounded-lg transition-colors"
                    @click="handleSearch(result)"
                  >
                    <div class="bg-gray-100 rounded-full p-2">
                      <Search class="h-4 w-4 text-gray-600" />
                    </div>
                    <span class="text-gray-800">{{ result }}</span>
                  </button>
                </li>
                <li>
                  <button
                    class="flex items-center justify-between w-full p-3 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors mt-2"
                    @click="handleSeeAllResults"
                  >
                    <span class="font-medium text-blue-600">
                      {{
                        selectedCategories.length > 0
                          ? `Search "${searchQuery}" in ${selectedCategories.length} categories`
                          : `See all results for "${searchQuery}"`
                      }}
                    </span>
                    <ArrowRight class="h-4 w-4 text-blue-600" />
                  </button>
                </li>
              </ul>
            </div>

            <div v-if="searchQuery.length === 0" class="p-4">
              <h3 class="text-sm font-medium text-gray-600 mb-2">
                Recent Searches
              </h3>
              <ul class="space-y-3">
                <li v-for="(term, index) in recentSearches" :key="index">
                  <button
                    class="flex items-center gap-3 w-full p-3 hover:bg-gray-50 rounded-lg transition-colors"
                    @click="handleSearch(term)"
                  >
                    <div class="bg-gray-100 rounded-full p-2">
                      <Clock class="h-4 w-4 text-gray-600" />
                    </div>
                    <span class="text-gray-800">{{ term }}</span>
                  </button>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "adsy-business-network",
});

import {
  Search,
  X,
  Clock,
  ArrowRight,
  Loader2,
  Check,
  ChevronUp,
} from "lucide-vue-next";

// State
const allPosts = ref([]); // All loaded posts
const displayedPosts = ref([]); // Currently displayed posts
const loading = ref(true);
const loadingMore = ref(false);
const { get } = useApi();
const { user } = useAuth();
const eventBus = useEventBus();
const loadedPostIds = ref(new Set()); // Track loaded post IDs to prevent duplicates

// Feed configuration - optimized for social connectivity algorithm
// Backend priority: 1) Own recent posts, 2) Following, 3) Followers, 4) Others
const INITIAL_BATCH_SIZE = 10; // Load more posts initially for better first impression
const LOAD_MORE_BATCH_SIZE = 7; // Optimized batch size for pagination (matches backend MediumDevicePagination)
const SCROLL_THRESHOLD = 600; // Pixels before end to trigger load more

// Pagination state
const page = ref(1);
const hasMore = ref(true);
const lastCreatedAt = ref(null); // For pagination cursor
const newestCreatedAt = ref(null); // For refresh/newer posts
const totalPostCount = ref(0); // Track total available posts

// Error handling state
const errorType = ref(null); // 'network', 'auth', 'server', 'timeout'
const errorMessage = ref(null);
const isRefreshing = ref(false);

// Listen for loading events from footer and sidebar
eventBus.on("start-loading-posts", () => {
  // Set loading to true immediately
  loading.value = true;
});

/**
 * Get posts from the business network feed
 * 
 * The backend implements a sophisticated priority-based feed algorithm:
 * - Priority 1: User's own recent posts (last 24 hours)
 * - Priority 2: Posts from users the current user follows
 * - Priority 3: Posts from the current user's followers  
 * - Priority 4: Other posts (chronological)
 * 
 * Additional backend features:
 * - Hidden posts are excluded
 * - Relationship data is cached for 5 minutes
 * - Device-level optimization available
 */
async function getPosts(isLoadingMore = false, pageNum = 1) {
  try {
    // Set loading state
    if (isLoadingMore) {
      loadingMore.value = true;
    } else {
      loading.value = true;
      errorType.value = null;
      errorMessage.value = null;
    }

    // Build optimized query parameters
    const params = {
      page_size: isLoadingMore ? LOAD_MORE_BATCH_SIZE : INITIAL_BATCH_SIZE,
    };

    // Add cursor-based pagination for older posts
    if (isLoadingMore && lastCreatedAt.value) {
      params.older_than = lastCreatedAt.value;
    }

    // Make API request with timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000); // 15s timeout

    try {
      const response = await get(`/bn/posts/?page=${pageNum}`, { 
        params,
        signal: controller.signal 
      });
      clearTimeout(timeoutId);

      if (response.data && response.data.results) {
        const newPosts = response.data.results;
        
        // Track total count from API
        if (response.data.count) {
          totalPostCount.value = response.data.count;
        }

        // Process posts with UI properties
        const processedPosts = newPosts.map((post) => ({
          ...post,
          showFullDescription: false,
          showDropdown: false,
          commentText: "",
          isCommentLoading: false,
          isLikeLoading: false,
        }));

        // Filter duplicates using Set for O(1) lookup
        const uniquePosts = processedPosts.filter((post) => {
          if (loadedPostIds.value.has(post.id)) {
            return false;
          }
          loadedPostIds.value.add(post.id);
          return true;
        });

        // Update posts array
        allPosts.value = isLoadingMore
          ? [...allPosts.value, ...uniquePosts]
          : uniquePosts;

        // Update pagination cursors
        if (uniquePosts.length > 0) {
          const lastPost = uniquePosts[uniquePosts.length - 1];
          lastCreatedAt.value = lastPost.created_at;

          if (!newestCreatedAt.value) {
            newestCreatedAt.value = uniquePosts[0].created_at;
          }
        }

        // Determine if more posts available
        hasMore.value = response.data.next !== null && uniquePosts.length > 0;

        // Update displayed posts
        updateDisplayedPosts();
      } else {
        if (!isLoadingMore) {
          allPosts.value = [];
          displayedPosts.value = [];
        }
        hasMore.value = false;
      }
    } catch (fetchError) {
      clearTimeout(timeoutId);
      throw fetchError;
    }
  } catch (error) {
    console.error("❌ Failed to load posts:", error);
    
    // Determine error type for better UX
    if (error.name === 'AbortError') {
      errorType.value = 'timeout';
      errorMessage.value = 'Connection timed out. Please check your internet.';
    } else if (error.response?.status === 401) {
      errorType.value = 'auth';
      errorMessage.value = 'Please log in to view personalized feed.';
    } else if (error.response?.status >= 500) {
      errorType.value = 'server';
      errorMessage.value = 'Server error. Please try again later.';
    } else if (!navigator.onLine) {
      errorType.value = 'network';
      errorMessage.value = 'No internet connection. Please check your network.';
    } else {
      errorType.value = 'unknown';
      errorMessage.value = 'Failed to load posts. Please try again.';
    }

    // Show toast notification
    useToast().add({
      title: errorType.value === 'auth' ? 'Login Required' : 'Error',
      description: errorMessage.value,
      color: errorType.value === 'auth' ? 'blue' : 'red',
      timeout: 4000,
    });

    if (!isLoadingMore) {
      allPosts.value = [];
      displayedPosts.value = [];
    }
    hasMore.value = false;
  } finally {
    loading.value = false;
    loadingMore.value = false;
    isRefreshing.value = false;
  }
}

// Function to update displayed posts with proper grouping
function updateDisplayedPosts() {
  // Create a new array to avoid reactivity issues
  displayedPosts.value = [...allPosts.value];
}

// Handle gift sent event from child components
function handleGiftSent(giftData) {
  // Reload posts after a short delay to ensure backend is updated
  setTimeout(() => {
    // Reset state and reload posts
    loadData();
  }, 20);
}

// Handle post update event from child components
function handlePostUpdate(updatedPost) {
  // Find and update the post in allPosts
  const postIndex = allPosts.value.findIndex((p) => p.id === updatedPost.id);
  if (postIndex !== -1) {
    allPosts.value[postIndex] = {
      ...allPosts.value[postIndex],
      ...updatedPost,
    };
  }

  // Also update in displayedPosts
  const displayedIndex = displayedPosts.value.findIndex(
    (p) => p.id === updatedPost.id
  );
  if (displayedIndex !== -1) {
    displayedPosts.value[displayedIndex] = {
      ...displayedPosts.value[displayedIndex],
      ...updatedPost,
    };
  }
}

// Load data when component is created
function loadData() {
  // Reset state
  loading.value = true;
  page.value = 1;
  hasMore.value = true;
  lastCreatedAt.value = null;
  loadedPostIds.value.clear(); // Reset tracked post IDs when reloading

  // Get initial posts with a slight delay
  setTimeout(() => {
    getPosts();
  }, 100); // Small delay to ensure navigation completes first
}

// Load more posts when user scrolls down
function loadMorePosts() {
  if (!hasMore.value || loadingMore.value || loading.value) return;

  page.value++;
  getPosts(true, page.value);
}

// Setup scroll detection for infinite scroll with optimized threshold
function setupInfiniteScroll() {
  let ticking = false; // Throttle scroll events for performance
  
  const handleScroll = () => {
    if (!ticking) {
      window.requestAnimationFrame(() => {
        const scrollPosition = window.innerHeight + window.scrollY;
        const threshold = document.body.offsetHeight - SCROLL_THRESHOLD;
        
        if (scrollPosition >= threshold) {
          if (!loadingMore.value && !loading.value && hasMore.value) {
            loadMorePosts();
          }
        }
        ticking = false;
      });
      ticking = true;
    }
  };

  window.addEventListener("scroll", handleScroll, { passive: true });

  // Remove event listener on component unmount
  onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
  });
}

// Initialize
onMounted(() => {
  loadData();
  setupInfiniteScroll();
});

// Event listener setup
onMounted(() => {
  // Listen for events from footer or sidebar
  eventBus.on("start-loading-posts", () => {
    loadData();
  });

  // Listen for the specific recent posts loading event
  eventBus.on("load-recent-posts", () => {
    loadRecentPosts();
  });

  // Also listen for post-created events from the global event bus
  const globalEventBus = useEventBus();
  globalEventBus.on("post-created", (newPostData) => {
    handleNewPost(newPostData);
  });

  // Clean up event listeners when component is unmounted
  onUnmounted(() => {
    eventBus.off("start-loading-posts");
    eventBus.off("load-recent-posts");
    globalEventBus.off("post-created");
  });
});

// Add this function to handle the new post
const handleNewPost = async (newPost) => {
  if (newPost) {
    // Process the new post to ensure it has necessary UI properties
    const processedNewPost = {
      ...newPost,
      showFullDescription: false,
      showDropdown: false,
      commentText: "",
      isCommentLoading: false,
      isLikeLoading: false,
    };

    // Track the new post ID to prevent future duplicates
    if (newPost.id) {
      loadedPostIds.value.add(newPost.id);
    }

    // Add the new post to the beginning of the posts array for immediate display

    allPosts.value = [processedNewPost, ...allPosts.value];

    // Update the displayed posts

    updateDisplayedPosts();

    // Update newest timestamp if applicable
    if (processedNewPost.created_at) {
      newestCreatedAt.value = processedNewPost.created_at;
    }
  } else {
    // If no post data is provided, reload all posts
    await loadData();
  }
};

// Function to specifically load recent posts with optimized settings
async function loadRecentPosts() {
  // Prevent duplicate refresh calls
  if (isRefreshing.value) return;
  isRefreshing.value = true;
  
  // Reset state
  loading.value = true;
  page.value = 1;
  hasMore.value = true;
  lastCreatedAt.value = null;
  errorType.value = null;
  errorMessage.value = null;
  loadedPostIds.value.clear();
  allPosts.value = [];
  displayedPosts.value = [];

  try {
    const params = {
      page_size: INITIAL_BATCH_SIZE,
    };

    const response = await get("/bn/posts/", { params });
    
    if (response.data && response.data.results) {
      const newPosts = response.data.results;
      
      // Track total count
      if (response.data.count) {
        totalPostCount.value = response.data.count;
      }

      // Process posts
      const processedPosts = newPosts.map((post) => ({
        ...post,
        showFullDescription: false,
        showDropdown: false,
        commentText: "",
        isCommentLoading: false,
        isLikeLoading: false,
      }));

      // Track post IDs
      processedPosts.forEach((post) => {
        loadedPostIds.value.add(post.id);
      });

      allPosts.value = processedPosts;

      // Update cursors
      if (processedPosts.length > 0) {
        lastCreatedAt.value = processedPosts[processedPosts.length - 1].created_at;
        newestCreatedAt.value = processedPosts[0].created_at;
      }

      hasMore.value = response.data.next !== null;
      updateDisplayedPosts();
    }
  } catch (error) {
    console.error("❌ Failed to load recent posts:", error);
    useToast().add({
      title: "Error",
      description: "Failed to load recent posts",
      color: "red",
      timeout: 3000,
    });
  } finally {
    loading.value = false;
    isRefreshing.value = false;
  }
}

// Search functionality
const isSearchOpen = ref(false);
const searchQuery = ref("");
const recentSearches = ref([
  "Marketing Strategy",
  "Business Development",
  "Networking Events",
  "Leadership Training",
]);
const selectedCategories = ref([]);
const availableCategories = [
  "Marketing",
  "Finance",
  "Operations",
  "Leadership",
  "Technology",
  "HR",
  "Sales",
  "Strategy",
];
const searchInputRef = ref(null);

// Format time ago
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

const handleSearch = (term) => {
  searchQuery.value = term;
  // Add to recent searches if not already there
  if (!recentSearches.value.includes(term) && term.trim() !== "") {
    recentSearches.value = [term, ...recentSearches.value.slice(0, 4)];
  }
};

const handleSeeAllResults = () => {
  if (searchQuery.value.trim()) {
    handleSearch(searchQuery.value);
    isSearchOpen.value = false;
  }
};

// Computed search results
const searchResults = computed(() => {
  if (searchQuery.value.length > 0) {
    // Simulate search results
    let mockResults = [
      `${searchQuery.value}`,
      `${searchQuery.value} trends`,
      `${searchQuery.value} examples`,
      `${searchQuery.value} best practices`,
      `${searchQuery.value} tips`,
    ];

    // If categories are selected, add them to the results
    if (selectedCategories.value.length > 0) {
      mockResults = mockResults.map(
        (result) => `${result} in ${selectedCategories.value.join(", ")}`
      );
    }

    return mockResults;
  }
  return [];
});

// Initialize
onMounted(() => {
  // Focus search input when overlay opens
  watch(isSearchOpen, (newVal) => {
    if (newVal) {
      nextTick(() => {
        searchInputRef.value?.focus();
      });
    }
  });
});

// Scroll to top functionality
const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: "smooth" });
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

/* Pull-to-refresh indicator animation */
.ptr-indicator {
  transition: transform 0.2s ease;
}
</style>
