<template>
  <!-- Mobile Search Overlay -->
  <div
    v-if="isMobileSearchActive"
    class="fixed inset-0 bg-white z-[999999999] md:hidden flex flex-col"
  >
    <!-- Mobile Search Header -->
    <div class="bg-white border-b border-gray-200 p-2 flex-shrink-0">
      <div class="flex items-center gap-1">
        <!-- Back Button -->
        <button
          @click="closeMobileSearch"
          class="p-2 flex rounded-full hover:bg-gray-100 transition-colors"
        >
          <UIcon name="i-heroicons-chevron-left" class="size-6 text-gray-600" />
        </button>

        <!-- Search Input -->
        <div class="flex-1">
          <div class="relative">
            <input
              ref="mobileSearchInput"
              v-model="mobileSearchQuery"
              type="text"
              placeholder="Search products..."
              class="w-full h-12 pl-12 pr-4 text-base text-gray-900 placeholder-gray-500 bg-gray-50 border-0 rounded-full shadow-sm focus:bg-white outline-gray-200 transition-all duration-200"
              @input="handleMobileSearchInput"
              @keydown.enter="handleMobileSearchEnter"
            />
            <!-- Search Icon -->
            <div
              class="absolute left-4 top-1/2 transform -translate-y-1/2 mt-1"
            >
              <UIcon
                name="i-heroicons-magnifying-glass-20-solid"
                class="size-6 text-gray-600 font-bold"
              />
            </div>
            <!-- Clear Button -->
            <button
              v-if="mobileSearchQuery"
              @click="clearSearch"
              class="absolute right-3 top-1/2 transform -translate-y-1/2 pr-1 rounded-full hover:bg-gray-100 transition-colors mt-1"
            >
              <UIcon name="i-heroicons-x-mark" class="size-4 text-gray-400" />
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Mobile Search Results -->
    <div class="flex-1 overflow-y-auto overscroll-contain p-2">
      <!-- Loading State -->
      <div v-if="isSearching" class="flex justify-center py-8">
        <UIcon
          name="i-heroicons-arrow-path"
          class="w-6 h-6 animate-spin text-emerald-500"
        />
      </div>

      <!-- Search Results -->
      <div v-else-if="searchResults.length > 0" class="space-y-4">
        <p class="text-sm text-gray-600 mb-4">
          {{ searchResults.length }} results found for "{{ mobileSearchQuery }}"
        </p>

        <div class="grid grid-cols-2 gap-2">
          <CommonProductCard
            v-for="product in searchResults"
            :key="product.id"
            :product="product"
            :is-in-search-overlay="true"
          />
        </div>

        <!-- Load More Button / Loading More -->
        <div v-if="hasMoreResults" class="text-center mt-6 pb-6">
          <button
            v-if="!isLoadingMore"
            @click="loadMoreResults"
            class="px-6 py-3 bg-emerald-500 text-white rounded-lg hover:bg-emerald-600 transition-colors"
          >
            Load More Products
          </button>
          <div v-else class="flex justify-center">
            <UIcon
              name="i-heroicons-arrow-path"
              class="w-5 h-5 animate-spin text-emerald-500"
            />
            <span class="ml-2 text-sm text-gray-600">Loading more...</span>
          </div>
        </div>
      </div>
      <!-- No Results -->
      <div
        v-else-if="mobileSearchQuery && !isSearching"
        class="text-center py-12"
      >
        <UIcon
          name="i-heroicons-magnifying-glass"
          class="w-12 h-12 text-gray-300 mx-auto mb-4"
        />
        <h3 class="text-lg font-medium text-gray-900 mb-2">No results found</h3>
        <p class="text-gray-500">
          Try searching with different keywords or check spelling
        </p>
      </div>

      <!-- Default State - Recent Searches, Trending & Hot Products -->
      <div v-else class="space-y-6">
        <!-- Recent Searches Section -->
        <div v-if="recentSearches.length > 0" class="space-y-3">
          <h3 class="text-base font-semibold text-gray-900 flex items-center">
            <UIcon
              name="i-heroicons-clock"
              class="w-5 h-5 mr-2 text-gray-500"
            />
            Recent Searches
          </h3>
          <div class="flex flex-wrap gap-2">
            <div
              v-for="(search, index) in recentSearches"
              :key="index"
              class="inline-flex items-center bg-gray-100 hover:bg-gray-200 rounded-full px-3 py-1.5 text-sm text-gray-700 transition-colors group"
            >
              <button
                @click="selectRecentSearch(search)"
                class="flex items-center hover:text-gray-900 transition-colors"
              >
                <UIcon
                  name="i-heroicons-magnifying-glass"
                  class="w-3 h-3 mr-1.5 text-gray-400"
                />
                <span class="max-w-[120px] truncate">{{ search }}</span>
              </button>
              <button
                @click="removeRecentSearch(index)"
                class="ml-2 flex p-0.5 hover:bg-gray-300 rounded-full transition-colors"
              >
                <UIcon
                  name="i-heroicons-x-mark"
                  class="w-3 h-3 text-gray-500 hover:text-gray-700"
                />
              </button>
            </div>
          </div>
        </div>

        <!-- Trending Searches Section -->
        <div class="space-y-3">
          <h3 class="text-base font-semibold text-gray-900 flex items-center">
            <UIcon
              name="i-heroicons-fire"
              class="w-5 h-5 mr-2 text-orange-500"
            />
            Trending Searches
          </h3>
          <div v-if="isLoadingTrending" class="flex justify-center py-4">
            <UIcon
              name="i-heroicons-arrow-path"
              class="w-5 h-5 animate-spin text-emerald-500"
            />
          </div>
          <div v-else class="flex flex-wrap gap-2">
            <button
              v-for="trend in trendingSearches"
              :key="trend"
              @click="selectTrendingSearch(trend)"
              class="px-3 py-1.5 bg-emerald-50 text-emerald-700 rounded-full text-sm hover:bg-emerald-100 transition-colors"
            >
              {{ trend }}
            </button>
          </div>
        </div>

        <!-- Hot Products Section -->
        <div class="space-y-3">
          <h3 class="text-base font-semibold text-gray-900 flex items-center">
            <UIcon name="i-heroicons-bolt" class="w-5 h-5 mr-2 text-red-500" />
            Hot Products
          </h3>
          <div v-if="isLoadingHotProducts" class="flex justify-center py-4">
            <UIcon
              name="i-heroicons-arrow-path"
              class="w-5 h-5 animate-spin text-emerald-500"
            />
          </div>
          <div
            v-else-if="hotProducts.length > 0"
            class="grid grid-cols-2 gap-2"
          >
            <CommonProductCard
              v-for="product in hotProducts"
              :key="product.id"
              :product="product"
              :is-in-search-overlay="true"
            />
          </div>
          <div v-else class="text-center py-8">
            <UIcon
              name="i-heroicons-shopping-bag"
              class="w-8 h-8 text-gray-300 mx-auto mb-2"
            />
            <p class="text-sm text-gray-500">No hot products available</p>
          </div>
        </div>

        <!-- Suggestions based on previous searches -->
        <div v-if="suggestedProducts.length > 0" class="space-y-3">
          <h3 class="text-base font-semibold text-gray-900 flex items-center">
            <UIcon
              name="i-heroicons-lightbulb"
              class="w-5 h-5 mr-2 text-yellow-500"
            />
            Suggested for You
          </h3>
          <div class="grid grid-cols-2 gap-2">
            <CommonProductCard
              v-for="product in suggestedProducts"
              :key="product.id"
              :product="product"
              :is-in-search-overlay="true"
            />
          </div>
        </div>

        <!-- Empty State when no data -->
        <div
          v-if="
            recentSearches.length === 0 &&
            trendingSearches.length === 0 &&
            hotProducts.length === 0
          "
          class="text-center py-12"
        >
          <UIcon
            name="i-heroicons-magnifying-glass"
            class="w-12 h-12 text-gray-300 mx-auto mb-4"
          />
          <h3 class="text-lg font-medium text-gray-900 mb-2">
            Search Products
          </h3>
          <p class="text-gray-500">
            Start typing to find products, brands, and categories
          </p>
        </div>
      </div>
    </div>
  </div>

  <header
    class="bg-white border-b border-gray-200 transition-all duration-300 z-[99999999] w-full md:hidden"
    :class="[
      isScrolled
        ? 'fixed top-0 left-0 right-0 shadow-sm'
        : 'sticky top-0 shadow-sm',
    ]"
  >
    <UContainer class="pl-2 py-2.5">
      <div class="flex items-center justify-between gap-2">
        <!-- Left Section: Sidebar Toggle + Logo OR Back Button + Logo -->
        <div class="flex items-center gap-3">
          <!-- Back Button for Product Details and Store Pages -->
          <button
            v-if="isProductDetailsPage"
            @click="navigateToEshop"
            :disabled="isNavigating"
            class="inline-flex items-center justify-center p-1.5 rounded-lg hover:bg-gray-50 transition-all duration-200 flex-shrink-0 group"
            :class="{
              'opacity-50 cursor-not-allowed': isNavigating,
              'text-gray-700 hover:text-gray-900': !isNavigating,
            }"
          >
            <span class="sr-only">Back to eshop</span>
            <div v-if="isNavigating" class="dotted-spinner text-gray-600"></div>
            <UIcon
              v-else
              name="i-heroicons-chevron-left"
              class="size-6 transition-transform group-hover:scale-110"
            />
          </button>

          <!-- Sidebar toggle button (shown when not on product details page) -->
          <button
            v-else
            @click="toggleSidebar"
            class="inline-flex items-center justify-center p-2.5 bg-gray-100 rounded-full hover:bg-gray-200 transition-all duration-200 flex-shrink-0 group"
            :class="{
              'text-emerald-600 bg-emerald-100 hover:bg-emerald-200':
                isSidebarOpen,
              'text-gray-700 hover:text-gray-800': !isSidebarOpen,
            }"
          >
            <span class="sr-only">Toggle categories</span>
            <UIcon
              name="streamline:interface-page-controller-loading-3-progress-loading-dot-load-wait-waiting"
              class="size-5 transition-transform group-hover:scale-110"
            />
          </button>

          <!-- Logo -->
          <div class="flex-shrink-0">
            <PublicEshopLogo />
          </div>
        </div>

        <!-- Center Section: Search Bar (Desktop) / Search Icon (Mobile) -->
        <div class="flex-1 max-w-2xl mx-2">
          <!-- Desktop Search Bar -->
          <div class="relative hidden md:block">
            <UInput
              v-model="headerSearchQuery"
              icon="i-heroicons-magnifying-glass-20-solid"
              size="lg"
              color="emerald"
              variant="outline"
              :trailing="false"
              placeholder="Search products, brands, categories..."
              class="w-full"
              :ui="{
                wrapper: 'relative',
                base: 'relative block w-full disabled:cursor-not-allowed disabled:opacity-75 focus:outline-none border-0',
                form: 'form-input',
                rounded: 'rounded-full',
                placeholder: 'placeholder-gray-400',
                size: {
                  lg: 'text-base py-2 px-4',
                },
                icon: {
                  base: 'flex-shrink-0 text-gray-400',
                  color: 'text-gray-400',
                  size: {
                    lg: 'size-6',
                  },
                },
                color: {
                  emerald: {
                    outline:
                      'shadow-sm bg-white dark:bg-gray-900 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-300 dark:ring-gray-700 focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400',
                  },
                },
                default: {
                  size: 'lg',
                  color: 'emerald',
                  variant: 'outline',
                },
              }"
              @input="handleSearchInput"
              @keydown.enter="handleSearchEnter"
            />
          </div>

          <!-- Mobile Search Icon and Share Icon (only on mobile and specific pages) -->
          <div v-if="showMobileSearchIcon" class="block md:hidden">
            <div class="flex justify-end gap-2">
              <!-- Search Icon -->
              <button
                @click="openMobileSearch"
                class="p-2.5 bg-gray-100 rounded-full flex hover:bg-gray-200 transition-colors"
              >
                <UIcon name="bx:search-alt" class="size-6 text-gray-700" />
              </button>

              <!-- Share Icon -->
              <button
                @click="shareCurrentPage"
                :disabled="isSharing"
                class="p-2.5 bg-gray-100 rounded-full flex hover:bg-gray-200 transition-colors"
                :class="{
                  'opacity-50 cursor-not-allowed': isSharing,
                }"
              >
                <div
                  v-if="isSharing"
                  class="dotted-spinner-small text-gray-600"
                ></div>
                <UIcon
                  v-else
                  name="i-heroicons-share"
                  class="size-5 text-gray-700"
                />
              </button>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </header>
