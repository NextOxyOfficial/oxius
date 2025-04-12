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
          <div class="grid grid-cols-1 md:grid-cols-3 gap-2 sm:gap-4">
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
        </div>
      </UContainer>
    </div>

    <UContainer>
      <!-- Product Grid with Infinity Scroll - KEEPING THE SAME DESIGN -->
      <div
        :class="{
          'grid gap-2 sm:gap-4': true,
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
          :class="isNewlyLoaded(index) ? 'animate-fade-up' : ''"
        >
          <CommonProductCard :product="product" />
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

const { get } = useApi();
const initialProducts = ref([]);
const isLoading = ref(true);
const toast = useToast();

// Add missing variables for pagination and animation
const currentPage = ref(1);
const lastLoadedIndex = ref(-1); // Track last loaded index for animation
const productsPerPage = ref(15);
const hasMoreProducts = ref(true);
const loadMoreTrigger = ref(null);
const currentProduct = ref(null);
const isModalOpen = ref(false);

// Modified getAllProducts function to preserve all fields
async function getAllProducts() {
  try {
    isLoading.value = true;
    const res = await get("/all-products/");
    console.log("API response:", res);

    // Preserve all original fields instead of mapping to new objects
    initialProducts.value = res.data.map((product) => {
      // Calculate discount only if needed
      const discount = calculateDiscount(
        product.regular_price,
        product.sale_price
      );

      // Return the original product with minimal modifications
      return {
        ...product, // Keep ALL original fields including slug
        // Only add fields that don't exist in the API response
        inStock: product.quantity > 0,
        discount: discount,
      };
    });

    console.log("Processed products:", initialProducts.value);

    // Update lastLoadedIndex after initial products load
    lastLoadedIndex.value = initialProducts.value.length - 1;

    // Set hasMoreProducts based on whether we received all products
    hasMoreProducts.value = res.data.length >= productsPerPage.value;
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error loading products",
      description: "Could not load products. Please try again later.",
      color: "red",
      timeout: 3000,
    });
    initialProducts.value = [];
  } finally {
    isLoading.value = false;
  }
}
await getAllProducts();
// Helper to calculate discount percentage
function calculateDiscount(regular_price, sale_price) {
  if (!sale_price || !regular_price) return null;

  const regular = parseFloat(regular_price);
  const sale = parseFloat(sale_price);

  if (sale >= regular) return null;

  const discount = Math.round((1 - sale / regular) * 100);
  return discount > 0 ? discount : null;
}

// Pagination for display with proper tracking
const displayedProducts = computed(() => {
  // Get filtered products based on current page
  const products = filteredProducts.value;
  const endIndex = currentPage.value * productsPerPage.value;

  // Update last loaded index for animation
  if (endIndex > lastLoadedIndex.value) {
    lastLoadedIndex.value = Math.min(endIndex - 1, products.length - 1);
  }

  return products.slice(0, endIndex);
});

// Check if a product was just loaded (for animation)
const isNewlyLoaded = (index) => {
  // This function now safely uses lastLoadedIndex
  const previousLastLoaded = lastLoadedIndex.value - productsPerPage.value;
  return index > previousLastLoaded;
};

// Track total product count for "All Categories" display
const totalProductCount = computed(() => {
  return initialProducts.value.length;
});

// Load more products (infinite scroll implementation)
const loadMoreProducts = () => {
  if (isLoading.value || !hasMoreProducts.value) return;

  const previousCount = displayedProducts.value.length;
  currentPage.value++;

  // Check if we've loaded all filtered products
  nextTick(() => {
    if (displayedProducts.value.length === filteredProducts.value.length) {
      hasMoreProducts.value = false;
    }

    // If no new products were loaded despite increasing page, we're at the end
    if (displayedProducts.value.length === previousCount) {
      hasMoreProducts.value = false;
    }
  });
};

// Setup intersection observer for infinite scroll
onMounted(() => {
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

  onBeforeUnmount(() => {
    if (loadMoreTrigger.value) {
      observer.unobserve(loadMoreTrigger.value);
    }
  });
});

// For dropdown functionality
function toggleDropdown() {
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    nextTick(() => {
      if (searchInput.value) {
        searchInput.value.focus();
      }
    });
  }
}

