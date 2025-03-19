<template>
  <UContainer>
    <!-- Category Header Section -->
    <div class="mt-10 mb-8">
      <div
        class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4"
      >
        <h2 class="text-2xl md:text-3xl font-medium flex items-center gap-2">
          <div class="p-1.5 rounded bg-primary/10 text-primary">
            <UIcon name="i-heroicons-squares-2x2" class="w-6 h-6"></UIcon>
          </div>
          Shop by Category
          <UBadge
            color="primary"
            variant="subtle"
            class="ml-2 text-xs font-medium"
          >
            {{ totalProductCount }} Products
          </UBadge>
        </h2>

        <!-- Category Dropdown -->
        <div class="relative z-40 w-full md:w-auto max-w-xl">
          <div
            class="flex items-center justify-between p-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg shadow-sm hover:shadow-md cursor-pointer transition-all duration-200"
            :class="{ 'ring-1 ring-primary/40 border-primary/30': isOpen }"
            @click="toggleDropdown"
          >
            <div class="flex items-center gap-2">
              <UIcon
                :name="selectedCategory?.icon || 'i-heroicons-squares-2x2'"
                class="w-5 h-5"
              />
              <span class="font-medium">{{
                selectedCategory?.name || "All Categories"
              }}</span>
              <UBadge
                v-if="selectedCategory"
                size="xs"
                color="primary"
                class="ml-1"
              >
                {{ selectedCategory.count }}
              </UBadge>
            </div>
            <UIcon
              name="i-heroicons-chevron-down"
              class="w-5 h-5 transition-transform duration-300"
              :class="{ 'rotate-180': isOpen }"
            />
          </div>

          <!-- Dropdown Content (same as original) -->
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
              class="absolute w-full mt-1.5 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg shadow-lg overflow-hidden"
            >
              <!-- Search Bar -->
              <div
                class="relative flex items-center p-3 border-b border-slate-200 dark:border-slate-700"
              >
                <UIcon
                  name="i-heroicons-magnifying-glass"
                  class="absolute left-5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400"
                />
                <input
                  v-model="searchQuery"
                  type="text"
                  placeholder="Search categories..."
                  class="w-full py-2 pl-8 pr-8 bg-slate-50 dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary/50 transition-all"
                  @click.stop
                  ref="searchInput"
                />
                <UButton
                  v-if="searchQuery"
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-x-mark"
                  size="xs"
                  class="absolute right-5 top-1/2 -translate-y-1/2"
                  @click.stop="searchQuery = ''"
                />
              </div>

              <!-- Categories List -->
              <div class="max-h-[400px] overflow-y-auto p-2">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-1">
                  <!-- All Categories Option -->
                  <div
                    class="p-2.5 rounded-md cursor-pointer transition-colors duration-150 hover:bg-slate-50 dark:hover:bg-slate-700"
                    :class="{ 'bg-primary/10 text-primary': !selectedCategory }"
                    @click.stop="selectCategory(null)"
                  >
                    <div class="flex items-center gap-2">
                      <div
                        class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-slate-100 dark:bg-slate-700"
                      >
                        <UIcon name="i-heroicons-squares-2x2" class="w-4 h-4" />
                      </div>
                      <div class="flex-1">
                        <span class="font-medium">All Categories</span>
                      </div>
                      <UBadge color="primary" variant="subtle" size="xs">
                        {{ totalProductCount }}
                      </UBadge>
                    </div>
                  </div>

                  <!-- Category Items -->
                  <div
                    v-for="category in filteredCategories"
                    :key="category.id"
                    class="p-2.5 rounded-md cursor-pointer transition-colors duration-150 hover:bg-slate-50 dark:hover:bg-slate-700"
                    :class="{
                      'bg-primary/10 text-primary':
                        selectedCategory?.id === category.id,
                    }"
                    @click.stop="selectCategory(category)"
                  >
                    <div class="flex items-center gap-2">
                      <div
                        class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-slate-100 dark:bg-slate-700"
                      >
                        <UIcon :name="category.icon" class="w-4 h-4" />
                      </div>
                      <div class="flex-1">
                        <span class="font-medium">{{ category.name }}</span>
                      </div>
                      <UBadge color="gray" size="xs">
                        {{ category.count }}
                      </UBadge>
                    </div>
                  </div>
                </div>

                <!-- Empty State -->
                <div
                  v-if="filteredCategories.length === 0"
                  class="py-8 flex flex-col items-center justify-center text-center"
                >
                  <UIcon
                    name="i-heroicons-magnifying-glass"
                    class="w-10 h-10 text-slate-300 dark:text-slate-600"
                  />
                  <p class="mt-2 text-slate-500 dark:text-slate-400">
                    No categories match "{{ searchQuery }}"
                  </p>
                </div>
              </div>
            </div>
          </transition>
        </div>
      </div>
    </div>

    <!-- NEW: Products Grid with Infinity Scroll -->
    <div class="mb-16">
      <!-- Filter & Sort Options -->
      <div
        class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 gap-4"
      >
        <!-- Active Filter Tags -->
        <div class="flex flex-wrap gap-2">
          <UBadge
            v-if="selectedCategory"
            color="primary"
            variant="soft"
            size="md"
            class="flex items-center gap-1"
          >
            <UIcon :name="selectedCategory.icon" class="w-3.5 h-3.5" />
            {{ selectedCategory.name }}
            <button
              @click="selectCategory(null)"
              class="ml-1 hover:bg-primary-100 dark:hover:bg-primary-800 p-0.5 rounded-full"
            >
              <UIcon name="i-heroicons-x-mark" class="w-3 h-3" />
            </button>
          </UBadge>

          <UBadge
            v-if="!selectedCategory"
            color="gray"
            variant="soft"
            size="md"
          >
            All Products
          </UBadge>
        </div>

        <!-- Sort Dropdown -->
        <div class="relative">
          <UDropdown
            :items="[
              { label: 'Newest First', icon: 'i-heroicons-sparkles' },
              { label: 'Price: Low to High', icon: 'i-heroicons-arrow-up' },
              { label: 'Price: High to Low', icon: 'i-heroicons-arrow-down' },
              { label: 'Popular', icon: 'i-heroicons-fire' },
              { label: 'Best Rated', icon: 'i-heroicons-star' },
            ]"
          >
            <UButton
              color="gray"
              variant="soft"
              trailing-icon="i-heroicons-chevron-down-20-solid"
            >
              <UIcon
                name="i-heroicons-adjustments-horizontal"
                class="mr-1 w-4 h-4"
              />
              Sort: {{ sortOption }}
            </UButton>
          </UDropdown>
        </div>
      </div>

      <!-- Product Grid with Animation -->
      <div
        class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4"
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

      <!-- Loading & End Indicators -->
      <div
        ref="loadMoreTrigger"
        class="py-8 flex flex-col items-center justify-center"
      >
        <div v-if="isLoading" class="flex flex-col items-center">
          <div
            class="w-10 h-10 border-4 border-primary/30 border-t-primary rounded-full animate-spin mb-3"
          ></div>
          <p class="text-slate-500 dark:text-slate-400">
            Loading more products...
          </p>
        </div>

        <div v-else-if="hasMoreProducts === false" class="text-center py-6">
          <div
            class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-800 mb-3"
          >
            <UIcon
              name="i-heroicons-check-circle"
              class="w-8 h-8 text-primary"
            />
          </div>
          <p class="text-slate-600 dark:text-slate-300 font-medium">
            You've seen all products
          </p>
          <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Check back soon for more items
          </p>
        </div>
      </div>
    </div>

    <!-- Product Review Modal (keep as is) -->
    <UModal v-model="isModalOpen" :ui="{ width: 'w-full max-w-4xl' }">
      <!-- Modal content (keep the same) -->
    </UModal>
  </UContainer>
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

