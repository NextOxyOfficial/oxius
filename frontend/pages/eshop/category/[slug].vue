<template>  <div
    class="bg-gradient-to-b from-slate-50 via-white to-slate-50 dark:from-slate-900 dark:via-slate-900/95 dark:to-slate-800/90 min-h-screen pb-20 pt-4"
  >
    <UContainer>
        <!-- Modern Header Section -->
      <div class="mb-4">        
        <!-- Main Header Card -->
        <div class="relative bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-200/50 dark:border-gray-700/50 overflow-hidden">
          <!-- Subtle gradient overlay -->
          <div class="absolute inset-0 bg-gradient-to-br from-emerald-100/30 via-transparent to-blue-100/30 dark:from-emerald-900/10 dark:via-transparent dark:to-blue-900/10"></div>
          
          <div class="relative py-2 px-4 ">
            <!-- Header Row -->
            <div class="flex items-center justify-between">
              <!-- Left: Back Button + Category Name -->
              <div class="flex items-center gap-1 flex-1 min-w-0">                
                <!-- Back Button -->
                <button
                  @click="$router.push('/eshop')"
                  class="flex-shrink-0 inline-flex items-center justify-center w-10 h-10 text-gray-600 dark:text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-900/20 rounded-xl transition-all duration-200"
                >
                  <span class="sr-only">Back to eShop</span>
                  <UIcon name="material-symbols-light-arrow-back-ios-rounded" class="size-5" />
                </button>

                <!-- Category Name -->
                <div class="flex-1 min-w-0">
                  <h1 class="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white truncate">
                    {{ categoryDetails.name || 'Category' }}
                  </h1>
                </div>
              </div>                
              <!-- Right: Search, Filter & Share -->
              <div class="flex items-center gap-2 flex-shrink-0">                
                <!-- Search Button -->
                <button
                  @click="toggleSearch"
                  class="inline-flex items-center justify-center w-10 h-10 text-gray-600 dark:text-gray-400 hover:text-emerald-600 dark:hover:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-900/20 rounded-xl transition-all duration-200 search-container"
                >
                  <span class="sr-only">Search</span>
                  <UIcon name="i-heroicons-magnifying-glass" class="size-5" />
                </button>
                <!-- Filter Dropdown Button -->
                <button
                  @click="togglePriceRange"
                  class="inline-flex items-center justify-center w-10 h-10 text-gray-600 dark:text-gray-400 hover:text-purple-600 dark:hover:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-900/20 rounded-xl transition-all duration-200"
                >
                  <span class="sr-only">Price Filters</span>
                  <UIcon 
                    name="mdi-filter-multiple-outline" 
                    class="size-5 transition-transform duration-200" 
                  />
                </button>
                <!-- Share Button -->
                <button
                  @click="shareCategory"
                  class="inline-flex items-center justify-center w-10 h-10 text-gray-600 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-xl transition-all duration-200"
                >
                  <span class="sr-only">Share Category</span>
                  <UIcon name="i-heroicons-share" class="size-5" />
                </button>
              </div></div>

            <!-- Search Dropdown Section -->
            <transition
              enter-active-class="transition-all duration-300 ease-out"
              enter-from-class="opacity-0 max-h-0 overflow-hidden"
              enter-to-class="opacity-100 max-h-20"
              leave-active-class="transition-all duration-300 ease-in"
              leave-from-class="opacity-100 max-h-20"
              leave-to-class="opacity-0 max-h-0 overflow-hidden"
            >
              <div v-if="isSearchOpen" class="flex flex-col gap-3 px-4 py-4 border-t border-gray-100 dark:border-gray-700/30 search-container">
                <label class="text-sm font-medium text-gray-700 dark:text-gray-300 flex items-center gap-2 flex-shrink-0">
                  <UIcon name="i-heroicons-magnifying-glass" class="size-4 text-emerald-500" />
                  Search Products
                </label>

                <div class="relative">
                  <UIcon
                    name="i-heroicons-magnifying-glass"
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 size-4"
                  />
                  <input
                    ref="searchInput"
                    v-model="searchQuery"
                    type="text"
                    placeholder="Search in this category..."
                    class="w-full pl-10 pr-10 py-2.5 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-400 transition-all text-sm"
                    @input="debouncedSearch"
                    @keydown.escape="closeSearch"
                  />
                  <button
                    @click="clearSearch"
                    class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                  >
                    <UIcon name="i-heroicons-x-mark" class="size-4" />
                  </button>
                </div>
              </div>            
            </transition>

            <!-- Price Range Section -->
            <transition
              enter-active-class="transition-all duration-300 ease-out"
              enter-from-class="opacity-0 max-h-0 overflow-hidden"
              enter-to-class="opacity-100 max-h-20"
              leave-active-class="transition-all duration-300 ease-in"
              leave-from-class="opacity-100 max-h-20"
              leave-to-class="opacity-0 max-h-0 overflow-hidden"
            >
              <div v-if="isPriceRangeOpen" class="flex flex-col sm:flex-row gap-3 sm:items-center px-4 py-4 border-t border-gray-100 dark:border-gray-700/30">
                <label class="text-sm font-medium text-gray-700 dark:text-gray-300 flex items-center gap-2 flex-shrink-0">
                  <UIcon name="i-heroicons-banknotes" class="size-4 text-emerald-500" />
                  Price Range
                </label>

                <div class="flex items-center gap-3 flex-1">
                  <div class="relative flex-1">
                    <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500 dark:text-gray-400 text-sm font-medium">
                      ৳
                    </span>
                    <input
                      v-model="minPrice"
                      type="number"
                      placeholder="Min"
                      class="w-full pl-7 pr-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-400 transition-all text-sm"
                      @change="applyPriceFilter"
                    />
                  </div>

                  <span class="text-gray-400 flex-shrink-0">—</span>

                  <div class="relative flex-1">
                    <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500 dark:text-gray-400 text-sm font-medium">
                      ৳
                    </span>
                    <input
                      v-model="maxPrice"
                      type="number"
                      placeholder="Max"
                      class="w-full pl-7 pr-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-400 transition-all text-sm"
                      @change="applyPriceFilter"
                    />
                  </div>

                  <UButton
                    color="emerald"
                    variant="soft"
                    @click="applyPriceFilter"
                    class="whitespace-nowrap px-4 py-2 shadow-sm hover:shadow font-medium"
                  >
                    Apply
                  </UButton>
                </div>
              </div>
            </transition>
          </div>
        </div>
      </div><!-- Active Filters with elegantly styled badges -->
        <div
          v-if="hasActiveFilters"
          class="flex flex-wrap items-center gap-2 pt-4 border-t border-gray-100 dark:border-gray-700/30 mt-4"
        >          
          <span class="text-sm text-gray-600 dark:text-gray-600 font-medium"
            >Active filters:</span
          >

          <UBadge
            v-if="searchQuery"
            color="blue"
            variant="soft"
            class="pl-3 pr-2 py-1 group cursor-pointer"
            @click.stop="clearSearch"
          >
            Search: "{{ searchQuery }}"
            <span
              class="ml-1.5 bg-blue-200/50 dark:bg-blue-800/30 rounded-full p-0.5 group-hover:bg-blue-300/50 dark:group-hover:bg-blue-700/30 transition-colors"
            >
              <UIcon name="i-heroicons-x-mark" class="size-3" />
            </span>
          </UBadge>

          <UBadge
            v-if="minPrice || maxPrice"
            color="emerald"
            variant="soft"
            class="pl-3 pr-2 py-1 group cursor-pointer"
            @click.stop="clearPriceFilter"
          >
            Price: {{ minPrice || "0" }} - {{ maxPrice || "∞" }}
            <span
              class="ml-1.5 bg-emerald-200/50 dark:bg-emerald-800/30 rounded-full p-0.5 group-hover:bg-emerald-300/50 dark:group-hover:bg-emerald-700/30 transition-colors"
            >
              <UIcon name="i-heroicons-x-mark" class="size-3" />
            </span>
          </UBadge>

          <UButton
            v-if="hasActiveFilters"
            color="gray"
            variant="ghost"
            size="xs"
            @click="clearAllFilters"
            class="ml-2"
          >
            Clear all
          </UButton>
        </div>
      

      <!-- Enhanced Loading State -->
      <div v-if="isLoading" class="py-20">
        <div class="flex flex-col items-center justify-center">
          <div class="w-16 h-16 relative">
            <div
              class="w-full h-full rounded-full border-4 border-emerald-200 dark:border-emerald-800/20"
            ></div>
            <div
              class="w-full h-full rounded-full border-4 border-t-emerald-500 animate-spin absolute top-0 left-0"
            ></div>
          </div>
          <p class="text-center text-gray-600 mt-6 font-medium">
            Loading premium collection...
          </p>
        </div>
      </div>

      <!-- Enhanced No Results -->
      <div
        v-else-if="products?.results?.length === 0"
        class="py-20 text-center"
      >
        <div
          class="bg-gray-50 dark:bg-gray-800/50 rounded-full p-6 w-24 h-24 mx-auto flex items-center justify-center"
        >
          <UIcon
            name="i-heroicons-shopping-bag"
            class="size-12 text-gray-400 dark:text-gray-600"
          />
        </div>
        <h3 class="mt-6 text-xl font-medium text-gray-800 dark:text-gray-200">
          No products found
        </h3>
        <p class="mt-2 text-gray-600 dark:text-gray-600 max-w-md mx-auto">
          We couldn't find products matching your criteria. Try adjusting your
          filters.
        </p>
        <UButton
          class="mt-6"
          color="emerald"
          variant="soft"
          size="lg"
          @click="clearAllFilters"
        >
          Clear filters
        </UButton>
      </div>

      <!-- Enhanced Products Grid with Premium Card Layout -->
      <div
        v-else
        :class="{
          'grid gap-x-2 gap-y-3 sm:gap-3 mt-4': true,
          'grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5':
            viewMode === 'grid',
          'grid-cols-1 gap-y-3': viewMode === 'list',
        }"
        class="relative z-0"
      >
        <div
          v-for="product in allProducts"
          :key="product.id"
          class="premium-product-card group"
        >
          <CommonProductCard :product="product" />
        </div>
      </div>

      <!-- Infinity Loader -->
      <div ref="loadMoreTrigger" class="flex justify-center py-10 mt-6">
        <div v-if="isLoadingMore" class="flex flex-col items-center">
          <div class="w-10 h-10 relative">
            <div
              class="w-full h-full rounded-full border-3 border-emerald-200 dark:border-emerald-800/20"
            ></div>
            <div
              class="w-full h-full rounded-full border-3 border-t-emerald-500 animate-spin absolute top-0 left-0"
            ></div>
          </div>
          <p class="text-sm text-gray-600 dark:text-gray-600 mt-3">
            Loading more products...
          </p>
        </div>
        <div
          v-else-if="!hasMoreProducts && allProducts.length > 0"
          class="text-center py-4"
        >
          <p class="text-sm text-gray-600 dark:text-gray-600">
            You've reached the end of the list
          </p>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import { CommonHotDealsSection } from "#components";
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from "vue";
const { get } = useApi();
const products = ref({});
const isLoading = ref(true);
const toast = useToast();
const viewMode = ref("grid");
const route = useRoute();
const router = useRouter();

