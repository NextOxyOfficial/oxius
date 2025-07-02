<template>
  <div class="relative overflow-hidden rounded-xl shadow-sm">
    <!-- Loading State -->
    <div v-if="isLoading" class="rounded-xl overflow-hidden relative pb-[25%] lg:pb-[20%] bg-slate-200 dark:bg-slate-800 animate-pulse">
      <div class="absolute inset-0 flex items-center justify-center">
        <UIcon name="i-heroicons-photo" class="size-16 text-slate-400 dark:text-slate-600" />
      </div>
    </div>
    
    <!-- Error State -->
    <div v-else-if="error" class="rounded-xl overflow-hidden relative pb-[25%] lg:pb-[20%] bg-slate-200 dark:bg-slate-800">
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <UIcon name="i-heroicons-exclamation-triangle" class="size-16 text-amber-500 mb-3" />
        <p class="text-base text-slate-600 dark:text-slate-400">{{ error }}</p>
      </div>
    </div>
    
    <!-- No Banners State -->
    <div v-else-if="!banners.length" class="rounded-xl overflow-hidden relative pb-[25%] lg:pb-[20%] bg-slate-200 dark:bg-slate-800">
      <div class="absolute inset-0 flex flex-col items-center justify-center">
        <UIcon name="i-heroicons-photo" class="size-16 text-slate-400 dark:text-slate-600 mb-3" />
        <p class="text-base text-slate-600 dark:text-slate-400">No desktop banners available</p>
      </div>
    </div>
    
    <!-- Desktop Banner Slider -->
    <div
      v-else
      class="relative overflow-hidden rounded-xl shadow-sm desktop-slider"
      ref="sliderContainer"
      @mouseenter="handleSliderHover(true)"
      @mouseleave="handleSliderHover(false)"
    >
      <!-- Background pattern for premium look -->
      <div class="absolute inset-0 bg-gradient-to-r from-slate-900/5 to-slate-900/5 dark:from-slate-950/20 dark:to-slate-950/10 backdrop-blur-[1px] z-0"></div>
      
      <!-- Desktop optimized aspect ratio container -->
      <div class="rounded-xl overflow-hidden relative pb-[25%] lg:pb-[20%]">
        <div
          v-for="(banner, index) in banners"
          :key="index"
          class="absolute inset-0 transition-all duration-700 ease-out transform"
          :class="{
            'opacity-100 translate-x-0 scale-100': index === currentSlide,
            'opacity-0 translate-x-full scale-95': index > currentSlide,
            'opacity-0 -translate-x-full scale-95': index < currentSlide,
          }"
        >
          <!-- Banner Link Wrapper -->
          <a 
            v-if="banner.link" 
            :href="banner.link" 
            class="absolute inset-0 z-10 group"
            target="_blank"
            @click="trackBannerClick(banner)"
          >
            <!-- Hover overlay for desktop -->
            <div class="absolute inset-0 bg-black/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
          </a>
          
          <!-- Banner Image -->
          <img
            v-if="banner.image"
            :src="banner.image"
            :alt="banner.title || `Desktop Slide ${index + 1}`"
            class="w-full h-full object-cover transform transition-transform duration-700 hover:scale-105"
            loading="lazy"
          />
          
          <!-- Banner Title Overlay with enhanced styling -->
          <div 
            v-if="banner.title" 
            class="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black/80 via-black/50 to-transparent text-white z-5"
          >
            <h3 class="text-2xl font-bold mb-2">{{ banner.title }}</h3>
            <div class="w-12 h-1 bg-white/60 rounded-full"></div>
          </div>
        </div>
      </div>

      <!-- Navigation arrows with enhanced styling -->
      <button
        v-if="banners.length > 1"
        @click="prevSlide"
        class="absolute left-4 top-1/2 -translate-y-1/2 bg-gradient-to-r from-emerald-600/90 to-blue-600/90 backdrop-blur-md hover:from-emerald-600 hover:to-blue-600 rounded-full p-3 z-20 transition-all duration-300 shadow-lg opacity-0 transform -translate-x-3 hover:scale-110"
        :class="{ 'opacity-100 translate-x-0': isHovering }"
        aria-label="Previous slide"
      >
        <ChevronLeft class="h-6 w-6 text-white" />
      </button>

      <button
        v-if="banners.length > 1"
        @click="nextSlide"
        class="absolute right-4 top-1/2 -translate-y-1/2 bg-gradient-to-r from-emerald-600/90 to-blue-600/90 backdrop-blur-md hover:from-emerald-600 hover:to-blue-600 rounded-full p-3 z-20 transition-all duration-300 shadow-lg opacity-0 transform translate-x-3 hover:scale-110"
        :class="{ 'opacity-100 translate-x-0': isHovering }"
        aria-label="Next slide"
      >
        <ChevronRight class="h-6 w-6 text-white" />
      </button>

      <!-- Enhanced slider indicators -->
      <div
        v-if="banners.length > 1"
        class="absolute bottom-6 left-1/2 -translate-x-1/2 flex space-x-3 z-20 bg-black/30 backdrop-blur-md px-4 py-2 rounded-full"
      >
        <button
          v-for="(_, index) in banners"
          :key="index"
          @click="goToSlide(index)"
          class="w-3 h-3 rounded-full transition-all duration-300 relative hover:scale-125"
          :class="{
            'bg-white scale-125 shadow-lg': index === currentSlide,
            'bg-white/50 hover:bg-white/70': index !== currentSlide,
          }"
          :aria-label="`Go to desktop slide ${index + 1}`"
        >
          <!-- Active indicator ring -->
          <div
            v-if="index === currentSlide"
            class="absolute inset-0 rounded-full border-2 border-white/50 scale-150"
          ></div>
        </button>
      </div>

      <!-- Auto-play progress indicator -->
      <div
        v-if="banners.length > 1 && autoplayEnabled && isHovering"
        class="absolute top-4 right-4 z-20"
      >
        <div class="bg-black/30 backdrop-blur-md rounded-full p-2">
          <div class="w-8 h-8 relative">
            <svg class="w-8 h-8 transform -rotate-90" viewBox="0 0 32 32">
              <circle
                cx="16"
                cy="16"
                r="14"
                stroke="currentColor"
                stroke-width="2"
                fill="none"
                class="text-white/30"
              />
              <circle
                cx="16"
                cy="16"
                r="14"
                stroke="currentColor"
                stroke-width="2"
                fill="none"
                class="text-white transition-all duration-100"
                :stroke-dasharray="87.96"
                :stroke-dashoffset="87.96 - (87.96 * progressWidth / 100)"
              />
            </svg>
            <div class="absolute inset-0 flex items-center justify-center">
              <div class="w-1 h-1 bg-white rounded-full"></div>
            </div>
          </div>
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
    default: 6000
  },
  autoplayEnabled: {
    type: Boolean,
    default: true
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
const progressWidth = ref(0);
const progressIntervalId = ref(null);

// Fetch desktop banners from API
async function fetchBanners() {
  try {
    isLoading.value = true;
    error.value = null;
    
    const res = await get("/eshop-banner/?device_type=desktop");
    banners.value = res.data;
    
    // Start the slider interval only if there are multiple banners
    if (banners.value.length > 1 && props.autoplayEnabled) {
      startSliderInterval();
    }
  } catch (err) {
    console.error("Error fetching desktop banners:", err);
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
    
    // Progress animation
    progressIntervalId.value = setInterval(() => {
      progressWidth.value += (100 / (props.autoplayInterval / 100));
      if (progressWidth.value >= 100) {
        progressWidth.value = 0;
      }
    }, 100);
    
    // Slide transition
    intervalId.value = setInterval(() => {
      nextSlide();
    }, props.autoplayInterval);
  }
}

// Handle slider hover
function handleSliderHover(isHover) {
  isHovering.value = isHover;
  
  if (isHover) {
    // Pause auto-play on hover
    clearInterval(intervalId.value);
    clearInterval(progressIntervalId.value);
  } else {
    // Resume auto-play when not hovering
    if (props.autoplayEnabled && banners.value.length > 1) {
      startSliderInterval();
    }
  }
}

// Track banner clicks for analytics
function trackBannerClick(banner) {
  // You can add analytics tracking here
  console.log(`Desktop banner clicked: ${banner.title || 'Untitled'}`);
}

// Keyboard navigation
function handleKeydown(event) {
  if (banners.value.length <= 1) return;
  
  switch (event.key) {
    case 'ArrowLeft':
      event.preventDefault();
      prevSlide();
      break;
    case 'ArrowRight':
      event.preventDefault();
      nextSlide();
      break;
  }
}

// Lifecycle hooks
onMounted(() => {
  fetchBanners();
  
  // Add keyboard navigation
  if (process.client) {
    window.addEventListener('keydown', handleKeydown);
  }
});

onUnmounted(() => {
  clearInterval(intervalId.value);
  clearInterval(progressIntervalId.value);
  
  // Remove keyboard navigation
  if (process.client) {
    window.removeEventListener('keydown', handleKeydown);
  }
});
</script>

<style scoped>
/* Desktop-specific enhancements */
.desktop-slider {
  cursor: pointer;
}

.desktop-slider img {
  transition: transform 0.7s cubic-bezier(0.4, 0, 0.2, 1);
}

.desktop-slider:hover img {
  transform: scale(1.02);
}

/* Enhanced smooth transitions */
.desktop-slider .transition-all {
  transition: transform 0.7s cubic-bezier(0.4, 0, 0.2, 1), 
              opacity 0.7s cubic-bezier(0.4, 0, 0.2, 1),
              scale 0.7s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Button hover effects */
.desktop-slider button:hover {
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
}

/* Accessibility improvements */
@media (prefers-reduced-motion: reduce) {
  .desktop-slider .transition-all,
  .desktop-slider img {
    transition: none;
  }
}

/* Focus states for keyboard navigation */
.desktop-slider button:focus {
  outline: 2px solid #fff;
  outline-offset: 2px;
}
</style>
