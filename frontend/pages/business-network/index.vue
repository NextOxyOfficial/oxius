<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 flex-1">
    <!-- Add the event listener here -->
    <BusinessNetworkPost :posts="posts" :id="user?.user?.id" />

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
  ArrowRight
} from "lucide-vue-next";

// State
const posts = ref([]);
const loading = ref(false);
const { get } = useApi();
const { user } = useAuth();

async function getPosts() {
  loading.value = true;
  try {
    const response = await get("/bn/posts/");
    posts.value = response.data.results;
    console.log(posts.value);
  } catch (error) {
    console.log(error);
  } finally {
    loading.value = false;
  }
}

await getPosts();

const page = ref(1);
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

// Add this function to handle the new post
const handleNewPost = (newPost) => {
  // Add the new post to the beginning of the posts array for immediate display
  posts.value = [newPost, ...posts.value];
};

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
</style>