// Pagination and infinite scroll variables
const currentPage = ref(1);
const itemsPerPage = ref(20); // Products per page
const totalProducts = ref(0);
const allProducts = ref([]);
const isLoadingMore = ref(false);
const hasMoreProducts = ref(true);
const loadMoreTrigger = ref(null);
const categoryDetails = ref({});

// Filter state
const searchQuery = ref("");
const minPrice = ref("");
const maxPrice = ref("");

// Search functionality state
const isSearchOpen = ref(false);
const isMobile = ref(false);
const isPriceRangeOpen = ref(false);

// Search input references
const searchInput = ref(null);

// Computed property to check if any filters are active
const hasActiveFilters = computed(() => {
  return (
    minPrice.value ||
    maxPrice.value ||
    searchQuery.value
  );
});

// Search functionality
async function toggleSearch() {
  console.log('Toggle search clicked, current state:', isSearchOpen.value);
  isSearchOpen.value = !isSearchOpen.value;
  
  if (isSearchOpen.value) {
    await nextTick();
    try {
      if (searchInput.value) {
        searchInput.value.focus();
      }
    } catch (error) {
      console.error('Error focusing search input:', error);
    }
  }
}

function closeSearch() {
  console.log('Closing search');
  isSearchOpen.value = false;
  // Don't clear the search query when closing, just hide the UI
}