</template>

<script setup>
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from "vue";

// Handle scroll events
const isScrolled = ref(false);
const windowWidth = ref(0);

const handleScroll = () => {
  isScrolled.value = window.scrollY > 80;
};

const handleResize = () => {
  if (process.client) {
    windowWidth.value = window.innerWidth;
  }
};

// Header search functionality
const headerSearchQuery = ref("");

// Mobile search functionality
const isMobileSearchActive = ref(false);
const mobileSearchQuery = ref("");
const mobileSearchInput = ref(null);
const searchResults = ref([]);
const isSearching = ref(false);
const isLoadingMore = ref(false);
const hasMoreResults = ref(false);
const currentPage = ref(1);
const route = useRoute();
const router = useRouter();
const { get } = useApi();

// Recent searches functionality
const recentSearches = ref([]);
const MAX_RECENT_SEARCHES = 12;
const RECENT_SEARCHES_KEY = "eshop_recent_searches";

// Trending and hot products
const trendingSearches = ref([]);
const hotProducts = ref([]);
const suggestedProducts = ref([]);
const isLoadingTrending = ref(false);
const isLoadingHotProducts = ref(false);

// Check if mobile search icon should be shown based on current route
const showMobileSearchIcon = computed(() => {
  // Only show on mobile screens (less than 768px)
  if (windowWidth.value >= 768) {
    return false;
  }

  const currentPath = route.path;
  return (
    currentPath.startsWith("/eshop") || // Show on all eshop pages including main page
    currentPath.includes("/product-details/") ||
    currentPath.includes("/store/")
  );
});

