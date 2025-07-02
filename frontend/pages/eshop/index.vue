<template>
  <div
    class="bg-gradient-to-b from-slate-50 via-white to-slate-50 dark:from-slate-900 dark:via-slate-900/95 dark:to-slate-800/90 min-h-screen pb-20 page-eshop"
  >
    <!-- Premium Banner Slider with Enhanced Visual Effects -->
    <div class="pt-4 pb-2 mb-2">
      <UContainer>
        <CommonEshopBanner
          :customHeight="{
            mobile: '38%',
            tablet: '25%',
            desktop: '22%',
          }"
          endpoint="/eshop-banner/"
          :autoplayInterval="5000"
        />
      </UContainer>
    </div>
    <UContainer>
      <!-- Categories Sidebar Component -->
      <CommonEshopCategoriesSidebar
        :isOpen="isSidebarOpen"
        :displayedCategories="displayedCategories"
        :selectedCategory="selectedCategory"
        :hasMoreCategoriesToLoad="hasMoreCategoriesToLoad"
        :isLoadingMore="isLoadingMoreCategories"
        @close="toggleSidebar"
        @categorySelect="selectCategoryAndCloseSidebar"
        @loadMore="loadMoreCategories"
        @sellerRegistration="goToSellerRegistration"
        @contactSupport="contactSupport"
        @eshopManager="navigateToEshopManager"
      />

      <CommonHotDealsSection />
      <!-- Premium Search & Filters Section -->
      <div class="mb-5">
        <!-- Elegant Search Bar & Price Range - Responsive Layout -->
        <div class="flex flex-col lg:flex-row gap-3">
          <!-- Search Section - Hidden on mobile, visible on desktop -->
          <div class="hidden lg:flex gap-3 items-center lg:flex-1">
            <!-- Sidebar Toggle Button -->
            <button
              @click="toggleSidebar"
              class="inline-flex items-center justify-center p-2 rounded-lg border border-gray-200/80 dark:border-gray-700/80 bg-white/90 dark:bg-gray-800/80 backdrop-blur-sm hover:bg-gray-50 dark:hover:bg-gray-700/70 transition-all duration-200 shadow-sm hover:shadow flex-shrink-0 group"
              :class="{
                'text-emerald-500 border-emerald-200 dark:border-emerald-800/50':
                  isSidebarOpen,
              }"
            >
              <span class="sr-only">Toggle categories</span>
              <UIcon
                name="i-heroicons-bars-3"
                class="size-5 transition-transform group-hover:scale-110"
              />
            </button>

            <div class="relative flex-1">
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search products, brands, categories..."
                class="text-base w-full px-5 py-2 pl-12 pr-10 rounded-lg border border-gray-200/80 dark:border-gray-700/70 bg-white/90 dark:bg-gray-800/80 backdrop-blur-sm focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-400 transition-all duration-300 shadow-sm hover:shadow-sm placeholder:text-gray-600 dark:placeholder:text-gray-600"
                @input="debouncedSearch"
              />
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-600 dark:text-gray-600 size-5"
              />
              <button
                v-if="searchQuery"
                @click="clearSearch"
                class="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-600 hover:text-gray-800 dark:hover:text-gray-300 transition-colors"
              >
                <UIcon name="i-heroicons-x-mark" class="size-5" />
              </button>
            </div>
          </div>

          <!-- Price Range Section - Desktop: Right side of search, Mobile: Full width -->
          <div
            class="flex flex-col sm:flex-row lg:w-[55%] gap-3 sm:items-center"
          >
            <h3
              class="text-base px-2 font-medium text-gray-800 dark:text-gray-400 flex items-center lg:whitespace-nowrap"
            >
              <UIcon
                name="i-heroicons-banknotes"
                class="mr-2 size-4.5 text-emerald-500"
              />
              Price Range
            </h3>

            <div class="flex items-center gap-3 flex-1">
              <div class="relative flex-1">
                <span
                  class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-600 dark:text-gray-600 font-medium"
                  >৳</span
                >
                <input
                  v-model="minPrice"
                  type="number"
                  placeholder="Min"
                  class="w-full pl-8 pr-3 py-1.5 rounded-lg border border-gray-200/80 dark:border-gray-700/80 bg-white/70 dark:bg-gray-800/60 backdrop-blur-sm focus:ring-1 focus:ring-emerald-400 shadow-sm transition-all"
                  @change="applyPriceFilter"
                />
              </div>

              <div class="flex-shrink-0 text-gray-600">—</div>

              <div class="relative flex-1">
                <span
                  class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-600 dark:text-gray-600 font-medium"
                  >৳</span
                >
                <input
                  v-model="maxPrice"
                  type="number"
                  placeholder="Max"
                  class="w-full pl-8 pr-3 py-1.5 rounded-lg border border-gray-200/80 dark:border-gray-700/80 bg-white/70 dark:bg-gray-800/60 backdrop-blur-sm focus:ring-1 focus:ring-emerald-400 shadow-sm transition-all"
                  @change="applyPriceFilter"
                />
              </div>
              <UButton
                color="emerald"
                variant="soft"
                @click="applyPriceFilter"
                class="whitespace-nowrap px-4 py-1.5 shadow-sm hover:shadow font-medium"
              >
                Apply Filter
              </UButton>
            </div>
          </div>
        </div>
      </div>

      <!-- Elegant Filter Container -->
      <div
        class="bg-white/70 dark:bg-gray-800/40 backdrop-blur-[2px] rounded-xl px-2 py-2 border border-gray-100 dark:border-gray-700/50 shadow-sm"
      >
        <div class="">
          <!-- Categories Column -->
          <div class="lg:col-span-3">
            <h3
              class="text-base font-medium mb-3 text-gray-800 dark:text-gray-400 flex items-center"
            >
              <UIcon
                name="i-heroicons-circle-stack"
                class="mr-2 size-4 text-emerald-500"
              />
              Categories
            </h3>

            <!-- Horizontal scrollable categories -->
            <div
              class="overflow-x-auto py-2 px-1 md:flex flex-nowrap gap-2 hide-scrollbar hidden"
            >
              <div class="flex gap-2">
                <UBadge
                  v-for="category in categories"
                  :key="category.id"
                  :color="selectedCategory === category.id ? 'emerald' : 'gray'"
                  variant="soft"
                  size="lg"
                  class="cursor-pointer whitespace-nowrap transition-all duration-300 px-4 py-1.5 hover:shadow-sm"
                  :class="
                    selectedCategory === category.id
                      ? 'ring-2 ring-emerald-200 dark:ring-emerald-800/30'
                      : ''
                  "
                  @click="toggleCategory(category.id)"
                >
                  {{ category.name }}
                </UBadge>
              </div>
            </div>
          </div>

          <!-- Price Filter Column -->
        </div>

        <!-- Active Filters with elegantly styled badges -->
        <div
          v-if="hasActiveFilters"
          class="flex flex-wrap items-center gap-2 mt-6 pt-5 border-t border-gray-100 dark:border-gray-700/30"
        >
          <span class="text-sm text-gray-600 dark:text-gray-600 font-medium"
            >Active filters:</span
          >

          <UBadge
            v-if="selectedCategory"
            color="emerald"
            variant="soft"
            class="pl-3 pr-2 py-1.5 group"
            @click.stop="clearCategoryFilter"
          >
            {{ getCategoryName(selectedCategory) }}
            <span
              class="ml-1.5 bg-emerald-200/50 dark:bg-emerald-800/30 rounded-full p-0.5 group-hover:bg-emerald-300/50 dark:group-hover:bg-emerald-700/30 transition-colors"
            >
              <UIcon name="i-heroicons-x-mark" class="size-3" />
            </span>
          </UBadge>

          <UBadge
            v-if="minPrice || maxPrice"
            color="emerald"
            variant="soft"
            class="pl-3 pr-2 py-1 group"
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
          v-else-if="hasMoreProducts && allProducts.length > 0 && !isLoading"
          class="text-center py-4"
        >
          <UButton
            @click="loadMoreProducts"
            color="emerald"
            variant="soft"
            size="lg"
            :loading="isLoadingMore"
            :disabled="isLoadingMore"
            class="px-8 py-3"
          >
            <template v-if="!isLoadingMore">
              Load More Products
            </template>
            <template v-else>
              Loading...
            </template>
          </UButton>
          <p class="text-xs text-gray-500 mt-2">
            Showing {{ allProducts.length }} of {{ totalProducts }} products
          </p>
        </div>
        <div
          v-else-if="!hasMoreProducts && allProducts.length > 0"
          class="text-center py-4"
        >
          <p class="text-sm text-gray-600 dark:text-gray-600">
            You've reached the end of the list
          </p>
          <p class="text-xs text-gray-500 mt-1">
            Showing all {{ allProducts.length }} products
          </p>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "eshop",
});