// Price range toggle functionality
function togglePriceRange() {
  isPriceRangeOpen.value = !isPriceRangeOpen.value;
}

// Share functionality
async function shareCategory() {
  const shareData = {
    title: `${categoryDetails.value.name || 'Category'} - AdsyClub eShop`,
    text: `Check out ${categoryDetails.value.name || 'this category'} with ${totalProducts.value} amazing products!`,
    url: window.location.href
  };

  try {
    if (navigator.share && navigator.canShare(shareData)) {
      await navigator.share(shareData);
    } else {
      // Fallback: copy to clipboard
      await navigator.clipboard.writeText(window.location.href);
      toast.add({
        title: "Link copied!",
        description: "Category link has been copied to your clipboard.",
        color: "emerald",
        timeout: 3000,
      });
    }
  } catch (error) {
    console.error('Error sharing:', error);
    // Fallback: copy to clipboard
    try {
      await navigator.clipboard.writeText(window.location.href);
      toast.add({
        title: "Link copied!",
        description: "Category link has been copied to your clipboard.",
        color: "emerald",
        timeout: 3000,
      });
    } catch (clipboardError) {
      toast.add({
        title: "Share failed",
        description: "Unable to share or copy link. Please try again.",
        color: "red",
        timeout: 3000,
      });
    }
  }
}

