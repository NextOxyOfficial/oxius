<template>
  <UContainer>
    <!-- Header -->
    <div class="flex items-center justify-between mt-5 mb-4">
      <div class="flex items-center gap-2">
        <div
          class="p-1.5 rounded bg-gradient-to-r from-primary-50 to-primary-100 dark:from-primary-900/20 dark:to-primary-800/30 text-primary"
        >
          <UIcon name="i-heroicons-shopping-bag" class="w-5 h-5" />
        </div>
        <h2 class="font-bold text-lg md:text-xl text-slate-800 dark:text-white">
          <span class="relative inline-block">
            {{ $t("eshop") }}
            <span
              class="absolute -bottom-0.5 left-0 w-full h-0.5 bg-gradient-to-r from-primary to-primary-400"
            ></span>
          </span>
        </h2>
      </div>

      <NuxtLink
        to="/eshop"
        class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 md:hover:bg-gradient-to-r md:hover:from-primary-50 md:hover:to-blue-50 dark:hover:from-primary-900/20 dark:hover:to-blue-900/20 transition-all duration-300 text-sm font-medium"
      >
        <span>{{ $t("view_all") }}</span>
        <UIcon name="i-heroicons-arrow-right" class="w-3.5 h-3.5" />
      </NuxtLink>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex justify-center py-12">
      <UIcon
        name="i-heroicons-arrow-path"
        class="w-8 h-8 animate-spin text-primary-500"
      />
    </div>

    <!-- Debug Info - Remove in production -->
    <pre
      v-if="debugMode"
      class="text-xs bg-gray-100 dark:bg-gray-800 p-2 rounded mb-4 overflow-auto max-h-40"
    >
      Products Count: {{ productsCount }}
      Raw Data: {{ JSON.stringify(debugData, null, 2) }}
    </pre>

    <!-- Product Carousel Section -->
    <div v-else-if="productsCount > 0" class="relative">
      <!-- Navigation Arrows -->
      <button
        @click="prevSlide"
        class="absolute -left-4 md:-left-6 top-1/2 -translate-y-1/2 z-10 w-10 h-10 flex items-center justify-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full shadow-md md:hover:shadow-lg transition-all duration-200"
        :class="{ 'opacity-50 cursor-not-allowed': currentSlide === 0 }"
        :disabled="currentSlide === 0"
      >
        <UIcon
          name="i-heroicons-chevron-left"
          class="w-5 h-5 text-slate-600 dark:text-slate-300"
        />
      </button>

      <button
        @click="nextSlide"
        class="absolute -right-4 md:-right-6 top-1/2 -translate-y-1/2 z-10 w-10 h-10 flex items-center justify-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full shadow-md md:hover:shadow-lg transition-all duration-200"
        :class="{
          'opacity-50 cursor-not-allowed': currentSlide === maxSlides - 1,
        }"
        :disabled="currentSlide === maxSlides - 1"
      >
        <UIcon
          name="i-heroicons-chevron-right"
          class="w-5 h-5 text-slate-600 dark:text-slate-300"
        />
      </button>

      <!-- Carousel Track -->
      <div class="overflow-hidden rounded-xl">
        <div
          class="flex transition-transform duration-500 ease-out"
          :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
        >
          <div
            v-for="i in maxSlides"
            :key="i"
            class="flex-shrink-0 w-full grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4"
          >
            <div
              v-for="product in getProductsForSlide(i - 1)"
              :key="product.id"
              class="product-card relative group"
            >
              <!-- Product Card Content -->
              <div
                class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl overflow-hidden shadow-sm md:hover:shadow-md transition-all duration-300 h-full flex flex-col"
              >
                <!-- Product Image Section -->
                <div class="relative pt-[100%] overflow-hidden group">
                  <!-- Discount Badge -->
                  <div
                    v-if="product.regular_price"
                    class="absolute top-2 left-2 z-10 px-1.5 py-0.5 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs font-medium rounded-full"
                  >
                    -{{
                      calculateDiscount(
                        product.sale_price,
                        product.regular_price
                      )
                    }}%
                  </div>

                  <!-- Product Image -->
                  <img
                    :src="getProductImage(product)"
                    :alt="product.name"
                    class="absolute inset-0 w-full h-full object-cover object-center transition-transform duration-700 ease-out md:group-hover:scale-105"
                  />

                  <!-- Quick View Button -->
                  <div
                    class="absolute inset-0 bg-black/0 md:group-hover:bg-black/20 flex items-center justify-center transition-all duration-300 opacity-0 md:group-hover:opacity-100"
                  >
                    <UButton
                      @click="openProductModal(product)"
                      class="px-3 py-1.5 bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm text-sm font-medium rounded-lg"
                    >
                      Quick View
                    </UButton>
                  </div>
                </div>

                <!-- Product Details -->
                <div class="p-3 flex-grow flex flex-col">
                  <!-- Product Title -->
                  <NuxtLink :to="`/product-details/${product.id}`">
                    <h3
                      class="font-medium text-slate-800 dark:text-white mb-1 line-clamp-2 flex-grow text-base"
                    >
                      {{ product.name }}
                    </h3>
                  </NuxtLink>
                  <NuxtLink
                    :to="`https://adsyclub.com/eshop/${product?.owner_details?.store_username}`"
                    class="text-blue-400 text-sm mb-1.5 inline-flex items-center gap-1 cursor-pointer"
                  >
                    <UIcon
                      name="i-material-symbols-storefront-outline-rounded"
                      class="size-4"
                    />
                    <span>
                      {{ product?.owner_details?.store_name }}
                    </span>
                  </NuxtLink>
                  <!-- Rating -->
                  <div class="flex items-center gap-1 mb-1.5">
                    <div class="flex">
                      <UIcon
                        v-for="n in 5"
                        :key="n"
                        :name="
                          n <= Math.floor(product.rating || 0)
                            ? 'i-heroicons-star-solid'
                            : 'i-heroicons-star'
                        "
                        class="w-3.5 h-3.5"
                        :class="
                          n <= Math.floor(product.rating || 0)
                            ? 'text-yellow-400'
                            : 'text-gray-200'
                        "
                      />
                    </div>
                    <span class="text-xs text-slate-500 dark:text-slate-400">
                      ({{ product.reviews?.length || 0 }})
                    </span>
                  </div>

                  <!-- Price -->
                  <div class="flex items-center justify-between">
                    <div class="flex flex-col gap-1">
                      <span
                        class="font-semibold text-slate-800 dark:text-white"
                      >
                        ৳{{ product.sale_price }}
                      </span>
                      <span
                        v-if="product.regular_price"
                        class="text-xs text-slate-400 line-through"
                      >
                        ৳{{ product.regular_price }}
                      </span>
                    </div>
                    <UButton
                      size="sm"
                      color="primary"
                      :icon="
                        !loadingStates[product.id]
                          ? 'i-heroicons-shopping-cart'
                          : ''
                      "
                      :trailing="false"
                      class="rounded-full"
                      @click="addToCart(product)"
                      :loading="loadingStates[product.id]"
                      :disabled="loadingStates[product.id]"
                    >
                      {{ !loadingStates[product.id] ? "Buy" : "" }}
                    </UButton>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Dots Navigation -->
      <div class="flex justify-center gap-2 mt-6">
        <button
          v-for="i in maxSlides"
          :key="i"
          @click="goToSlide(i - 1)"
          class="w-2 h-2 rounded-full transition-all duration-200"
          :class="
            currentSlide === i - 1
              ? 'bg-primary w-6'
              : 'bg-slate-300 dark:bg-slate-600'
          "
        ></button>
      </div>
    </div>

    <!-- Empty State -->
    <div
      v-else
      class="py-16 flex flex-col items-center justify-center text-center bg-slate-50 dark:bg-slate-800/50 rounded-xl mt-4"
    >
      <div
        class="w-16 h-16 bg-slate-100 dark:bg-slate-700 rounded-full flex items-center justify-center mb-4"
      >
        <UIcon name="i-heroicons-shopping-bag" class="w-8 h-8 text-slate-400" />
      </div>
      <h3 class="text-lg font-medium text-slate-800 dark:text-white mb-2">
        No products available
      </h3>
      <p class="text-slate-500 dark:text-slate-400 max-w-md">
        Check back soon for our latest products
      </p>

      <!-- Retry Button -->
      <UButton
        @click="fetchProducts"
        class="mt-4"
        color="primary"
        variant="soft"
      >
        <UIcon name="i-heroicons-arrow-path" class="mr-1.5" />
        Refresh
      </UButton>
    </div>

    <!-- Product Quick View Modal -->
    <UModal
      v-model="isModalOpen"
      :ui="{
        inner: 'fixed inset-0 overflow-y-auto rounded-md',
        base: 'relative text-left rtl:text-right flex flex-col -top-12 sm:top-8 rounded-md',
        fullscreen: 'w-full max-w-xl h-[480px] sm:h-[600px]',
      }"
      fullscreen
    >
      <div class="w-full h-full overflow-hidden overflow-y-scroll">
        <CommonProductDetailsCard
          :current-product="selectedProduct"
          :modal="true"
          @close-modal="closeProductModal"
        />
      </div>
    </UModal>
  </UContainer>
