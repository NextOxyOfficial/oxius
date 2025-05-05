<template>
  <div class="mb-3">
    <!-- Main content area with enhanced premium image display -->
    <div class="relative overflow-hidden rounded-xl shadow-sm group transform transition-all duration-300 hover:shadow-sm hover:-translate-y-0.5">
      <div
        class="relative w-full overflow-hidden transition-all duration-700 max-h-[520px] sm:max-h-[540px] flex items-center justify-center"
      >
        <!-- Main image with premium hover effects -->
        <img
          :src="post.post_media[activeIndex].image"
          alt="Media"
          class="w-auto h-auto max-h-[520px] sm:max-h-[540px] max-w-full object-contain transition-all duration-700 ease-out group-hover:brightness-[1.02]"
        />

  

        <!-- Glassmorphic image counter indicator -->
        <div class="absolute bottom-3.5 right-3.5 px-3 py-1.5 bg-black/25 backdrop-blur-md rounded-full text-white text-xs font-semibold flex items-center space-x-2 shadow-sm border border-white/10 transform transition-all duration-300 group-hover:scale-105">
          <div class="relative w-3 h-3">
            <div class="absolute inset-0 bg-blue-400/50 rounded-full animate-ping opacity-75"></div>
            <div class="absolute inset-0 bg-blue-500 rounded-full"></div>
          </div>
          <div class="flex items-center">
            <span>{{ activeIndex + 1 }}</span>
            <span class="mx-1 text-white/70">/</span>
            <span>{{ post.post_media.length }}</span>
          </div>
        </div>
        
        <!-- Download button with premium styling - kept only on main image -->
        <button 
          @click.stop="downloadImage(post.post_media[activeIndex].image)"
          class="absolute top-3.5 right-3.5 p-2 rounded-full bg-black/30 backdrop-blur-md text-white opacity-0 group-hover:opacity-100 hover:bg-black/50 transition-all duration-300 shadow-lg border border-white/10"
          title="Download image"
        >
          <UIcon name="i-heroicons-arrow-down-tray" class="w-4 h-4" />
        </button>
        
        <!-- Navigation arrows for quick navigation on main image -->
        <button
          v-if="post.post_media.length > 1"
          @click.stop="navigateMedia('prev')"
          class="absolute left-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md hover:bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all duration-300 transform hover:-translate-x-0.5 border border-white/10 shadow-lg"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5 text-white">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
          </svg>
        </button>
        
        <button
          v-if="post.post_media.length > 1"
          @click.stop="navigateMedia('next')"
          class="absolute right-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md hover:bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all duration-300 transform hover:translate-x-0.5 border border-white/10 shadow-lg"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5 text-white">
            <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Enhanced thumbnail gallery with premium styling - only show if there's more than one media item -->
    <div v-if="post.post_media.length > 1" class="relative px-0.5 mt-5">
      <!-- Premium Gallery Heading with glass effect -->
      <div class="flex items-center px-4 justify-between mb-4 relative">
        <div class="absolute -inset-2 bg-gradient-to-r from-purple-500/5 via-blue-500/10 to-emerald-500/5 rounded-lg blur-xl opacity-50 dark:opacity-30"></div>
        
        <h3 class="font-medium text-slate-800 dark:text-slate-100 flex items-center space-x-2 relative backdrop-blur-sm">
          <span class="inline-flex items-center justify-center w-6 h-6 bg-gradient-to-br from-blue-500 to-indigo-600 text-white rounded-md shadow-sm shadow-blue-500/20 dark:shadow-blue-400/10">
            <UIcon name="i-heroicons-photo" class="w-3.5 h-3.5" />
          </span>
          <span class="relative">
            Gallery
            <span class="absolute -bottom-1 left-0 h-0.5 w-full bg-gradient-to-r from-blue-500 to-indigo-600 rounded opacity-70"></span>
          </span>
          <span class="text-xs flex items-center px-2 py-0.5 bg-gradient-to-r from-blue-500/10 to-indigo-500/10 dark:from-blue-900/30 dark:to-indigo-900/30 rounded-full text-blue-700 dark:text-blue-300 font-medium shadow-sm">
            {{ post.post_media.length }} items
          </span>
        </h3>
        
        <!-- Media counter with luxury styling -->
        <div class="relative group">
          <div class="absolute -inset-2 bg-gradient-to-r from-blue-500/20 to-indigo-500/20 rounded-lg blur opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
          <div class="px-3 py-1.5 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-slate-800 dark:to-slate-800/90 rounded-lg text-xs font-medium text-blue-700 dark:text-blue-300 border border-blue-100/50 dark:border-blue-800/50 shadow-sm relative group-hover:shadow-blue-500/10 dark:shadow-blue-800/5 group-hover:scale-[1.02] transition-all duration-300">
            <span class="flex items-center space-x-1.5">
              <UIcon name="i-heroicons-viewfinder-circle" class="w-3.5 h-3.5 text-blue-500 dark:text-blue-400 animate-pulse" />
              <span class="relative">
                <span class="opacity-0 absolute top-0 -translate-y-full text-[10px] text-blue-500 dark:text-blue-400 font-normal whitespace-nowrap bg-white dark:bg-slate-800 px-1.5 py-0.5 rounded shadow-sm border border-blue-100/70 dark:border-blue-900/50 group-hover:opacity-100 transition-opacity duration-300 left-1/2 -translate-x-1/2">Current position</span>
                {{ activeIndex + 1 }}
                <span class="text-blue-400/80 dark:text-blue-500/70 font-normal mx-0.5">/</span>
                {{ post.post_media.length }}
              </span>
            </span>
          </div>
        </div>
      </div>
      
      <!-- Left navigation arrow with premium glass styling -->
      <button
        v-show="canScrollLeft"
        @click="scrollThumbnails('left')"
        class="absolute -left-2.5 top-1/2 -translate-y-1/2 z-10 bg-gradient-to-br from-white/80 to-white/40 dark:from-slate-800/90 dark:to-slate-900/80 text-slate-700 dark:text-slate-200 rounded-full p-2 shadow-sm border border-white/30 dark:border-white/5 transition-all duration-300 hover:-translate-x-0.5 hover:shadow-blue-500/10 backdrop-blur-md"
        aria-label="Previous thumbnails"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2.5"
          stroke="currentColor"
          class="w-4 h-4"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M15.75 19.5 8.25 12l7.5-7.5"
          />
        </svg>
        <div class="absolute inset-0 bg-gradient-to-r from-blue-500/10 to-indigo-500/10 rounded-full opacity-0 hover:opacity-100 transition-opacity duration-300"></div>
      </button>

      <!-- Premium thumbnail container with luxury glass effect -->
      <div class="relative rounded-xl overflow-hidden bg-gradient-to-br from-white/80 via-slate-50/90 to-white/70 dark:from-slate-800/80 dark:via-slate-800/40 dark:to-slate-900/60 backdrop-blur-sm shadow-lg border border-white/50 dark:border-slate-700/50 p-3 transition-all duration-500 hover:shadow-blue-500/5 dark:hover:shadow-blue-500/5">
        <!-- Premium light beam effects -->
        <div class="absolute -inset-2 bg-grid opacity-10 dark:opacity-5 pointer-events-none"></div>
        <div class="absolute -inset-2 bg-gradient-conic opacity-5 dark:opacity-10 mix-blend-overlay pointer-events-none"></div>
        
        <div
          class="absolute left-0 top-0 bottom-0 w-16 bg-gradient-to-r from-white/90 dark:from-slate-900/90 to-transparent z-[1] pointer-events-none backdrop-blur-md"
          v-if="canScrollLeft"
        ></div>

        <div
          class="absolute right-0 top-0 bottom-0 w-16 bg-gradient-to-l from-white/90 dark:from-slate-900/90 to-transparent z-[1] pointer-events-none backdrop-blur-md"
          v-if="canScrollRight"
        ></div>

        <div
          ref="thumbnailsContainer"
          class="grid grid-cols-5 md:grid-cols-7 gap-2.5 overflow-x-auto scrollbar-hide scroll-smooth px-1 py-1 relative"
          @scroll="updateScrollIndicators"
        >
          <div
            v-for="(media, mediaIndex) in post.post_media"
            :key="media.id"
            class="relative cursor-pointer overflow-hidden h-[72px] sm:h-[76px] rounded-lg transition-all duration-500 hover:-translate-y-1 hover:scale-[1.02] group/thumb"
            :class="{
              'ring-2 ring-blue-500/70 dark:ring-blue-500/80 shadow-lg scale-[1.03] z-10 premium-thumb-active':
                activeIndex === mediaIndex,
              'opacity-90 hover:opacity-100 hover:shadow-sm ring-1 ring-white/70 dark:ring-slate-700/90':
                activeIndex !== mediaIndex,
            }"
            @click="setActiveMedia(mediaIndex)"
          >
            <!-- Fancy gradient border for non-active items -->
            <div 
              v-if="activeIndex !== mediaIndex"
              class="absolute inset-0 rounded-lg p-[1px] opacity-0 group-hover/thumb:opacity-100 transition-opacity duration-300"
            >
              <div class="absolute inset-0 rounded-lg border border-blue-200 dark:border-blue-900/40 opacity-0 group-hover/thumb:opacity-100 transition-all duration-300"></div>
            </div>

            <div class="h-full w-full overflow-hidden rounded-md">
              <img
                :src="media.image"
                :alt="`Media ${mediaIndex + 1}`"
                class="h-full w-full object-cover transition-transform duration-700 group-hover/thumb:scale-110"
              />
            </div>

            <!-- Premium active thumbnail indicator with advanced animation -->
            <div
              v-if="activeIndex === mediaIndex"
              class="absolute bottom-0 left-0 right-0 h-1.5 bg-gradient-to-r from-blue-400 via-indigo-500 to-blue-600 shadow-glow-premium"
            >
              <div class="absolute inset-0 bg-shimmer"></div>
            </div>

            <!-- Premium hover overlay with advanced glassmorphism -->
            <div class="absolute inset-0 opacity-0 group-hover/thumb:opacity-100 transition-all duration-500">
              <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent"></div>
              <div class="absolute inset-0 bg-grid opacity-10 mix-blend-overlay"></div>
            </div>

            <!-- Premium media counter badge on thumbnails -->
            <div 
              class="absolute top-1 right-1 px-1.5 py-0.5 bg-black/50 backdrop-blur-md rounded-full text-white text-[10px] font-medium opacity-0 group-hover/thumb:opacity-100 transition-opacity duration-300 shadow-lg border border-white/10 flex items-center"
            >
              <span class="relative z-10">{{ mediaIndex + 1 }}</span>
              <div class="absolute inset-0 bg-gradient-to-r from-blue-600/80 to-indigo-600/80 rounded-full opacity-0 group-hover/thumb:opacity-100 transition-all duration-300 z-0"></div>
            </div>
            
            <!-- Premium selection indicator -->
            <div
              v-if="activeIndex === mediaIndex" 
              class="absolute top-1 left-1 w-4 h-4 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center shadow-sm"
            >
              <span class="text-white text-[8px]">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-2.5 h-2.5">
                  <path fill-rule="evenodd" d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z" clip-rule="evenodd" />
                </svg>
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right navigation arrow with premium glass styling -->
      <button
        v-show="canScrollRight"
        @click="scrollThumbnails('right')"
        class="absolute -right-2.5 top-1/2 -translate-y-1/2 z-10 bg-gradient-to-br from-white/80 to-white/40 dark:from-slate-800/90 dark:to-slate-900/80 text-slate-700 dark:text-slate-200 rounded-full p-2 shadow-sm border border-white/30 dark:border-white/5 transition-all duration-300 hover:translate-x-0.5 hover:shadow-blue-500/10 backdrop-blur-md"
        aria-label="Next thumbnails"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2.5"
          stroke="currentColor"
          class="w-4 h-4"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="m8.25 4.5 7.5 7.5-7.5 7.5"
          />
        </svg>
        <div class="absolute inset-0 bg-gradient-to-r from-blue-500/10 to-indigo-500/10 rounded-full opacity-0 hover:opacity-100 transition-opacity duration-300"></div>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, watch } from "vue";

