<template>
  <div>
    <header class="sticky top-0 z-50 bg-white shadow-md">
      <div class="max-w-7xl mx-auto">
        <!-- Top Bar -->
        <div class="border-b border-gray-200">
          <div
            class="flex justify-between items-center px-4 py-2 sm:px-6 lg:px-8"
          >
            <div class="flex items-center space-x-4">
              <span class="text-sm text-gray-500">{{ currentDate }}</span>
              <div class="hidden sm:flex items-center text-sm text-gray-500">
                <SunIcon
                  v-if="weather.icon === 'sun'"
                  class="h-4 w-4 mr-1 text-amber-500"
                />
                <CloudIcon
                  v-else-if="weather.icon === 'cloud'"
                  class="h-4 w-4 mr-1 text-gray-400"
                />
                <CloudRainIcon v-else class="h-4 w-4 mr-1 text-blue-500" />
                {{ weather.temp }}°C | {{ weather.condition }}
              </div>
            </div>
          </div>
        </div>

        <!-- Main Navigation -->
        <div
          class="flex flex-col sm:flex-row gap-4 justify-between items-center px-4 py-4 sm:px-6 lg:px-8"
        >
          <div class="flex items-center flex-1">
            <div class="flex-shrink-0">
              <NuxtLink to="/adsy-news/">
                <NuxtImg
                  v-if="logo[0]?.image"
                  :src="logo[0].image"
                  alt="Adsy News Logo"
                  width="150"
                  height="50"
                  class="h-8 mr-6 sm:h-10 w-auto object-fit"
                />
              </NuxtLink>
            </div>
            <div class="sm:hidden flex gap-1">
              <UButton class="bg-black/70" to="/">AdsyClub</UButton>
              <UButton class="bg-black/70" to="/business-network"
                >Adsy BN</UButton
              >
            </div>

            <nav
              class="hidden md:ml-10 md:flex space-x-8"
              v-if="categories?.length > 0"
            >
              <a
                v-for="category in categories.slice(0, 4)"
                :key="category.id"
                :class="[
                  'text-sm font-medium hover:text-primary transition-colors duration-200',
                  activeCategory === category.id
                    ? 'text-primary border-b-2 border-primary'
                    : 'text-gray-700',
                ]"
                href="#"
                @click.prevent="setActiveCategory(category.id)"
              >
                {{ category.name }}
              </a>
              <div class="relative" v-if="categories.length > 4">
                <button
                  @click="toggleMoreCategories"
                  @blur="moreMenuOpen = false"
                  class="flex items-center text-sm font-medium text-gray-700 hover:text-primary transition-colors duration-200"
                >
                  See More
                  <UIcon name="i-heroicons-arrow-small-down-20-solid" />
                </button>
                <div
                  v-if="moreMenuOpen"
                  class="absolute top-full right-0 mt-2 bg-white shadow-lg rounded-md py-2 z-50 min-w-[200px]"
                >
                  <a
                    v-for="category in categories.slice(4)"
                    :key="category.id"
                    :class="[
                      'block px-4 py-2 text-sm hover:bg-gray-100 transition-colors',
                      activeCategory === category.id
                        ? 'text-primary'
                        : 'text-gray-700',
                    ]"
                    href="#"
                    @mousedown.prevent
                    @click.prevent="setMoreCategory(category.id)"
                  >
                    {{ category.name }}
                  </a>
                </div>
              </div>
            </nav>
          </div>

          <div
            class="flex items-center sm:justify-end space-x-2 flex-1 max-sm:w-full"
          >
            <UButton class="bg-black/70 max-sm:hidden" to="/">AdsyClub</UButton>
            <UButton class="bg-black/70 max-sm:hidden" to="/business-network"
              >Adsy BN</UButton
            >
            <div class="relative max-sm:flex-1">
              <input
                type="text"
                placeholder="Search news..."
                v-model="searchQuery"
                class="w-full sm:w-64 pl-10 pr-4 py-2 border border-gray-300 rounded-full text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent bg-gray-100 text-gray-900"
                @input="handleSearchInput"
              />
              <SearchIcon
                class="absolute left-3 top-2.5 h-4 w-4 text-gray-500"
              />
              <button
                v-if="searchQuery"
                @click="clearSearch"
                class="absolute right-3 top-2.5"
              >
                <XIcon class="h-4 w-4 text-gray-500" />
              </button>

              <!-- Auto-loading search results -->
              <div
                v-if="searchQuery"
                class="absolute top-full left-0 right-0 mt-2 bg-white rounded-md shadow-lg z-10 max-h-96 overflow-y-auto border border-gray-200"
              >
                <div class="p-3 border-b border-gray-200">
                  <p class="text-sm text-gray-700">
                    Search results for:
                    <span class="font-medium">{{ searchQuery }}</span>
                  </p>
                </div>

                <!-- Loading indicator -->
                <div v-if="isSearching" class="p-4 text-center">
                  <div
                    class="inline-block h-6 w-6 animate-spin rounded-full border-2 border-solid border-primary border-r-transparent"
                  ></div>
                  <p class="mt-2 text-sm text-gray-600">Searching...</p>
                </div>

                <!-- Results list -->
                <div v-else class="divide-y divide-gray-100">
                  <div
                    v-for="result in searchResults"
                    :key="result.id"
                    class="p-3 hover:bg-gray-50 cursor-pointer"
                    @click="navigateToArticle(result)"
                  >
                    <p class="text-sm font-medium text-gray-900">
                      {{ result.title }}
                    </p>
                    <p class="text-xs text-gray-500 mt-1 flex items-center">
                      <CalendarIcon class="h-3 w-3 mr-1" />
                      {{ formatDate(result.created_at) }}
                      <span class="mx-2">•</span>
                      <span
                        class="bg-primary/10 text-primary px-2 py-0.5 rounded-full text-xs"
                      >
                        {{
                          result.post_tags && result.post_tags.length > 0
                            ? result.post_tags[0].tag
                            : "News"
                        }}
                      </span>
                    </p>
                  </div>

                  <!-- No results message -->
                  <div
                    v-if="
                      searchResults.length === 0 && !isSearching && searchQuery
                    "
                    class="p-4 text-center text-gray-500"
                  >
                    No results found for "{{ searchQuery }}"
                  </div>
                </div>
              </div>
            </div>
            <button
              @click="mobileMenuOpen = !mobileMenuOpen"
              class="md:hidden p-2 rounded-md text-gray-700 hover:bg-gray-100 focus:outline-none"
            >
              <MenuIcon v-if="!mobileMenuOpen" class="h-6 w-6" />
              <XIcon v-else class="h-6 w-6" />
            </button>
          </div>
        </div>

        <!-- Mobile Menu -->
        <div v-if="mobileMenuOpen" class="md:hidden border-t border-gray-200">
          <div class="px-2 pt-2 pb-3 space-y-1">
            <a
              v-for="category in categories"
              :key="category.id"
              :class="[
                'block px-3 py-2 rounded-md text-base font-medium hover:bg-gray-100 transition-colors duration-200',
                activeCategory === category.id
                  ? 'text-primary bg-gray-100'
                  : 'text-gray-700',
              ]"
              href="#"
              @click.prevent="
                setActiveCategory(category.id);
                mobileMenuOpen = false;
              "
            >
              {{ category.name }}
            </a>
          </div>
        </div>
      </div>
    </header>

    <UContainer>
      <div
        class="bg-primary text-white py-3 px-6 rounded-lg mb-8 shadow-md mt-3"
      >
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <span
              class="font-bold text-sm sm:text-lg mr-4 border-r border-white/30 pr-4"
              >BREAKING NEWS</span
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
                class="ticker-item px-4"
              >
                {{ news }}
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