// Check if current route is product details page or store page
const isProductDetailsPage = computed(() => {
  return (
    route.path.includes("/product-details/") ||
    (route.path.includes("/eshop/") && route.path !== "/eshop")
  );
});

// Navigation state
const isNavigating = ref(false);

// Share functionality state
const isSharing = ref(false);

// Navigate to eshop page function
async function navigateToEshop() {
  if (isNavigating.value) return;

  isNavigating.value = true;

  try {
    // Navigate to eshop and wait for route change to complete
    await router.push("/eshop");

    // Wait for next tick to ensure component has fully navigated
    await nextTick();

    // Wait for page to fully load by checking if we're actually on the eshop page
    await new Promise((resolve) => {
      const checkNavigation = () => {
        if (route.path === "/eshop") {
          // Reduced delay for faster navigation feedback
          setTimeout(resolve, 100);
        } else {
          // Keep checking until we're on the right page
          setTimeout(checkNavigation, 25);
        }
      };
      checkNavigation();
    });
  } catch (error) {
    console.error("Navigation error:", error);
  } finally {
    isNavigating.value = false;
  }
}

// Share current page function
async function shareCurrentPage() {
  if (isSharing.value) return;

  isSharing.value = true;

  try {
    const currentUrl = window.location.href;
    const pageTitle = document.title || "Check out this page";

    // Check if Web Share API is supported (modern mobile browsers)
    if (navigator.share) {
      await navigator.share({
        title: pageTitle,
        text: "Check out this page on our e-commerce platform",
        url: currentUrl,
      });
    } else {
      // Fallback: Copy to clipboard
      await navigator.clipboard.writeText(currentUrl);

      // Show a toast notification (you can customize this based on your notification system)
      if (process.client) {
        // Create a simple toast notification
        const toast = document.createElement("div");
        toast.textContent = "Link copied to clipboard!";
        toast.className =
          "fixed bottom-4 left-1/2 transform -translate-x-1/2 bg-emerald-500 text-white px-4 py-2 rounded-lg shadow-lg z-[999999999] text-sm";
        document.body.appendChild(toast);

        // Remove toast after 3 seconds
        setTimeout(() => {
          if (document.body.contains(toast)) {
            document.body.removeChild(toast);
          }
        }, 3000);
      }
    }
  } catch (error) {
    console.error("Error sharing:", error);

    // Show error toast
    if (process.client) {
      const errorToast = document.createElement("div");
      errorToast.textContent = "Unable to share. Please try again.";
      errorToast.className =
        "fixed bottom-4 left-1/2 transform -translate-x-1/2 bg-red-500 text-white px-4 py-2 rounded-lg shadow-lg z-[999999999] text-sm";
      document.body.appendChild(errorToast);

      setTimeout(() => {
        if (document.body.contains(errorToast)) {
          document.body.removeChild(errorToast);
        }
      }, 3000);
    }
  } finally {
    isSharing.value = false;
  }
}

