<template>
  <div
    v-if="ads?.results?.length"
    class="py-4 bg-gradient-to-b from-slate-50 to-white dark:from-slate-900 dark:to-slate-800"
  >
    <UContainer>
      <div
        class="ads-container relative overflow-hidden rounded-lg border border-slate-100 dark:border-slate-700 bg-white dark:bg-slate-800 shadow-sm"
      >
        <!-- Header with accent line -->
        <div
          class="px-3.5 py-3 border-b border-slate-100 dark:border-slate-700 relative overflow-hidden flex justify-between items-center"
        >
          <div
            class="absolute top-0 left-0 w-full h-0.5 bg-gradient-to-r from-emerald-500 via-blue-500 to-purple-500"
          ></div>

          <div class="flex items-center gap-2">
            <div
              class="bg-emerald-50 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 p-1 rounded"
            >
              <UIcon name="i-heroicons-clock" class="w-4 h-4" />
            </div>
            <h2 class="text-sm font-semibold text-slate-800 dark:text-white">
              সাম্প্রতিক পোষ্ট
            </h2>
          </div>

          <!-- Navigation controls -->
          <div class="flex items-center gap-2">
            <button
              @click="scrollLeft"
              class="p-1.5 rounded-full bg-slate-100 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600 text-slate-600 dark:text-slate-300 transition-colors"
              aria-label="Scroll left"
            >
              <UIcon name="i-heroicons-chevron-left" class="w-3.5 h-3.5" />
            </button>
            <button
              @click="scrollRight"
              class="p-1.5 rounded-full bg-slate-100 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600 text-slate-600 dark:text-slate-300 transition-colors"
              aria-label="Scroll right"
            >
              <UIcon name="i-heroicons-chevron-right" class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        <!-- Carousel with continuous scrolling -->
        <div
          ref="carouselRef"
          class="relative px-3 py-3.5 overflow-hidden"
          @mouseenter="pauseAutoScroll"
          @mouseleave="resumeAutoScroll"
        >
          <div
            ref="carouselInnerRef"
            class="flex gap-3 transition-transform duration-300 ease-out"
            :style="{ transform: `translateX(${-scrollPosition}px)` }"
            @touchstart="handleTouchStart"
            @touchmove="handleTouchMove"
            @touchend="handleTouchEnd"
          >
            <div
              v-for="(ad, index) in displayedAds"
              :key="index"
              class="ad-card flex-shrink-0 group"
              :style="{ width: `${cardWidth}px` }"
            >
              <!-- Card with clean design -->
              <div
                class="h-full flex flex-col rounded-lg overflow-hidden border border-slate-100 dark:border-slate-700 bg-white dark:bg-slate-800 shadow-sm hover:shadow-md transition-all"
              >
                <!-- Image container -->
                <div class="relative h-36 overflow-hidden">
                  <div
                    class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent z-10 opacity-0 group-hover:opacity-100 transition-opacity"
                  ></div>
                  <NuxtImg
                    :src="getImageSrc(ad)"
                    :alt="ad.title"
                    class="w-full h-full object-cover transition-transform duration-500 ease-out group-hover:scale-105"
                    loading="lazy"
                  />
                  <!-- Price tag -->
                  <div
                    class="absolute top-2 right-2 z-20 bg-white dark:bg-slate-800 px-2 py-0.5 rounded-full shadow-sm"
                  >
                    <span
                      class="text-emerald-600 dark:text-emerald-400 font-medium text-xs flex items-center"
                    >
                      <span class="text-sm mr-0.5">৳</span
                      >{{ formatPrice(ad.price) }}
                    </span>
                  </div>
                </div>

                <!-- Content area -->
                <div class="flex flex-col flex-grow p-3">
                  <NuxtLink
                    :to="`/classified-categories/details/${ad.id}`"
                    class="group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors"
                  >
                    <h3
                      class="font-medium text-slate-800 dark:text-slate-100 line-clamp-2 mb-1.5 leading-snug"
                    >
                      {{ ad.title }}
                    </h3>
                  </NuxtLink>

                  <!-- Location with icon -->
                  <div
                    class="flex items-center text-slate-500 dark:text-slate-400 mb-1.5"
                  >
                    <UIcon
                      name="i-heroicons-map-pin"
                      class="w-3.5 h-3.5 mr-1 flex-shrink-0"
                    />
                    <span class="truncate text-xs"
                      >{{ ad.upazila }}, {{ ad.city }}</span
                    >
                  </div>

                  <!-- Date with icon -->
                  <div
                    class="mt-auto flex items-center text-slate-500 dark:text-slate-400"
                  >
                    <UIcon
                      name="i-heroicons-calendar"
                      class="w-3.5 h-3.5 mr-1 flex-shrink-0"
                    />
                    <span class="text-xs">{{ formatDate(ad.created_at) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
const { formatDate } = useUtils();
const { ads } = defineProps({
  ads: {
    type: Object,
    required: true,
  },
});

// Refs for carousel control
const carouselRef = ref(null);
const carouselInnerRef = ref(null);
const cardWidth = ref(180); // Moderately sized cards
const cardGap = 12; // Increased gap between cards
const scrollPosition = ref(0);
const totalWidth = ref(0);
const viewportWidth = ref(0);

// Touch interaction
const isDragging = ref(false);
const startX = ref(0);
const startScrollPos = ref(0);
const isPaused = ref(false);

// Animation control
const animationSpeed = ref(0.8);
const autoScrollInterval = ref(null);

// Process ads data
const adsArray = computed(() => {
  if (!ads?.results) return [];
  return Array.isArray(ads.results) ? ads.results : [];
});

// Create enough duplicates to ensure continuous scrolling
const displayedAds = computed(() => {
  if (adsArray.value.length === 0) return [];
  // Create multiple duplicates of the array to ensure continuous scrolling
  return [
    ...adsArray.value,
    ...adsArray.value,
    ...adsArray.value,
    ...adsArray.value,
  ];
});

// Get appropriate image source
function getImageSrc(ad) {
  if (ad.medias && ad.medias.length > 0 && ad.medias[0].image) {
    return ad.medias[0].image;
  }

  if (ad.image) {
    return ad.image;
  }

  return "https://placehold.co/300x200?text=No+Image";
}

// Format price with commas
const formatPrice = (price) => {
  if (!price) return "0";
  return price.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
};

// Manual navigation controls
const scrollLeft = () => {
  const scrollAmount = viewportWidth.value * 0.5; // Scroll half the viewport
  scrollPosition.value = Math.max(0, scrollPosition.value - scrollAmount);
};

const scrollRight = () => {
  const scrollAmount = viewportWidth.value * 0.5; // Scroll half the viewport
  const maxScroll = totalWidth.value - viewportWidth.value;
  scrollPosition.value = Math.min(
    maxScroll,
    scrollPosition.value + scrollAmount
  );
};

// Handle touch events
const handleTouchStart = (e) => {
  isDragging.value = true;
  startX.value = e.touches[0].clientX;
  startScrollPos.value = scrollPosition.value;
  pauseAutoScroll();
};

const handleTouchMove = (e) => {
  if (!isDragging.value) return;
  const currentX = e.touches[0].clientX;
  const diff = startX.value - currentX;

  // Calculate the new scroll position with resistance at edges
  const newPosition = startScrollPos.value + diff;
  const maxScroll = totalWidth.value - viewportWidth.value;

  // Apply position with bounds and resistance
  if (newPosition < 0) {
    scrollPosition.value = newPosition * 0.3; // Resistance when pulling past left edge
  } else if (newPosition > maxScroll) {
    scrollPosition.value = maxScroll + (newPosition - maxScroll) * 0.3; // Resistance when pulling past right edge
  } else {
    scrollPosition.value = newPosition;
  }
};

const handleTouchEnd = () => {
  if (!isDragging.value) return;
  isDragging.value = false;

  // Snap back to bounds if pulled past edges
  const maxScroll = totalWidth.value - viewportWidth.value;
  if (scrollPosition.value < 0) {
    scrollPosition.value = 0;
  } else if (scrollPosition.value > maxScroll) {
    scrollPosition.value = maxScroll;
  }

  // Resume auto-scrolling after a short delay
  setTimeout(() => {
    resumeAutoScroll();
  }, 2000);
};

// Auto-scroll controls
const pauseAutoScroll = () => {
  isPaused.value = true;
  if (autoScrollInterval.value) {
    clearInterval(autoScrollInterval.value);
    autoScrollInterval.value = null;
  }
};

const resumeAutoScroll = () => {
  isPaused.value = false;
  startAutoScroll();
};

// New continuous scrolling function
const startAutoScroll = () => {
  if (autoScrollInterval.value) {
    clearInterval(autoScrollInterval.value);
  }

  // Only auto-scroll if content exceeds viewport
  if (totalWidth.value > viewportWidth.value) {
    autoScrollInterval.value = setInterval(() => {
      if (isPaused.value) return;

      // Original array length (before duplication)
      const originalLength = adsArray.value.length;
      // Width of one set of the original array
      const oneSetWidth =
        originalLength * cardWidth.value + (originalLength - 1) * cardGap;

      // Advance position
      scrollPosition.value += animationSpeed.value;

      // If we've scrolled past the first set and have enough duplicates
      // silently reset to beginning of second set to create illusion of continuous scrolling
      if (
        scrollPosition.value > oneSetWidth &&
        displayedAds.value.length > originalLength * 2
      ) {
        scrollPosition.value = 1; // Keep a slight offset to avoid visual jumps
      }

      // Safety check to ensure we don't scroll beyond the content
      const maxScroll = totalWidth.value - viewportWidth.value;
      if (scrollPosition.value > maxScroll) {
        scrollPosition.value = maxScroll - 10; // Keep slightly before the end
      }
    }, 30); // Smooth scrolling interval
  }
};

// Calculate dimensions and set up scrolling
const initializeCarousel = () => {
  if (
    !carouselRef.value ||
    !carouselInnerRef.value ||
    !displayedAds.value.length
  )
    return;

  viewportWidth.value = carouselRef.value.clientWidth;

  // Adjust card width based on screen size - more reasonable sizes
  if (window.innerWidth < 640) {
    // Mobile: show 2 cards
    cardWidth.value = viewportWidth.value * 0.45;
    animationSpeed.value = 0.6;
  } else if (window.innerWidth < 1024) {
    // Tablet: show 3 cards
    cardWidth.value = viewportWidth.value * 0.3;
    animationSpeed.value = 0.8;
  } else {
    // Desktop: show 4-5 cards
    cardWidth.value = viewportWidth.value * 0.21;
    animationSpeed.value = 1;
  }

  // Calculate total width of all cards including gaps
  totalWidth.value =
    displayedAds.value.length * cardWidth.value +
    (displayedAds.value.length - 1) * cardGap;

  startAutoScroll();
};

// Lifecycle hooks
onMounted(() => {
  setTimeout(() => {
    initializeCarousel();
    window.addEventListener("resize", initializeCarousel);
  }, 200); // Slight delay to ensure DOM is ready
});

onUnmounted(() => {
  if (autoScrollInterval.value) {
    clearInterval(autoScrollInterval.value);
  }
  window.removeEventListener("resize", initializeCarousel);
});
</script>

<style scoped>
/* Ensure proper stacking context */
.ad-card {
  will-change: transform;
  backface-visibility: hidden;
}

/* Prevent text selection during swiping */
.carousel-inner {
  user-select: none;
}

/* Ensure smooth performance */
.ad-card img {
  backface-visibility: hidden;
  -webkit-backface-visibility: hidden;
}

/* Reduced spacing for mobile */
@media (max-width: 640px) {
  .ad-card h3 {
    font-size: 12px;
    line-height: 1.4;
  }
}

/* Slightly larger for tablets */
@media (min-width: 641px) and (max-width: 1024px) {
  .ad-card h3 {
    font-size: 13px;
    line-height: 1.4;
  }
}

/* Desktop size */
@media (min-width: 1025px) {
  .ad-card h3 {
    font-size: 14px;
    line-height: 1.4;
  }
}
</style>
