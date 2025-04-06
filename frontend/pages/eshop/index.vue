<template>
  <div
    class="bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800/90 min-h-screen pb-16"
  >
    <!-- Premium Header Section -->
    <div
      class="relative bg-gradient-to-r from-slate-900/5 to-primary-500/5 dark:from-slate-800/30 dark:to-primary-900/30 z-50"
    >
      <!-- Background Elements -->
      <div class="absolute inset-0 z-0">
        <div
          class="absolute top-0 right-0 w-64 h-64 bg-primary-500/10 rounded-full blur-3xl transform -translate-y-1/2 translate-x-1/3"
        ></div>
        <div
          class="absolute bottom-0 left-0 w-64 h-64 bg-blue-500/10 rounded-full blur-3xl transform translate-y-1/2 -translate-x-1/3"
        ></div>
      </div>

      <UContainer class="relative z-10 pt-8 pb-6">
        <!-- Shop Title -->
        <div class="text-center mb-8">
          <h1
            class="relative inline-block text-3xl md:text-4xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-slate-800 to-slate-900 dark:from-white dark:to-slate-200 mb-2"
          >
            <span
              class="text-transparent bg-clip-text bg-gradient-to-r from-primary-600 to-blue-600 dark:from-primary-500 dark:to-blue-400"
              >Adsy eShop</span
            >
          </h1>
          <p class="text-slate-600 dark:text-slate-400 max-w-xl mx-auto">
            Discover premium products with exceptional quality and prices
          </p>
        </div>

        <!-- Search & Filter Bar -->
        <div
          class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-4 shadow-sm mb-6 relative z-20"
        >
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <!-- Search Bar -->
            <div class="relative md:col-span-2">
              <div
                class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
              >
                <UIcon
                  name="i-heroicons-magnifying-glass"
                  class="h-5 w-5 text-slate-400"
                />
              </div>
              <input
                v-model="searchTerm"
                type="text"
                class="block w-full pl-10 pr-3 py-2.5 bg-slate-50 dark:bg-slate-700/50 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-600 dark:text-slate-300 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500/20 transition duration-200"
                placeholder="Search products..."
              />
              <button
                v-if="searchTerm"
                @click="searchTerm = ''"
                class="absolute inset-y-0 right-0 pr-3 flex items-center"
              >
                <UIcon
                  name="i-heroicons-x-mark"
                  class="h-5 w-5 text-slate-400 hover:text-primary-500 transition-colors"
                />
              </button>
            </div>

            <!-- Categories Dropdown -->
            <div class="relative z-30 dropdown-container">
              <button
                @click="toggleDropdown"
                class="relative w-full flex items-center justify-between bg-slate-50 dark:bg-slate-700/50 border border-slate-200 dark:border-slate-700 rounded-lg px-3 py-2.5 text-slate-600 dark:text-slate-300 hover:bg-white dark:hover:bg-slate-700 transition-colors"
                :class="{
                  'ring-2 ring-primary-500/30 border-primary-500/20': isOpen,
                }"
              >
                <div class="flex items-center">
                  <div
                    class="w-7 h-7 rounded-lg bg-primary-50 dark:bg-primary-900/30 flex items-center justify-center text-primary-600 dark:text-primary-400 mr-2"
                  >
                    <UIcon
                      :name="
                        selectedCategory?.icon || 'i-heroicons-squares-2x2'
                      "
                      class="w-4 h-4"
                    />
                  </div>
                  <span>{{ selectedCategory?.name || "All Categories" }}</span>
                </div>
                <UIcon
                  name="i-heroicons-chevron-down"
                  class="h-5 w-5 text-slate-400 transition-transform duration-200"
                  :class="{ 'rotate-180': isOpen }"
                />
              </button>

              <!-- Dropdown Menu -->
              <transition
                enter-active-class="transition ease-out duration-200"
                enter-from-class="opacity-0 -translate-y-4"
                enter-to-class="opacity-100 translate-y-0"
                leave-active-class="transition ease-in duration-150"
                leave-from-class="opacity-100 translate-y-0"
                leave-to-class="opacity-0 -translate-y-4"
              >
                <div
                  v-if="isOpen"
                  class="absolute z-30 w-full mt-2 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg overflow-hidden"
                  @click.stop
                >
                  <!-- Search Categories -->
                  <div
                    class="p-2 border-b border-slate-200 dark:border-slate-700"
                  >
                    <div class="relative">
                      <UIcon
                        name="i-heroicons-magnifying-glass"
                        class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400"
                      />
                      <input
                        v-model="searchQuery"
                        type="text"
                        class="w-full focus:outline-none pl-10 pr-3 py-2 text-sm bg-slate-50 dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-lg"
                        placeholder="Search categories..."
                        @click.stop
                        ref="searchInput"
                      />
                    </div>
                  </div>

                  <!-- Categories List -->
                  <div class="max-h-60 overflow-y-auto z-40">
                    <!-- All Categories Option -->
                    <div
                      class="px-3 py-2 hover:bg-slate-50 dark:hover:bg-slate-700/50 cursor-pointer flex items-center"
                      :class="{
                        'bg-primary-50 dark:bg-primary-900/20':
                          !selectedCategory,
                      }"
                      @click="selectCategory(null)"
                    >
                      <div
                        class="w-8 h-8 rounded-lg bg-slate-100 dark:bg-slate-700 flex items-center justify-center mr-3"
                      >
                        <UIcon
                          name="i-heroicons-squares-2x2"
                          class="h-4 w-4 text-slate-500 dark:text-slate-400"
                        />
                      </div>
                      <div>
                        <div class="font-medium text-slate-800 dark:text-white">
                          All Categories
                        </div>
                        <div class="text-xs text-slate-500">
                          {{ totalProductCount }} products
                        </div>
                      </div>
                    </div>

                    <!-- Category Items -->
                    <div
                      v-for="category in filteredCategories"
                      :key="category.id"
                      class="px-3 py-2 hover:bg-slate-50 dark:hover:bg-slate-700/50 cursor-pointer flex items-center"
                      :class="{
                        'bg-primary-50 dark:bg-primary-900/20':
                          selectedCategory?.id === category.id,
                      }"
                      @click="selectCategory(category)"
                    >
                      <div
                        class="w-8 h-8 rounded-lg bg-slate-100 dark:bg-slate-700 flex items-center justify-center mr-3"
                      >
                        <UIcon
                          :name="category.icon"
                          class="h-4 w-4 text-slate-500 dark:text-slate-400"
                        />
                      </div>
                      <div>
                        <div class="font-medium text-slate-800 dark:text-white">
                          {{ category.name }}
                        </div>
                        <div class="text-xs text-slate-500">
                          {{ category.count }} products
                        </div>
                      </div>
                    </div>

                    <!-- Empty State -->
                    <div
                      v-if="filteredCategories.length === 0"
                      class="px-3 py-6 text-center text-slate-500 dark:text-slate-400"
                    >
                      No categories found
                    </div>
                  </div>
                </div>
              </transition>
            </div>

            <!-- age -->
          </div>

          <!-- Advanced Filters Panel (Expandable) -->
          <!-- pore -->
        </div>

        <!-- Results Header -->
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <h2 class="text-xl font-medium text-slate-800 dark:text-white">
              {{ selectedCategory ? selectedCategory.name : "All Products" }}
            </h2>
            <UBadge color="gray" variant="soft" size="sm">
              {{ filteredProducts.length }} items
            </UBadge>
          </div>
          <!-- <div class="hidden md:flex items-center space-x-2">
            <span class="text-sm text-slate-500">View:</span>
            <div class="flex p-1 bg-slate-100 dark:bg-slate-800 rounded-lg">
              <button
                @click="viewMode = 'grid'"
                class="p-1 rounded transition"
                :class="
                  viewMode === 'grid'
                    ? 'bg-white dark:bg-slate-700 shadow-sm'
                    : 'text-slate-500'
                "
              >
                <UIcon name="i-heroicons-squares-2x2" class="w-4 h-4" />
              </button>
              <button
                @click="viewMode = 'list'"
                class="p-1 rounded transition"
                :class="
                  viewMode === 'list'
                    ? 'bg-white dark:bg-slate-700 shadow-sm'
                    : 'text-slate-500'
                "
              >
                <UIcon name="i-heroicons-bars-3" class="w-4 h-4" />
              </button>
            </div>
          </div> -->
        </div>
      </UContainer>
    </div>

    <UContainer>
      <!-- Product Grid with Infinity Scroll - KEEPING THE SAME DESIGN -->
      <div
        :class="{
          'grid gap-4': true,
          'grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5':
            viewMode === 'grid',
          'grid-cols-1': viewMode === 'list',
        }"
        class="relative z-0 pt-8"
      >
        <div
          v-for="(product, index) in displayedProducts"
          :key="product.id"
          class="product-card relative group"
          :style="{ animationDelay: `${index * 50}ms` }"
          :class="{ 'animate-fade-up': isNewlyLoaded(index) }"
        >
          <!-- Product Card Content -->
          <div
            class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300 h-full flex flex-col"
          >
            <!-- Single Product Image Section with All Features -->
            <div class="relative pt-[100%] overflow-hidden group">
              <!-- Product Badges -->
              <div
                class="absolute top-0 left-0 right-0 z-10 p-2 flex justify-between"
              >
                <div
                  v-if="product.discount"
                  class="px-1.5 py-0.5 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs font-medium rounded-full"
                >
                  -{{ product.discount }}%
                </div>
                <div
                  class="absolute top-2 right-2 z-20 bg-gradient-to-r from-emerald-500 to-teal-500 text-white text-xs font-semibold px-2 py-0.5 rounded-md shadow-sm"
                >
                  <span>Sold {{ Math.floor(Math.random() * 20) + 1 }}</span>
                </div>
              </div>

              <!-- Product Image -->
              <img
                :src="product.image"
                :alt="product.name"
                class="absolute inset-0 w-full h-full object-cover object-center transition-transform duration-700 ease-out group-hover:scale-105"
              />

              <!-- Hover Elements -->
              <div
                class="absolute inset-0 bg-black/0 group-hover:bg-black/20 flex items-center justify-center transition-all duration-300 opacity-0 group-hover:opacity-100"
              >
                <button
                  @click.prevent="openReviewModal(product)"
                  class="px-3 py-1.5 bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm text-sm font-medium text-slate-800 dark:text-white rounded-lg border border-slate-200/50 dark:border-slate-700/50 shadow-sm transform transition-all hover:scale-105"
                >
                  Quick View
                </button>
              </div>
            </div>

            <!-- Product Details -->
            <div class="p-3 flex-grow flex flex-col">
              <!-- Title -->
              <h3
                class="font-medium text-slate-800 dark:text-white mb-1.5 line-clamp-2 text-sm flex-grow"
              >
                {{ product.name }}
              </h3>

              <!-- Rating -->
              <div class="flex items-center gap-1 mb-1.5">
                <div class="flex">
                  <UIcon
                    v-for="n in 5"
                    :key="n"
                    :name="
                      n <= Math.floor(product.rating)
                        ? 'i-heroicons-star-solid'
                        : 'i-heroicons-star'
                    "
                    class="w-3.5 h-3.5"
                    :class="
                      n <= Math.floor(product.rating)
                        ? 'text-yellow-400'
                        : 'text-gray-200'
                    "
                  />
                </div>
                <span class="text-xs text-slate-500 dark:text-slate-400"
                  >({{ product.reviews.length }})</span
                >
              </div>

              <!-- Price -->
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-2 mb-2">
                  <span class="font-semibold text-slate-800 dark:text-white"
                    >৳{{ product.price }}</span
                  >
                  <span
                    v-if="product.oldPrice"
                    class="text-xs text-slate-400 line-through"
                    >৳{{ product.oldPrice }}</span
                  >
                </div>
                <UButton
                  size="sm"
                  color="primary"
                  icon="i-material-symbols-light-garden-cart-outline"
                  @click="openReviewModal(product)"
                  :trailing="false"
                  class="rounded-full"
                >
                  Buy
                </UButton>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State (No Products) -->
      <div
        v-if="filteredProducts.length === 0 && !isLoading"
        class="py-16 flex flex-col items-center justify-center text-center bg-slate-50 dark:bg-slate-800/50 rounded-xl mt-4"
      >
        <div
          class="w-20 h-20 bg-slate-100 dark:bg-slate-700 rounded-full flex items-center justify-center mb-4"
        >
          <UIcon
            name="i-heroicons-magnifying-glass"
            class="w-10 h-10 text-slate-400 dark:text-slate-500"
          />
        </div>
        <h3 class="text-lg font-medium text-slate-800 dark:text-white mb-2">
          No products found
        </h3>
        <p class="text-slate-500 dark:text-slate-400 max-w-md">
          We couldn't find any products matching your criteria. Try adjusting
          your filters or search term.
        </p>
        <UButton
          color="primary"
          variant="soft"
          class="mt-4"
          @click="resetAllFilters"
        >
          Reset All Filters
        </UButton>
      </div>

      <!-- Loading & End Indicators -->
      <div
        ref="loadMoreTrigger"
        class="py-8 flex flex-col items-center justify-center"
      >
        <div v-if="isLoading" class="flex flex-col items-center">
          <div class="w-10 h-10 relative">
            <div
              class="w-10 h-10 rounded-full border-2 border-primary-300 dark:border-primary-700 opacity-20"
            ></div>
            <div
              class="w-10 h-10 rounded-full border-t-2 border-l-2 border-primary-500 absolute inset-0 animate-spin"
            ></div>
          </div>
          <p class="text-slate-500 dark:text-slate-400 mt-3">
            Loading more products...
          </p>
        </div>

        <div
          v-else-if="hasMoreProducts === false && filteredProducts.length > 0"
          class="text-center py-6"
        >
          <div
            class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gradient-to-br from-primary-50 to-blue-50 dark:from-primary-900/30 dark:to-blue-900/30 mb-3"
          >
            <UIcon
              name="i-heroicons-check-circle"
              class="w-8 h-8 text-primary-500"
            />
          </div>
          <p class="text-slate-600 dark:text-slate-300 font-medium">
            You've seen all products
          </p>
          <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Check back soon for more amazing items
          </p>
          <UButton
            color="gray"
            variant="soft"
            size="sm"
            class="mt-3"
            @click="scrollToTop"
          >
            <UIcon name="i-heroicons-arrow-up" class="w-4 h-4 mr-1.5" />
            Back to Top
          </UButton>
        </div>
      </div>
    </UContainer>

    <!-- Product Review Modal (keep as is) -->
    <UModal v-model="isModalOpen" :ui="{ width: 'w-full max-w-4xl' }">
      <!-- Modal content (keeping the same) -->
    </UModal>
  </div>
