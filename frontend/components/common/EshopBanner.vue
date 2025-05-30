<template>
  <div class="relative overflow-hidden rounded-xl shadow-sm">
    <!-- Loading State -->
    <div v-if="isLoading" class="rounded-xl overflow-hidden relative pb-[38%] md:pb-[25%] lg:pb-[22%] bg-slate-200 dark:bg-slate-800 animate-pulse">
      <div class="absolute inset-0 flex items-center justify-center">
        <UIcon name="i-heroicons-photo" class="size-12 text-slate-400 dark:text-slate-600" />
      </div>
    </div>
    
    <!-- Error State -->
    <div v-else-if="error" class="rounded-xl overflow-hidden relative pb-[38%] md:pb-[25%] lg:pb-[22%] bg-slate-200 dark:bg-slate-800">
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <UIcon name="i-heroicons-exclamation-triangle" class="size-12 text-amber-500 mb-2" />
        <p class="text-sm text-slate-600 dark:text-slate-400">{{ error }}</p>
      </div>
    </div>
    
    <!-- No Banners State -->
    <div v-else-if="!banners.length" class="rounded-xl overflow-hidden relative pb-[38%] md:pb-[25%] lg:pb-[22%] bg-slate-200 dark:bg-slate-800">
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <UIcon name="i-heroicons-photo" class="size-12 text-slate-400 dark:text-slate-600 mb-2" />
        <p class="text-sm text-slate-600 dark:text-slate-400">No banner images available</p>
      </div>
    </div>
    
    <!-- Banner Slider -->
    <div
      v-else
      class="relative overflow-hidden rounded-xl shadow-sm touch-slider"
      ref="sliderContainer"
      @mouseenter="handleSliderHover(true)"
      @mouseleave="handleSliderHover(false)"
      @touchstart="handleTouchStart"
      @touchmove="handleTouchMove"
      @touchend="handleTouchEnd"
    >
      <!-- Background pattern for premium look -->
      <div
        class="absolute inset-0 bg-gradient-to-r from-slate-900/5 to-slate-900/5 dark:from-slate-950/20 dark:to-slate-950/10 backdrop-blur-[1px] z-0"
      ></div>

      <!-- Mobile swipe indicator shown only on mobile when multiple banners -->
      <div
        v-if="banners.length > 1"
        class="md:hidden absolute top-1/2 left-0 right-0 -translate-y-1/2 flex justify-between px-3 z-20 opacity-60 pointer-events-none"
      >
        <div class="swipe-indicator swipe-indicator-left">
          <ChevronLeft class="h-8 w-8 text-white" />
        </div>
        <div class="swipe-indicator swipe-indicator-right">
          <ChevronRight class="h-8 w-8 text-white" />
        </div>
      </div>
      
      <!-- Aspect ratio container for rounded and consistent height -->
      <div
        class="rounded-xl overflow-hidden relative pb-[38%] md:pb-[25%] lg:pb-[22%]"
      >
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
          ></a>
          
          <!-- Banner Image -->
          <img
            v-if="banner.image"
            :src="banner.image"
            :alt="banner.title || `Slide ${index + 1}`"
            class="w-full h-full object-cover"
          />
          
          <!-- Banner Title Overlay (optional) -->
          <div 
            v-if="banner.title" 
            class="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/60 to-transparent text-white z-5"
          >
            <h3 class="text-lg font-semibold">{{ banner.title }}</h3>
          </div>
        </div>
      </div>

      <!-- Navigation arrows - hidden on mobile but visible on desktop on hover -->
      <button
        v-if="banners.length > 1"
        @click="prevSlide"
        class="hidden md:flex absolute left-3 top-1/2 -translate-y-1/2 bg-gradient-to-r from-emerald-600/80 to-blue-600/80 backdrop-blur-sm hover:from-emerald-600/90 hover:to-blue-600/90 rounded-full p-2 sm:p-3 z-20 transition-all duration-300 shadow-sm opacity-0 transform -translate-x-2"
        :class="{ 'opacity-100 translate-x-0': isHovering }"
        aria-label="Previous slide"
      >
        <ChevronLeft class="h-5 w-5 text-white" />
      </button>

      <button
        v-if="banners.length > 1"
        @click="nextSlide"
        class="hidden md:flex absolute right-3 top-1/2 -translate-y-1/2 bg-gradient-to-r from-emerald-600/80 to-blue-600/80 backdrop-blur-sm hover:from-emerald-600/90 hover:to-blue-600/90 rounded-full p-2 sm:p-3 z-20 transition-all duration-300 shadow-sm opacity-0 transform translate-x-2"
        :class="{ 'opacity-100 translate-x-0': isHovering }"
        aria-label="Next slide"
      >
        <ChevronRight class="h-5 w-5 text-white" />
      </button>

      <!-- Slider indicators - only shown when multiple banners -->
      <div
        v-if="banners.length > 1"
        class="absolute bottom-4 left-1/2 -translate-x-1/2 flex space-x-3 z-20 bg-black/20 backdrop-blur-md px-3 py-1.5 rounded-full"
      >
        <button
          v-for="(_, index) in banners"
          :key="index"
          @click="goToSlide(index)"
          class="w-2.5 h-2.5 rounded-full transition-all duration-300 relative"
          :class="{
            'bg-white scale-110': index === currentSlide,
            'bg-white/40 hover:bg-white/60': index !== currentSlide,
          }"
          :aria-label="`Go to slide ${index + 1}`"
        ></button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from "vue";
