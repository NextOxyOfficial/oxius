<template>
  <UContainer class="relative">
    <!-- Professional App-like Header -->
    <div class="relative sm:mb-6">
      <!-- Mobile-First Background Design -->
      <div
        class="relative p-4 sm:p-6 rounded-2xl sm:rounded-3xl bg-gradient-to-br from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 backdrop-blur-sm overflow-hidden"
      >
        <!-- Dynamic Background Pattern -->
        <div class="absolute inset-0 opacity-40 dark:opacity-20">
          <!-- Subtle grid pattern -->
          <div
            class="absolute inset-0 bg-[linear-gradient(90deg,rgba(0,0,0,0.02)_1px,transparent_1px)] bg-[size:20px_20px] dark:bg-[linear-gradient(90deg,rgba(255,255,255,0.03)_1px,transparent_1px)]"
          ></div>
          <div
            class="absolute inset-0 bg-[linear-gradient(0deg,rgba(0,0,0,0.02)_1px,transparent_1px)] bg-[size:20px_20px] dark:bg-[linear-gradient(0deg,rgba(255,255,255,0.03)_1px,transparent_1px)]"
          ></div>
          <!-- Floating elements for visual interest -->
          <div
            class="absolute top-2 right-4 w-2 h-2 rounded-full bg-blue-400/20"
          ></div>
          <div
            class="absolute bottom-3 left-6 w-1 h-1 rounded-full bg-emerald-400/30"
          ></div>
          <div
            class="absolute top-1/2 right-1/4 w-1.5 h-1.5 rounded-full bg-purple-400/20"
          ></div>
        </div>

        <!-- Header Content -->
        <div class="relative z-10">
          <!-- Top section with icon and title -->
          <div class="flex items-center justify-between mb-3 sm:mb-0">
            <div class="flex items-center gap-3 sm:gap-4">
              <!-- App-style Icon -->
              <div class="relative">
                <!-- Icon background with modern design -->
                <div
                  class="w-10 h-10 sm:w-12 sm:h-12 rounded-2xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center"
                >
                  <UIcon
                    name="i-heroicons-shopping-bag"
                    class="w-5 h-5 sm:w-6 sm:h-6 text-white"
                  />
                  <!-- Subtle shine effect -->
                  <div
                    class="absolute inset-0 rounded-2xl bg-gradient-to-br from-white/20 to-transparent"
                  ></div>
                </div>
                <!-- Active indicator dot -->
                <div
                  class="absolute -top-1 -right-1 w-3 h-3 bg-emerald-400 rounded-full border-2 border-white dark:border-slate-800"
                ></div>
              </div>

              <!-- Title and description -->
              <div class="flex-1 min-w-0">
                <NuxtLink to="/eshop">
                  <h2
                    class="text-lg sm:text-xl font-medium text-slate-900 dark:text-white truncate hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors duration-200 cursor-pointer"
                  >
                    {{ $t("eshop") }}
                  </h2>
                </NuxtLink>
                <p
                  class="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium"
                >
                  Diverse products from various categories
                </p>
              </div>
            </div>
            <!-- Action button - mobile optimized -->
            <NuxtLink
              to="/shop-manager"
              class="flex-shrink-0 group relative inline-flex items-center gap-2 px-3 py-2 sm:px-4 sm:py-2.5 rounded-xl bg-gradient-to-r from-blue-600 to-purple-600 text-white font-medium text-xs sm:text-sm transition-colors duration-200 overflow-hidden"
              @click="handleButtonClick('sell-on-eshop')"
            >
              <div
                v-if="loadingButtons.has('sell-on-eshop')"
                class="dotted-spinner white mr-2"
              ></div>
              <span v-else class="relative z-10 truncate">{{
                $t("sell_on_eshop")
              }}</span>
              <UIcon
                v-if="!loadingButtons.has('sell-on-eshop')"
                name="i-heroicons-arrow-right"
                class="w-3 h-3 sm:w-4 sm:h-4 relative z-10 flex-shrink-0"
              />
            </NuxtLink>
          </div>
        </div>
      </div>
    </div>

    <CommonCategoryLayout />
    <!-- Professional Loading State -->
    <div v-if="isLoading" class="flex justify-center py-12">
      <div class="relative">
        <!-- Modern spinner -->
        <div
          class="w-12 h-12 rounded-full border-4 border-slate-200 dark:border-slate-700"
        ></div>
        <div
          class="w-12 h-12 rounded-full border-t-4 border-blue-600 animate-spin absolute top-0"
        ></div>
        <!-- Pulsing dots -->
        <div class="flex justify-center gap-1 mt-4">
          <div class="w-2 h-2 bg-blue-600 rounded-full"></div>
          <div class="w-2 h-2 bg-blue-600 rounded-full"></div>
          <div class="w-2 h-2 bg-blue-600 rounded-full"></div>
        </div>
      </div>
    </div>
    <!-- Professional Product Slider -->
    <div
      v-else-if="productsCount > 0"
      class="relative product-slider-container group"
    >
      <!-- Modern Product Container -->
      <div
        ref="sliderContainer"
        class="rounded-2xl bg-gradient-to-br from-slate-50/80 to-white dark:from-slate-900/80 dark:to-slate-800 backdrop-blur-sm border border-slate-200/50 dark:border-slate-700/50 overflow-hidden"
      >
        <!-- First row of products -->
        <div class="slider-content py-3 px-1 sm:px-4">
          <div class="product-row">
            <div
              class="flex gap-1 sm:gap-3 md:gap-4 overflow-x-auto hide-scrollbar scroll-smooth"
              style="-webkit-overflow-scrolling: touch"
            >
              <div
                v-for="product in firstRowProducts"
                :key="product.id"
                class="product-card-wrapper flex-shrink-0"
              >
                <CommonProductCard :product="product" class="product-card" />
              </div>
            </div>
          </div>
        </div>
        <!-- Second row of products -->
        <div class="slider-content py-3 px-1 sm:px-4 pb-4">
          <div class="product-row">
            <div
              class="flex gap-1 sm:gap-3 md:gap-4 overflow-x-auto hide-scrollbar scroll-smooth"
              style="-webkit-overflow-scrolling: touch"
            >
              <div
                v-for="product in secondRowProducts"
                :key="product.id"
                class="product-card-wrapper flex-shrink-0"
              >
                <CommonProductCard :product="product" class="product-card" />
              </div>
            </div>
          </div>
        </div>
        <!-- third row of products -->
        <!-- <div class="slider-content py-3 px-1 sm:px-4 pb-4">
          <div class="product-row">
            <div
              class="flex gap-1 sm:gap-3 md:gap-4 overflow-x-auto hide-scrollbar scroll-smooth"
              style="-webkit-overflow-scrolling: touch"
            >
              <div
                v-for="product in thirdRowProducts"
                :key="product.id"
                class="product-card-wrapper flex-shrink-0"
              >
                <CommonProductCard :product="product" class="product-card" />
              </div>
            </div>
          </div>
        </div> -->
        <!-- fourth row of products -->
        <!-- <div class="slider-content py-3 px-1 sm:px-4 pb-4">
          <div class="product-row">
            <div
              class="flex gap-1 sm:gap-3 md:gap-4 overflow-x-auto hide-scrollbar scroll-smooth"
              style="-webkit-overflow-scrolling: touch"
            >
              <div
                v-for="product in fourthRowProducts"
                :key="product.id"
                class="product-card-wrapper flex-shrink-0"
              >
                <CommonProductCard :product="product" class="product-card" />
              </div>
            </div>
          </div>
        </div> -->
      </div>

      <!-- Professional CTA Section -->
      <div class="text-center mt-6 sm:mt-8">
        <!-- Mobile: Compact button -->
        <NuxtLink
          to="/eshop"
          class="sm:hidden group relative inline-flex items-center justify-center gap-2 px-4 py-2 font-semibold text-xs text-white bg-gradient-to-r from-green-500 to-emerald-600 rounded-xl transition-colors duration-200 overflow-hidden"
          @click="handleButtonClick('all-product-mobile')"
        >
          <div
            v-if="loadingButtons.has('all-product-mobile')"
            class="dotted-spinner white mr-2"
          ></div>
          <span v-else class="relative z-10">{{ $t("all_product") }}</span>
          <UIcon 
            v-if="!loadingButtons.has('all-product-mobile')"
            name="i-heroicons-arrow-right" 
            class="w-3 h-3 relative z-10" 
          />
        </NuxtLink>
        <!-- Desktop: Enhanced button -->
        <NuxtLink
          to="/eshop"
          class="hidden sm:inline-flex group relative items-center justify-center gap-2 px-6 py-3 font-semibold text-sm text-white bg-gradient-to-r from-green-500 to-emerald-600 rounded-xl transition-colors duration-200 overflow-hidden"
          @click="handleButtonClick('all-product-desktop')"
        >
          <div
            v-if="loadingButtons.has('all-product-desktop')"
            class="dotted-spinner white mr-2"
          ></div>
          <span v-else class="relative z-10">{{ $t("all_product") }}</span>
          <UIcon
            v-if="!loadingButtons.has('all-product-desktop')"
            name="i-heroicons-arrow-long-right"
            class="w-4 h-4 relative z-10"
          />
        </NuxtLink>
      </div>
    </div>
    <!-- Professional Empty State -->
    <div
      v-else
      class="py-12 sm:py-16 flex flex-col items-center justify-center text-center bg-gradient-to-br from-slate-50 to-white dark:from-slate-900 dark:to-slate-800 rounded-2xl border border-slate-200/50 dark:border-slate-700/50"
    >
      <!-- Modern Empty State Icon -->
      <div class="relative mb-6">
        <div
          class="w-20 h-20 sm:w-24 sm:h-24 bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-700 dark:to-slate-600 rounded-3xl flex items-center justify-center"
        >
          <UIcon
            name="i-heroicons-shopping-bag"
            class="w-10 h-10 sm:w-12 sm:h-12 text-slate-400 dark:text-slate-500"
          />
        </div>
        <!-- Floating elements around the icon -->
        <div
          class="absolute -top-1 -right-1 w-4 h-4 bg-blue-400/20 rounded-full animate-ping"
        ></div>
        <div
          class="absolute -bottom-2 -left-2 w-3 h-3 bg-purple-400/20 rounded-full animate-pulse"
        ></div>
      </div>

      <!-- Professional messaging -->
      <h3
        class="text-xl sm:text-2xl font-bold text-slate-800 dark:text-white mb-2"
      >
        No Products Available
      </h3>
      <p class="text-slate-600 dark:text-slate-400 mb-6 max-w-sm">
        We're working to bring you amazing products. Check back soon!
      </p>

      <!-- Modern refresh button -->
      <button
        @click="fetchProducts"
        class="group inline-flex items-center gap-2 px-6 py-3 font-semibold text-sm text-white bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl transition-all duration-300 transform hover:scale-[1.02] active:scale-[0.98] overflow-hidden"
      >
        <div
          class="absolute inset-0 bg-gradient-to-r from-blue-700 to-purple-700 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
        ></div>
        <UIcon
          name="i-heroicons-arrow-path"
          class="w-4 h-4 relative z-10 group-hover:rotate-180 transition-transform duration-500"
        />
        <span class="relative z-10">Refresh</span>
      </button>
    </div>
  </UContainer>