import {
  CommonHotDealsSection,
  CommonEshopBanner,
  CommonEshopCategoriesSidebar,
} from "#components";
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from "vue";
const { get } = useApi();
const products = ref({});
const categories = ref([]);
const isLoading = ref(true);
const toast = useToast();
const viewMode = ref("grid");

// Pagination and infinite scroll variables
const currentPage = ref(1);
const itemsPerPage = ref(20); // Products per page
const totalProducts = ref(0);
const allProducts = ref([]);
const isLoadingMore = ref(false);
const hasMoreProducts = ref(true);
const loadMoreTrigger = ref(null);

// Filter state
const searchQuery = ref("");
const selectedCategory = ref(null);
const minPrice = ref("");
const maxPrice = ref("");
const isSidebarOpen = ref(false);

// Sidebar state
const displayedCategories = ref([]);
const hasMoreCategoriesToLoad = ref(false);
const isLoadingMoreCategories = ref(false);

// Computed property to check if any filters are active
const hasActiveFilters = computed(() => {
  return (
    selectedCategory.value ||
    minPrice.value ||
    maxPrice.value ||
    searchQuery.value
  );
});

// Debounce search
let searchTimeout = null;
function debouncedSearch() {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    currentPage.value = 1;
    allProducts.value = [];
    hasMoreProducts.value = true;
    fetchProducts();
  }, 500);
}