</template>

<script setup>
import {
  ref,
  computed,
  onMounted,
  onBeforeUnmount,
  nextTick,
  watch,
} from "vue";

const { get } = useApi();

// Category filtering
const isOpen = ref(false);
const searchQuery = ref("");
const selectedCategory = ref(null);
const searchInput = ref(null);
const searchTerm = ref("");
const viewMode = ref("grid"); // 'grid' or 'list'
const showAdvancedFilters = ref(false);

// Advanced filtering
const priceRange = ref([0, 10000]);
const minRating = ref(0);
const inStockOnly = ref(false);
const sortOption = ref("Newest First");

// Sort options
const sortOptions = [
  { label: "Newest First", icon: "i-heroicons-sparkles" },
  { label: "Price: Low to High", icon: "i-heroicons-arrow-up" },
  { label: "Price: High to Low", icon: "i-heroicons-arrow-down" },
  { label: "Popular", icon: "i-heroicons-fire" },
  { label: "Best Rated", icon: "i-heroicons-star" },
];

// Check if any filters are active
const hasActiveFilters = computed(() => {
  return (
    selectedCategory.value !== null ||
    searchTerm.value !== "" ||
    priceRange.value[0] > 0 ||
    priceRange.value[1] < 10000 ||
    minRating.value > 0 ||
    inStockOnly.value
  );
});