// Debounce search
let searchTimeout = null;
function debouncedSearch() {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    fetchProducts();
  }, 500);
}

async function getCategoryDetails() {
  try {
    const res = await get(`/product-categories/details/${route.params.slug}/`);
    if (res.data) {
      categoryDetails.value = res.data;
      console.log("Category Details:", categoryDetails.value);
    }
  } catch (error) {
    console.error("Error fetching category details:", error);
    toast.add({
      title: "Error loading category details",
      description: "Could not load category details. Please try again later.",
      color: "red",
      timeout: 3000,
    });
  }
}

await getCategoryDetails();

function clearPriceFilter() {
  minPrice.value = "";
  maxPrice.value = "";
  fetchProducts();
}

function clearSearch() {
  searchQuery.value = "";
  fetchProducts();
}

function applyPriceFilter() {
  currentPage.value = 1;
  fetchProducts();
}

function clearAllFilters() {
  minPrice.value = "";
  maxPrice.value = "";
  searchQuery.value = "";
  currentPage.value = 1;
  fetchProducts();
}

function handlePageChange(page) {
  window.scrollTo({ top: 0, behavior: "smooth" });
  fetchProducts();
}

// Data fetching
async function fetchProducts() {
  try {
    isLoading.value = true;

    // Build query parameters
    let queryParams = `page=${currentPage.value}&page_size=${itemsPerPage.value}`;

    if (categoryDetails.value?.id) {
      queryParams += `&category=${categoryDetails.value.id}`;
    }

    if (searchQuery.value) {
      queryParams += `&name=${encodeURIComponent(searchQuery.value)}`;
    }

    if (minPrice.value) {
      queryParams += `&min_price=${minPrice.value}`;
    }

    if (maxPrice.value) {
      queryParams += `&max_price=${maxPrice.value}`;
    }

    const res = await get(`/all-products/?${queryParams}`);
    products.value = res.data;
    totalProducts.value = res.data.count;

    // Reset allProducts and populate with initial results
    if (currentPage.value === 1) {
      allProducts.value = res.data.results || [];
    }

    // Update hasMoreProducts status
    hasMoreProducts.value =
      res.data.results && res.data.results.length === itemsPerPage.value;
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error loading products",
      description: "Could not load products. Please try again later.",
      color: "red",
      timeout: 3000,
    });
  } finally {
    isLoading.value = false;
  }
}

// Load more products function
async function loadMoreProducts() {
  if (isLoadingMore.value || !hasMoreProducts.value) return;

  try {
    isLoadingMore.value = true;
    currentPage.value++;

    // Build query parameters
    let queryParams = `page=${currentPage.value}&page_size=${itemsPerPage.value}`;

    if (categoryDetails.value?.id) {
      queryParams += `&category=${categoryDetails.value.id}`;
    }

    if (searchQuery.value) {
      queryParams += `&name=${encodeURIComponent(searchQuery.value)}`;
    }

    if (minPrice.value) {
      queryParams += `&min_price=${minPrice.value}`;
    }

    if (maxPrice.value) {
      queryParams += `&max_price=${maxPrice.value}`;
    }

    const res = await get(`/all-products/?${queryParams}`);
    const newProducts = res.data.results;

    // Add new products to the existing list
    if (newProducts && newProducts.length > 0) {
      allProducts.value = [...allProducts.value, ...newProducts];
    }

    // Check if there are more products to load
    hasMoreProducts.value = newProducts.length === itemsPerPage.value;
  } catch (error) {
    console.error("Error loading more products:", error);
    toast.add({
      title: "Error loading more products",
      description:
        "Could not load additional products. Please try again later.",
      color: "red",
      timeout: 3000,
    });
  } finally {
    isLoadingMore.value = false;
  }
}