// Category filtering (keep the original code)
const isOpen = ref(false);
const searchQuery = ref("");
const selectedCategory = ref(null);
const searchInput = ref(null);

// Mock categories for the dropdown
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
function toggleDropdown() {
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

// Initialize sample product data instead of referencing undefined products
const initialProducts = ref([
  {
    id: 1,
    name: "Wireless Bluetooth Earbuds",
    price: "2,499",
    oldPrice: "3,200",
    discount: 22,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Earbuds",
    rating: 4.5,
    reviews: Array(12).fill({}),
    category: "Electronics",
  },
  {
    id: 2,
    name: "Premium Smart Watch",
    price: "4,999",
    oldPrice: "5,500",
    discount: 10,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Watch",
    rating: 4.8,
    reviews: Array(28).fill({}),
    category: "Electronics",
  },
  {
    id: 3,
    name: "Cotton Casual T-Shirt",
    price: "999",
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=T-Shirt",
    rating: 4.2,
    reviews: Array(42).fill({}),
    category: "Clothing",
  },
  {
    id: 4,
    name: "Stainless Steel Water Bottle",
    price: "899",
    oldPrice: "1,200",
    discount: 25,
    image: "https://placehold.co/300x300/f1f5f9/64748b?text=Bottle",
    rating: 4.7,
    reviews: Array(19).fill({}),
    category: "Home & Kitchen",
  },
]);

// NEW: Infinite scroll implementation
const currentPage = ref(0);
const isLoading = ref(false);
const hasMoreProducts = ref(true);
const loadMoreTrigger = ref(null);
const perPage = ref(8); // Products per page
const allLoadedProducts = ref([]);
const lastLoadedIndex = ref(-1);
const sortOption = ref("Newest First");
const isModalOpen = ref(false);
const currentProduct = ref(null);

// Generate more products for infinite scroll demo
const generateMoreProducts = () => {
  // This simulates an API call that would fetch more products
  return new Promise((resolve) => {
    setTimeout(() => {
      // Generate more products based on the existing product templates
      const newProducts = [];
      for (let i = 0; i < perPage.value; i++) {
        // Clone a random product from the original set and give it a new ID
        const templateProduct =
          initialProducts.value[
            Math.floor(Math.random() * initialProducts.value.length)
          ];
        const newProduct = {
          ...JSON.parse(JSON.stringify(templateProduct)),
          id: allLoadedProducts.value.length + i + 1 + Math.random(), // Ensure unique ID
          name: `${templateProduct.name} ${
            currentPage.value * perPage.value + i + 1
          }`,
          price: (
            parseFloat(templateProduct.price.replace(/,/g, "")) +
            Math.floor(Math.random() * 500)
          ).toLocaleString(),
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
  // Start with the initial products instead of a non-existent variable
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

    // Wait a small delay before adding products for nicer animation
    await new Promise((r) => setTimeout(r, 300));

    allLoadedProducts.value = [...allLoadedProducts.value, ...newProducts];
    currentPage.value++;
  } catch (error) {
    console.error("Error loading more products:", error);
  } finally {
    isLoading.value = false;
  }
};

// Filtered and displayed products based on category
const displayedProducts = computed(() => {
  if (!selectedCategory.value) {
    return allLoadedProducts.value;
  }
  return allLoadedProducts.value.filter(
    (product) => product.category === selectedCategory.value.name
  );
});

// Check if a product was just loaded (for animation)
const isNewlyLoaded = (index) => {
  return index > lastLoadedIndex.value;
};

// Open product modal
function openReviewModal(product) {
  currentProduct.value = product;
  isModalOpen.value = true;
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

  // Clean up the observer when component is destroyed
  onBeforeUnmount(() => {
    if (loadMoreTrigger.value) {
      observer.unobserve(loadMoreTrigger.value);
    }
  });
});

// Watch for category changes to reset products
watch(selectedCategory, async () => {
  // Reset and reload products when category changes
  currentPage.value = 0;
  allLoadedProducts.value = [];
  hasMoreProducts.value = true;
  lastLoadedIndex.value = -1;

  await loadInitialProducts();
});

// Close dropdown when clicking outside
onMounted(() => {
  document.addEventListener("click", (e) => {
    if (isOpen.value) {
      isOpen.value = false;
    }
  });
});
</script>

<style>
/* Keep only the necessary styles, remove carousel-specific styles */

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

.animate-fade-up {
  animation: fadeUp 0.5s ease-out forwards;
}

/* Rest of your styles for product cards, badges, etc. */
</style>
