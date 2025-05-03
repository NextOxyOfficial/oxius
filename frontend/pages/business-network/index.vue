<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 flex-1">
    <!-- Lazyloader component to display while initial posts are loading -->
    <template v-if="loading && !loadingMore && allPosts.length === 0">
      <div class="p-4">
        <div class="flex justify-center items-center mb-6">
          <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
        </div>
        <!-- Skeleton loaders for posts -->
        <div v-for="i in 3" :key="i" class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4">
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
      v-if="!loading || (allPosts.length > 0)" 
      :posts="displayedPosts" 
      :id="user?.user?.id" 
    />

    <!-- Load more indicator -->
    <div v-if="loadingMore && !loading" class="flex justify-center py-6">
      <div class="h-6 w-6 animate-spin text-blue-600">
        <Loader2 />
      </div>
    </div>
    
    <!-- End of feed indicator - shows when all posts are loaded -->
    <div 
      v-if="!loading && !loadingMore && !hasMore && allPosts.length > 0"
      class="flex flex-col items-center justify-center py-8 text-center"
    >
      <div class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4">
        <Check class="h-8 w-8 text-blue-600" />
      </div>
      <h3 class="text-lg font-medium text-gray-800 mb-1">You're all caught up!</h3>
      <p class="text-gray-500 mb-8 max-w-md">You've seen all posts in the business network feed.</p>
      <button 
        @click="scrollToTop" 
        class="flex items-center gap-2 px-4 py-2 text-sm bg-blue-50 text-blue-600 rounded-full hover:bg-blue-100 transition-colors"
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
      <p class="text-gray-500 mb-2">{{ $t("no_post_available") }}</p>
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
          class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-hidden"
          @click.stop
        >
          <div class="p-4 border-b border-gray-200 sticky top-0 bg-white">
            <div class="flex items-center gap-3">
              <div class="relative flex-1">
                <div
                  class="absolute inset-y-0 left-3 flex items-center pointer-events-none"
                >
                  <Search class="h-5 w-5 text-gray-400" />
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
            <h3 class="text-sm font-medium text-gray-500 mb-2">
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
                      <Search class="h-4 w-4 text-gray-500" />
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
              <h3 class="text-sm font-medium text-gray-500 mb-2">
                Recent Searches
              </h3>
              <ul class="space-y-3">
                <li v-for="(term, index) in recentSearches" :key="index">
                  <button
                    class="flex items-center gap-3 w-full p-3 hover:bg-gray-50 rounded-lg transition-colors"
                    @click="handleSearch(term)"
                  >
                    <div class="bg-gray-100 rounded-full p-2">
                      <Clock class="h-4 w-4 text-gray-500" />
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
  ChevronUp
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

// Batch size and pagination
const POSTS_PER_BATCH = 5;
const page = ref(1);
const hasMore = ref(true);
const lastCreatedAt = ref(null); // For pagination cursor
const newestCreatedAt = ref(null); // For refresh/newer posts

// Listen for loading events from footer and sidebar
eventBus.on('start-loading-posts', () => {
  // Set loading to true immediately
  loading.value = true;
});

// Get initial posts or more posts based on pagination
async function getPosts(isLoadingMore = false) {
  try {
    if (isLoadingMore) {
      loadingMore.value = true;
    } else {
      loading.value = true;
    }
    
    // Build query parameters based on action type
    let params = {
      page_size: isLoadingMore ? 1 : POSTS_PER_BATCH // Load 1 post at a time when scrolling
    };
    
    if (isLoadingMore && lastCreatedAt.value) {
      // Get older posts (for pagination)
      params.older_than = lastCreatedAt.value;
    }
    
    console.log('Fetching posts with params:', params);
    
    const [response] = await Promise.all([
      get("/bn/posts/", { params }),
      // Add a minimum delay for UX, shorter for subsequent loads
      new Promise(resolve => setTimeout(resolve, isLoadingMore ? 300 : 800))
    ]);
    
    if (response.data && response.data.results) {
      const newPosts = response.data.results;
      
      // Process posts to ensure they have necessary UI properties
      const processedPosts = newPosts.map(post => ({
        ...post,
        showFullDescription: false,
        showDropdown: false,
        commentText: '',
        isCommentLoading: false,
        isLikeLoading: false,
      }));
      
      // Filter out duplicate posts based on their IDs
      const uniquePosts = processedPosts.filter(post => {
        if (loadedPostIds.value.has(post.id)) {
          console.log(`Filtered out duplicate post ID: ${post.id}`);
          return false;
        }
        loadedPostIds.value.add(post.id);
        return true;
      });
      
      console.log(`Found ${processedPosts.length} posts, ${uniquePosts.length} are unique`);
      
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
          console.log('Initial newest timestamp set:', newestCreatedAt.value);
        }
      }
      
      // Check if we have more posts to load
      // If we received posts but all were duplicates, or if we received no posts at all,
      // then we've reached the end
      if (processedPosts.length > 0 && uniquePosts.length === 0) {
        hasMore.value = false;
        
        useToast().add({
          title: 'You\'re all caught up!',
          description: 'You\'ve reached the end of the feed',
          color: 'blue',
          timeout: 3000
        });
      } else {
        // If we got some unique posts, assume there might be more
        hasMore.value = processedPosts.length > 0;
        
        // If we got no posts at all, we've definitely reached the end
        if (processedPosts.length === 0) {
          hasMore.value = false;
          
          if (isLoadingMore) {
            useToast().add({
              title: 'You\'re all caught up!',
              description: 'You\'ve reached the end of the feed',
              color: 'blue',
              timeout: 3000
            });
          }
        }
      }
      
      // Update displayed posts
      updateDisplayedPosts();
      
    } else {
      console.log('No posts returned from API');
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
      title: 'Error',
      description: 'Failed to load posts',
      color: 'red',
      timeout: 3000
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
  getPosts(true);
}

