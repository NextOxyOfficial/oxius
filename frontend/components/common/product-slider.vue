<template>
  <UContainer class="relative py-2">
    <!-- Header with Premium Styling -->
    <div class="flex items-center justify-between mt-1 mb-4">
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
            class="w-5 h-5 relative z-10 text-green-500"
          />
        </div>
        <h2 class="font-semibold text-lg md:text-xl text-gray-800 dark:text-white">
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
        <span>{{ $t("sell_on_eshop") }}</span>
        <UIcon
          name="i-heroicons-arrow-right"
          class="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform"
        />
      </NuxtLink>
    </div>

    <CommonCategoryLayout/>

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

    <div v-else-if="productsCount > 0" class="relative product-slider-container">
      <!-- Navigation Arrows with Premium Styling -->
      <button
        @click="scrollSlider('left')"
        class="absolute -left-3 md:-left-5 top-1/2 -translate-y-1/2 z-10 w-9 h-9 flex items-center justify-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full shadow-sm hover:shadow-md transition-all duration-200 hover:scale-105 opacity-0 group-hover:opacity-100"
      >
        <UIcon
          name="i-heroicons-chevron-left"
          class="w-5 h-5 text-gray-600 dark:text-slate-300"
        />
      </button>

      <button
        @click="scrollSlider('right')"
        class="absolute -right-3 md:-right-5 top-1/2 -translate-y-1/2 z-10 w-9 h-9 flex items-center justify-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-full shadow-sm hover:shadow-md transition-all duration-200 hover:scale-105 opacity-0 group-hover:opacity-100"
      >
        <UIcon
          name="i-heroicons-chevron-right"
          class="w-5 h-5 text-gray-600 dark:text-slate-300"
        />
      </button>

      <!-- Smooth Scrollable Product Slider -->
      <div
        ref="sliderContainer"
        class="overflow-x-auto custom-scrollbar rounded-lg bg-white/30 dark:bg-slate-800/30 backdrop-blur-sm select-none scroll-smooth hide-scrollbar"
        @mousedown="handleSliderClick"
        @touchstart="handleSliderTouch"
      >
        <div class="slider-content inline-flex py-3 px-2">
          <!-- First row of products -->
          <div class="product-row">
            <div class="flex gap-2">
              <div
                v-for="product in firstRowProducts"
                :key="product.id"
                class="product-card-wrapper flex-shrink-0"
              >
                <CommonProductCard
                  :product="product"
                  class="product-card"
                />
              </div>
            </div>
          </div>
        </div>
        
        <div class="slider-content inline-flex py-1 px-2 mb-2">
          <!-- Second row of products -->
          <div class="product-row">
            <div class="flex gap-4">
              <div
                v-for="product in secondRowProducts"
                :key="product.id"
                class="product-card-wrapper flex-shrink-0"
              >
                <CommonProductCard
                  :product="product"
                  class="product-card"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Scroll indicator dots -->
      <div class="flex justify-center gap-1.5 mt-3">
        <div
          v-for="(_, i) in scrollPositions"
          :key="i"
          @click="scrollToPosition(i)"
          class="w-2 h-2 rounded-full cursor-pointer transition-all duration-200 hover:scale-110"
          :class="
            currentScrollIndex === i
              ? 'bg-green-500 w-6'
              : 'bg-slate-300 dark:bg-slate-600'
          "
        ></div>
      </div>

      <!-- Bottom "All Products" button -->
      <div class="text-center mt-5 mb-2">
        <NuxtLink
          to="/eshop"
          class="group relative text-sm inline-flex items-center justify-center gap-2 px-4 py-2.5 font-medium text-white bg-gradient-to-r from-emerald-500 to-blue-500 rounded-full overflow-hidden shadow-sm hover:shadow-sm transition-all duration-300 transform hover:scale-105"
        >
          <!-- Premium shine effect -->
          <span
            class="absolute inset-0 w-full h-full bg-gradient-to-r from-emerald-600 to-blue-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
          ></span>
          <span class="relative z-10 font-medium">{{
            $t("all_product")
          }}</span>
          <UIcon
            name="i-heroicons-arrow-long-right"
            class="w-4 h-4 group-hover:translate-x-1 transition-transform"
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
      <h3 class="text-lg font-medium text-gray-800 dark:text-white mb-2">
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
    <!-- <UModal
      v-model="isModalOpen"
      :ui="{
        inner: 'fixed inset-0 overflow-y-auto rounded-md',
        base: 'relative text-left rtl:text-right flex flex-col -top-12 sm:top-8 rounded-md',
        fullscreen: 'w-full max-w-3xl mt-32 sm:mt-12 mb-10 sm:h-[750px]',
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
    </UModal> -->

    <!-- <div
      v-if="isModalOpen"
      class="fixed inset-0 top-14 z-10 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
      >
        <CommonProductDetailsCard
          :current-product="selectedProduct"
          :modal="true"
          @close-modal="closeProductModal"
        />
      </div>
    </div> -->
  </UContainer>