</template>

<script setup>
const { get } = useApi();

// Core state
const products = ref([]);
const isLoading = ref(true);
const currentSlide = ref(0);
const itemsPerSlide = ref(5);
const isModalOpen = ref(false);
const selectedProduct = ref(null);
const quantity = ref(1);
const cart = useStoreCart();
const loadingStates = ref({});

// Debug settings
const debugMode = ref(false); // Set to true to enable debugging
const debugData = ref(null);

// Fetch products from API with better error handling
async function fetchProducts() {
  isLoading.value = true;

  try {
    // Fetch from the public products endpoint
    const response = await get("/products/");
    console.log("API Response:", response);

    // Check if response has data
    if (response && response.data) {
      // Store the response in the debug data
      debugData.value = response.data;

      // Handle different API response structures
      if (Array.isArray(response.data)) {
        // Direct array response
        products.value = response.data;
      } else if (
        response.data.results &&
        Array.isArray(response.data.results)
      ) {
        // Paginated response with results array
        products.value = response.data.results;
      } else if (typeof response.data === "object") {
        // Direct object response, convert to array
        products.value = [response.data];
      } else {
        console.error("Unknown API response format:", response.data);
        products.value = [];
      }

      // Reset to first slide when products change
      currentSlide.value = 0;
    } else {
      console.error("No data in API response");
      products.value = [];
    }
  } catch (error) {
    console.error("Error fetching products:", error);
    const toast = useToast();
    toast.add({
      title: "Error loading products",
      description: error.message || "Couldn't load products. Please try again.",
      color: "red",
    });
    products.value = [];
  } finally {
    isLoading.value = false;
  }
}