</template>

<script setup>
import { CommonCategoryLayout } from "#components";

const { get } = useApi();

// Loading state for buttons
const loadingButtons = ref(new Set());

// Function to handle button click and show loading
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
  // Remove loading state after navigation (cleanup happens in route change)
  setTimeout(() => {
    loadingButtons.value.delete(buttonId);
  }, 3000); // Fallback timeout
};

// Watch for route changes to clear loading states
const route = useRoute();
watch(
  () => route.path,
  () => {
    loadingButtons.value.clear();
  }
);

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
  return products.value.slice(0, 5); // First 5 products (half of total)
});

const secondRowProducts = computed(() => {
  if (!products.value.length) return [];
  return products.value.slice(5, 10); // Last 5 products (second half)
});

const thirdRowProducts = computed(() => {
  if (!products.value.length) return [];
  return products.value.slice(10, 15); // Last 5 products (second half)
});

const fourthRowProducts = computed(() => {
  if (!products.value.length) return [];
  return products.value.slice(15, 20); // Last 5 products (second half)
});

// Calculate number of scroll positions based on products and visible items
const scrollPositions = computed(() => {
  if (productsCount.value === 0) return [];
  const cardsPerView = getCardsPerView();
  const totalPositions = Math.ceil(productsCount.value / 2 / cardsPerView);
  return Array.from({ length: totalPositions });
});

