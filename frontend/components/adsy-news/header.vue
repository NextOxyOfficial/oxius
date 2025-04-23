<template>
  <div>
    <header class="sticky top-0 z-50 bg-white shadow-md">
      <div class="max-w-7xl mx-auto">
        
        <!-- Main Navigation -->
        <div
          class="flex flex-col sm:flex-row justify-between items-center px-4 py-4 sm:py-6 sm:px-6 lg:px-8"
        >
          <NuxtLink to="/adsy-news" class="hidden sm:block">
            <NuxtImg
              v-if="logo[0]?.image"
              :src="logo[0].image"
              alt="Adsy News Logo"
              width="150"
              height="50"
              class="h-8 sm:h-10 w-auto object-fit"
            />
          </NuxtLink>
          <div class="flex items-center">
            <nav
              class="hidden md:ml-10 md:flex space-x-8"
              v-if="categories?.length > 0"
            >
              <NuxtLink
                v-for="category in categories.slice(0, 4)"
                :key="category.id"
                :class="[
                  'text-lg font-medium hover:text-primary transition-colors duration-200',
                  activeCategory === category.id
                    ? 'text-primary border-b-2 border-primary'
                    : 'text-gray-700',
                ]"
                :to="`/adsy-news/categories/${category.slug}/`"
              >
                {{ category.name }}
              </NuxtLink>
              <div class="relative" v-if="categories.length > 4">
                <button
                  @click="toggleMoreCategories"
                  class="flex items-center text-lg font-medium text-gray-700 hover:text-primary transition-colors duration-200"
                >
                  See More
                  <UIcon name="i-heroicons-arrow-small-down-20-solid" />
                </button>
                <div
                  v-if="moreMenuOpen"
                  class="absolute top-full left-0 mt-2 bg-white shadow-lg rounded-md py-2 z-50 max-h-64 overflow-y-auto border border-gray-200"
                >
                  <NuxtLink
                    v-for="category in categories.slice(4)"
                    :key="category.id"
                    :class="[
                      'block px-4 py-2 text-sm hover:bg-gray-100 transition-colors',
                      activeCategory === category.id
                        ? 'text-primary'
                        : 'text-gray-700',
                    ]"
                    :to="`/adsy-news/categories/${category.slug}/`"
                  >
                    {{ category.name }}
                  </NuxtLink>
                </div>
              </div>
            </nav>
          </div>

          <div
            class="flex items-center sm:justify-end space-x-2 max-sm:w-full relative"
          >
            <div class="flex items-center justify-between w-full sm:w-auto">
              <NuxtLink to="/adsy-news" class="flex-shrink-0 sm:hidden block">
                <NuxtImg
                  v-if="logo[0]?.image"
                  :src="logo[0].image"
                  alt="Adsy News Logo"
                  width="150"
                  height="50"
                  class="h-8 sm:h-10 w-auto object-fit"
                />
              </NuxtLink>
              
              <div class="flex items-center space-x-2 ml-auto">
                <SearchIcon
                  class="h-6 w-6 text-gray-500 cursor-pointer search-icon"
                  @click="toggleSearch"
                />
                <UButton class="bg-black/70" to="/">AdsyClub</UButton>
                <UButton class="bg-black/70" to="/business-network"
                  >Adsy BN</UButton
                >
                
              </div>
            </div>
            <div
              v-if="isSearchVisible"
              class="absolute top-full right-0 mt-2 bg-white rounded-md shadow-lg z-10 border border-gray-200 p-4 w-full sm:w-72 search-dropdown"
            >
              <input
                type="text"
                placeholder="Search news..."
                v-model="searchQuery"
                class="w-full pl-4 pr-4 py-2 border border-gray-300 rounded-full text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent bg-gray-100 text-gray-700 search-input"
                @input="handleSearchInput"
              />

              <div
                v-if="searchQuery"
                class="mt-4 max-h-96 overflow-y-auto divide-y divide-gray-100"
              >
                <div
                  v-for="result in searchResults"
                  :key="result.id"
                  class="p-3 hover:bg-gray-50 cursor-pointer"
                  @click="navigateToArticle(result)"
                >
                  <p class="text-sm font-medium text-gray-700">
                    {{ result.title }}
                  </p>
                  <p class="text-xs text-gray-500 mt-1 flex items-center">
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
                  </p>
                </div>
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
        </div>
        <div class="flex items-center px-6 mb-4 mt-2 sm:hidden">
          <nav
            class="flex md:ml-10 md:hidden justify-between mb-2 space-x-2"
            v-if="categories?.length > 0"
          >
            <NuxtLink
              v-for="category in categories.slice(0, 4)"
              :key="category.id"
              :class="[
                'text-base sm:text-lg  font-medium hover:text-primary transition-colors duration-200',
                activeCategory === category.id
                  ? 'text-primary border-b-2 border-primary'
                  : 'text-gray-700',
              ]"
              :to="`/adsy-news/categories/${category.slug}/`"
            >
              {{ category.name }}
            </NuxtLink>
            <div class="relative" v-if="categories.length > 4">
              <button
                @click="toggleMoreCategories"
                class="flex items-center text-lg font-medium text-gray-700 hover:text-primary transition-colors duration-200"
              >
                See More
                <UIcon name="i-heroicons-arrow-small-down-20-solid" />
              </button>
              <div
                v-if="moreMenuOpen"
                class="absolute top-full left-0 mt-2 bg-white shadow-lg rounded-md py-2 z-50 max-h-64 overflow-y-auto border border-gray-200"
              >
                <NuxtLink
                  v-for="category in categories.slice(4)"
                  :key="category.id"
                  :class="[
                    'block px-4 py-2 text-sm hover:bg-gray-100 transition-colors',
                    activeCategory === category.id
                      ? 'text-primary'
                      : 'text-gray-700',
                  ]"
                  :to="`/adsy-news/categories/${category.slug}/`"
                >
                  {{ category.name }}
                </NuxtLink>
              </div>
            </div>
          </nav>
        </div>
        <!-- Mobile Menu -->
        <div v-if="mobileMenuOpen" class="border-t border-gray-200">
          <div class="px-2 pt-2 pb-3 space-y-1 max-h-64 overflow-y-auto">
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
          <div class="px-2 pt-2 pb-3 space-y-1 max-h-64 overflow-y-auto">
            <span
              v-for="tag in tags"
              :key="tag.id"
              class="block px-3 py-2 rounded-md text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 cursor-pointer"
            >
              #{{ tag.title }}
            </span>
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
              class="font-semibold text-sm sm:text-lg mr-4 border-r border-white/30 pr-4"
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
                class="ticker-item px-4 capitalize"
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

import { onMounted, onUnmounted, nextTick } from "vue";

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
const isSearchVisible = ref(false);

// Toggle search visibility
const toggleSearch = () => {
  isSearchVisible.value = !isSearchVisible.value;

  // Focus the search input when the search bar is made visible
  if (isSearchVisible.value) {
    nextTick(() => {
      const searchInput = document.querySelector(".search-input");
      if (searchInput) {
        searchInput.focus();
      }
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

onMounted(() => {
  document.addEventListener("click", handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
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
  mobileMenuOpen.value = false;
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
    if (res.data ) {
      breakingNews.value = res.data.map((news) => ({title:news.title,description:news.description}));
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