// Mobile search functions
async function openMobileSearch() {
  isMobileSearchActive.value = true;
  // Disable background scroll
  if (process.client) {
    document.body.style.overflow = "hidden";
    document.documentElement.style.overflow = "hidden";
  }

  // Load initial data
  await Promise.all([
    loadRecentSearches(),
    loadTrendingSearches(),
    loadHotProducts(),
    loadSuggestedProducts(),
  ]);

  await nextTick();
  if (mobileSearchInput.value) {
    mobileSearchInput.value.focus();
  }
}

function closeMobileSearch() {
  isMobileSearchActive.value = false;
  mobileSearchQuery.value = "";
  searchResults.value = [];
  currentPage.value = 1;
  hasMoreResults.value = false;

  // Re-enable background scroll
  if (process.client) {
    document.body.style.overflow = "";
    document.documentElement.style.overflow = "";
  }
}

// Clear search function for the X button
function clearSearch() {
  mobileSearchQuery.value = "";
  searchResults.value = [];
  hasMoreResults.value = false;
  currentPage.value = 1;
  // Focus back to input
  nextTick(() => {
    if (mobileSearchInput.value) {
      mobileSearchInput.value.focus();
    }
  });
}

// Search API integration
let mobileSearchTimeout = null;
async function handleMobileSearchInput() {
  clearTimeout(mobileSearchTimeout);

  if (!mobileSearchQuery.value.trim()) {
    searchResults.value = [];
    hasMoreResults.value = false;
    return;
  }

  mobileSearchTimeout = setTimeout(async () => {
    currentPage.value = 1;
    await performMobileSearch();
  }, 300);
}

