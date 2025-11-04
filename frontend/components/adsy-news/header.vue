<template>
  <div>
    <header class="sticky top-0 z-40 bg-white shadow-sm">
      <div class="max-w-7xl mx-auto">
        <!-- Main Navigation - REVISED LAYOUT -->
        <div
          class="flex items-center justify-between pl-2 pr-3 py-3 sm:py-4 lg:py-5 sm:px-6 lg:px-8"
        >
          <!-- Logo - Now in the same row with increased size -->
          <NuxtLink to="/adsy-news" class="flex-shrink-0 mr-3">
            <NuxtImg
              v-if="logo?.image"
              :src="logo.image"
              alt="Adsy News Logo"
              width="120"
              height="40"
              class="h-7 sm:h-9 w-auto object-cover"
            />
            <img
              v-else
              src="/static/frontend/images/logo.png"
              alt="AdsyClub Logo"
              class="h-7 sm:h-9 w-auto object-contain"
            />
          </NuxtLink>

          <!-- Desktop Nav Categories - Middle section -->
          <nav
            class="hidden md:flex flex-1 justify-center space-x-4 lg:space-x-8"
            v-if="categories?.length > 0"
            ref="moreMenuRef"
            @click.stop
          >
            <NuxtLink
              v-for="category in categories.slice(0, 5)"
              :key="category.id"
              :class="[
                'text-sm font-medium hover:text-primary transition-colors duration-200 py-1',
                activeCategory === category.id
                  ? 'text-primary border-b-2 border-primary'
                  : 'text-gray-800',
              ]"
              :to="`/adsy-news/categories/${category.slug}/`"
            >
              {{ category.name }}
            </NuxtLink>
            <div class="relative mt-1" v-if="categories.length > 4">
              <button
                @click="toggleMoreCategories"
                class="flex items-center text-sm font-medium text-gray-800 hover:text-primary transition-colors duration-200"
              >
                More
                <UIcon
                  name="i-heroicons-arrow-small-down-20-solid"
                  class="ml-1"
                />
              </button>
              <!-- More menu dropdown - unchanged -->
              <div
                v-if="moreMenuOpen"
                class="absolute top-full right-0 mt-1 bg-white shadow-sm rounded-md py-2 z-50 w-48 overflow-y-auto border border-gray-200 transform origin-top-right"
              >
                <NuxtLink
                  v-for="category in categories"
                  :key="category.id"
                  :class="[
                    'block px-4 py-2 text-sm hover:bg-gray-100 transition-colors',
                    activeCategory === category.id
                      ? 'text-primary'
                      : 'text-gray-800',
                  ]"
                  :to="`/adsy-news/categories/${category.slug}/`"
                >
                  {{ category.name }}
                </NuxtLink>
              </div>
            </div>
          </nav>

          <!-- Right side actions - search and buttons -->
          <div class="flex items-center space-x-1 sm:space-x-3">
            <!-- Search icon -->
            <button
              @click="toggleSearch"
              class="flex items-center justify-center h-9 w-9 rounded-full hover:bg-gray-100 text-gray-600 transition-colors"
              aria-label="Search"
            >
              <SearchIcon class="h-5 w-5" />
            </button>            <!-- Navigation Buttons -->
            <NuxtLink
              @click="handleButtonClick('adsyclub')"
              to="/"
              class="flex items-center gap-1.5 px-2.5 py-1.5 sm:px-3 sm:py-2 rounded-full text-xs sm:text-sm font-medium text-white bg-gradient-to-r from-blue-600 to-indigo-700 hover:from-blue-700 hover:to-indigo-800 transition-all"
              aria-label="Go to AdsyClub"
            >
              <div v-if="loadingButtons.adsyclub" class="spinner-white"></div>
              <BarChartBig v-else class="h-3.5 w-3.5 sm:h-4 sm:w-4" />
              <span>AdsyClub</span>
            </NuxtLink>

            <NuxtLink
              @click="handleButtonClick('adsybn')"
              to="/business-network"
              class="flex items-center gap-1.5 px-2.5 py-1.5 sm:px-3 sm:py-2 rounded-full text-xs sm:text-sm font-medium text-white bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 transition-all"
              aria-label="Go to Business Network"
            >
              <div v-if="loadingButtons.adsybn" class="spinner-white"></div>
              <Globe v-else class="h-3.5 w-3.5 sm:h-4 sm:w-4" />
              <span class="whitespace-nowrap">Adsy BN</span>
            </NuxtLink>
          </div>
        </div>

        <!-- Mobile Category Nav - CENTERED WITH FIXED DROPDOWN -->
        <div class="px-4 sm:px-6 lg:px-8">
          <nav
            class="flex md:hidden flex-1 justify-center space-x-4 lg:space-x-8"
            v-if="categories?.length > 0"
            ref="moreMenuRef"
          >
            <NuxtLink
              v-for="category in categories.slice(0, 4)"
              :key="category.id"
              :class="[
                'text-sm font-medium hover:text-primary transition-colors duration-200 py-1',
                activeCategory === category.id
                  ? 'text-primary border-b-2 border-primary'
                  : 'text-gray-800',
              ]"
              :to="`/adsy-news/categories/${category.slug}/`"
            >
              {{ category.name }}
            </NuxtLink>
            <div
              class="relative mt-1 flex-shrink-0"
              v-if="categories.length > 4"
            >
              <button
                @click="toggleMoreCategories"
                class="flex items-center text-sm font-medium text-gray-800 hover:text-primary transition-colors duration-200"
              >
                More
                <UIcon
                  name="i-heroicons-arrow-small-down-20-solid"
                  class="ml-1"
                />
              </button>
              <!-- More menu dropdown - unchanged -->
              <div
                v-if="moreMenuOpen"
                class="absolute top-full right-0 mt-1 bg-white shadow-sm rounded-md py-2 z-50 w-48 overflow-y-auto border border-gray-200 transform origin-top-right"
              >
                <NuxtLink
                  v-for="category in categories"
                  :key="category.id"
                  :class="[
                    'block px-4 py-2 text-sm hover:bg-gray-100 transition-colors',
                    activeCategory === category.id
                      ? 'text-primary'
                      : 'text-gray-800',
                  ]"
                  :to="`/adsy-news/categories/${category.slug}/`"
                >
                  {{ category.name }}
                </NuxtLink>
              </div>
            </div>
          </nav>
        </div>
      </div>
    </header>

    <!-- Search Overlay -->
    <div
      v-if="isSearchVisible"
      class="fixed inset-0 bg-black/20 backdrop-blur-sm z-50 flex items-start justify-center pt-20 px-4 sm:px-0"
      @click="isSearchVisible = false"
    >
      <div
        class="bg-white rounded-lg shadow-sm w-full max-w-lg transform transition-all duration-300 overflow-hidden"
        @click.stop
      >
        <div class="p-4 border-b border-gray-100">
          <div class="relative">
            <SearchIcon
              class="h-5 w-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-600"
            />
            <input
              type="text"
              placeholder="Search news articles..."
              v-model="searchQuery"
              class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-full text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent bg-gray-50 text-gray-800"
              @input="handleSearchInput"
              ref="searchInputRef"
            />
            <button
              v-if="searchQuery"
              @click="clearSearch"
              class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-600 hover:text-gray-600"
            >
              <XIcon class="h-4 w-4" />
            </button>
          </div>
        </div>

        <div
          v-if="searchQuery"
          class="divide-y divide-gray-100 max-h-[60vh] overflow-y-auto"
        >
          <div
            v-for="result in searchResults"
            :key="result.id"
            class="p-4 hover:bg-gray-50 cursor-pointer transition-colors"
            @click="navigateToArticle(result)"
          >
            <p class="font-medium text-gray-800 line-clamp-2 mb-1">
              {{ result.title }}
            </p>
            <div class="flex items-center text-xs text-gray-600">
              <CalendarIcon class="h-3 w-3 mr-1" />
              {{ formatDate(result.created_at) }}
              <span class="mx-2">•</span>
              <span
                class="bg-primary/10 text-primary px-2 py-0.5 rounded-full text-xs capitalize"
              >
                {{
                  result.categories && result.categories.length > 0
                    ? result.categories[0].title
                    : "News"
                }}
              </span>
            </div>
          </div>

          <div
            v-if="searchResults.length === 0 && !isSearching && searchQuery"
            class="p-6 text-center text-gray-600"
          >
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
              />
            </svg>
            <p class="mt-4">No results found for "{{ searchQuery }}"</p>
            <p class="text-sm mt-2">
              Try using different keywords or check spelling
            </p>
          </div>

          <div v-if="isSearching" class="p-6 text-center">
            <div
              class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary mx-auto"
            ></div>
            <p class="mt-4 text-gray-600">Searching...</p>
          </div>
        </div>

        <div v-if="!searchQuery" class="p-6 text-center text-gray-600">
          <SearchIcon class="mx-auto h-8 w-8 text-gray-400 mb-2" />
          <p>Type to start searching</p>
          <p class="text-xs mt-1">Press ESC to close</p>
        </div>
      </div>
    </div>

    <!-- Breaking News Ticker -->
    <UContainer>
      <div
        class="bg-primary text-white py-2.5 px-4 sm:px-6 rounded-lg shadow-sm mt-3 mb-6 sm:mb-8"
      >
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <span
              class="font-semibold text-xs sm:text-base mr-3 sm:mr-4 border-r border-white/30 pr-3 sm:pr-4"
              >BREAKING</span
            >
          </div>
          <div class="overflow-hidden relative w-full">
            <transition-group
              name="ticker"
              tag="div"
              class="flex whitespace-nowrap ticker-container"
            >
              <p
                v-for="(news, index) in breakingNews"
                :key="index"
                class="ticker-item px-4 capitalize text-sm sm:text-base"
              >
                {{ news.title }}
              </p>
            </transition-group>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