// Reset filters
function resetAllFilters() {
  selectedCategory.value = null;
  searchTerm.value = "";
  resetPriceRange();
  minRating.value = 0;
  inStockOnly.value = false;
}

function resetPriceRange() {
  priceRange.value = [0, 10000];
}

// Update sort option
const updateSortOption = (option) => {
  sortOption.value = option.label;
  sortProducts();
};

// Enhanced categories for the dropdown
const categories = ref([
  {
    id: 1,
    name: "Electronics",
    icon: "i-heroicons-device-phone-mobile",
    count: 42,
  },
  { id: 2, name: "Clothing", icon: "i-heroicons-shirt", count: 38 },
  { id: 3, name: "Home & Kitchen", icon: "i-heroicons-home", count: 24 },
  { id: 4, name: "Books", icon: "i-heroicons-book-open", count: 18 },
  { id: 5, name: "Sports", icon: "i-heroicons-trophy", count: 15 },
  { id: 6, name: "Beauty", icon: "i-heroicons-sparkles", count: 27 },
  { id: 7, name: "Toys", icon: "i-heroicons-puzzle-piece", count: 19 },
  { id: 8, name: "Automotive", icon: "i-heroicons-truck", count: 23 },
]);

// Calculate total product count
const totalProductCount = computed(() => {
  return categories.value.reduce(
    (total, category) => total + category.count,
    0
  );
});