// Setup scroll detection for infinite scroll
function setupInfiniteScroll() {
  const handleScroll = () => {
    if (window.innerHeight + window.scrollY >= document.body.offsetHeight - 500) {
      if (!loadingMore.value && hasMore.value) {
        loadMorePosts();
      }
    }
  };

  window.addEventListener('scroll', handleScroll);

  // Remove event listener on component unmount
  onUnmounted(() => {
    window.removeEventListener('scroll', handleScroll);
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
  eventBus.on('start-loading-posts', () => {
    loadData();
  });
  
  // Listen for the specific recent posts loading event
  eventBus.on('load-recent-posts', () => {
    loadRecentPosts();
  });
  
  // Clean up event listeners when component is unmounted
  onUnmounted(() => {
    eventBus.off('start-loading-posts');
    eventBus.off('load-recent-posts');
  });
});

// Add this function to handle the new post
const handleNewPost = (newPost) => {
  // Process the new post to ensure it has necessary UI properties
  const processedNewPost = {
    ...newPost,
    showFullDescription: false,
    showDropdown: false,
    commentText: '',
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

// Function to specifically load recent posts (newest 10)
function loadRecentPosts() {
  // Reset state
  loading.value = true;
  page.value = 1;
  hasMore.value = true;
  lastCreatedAt.value = null;
  loadedPostIds.value.clear(); // Reset tracked post IDs
  allPosts.value = []; // Clear existing posts
  displayedPosts.value = []; // Clear displayed posts

  // Set a small delay for better UX (showing skeleton)
  setTimeout(() => {
    // Use specific params for recent posts
    const params = {
      page_size: 10, // Get 10 most recent posts
      sort: 'recent' // Sort parameter for recent posts
    };
    
    // Call API with specific parameters for recent posts
    get("/bn/posts/", { params })
      .then(response => {
        if (response.data && response.data.results) {
          const newPosts = response.data.results;
          
          // Process posts
          const processedPosts = newPosts.map(post => ({
            ...post,
            showFullDescription: false,
            showDropdown: false,
            commentText: '',
            isCommentLoading: false,
            isLikeLoading: false,
          }));
          
          // Track post IDs to prevent duplicates
          processedPosts.forEach(post => {
            loadedPostIds.value.add(post.id);
          });
          
          // Set posts
          allPosts.value = processedPosts;
          
          // Update cursor for pagination
          if (processedPosts.length > 0) {
            const lastPost = processedPosts[processedPosts.length - 1];
            lastCreatedAt.value = lastPost.created_at;
            
            // Set newest timestamp for potential refresh
            newestCreatedAt.value = processedPosts[0].created_at;
          }
          
          // Check if we have more posts to load
          hasMore.value = processedPosts.length === 10;
          
          // Update displayed posts
          updateDisplayedPosts();
        }
      })
      .catch(error => {
        console.error("Failed to load recent posts:", error);
        useToast().add({
          title: 'Error',
          description: 'Failed to load recent posts',
          color: 'red',
          timeout: 3000
        });
      })
      .finally(() => {
        loading.value = false;
      });
  }, 500); // Slightly longer delay to ensure skeleton shows
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

// Search functions
const toggleCategory = (category) => {
  if (selectedCategories.value.includes(category)) {
    selectedCategories.value = selectedCategories.value.filter(
      (c) => c !== category
    );
  } else {
    selectedCategories.value.push(category);
  }
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
