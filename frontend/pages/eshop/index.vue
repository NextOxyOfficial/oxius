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
      <!-- Categories Sidebar Component -->      <CommonEshopCategoriesSidebar
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
          <!-- Search Section -->
          <div class="flex gap-3 items-center lg:flex-1">
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

          <!-- Price Range Section - Desktop: Right side of search -->
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
import {
  CommonHotDealsSection,
  CommonEshopBanner,
  CommonEshopCategoriesSidebar,
} from "#components";
import { ref, computed, watch, onMounted, onUnmounted } from "vue";
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
  fetchProducts();
}

function clearCategoryFilter() {
  selectedCategory.value = null;
  fetchProducts();
}

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
  selectedCategory.value = null;
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

// Sidebar toggle function
function toggleSidebar() {
  isSidebarOpen.value = !isSidebarOpen.value;
}

// Select category and close sidebar
function selectCategoryAndCloseSidebar(categoryId) {
  selectedCategory.value = categoryId;
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
    const nextBatch = categories.value.slice(currentCount, currentCount + batchSize);
    
    // Add the next batch to displayed categories
    displayedCategories.value.push(...nextBatch);
    
    // Update hasMoreCategoriesToLoad based on whether there are more categories
    hasMoreCategoriesToLoad.value = displayedCategories.value.length < categories.value.length;
    
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

async function fetchProducts() {
  try {
    isLoading.value = true;

    // Build query parameters
    let queryParams = `page=${currentPage.value}&page_size=${itemsPerPage.value}`;

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
await Promise.all([fetchCategories(), fetchProducts()]);
onMounted(() => {
  initInfiniteScroll();
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
