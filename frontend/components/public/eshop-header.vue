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
          class="p-2 rounded-full hover:bg-gray-100 transition-colors"
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
            <div class="absolute left-4 top-1/2 transform -translate-y-1/2">
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="w-5 h-5 text-gray-400"
              />
            </div>
            <!-- Clear Button -->
            <button
              v-if="mobileSearchQuery"
              @click="clearSearch"
              class="absolute right-3 top-1/2 transform -translate-y-1/2 p-1 rounded-full hover:bg-gray-100 transition-colors"
            >
              <UIcon name="i-heroicons-x-mark" class="w-4 h-4 text-gray-400" />
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
          <div
            v-for="product in searchResults"
            :key="product.id"
            @click="handleProductCardClick(product, $event)"
          >
            <CommonProductCard :product="product" />
          </div>
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

      <!-- Empty State -->
      <div v-else class="text-center py-12">
        <UIcon
          name="i-heroicons-magnifying-glass"
          class="w-12 h-12 text-gray-300 mx-auto mb-4"
        />
        <h3 class="text-lg font-medium text-gray-900 mb-2">Search Products</h3>
        <p class="text-gray-500">
          Start typing to find products, brands, and categories
        </p>
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
        <!-- Left Section: Sidebar Toggle + Logo -->
        <div class="flex items-center gap-1">
          <!-- Sidebar toggle button -->
          <button
            @click="toggleSidebar"
            class="inline-flex items-center justify-center p-1.5 rounded-lg border border-gray-300 bg-white hover:bg-gray-50 transition-all duration-200 shadow-sm hover:shadow-md flex-shrink-0 group"
            :class="{
              'text-emerald-600 border-emerald-300 bg-emerald-50 hover:bg-emerald-100':
                isSidebarOpen,
              'text-gray-700 hover:text-gray-900': !isSidebarOpen,
            }"
          >
            <span class="sr-only">Toggle categories</span>
            <UIcon
              name="i-heroicons-bars-3"
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
                    lg: 'h-5 w-5',
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

          <!-- Mobile Search Icon (only on mobile and specific pages) -->
          <div v-if="showMobileSearchIcon" class="block md:hidden">
            <div class="flex justify-end">
              <button
                @click="openMobileSearch"
                class="p-2 rounded-full flex hover:bg-gray-100 transition-colors"
              >
                <UIcon
                  name="i-heroicons-magnifying-glass"
                  class="w-5 h-5 text-gray-600"
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
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from "vue";

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

// Check if mobile search icon should be shown based on current route
const showMobileSearchIcon = computed(() => {
  // Only show on mobile screens (less than 768px)
  if (windowWidth.value >= 768) {
    return false;
  }

  const currentPath = route.path;
  return (
    currentPath.startsWith("/eshop") || // Show on all eshop pages including main page
    currentPath.includes("/product-details/")
  );
});

// Mobile search functions
async function openMobileSearch() {
  isMobileSearchActive.value = true;
  // Disable background scroll
  if (process.client) {
    document.body.style.overflow = "hidden";
    document.documentElement.style.overflow = "hidden";
  }
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

    console.log(`Mobile search with URL: /all-products/?${queryParams}`);

    const { data } = await get(`/all-products/?${queryParams}`);

    const newResults = data?.results || data || [];

    if (loadMore) {
      searchResults.value = [...searchResults.value, ...newResults];
    } else {
      searchResults.value = newResults;
    }

    // Check if there are more results based on returned data length
    hasMoreResults.value = newResults.length === 20;

    console.log("Mobile search results:", {
      searchQuery: mobileSearchQuery.value,
      resultsFound: newResults.length,
      totalResults: searchResults.value.length,
      hasMore: hasMoreResults.value,
      currentPage: currentPage.value,
    });
  } catch (error) {
    console.error("Mobile search error:", error);
    if (!loadMore) {
      searchResults.value = [];
    }
    hasMoreResults.value = false;
  } finally {
    isSearching.value = false;
    isLoadingMore.value = false;
  }
}

// Load more results function
async function loadMoreResults() {
  currentPage.value += 1;
  await performMobileSearch(true);
}

// Handle product click to close search overlay
function handleProductCardClick(product, event) {
  // Check if the click was on a NuxtLink (product title or image)
  const target = event.target.closest('a[href*="product-details"]');
  if (target) {
    event.preventDefault();
    closeMobileSearch();
    // Navigate after a small delay to ensure search overlay is closed
    setTimeout(() => {
      router.push(target.getAttribute("href"));
    }, 100);
  }
}

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