const { get } = useApi();
const logo = ref({});

// Loading state for buttons
const loadingButtons = ref({});

// Handle button click with loading state
const handleButtonClick = (buttonId) => {
  loadingButtons.value[buttonId] = true;
  
  // Clear loading state after a brief delay
  setTimeout(() => {
    loadingButtons.value[buttonId] = false;
  }, 800);
};

// Clear loading states on route change
watch(() => useRoute().path, () => {
  loadingButtons.value = {};
});

async function getLogo() {
  try {
    const { data } = await get("/news-logo/");
    logo.value = data;
    console.log('News Logo loaded:', data);
  } catch (error) {
    console.warn('Failed to load News logo, using fallback:', error);
    logo.value = {};
  }
}
await getLogo();

import {
  SunIcon,
  XIcon,
  SearchIcon,
  CalendarIcon,
  CloudIcon,
  CloudRainIcon,
  Globe, // Added for Business Network
  BarChartBig, // Added for AdsyClub
} from "lucide-vue-next";

// Debounce utility function
function debounce(func, wait) {
  let timeout;
  return function (...args) {
    const context = this;
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(context, args), wait);
  };
}

// Navigation state
const moreMenuOpen = ref(false);
const moreMenuRef = ref(null);

const toggleMoreCategories = () => {
  moreMenuOpen.value = !moreMenuOpen.value;
};
const handleClickOutsideCategory = (event) => {
  if (moreMenuRef.value && !moreMenuRef.value.contains(event.target)) {
    moreMenuOpen.value = false;
  }
};