// Filter categories based on search query
const filteredCategories = computed(() => {
  if (!searchQuery.value) return categories.value;
  return categories.value.filter((category) =>
    category.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

// Category dropdown functions
function toggleDropdown(event) {
  // Prevent event propagation
  event.stopPropagation();
  isOpen.value = !isOpen.value;
  if (isOpen.value && searchInput.value) {
    nextTick(() => {
      searchInput.value.focus();
    });
  }
}

function selectCategory(category) {
  selectedCategory.value = category;
  isOpen.value = false;
}

// Initialize sample product data
const initialProducts = ref([
  {
    id: 1,
    name: "Wireless Bluetooth Earbuds with Noise Cancellation",
    price: "2,499",
    oldPrice: "3,200",
    discount: 22,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Earbuds",
    rating: 4.5,
    reviews: Array(12).fill({}),
    category: "Electronics",
    inStock: true,
  },
  {
    id: 2,
    name: "Premium Smart Watch with Heart Rate Monitor",
    price: "4,999",
    oldPrice: "5,500",
    discount: 10,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Watch",
    rating: 4.8,
    reviews: Array(28).fill({}),
    category: "Electronics",
    inStock: true,
  },
  {
    id: 3,
    name: "Cotton Casual T-Shirt for Men",
    price: "999",
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=T-Shirt",
    rating: 4.2,
    reviews: Array(42).fill({}),
    category: "Clothing",
    inStock: true,
  },
  {
    id: 4,
    name: "Stainless Steel Water Bottle 750ml",
    price: "899",
    oldPrice: "1,200",
    discount: 25,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Bottle",
    rating: 4.7,
    reviews: Array(19).fill({}),
    category: "Home & Kitchen",
    inStock: false,
  },
  {
    id: 5,
    name: "Modern Desk Lamp with Adjustable Brightness",
    price: "1,599",
    oldPrice: "1,999",
    discount: 20,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Lamp",
    rating: 4.3,
    reviews: Array(15).fill({}),
    category: "Home & Kitchen",
    inStock: true,
  },
  {
    id: 6,
    name: "Professional Chef Knife Set with Case",
    price: "3,299",
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Knives",
    rating: 4.9,
    reviews: Array(31).fill({}),
    category: "Home & Kitchen",
    inStock: true,
  },
  {
    id: 7,
    name: "Wireless Gaming Mouse with RGB Lighting",
    price: "1,999",
    oldPrice: "2,499",
    discount: 20,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Mouse",
    rating: 4.6,
    reviews: Array(47).fill({}),
    category: "Electronics",
    inStock: true,
  },
  {
    id: 8,
    name: "Leather Wallet with RFID Protection",
    price: "1,299",
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Wallet",
    rating: 4.4,
    reviews: Array(22).fill({}),
    category: "Clothing",
    inStock: false,
  },
]);

// async function fetchAllProducts() {
//   const { data } = await get("/products/");
//   initialProducts.value = data;
// }

// Infinity scroll implementation
const currentPage = ref(0);
const isLoading = ref(false);
const hasMoreProducts = ref(true);
const loadMoreTrigger = ref(null);
const perPage = ref(10); // Products per page
const allLoadedProducts = ref([]);
const lastLoadedIndex = ref(-1);
const isModalOpen = ref(false);
const currentProduct = ref(null);

// Generate more products for infinite scroll
const generateMoreProducts = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      // Generate more products based on existing ones
      const newProducts = [];
      for (let i = 0; i < perPage.value; i++) {
        const templateProduct =
          initialProducts.value[
            Math.floor(Math.random() * initialProducts.value.length)
          ];
        const newProduct = {
          ...JSON.parse(JSON.stringify(templateProduct)),
          id: allLoadedProducts.value.length + i + 1 + Math.random(),
          name: `${templateProduct.name} ${
            currentPage.value * perPage.value + i + 1
          }`,
          price: (
            parseFloat(templateProduct.price.replace(/,/g, "")) +
            Math.floor(Math.random() * 500)
          ).toLocaleString(),
          inStock: Math.random() > 0.2, // 80% chance of being in stock
        };
        newProducts.push(newProduct);
      }

      // If we've generated more than 50 products total, indicate we've reached the end
      if (allLoadedProducts.value.length + newProducts.length > 40) {
        hasMoreProducts.value = false;
      }

      resolve(newProducts);
    }, 1000); // Simulate network delay
  });
};

