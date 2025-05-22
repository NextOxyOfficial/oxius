<template>
  <div
    class="bg-gradient-to-b from-slate-50 via-white to-slate-50 dark:from-slate-900 dark:via-slate-900/95 dark:to-slate-800/90 min-h-screen pb-20"
  >
    <!-- Premium Banner Slider with Enhanced Visual Effects -->
    <div class="pt-4 pb-2 mb-2">
      <UContainer>
        <div
          class="relative overflow-hidden rounded-xl shadow-sm touch-slider"
          ref="sliderContainer"
          @mouseenter="handleSliderHover(true)"
          @mouseleave="handleSliderHover(false)"
          @touchstart="handleTouchStart"
          @touchmove="handleTouchMove"
          @touchend="handleTouchEnd"
        >
          <!-- Background pattern for premium look -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-slate-900/5 to-slate-900/5 dark:from-slate-950/20 dark:to-slate-950/10 backdrop-blur-[1px] z-0"
          ></div>

          <!-- Mobile swipe indicator shown only on mobile -->
          <div
            class="md:hidden absolute top-1/2 left-0 right-0 -translate-y-1/2 flex justify-between px-3 z-20 opacity-60 pointer-events-none"
          >
            <div class="swipe-indicator swipe-indicator-left">
              <ChevronLeft class="h-8 w-8 text-white" />
            </div>
            <div class="swipe-indicator swipe-indicator-right">
              <ChevronRight class="h-8 w-8 text-white" />
            </div>
          </div>
          <!-- Aspect ratio container for rounded and consistent height - matching hero banner -->
          <div
            class="rounded-xl overflow-hidden relative pb-[38%] md:pb-[25%] lg:pb-[22%]"
          >
            <div
              v-for="(banner, index) in banners"
              :key="index"
              class="absolute inset-0 transition-all duration-500 ease-out transform"
              :class="{
                'opacity-100 translate-x-0': index === currentSlide,
                'opacity-0 translate-x-full': index > currentSlide,
                'opacity-0 -translate-x-full': index < currentSlide,
              }"
            >
              <!-- Gradient overlay -->
              <div
                class="absolute inset-0 bg-gradient-to-r from-black/40 to-black/20 z-10"
              ></div>
              <img
                v-if="banner.image"
                :src="banner.image"
                :alt="banner.title || `Slide ${index + 1}`"
                class="w-full h-full object-contain"
              />
            </div>
          </div>

          <!-- Navigation arrows - hidden on mobile but visible on desktop on hover -->
          <button
            @click="prevSlide"
            class="hidden md:flex absolute left-3 top-1/2 -translate-y-1/2 bg-gradient-to-r from-emerald-600/80 to-blue-600/80 backdrop-blur-sm hover:from-emerald-600/90 hover:to-blue-600/90 rounded-full p-2 sm:p-3 z-20 transition-all duration-300 shadow-sm opacity-0 transform -translate-x-2"
            :class="{ 'opacity-100 translate-x-0': isHovering }"
            aria-label="Previous slide"
          >
            <ChevronLeft class="h-5 w-5 text-white" />
          </button>

          <button
            @click="nextSlide"
            class="hidden md:flex absolute right-3 top-1/2 -translate-y-1/2 bg-gradient-to-r from-emerald-600/80 to-blue-600/80 backdrop-blur-sm hover:from-emerald-600/90 hover:to-blue-600/90 rounded-full p-2 sm:p-3 z-20 transition-all duration-300 shadow-sm opacity-0 transform translate-x-2"
            :class="{ 'opacity-100 translate-x-0': isHovering }"
            aria-label="Next slide"
          >
            <ChevronRight class="h-5 w-5 text-white" />
          </button>

          <!-- Slider indicators -->
          <div
            class="absolute bottom-4 left-1/2 -translate-x-1/2 flex space-x-3 z-20 bg-black/20 backdrop-blur-md px-3 py-1.5 rounded-full"
          >
            <button
              v-for="(_, index) in banners"
              :key="index"
              @click="goToSlide(index)"
              class="w-2.5 h-2.5 rounded-full transition-all duration-300 relative"
              :class="{
                'bg-white scale-110': index === currentSlide,
                'bg-white/40 hover:bg-white/60': index !== currentSlide,
              }"
              :aria-label="`Go to slide ${index + 1}`"
            ></button>
          </div>
        </div>
      </UContainer>
    </div>

    <UContainer>
      <!-- Categories Sidebar -->
      <transition name="slide">
        <div
          v-if="isSidebarOpen"
          class="fixed top-0 left-0 h-full z-40 bg-white dark:bg-gray-900 shadow-sm border-r border-gray-200 dark:border-gray-700 w-80 overflow-hidden flex flex-col"
        >
          <div class="pt-safe sticky top-0 z-10">
            <div
              class="p-4 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between bg-white/95 dark:bg-gray-900/95 backdrop-blur-md mt-[60px] sm:mt-0"
            >
              <h2
                class="text-lg font-semibold text-gray-700 dark:text-gray-300 flex items-center"
              >
                <UIcon
                  name="i-heroicons-circle-stack"
                  class="mr-2.5 size-5 text-emerald-500"
                />
                Categories
              </h2>
              <button
                @click="toggleSidebar"
                class="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-600"
              >
                <UIcon name="i-heroicons-x-mark" class="size-5" />
              </button>
            </div>
          </div>

          <div class="overflow-y-auto flex-1 py-4 px-4">
            <!-- Featured Categories Section -->
            <div class="mb-4">
              <p
                class="text-xs font-medium uppercase tracking-wider text-gray-600 dark:text-gray-600 mb-3 ml-1"
              >
                BROWSE CATEGORIES
              </p>
              <ul class="space-y-0.5">
                <li v-for="category in displayedCategories" :key="category.id">
                  <button
                    @click="selectCategoryAndCloseSidebar(category.id)"
                    class="w-full text-left px-4 py-3 rounded-lg flex items-center gap-3.5 transition-all"
                    :class="
                      selectedCategory === category.id
                        ? 'bg-emerald-200 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 font-medium'
                        : 'hover:bg-gray-100 dark:hover:bg-gray-800/60 text-gray-700 dark:text-gray-400'
                    "
                  >
                    <div
                      class="flex-shrink-0 size-8 flex items-center justify-center rounded-md bg-gray-100 dark:bg-gray-800"
                    >
                      <UIcon
                        :name="getCategoryIcon(category.name)"
                        class="size-4.5"
                        :class="
                          selectedCategory === category.id
                            ? 'text-emerald-500'
                            : 'text-gray-600 dark:text-gray-600'
                        "
                      />
                    </div>
                    <span class="truncate font-medium">{{
                      category.name
                    }}</span>
                    <div
                      v-if="selectedCategory === category.id"
                      class="ml-auto flex-shrink-0 size-2 rounded-full bg-emerald-500"
                    ></div>
                  </button>
                </li>
              </ul>

              <div
                v-if="hasMoreCategoriesToLoad"
                class="pt-4 pb-2 flex justify-center"
              >
                <UButton
                  @click="loadMoreCategories"
                  color="gray"
                  variant="soft"
                  size="sm"
                  class="w-full"
                >
                  <UIcon name="i-heroicons-arrow-down" class="size-4 mr-1" />
                  Load more categories
                </UButton>
              </div>
            </div>

            <!-- Divider -->
            <div
              class="border-t border-gray-200 dark:border-gray-700/60 my-6"
            ></div>

            <!-- Sell on eShop Section - Enhanced Design -->
            <div class="relative overflow-hidden rounded-xl shadow-sm group">
              <!-- Gradient background with pattern -->
              <div
                class="absolute inset-0 bg-gradient-to-br from-emerald-500/90 via-emerald-600 to-emerald-700 opacity-90"
              ></div>
              <!-- Background pattern -->
              <div
                class="absolute inset-0 opacity-10 bg-[radial-gradient(circle_at_1px_1px,white_1px,transparent_0)]"
                style="background-size: 10px 10px"
              ></div>

              <div class="relative p-5 text-white">
                <div class="flex items-start">
                  <div
                    class="bg-white/20 backdrop-blur-sm p-2.5 rounded-lg mr-3"
                  >
                    <UIcon name="i-heroicons-shopping-bag" class="size-6" />
                  </div>
                  <div>
                    <h3 class="font-semibold text-lg text-white">
                      Become a Seller
                    </h3>
                    <p class="text-sm mt-1.5 text-white/90 leading-relaxed">
                      Start selling your products in our marketplace and reach
                      thousands of customers.
                    </p>
                  </div>
                </div>

                <UButton
                  color="white"
                  variant="solid"
                  size="md"
                  class="mt-4 w-full font-medium shadow-sm group-hover:shadow-sm transition-all"
                  @click="goToSellerRegistration"
                >
                  <UIcon
                    name="i-heroicons-arrow-right"
                    class="mr-1.5 size-4 transition-transform group-hover:translate-x-0.5"
                  />
                  Start Selling Today
                </UButton>
              </div>
            </div>

            <!-- Customer Support Section -->
            <div
              class="mt-5 rounded-xl bg-white dark:bg-gray-800/70 border border-gray-100 dark:border-gray-700/50 shadow-sm p-4"
            >
              <h3
                class="font-medium text-gray-700 dark:text-gray-300 flex items-center"
              >
                <UIcon
                  name="i-heroicons-chat-bubble-left-right"
                  class="mr-2 size-5 text-blue-500"
                />
                Customer Support
              </h3>
              <p class="text-sm mt-2 text-gray-600 dark:text-gray-400">
                Our team is here to help you with any questions about your
                orders or products.
              </p>
              <div class="mt-3 flex gap-2">
                <UButton
                  color="blue"
                  variant="soft"
                  size="sm"
                  class="flex-1"
                  @click="contactSupport('chat')"
                >
                  <UIcon
                    name="i-heroicons-chat-bubble-oval-left"
                    class="mr-1.5"
                  />
                  Live Chat
                </UButton>
                <UButton
                  color="gray"
                  variant="outline"
                  size="sm"
                  class="flex-1"
                  @click="contactSupport('email')"
                >
                  <UIcon name="i-heroicons-envelope" class="mr-1.5" />
                  Email
                </UButton>
              </div>
            </div>

            <!-- eShop Manager Button -->
            <div class="mt-6 mb-20">
              <UButton
                color="indigo"
                variant="solid"
                class="w-full group py-3 font-medium"
                @click="navigateToEshopManager"
              >
                <div class="flex items-center justify-center">
                  <UIcon
                    name="i-heroicons-building-storefront"
                    class="size-5 mr-2"
                  />
                  eShop Manager
                </div>
              </UButton>
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
                class="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-600 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
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
              class="text-base px-2 font-medium text-gray-700 dark:text-gray-400 flex items-center lg:whitespace-nowrap"
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
              class="text-base font-medium mb-3 text-gray-700 dark:text-gray-400 flex items-center"
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
        <h3 class="mt-6 text-xl font-medium text-gray-700 dark:text-gray-200">
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
import { ref, computed, watch, onMounted, onUnmounted } from "vue";
import { ChevronLeft, ChevronRight } from "lucide-vue-next";
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

