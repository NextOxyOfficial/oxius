<template>
  <div class="relative overflow-hidden rounded-lg shadow-sm">
    <!-- Loading State -->
    <div v-if="isLoading" class="rounded-lg overflow-hidden relative pb-[50%] bg-slate-200 dark:bg-slate-800 animate-pulse">
      <div class="absolute inset-0 flex items-center justify-center">
        <UIcon name="i-heroicons-photo" class="size-10 text-slate-400 dark:text-slate-600" />
      </div>
    </div>
    
    <!-- Error State -->
    <div v-else-if="error" class="rounded-lg overflow-hidden relative pb-[50%] bg-slate-200 dark:bg-slate-800">
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <UIcon name="i-heroicons-exclamation-triangle" class="size-10 text-amber-500 mb-2" />
        <p class="text-xs text-slate-600 dark:text-slate-400 text-center px-2">{{ error }}</p>
      </div>
    </div>
    
    <!-- No Banners State -->
    <div v-else-if="!banners.length" class="rounded-lg overflow-hidden relative pb-[50%] bg-slate-200 dark:bg-slate-800">
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <UIcon name="i-heroicons-photo" class="size-10 text-slate-400 dark:text-slate-600 mb-2" />
        <p class="text-xs text-slate-600 dark:text-slate-400">No mobile banners available</p>
      </div>
    </div>
    
    <!-- Mobile Banner Slider -->
    <div
      v-else
      class="relative overflow-hidden rounded-lg shadow-sm mobile-slider"
      ref="sliderContainer"
      @touchstart="handleTouchStart"
      @touchmove="handleTouchMove"
      @touchend="handleTouchEnd"
    >
      <!-- Mobile optimized aspect ratio container -->
      <div class="rounded-lg overflow-hidden relative pb-[50%]">
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
          <!-- Banner Link Wrapper -->
          <a 
            v-if="banner.link" 
            :href="banner.link" 
            class="absolute inset-0 z-10"
            target="_blank"
            @click="trackBannerClick(banner)"
          ></a>
          
          <!-- Banner Image -->
          <img
            v-if="banner.image"
            :src="banner.image"
            :alt="banner.title || `Mobile Slide ${index + 1}`"
            class="w-full h-full object-cover"
            loading="lazy"
          />
          
          <!-- Banner Title Overlay (optional, smaller for mobile) -->
          <div 
            v-if="banner.title" 
            class="absolute bottom-0 left-0 right-0 p-2 bg-gradient-to-t from-black/70 to-transparent text-white z-5"
          >
            <h3 class="text-sm font-medium truncate">{{ banner.title }}</h3>
          </div>
        </div>
      </div>

      <!-- Mobile swipe indicators (dots) - only shown when multiple banners -->
      <div
        v-if="banners.length > 1"
        class="absolute bottom-2 left-1/2 -translate-x-1/2 flex space-x-2 z-20 bg-black/30 backdrop-blur-sm px-2 py-1 rounded-full"
      >
        <button
          v-for="(_, index) in banners"
          :key="index"
          @click="goToSlide(index)"
          class="w-2 h-2 rounded-full transition-all duration-300"
          :class="{
            'bg-white scale-110': index === currentSlide,
            'bg-white/50': index !== currentSlide,
          }"
          :aria-label="`Go to mobile slide ${index + 1}`"
        ></button>
      </div>

      <!-- Progress bar indicator for auto-play -->
      <div
        v-if="banners.length > 1 && autoplayEnabled"
        class="absolute bottom-0 left-0 right-0 h-0.5 bg-white/20 z-20"
      >
        <div
          class="h-full bg-white transition-all duration-100 ease-linear"
          :style="{ width: `${progressWidth}%` }"
        ></div>
      </div>

      <!-- Swipe hint for first-time users -->
      <div
        v-if="showSwipeHint && banners.length > 1"
        class="absolute inset-0 bg-black/10 flex items-center justify-center z-30 pointer-events-none"
      >
        <div class="bg-white/90 rounded-lg px-3 py-2 flex items-center space-x-2 animate-pulse">
          <ChevronLeft class="h-4 w-4 text-gray-600" />
          <span class="text-xs text-gray-700 font-medium">Swipe to see more</span>
          <ChevronRight class="h-4 w-4 text-gray-600" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from "vue";