// Initialize infinite scroll
function initInfiniteScroll() {
  const options = {
    root: null,
    rootMargin: "0px",
    threshold: 0.1,
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (
        entry.isIntersecting &&
        !isLoadingMore.value &&
        hasMoreProducts.value
      ) {
        loadMoreProducts();
      }
    });
  }, options);

  if (loadMoreTrigger.value) {
    observer.observe(loadMoreTrigger.value);
  }
}

// Initialize data
await fetchProducts();
onMounted(() => {
  initInfiniteScroll();
  
  // Detect mobile device
  const checkMobile = () => {
    isMobile.value = window.innerWidth < 768; // Tailwind md breakpoint
  };
  
  checkMobile();
  window.addEventListener('resize', checkMobile);
    // Close search when clicking outside
  const handleClickOutside = (event) => {
    if (isSearchOpen.value) {
      const searchContainer = event.target.closest('.search-container');
      if (!searchContainer) {
        closeSearch();
      }
    }
  };
  
  document.addEventListener('click', handleClickOutside);
  
  // Also listen for escape key globally
  const handleEscapeKey = (event) => {
    if (event.key === 'Escape') {
      if (isSearchOpen.value) {
        closeSearch();
      }
      if (isPriceRangeOpen.value) {
        isPriceRangeOpen.value = false;
      }
    }
  };
  
  document.addEventListener('keydown', handleEscapeKey);
});

// Clean up on unmount
onUnmounted(() => {
  // Cleanup event listeners
  window.removeEventListener('resize', () => {});
  document.removeEventListener('click', () => {});
  document.removeEventListener('keydown', () => {});
});
</script>

<style>
@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeInScale {
  from {
    opacity: 0;
    transform: scale(0.95) translateY(-10px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

@keyframes float {
  0%, 100% {
    transform: translateY(0px) scale(1);
  }
  50% {
    transform: translateY(-10px) scale(1.05);
  }
}

@keyframes float-delayed {
  0%, 100% {
    transform: translateY(0px) scale(1);
  }
  50% {
    transform: translateY(10px) scale(0.95);
  }
}

.animate-fade-up {
  animation: fadeUp 0.5s ease-out forwards;
}

.animate-fade-in-scale {
  animation: fadeInScale 0.3s ease-out forwards;
}

.animate-shimmer {
  animation: shimmer 3s infinite;
}

.animate-float {
  animation: float 6s ease-in-out infinite;
}

.animate-float-delayed {
  animation: float-delayed 8s ease-in-out infinite;
}

.premium-product-card {
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.premium-product-card:hover {
  transform: translateY(-6px);
}

.badge-discount {
  padding: 2px 6px;
  background-color: rgb(254, 242, 242);
  color: rgb(220, 38, 38);
  font-size: 0.75rem;
  font-weight: 500;
  border-radius: 9999px;
  border: 1px solid rgb(254, 226, 226);
}

.dark .badge-discount {
  background-color: rgba(220, 38, 38, 0.3);
  color: rgb(248, 113, 113);
  border-color: rgba(185, 28, 28, 0.4);
}

/* Touch slider styles */
.touch-slider {
  touch-action: pan-y;
  user-select: none;
}

.swipe-indicator {
  opacity: 0;
  transform: translateX(0);
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.swipe-indicator-left {
  transform: translateX(-10px);
}

.swipe-indicator-right {
  transform: translateX(10px);
}

.touch-slider.swiping-left .swipe-indicator-left {
  opacity: 0.8;
  transform: translateX(0);
}

.touch-slider.swiping-right .swipe-indicator-right {
  opacity: 0.8;
  transform: translateX(0);
}

/* Hide scrollbar for cleaner look */
.hide-scrollbar::-webkit-scrollbar {
  display: none;
}

.hide-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

/* Search container specific styles */
.search-container {
  position: relative;
  z-index: 50;
}

.search-container .absolute {
  z-index: 51 !important;
}
</style>