// Get category name by ID
function getCategoryName(categoryId) {
  const category = categories.value.find((cat) => cat.id === categoryId);
  return category ? category.name : "";
}

// Filter functions
function toggleCategory(categoryId) {
  if (selectedCategory.value === categoryId) {
    selectedCategory.value = null;
  } else {
    selectedCategory.value = categoryId;
  }
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;
  fetchProducts();
}

function clearCategoryFilter() {
  selectedCategory.value = null;
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;
  fetchProducts();
}

function clearPriceFilter() {
  minPrice.value = "";
  maxPrice.value = "";
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;
  fetchProducts();
}

function clearSearch() {
  searchQuery.value = "";
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;
  fetchProducts();
}

function applyPriceFilter() {
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;
  fetchProducts();
}

function clearAllFilters() {
  selectedCategory.value = null;
  minPrice.value = "";
  maxPrice.value = "";
  searchQuery.value = "";
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;
  fetchProducts();
}

function handlePageChange(page) {
  window.scrollTo({ top: 0, behavior: "smooth" });
  fetchProducts();
}

// Sidebar toggle function
function toggleSidebar() {
  isSidebarOpen.value = !isSidebarOpen.value;
  
  // Notify header component of state change
  if (process.client) {
    window.dispatchEvent(new CustomEvent('eshop-sidebar-state-update', {
      detail: { isOpen: isSidebarOpen.value }
    }));
  }
}

// Listen for sidebar toggle from header
const handleHeaderSidebarToggle = (event) => {
  isSidebarOpen.value = event.detail.isOpen;
};

// Select category and close sidebar
function selectCategoryAndCloseSidebar(categoryId) {
  selectedCategory.value = categoryId;
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;
  toggleSidebar();
  fetchProducts();
}

// Load more categories
async function loadMoreCategories() {
  // Check if already loading or no more categories to load
  if (isLoadingMoreCategories.value || !hasMoreCategoriesToLoad.value) {
    return;
  }

  try {
    isLoadingMoreCategories.value = true;

    // Calculate how many categories to load next
    const currentCount = displayedCategories.value.length;
    const batchSize = 10;
    const nextBatch = categories.value.slice(
      currentCount,
      currentCount + batchSize
    );

    // Add the next batch to displayed categories
    displayedCategories.value.push(...nextBatch);

    // Update hasMoreCategoriesToLoad based on whether there are more categories
    hasMoreCategoriesToLoad.value =
      displayedCategories.value.length < categories.value.length;
  } catch (error) {
    console.error("Error loading more categories:", error);
    toast.add({
      title: "Error loading categories",
      description: "Could not load more categories. Please try again later.",
      color: "red",
      timeout: 3000,
    });
  } finally {
    isLoadingMoreCategories.value = false;
  }
}

// Seller registration function
function goToSellerRegistration() {
  // Navigate to seller registration page
  navigateTo("/shop-manager");
  toggleSidebar();
}