// Fetch products from API with better error handling and limit
async function fetchProducts() {
  isLoading.value = true;

  try {
    // Add limit and random parameters to fetch exactly 10 random products from different categories
    const response = await get(
      `/all-products/?limit=${productsLimit}&random=true`
    );

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
  const scrollAmount = direction === "left" ? -cardWidth * 2 : cardWidth * 2;
  const targetScroll = Math.max(
    0,
    Math.min(scrollLeft + scrollAmount, scrollWidth - containerWidth)
  );

  container.scrollTo({
    left: targetScroll,
    behavior: "smooth",
  });
  // Update scroll indicator
  const scrollIndex = Math.round(
    (targetScroll / (scrollWidth - containerWidth)) *
      (scrollPositions.value.length - 1)
  );
  currentScrollIndex.value = Math.max(
    0,
    Math.min(scrollIndex, scrollPositions.value.length - 1)
  );

  // Reset scrolling flag after animation completes
  container.addEventListener(
    "scrollend",
    () => {
      isScrolling.value = false;
    },
    { once: true }
  );

  // Fallback timeout in case scrollend isn't supported
  setTimeout(() => {
    isScrolling.value = false;
  }, 800);
}

// Handle mouse click for slider interaction
function handleSliderClick(event) {
  // Ignore clicks on product cards to allow normal card interactions
  if (
    event.target.closest(".product-card") ||
    event.target.closest("a") ||
    event.target.closest("button")
  ) {
    return;
  }

  event.preventDefault();
  clickStartX.value = event.clientX;
  clickStartTime.value = Date.now();
  isMouseDown.value = true;

  // Add event listeners for mouse movement and release
  window.addEventListener("mousemove", handleMouseMove, { once: false });
  window.addEventListener("mouseup", handleMouseUp, { once: true });
}

// Handle mouse movement during click
function handleMouseMove(event) {
  if (!isMouseDown.value) return;

  const deltaX = event.clientX - clickStartX.value;

  // Only track movement for gesture detection, don't manually manipulate scroll
  if (Math.abs(deltaX) > 5) {
    // Mark as dragging but let native scrolling handle the movement
    clickStartX.value = event.clientX;
  }
}

// Handle mouse up after click
function handleMouseUp(event) {
  if (!isMouseDown.value) return;

  window.removeEventListener("mousemove", handleMouseMove);

  const deltaX = event.clientX - clickStartX.value;
  const timeDiff = Date.now() - clickStartTime.value;

  // If it's a quick click (not a drag) and barely moved, scroll in the direction of the click
  if (Math.abs(deltaX) < 5 && timeDiff < 300) {
    const container = sliderContainer.value;
    if (container) {
      const containerWidth = container.clientWidth;
      const clickPosition =
        event.clientX - container.getBoundingClientRect().left;

      // Click on left half scrolls left, right half scrolls right
      if (clickPosition < containerWidth / 2) {
        scrollSlider("left");
      } else {
        scrollSlider("right");
      }
    }
  }

  isMouseDown.value = false;
}

// Handle touch events for mobile devices
function handleSliderTouch(event) {
  // For mobile, let native scrolling handle the interaction
  // Only prevent if it's not a product card interaction
  if (
    event.target.closest(".product-card") ||
    event.target.closest("a") ||
    event.target.closest("button")
  ) {
    return;
  }

  // Don't interfere with native scrolling on mobile
  if (window.innerWidth < 640) {
    return;
  }

  const touch = event.touches[0];
  clickStartX.value = touch.clientX;
  clickStartTime.value = Date.now();

  // Add event listeners for touch movement and end
  window.addEventListener("touchend", handleTouchEnd, { once: true });
}

// Handle touch end
function handleTouchEnd(event) {
  if (
    event.target.closest(".product-card") ||
    event.target.closest("a") ||
    event.target.closest("button")
  ) {
    return;
  }

  // Don't interfere with native scrolling on mobile
  if (window.innerWidth < 640) {
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
      const touchPosition =
        touch.clientX - container.getBoundingClientRect().left;

      // Tap on left half scrolls left, right half scrolls right
      if (touchPosition < containerWidth / 2) {
        scrollSlider("left");
      } else {
        scrollSlider("right");
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
  const targetScroll =
    index === 0
      ? 0
      : (index / (scrollPositions.value.length - 1)) * scrollableWidth;
  container.scrollTo({
    left: targetScroll,
    behavior: "smooth",
  });

  // Reset scrolling flag after animation completes
  container.addEventListener(
    "scrollend",
    () => {
      isScrolling.value = false;
    },
    { once: true }
  );

  // Fallback timeout in case scrollend isn't supported
  setTimeout(() => {
    isScrolling.value = false;
  }, 800);
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
  const targetScroll =
    currentScrollIndex.value === 0
      ? 0
      : (currentScrollIndex.value / (scrollPositions.value.length - 1)) *
        scrollableWidth;

  container.scrollTo({
    left: targetScroll,
    behavior: "auto",
  });
}

// Watch for scroll events
function handleScroll() {
  if (
    !sliderContainer.value ||
    isScrolling.value ||
    scrollPositions.value.length <= 1
  )
    return;

  // Throttle scroll event handling to improve performance
  requestAnimationFrame(() => {
    if (!sliderContainer.value) return;

    const container = sliderContainer.value;
    const scrollWidth = container.scrollWidth;
    const containerWidth = container.clientWidth;
    const scrollLeft = container.scrollLeft;

    const scrollableWidth = scrollWidth - containerWidth;
    const scrollRatio = scrollLeft / scrollableWidth;

    currentScrollIndex.value = Math.round(
      scrollRatio * (scrollPositions.value.length - 1)
    );
  });
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
        // Only add scroll listener for non-mobile devices
        if (window.innerWidth >= 640) {
          sliderContainer.value.addEventListener("scroll", handleScroll);
        }
      }
    }
  });
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", updateResponsiveDisplay);
  window.removeEventListener("mousemove", handleMouseMove);
  window.removeEventListener("mouseup", handleMouseUp);
  window.removeEventListener("touchend", handleTouchEnd);

  // Clean up ResizeObserver and event listeners
  if (resizeObserver && sliderContainer.value) {
    resizeObserver.unobserve(sliderContainer.value);
    resizeObserver.disconnect();
    sliderContainer.value.removeEventListener("scroll", handleScroll);
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
  width: 100%;
  padding: 0;
}