// Banner state
const currentSlide = ref(0);
const intervalId = ref(null);
const banners = ref([]);
const sliderContainer = ref(null);
const isHovering = ref(false);
let touchStartX = 0;
let touchEndX = 0;
let isHandlingTouch = false;

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

function resetSliderInterval() {
  clearInterval(intervalId.value);
  startSliderInterval();
}

function startSliderInterval() {
  intervalId.value = setInterval(() => {
    if (!isHandlingTouch) {
      nextSlide();
    }
  }, 5000);
}

// Touch event handlers
function handleTouchStart(e) {
  isHandlingTouch = true;
  touchStartX = e.touches[0].clientX;
}

function handleTouchMove(e) {
  if (!isHandlingTouch) return;
  touchEndX = e.touches[0].clientX;

  // Add visual feedback during swiping
  const swipeDiff = touchEndX - touchStartX;
  if (Math.abs(swipeDiff) > 30) {
    e.preventDefault(); // Prevent default only if significant swipe detected

    // Add visual feedback with classes
    if (sliderContainer.value) {
      sliderContainer.value.classList.remove("swiping-left", "swiping-right");
      if (swipeDiff > 0) {
        sliderContainer.value.classList.add("swiping-right");
      } else {
        sliderContainer.value.classList.add("swiping-left");
      }
    }
  }
}