async function handleMobileSearchEnter() {
  clearTimeout(mobileSearchTimeout);
  currentPage.value = 1;
  await performMobileSearch();
}

async function performMobileSearch(loadMore = false) {
  if (!mobileSearchQuery.value.trim()) {
    searchResults.value = [];
    hasMoreResults.value = false;
    return;
  }

  // Add to recent searches when user performs a search
  addToRecentSearches(mobileSearchQuery.value.trim());

  try {
    if (loadMore) {
      isLoadingMore.value = true;
    } else {
      isSearching.value = true;
      searchResults.value = [];
    }

    // Build query parameters for comprehensive search
    let queryParams = `page=${currentPage.value}&page_size=20&ordering=-created_at`;

    // Add search query that matches name, description, and keywords
    const searchTerm = encodeURIComponent(mobileSearchQuery.value.trim());
    queryParams += `&search=${searchTerm}`;

    // Also add specific keyword search for better matching
    queryParams += `&keywords=${searchTerm}`;

    // Add name search for product name matching
    queryParams += `&name=${searchTerm}`;

    const { data } = await get(`/all-products/?${queryParams}`);

    const newResults = data?.results || data || [];

    if (loadMore) {
      searchResults.value = [...searchResults.value, ...newResults];
    } else {
      searchResults.value = newResults;
    }

    // Check if there are more results based on returned data length
    hasMoreResults.value = newResults.length === 20;
  } catch (error) {
    if (!loadMore) {
      searchResults.value = [];
    }
    hasMoreResults.value = false;
  } finally {
    isSearching.value = false;
    isLoadingMore.value = false;
  }
}