.product-card {
  transition: transform 0.15s ease;
  z-index: 1;
  width: 100%;
  height: auto;
}

/* Improved clickable areas */
.slider-content {
  width: 100%;
}

/* On mobile, don't change cursor since we want native scrolling */
@media (min-width: 640px) {
  .slider-content {
    cursor: grab;
  }

  .slider-content:active {
    cursor: grabbing;
  }
}

/* Product cards should have pointer cursor */
.product-card,
.product-card * {
  cursor: pointer;
}

/* Card sizes based on screen size - ensuring proper mobile scrolling */
@media (min-width: 1024px) {
  .product-card-wrapper {
    width: calc(
      20% - 12px
    ); /* 5 cards per row on desktop, accounting for gaps */
    min-width: calc(20% - 12px);
    max-width: calc(20% - 12px);
  }

  .product-row .flex {
    width: 100%;
    justify-content: space-between;
  }
}

@media (min-width: 768px) and (max-width: 1023px) {
  .product-card-wrapper {
    width: calc(25% - 12px); /* 4 cards per row on tablet */
    min-width: calc(25% - 12px);
    max-width: calc(25% - 12px);
  }

  .product-row .flex {
    width: 100%;
    justify-content: space-between;
  }
}

@media (min-width: 640px) and (max-width: 767px) {
  .product-card-wrapper {
    width: calc(33.33% - 10px); /* 3 cards per row on small tablet */
    min-width: calc(33.33% - 10px);
    max-width: calc(33.33% - 10px);
  }

  .product-row .flex {
    width: 100%;
    justify-content: space-between;
  }
}