</template>

<script setup>
import { CommonCategoryLayout } from '#components';

const { get } = useApi();

// Core state
const products = ref([]);
const isLoading = ref(true);
const sliderContainer = ref(null);

// Responsive settings
const itemsPerRow = ref(5); // Default for desktop
const productsLimit = 20; // Total products to fetch

// Scroll state
const currentScrollIndex = ref(0);
const scrollInterval = ref(null);
const isScrolling = ref(false);
const clickStartX = ref(0);
const clickStartTime = ref(0);
const isMouseDown = ref(false);

// Debug settings
const debugMode = ref(false);
const debugData = ref(null);

// Computed properties for product display
const productsCount = computed(() => products.value?.length || 0);

const firstRowProducts = computed(() => {
  if (!products.value.length) return [];
  return products.value.slice(0, 10); // First 10 products (half of total)
});

const secondRowProducts = computed(() => {
  if (!products.value.length) return [];
  return products.value.slice(10, 20); // Last 10 products (second half)
});

// Calculate number of scroll positions based on products and visible items
const scrollPositions = computed(() => {
  if (productsCount.value === 0) return [];
  const cardsPerView = getCardsPerView();
  const totalPositions = Math.ceil((productsCount.value / 2) / cardsPerView);
  return Array.from({ length: totalPositions });
});