// Load the first batch of products
const loadInitialProducts = async () => {
  allLoadedProducts.value = [...initialProducts.value];
  currentPage.value = 1;

  // If we have less than perPage products, load more immediately
  if (allLoadedProducts.value.length < perPage.value) {
    await loadMoreProducts();
  }
};

// Load more products when user scrolls to bottom
const loadMoreProducts = async () => {
  if (isLoading.value || !hasMoreProducts.value) return;

  isLoading.value = true;
  lastLoadedIndex.value = allLoadedProducts.value.length - 1;

  try {
    const newProducts = await generateMoreProducts();
    await new Promise((r) => setTimeout(r, 300));
    allLoadedProducts.value = [...allLoadedProducts.value, ...newProducts];
    currentPage.value++;
  } catch (error) {
    console.error("Error loading more products:", error);
  } finally {
    isLoading.value = false;
  }
};

// Apply all filters and sorting
const filteredProducts = computed(() => {
  let filtered = [...allLoadedProducts.value];

  // Category filter
  if (selectedCategory?.value) {
    filtered = filtered.filter(
      (p) => p.category === selectedCategory.value.name
    );
  }

  // Search term filter
  if (searchTerm.value) {
    const term = searchTerm.value.toLowerCase();
    filtered = filtered.filter(
      (p) =>
        p.name.toLowerCase().includes(term) ||
        p.category.toLowerCase().includes(term)
    );
  }

  // Price range filter
  filtered = filtered.filter((p) => {
    const price = parseFloat(p.price.replace(/,/g, ""));
    return price >= priceRange.value[0] && price <= priceRange.value[1];
  });

  // Rating filter
  if (minRating.value > 0) {
    filtered = filtered.filter((p) => p.rating >= minRating.value);
  }

  // Stock filter
  if (inStockOnly.value) {
    filtered = filtered.filter((p) => p.inStock);
  }

  // Sort products
  sortProductsArray(filtered);

  return filtered;
});

