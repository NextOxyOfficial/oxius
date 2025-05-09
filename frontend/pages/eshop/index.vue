<template>
  <div
    class="bg-gradient-to-b from-slate-50 via-white to-slate-50 dark:from-slate-900 dark:via-slate-900/95 dark:to-slate-800/90 min-h-screen pb-20"
  >
    <!-- Premium Banner Slider with Enhanced Visual Effects -->
    <div class="pt-4 pb-2 mb-2">
      <UContainer>
        <div class="relative overflow-hidden rounded-xl shadow-md">
          <!-- Background pattern for premium look -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-slate-900/5 to-slate-900/5 dark:from-slate-950/20 dark:to-slate-950/10 backdrop-blur-[1px] z-0"
          ></div>

          <div class="carousel-container overflow-hidden">
            <div
              class="carousel-slides flex transition-transform duration-700 ease-in-out"
              :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
            >
              <div
                v-for="(banner, index) in banners"
                :key="index"
                class="w-full flex-shrink-0 relative"
              >
                <!-- Image with subtle overlay -->
                <div class="relative">
                  <img
                    :src="banner.image"
                    :alt="banner.title"
                    class="relative h-[200px] sm:h-[250px] md:h-[300px] w-full overflow-hidden"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </UContainer>
    </div>

    <UContainer>
      <!-- Categories Sidebar -->
      <transition name="slide">
        <div 
          v-if="isSidebarOpen" 
          class="fixed top-0 left-0 h-full z-40 bg-white dark:bg-gray-900 shadow-xl border-r border-gray-200 dark:border-gray-700 w-72 overflow-hidden flex flex-col"
        >
          <div class="p-4 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between">
            <h2 class="text-lg font-medium text-gray-800 dark:text-gray-200 flex items-center">
              <UIcon name="i-heroicons-squares-2x2" class="mr-2 size-5 text-emerald-500" />
              Categories
            </h2>
            <button 
              @click="toggleSidebar" 
              class="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"
            >
              <UIcon name="i-heroicons-x-mark" class="size-5" />
            </button>
          </div>
          
          <div class="overflow-y-auto flex-1 py-4 px-3">
            <ul class="space-y-1">
              <li v-for="category in displayedCategories" :key="category.id">
                <button 
                  @click="selectCategoryAndCloseSidebar(category.id)"
                  class="w-full text-left px-3 py-2.5 rounded-lg flex items-center gap-3 transition-colors"
                  :class="selectedCategory === category.id 
                    ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400' 
                    : 'hover:bg-gray-100 dark:hover:bg-gray-800/60 text-gray-700 dark:text-gray-300'"
                >
                  <div class="flex-shrink-0 size-7 flex items-center justify-center rounded-md bg-gray-100 dark:bg-gray-800">
                    <UIcon 
                      :name="getCategoryIcon(category.name)" 
                      class="size-4"
                      :class="selectedCategory === category.id ? 'text-emerald-500' : 'text-gray-500 dark:text-gray-400'" 
                    />
                  </div>
                  <span class="truncate">{{ category.name }}</span>
                  <span 
                    v-if="selectedCategory === category.id"
                    class="ml-auto flex-shrink-0 size-2 rounded-full bg-emerald-500"
                  ></span>
                </button>
              </li>
            </ul>
            
            <div v-if="hasMoreCategoriesToLoad" class="pt-4 pb-2 flex justify-center">
              <UButton
                @click="loadMoreCategories"
                color="gray"
                variant="soft"
                size="sm"
                class="w-full"
              >
                <UIcon name="i-heroicons-arrow-down" class="size-4 mr-1" />
                Load more
              </UButton>
            </div>
            
            <!-- Sell on eShop Section -->
            <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700/60">
              <div class="bg-gradient-to-r from-emerald-50 to-emerald-100 dark:from-emerald-900/20 dark:to-emerald-800/20 rounded-xl p-4 shadow-sm">
                <h3 class="font-medium text-emerald-700 dark:text-emerald-400 flex items-center">
                  <UIcon name="i-heroicons-shopping-bag" class="mr-2 size-5" />
                  Want to sell your products in our eShop? Contact us today
                </h3>
                <p class="text-sm mt-2 text-gray-600 dark:text-gray-300">
                  Join our marketplace and start selling your products to thousands of customers.
                </p>
                <UButton
                  color="emerald"
                  variant="solid"
                  size="sm"
                  class="mt-3 w-full"
                  @click="goToSellerRegistration"
                >
                  Become a Seller
                </UButton>
              </div>
            </div>
            
            <!-- Customer Support Section -->
            <div class="mt-6">
              <div class="bg-gradient-to-r from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20 rounded-xl p-4 shadow-sm">
                <h3 class="font-medium text-blue-700 dark:text-blue-400 flex items-center">
                  <UIcon name="i-heroicons-chat-bubble-left-right" class="mr-2 size-5" />
                  Need Help?
                </h3>
                <p class="text-sm mt-2 text-gray-600 dark:text-gray-300">
                  Our customer support team is here to assist you with any questions or issues.
                </p>
                <div class="mt-3 flex gap-2">
                  <UButton
                    color="blue"
                    variant="soft"
                    size="sm"
                    class="flex-1"
                    @click="contactSupport('chat')"
                  >
                    <UIcon name="i-heroicons-chat-bubble-oval-left" class="mr-1" />
                    Live Chat
                  </UButton>
                  <UButton
                    color="white"
                    variant="solid"
                    size="sm"
                    class="flex-1"
                    @click="contactSupport('email')"
                  >
                    <UIcon name="i-heroicons-envelope" class="mr-1" />
                    Email
                  </UButton>
                </div>
              </div>
            </div>
          </div>
        </div>
      </transition>
      
      <!-- Backdrop overlay when sidebar is open -->
      <div 
        v-if="isSidebarOpen" 
        class="fixed inset-0 bg-black/30 dark:bg-black/50 backdrop-blur-sm z-30"
        @click="toggleSidebar"
      ></div>
      
      <CommonHotDealsSection/>
      <!-- Premium Search & Filters Section -->
      <div class="mb-3 space-y-3">
        <!-- Elegant Search Bar -->
        <div class="flex gap-2 items-center">
          <!-- Sidebar Toggle Button -->
          <button 
            @click="toggleSidebar"
            class="inline-flex items-center justify-center p-2.5 rounded-md border border-gray-200/80 dark:border-gray-700/80 bg-white/70 dark:bg-gray-800/60 backdrop-blur-sm hover:bg-gray-50 dark:hover:bg-gray-700/60 transition-colors shadow-sm flex-shrink-0"
            :class="{'text-emerald-500': isSidebarOpen}"
          >
            <UIcon 
              name="i-heroicons-bars-3" 
              class="size-5" 
            />
          </button>
          
          <div class="relative flex-1">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search premium products..."
              class="text-base w-full px-5 py-2.5 pl-12 pr-12 rounded-xl border border-gray-200/80 dark:border-gray-700/80 bg-white/70 dark:bg-gray-800/60 backdrop-blur-sm focus:ring-2 focus:ring-emerald-500/60 focus:border-emerald-400 transition-all duration-300 shadow-sm hover:shadow-md"
              @input="debouncedSearch"
            />
            <UIcon
              name="i-heroicons-magnifying-glass"
              class="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 size-5"
            />
            <button
              v-if="searchQuery"
              @click="clearSearch"
              class="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <UIcon name="i-heroicons-x-mark" class="size-5" />
            </button>
          </div>
        </div>

        <div class="flex flex-col sm:flex-row gap-1 sm:items-center">
          <h3
            class="text-base font-medium text-gray-700 dark:text-gray-300 flex items-center"
          >
            <UIcon
              name="i-heroicons-banknotes"
              class="mr-2 size-4 text-emerald-500"
            />
            Price Range:
          </h3>

          <div class="flex items-center space-x-3">
            <div class="relative flex-1">
              <span
                class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500"
                >৳</span
              >
              <input
                v-model="minPrice"
                type="number"
                placeholder="Min"
                class="w-full pl-8 pr-3 py-1 rounded-lg border border-gray-200 dark:border-gray-700/80 bg-white/60 dark:bg-gray-800/60 focus:ring-1 focus:ring-emerald-400"
                @change="applyPriceFilter"
              />
            </div>
            <div class="relative flex-1">
              <span
                class="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-500"
                >৳</span
              >
              <input
                v-model="maxPrice"
                type="number"
                placeholder="Max"
                class="w-full pl-8 pr-3 py-1 rounded-lg border border-gray-200 dark:border-gray-700/80 bg-white/60 dark:bg-gray-800/60 focus:ring-1 focus:ring-emerald-400"
                @change="applyPriceFilter"
              />
            </div>
            <UButton
              color="emerald"
              variant="soft"
              @click="applyPriceFilter"
              class="whitespace-nowrap px-4"
            >
              Apply
            </UButton>
          </div>
        </div>
      </div>

      <!-- Elegant Filter Container -->
      <div
        class="bg-white/70 dark:bg-gray-800/40 backdrop-blur-[2px] rounded-xl px-2 py-2 border border-gray-100 dark:border-gray-700/50 shadow-sm"
      >
        <div class="grid grid-cols-1 lg:grid-cols-5 gap-6">
          <!-- Categories Column -->
          <div class="lg:col-span-3">
            <h3
              class="text-base font-medium mb-3 text-gray-700 dark:text-gray-300 flex items-center"
            >
              <UIcon
                name="i-heroicons-squares-2x2"
                class="mr-2 size-4 text-emerald-500"
              />
              Categories
            </h3>

            <!-- Horizontal scrollable categories -->
            <div
              class="overflow-x-auto py-2 px-1 flex flex-nowrap gap-2 hide-scrollbar"
            >
              <div class="flex gap-2">
                <UBadge
                  v-for="category in categories"
                  :key="category.id"
                  :color="
                    selectedCategory === category.id ? 'emerald' : 'gray'
                  "
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
          <span class="text-sm text-gray-600 dark:text-gray-400 font-medium"
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
              class="w-full h-full rounded-full border-4 border-emerald-100 dark:border-emerald-800/20"
            ></div>
            <div
              class="w-full h-full rounded-full border-4 border-t-emerald-500 animate-spin absolute top-0 left-0"
            ></div>
          </div>
          <p class="text-center text-gray-500 mt-6 font-medium">
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
            class="size-12 text-gray-300 dark:text-gray-600"
          />
        </div>
        <h3 class="mt-6 text-xl font-medium text-gray-900 dark:text-gray-100">
          No products found
        </h3>
        <p class="mt-2 text-gray-500 dark:text-gray-400 max-w-md mx-auto">
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
          'grid gap-x-4 gap-y-8 sm:gap-6': true,
          'grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5':
            viewMode === 'grid',
          'grid-cols-1 gap-y-4': viewMode === 'list',
        }"
        class="relative z-0"
      >
        <div
          v-for="product in products?.results"
          :key="product.id"
          class="premium-product-card group"
        >
          <CommonProductCard :product="product" />
        </div>
      </div>

      <!-- Enhanced Pagination -->
      <div class="mt-14 mb-8 flex justify-center">
        <UPagination
          v-model="currentPage"
          :total="totalProducts"
          :page-count="5"
          :items-per-page="itemsPerPage"
          :ui="{
            wrapper: 'flex items-center gap-1',
            base: 'rounded-lg transition-colors flex items-center justify-center',
            default: {
              size: 'size-10',
              inactive:
                'bg-white dark:bg-gray-800 text-gray-500 hover:text-gray-900 dark:hover:text-white border border-gray-200 dark:border-gray-700',
              active:
                'bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800/30 text-emerald-600 dark:text-emerald-400 font-semibold',
            },
          }"
          @change="handlePageChange"
        />
      </div>
    </UContainer>
  </div>