@media (max-width: 639px) {
  .product-card-wrapper {
    width: calc(
      50% - 2px
    ); /* 2 cards per row on mobile, accounting for smaller gaps */
    min-width: calc(50% - 2px);
    max-width: calc(50% - 2px);
    flex-shrink: 0;
  }

  .product-row .flex {
    width: 100%; /* Full width container */
    justify-content: space-between; /* Even distribution */
    gap: 4px !important; /* Smaller gap on mobile to fit 2 cards perfectly */
    flex-wrap: nowrap; /* Prevent wrapping to maintain 2 per row */
    overflow-x: auto; /* Allow horizontal scrolling for additional products */
  }
}

/* Slider content styling */
.slider-content {
  width: 100%;
  display: block;
}

/* Ensure both rows have consistent spacing */
.slider-content + .slider-content {
  margin-top: 0;
}

/* Product row flex container */
.product-row .flex {
  display: flex;
  flex-wrap: nowrap;
  align-items: stretch;
}

/* Improved scrolling for touch devices */
@media (hover: none) and (pointer: coarse) {
  .slider-content {
    -webkit-overflow-scrolling: touch;
  }

  /* Ensure smooth scrolling on mobile */
  .overflow-x-auto {
    scroll-behavior: smooth;
    -webkit-overflow-scrolling: touch;
    scrollbar-width: none; /* Firefox */
    -ms-overflow-style: none; /* IE and Edge */
  }

  .overflow-x-auto::-webkit-scrollbar {
    display: none; /* Chrome, Safari, Opera */
  }
}

