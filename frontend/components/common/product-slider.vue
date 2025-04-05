<template>
  <UContainer class="relative py-2">
    <!-- Header with Premium Styling -->
    <div class="flex items-center justify-between mt-3 mb-3">
      <div class="flex items-center gap-2">
        <div
          class="p-1.5 rounded bg-gradient-to-r from-primary-50 to-primary-100 dark:from-primary-900/20 dark:to-primary-800/30 text-primary relative overflow-hidden"
        >
          <!-- Shimmer effect -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 dark:via-white/10 to-transparent -translate-x-full animate-shimmer"
          ></div>
          <UIcon
            name="i-heroicons-shopping-bag"
            class="w-5 h-5 relative z-10"
          />
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
        to="/shop-manager"
        class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 md:hover:bg-gradient-to-r md:hover:from-primary-50 md:hover:to-blue-50 dark:hover:from-primary-900/20 dark:hover:to-blue-900/20 transition-all duration-300 text-sm font-medium group"
      >
        <span>Sell On eShop</span>
        <UIcon
          name="i-heroicons-arrow-right"
          class="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform"
        />
      </NuxtLink>
    </div>

    <!-- Product Carousel Section -->
    <div v-if="isLoading" class="flex justify-center py-8">
      <!-- Premium Loading Animation -->
      <div class="relative">
        <div
          class="w-10 h-10 rounded-full border-2 border-primary-200 dark:border-primary-800/50 opacity-30"
        ></div>
        <div
          class="w-10 h-10 rounded-full border-t-2 border-primary-600 dark:border-primary-400 animate-spin absolute top-0"
        ></div>
      </div>
    </div>

    <div v-else-if="productsCount > 0" class="relative overflow-hidden">
      <!-- Navigation Arrows with Premium Styling -->
      <button
        @click="
          nextSlide();
          pauseAutoSlide();
          setTimeout(resumeAutoSlide, 2000);
        "
        class="absolute -left-3 md:-left-5 top-1/2 -translate-y-1/2 z-10 w-9 h-9 flex items-center justify-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full shadow-md hover:shadow-lg transition-all duration-200 hover:scale-105"
        :class="{
          'opacity-50 cursor-not-allowed': currentSlide === 0,
        }"
        :disabled="currentSlide === 0"
      >
        <UIcon
          name="i-heroicons-chevron-left"
          class="w-5 h-5 text-slate-600 dark:text-slate-300"
        />
      </button>

      <button
        @click="
          prevSlide();
          pauseAutoSlide();
          setTimeout(resumeAutoSlide, 2000);
        "
        class="absolute -right-3 md:-right-5 top-1/2 -translate-y-1/2 z-10 w-9 h-9 flex items-center justify-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full shadow-md hover:shadow-lg transition-all duration-200 hover:scale-105"
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

      <!-- Two-Row Carousel with RTL direction -->
      <div
        class="overflow-hidden rounded-lg bg-white/30 dark:bg-slate-800/30 backdrop-blur-sm"
        @mouseenter="pauseAutoSlide"
        @mouseleave="resumeAutoSlide"
      >
        <div
          class="rtl-slider transition-transform duration-500 ease-out"
          :style="{ transform: `translateX(${currentSlide * 100}%)` }"
        >
          <div v-for="i in maxSlides" :key="i" class="slider-page">
            <!-- First row -->
            <div
              class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2 mb-2"
            >
              <CommonProductCard
                v-for="product in getProductsForRow(i - 1, 0)"
                :key="product.id"
                :product="product"
                @open-modal="openProductModal"
                class="transition-transform hover:-translate-y-1 hover:shadow-md duration-300"
              />
            </div>

            <!-- Second row -->
            <div
              class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2"
            >
              <CommonProductCard
                v-for="product in getProductsForRow(i - 1, 1)"
                :key="product.id"
                :product="product"
                @open-modal="openProductModal"
                class="transition-transform hover:-translate-y-1 hover:shadow-md duration-300"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Premium Dot Indicators -->
      <div class="flex justify-center gap-1.5 mt-4">
        <button
          v-for="i in maxSlides"
          :key="i"
          @click="
            goToSlide(i - 1);
            pauseAutoSlide();
            setTimeout(resumeAutoSlide, 2000);
          "
          class="w-2 h-2 rounded-full transition-all duration-200 hover:scale-110"
          :class="
            currentSlide === i - 1
              ? 'bg-primary w-6'
              : 'bg-slate-300 dark:bg-slate-600'
          "
        ></button>
      </div>

      <!-- Progress Bar -->
      <div
        class="w-full max-w-[250px] mx-auto mt-2 h-0.5 bg-slate-200 dark:bg-slate-700 overflow-hidden rounded-full"
      >
        <div
          class="h-full bg-primary transition-all duration-300 rounded-full"
          :class="{ 'progress-animation': !isPaused }"
          :style="{
            animation: isPaused
              ? 'none'
              : `progress-animation ${autoSlideDelay}ms linear infinite`,
          }"
        ></div>
      </div>

      <!-- Bottom "All Products" button (styled like category load more) -->
      <div class="text-center mt-5 mb-2">
        <NuxtLink
          to="/eshop"
          class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 shadow-sm hover:shadow-md transition-all duration-300 relative overflow-hidden group"
        >
          <!-- Premium shine effect -->
          <div
            class="absolute inset-0 w-1/2 bg-gradient-to-r from-transparent via-white/30 dark:via-white/10 to-transparent -translate-x-full group-hover:translate-x-[200%] transition-all duration-1000"
          ></div>
          <span class="font-medium text-slate-800 dark:text-white"
            >All Products</span
          >
          <UIcon
            name="i-heroicons-arrow-long-right"
            class="w-4 h-4 text-primary group-hover:translate-x-1 transition-transform"
          />
        </NuxtLink>
      </div>
    </div>

    <div
      v-else
      class="py-10 flex flex-col items-center justify-center text-center bg-slate-50 dark:bg-slate-800/50 rounded-lg"
    >
      <div
        class="w-16 h-16 bg-slate-100 dark:bg-slate-700 rounded-full flex items-center justify-center mb-4 relative overflow-hidden"
      >
        <div
          class="absolute inset-0 bg-gradient-to-r from-transparent via-slate-200/20 to-transparent animate-shimmer"
        ></div>
        <UIcon name="i-heroicons-shopping-bag" class="w-8 h-8 text-slate-400" />
      </div>
      <h3 class="text-lg font-medium text-slate-800 dark:text-white mb-2">
        No products available
      </h3>
      <UButton
        @click="fetchProducts"
        class="mt-3"
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
const itemsPerRow = ref(5); // Items per row
const isModalOpen = ref(false);
const selectedProduct = ref(null);
const quantity = ref(1);

