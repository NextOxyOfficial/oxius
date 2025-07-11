<template>
  <div
    class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-6 shadow-sm w-full max-w-full"
  >
    <!-- Header -->
    <div
      class="px-4 py-3 border-b border-gray-100 bg-gradient-to-r from-blue-50 to-indigo-50"
    >
      <div class="flex items-center justify-between">
        <div class="flex items-center">
          <Users class="h-5 w-5 text-blue-600 mr-2" />
          <h3 class="text-sm font-semibold text-gray-800">
            Follow the people you may know
          </h3>
        </div>        <button
          @click="refreshDisplayedSuggestions"
          :disabled="loading || isRefreshing"
          class="text-blue-600 hover:text-blue-800 disabled:opacity-50 transition-colors"
          title="Show different suggestions"
        >
          <svg
            v-if="loading || isRefreshing"
            class="h-4 w-4 animate-spin"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
          <svg
            v-else
            class="h-4 w-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
        </button>
      </div>
    </div>
    <!-- User Suggestions -->
    <div class="p-4 w-full max-w-full overflow-hidden">
      <div v-if="loading">
        <!-- Desktop: Grid Skeleton -->
        <div
          v-if="isDesktop"
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
        >
          <div
            v-for="i in 3"
            :key="i"
            class="bg-white border border-gray-200 rounded-lg p-4"
          >            <div class="flex flex-col items-center text-center space-y-3">
              <div class="size-36 rounded-lg bg-gray-200 animate-pulse"></div>
              <div class="w-full space-y-2">
                <div
                  class="h-4 bg-gray-200 rounded animate-pulse w-3/4 mx-auto"
                ></div>
                <div
                  class="h-3 bg-gray-200 rounded animate-pulse w-1/2 mx-auto"
                ></div>
              </div>
              <div class="h-8 bg-gray-200 rounded animate-pulse w-20"></div>
            </div>
          </div>
        </div>
        <!-- Mobile: Simple Grid Skeleton -->
        <div v-else class="grid grid-cols-2 gap-3">
          <div
            v-for="i in 2"
            :key="i"
            class="bg-white border border-gray-200 rounded-lg p-3"
          >            <div class="flex flex-col items-center text-center space-y-3">
              <div class="w-24 h-24 rounded-lg bg-gray-200 animate-pulse"></div>
              <div class="w-full space-y-2">
                <div
                  class="h-4 bg-gray-200 rounded animate-pulse w-3/4 mx-auto"
                ></div>
                <div
                  class="h-3 bg-gray-200 rounded animate-pulse w-1/2 mx-auto"
                ></div>
              </div>
              <div class="h-6 bg-gray-200 rounded animate-pulse w-16"></div>
            </div>
          </div>
        </div>
      </div>
      <div v-else-if="displayedSuggestions.length > 0">
        <!-- Desktop: Grid Layout -->
        <div
          v-if="isDesktop"
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
        >
          <div
            v-for="user in displayedSuggestions"
            :key="user.id"
            class="bg-white border border-gray-200 rounded-lg p-4"
          >
            <!-- User Info Card -->
            <div class="flex flex-col items-center text-center space-y-3">
              <!-- Profile Picture -->              
               <NuxtLink :to="`/business-network/profile/${user.id}`">
                <img
                  :src="user.image || '/static/frontend/images/placeholder.jpg'"
                  :alt="getUserDisplayName(user)"
                  class="size-36 rounded-lg object-cover border-2 border-white shadow-sm"
                />
              </NuxtLink>

              <!-- User Details -->
              <div class="flex-1 min-w-0 w-full">
                <NuxtLink
                  :to="`/business-network/profile/${user.id}`"
                  class="block"
                >
                  <h4
                    class="font-semibold text-gray-900 truncate hover:text-blue-600 transition-colors text-sm"
                  >
                    {{ getUserDisplayName(user) }}
                  </h4>
                </NuxtLink>
                <!-- Mutual connections -->
                <div
                  v-if="user.mutual_connections > 0"
                  class="text-xs text-blue-600 mt-1"
                >
                  {{ user.mutual_connections }} mutual connection{{
                    user.mutual_connections > 1 ? "s" : ""
                  }}
                </div>
              </div>
              <!-- Follow Button -->
              <button
                @click="toggleFollow(user)"
                :disabled="user.isFollowing === 'pending'"
                class="px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                :class="getFollowButtonClass(user)"
              >
                <span
                  v-if="user.isFollowing === 'pending'"
                  class="flex items-center justify-center"
                >
                  <Loader2 class="h-4 w-4 animate-spin mr-1" />
                  Loading...
                </span>
                <span
                  v-else-if="user.isFollowing"
                  class="flex items-center justify-center"
                >
                  <UserCheck class="h-4 w-4 mr-1" />
                  Following
                </span>
                <span v-else class="flex items-center justify-center">
                  <UserPlus class="h-4 w-4 mr-1" />
                  Follow
                </span>
              </button>
            </div>
          </div>
        </div>
        <!-- Mobile: Simple Grid Layout -->
        <div v-else class="grid grid-cols-2 gap-3">
          <div
            v-for="user in displayedSuggestions"
            :key="user.id"
            class="bg-white border border-gray-200 rounded-lg p-3 hover:shadow-md transition-shadow duration-200"
          >
            <!-- User Info Card -->
            <div class="flex flex-col items-center text-center space-y-3">
              <!-- Profile Picture -->              
               <NuxtLink :to="`/business-network/profile/${user.id}`">
                <img
                  :src="user.image || '/static/frontend/images/placeholder.jpg'"
                  :alt="getUserDisplayName(user)"
                  class="w-36 h-32 rounded-lg object-cover border-2 border-white shadow-sm hover:shadow-md transition-shadow"
                />
              </NuxtLink>

              <!-- User Details -->
              <div class="flex-1 min-w-0 w-full">
                <NuxtLink
                  :to="`/business-network/profile/${user.id}`"
                  class="block"
                >
                  <h4
                    class="font-semibold text-gray-900 truncate hover:text-blue-600 transition-colors text-sm"
                  >
                    {{ getUserDisplayName(user) }}
                  </h4>
                </NuxtLink>
                <!-- Mutual connections -->
                <div
                  v-if="user.mutual_connections > 0"
                  class="text-xs text-blue-600 mt-1"
                >
                  {{ user.mutual_connections }} mutual connection{{
                    user.mutual_connections > 1 ? "s" : ""
                  }}
                </div>
              </div>

              <!-- Follow Button -->
              <button
                @click="toggleFollow(user)"
                :disabled="user.isFollowing === 'pending'"
                class="px-3 py-1.5 text-xs font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                :class="getFollowButtonClass(user)"
              >
                <span
                  v-if="user.isFollowing === 'pending'"
                  class="flex items-center justify-center"
                >
                  <Loader2 class="h-3 w-3 animate-spin mr-1" />
                  Loading...
                </span>
                <span
                  v-else-if="user.isFollowing"
                  class="flex items-center justify-center"
                >
                  <UserCheck class="h-3 w-3 mr-1" />
                  Following
                </span>
                <span v-else class="flex items-center justify-center">
                  <UserPlus class="h-3 w-3 mr-1" />
                  Follow
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div v-else-if="!loading" class="text-center py-6">
        <Users class="h-12 w-12 text-gray-300 mx-auto mb-2" />
        <p class="text-gray-500 text-sm">
          {{ error || "No suggestions available right now" }}
        </p>
        <button
          @click="fetchSuggestions"
          class="mt-2 text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          Try again
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Users, UserPlus, UserCheck, Loader2 } from "lucide-vue-next";