// Customer support contact function
function contactSupport(type) {
  if (type === "chat") {
    // Open live chat support
    toast.add({
      title: "Live Chat",
      description: "Connecting you with a customer support agent...",
      color: "blue",
      timeout: 3000,
    });
    // Here you would typically initialize your chat widget
  } else if (type === "email") {
    // Open email support form or redirect to contact page
    navigateTo("/contact-us");
    toggleSidebar();
  }
}

// Navigate to eShop Manager
function navigateToEshopManager() {
  navigateTo("/shop-manager");
}

// Data fetching
async function fetchCategories() {
  try {
    const res = await get("/product-categories/");
    categories.value = res.data;
    displayedCategories.value = res.data.slice(0, 10); // Display first 10 categories initially
    hasMoreCategoriesToLoad.value = res.data.length > 10;
  } catch (error) {
    console.error("Error fetching categories:", error);
    toast.add({
      title: "Error loading categories",
      description: "Could not load categories. Please try again later.",
      color: "red",
      timeout: 3000,
    });
  }
}

// Fetch diverse products from different categories
async function fetchDiverseProducts() {
  try {
    if (categories.value.length === 0) {
      // Fallback to regular fetch if no categories
      const res = await get(
        `/all-products/?page=1&page_size=${itemsPerPage.value}&ordering=-created_at`
      );
      return res.data?.results || [];
    }

    const diverseProducts = [];
    const targetCount = itemsPerPage.value; // Always aim for exactly 20 products
    const productsPerCategory = Math.max(
      2,
      Math.floor(targetCount / Math.min(6, categories.value.length))
    );
    const maxCategoriesToFetch = Math.min(6, categories.value.length); // Limit to 6 categories for performance

    // Shuffle categories to get random selection
    const shuffledCategories = [...categories.value].sort(
      () => Math.random() - 0.5
    );

    // Fetch products from each category with error handling
    const categoryPromises = shuffledCategories
      .slice(0, maxCategoriesToFetch)
      .map(async (category) => {
        try {
          const res = await get(
            `/all-products/?category=${category.id}&page_size=${productsPerCategory}&ordering=-created_at`
          );
          return res.data?.results || [];
        } catch (error) {
          console.warn(
            `Error fetching products for category ${category.name}:`,
            error
          );
          return [];
        }
      });

    const categoryResults = await Promise.allSettled(categoryPromises);

    // Combine all successful results
    categoryResults.forEach((result) => {
      if (result.status === 'fulfilled' && result.value) {
        diverseProducts.push(...result.value);
      }
    });

    // Always ensure we have exactly the target count
    if (diverseProducts.length < targetCount) {
      try {
        const additionalCount = targetCount - diverseProducts.length;
        const res = await get(
          `/all-products/?page_size=${additionalCount * 2}&ordering=-created_at`
        );
        const additionalProducts = (res.data?.results || []).filter(
          (product) =>
            !diverseProducts.some((existing) => existing.id === product.id)
        );
        diverseProducts.push(...additionalProducts.slice(0, additionalCount));
      } catch (error) {
        console.warn("Error fetching additional products:", error);
      }
    }

    // If we still don't have enough, fetch more with a larger request
    if (diverseProducts.length < targetCount) {
      try {
        const stillNeeded = targetCount - diverseProducts.length;
        const res = await get(
          `/all-products/?page_size=${stillNeeded * 3}&ordering=random`
        );
        const moreProducts = (res.data?.results || []).filter(
          (product) =>
            !diverseProducts.some((existing) => existing.id === product.id)
        );
        diverseProducts.push(...moreProducts.slice(0, stillNeeded));
      } catch (error) {
        console.warn("Error fetching backup products:", error);
      }
    }

    // Shuffle and ensure exactly the target count
    const finalProducts = diverseProducts
      .sort(() => Math.random() - 0.5)
      .slice(0, targetCount);

    console.log("Diverse products fetched:", {
      categoriesUsed: maxCategoriesToFetch,
      targetCount: targetCount,
      totalProductsFetched: diverseProducts.length,
      finalProductsCount: finalProducts.length,
      itemsPerPageSetting: itemsPerPage.value,
    });

    return finalProducts;
  } catch (error) {
    console.error("Error fetching diverse products:", error);
    // Fallback to regular fetch that guarantees the right count
    try {
      const res = await get(
        `/all-products/?page=1&page_size=${itemsPerPage.value}&ordering=-created_at`
      );
      return res.data?.results || [];
    } catch (fallbackError) {
      console.error("Fallback fetch also failed:", fallbackError);
      return [];
    }
  }
}

