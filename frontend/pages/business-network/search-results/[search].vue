<template>  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 flex-1">
    <!-- Enhanced Search Results Header -->
    <div class="relative bg-white rounded-xl shadow-sm mb-6 border border-gray-100">
      <div class="flex flex-col md:flex-row md:items-center justify-between px-6 py-4">
        <div class="mb-4 md:mb-0">
          <h1 class="text-xl font-bold text-gray-800 flex items-center">
            <span class="bg-blue-100 rounded-full p-1.5 mr-2.5">
              <Search class="h-4 w-4 text-blue-600" />
            </span>
            Search Results
          </h1>
          <p class="text-gray-600 text-sm mt-1 flex items-center">
            <span class="font-medium text-gray-700">{{ $route.params.search }}</span>
            <span class="mx-2 text-gray-400">•</span>
            <span v-if="!loading && allPosts.length > 0">{{ allPosts.length }} {{ allPosts.length === 1 ? 'result' : 'results' }}</span>
            <span v-else-if="!loading && allPosts.length === 0">No results found</span>
            <span v-else>Searching...</span>
          </p>
        </div>
        
        <div class="flex items-center gap-2">
          <NuxtLink 
            :to="`/business-network`"
            class="flex items-center gap-2 px-3 py-1.5 text-blue-600 hover:text-blue-700 hover:underline transition-colors text-sm"
          >
            <ArrowLeft class="h-3.5 w-3.5" />
            <span>Back to feed</span>
          </NuxtLink>
        </div>
      </div>
    </div>
    
    <!-- Enhanced skeleton loaders -->
    <template v-if="loading && !loadingMore && allPosts.length === 0">
      <div class="p-4">
        <div class="relative mb-8">
          <!-- Pulse loading animation -->
          <div class="flex justify-center items-center">
            <div class="relative">
              <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
              <div class="absolute inset-0 -m-2 rounded-full animate-ping opacity-30 bg-blue-400"></div>
            </div>
          </div>
          <p class="text-center text-blue-600 text-sm font-medium mt-4">Searching for relevant posts...</p>
        </div>
        
        <!-- Enhanced skeleton loaders for posts -->
        <div
          v-for="i in 3"
          :key="i"
          class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden mb-6 relative"
        >
          <!-- Header -->
          <div class="p-4 border-b border-gray-50">
            <div class="flex items-center space-x-3">
              <div class="w-10 h-10 rounded-full bg-gradient-to-r from-gray-200 to-gray-100 animate-pulse relative overflow-hidden">
                <div class="absolute inset-0 bg-gray-100 animate-pulse-wave"></div>
              </div>
              <div class="flex-1 space-y-2">
                <div class="h-3.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-1/4"></div>
                <div class="h-2.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-1/6"></div>
              </div>
              <div class="h-7 w-7 rounded-md bg-gradient-to-r from-gray-200 to-gray-100 animate-pulse"></div>
            </div>
          </div>
          
          <!-- Content -->
          <div class="p-4">
            <!-- Content lines -->
            <div class="space-y-3 mb-4">
              <div class="h-3.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-3/4"></div>
              <div class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-full"></div>
              <div class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-5/6"></div>
              <div class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-4/6"></div>
            </div>
            
            <!-- Media placeholder -->
            <div class="h-40 bg-gradient-to-r from-gray-200 to-gray-100 rounded-lg animate-pulse mb-4 overflow-hidden relative">
              <div class="absolute inset-0 bg-gray-100 animate-pulse-slower opacity-50"></div>
              <div class="absolute inset-0 flex items-center justify-center">
                <div class="w-10 h-10 rounded-full bg-white/30 flex items-center justify-center">
                  <Image class="w-5 h-5 text-white/50" />
                </div>
              </div>
            </div>
            
            <!-- Action buttons -->
            <div class="flex justify-between items-center pt-2 border-t border-gray-50">
              <div class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"></div>
              <div class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"></div>
              <div class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"></div>
            </div>
          </div>
          
          <!-- Tag indicators at bottom -->
          <div class="px-4 pb-4 flex gap-2">
            <div class="h-5 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-16"></div>
            <div class="h-5 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"></div>
          </div>
        </div>
      </div>
    </template>
    
    <!-- Actual posts displayed after loading -->
    <div class="relative">
      <!-- Search result count when posts are loaded -->
      <div v-if="!loading && displayedPosts.length > 0" class="mb-4 text-sm text-gray-500 px-1">
        Showing {{ displayedPosts.length }} {{ displayedPosts.length === 1 ? 'result' : 'results' }} for "<span class="font-medium text-gray-700">{{ $route.params.search }}</span>"
      </div>
      
      <BusinessNetworkPost
        v-if="!loading || allPosts.length > 0"
        :posts="displayedPosts"
        :id="user?.user?.id"
        class="result-card"
        @gift-sent="handleGiftSent"
      />
    </div>

    <!-- Enhanced load more indicator with improved skeleton -->
    <div v-if="loadingMore && !loading" class="pb-6">
      <div class="flex justify-center items-center py-4">
        <div class="relative">
          <Loader2 class="h-8 w-8 text-blue-600 animate-spin" />
          <div class="absolute inset-0 -m-1 rounded-full animate-ping opacity-30 bg-blue-400"></div>
        </div>
      </div>
      
      <!-- Enhanced skeleton loader for loading more posts -->
      <div class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden mb-6 relative">
        <!-- Header -->
        <div class="p-4 border-b border-gray-50">
          <div class="flex items-center space-x-3">
            <div class="w-10 h-10 rounded-full bg-gradient-to-r from-gray-200 to-gray-100 animate-pulse relative overflow-hidden">
              <div class="absolute inset-0 bg-gray-100 animate-pulse-wave"></div>
            </div>
            <div class="flex-1 space-y-2">
              <div class="h-3.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-1/4"></div>
              <div class="h-2.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-1/6"></div>
            </div>
            <div class="h-7 w-7 rounded-md bg-gradient-to-r from-gray-200 to-gray-100 animate-pulse"></div>
          </div>
        </div>
        
        <!-- Content -->
        <div class="p-4">
          <!-- Content lines -->
          <div class="space-y-3 mb-4">
            <div class="h-3.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-3/4"></div>
            <div class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-full"></div>
            <div class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-5/6"></div>
          </div>
          
          <!-- Action buttons -->
          <div class="flex justify-between items-center pt-2 border-t border-gray-50">
            <div class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"></div>
            <div class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"></div>
            <div class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"></div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Enhanced end of results indicator -->
    <div
      v-if="!loading && !loadingMore && !hasMore && allPosts.length > 0"
      class="flex flex-col items-center justify-center py-8 text-center"
    >
      <div class="relative mb-4">
        <div
          class="w-16 h-16 rounded-full bg-blue-50 border border-blue-100 flex items-center justify-center"
        >
          <Check class="h-8 w-8 text-blue-600" />
        </div>
        <div class="absolute inset-0 bg-blue-50/50 rounded-full animate-ping-slow opacity-70 w-16 h-16"></div>
      </div>
      
      <h3 class="text-lg font-bold text-gray-800 mb-1">
        End of Search Results
      </h3>
      <p class="text-gray-500 mb-4 max-w-md">
        You've seen all posts matching your search for "{{ $route.params.search }}".
      </p>
      
      <div class="flex flex-col sm:flex-row gap-3 mb-8">
        <button
          @click="scrollToTop"
          class="flex items-center justify-center gap-2 px-5 py-2 text-sm bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors border border-blue-100 shadow-sm"
        >
          <ChevronUp class="h-4 w-4" />
          <span>Back to top</span>
        </button>
        
        <NuxtLink
          to="/business-network"
          class="flex items-center justify-center gap-2 px-5 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
        >
          <Home class="h-4 w-4" />
          <span>Return to feed</span>
        </NuxtLink>
      </div>
      
      <div class="bg-gray-50 rounded-lg p-4 border border-gray-100 max-w-md">
        <h4 class="font-medium text-gray-700 mb-2">Looking for something else?</h4>
        <div class="relative">
          <input
            type="text"
            placeholder="Try another search..."
            v-model="newSearchQuery"
            class="w-full border border-gray-300 rounded-lg py-2 px-4 pr-10 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
            @keyup.enter="handleNewSearch"
          />
          <button
            @click="handleNewSearch"
            class="absolute right-2 top-1/2 -translate-y-1/2 p-1 bg-blue-500 hover:bg-blue-600 text-white rounded-md transition-colors"
          >
            <Search class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Enhanced no results message -->
    <div
      v-if="!loading && !loadingMore && allPosts.length === 0"
      class="flex flex-col items-center justify-center py-12 text-center bg-white rounded-xl shadow-sm border border-gray-100 px-4"
    >
      <div class="w-16 h-16 rounded-full bg-gray-50 flex items-center justify-center mb-6 border border-gray-200">
        <Search class="h-8 w-8 text-gray-400" />
      </div>
      
      <h3 class="text-lg font-bold text-gray-800 mb-2">No results found</h3>
      <p class="text-gray-500 mb-6 max-w-md">
        We couldn't find any posts matching "{{ $route.params.search }}". Try adjusting your search terms or filters.
      </p>
      
      <div class="w-full max-w-md">
        <div class="bg-gray-50 rounded-lg p-4 mb-6 border border-gray-100">
          <h4 class="font-medium text-gray-700 mb-3">Suggestions:</h4>
          <ul class="text-sm text-gray-600 space-y-2">
            <li class="flex items-start">
              <div class="min-w-4 mr-2 mt-0.5">•</div>
              <span>Check your spelling</span>
            </li>
            <li class="flex items-start">
              <div class="min-w-4 mr-2 mt-0.5">•</div>
              <span>Try more general keywords</span>
            </li>
            <li class="flex items-start">
              <div class="min-w-4 mr-2 mt-0.5">•</div>
              <span>Use different keywords</span>
            </li>
            <li class="flex items-start">
              <div class="min-w-4 mr-2 mt-0.5">•</div>
              <span>Reset the search filters</span>
            </li>
          </ul>
        </div>
        
        <div class="relative">
          <input
            type="text"
            placeholder="Try another search..."
            v-model="newSearchQuery"
            class="w-full border border-gray-300 rounded-lg py-2.5 px-4 pr-12 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
            @keyup.enter="handleNewSearch"
          />
          <button
            @click="handleNewSearch"
            class="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 bg-blue-500 hover:bg-blue-600 text-white rounded-md transition-colors"
          >
            <Search class="h-4 w-4" />
          </button>
        </div>
        
        <div class="mt-6">
          <NuxtLink
            to="/business-network"
            class="flex items-center justify-center gap-2 px-5 py-2.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
          >
            <ArrowLeft class="h-4 w-4" />
            <span>Return to feed</span>
          </NuxtLink>
        </div>
      </div>
    </div>

    <!-- Add the create post component with event listener -->
    <BusinessNetworkCreatePost @post-created="handleNewPost" />
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
  ArrowLeft,
  Loader2,
  Check,
  ChevronUp,
  Home,
  Image,
} from "lucide-vue-next";
const route = useRoute();

