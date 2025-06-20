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
              class="bg-emerald-50 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 p-1.5 rounded-full inline-flex items-center"
            >
              <UIcon name="i-heroicons-clock" class="size-5" />
            </div>
            <h2 class="font-semibold text-gray-800 dark:text-white text-lg">
              {{ sectionTitle }}
            </h2>
          </div>

          <!-- Navigation controls -->
          <div class="flex items-center gap-2">
            <!-- <NuxtLink
              to="/all-result"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 md:hover:bg-gradient-to-r md:hover:from-primary-50 md:hover:to-blue-50 dark:hover:from-primary-900/20 dark:hover:to-blue-900/20 transition-all duration-300 text-sm font-medium group"
            >
              <span>View All Posts</span>
              <UIcon
                name="i-heroicons-arrow-right"
                class="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform"
              />
            </NuxtLink> -->
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
                class="h-full flex flex-col rounded-lg overflow-hidden border border-slate-100 dark:border-slate-700 bg-white dark:bg-slate-800 shadow-sm hover:shadow-sm transition-all"
              >
                <!-- Image container -->
                <div class="relative h-36 overflow-hidden">
                  <div
                    class="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent z-10 opacity-0 group-hover:opacity-100 transition-opacity"
                  ></div>                  <NuxtImg
                    :src="getImageSrc(ad)"
                    :alt="ad.title"
                    class="w-full h-full object-cover transition-transform duration-300 ease-out group-hover:scale-105"
                    loading="lazy"
                    placeholder
                    format="webp"
                    quality="80"
                    sizes="sm:180px md:220px lg:250px"
                  />
                  <!-- Price tag -->
                  <div
                    class="absolute top-2 right-2 z-20 bg-white dark:bg-slate-800 px-2 py-0.5 rounded-full shadow-sm"
                  >
                    <span
                      class="text-emerald-600 dark:text-emerald-400 font-medium text-sm flex items-center"
                    >
                      <span class="text-sm mr-0.5">৳</span
                      >{{ formatPrice(ad.price) }}
                    </span>
                  </div>
                </div>

                <!-- Content area -->
                <div class="flex flex-col flex-grow p-3">
                  <NuxtLink
                    :to="`/classified-categories/details/${ad.slug || ad.id}`"
                    class="group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors"
                  >
                    <h3
                      class="font-medium text-gray-800 dark:text-slate-100 line-clamp-2 mb-1.5 leading-snug"
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
                    <span class="truncate text-sm"
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
/**
 * AdsScroll Component - Optimized for Performance
 * - Limits to maximum 10 random recent posts per reload
 * - Uses random selection for variety on each page load
 * - Optimized animation speeds and intervals for smooth scrolling
 * - Reduced memory footprint and improved initial loading speed
 */

const { formatDate } = useUtils();
const { ads } = defineProps({
  ads: {
    type: Object,
    required: true,
  },
  sectionTitle: {
    type: String,
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

// Animation control with performance optimization for limited data
const animationSpeed = ref(0.8); // Slightly faster since we have fewer items
const autoScrollInterval = ref(null);

// Process ads data with performance optimization and random selection
const adsArray = computed(() => {
  if (!ads?.results) return [];
  const results = Array.isArray(ads.results) ? ads.results : [];
  
  // Limit to maximum 10 random recent posts for optimal performance
  const MAX_ADS = 10;
  
  if (results.length <= MAX_ADS) {
    return results;
  }
  
  // Randomly select 10 posts from the available results
  const shuffled = [...results].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, MAX_ADS);
});

// Create optimized duplicates for smooth continuous scrolling with limited data
const displayedAds = computed(() => {
  if (adsArray.value.length === 0) return [];
  
  // Since we're limiting to max 10 ads, we need more duplicates for smooth scrolling
  const duplicateCount = adsArray.value.length <= 5 ? 6 : 
                        adsArray.value.length <= 8 ? 4 : 3;
  
  const duplicatedAds = [];
  for (let i = 0; i < duplicateCount; i++) {
    duplicatedAds.push(...adsArray.value);
  }
  
  return duplicatedAds;
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
      }      // Safety check to ensure we don't scroll beyond the content
      const maxScroll = totalWidth.value - viewportWidth.value;
      if (scrollPosition.value > maxScroll) {
        scrollPosition.value = maxScroll - 10; // Keep slightly before the end
      }
    }, 40); // Optimized interval for smoother animation with limited data
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

  viewportWidth.value = carouselRef.value.clientWidth;  // Adjust card width based on screen size - performance optimized sizes
  if (window.innerWidth < 640) {
    // Mobile: show 2 cards
    cardWidth.value = viewportWidth.value * 0.45;
    animationSpeed.value = 0.6; // Optimized for mobile with limited data
  } else if (window.innerWidth < 1024) {
    // Tablet: show 3 cards
    cardWidth.value = viewportWidth.value * 0.3;
    animationSpeed.value = 0.8; // Balanced speed for tablets
  } else {
    // Desktop: show 4-5 cards
    cardWidth.value = viewportWidth.value * 0.21;
    animationSpeed.value = 1.0; // Slightly faster for desktop with limited data
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