function handleTouchEnd() {
  if (!isHandlingTouch) return;

  const swipeDiff = touchEndX - touchStartX;
  const minSwipeDistance = 50; // Minimum distance to consider it a swipe

  if (swipeDiff > minSwipeDistance) {
    prevSlide(); // Swipe right = previous slide
  } else if (swipeDiff < -minSwipeDistance) {
    nextSlide(); // Swipe left = next slide
  }

  // Remove swiping classes
  if (sliderContainer.value) {
    sliderContainer.value.classList.remove("swiping-left", "swiping-right");
  }

  isHandlingTouch = false;
  resetSliderInterval();
}

// Handle slider hover
function handleSliderHover(isHover) {
  isHovering.value = isHover;
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
    const res = await get("/product-categories/", {
      params: { offset: displayedCategories.value.length },
    });
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
  navigateTo("/eshop-manager");
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
  navigateTo("/eshop-manager");
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
  startSliderInterval();
  initInfiniteScroll();

  // Add touch event listeners for banner slider
  if (sliderContainer.value) {
    sliderContainer.value.addEventListener("touchstart", handleTouchStart, {
      passive: false,
    });
    sliderContainer.value.addEventListener("touchmove", handleTouchMove, {
      passive: false,
    });
    sliderContainer.value.addEventListener("touchend", handleTouchEnd);
  }
});

// Clean up slider interval
onUnmounted(() => {
  clearInterval(intervalId.value);

  // Remove touch event listeners
  if (sliderContainer.value) {
    sliderContainer.value.removeEventListener("touchstart", handleTouchStart);
    sliderContainer.value.removeEventListener("touchmove", handleTouchMove);
    sliderContainer.value.removeEventListener("touchend", handleTouchEnd);
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