// State
const allPosts = ref([]); // All loaded posts
const displayedPosts = ref([]); // Currently displayed posts
const loading = ref(true);
const loadingMore = ref(false);
const { get } = useApi();
const { user } = useAuth();
const eventBus = useEventBus();
const loadedPostIds = ref(new Set()); // Track loaded post IDs to prevent duplicates

// Search state
const newSearchQuery = ref("");

// Batch size and pagination
const POSTS_PER_BATCH = 5;
const page = ref(1);
const hasMore = ref(true);
const lastCreatedAt = ref(null); // For pagination cursor
const newestCreatedAt = ref(null); // For refresh/newer posts

// Listen for loading events from footer and sidebar
eventBus.on("start-loading-posts", () => {
  // Set loading to true immediately
  loading.value = true;
});

// Get initial posts or more posts based on pagination
async function getPosts(isLoadingMore = false, page = 1) {
  try {
    if (isLoadingMore) {
      loadingMore.value = true;
    } else {
      loading.value = true;
    }

    // Build query parameters based on action type
    let params = {
      page_size: isLoadingMore ? 1 : POSTS_PER_BATCH, // Load 1 post at a time when scrolling
    };

    if (isLoadingMore && lastCreatedAt.value) {
      // Get older posts (for pagination)
      params.older_than = lastCreatedAt.value;
    }

    console.log("Fetching posts with params:", params);

    const [response] = await Promise.all([
      get(`/bn/posts/search/?q=${route.params.search}&page=${page}`),
      // Add a minimum delay for UX, shorter for subsequent loads
      new Promise((resolve) => setTimeout(resolve, isLoadingMore ? 300 : 800)),
    ]);

    if (response.data && response.data.results) {
      const newPosts = response.data.results;

      // Process posts to ensure they have necessary UI properties
      const processedPosts = newPosts.map((post) => ({
        ...post,
        showFullDescription: false,
        showDropdown: false,
        commentText: "",
        isCommentLoading: false,
        isLikeLoading: false,
      }));

      // Filter out duplicate posts based on their IDs
      const uniquePosts = processedPosts.filter((post) => {
        if (loadedPostIds.value.has(post.id)) {
          console.log(`Filtered out duplicate post ID: ${post.id}`);
          return false;
        }
        loadedPostIds.value.add(post.id);
        return true;
      });

      console.log(
        `Found ${processedPosts.length} posts, ${uniquePosts.length} are unique`
      );

      // On initial load or load more, append to the end
      allPosts.value = isLoadingMore
        ? [...allPosts.value, ...uniquePosts]
        : uniquePosts;

      // Update pagination cursor if we got any unique posts
      if (uniquePosts.length > 0) {
        const lastPost = uniquePosts[uniquePosts.length - 1];
        lastCreatedAt.value = lastPost.created_at;

        // Set initial newest timestamp if first load
        if (!newestCreatedAt.value && uniquePosts.length > 0) {
          newestCreatedAt.value = uniquePosts[0].created_at;
          console.log("Initial newest timestamp set:", newestCreatedAt.value);
        }
      }

      if (processedPosts.length > 0 && uniquePosts.length === 0) {
        hasMore.value = false;
      } else {
        // If we got some unique posts, assume there might be more
        hasMore.value = processedPosts.length > 0;

        // If we got no posts at all, we've definitely reached the end
        if (processedPosts.length === 0) {
          hasMore.value = false;
        }
      }

      // Update displayed posts
      updateDisplayedPosts();
    } else {
      console.log("No posts returned from API");
      if (!isLoadingMore) {
        // Only clear on initial load failure
        allPosts.value = [];
        displayedPosts.value = [];
      }
      hasMore.value = false;
    }
  } catch (error) {
    console.error("Failed to load posts:", error);
    useToast().add({
      title: "Error",
      description: "Failed to load posts",
      color: "red",
      timeout: 3000,
    });

    if (!isLoadingMore) {
      allPosts.value = [];
      displayedPosts.value = [];
    }
    hasMore.value = false;
  } finally {
    loading.value = false;
    loadingMore.value = false;
  }
}