const props = defineProps({
  post: {
    type: Object,
    required: true,
  },
});

defineEmits(["open-media"]);

// References and state
const activeIndex = ref(0);
const thumbnailsContainer = ref(null);
const isMobile = ref(false);
const canScrollLeft = ref(false);
const canScrollRight = ref(false);

// Set the active media
const setActiveMedia = (index) => {
  activeIndex.value = index;

  // Ensure the active thumb is visible by scrolling to it
  nextTick(() => {
    if (!thumbnailsContainer.value) return;

    const thumbnailElements = thumbnailsContainer.value.children;
    if (thumbnailElements && thumbnailElements[index]) {
      thumbnailElements[index].scrollIntoView({
        behavior: "smooth",
        block: "nearest",
        inline: "center",
      });
    }
  });
};

// Navigate through media directly from main image
const navigateMedia = (direction) => {
  const totalMedia = props.post.post_media.length;
  if (totalMedia <= 1) return;
  
  if (direction === 'next') {
    activeIndex.value = (activeIndex.value + 1) % totalMedia;
  } else {
    activeIndex.value = (activeIndex.value - 1 + totalMedia) % totalMedia;
  }
};

// Function to download an image
const downloadImage = (url) => {
  if (!url) return;
  
  // Create a temporary link element
  const link = document.createElement('a');
  link.href = url;
  link.download = url.split('/').pop() || 'image.jpg';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

// Handle thumbnail scrolling with enhanced smooth behavior
const scrollThumbnails = (direction) => {
  if (!thumbnailsContainer.value) return;

  const container = thumbnailsContainer.value;
  const scrollAmount = direction === "left"
    ? -1 * container.clientWidth * 0.75
    : container.clientWidth * 0.75;

  container.scrollBy({
    left: scrollAmount,
    behavior: "smooth",
  });

  // Update scroll indicators after animation completes
  setTimeout(() => {
    updateScrollIndicators();
  }, 300);
};

// Update scroll indicators
const updateScrollIndicators = () => {
  if (!thumbnailsContainer.value) return;

  const container = thumbnailsContainer.value;
  canScrollLeft.value = container.scrollLeft > 5; // Small buffer
  canScrollRight.value = container.scrollLeft < container.scrollWidth - container.clientWidth - 5; // 5px buffer
};

// Check if the device is mobile
const checkMobile = () => {
  isMobile.value = window.innerWidth < 640; // sm breakpoint in Tailwind
};

// Lifecycle hooks
onMounted(() => {
  checkMobile();
  window.addEventListener("resize", () => {
    checkMobile();
    updateScrollIndicators();
  });

  // Initialize scroll indicators
  updateScrollIndicators();

  if (thumbnailsContainer.value) {
    thumbnailsContainer.value.addEventListener(
      "scroll",
      updateScrollIndicators
    );
  }

  // Initial check for right scroll indicator
  nextTick(() => {
    if (thumbnailsContainer.value) {
      canScrollRight.value =
        thumbnailsContainer.value.scrollWidth >
        thumbnailsContainer.value.clientWidth;
    }
  });
});

// Watch for post media changes to update scroll indicators
watch(
  () => props.post.post_media,
  () => {
    nextTick(updateScrollIndicators);
  },
  { deep: true }
);
</script>

<style scoped>
/* Hide scrollbar but maintain functionality */
.scrollbar-hide {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}
.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Opera */
}