async function fetchProducts() {
  try {
    isLoading.value = true;

    // Build query parameters
    let queryParams = `page=${currentPage.value}&page_size=${itemsPerPage.value}`;

    // Add ordering - use consistent ordering for better pagination
    if (
      !selectedCategory.value &&
      !searchQuery.value &&
      !minPrice.value &&
      !maxPrice.value &&
      currentPage.value === 1
    ) {
      // Only use random ordering for the very first page with no filters
      queryParams += `&ordering=random`;
    } else {
      // Use consistent ordering for filtered results and pagination
      queryParams += `&ordering=-created_at`;
    }

    if (selectedCategory.value) {
      queryParams += `&category=${selectedCategory.value}`;
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

    console.log("Fetching products with URL:", `/all-products/?${queryParams}`);

    const res = await get(`/all-products/?${queryParams}`);

    // More robust response validation
    if (!res || !res.data) {
      console.warn("Invalid API response structure, using empty results");
      // Set default values instead of throwing error
      products.value = { results: [], count: 0 };
      totalProducts.value = 0;
      allProducts.value = [];
      hasMoreProducts.value = false;
      return;
    }

    let productsToDisplay = res.data.results || [];

    // Only use diverse products for the very first page with no filters
    if (
      !selectedCategory.value &&
      !searchQuery.value &&
      !minPrice.value &&
      !maxPrice.value &&
      currentPage.value === 1 &&
      categories.value.length > 0
    ) {
      try {
        const diverseProducts = await fetchDiverseProducts();
        if (diverseProducts && diverseProducts.length > 0) {
          productsToDisplay = diverseProducts;
          // Update response data structure to maintain consistency
          products.value = { 
            ...res.data, 
            results: diverseProducts,
            count: res.data.count || diverseProducts.length 
          };
        } else {
          products.value = res.data;
        }
      } catch (diverseError) {
        console.warn("Failed to fetch diverse products, using regular results:", diverseError);
        products.value = res.data;
      }
    } else {
      products.value = res.data;
    }

    // Update total products count
    totalProducts.value = res.data.count || 0;

    // Reset allProducts and populate with initial results for first page
    if (currentPage.value === 1) {
      allProducts.value = productsToDisplay;
    }

    // Update hasMoreProducts status - simplified logic
    hasMoreProducts.value = allProducts.value.length < totalProducts.value;

    console.log("Fetch Products Debug:", {
      currentPage: currentPage.value,
      totalProducts: totalProducts.value,
      currentProductsCount: allProducts.value.length,
      hasMoreProducts: hasMoreProducts.value,
      resultsLength: productsToDisplay.length,
      apiTotalCount: res.data.count,
      itemsPerPageSetting: itemsPerPage.value,
    });

  } catch (error) {
    console.error("Error fetching products:", error);
    
    // Only show user-friendly errors, not technical details
    toast.add({
      title: "Unable to load products",
      description: "Please refresh the page or try again later.",
      color: "orange",
      timeout: 4000,
    });
    
    // Set safe defaults
    products.value = { results: [], count: 0 };
    totalProducts.value = 0;
    allProducts.value = [];
    hasMoreProducts.value = false;
  } finally {
    isLoading.value = false;

    // Reinitialize infinite scroll after loading is complete
    if (currentPage.value === 1) {
      nextTick(() => {
        setTimeout(() => {
          initInfiniteScroll();
        }, 300);
      });
    }
  }
}

// Load more products function
async function loadMoreProducts() {
  if (isLoadingMore.value || !hasMoreProducts.value) {
    console.log("Load more blocked:", { isLoadingMore: isLoadingMore.value, hasMoreProducts: hasMoreProducts.value });
    return;
  }

  try {
    isLoadingMore.value = true;
    const nextPage = currentPage.value + 1;

    // Build query parameters - always use consistent ordering for pagination
    let queryParams = `page=${nextPage}&page_size=${itemsPerPage.value}&ordering=-created_at`;

    if (selectedCategory.value) {
      queryParams += `&category=${selectedCategory.value}`;
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

    console.log("Loading more products with URL:", `/all-products/?${queryParams}`);

    const res = await get(`/all-products/?${queryParams}`);
    
    // More robust response validation
    if (!res) {
      console.warn("No response received from API");
      return; // Exit silently, don't show error to user
    }

    if (!res.data) {
      console.warn("No data property in API response");
      return; // Exit silently, don't show error to user
    }

    const newProducts = res.data.results || [];
    const responseCount = res.data.count || 0;

    console.log("Load More Products Debug:", {
      nextPage: nextPage,
      newProductsLength: newProducts.length,
      allProductsCountBefore: allProducts.value.length,
      totalProducts: responseCount,
      hasMoreProductsBefore: hasMoreProducts.value,
      expectedItemsPerPage: itemsPerPage.value,
    });

    // Update total products count if available
    if (responseCount > 0) {
      totalProducts.value = responseCount;
    }

    // Add new products to the existing list if we got results
    if (newProducts && newProducts.length > 0) {
      // Filter out any duplicate products to avoid display issues
      const existingIds = new Set(allProducts.value.map(p => p.id));
      const uniqueNewProducts = newProducts.filter(p => !existingIds.has(p.id));
      
      allProducts.value = [...allProducts.value, ...uniqueNewProducts];
      currentPage.value = nextPage; // Only update page if we successfully got new products
      
      console.log("Added products:", {
        newProductsCount: newProducts.length,
        uniqueNewProductsCount: uniqueNewProducts.length,
        totalProductsAfter: allProducts.value.length,
        itemsPerPageSetting: itemsPerPage.value,
      });
    }

    // Check if there are more products to load
    // More robust check with edge case handling
    if (newProducts.length === 0) {
      hasMoreProducts.value = false;
      console.log("No more products available - reached end of list");
    } else {
      // We have more products if our current total is less than API total
      hasMoreProducts.value = allProducts.value.length < totalProducts.value;
      
      // Additional safety check: if we got fewer products than requested, we might be at the end
      if (newProducts.length < itemsPerPage.value) {
        hasMoreProducts.value = false;
        console.log("Received fewer products than requested - likely at end of list");
      }
    }

    console.log("Load More Products Result:", {
      newProductsLength: newProducts.length,
      totalProductsAfter: allProducts.value.length,
      totalAvailable: totalProducts.value,
      hasMoreProducts: hasMoreProducts.value,
      currentPage: currentPage.value,
      shouldHaveMore: allProducts.value.length < totalProducts.value,
    });

  } catch (error) {
    console.error("Error loading more products:", error);
    
    // Only show user-friendly errors for network/server issues
    // Don't show technical validation errors
    if (error.message && !error.message.includes("Invalid response structure")) {
      toast.add({
        title: "Unable to load more products",
        description: "Please check your connection and try again.",
        color: "orange",
        timeout: 3000,
      });
    }
    
    // Don't increment currentPage.value if there was an error
  } finally {
    isLoadingMore.value = false;
  }
}

// Initialize infinite scroll
let observer = null;

function initInfiniteScroll() {
  // Clean up existing observer
  if (observer) {
    observer.disconnect();
    observer = null;
  }

  const options = {
    root: null,
    rootMargin: "300px", // Start loading 300px before the element comes into view
    threshold: 0.1,
  };

  observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      console.log("Intersection Observer triggered:", {
        isIntersecting: entry.isIntersecting,
        isLoadingMore: isLoadingMore.value,
        hasMoreProducts: hasMoreProducts.value,
        allProductsLength: allProducts.value.length,
        totalProducts: totalProducts.value,
        isLoading: isLoading.value,
        itemsPerPage: itemsPerPage.value,
      });

      if (
        entry.isIntersecting &&
        !isLoadingMore.value &&
        !isLoading.value &&
        hasMoreProducts.value &&
        allProducts.value.length > 0
      ) {
        console.log("🚀 Triggering loadMoreProducts...");
        loadMoreProducts();
      } else {
        console.log("❌ Infinite scroll conditions not met:", {
          isIntersecting: entry.isIntersecting,
          isLoadingMore: isLoadingMore.value,
          isLoading: isLoading.value,
          hasMoreProducts: hasMoreProducts.value,
          allProductsLength: allProducts.value.length,
        });
      }
    });
  }, options);

  // Use nextTick to ensure the element is in DOM
  nextTick(() => {
    setTimeout(() => {
      if (loadMoreTrigger.value) {
        observer.observe(loadMoreTrigger.value);
        console.log("✅ Infinite scroll observer attached to element:", loadMoreTrigger.value);
      } else {
        console.warn("⚠️ Load more trigger element not found");
      }
    }, 100);
  });
}