import { ChevronLeft, ChevronRight } from "lucide-vue-next";
const { get } = useApi();

// Define props
const props = defineProps({
  // Auto-play settings
  autoplayInterval: {
    type: Number,
    default: 4000
  },
  autoplayEnabled: {
    type: Boolean,
    default: true
  },
  // Show swipe hint for new users
  showSwipeHint: {
    type: Boolean,
    default: false
  }
});

// Banner states
const banners = ref([]);
const isLoading = ref(true);
const error = ref(null);
const currentSlide = ref(0);
const intervalId = ref(null);
const sliderContainer = ref(null);
const progressWidth = ref(0);
const progressIntervalId = ref(null);

// Touch handling
let touchStartX = 0;
let touchEndX = 0;
let isHandlingTouch = false;

// Progress bar calculation
const currentProgress = computed(() => {
  if (!props.autoplayEnabled || banners.value.length <= 1) return 0;
  return progressWidth.value;
});

// Fetch mobile banners from API
async function fetchBanners() {
  try {
    isLoading.value = true;
    error.value = null;
    
    const res = await get("/eshop-banner/mobile/");
    banners.value = res.data;
    
    // Start the slider interval only if there are multiple banners
    if (banners.value.length > 1 && props.autoplayEnabled) {
      startSliderInterval();
    }
  } catch (err) {
    console.error("Error fetching mobile banners:", err);
    error.value = "Could not load banners. Please try again later.";
  } finally {
    isLoading.value = false;
  }
}

// Banner slider functions
function nextSlide() {
  currentSlide.value = (currentSlide.value + 1) % banners.value.length;
  resetSliderInterval();
}

function prevSlide() {
  currentSlide.value = (currentSlide.value - 1 + banners.value.length) % banners.value.length;
  resetSliderInterval();
}

function goToSlide(index) {
  currentSlide.value = index;
  resetSliderInterval();
}

function resetSliderInterval() {
  clearInterval(intervalId.value);
  clearInterval(progressIntervalId.value);
  progressWidth.value = 0;
  
  if (banners.value.length > 1 && props.autoplayEnabled) {
    startSliderInterval();
  }
}

function startSliderInterval() {
  if (banners.value.length > 1 && props.autoplayEnabled) {
    progressWidth.value = 0;
    
    // Progress bar animation
    progressIntervalId.value = setInterval(() => {
      progressWidth.value += (100 / (props.autoplayInterval / 100));
      if (progressWidth.value >= 100) {
        progressWidth.value = 0;
      }
    }, 100);
    
    // Slide transition
    intervalId.value = setInterval(() => {
      if (!isHandlingTouch) {
        nextSlide();
      }
    }, props.autoplayInterval);
  }
}

// Touch event handlers optimized for mobile
function handleTouchStart(e) {
  isHandlingTouch = true;
  touchStartX = e.touches[0].clientX;
  
  // Pause auto-play during touch
  clearInterval(intervalId.value);
  clearInterval(progressIntervalId.value);
}

function handleTouchMove(e) {
  if (!isHandlingTouch) return;
  touchEndX = e.touches[0].clientX;

  const swipeDiff = touchEndX - touchStartX;
  if (Math.abs(swipeDiff) > 20) {
    e.preventDefault(); // Prevent scrolling when swiping
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
  } else {
    // Resume auto-play if no significant swipe
    if (props.autoplayEnabled) {
      startSliderInterval();
    }
  }

  isHandlingTouch = false;
}

// Track banner clicks for analytics
function trackBannerClick(banner) {
  // TODO: Add analytics tracking here
}

// Lifecycle hooks
onMounted(() => {
  fetchBanners();
});

onUnmounted(() => {
  clearInterval(intervalId.value);
  clearInterval(progressIntervalId.value);
});
</script>

<style scoped>
/* Mobile-specific optimizations */
.mobile-slider {
  touch-action: pan-y pinch-zoom;
}

/* Smooth progress bar animation */
.mobile-slider .transition-all {
  transition: transform 0.5s cubic-bezier(0.4, 0, 0.2, 1), 
              opacity 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Enhanced touch feedback */
.mobile-slider:active {
  transform: scale(0.99);
  transition: transform 0.1s ease-out;
}

/* Accessibility improvements */
@media (prefers-reduced-motion: reduce) {
  .mobile-slider .transition-all {
    transition: none;
  }
}
</style>