import { ChevronLeft, ChevronRight } from "lucide-vue-next";
const { get } = useApi();

// Define props
const props = defineProps({
  // Optional custom height based on device size
  customHeight: {
    type: Object,
    default: () => ({
      mobile: "38%",  // default mobile height (small screens)
      tablet: "25%",  // default tablet height (medium screens)
      desktop: "22%"  // default desktop height (large screens)
    })
  },
  // Optional custom endpoint to fetch banners from
  endpoint: {
    type: String,
    default: "/eshop-banner/"
  },
  // Optional autoplay interval in milliseconds
  autoplayInterval: {
    type: Number,
    default: 5000
  }
});

// Banner states
const banners = ref([]);
const isLoading = ref(true);
const error = ref(null);
const currentSlide = ref(0);
const intervalId = ref(null);
const sliderContainer = ref(null);
const isHovering = ref(false);
let touchStartX = 0;
let touchEndX = 0;
let isHandlingTouch = false;

// Fetch banners from API
async function fetchBanners() {
  try {
    isLoading.value = true;
    error.value = null;
    
    const res = await get(props.endpoint);
    banners.value = res.data;
    
    // Start the slider interval only if there are multiple banners
    if (banners.value.length > 1) {
      startSliderInterval();
    }
  } catch (err) {
    console.error("Error fetching banners:", err);
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
  if (banners.value.length > 1) {
    startSliderInterval();
  }
}

function startSliderInterval() {
  if (banners.value.length > 1) {
    intervalId.value = setInterval(() => {
      if (!isHandlingTouch) {
        nextSlide();
      }
    }, props.autoplayInterval);
  }
}

// Touch event handlers
function handleTouchStart(e) {
  isHandlingTouch = true;
  touchStartX = e.touches[0].clientX;
}

function handleTouchMove(e) {
  if (!isHandlingTouch) return;
  touchEndX = e.touches[0].clientX;

  // Add visual feedback during swiping
  const swipeDiff = touchEndX - touchStartX;
  if (Math.abs(swipeDiff) > 30) {
    e.preventDefault(); // Prevent default only if significant swipe detected

    // Add visual feedback with classes
    if (sliderContainer.value) {
      sliderContainer.value.classList.remove("swiping-left", "swiping-right");
      if (swipeDiff > 0) {
        sliderContainer.value.classList.add("swiping-right");
      } else {
        sliderContainer.value.classList.add("swiping-left");
      }
    }
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
  }

  // Remove swiping classes
  if (sliderContainer.value) {
    sliderContainer.value.classList.remove("swiping-left", "swiping-right");
  }

  isHandlingTouch = false;
  resetSliderInterval();
}

// Handle slider hover
function handleSliderHover(isHover) {
  isHovering.value = isHover;
}

// Lifecycle hooks
onMounted(() => {
  fetchBanners();
});

onUnmounted(() => {
  clearInterval(intervalId.value);
  // Remove touch event listeners
  if (sliderContainer.value) {
    sliderContainer.value.removeEventListener("touchstart", handleTouchStart);
    sliderContainer.value.removeEventListener("touchmove", handleTouchMove);
    sliderContainer.value.removeEventListener("touchend", handleTouchEnd);
  }
});
</script>

<style scoped>
/* Touch swipe animation styles */
.swiping-left {
  transform: translateX(-5px) !important;
  transition: transform 0.2s ease-out !important;
}

.swiping-right {
  transform: translateX(5px) !important;
  transition: transform 0.2s ease-out !important;
}

/* Swipe indicator animation */
.swipe-indicator {
  opacity: 0;
  transition: opacity 0.3s;
}

.touch-slider:active .swipe-indicator {
  opacity: 1;
}
</style>