/* Animation effects */
@keyframes fadeIn {
  0% {
    opacity: 0;
  }
  100% {
    opacity: 1;
  }
}

.animate-shimmer {
  animation: fadeIn 1s ease;
}

/* Smooth transition for scroll position indicators */
.w-2.rounded-full {
  transition: all 0.3s ease;
}

/* Professional app-like animations - simplified for performance */
@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeInScale {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

/* Component entrance animations - simplified */
.product-slider-container {
  animation: slideUp 0.3s ease-out;
}

/* Modern focus states */
button:focus-visible,
[role="button"]:focus-visible {
  outline: 2px solid rgb(59 130 246);
  outline-offset: 2px;
  border-radius: 0.5rem;
}

/* Enhanced touch interactions for mobile */
@media (hover: none) and (pointer: coarse) {
  /* Larger touch targets */
  button {
    min-width: 44px;
    min-height: 44px;
  }

  /* Better touch feedback - reduced animation for performance */
  .product-card-wrapper {
    transition: transform 0.1s ease;
  }

  .product-card-wrapper:active {
    transform: scale(0.99);
  }
}

/* Professional gradient backgrounds */
.gradient-bg-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.gradient-bg-secondary {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

/* Improved scrollbar for webkit browsers */
.custom-scrollbar::-webkit-scrollbar {
  height: 4px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.05);
  border-radius: 2px;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background: linear-gradient(90deg, rgb(59 130 246), rgb(147 51 234));
  border-radius: 2px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(90deg, rgb(37 99 235), rgb(126 34 206));
}

/* Professional loading states */
@keyframes pulse-soft {
  0%,
  100% {
    opacity: 0.6;
  }
  50% {
    opacity: 1;
  }
}

.animate-pulse-soft {
  animation: pulse-soft 2s ease-in-out infinite;
}

/* Custom colors */
:root {
  --primary-400: #60a5fa;
  --primary-500: #3b82f6;
  --primary-600: #2563eb;
  --secondary-400: #c084fc;
  --secondary-500: #a855f7;
  --secondary-600: #9333ea;
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.white {
  border-color: #ffffff;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