// Clean up observer on unmount
onUnmounted(() => {
  if (observer) {
    observer.disconnect();
  }
  
  // Clean up event listeners
  if (process.client) {
    window.removeEventListener('eshop-sidebar-toggle', handleHeaderSidebarToggle);
  }
});

// Watch for filter changes and reinitialize infinite scroll
watch([selectedCategory, searchQuery, minPrice, maxPrice], () => {
  // Reset pagination state when filters change
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;

  // Fetch new products based on updated filters
  fetchProducts();

  // Reinitialize infinite scroll after a brief delay to ensure DOM updates
  nextTick(() => {
    setTimeout(() => {
      initInfiniteScroll();
    }, 200);
  });
}, { deep: true });

// Debug function to help test infinite scroll
function debugInfiniteScroll() {
  console.log("=== 🔍 Infinite Scroll Debug Info ===");
  console.log("Current Page:", currentPage.value);
  console.log("Items Per Page:", itemsPerPage.value);
  console.log("Total Products:", totalProducts.value);
  console.log("All Products Length:", allProducts.value.length);
  console.log("Has More Products:", hasMoreProducts.value);
  console.log("Is Loading More:", isLoadingMore.value);
  console.log("Is Loading:", isLoading.value);
  console.log("Load More Trigger Element:", loadMoreTrigger.value);
  console.log("Observer:", observer);
  console.log("Selected Category:", selectedCategory.value);
  console.log("Search Query:", searchQuery.value);
  console.log("Min Price:", minPrice.value);
  console.log("Max Price:", maxPrice.value);
  console.log("Should load more?", allProducts.value.length < totalProducts.value);
  console.log("Expected products per page:", itemsPerPage.value);
  console.log("===================================");
}