const props = defineProps({
  currentUserId: {
    type: [String, Number],
    default: null,
  },
});

// Get API utilities
const { get, post: apiPost } = useApi();
const toast = useToast();

// Reactive data
const suggestions = ref([]);
const allSuggestions = ref([]); // Store all suggestions from API
const loading = ref(true);
const error = ref(null);
const isRefreshing = ref(false);

// Responsive display logic
const isDesktop = ref(true);

// Utility function to shuffle array
const shuffleArray = (array) => {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
};

// Function to get random suggestions from all available suggestions
const getRandomSuggestions = () => {
  if (allSuggestions.value.length === 0) return [];
  
  const shuffled = shuffleArray(allSuggestions.value);
  const maxSuggestions = isDesktop.value ? 3 : 2;
  return shuffled.slice(0, maxSuggestions);
};

const displayedSuggestions = computed(() => {
  return suggestions.value;
});

// Check screen size and update displayed suggestions
const checkScreenSize = () => {
  if (process.client) {
    const newIsDesktop = window.innerWidth >= 768; // md breakpoint
    if (newIsDesktop !== isDesktop.value) {
      isDesktop.value = newIsDesktop;
      // Refresh displayed suggestions when screen size changes
      if (allSuggestions.value.length > 0) {
        suggestions.value = getRandomSuggestions();
      }
    }
  }
};