// Function to update displayed posts with proper grouping
function updateDisplayedPosts() {
  // Create a new array to avoid reactivity issues
  displayedPosts.value = [...allPosts.value];
}

// Handle gift sent event from child components
function handleGiftSent(giftData) {
  console.log("Gift sent event received:", giftData);

  // Display a toast notification
  useToast().add({
    title: "Gift Sent!",
    description: `${giftData.giftAmount} diamonds sent successfully`,
    color: "green",
    timeout: 3000,
  });

  // Reload posts after a short delay to ensure backend is updated
  setTimeout(() => {
    // Reset state and reload posts
    loadData();
  }, 20);
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

// Setup scroll detection for infinite scroll
function setupInfiniteScroll() {
  const handleScroll = () => {
    if (
      window.innerHeight + window.scrollY >=
      document.body.offsetHeight - 500
    ) {
      if (!loadingMore.value && hasMore.value) {
        loadMorePosts();
      }
    }
  };

  window.addEventListener("scroll", handleScroll);

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

  // Clean up event listeners when component is unmounted
  onUnmounted(() => {
    eventBus.off("start-loading-posts");
    eventBus.off("load-recent-posts");
  });
});

// Add this function to handle the new post
const handleNewPost = (newPost) => {
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
  updateDisplayedPosts();

  // Update newest timestamp
  if (processedNewPost.created_at) {
    newestCreatedAt.value = processedNewPost.created_at;
  }
};