onMounted(() => {
  document.addEventListener("click", handleClickOutside);
  document.addEventListener("click", handleClickOutsideCategory);
});

onBeforeUnmount(() => {
  document.removeEventListener("click", handleClickOutside);
  document.removeEventListener("click", handleClickOutsideCategory);
});

// Search state
const searchQuery = ref("");
const searchResults = ref([]);
const isSearching = ref(false);
const isSearchVisible = ref(false);

// Add search input ref for focusing
const searchInputRef = ref(null);

// Update toggle search to focus input
const toggleSearch = () => {
  isSearchVisible.value = !isSearchVisible.value;

  // Focus the search input when the search bar is made visible
  if (isSearchVisible.value) {
    nextTick(() => {
      searchInputRef.value?.focus();
    });
  }
};

// Close search dropdown when clicking outside
const handleClickOutside = (event) => {
  const searchDropdown = document.querySelector(".search-dropdown");
  const searchIcon = document.querySelector(".search-icon");
  if (
    searchDropdown &&
    !searchDropdown.contains(event.target) &&
    searchIcon &&
    !searchIcon.contains(event.target)
  ) {
    isSearchVisible.value = false;
  }
};

// Add keyboard event listener for ESC key
onMounted(() => {
  // Don't remove your existing event listener
  document.addEventListener("click", handleClickOutside);

  // Add keyboard listener
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && isSearchVisible.value) {
      isSearchVisible.value = false;
    }
  });
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
  // document.removeEventListener("keydown", handleEscKey);
});

// Perform search when query changes
const performSearch = async () => {
  if (!searchQuery.value.trim()) {
    searchResults.value = [];
    return;
  }

  try {
    isSearching.value = true;
    // Make API call to fetch search results
    const { data } = await get(
      `/news/posts/?search=${encodeURIComponent(searchQuery.value.trim())}`
    );

    if (data && data.results) {
      searchResults.value = data.results;
    } else {
      searchResults.value = [];
    }
  } catch (error) {
    console.error("Error searching news:", error);
    searchResults.value = [];
  } finally {
    isSearching.value = false;
  }
};