// Add these new refs for controlling auto-sliding
const autoSlideInterval = ref(null);
const autoSlideDelay = 5000; // 5 seconds between slides
const isPaused = ref(false);

// Computed values for the two-row layout
const itemsPerSlide = computed(() => itemsPerRow.value * 2); // Double because we have 2 rows

// Debug settings
const debugMode = ref(false);
const debugData = ref(null);

// Fetch products from API with better error handling
async function fetchProducts() {
  isLoading.value = true;

  try {
    const response = await get("/products/");
    console.log("API Response:", response);

    if (response && response.data) {
      debugData.value = response.data;

      if (Array.isArray(response.data)) {
        products.value = response.data;
      } else if (
        response.data.results &&
        Array.isArray(response.data.results)
      ) {
        products.value = response.data.results;
      } else if (typeof response.data === "object") {
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

// Update responsive items per row based on screen size
function updateItemsPerRow() {
  if (window.innerWidth < 640) {
    itemsPerRow.value = 2; // Mobile: 2 items per row
  } else if (window.innerWidth < 768) {
    itemsPerRow.value = 3; // Small tablet: 3 items per row
  } else if (window.innerWidth < 1024) {
    itemsPerRow.value = 4; // Large tablet: 4 items per row
  } else {
    itemsPerRow.value = 5; // Desktop: 5 items per row
  }
}

// New function to get products for a specific row in a slide
function getProductsForRow(slideIndex, rowIndex) {
  if (!products.value || !products.value.length) {
    return [];
  }

  const itemsPerSlideTotal = itemsPerRow.value * 2; // Total items per slide (2 rows)
  const startIndexInSlide = slideIndex * itemsPerSlideTotal;
  const startIndexInRow = startIndexInSlide + rowIndex * itemsPerRow.value;
  const endIndexInRow = startIndexInRow + itemsPerRow.value;

  return products.value.slice(startIndexInRow, endIndexInRow);
}

// Carousel navigation - Note the direction change for RTL
function prevSlide() {
  if (currentSlide.value < maxSlides.value - 1) {
    currentSlide.value++;
  }
}

function nextSlide() {
  if (currentSlide.value > 0) {
    currentSlide.value--;
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

// Start automatic sliding
function startAutoSlide() {
  if (autoSlideInterval.value) clearInterval(autoSlideInterval.value);

  autoSlideInterval.value = setInterval(() => {
    if (!isPaused.value && maxSlides.value > 1) {
      // For RTL direction - increment means going left (next)
      if (currentSlide.value < maxSlides.value - 1) {
        currentSlide.value++;
      } else {
        // Reset to first slide when reaching the end
        currentSlide.value = 0;
      }
    }
  }, autoSlideDelay);
}

// Pause automatic sliding (for user interaction)
function pauseAutoSlide() {
  isPaused.value = true;
}

// Resume automatic sliding
function resumeAutoSlide() {
  isPaused.value = false;
}

// Auto-slide functionality
let autoSlideTimer = null;

function pauseAutoSlideLegacy() {
  if (autoSlideTimer) {
    clearInterval(autoSlideTimer);
    autoSlideTimer = null;
  }
}

function resumeAutoSlideLegacy() {
  pauseAutoSlideLegacy();
  autoSlideTimer = setInterval(() => {
    if (currentSlide.value < maxSlides.value - 1) {
      currentSlide.value++;
    } else {
      currentSlide.value = 0;
    }
  }, 5000);
}

// Lifecycle hooks
onMounted(() => {
  fetchProducts();
  updateItemsPerRow();
  window.addEventListener("resize", updateItemsPerRow);

  // Start auto-sliding after mounting
  startAutoSlide();
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", updateItemsPerRow);

  // Clear interval when component is destroyed
  if (autoSlideInterval.value) clearInterval(autoSlideInterval.value);
});

// Watch for products change to restart auto-slide
watch(
  () => products.value,
  () => {
    if (products.value.length > 0) {
      startAutoSlide();
    }
  }
);
</script>

<style scoped>
/* RTL slider layout */
.rtl-slider {
  display: flex;
  direction: rtl;
}

.slider-page {
  min-width: 100%;
  direction: ltr; /* Reset direction for content */
}

@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 2s infinite;
}
@keyframes progress-animation {
  0% {
    width: 0%;
  }
  100% {
    width: 100%;
  }
}

.progress-animation {
  animation: progress-animation var(--auto-slide-delay, 5000ms) linear infinite;
  animation-play-state: running;
}
</style>