// Fetch products from API with better error handling and limit
async function fetchProducts() {
  isLoading.value = true;

  try {
    // Add limit parameter to fetch exactly 20 products
    const response = await get(`/all-products/?limit=${productsLimit}`);
    console.log("API Response:", response);

    if (response && response.data) {
      debugData.value = response.data;

      if (Array.isArray(response.data)) {
        products.value = response.data.slice(0, productsLimit);
      } else if (
        response.data.results &&
        Array.isArray(response.data.results)
      ) {
        products.value = response.data.results.slice(0, productsLimit);
      } else if (typeof response.data === "object") {
        products.value = [response.data].slice(0, productsLimit);
      } else {
        console.error("Unknown API response format:", response.data);
        products.value = [];
      }
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
    // Reset scroll position after new products load
    resetScrollPosition();
  }
}

// Determine cards per view based on screen size
function getCardsPerView() {
  if (window.innerWidth < 640) {
    return 2; // Mobile: 2 cards per view
  } else if (window.innerWidth < 768) {
    return 3; // Tablet: 3 cards per view
  } else if (window.innerWidth < 1024) {
    return 4; // Small desktop: 4 cards per view
  } else {
    return 5; // Large desktop: 5 cards per view
  }
}

// Update responsive display based on screen size
function updateResponsiveDisplay() {
  if (window.innerWidth < 640) {
    itemsPerRow.value = 2; // Mobile: 2 items per row
  } else if (window.innerWidth < 768) {
    itemsPerRow.value = 3; // Small tablet: 3 items per row
  } else if (window.innerWidth < 1024) {
    itemsPerRow.value = 4; // Large tablet: 4 items per row
  } else {
    itemsPerRow.value = 5; // Desktop: 5 items per row
  }

  // Update current scroll position based on new display
  updateScrollPosition();
}

// Smooth scrolling function for arrow navigation
function scrollSlider(direction) {
  if (!sliderContainer.value) return;
  
  isScrolling.value = true;
  
  const container = sliderContainer.value;
  const scrollWidth = container.scrollWidth;
  const containerWidth = container.clientWidth;
  const scrollLeft = container.scrollLeft;
  
  const cardWidth = containerWidth / getCardsPerView();
  const scrollAmount = direction === 'left' ? -cardWidth * 2 : cardWidth * 2;
  const targetScroll = Math.max(0, Math.min(scrollLeft + scrollAmount, scrollWidth - containerWidth));
  
  container.scrollTo({
    left: targetScroll,
    behavior: 'smooth'
  });
  
  // Update scroll indicator
  const scrollIndex = Math.round((targetScroll / (scrollWidth - containerWidth)) * (scrollPositions.value.length - 1));
  currentScrollIndex.value = Math.max(0, Math.min(scrollIndex, scrollPositions.value.length - 1));
  
  // Reset scrolling flag after animation
  setTimeout(() => {
    isScrolling.value = false;
  }, 500);
}

// Handle mouse click for slider interaction
function handleSliderClick(event) {
  // Ignore clicks on product cards to allow normal card interactions
  if (event.target.closest('.product-card') || 
      event.target.closest('a') || 
      event.target.closest('button')) {
    return;
  }
  
  event.preventDefault();
  clickStartX.value = event.clientX;
  clickStartTime.value = Date.now();
  isMouseDown.value = true;
  
  // Add event listeners for mouse movement and release
  window.addEventListener('mousemove', handleMouseMove, { once: false });
  window.addEventListener('mouseup', handleMouseUp, { once: true });
}

// Handle mouse movement during click
function handleMouseMove(event) {
  if (!isMouseDown.value) return;
  
  const deltaX = event.clientX - clickStartX.value;
  
  // If moved more than 5px, treat as a drag operation, not a click
  if (Math.abs(deltaX) > 5) {
    const container = sliderContainer.value;
    if (container) {
      container.scrollLeft -= deltaX;
      clickStartX.value = event.clientX;
    }
  }
}

// Handle mouse up after click
function handleMouseUp(event) {
  if (!isMouseDown.value) return;
  
  window.removeEventListener('mousemove', handleMouseMove);
  
  const deltaX = event.clientX - clickStartX.value;
  const timeDiff = Date.now() - clickStartTime.value;
  
  // If it's a quick click (not a drag) and barely moved, scroll in the direction of the click
  if (Math.abs(deltaX) < 5 && timeDiff < 300) {
    const container = sliderContainer.value;
    if (container) {
      const containerWidth = container.clientWidth;
      const clickPosition = event.clientX - container.getBoundingClientRect().left;
      
      // Click on left half scrolls left, right half scrolls right
      if (clickPosition < containerWidth / 2) {
        scrollSlider('left');
      } else {
        scrollSlider('right');
      }
    }
  }
  
  isMouseDown.value = false;
}

// Handle touch events for mobile devices
function handleSliderTouch(event) {
  // Ignore touches on product cards to allow normal card interactions
  if (event.target.closest('.product-card') || 
      event.target.closest('a') || 
      event.target.closest('button')) {
    return;
  }
  
  const touch = event.touches[0];
  clickStartX.value = touch.clientX;
  clickStartTime.value = Date.now();
  
  // Add event listeners for touch movement and end
  window.addEventListener('touchend', handleTouchEnd, { once: true });
}

// Handle touch end
function handleTouchEnd(event) {
  if (event.target.closest('.product-card') || 
      event.target.closest('a') || 
      event.target.closest('button')) {
    return;
  }
  
  const touch = event.changedTouches[0];
  const deltaX = touch.clientX - clickStartX.value;
  const timeDiff = Date.now() - clickStartTime.value;
  
  // If it's a quick tap (not a swipe) and barely moved, scroll in the direction of the tap
  if (Math.abs(deltaX) < 5 && timeDiff < 300) {
    const container = sliderContainer.value;
    if (container) {
      const containerWidth = container.clientWidth;
      const touchPosition = touch.clientX - container.getBoundingClientRect().left;
      
      // Tap on left half scrolls left, right half scrolls right
      if (touchPosition < containerWidth / 2) {
        scrollSlider('left');
      } else {
        scrollSlider('right');
      }
    }
  }
}

// Scroll to specific position (for indicator dots)
function scrollToPosition(index) {
  if (!sliderContainer.value || isScrolling.value) return;
  
  isScrolling.value = true;
  currentScrollIndex.value = index;
  
  const container = sliderContainer.value;
  const scrollWidth = container.scrollWidth;
  const containerWidth = container.clientWidth;
  
  const scrollableWidth = scrollWidth - containerWidth;
  const targetScroll = index === 0 ? 0 : (index / (scrollPositions.value.length - 1)) * scrollableWidth;
  
  container.scrollTo({
    left: targetScroll,
    behavior: 'smooth'
  });
  
  // Reset scrolling flag after animation
  setTimeout(() => {
    isScrolling.value = false;
  }, 500);
}

// Reset scroll position
function resetScrollPosition() {
  if (!sliderContainer.value) return;
  sliderContainer.value.scrollLeft = 0;
  currentScrollIndex.value = 0;
}

// Update scroll position when screen size changes
function updateScrollPosition() {
  if (!sliderContainer.value || scrollPositions.value.length === 0) return;
  
  const container = sliderContainer.value;
  const scrollWidth = container.scrollWidth;
  const containerWidth = container.clientWidth;
  
  const scrollableWidth = scrollWidth - containerWidth;
  const targetScroll = currentScrollIndex.value === 0 ? 0 : 
    (currentScrollIndex.value / (scrollPositions.value.length - 1)) * scrollableWidth;
  
  container.scrollTo({
    left: targetScroll,
    behavior: 'auto'
  });
}

// Watch for scroll events
function handleScroll() {
  if (!sliderContainer.value || isScrolling.value || scrollPositions.value.length <= 1) return;
  
  const container = sliderContainer.value;
  const scrollWidth = container.scrollWidth;
  const containerWidth = container.clientWidth;
  const scrollLeft = container.scrollLeft;
  
  const scrollableWidth = scrollWidth - containerWidth;
  const scrollRatio = scrollLeft / scrollableWidth;
  
  currentScrollIndex.value = Math.round(scrollRatio * (scrollPositions.value.length - 1));
}

// Watch for element resizing using ResizeObserver
let resizeObserver = null;

// Lifecycle hooks
onMounted(() => {
  fetchProducts();
  updateResponsiveDisplay();
  window.addEventListener("resize", updateResponsiveDisplay);
  
  // Set up ResizeObserver to adjust on container size changes
  nextTick(() => {
    if (window.ResizeObserver) {
      resizeObserver = new ResizeObserver(() => {
        updateResponsiveDisplay();
      });
      
      if (sliderContainer.value) {
        resizeObserver.observe(sliderContainer.value);
        sliderContainer.value.addEventListener('scroll', handleScroll);
      }
    }
  });
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", updateResponsiveDisplay);
  window.removeEventListener('mousemove', handleMouseMove);
  window.removeEventListener('mouseup', handleMouseUp);
  window.removeEventListener('touchend', handleTouchEnd);
  
  // Clean up ResizeObserver and event listeners
  if (resizeObserver && sliderContainer.value) {
    resizeObserver.unobserve(sliderContainer.value);
    resizeObserver.disconnect();
    sliderContainer.value.removeEventListener('scroll', handleScroll);
  }
});

// Watch for products change
watch(
  () => products.value,
  () => {
    if (products.value.length > 0) {
      // Reset scroll position when products change
      resetScrollPosition();
    }
  }
);

// Watch for window resize to recalculate scroll positions
watch(
  () => itemsPerRow.value,
  () => {
    nextTick(() => {
      updateScrollPosition();
    });
  }
);
</script>

<style scoped>
/* Product Slider Container */
.product-slider-container {
  position: relative;
}

.product-slider-container:hover .group-hover\:opacity-100 {
  opacity: 1;
}

/* Slider Scrollbar Styling */
.custom-scrollbar {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.3) transparent;
  -webkit-overflow-scrolling: touch;
}