// Debounce the search function to avoid too many API calls
const debouncedSearch = debounce(performSearch, 300);

// Clear search
const clearSearch = () => {
  searchQuery.value = "";
  searchResults.value = [];
};

// Function to handle input events
const handleSearchInput = () => {
  if (!searchQuery.value.trim()) {
    searchResults.value = [];
    return;
  }
  debouncedSearch();
};

// Navigate to article detail page when clicking on search result
const router = useRouter();
const navigateToArticle = (article) => {
  // Clear the search
  searchQuery.value = "";
  searchResults.value = [];
  isSearchVisible.value = false;

  // Navigate to the article detail page
  router.push(`/adsy-news/${article.slug}/`);
};

// Helper functions
const formatDate = (dateString) => {
  if (!dateString) return "";
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
};

// Categories
const categories = ref([]);

async function getCategories() {
  try {
    const res = await get("/news/categories/");
    if (res.data && res.data.results) {
      categories.value = res.data.results.map((category) => ({
        id: category.id,
        name: category.title,
        slug: category.slug,
      }));
    } else {
      console.error("Unexpected response format:", res.data);
    }
  } catch (error) {
    console.error("Error fetching categories:", error);
  }
}
await getCategories();

const activeCategory = ref("all");
const setActiveCategory = (categoryId) => {
  activeCategory.value = categoryId;
};

// Breaking news ticker
const breakingNews = ref([
  "Global Summit on Climate Change Reaches Historic Agreement",
  "New Technology Breakthrough Could Revolutionize Renewable Energy",
  "Major Economic Reform Bill Passes in Senate",
  "Scientists Discover Potential Cure for Rare Disease",
]);

async function getBreakingNews() {
  try {
    const res = await get("/news/breaking-news/");
    if (res.data) {
      breakingNews.value = res.data.map((news) => ({
        title: news.title,
        description: news.description,
      }));
    } else {
      console.error("Unexpected response format:", res.data);
    }
  } catch (error) {
    console.error("Error fetching breaking news:", error);
  }
}
await getBreakingNews();

// Current date
const currentDate = computed(() => {
  return new Date().toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
});

// Weather data (simulated)
const weather = reactive({
  temp: 24,
  condition: "Partly Cloudy",
  icon: "cloud",
});

// Tags for mobile menu
const tags = ref([]);

async function getTags() {
  try {
    const res = await get("/news/categories/");
    if (res.data && res.data.results) {
      tags.value = res.data.results;
    }
  } catch (error) {
    console.error("Error fetching tags:", error);
  }
}

await getTags();

// Chat opening logic
const openChat = () => {
  alert("Chat option opened!"); // Replace with actual chat opening logic
};

// Add this to implement click outside behavior
const vClickOutside = {
  mounted(el, binding) {
    el.clickOutsideEvent = (event) => {
      if (!(el === event.target || el.contains(event.target))) {
        binding.value(event);
      }
    };
    document.addEventListener("click", el.clickOutsideEvent);
  },
  unmounted(el) {
    document.removeEventListener("click", el.clickOutsideEvent);
  },
};
</script>

<style>
:root {
  --color-primary: #e53e3e;
  --color-primary-dark: #c53030;
}

.bg-primary {
  background-color: var(--color-primary);
}

.text-primary {
  color: var(--color-primary);
}

.hover\:text-primary:hover {
  color: var(--color-primary);
}

.hover\:text-primary-dark:hover {
  color: var(--color-primary-dark);
}

.hover\:bg-primary-dark:hover {
  background-color: var(--color-primary-dark);
}

.focus\:ring-primary:focus {
  --tw-ring-color: var(--color-primary);
}

.focus\:border-primary:focus {
  border-color: var(--color-primary);
}

.border-primary {
  border-color: var(--color-primary);
}

/* Hide scrollbar but maintain functionality */
.scrollbar-hide {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}

.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Chrome, Safari and Opera */
}

/* Ticker animation */
.ticker-container {
  animation: ticker 20s linear infinite;
}

.ticker-item {
  margin-right: 50px;
}

@keyframes ticker {
  0% {
    transform: translateX(100%);
  }
  100% {
    transform: translateX(-100%);
  }
}

/* Transition effects */
.comment-list-enter-active,
.comment-list-leave-active {
  transition: all 0.5s ease;
}

.comment-list-enter-from,
.comment-list-leave-to {
  opacity: 0;
  transform: translateY(30px);
}

/* Line clamp for article summaries */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* White dotted spinner for navigation buttons */
.spinner-white {
  width: 14px;
  height: 14px;
  border: 2px dotted #ffffff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>