// Listen for window resize and fetch initial suggestions
onMounted(() => {
  checkScreenSize();
  if (process.client) {
    window.addEventListener("resize", checkScreenSize);
  }
  
  // Fetch initial suggestions
  fetchSuggestions();
  
  // Set up periodic refresh of displayed suggestions (every 30 seconds)
  const refreshInterval = setInterval(() => {
    if (allSuggestions.value.length > 0) {
      refreshDisplayedSuggestions();
    }
  }, 30000); // 30 seconds
  
  // Cleanup interval on unmount
  onUnmounted(() => {
    clearInterval(refreshInterval);
  });
});

onUnmounted(() => {
  if (process.client) {
    window.removeEventListener("resize", checkScreenSize);
  }
});

// Get user display name
const getUserDisplayName = (user) => {
  if (user.first_name && user.last_name) {
    return `${user.first_name} ${user.last_name}`;
  }
  return user.username || "Unknown User";
};

// Format follower count
const formatFollowerCount = (count) => {
  if (count >= 1000000) {
    return `${(count / 1000000).toFixed(1)}M`;
  } else if (count >= 1000) {
    return `${(count / 1000).toFixed(1)}K`;
  }
  return count.toString();
};

// Get follow button styling
const getFollowButtonClass = (user) => {
  if (user.isFollowing === "pending") {
    return "bg-gray-100 text-gray-600 cursor-not-allowed";
  } else if (user.isFollowing) {
    return "bg-green-100 text-green-700 hover:bg-green-200 border border-green-200";
  } else {
    return "bg-blue-600 text-white hover:bg-blue-700 active:bg-blue-800";
  }
};

// Fetch user suggestions
const fetchSuggestions = async () => {
  try {
    loading.value = true;
    error.value = null;

    // Check if user is authenticated first
    const { isAuthenticated } = useAuth();
    if (!isAuthenticated.value) {
      error.value = "Please log in to see suggestions";
      suggestions.value = [];
      return;
    }

    const { get } = useApi();
    const response = await get("/bn/user-suggestions/");

    // Handle the response object structure from useApi
    if (response.error) {
      console.error("API Error:", response.error);
      if (response.error.statusCode === 401) {
        error.value = "Please log in to see suggestions";
      } else {
        error.value = "Failed to load suggestions";
      }      allSuggestions.value = [];
      suggestions.value = [];
    } else if (
      response.data &&
      Array.isArray(response.data) &&
      response.data.length > 0
    ) {
      // Direct array response from the fixed backend
      allSuggestions.value = response.data.map((user) => ({
        ...user,
        isFollowing: false,
        mutual_connections: 0, // Simplified API doesn't include this
      }));
      
      // Set random suggestions for display
      suggestions.value = getRandomSuggestions();    } else {
      error.value = "No suggestions available right now";
      allSuggestions.value = [];
      suggestions.value = [];
    }
  } catch (err) {
    console.error("Error fetching user suggestions:", err);
    error.value = "Failed to load suggestions";
    allSuggestions.value = [];
    suggestions.value = [];
  } finally {
    loading.value = false;
  }
};

// Refresh displayed suggestions without refetching from API
const refreshDisplayedSuggestions = () => {
  if (allSuggestions.value.length > 0) {
    isRefreshing.value = true;
    suggestions.value = getRandomSuggestions();
    
    // Brief animation delay
    setTimeout(() => {
      isRefreshing.value = false;
    }, 300);
  } else {
    // If no cached suggestions, fetch new ones
    fetchSuggestions();
  }
};

// Toggle follow status
const toggleFollow = async (user) => {
  if (!props.currentUserId || user.isFollowing === "pending") return;

  const originalState = user.isFollowing;

  try {
    user.isFollowing = "pending";

    const endpoint = originalState
      ? `/bn/users/${user.id}/unfollow/`
      : `/bn/users/${user.id}/follow/`;

    const response = await apiPost(endpoint, {});

    // Handle the response object structure from useApi
    if (response.error) {
      console.error("Follow API Error:", response.error);
      throw new Error("Failed to update follow status");
    } else if (response.data) {
      user.isFollowing = !originalState;
      // With the simplified backend, we no longer track follower_count
      // But we keep the isFollowing state
      // Keep the user in the suggestions list to show "Following" status
    } else {
      throw new Error("Failed to update follow status");
    }
  } catch (err) {
    console.error("Error toggling follow:", err);
    user.isFollowing = originalState; // Revert on error

    // Show error message
    toast?.add?.({
      title: "Error",
      description: "Failed to update follow status",      
      color: "red",
    });
  }
};

// Expose methods for parent component
defineExpose({
  refreshSuggestions: fetchSuggestions,
  shuffleSuggestions: refreshDisplayedSuggestions,
});
</script>

<style scoped>
/* Add any additional custom styles here */
.transition-all {
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}
</style>