/* Premium shadow glow for active thumbnails */
.shadow-glow {
  box-shadow: 0 0 8px rgba(59, 130, 246, 0.5);
}

/* Enhanced premium shadow glow for active thumbnails */
.shadow-glow-premium {
  box-shadow: 0 0 12px rgba(79, 70, 229, 0.6);
}

/* Premium effect for active thumbnail */
.premium-thumb-active {
  animation: pulseGlow 2s infinite;
}

/* Background radial gradient overlay */
.bg-radial-gradient {
  background: radial-gradient(circle at center, rgba(59, 130, 246, 0.05), transparent 70%);
}

/* Vignette effect */
.bg-vignette-gradient {
  background: radial-gradient(ellipse at center, transparent 60%, rgba(0, 0, 0, 0.3) 100%);
}

/* Gradient conic background */
.bg-gradient-conic {
  background-image: conic-gradient(
    from 230deg at 50% 50%,
    #4f46e5 0deg,
    #3b82f6 25deg,
    #06b6d4 90deg,
    #3b82f6 180deg,
    #8b5cf6 250deg,
    #4f46e5 360deg
  );
}

/* Dot grid pattern overlay */
.bg-grid {
  background-image: 
    radial-gradient(circle, currentColor 1px, transparent 1px);
  background-size: 20px 20px;
}

/* Shimmer effect for active thumbnail indicator */
.bg-shimmer {
  background-image: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0) 0%,
    rgba(255, 255, 255, 0.8) 50%,
    rgba(255, 255, 255, 0) 100%
  );
  background-size: 200% 100%;
  animation: shimmer 2s infinite;
}

/* Premium animations for enhanced UX */
@keyframes pulseGlow {
  0% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.6);
  }
  70% {
    box-shadow: 0 0 0 6px rgba(59, 130, 246, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0);
  }
}

@keyframes fadeZoomIn {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}
</style>