// Recent searches management
function loadRecentSearches() {
  if (process.client) {
    try {
      const stored = localStorage.getItem(RECENT_SEARCHES_KEY);
      if (stored) {
        recentSearches.value = JSON.parse(stored);
      }
    } catch (error) {
      console.error("Error loading recent searches:", error);
      recentSearches.value = [];
    }
  }
}

function addToRecentSearches(searchTerm) {
  if (!searchTerm.trim()) return;

  // Remove if already exists to avoid duplicates
  const filtered = recentSearches.value.filter(
    (term) => term.toLowerCase() !== searchTerm.toLowerCase()
  );

  // Add to beginning
  filtered.unshift(searchTerm);

  // Keep only the most recent searches
  recentSearches.value = filtered.slice(0, MAX_RECENT_SEARCHES);

  // Save to localStorage
  if (process.client) {
    try {
      localStorage.setItem(
        RECENT_SEARCHES_KEY,
        JSON.stringify(recentSearches.value)
      );
    } catch (error) {
      console.error("Error saving recent searches:", error);
    }
  }
}

function removeRecentSearch(index) {
  recentSearches.value.splice(index, 1);

  // Update localStorage
  if (process.client) {
    try {
      localStorage.setItem(
        RECENT_SEARCHES_KEY,
        JSON.stringify(recentSearches.value)
      );
    } catch (error) {
      console.error("Error updating recent searches:", error);
    }
  }
}

function selectRecentSearch(searchTerm) {
  mobileSearchQuery.value = searchTerm;
  currentPage.value = 1;
  performMobileSearch();
}

// Trending searches
async function loadTrendingSearches() {
  isLoadingTrending.value = true;
  try {
    // You can replace this with actual API endpoint for trending searches
    // For now, using mock data
    trendingSearches.value = [
      "Electronics",
      "Fashion",
      "Home Decor",
      "Books",
      "Sports",
      "Beauty",
      "Mobile",
      "Laptop",
      "Shoes",
      "Watches",
    ];

    // If you have an API endpoint:
    // const { data } = await get('/trending-searches/');
    // trendingSearches.value = data?.searches || [];
  } catch (error) {
    console.error("Error loading trending searches:", error);
    trendingSearches.value = [];
  } finally {
    isLoadingTrending.value = false;
  }
}

function selectTrendingSearch(searchTerm) {
  mobileSearchQuery.value = searchTerm;
  currentPage.value = 1;
  performMobileSearch();
}

// Hot products
async function loadHotProducts() {
  isLoadingHotProducts.value = true;
  try {
    // Load popular/featured products
    const { data } = await get(
      "/all-products/?ordering=-views,-created_at&page_size=10"
    );
    hotProducts.value = data?.results || data || [];
  } catch (error) {
    console.error("Error loading hot products:", error);
    hotProducts.value = [];
  } finally {
    isLoadingHotProducts.value = false;
  }
}