.custom-scrollbar::-webkit-scrollbar {
  height: 6px; /* Thin horizontal scrollbar */
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.3);
  border-radius: 20px;
}

.dark .custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(75, 85, 99, 0.3);
}

/* Hide scrollbar but keep functionality */
.hide-scrollbar {
  /* Hide scrollbar for Chrome, Safari and Opera */
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Opera */
}

/* Product card wrapper - this isolates hover effects */
.product-card-wrapper {
  position: relative;
  isolation: isolate; /* Create stacking context to isolate hover effects */
}

/* Product row and card styling */
.product-row {
  min-width: 100%;
  padding: 0 1px;
}

.product-card {
  transition: transform 0.2s ease;
  z-index: 1;
}

/* Improved clickable areas */
.slider-content {
  cursor: grab;
}

.slider-content:active {
  cursor: grabbing;
}

/* Product cards should have pointer cursor */
.product-card,
.product-card * {
  cursor: pointer;
}

/* Card sizes based on screen size */
@media (min-width: 1024px) {
  .product-card-wrapper {
    width: calc(20% - 16px); /* 5 cards per row on desktop */
  }
}

@media (min-width: 768px) and (max-width: 1023px) {
  .product-card-wrapper {
    width: calc(25% - 16px); /* 4 cards per row on tablet */
  }
}