// Filter categories based on search
const filteredCategories = computed(() => {
  if (!searchQuery.value) return categories.value;

  return categories.value.filter((category) =>
    category.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

// Select a category
function selectCategory(category) {
  selectedCategory.value = category;
  isOpen.value = false;

  // Reset pagination when category changes
  currentPage.value = 1;
  lastLoadedIndex.value = -1; // Reset for new animations
}

// Extract real categories from products using original API field names
const categories = computed(() => {
  if (!initialProducts.value || initialProducts.value.length === 0) return [];

  const uniqueCategories = [];
  const categoryMap = new Map();

  initialProducts.value.forEach((product) => {
    if (
      product.category_details &&
      !categoryMap.has(product.category_details.id)
    ) {
      categoryMap.set(product.category_details.id, {
        id: product.category_details.id,
        name: product.category_details.name,
        icon: getCategoryIcon(product.category_details.name),
        count: 1,
      });
    } else if (product.category_details) {
      const category = categoryMap.get(product.category_details.id);
      category.count++;
    }
  });

  return Array.from(categoryMap.values());
});

// Map category names to icons
function getCategoryIcon(categoryName) {
  const name = (categoryName || "").toLowerCase();
  const iconMap = {
    electronics: "i-heroicons-device-phone-mobile",
    clothing: "i-heroicons-shirt",
    home: "i-heroicons-home",
    books: "i-heroicons-book-open",
    sports: "i-heroicons-trophy",
    beauty: "i-heroicons-sparkles",
    toys: "i-heroicons-puzzle-piece",
    automotive: "i-heroicons-truck",
    one: "i-heroicons-star", // Your category "ONE"
    two: "i-heroicons-heart", // Example for another category
  };

  // Try to find a matching icon or return default
  for (const key in iconMap) {
    if (name.includes(key)) return iconMap[key];
  }

  return "i-heroicons-squares-2x2"; // Default icon
}

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

// Apply all filters and sorting
const filteredProducts = computed(() => {
  let filtered = [...initialProducts.value];

  // Category filter
  if (selectedCategory?.value) {
    filtered = filtered.filter((p) => p.category === selectedCategory.value.id);
  }

  // Search term filter
  if (searchTerm.value) {
    const term = searchTerm.value.toLowerCase();
    filtered = filtered.filter(
      (p) =>
        p.name.toLowerCase().includes(term) ||
        (p.description && p.description.toLowerCase().includes(term)) ||
        (p.category_details?.name &&
          p.category_details.name.toLowerCase().includes(term))
    );
  }

  // Price range filter - use same field names as API
  filtered = filtered.filter((p) => {
    const price = parseFloat(p.sale_price);
    return price >= priceRange.value[0] && price <= priceRange.value[1];
  });

  // Rating filter
  if (minRating.value > 0) {
    filtered = filtered.filter((p) => (p.rating || 5) >= minRating.value);
  }

  // Stock filter
  if (inStockOnly.value) {
    filtered = filtered.filter((p) => p.quantity > 0);
  }

  // Sort products
  sortProductsArray(filtered);

  return filtered;
});

// Sort function
function sortProductsArray(products) {
  switch (sortOption.value) {
    case "Price: Low to High":
      products.sort(
        (a, b) => parseFloat(a.sale_price) - parseFloat(b.sale_price)
      );
      break;
    case "Price: High to Low":
      products.sort(
        (a, b) => parseFloat(b.sale_price) - parseFloat(a.sale_price)
      );
      break;
    case "Best Rated":
      products.sort((a, b) => (b.rating || 5) - (a.rating || 5));
      break;
    case "Popular":
      products.sort(
        (a, b) => (b.reviews?.length || 0) - (a.reviews?.length || 0)
      );
      break;
    // Newest First is default
    default:
      products.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
      break;
  }
}

function sortProducts() {
  // This triggers reactivity to resort products
  const temp = [...initialProducts.value];
  sortProductsArray(temp);
  initialProducts.value = temp;
}

// Open product modal
function openReviewModal(product) {
  currentProduct.value = product;
  isModalOpen.value = true;
}

// Scroll to top function
function scrollToTop() {
  window.scrollTo({ top: 0, behavior: "smooth" });
}

// Watch for filter changes to reset products
watch([selectedCategory, searchTerm, inStockOnly, minRating], async () => {
  // Reset pagination but keep loaded products
  currentPage.value = 1;
});
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