// Suggested products based on previous searches
async function loadSuggestedProducts() {
  try {
    if (recentSearches.value.length === 0) {
      suggestedProducts.value = [];
      return;
    }

    // Use the most recent search terms to find suggestions
    const recentTerms = recentSearches.value.slice(0, 3);
    const searchQuery = recentTerms.join(" ");

    if (searchQuery.trim()) {
      const queryParams = `search=${encodeURIComponent(
        searchQuery
      )}&page_size=6&ordering=-created_at`;
      const { data } = await get(`/all-products/?${queryParams}`);
      suggestedProducts.value = data?.results || data || [];
    }
  } catch (error) {
    console.error("Error loading suggested products:", error);
    suggestedProducts.value = [];
  }
}

// Load more results function
async function loadMoreResults() {
  currentPage.value += 1;
  await performMobileSearch(true);
}

// Handle product navigation from product cards
function handleProductNavigation(url) {
  closeMobileSearch();
  // Navigate after a small delay to ensure search overlay is closed
  setTimeout(() => {
    router.push(url);
  }, 100);
}

// Watch for route changes to close mobile search
watch(
  () => route.path,
  () => {
    if (isMobileSearchActive.value) {
      closeMobileSearch();
    }
  }
);

// Debounced search function
let searchTimeout = null;
function handleSearchInput() {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    emitSearchEvent();
  }, 300); // Slightly faster debounce for header search
}

function handleSearchEnter() {
  clearTimeout(searchTimeout);
  emitSearchEvent();
}

function emitSearchEvent() {
  if (process.client) {
    window.dispatchEvent(
      new CustomEvent("eshop-header-search", {
        detail: { searchQuery: headerSearchQuery.value },
      })
    );
  }
}

// Listen for search updates from the main page to sync the header input
const handleSearchSync = (event) => {
  headerSearchQuery.value = event.detail.searchQuery || "";
};

// Sidebar state management using event emitter
const isSidebarOpen = ref(false);

// Create event bus for sidebar communication
const toggleSidebar = () => {
  // Always toggle the sidebar state regardless of which page we're on
  isSidebarOpen.value = !isSidebarOpen.value;

  // Emit event to communicate with page components
  if (process.client) {
    window.dispatchEvent(
      new CustomEvent("eshop-sidebar-toggle", {
        detail: { isOpen: isSidebarOpen.value },
      })
    );
  }
};

// Listen for sidebar state changes from other components
const handleSidebarStateChange = (event) => {
  isSidebarOpen.value = event.detail.isOpen;
};

onMounted(() => {
  window.addEventListener("scroll", handleScroll);
  window.addEventListener("resize", handleResize);

  // Initialize window width
  if (process.client) {
    windowWidth.value = window.innerWidth;
  }

  // Listen for sidebar state updates
  if (process.client) {
    window.addEventListener(
      "eshop-sidebar-state-update",
      handleSidebarStateChange
    );

    // Listen for search synchronization from main page
    window.addEventListener("eshop-search-sync", handleSearchSync);
  }
});

onBeforeUnmount(() => {
  window.removeEventListener("scroll", handleScroll);
  window.removeEventListener("resize", handleResize);

  if (process.client) {
    window.removeEventListener(
      "eshop-sidebar-state-update",
      handleSidebarStateChange
    );

    window.removeEventListener("eshop-search-sync", handleSearchSync);

    // Ensure background scroll is re-enabled when component unmounts
    document.body.style.overflow = "";
    document.documentElement.style.overflow = "";
  }

  // Clear timeouts
  clearTimeout(searchTimeout);
  clearTimeout(mobileSearchTimeout);
});
</script>

<style scoped>
/* Dotted Spinner Styles (same as hero-banner) */
.dotted-spinner {
  width: 1.25rem;
  height: 1.25rem;
  border: 2px dotted #4b5563;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

/* Smaller dotted spinner for share button */
.dotted-spinner-small {
  width: 1rem;
  height: 1rem;
  border: 2px dotted #4b5563;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