</template>

<script setup>
import { CommonHotDealsSection } from "#components";
import { ref, computed, watch, onMounted, onUnmounted } from "vue";
const { get } = useApi();
const products = ref({});
const categories = ref([]);
const isLoading = ref(true);
const toast = useToast();
const viewMode = ref("grid");

// Pagination
const currentPage = ref(1);
const itemsPerPage = ref(20); // 4 rows of 5 products in grid view
const totalProducts = ref(0);

// Banner state
const currentSlide = ref(0);
const intervalId = ref(null);
const banners = ref([]);

async function getBanner() {
  try {
    const res = await get("/shop-banner-images/");
    banners.value = res.data;
  } catch (error) {
    console.error("Error fetching banners:", error);
    toast.add({
      title: "Error loading banners",
      description: "Could not load banners. Please try again later.",
      color: "red",
      timeout: 3000,
    });
  }
}
await getBanner();

// Filter state
const searchQuery = ref("");
const selectedCategory = ref(null);
const minPrice = ref("");
const maxPrice = ref("");
const isSidebarOpen = ref(false);

// Sidebar state
const displayedCategories = ref([]);
const hasMoreCategoriesToLoad = ref(false);

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

// Get category icon by name
function getCategoryIcon(categoryName) {
  // Example mapping of category names to icons
  const iconMapping = {
    Electronics: "i-heroicons-device-mobile",
    Fashion: "i-heroicons-tshirt",
    Home: "i-heroicons-home",
    Beauty: "i-heroicons-sparkles",
    Sports: "i-heroicons-football",
  };
  return iconMapping[categoryName] || "i-heroicons-tag";
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

// Banner slider functions
function nextSlide() {
  currentSlide.value = (currentSlide.value + 1) % banners.value.length;
  resetSliderInterval();
}

function prevSlide() {
  currentSlide.value =
    (currentSlide.value - 1 + banners.value.length) % banners.value.length;
  resetSliderInterval();
}

function goToSlide(index) {
  currentSlide.value = index;
  resetSliderInterval();
}

function startSliderInterval() {
  intervalId.value = setInterval(() => {
    nextSlide();
  }, 5000);
}

function resetSliderInterval() {
  clearInterval(intervalId.value);
  startSliderInterval();
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
  // Example implementation for loading more categories
  try {
    const res = await get("/product-categories/", { params: { offset: displayedCategories.value.length } });
    displayedCategories.value.push(...res.data);
    hasMoreCategoriesToLoad.value = res.data.length > 0;
  } catch (error) {
    console.error("Error loading more categories:", error);
    toast.add({
      title: "Error loading categories",
      description: "Could not load more categories. Please try again later.",
      color: "red",
      timeout: 3000,
    });
  }
}

// Seller registration function
function goToSellerRegistration() {
  // Navigate to seller registration page
  navigateTo('/seller/register');
  toggleSidebar();
}

// Customer support contact function
function contactSupport(type) {
  if (type === 'chat') {
    // Open live chat support
    toast.add({
      title: "Live Chat",
      description: "Connecting you with a customer support agent...",
      color: "blue",
      timeout: 3000,
    });
    // Here you would typically initialize your chat widget
  } else if (type === 'email') {
    // Open email support form or redirect to contact page
    navigateTo('/contact-us');
    toggleSidebar();
  }
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

// Initialize data
await Promise.all([fetchCategories(), fetchProducts()]);
onMounted(async () => {
  startSliderInterval();
});

// Clean up slider interval
onUnmounted(() => {
  clearInterval(intervalId.value);
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

/* Sidebar slide animation */
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s ease;
}

.slide-enter-from,
.slide-leave-to {
  transform: translateX(-100%);
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
  @apply px-2 py-0.5 bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs font-medium rounded-full border border-red-100 dark:border-red-800/40;
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