// Pagination for display
const displayedProducts = computed(() => {
  return filteredProducts.value;
});

// Sort function
function sortProductsArray(products) {
  switch (sortOption.value) {
    case "Price: Low to High":
      products.sort((a, b) => {
        return (
          parseFloat(a.price.replace(/,/g, "")) -
          parseFloat(b.price.replace(/,/g, ""))
        );
      });
      break;
    case "Price: High to Low":
      products.sort((a, b) => {
        return (
          parseFloat(b.price.replace(/,/g, "")) -
          parseFloat(a.price.replace(/,/g, ""))
        );
      });
      break;
    case "Best Rated":
      products.sort((a, b) => b.rating - a.rating);
      break;
    case "Popular":
      products.sort((a, b) => b.reviews.length - a.reviews.length);
      break;
    // Newest First is default
    default:
      // Already sorted by default
      break;
  }
}

function sortProducts() {
  // This triggers reactivity to resort products
  const temp = [...allLoadedProducts.value];
  sortProductsArray(temp);
  allLoadedProducts.value = temp;
}

// Check if a product was just loaded (for animation)
const isNewlyLoaded = (index) => {
  return index > lastLoadedIndex.value;
};

// Open product modal
function openReviewModal(product) {
  currentProduct.value = product;
  isModalOpen.value = true;
}