@media (min-width: 640px) and (max-width: 767px) {
  .product-card-wrapper {
    width: calc(33.33% - 16px); /* 3 cards per row on small tablet */
  }
}

@media (max-width: 639px) {
  .product-card-wrapper {
    width: calc(50% - 10px); /* 2 cards per row on mobile */
  }
  
  .product-row .flex {
    gap: 10px; /* Smaller gap on mobile */
  }
}

/* Slider content styling */
.slider-content {
  -webkit-transform: translateZ(0);
  -moz-transform: translateZ(0);
  transform: translateZ(0);
  will-change: transform;
  width: 100%;
  scroll-snap-type: x mandatory;
}

/* Enhanced touch feedback */
.slider-content::after {
  content: '';
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
  background: radial-gradient(circle, transparent 90%, rgba(0, 0, 0, 0.03) 100%);
  opacity: 0;
  transition: opacity 0.3s ease;
}

.slider-content:active::after {
  opacity: 1;
}

/* Improved scrolling for touch devices */
@media (hover: none) and (pointer: coarse) {
  .slider-content {
    -webkit-overflow-scrolling: touch;
  }
}

/* Animation effects */
@keyframes shimmer {
  0% {
    -webkit-transform: translateX(-100%);
    -moz-transform: translateX(-100%);
    transform: translateX(-100%);
  }
  100% {
    -webkit-transform: translateX(100%);
    -moz-transform: translateX(100%);
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 2s infinite;
}

/* Smooth transition for scroll position indicators */
.w-2.rounded-full {
  transition: all 0.3s ease;
}

/* Custom colors */
:root {
  --primary-400: #38bdf8;
  --primary-500: #0ea5e9;
}
</style>