// Helper computed properties
const productsCount = computed(() => products.value?.length || 0);

const maxSlides = computed(() => {
  if (!productsCount.value) return 0;
  return Math.ceil(productsCount.value / itemsPerSlide.value);
});

// Calculate discount percentage
function calculateDiscount(salePrice, originalPrice) {
  if (!salePrice || !originalPrice) return 0;
  const discount = ((originalPrice - salePrice) / originalPrice) * 100;
  return Math.round(discount);
}

// Update responsive items per slide based on screen size
function updateItemsPerSlide() {
  if (window.innerWidth < 640) {
    itemsPerSlide.value = 2;
  } else if (window.innerWidth < 768) {
    itemsPerSlide.value = 3;
  } else if (window.innerWidth < 1024) {
    itemsPerSlide.value = 4;
  } else {
    itemsPerSlide.value = 5;
  }
}

// Get products for current slide with safer array handling
function getProductsForSlide(slideIndex) {
  if (!products.value || !products.value.length) {
    return [];
  }

  const start = slideIndex * itemsPerSlide.value;
  const end = start + itemsPerSlide.value;
  return products.value.slice(start, end);
}

// Safely get product image with fallback
function getProductImage(product) {
  if (!product) return "/placeholder-image.jpg";

  if (product.image_details) {
    if (
      Array.isArray(product.image_details) &&
      product.image_details.length > 0
    ) {
      return product.image_details[0].image || "/placeholder-image.jpg";
    }
    if (typeof product.image_details === "string") {
      return product.image_details;
    }
  }

  return "/placeholder-image.jpg";
}

// Carousel navigation
function prevSlide() {
  if (currentSlide.value > 0) {
    currentSlide.value--;
  }
}

function nextSlide() {
  if (currentSlide.value < maxSlides.value - 1) {
    currentSlide.value++;
  }
}

function goToSlide(index) {
  currentSlide.value = index;
}

// Product modal
function openProductModal(product) {
  selectedProduct.value = product;
  quantity.value = 1;
  isModalOpen.value = true;
}

function closeProductModal() {
  isModalOpen.value = false;
}

// Cart functionality
function addToCart(product, qty = 1) {
  // Set loading state for this specific product
  loadingStates.value[product.id] = true;

  try {
    // Simulate network delay (remove in production)
    setTimeout(() => {
      cart.addProduct(product, qty);
      navigateTo("/checkout/");

      // Clear loading state if navigation fails
      loadingStates.value[product.id] = false;
    }, 800); // Simulate network latency
  } catch (error) {
    console.error("Error adding to cart:", error);
    const toast = useToast();
    toast.add({
      title: "Network Error",
      description: "Please check your internet connection and try again.",
      color: "red",
    });

    // Clear loading state on error
    loadingStates.value[product.id] = false;
  }
}

// Lifecycle hooks
onMounted(() => {
  fetchProducts();
  updateItemsPerSlide();
  window.addEventListener("resize", updateItemsPerSlide);
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", updateItemsPerSlide);
});
</script>

<style scoped>
/* Minimal styling for core functionality */
.product-card {
  transition: transform 0.3s ease;
}

.product-card:hover {
  transform: translateY(-4px);
}
</style>