// Scroll to top function
function scrollToTop() {
  window.scrollTo({ top: 0, behavior: "smooth" });
}

// Set up intersection observer for infinite scrolling
onMounted(async () => {
  // Load initial products
  await loadInitialProducts();

  // Set up the intersection observer
  const observer = new IntersectionObserver(
    (entries) => {
      if (
        entries[0].isIntersecting &&
        !isLoading.value &&
        hasMoreProducts.value
      ) {
        loadMoreProducts();
      }
    },
    { threshold: 0.1 }
  );

  if (loadMoreTrigger.value) {
    observer.observe(loadMoreTrigger.value);
  }

  // Close dropdown when clicking outside
  document.addEventListener("click", (e) => {
    if (isOpen.value && !e.target.closest(".dropdown-container")) {
      isOpen.value = false;
    }
  });

  // Clean up the observer when component is destroyed
  onBeforeUnmount(() => {
    if (loadMoreTrigger.value) {
      observer.unobserve(loadMoreTrigger.value);
    }

    // Remove the click event listener when component is unmounted
    document.removeEventListener("click", (e) => {
      if (isOpen.value && !e.target.closest(".dropdown-container")) {
        isOpen.value = false;
      }
    });
  });
});

// Watch for filter changes to reset products
watch([selectedCategory, searchTerm, inStockOnly, minRating], async () => {
  // Reset pagination but keep loaded products
  currentPage.value = 1;

  // If we have very few filtered products, load more
  if (
    filteredProducts.value.length < 10 &&
    hasMoreProducts.value &&
    !isLoading.value
  ) {
    await loadMoreProducts();
  }
});

// Add this function to count active filters
function getActiveFiltersCount() {
  let count = 0;
  if (selectedCategory) count++;
  if (priceRange[0] > 0 || priceRange[1] < 10000) count++;
  if (minRating > 0) count++;
  if (inStockOnly) count++;
  return count;
}
</script>

<style>
/* Animation for newly loaded products */
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

/* Product card hover effect */
.product-card:hover {
  transform: translateY(-4px);
  transition: transform 0.3s ease-out;
}

/* Badge styles */
.badge-discount {
  @apply px-1.5 py-0.5 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs font-medium rounded-full;
}
</style>