// Force load more for debugging
function forceLoadMore() {
  console.log("🔧 Forcing load more products...");
  if (isLoadingMore.value) {
    console.log("⏳ Already loading more products, please wait...");
    return;
  }
  if (!hasMoreProducts.value) {
    console.log("🛑 No more products available to load");
    console.log("Current products:", allProducts.value.length, "Total available:", totalProducts.value);
    return;
  }
  console.log("✅ Conditions met, calling loadMoreProducts...");
  loadMoreProducts();
}

// Test API directly
async function testAPIDirectly() {
  console.log("🧪 Testing API directly...");
  const nextPage = currentPage.value + 1;
  const testUrl = `/all-products/?page=${nextPage}&page_size=${itemsPerPage.value}&ordering=-created_at`;
  console.log("Test URL:", testUrl);
  
  try {
    const res = await get(testUrl);
    console.log("✅ API Response:", {
      resultsLength: res.data?.results?.length || 0,
      totalCount: res.data?.count || 0,
      hasResults: !!res.data?.results,
      results: res.data?.results || []
    });
  } catch (error) {
    console.error("❌ API Error:", error);
  }
}

// Reset pagination for debugging
function resetPagination() {
  console.log("🔄 Resetting pagination...");
  currentPage.value = 1;
  allProducts.value = [];
  hasMoreProducts.value = true;
  fetchProducts();
}

// Expose debug functions to window for manual testing
if (process.client) {
  window.debugInfiniteScroll = debugInfiniteScroll;
  window.forceLoadMore = forceLoadMore;
  window.testAPIDirectly = testAPIDirectly;
  window.resetPagination = resetPagination;
  window.manualLoadMore = () => {
    if (!isLoadingMore.value && hasMoreProducts.value) {
      loadMoreProducts();
    } else {
      console.log("Cannot load more:", {
        isLoadingMore: isLoadingMore.value,
        hasMoreProducts: hasMoreProducts.value,
      });
    }
  };
}

// Initialize data
await Promise.all([fetchCategories(), fetchProducts()]);

onMounted(() => {
  // Initialize infinite scroll after a delay to ensure DOM is ready
  setTimeout(() => {
    initInfiniteScroll();
  }, 500);
  
  // Listen for sidebar toggle from header
  if (process.client) {
    window.addEventListener('eshop-sidebar-toggle', handleHeaderSidebarToggle);
  }
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

@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-fade-up {
  animation: fadeUp 0.5s ease-out forwards;
}

.animate-shimmer {
  animation: shimmer 3s infinite;
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
</style>