async function getLogo() {
  const { data } = await get("/news-logo/");
  logo.value = data;
}
await getLogo();

import {
  SunIcon,
  MenuIcon,
  XIcon,
  SearchIcon,
  CalendarIcon,
  CloudIcon,
  CloudRainIcon,
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
const mobileMenuOpen = ref(false);
const moreMenuOpen = ref(false);
const toggleMoreCategories = () => {
  moreMenuOpen.value = !moreMenuOpen.value;
};
const setMoreCategory = (categoryId) => {
  setActiveCategory(categoryId);
  moreMenuOpen.value = false;
};

// Search state
const searchQuery = ref("");
const searchResults = ref([]);
const isSearching = ref(false);

// Perform search when query changes
const performSearch = async () => {
  if (!searchQuery.value) {
    searchResults.value = [];
    return;
  }

  try {
    isSearching.value = true;
    // Make API call to fetch search results
    const { data } = await get(
      `/news/posts/?search=${encodeURIComponent(searchQuery.value)}`
    );

    if (data && data.results) {
      searchResults.value = data.results;
    } else if (Array.isArray(data)) {
      searchResults.value = data;
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
  if (!searchQuery.value) {
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
    const res = await get("/news/tags/");
    if (res.data && res.data.results) {
      categories.value = res.data.results.map((category) => ({
        id: category.id,
        name: category.tag,
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
  mobileMenuOpen.value = false;
};

// Breaking news ticker
const breakingNews = ref([
  "Global Summit on Climate Change Reaches Historic Agreement",
  "New Technology Breakthrough Could Revolutionize Renewable Energy",
  "Major Economic Reform Bill Passes in Senate",
  "Scientists Discover Potential Cure for Rare Disease",
]);
const currentTickerIndex = ref(0);

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
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