// Handle new search from end of results or no results section
const handleNewSearch = () => {
  if (newSearchQuery.value && newSearchQuery.value.trim() !== '') {
    // Navigate to new search results
    navigateTo(`/business-network/search-results/${encodeURIComponent(newSearchQuery.value.trim())}`);
  }
};

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

/* Enhanced pulse animations */
@keyframes pulse-wave {
  0% {
    transform: scale(0.95);
    opacity: 0.7;
  }
  50% {
    transform: scale(1);
    opacity: 1;
  }
  100% {
    transform: scale(0.95);
    opacity: 0.7;
  }
}

@keyframes pulse-slower {
  0% {
    opacity: 0.5;
  }
  50% {
    opacity: 0.3;
  }
  100% {
    opacity: 0.5;
  }
}

@keyframes ping-slow {
  75%, 100% {
    transform: scale(1.5);
    opacity: 0;
  }
}

.animate-pulse-wave {
  animation: pulse-wave 2s ease-in-out infinite;
}

.animate-pulse-slower {
  animation: pulse-slower 3s ease-in-out infinite;
}

.animate-ping-slow {
  animation: ping-slow 2.5s cubic-bezier(0, 0, 0.2, 1) infinite;
}

/* Enhanced scrollbar for filter dropdowns */
.filter-scrollbar::-webkit-scrollbar {
  width: 4px;
}

.filter-scrollbar::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}

.filter-scrollbar::-webkit-scrollbar-thumb {
  background: #cfcfcf;
  border-radius: 10px;
}

.filter-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #a0a0a0;
}

/* Card hover effects */
.result-card {
  transition: transform 0.2s, box-shadow 0.2s;
}

.result-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}
</style>
