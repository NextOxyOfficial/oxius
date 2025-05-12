<template>
  <div class="mb-3">    <!-- Main content area -->
    <div class="relative overflow-hidden">
      <div
        class="relative w-full overflow-hidden min-h-[300px] max-h-[520px] sm:max-h-[540px] flex items-center justify-center"
      >
        <!-- Main image -->
        <img
          :src="post.post_media[activeIndex].image"
          alt="Media"
          class="w-auto h-auto max-h-[520px] sm:max-h-[540px] max-w-full object-contain"
        />

  

        <!-- Image counter indicator -->
        <div class="absolute bottom-3.5 right-3.5 px-3 py-1.5 bg-black/25 backdrop-blur-md rounded-full text-white text-xs font-semibold flex items-center space-x-2 shadow-xl border border-white/10">
          <div class="relative w-3 h-3">
            <div class="absolute inset-0 bg-blue-500 rounded-full"></div>
          </div>
          <div class="flex items-center">
            <span>{{ activeIndex + 1 }}</span>
            <span class="mx-1 text-white/70">/</span>
            <span>{{ post.post_media.length }}</span>
          </div>
        </div>
          <!-- Download button -->
        <button 
          @click.stop="downloadImage(post.post_media[activeIndex].image)"
          class="absolute top-3.5 right-3.5 p-2 rounded-full bg-black/30 backdrop-blur-md text-white shadow-lg border border-white/10"
          title="Download image"
        >
          <UIcon name="i-heroicons-arrow-down-tray" class="w-4 h-4" />
        </button>
        
        <!-- Navigation arrows -->
        <button
          v-if="post.post_media.length > 1"
          @click.stop="navigateMedia('prev')"
          class="absolute left-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md hover:bg-black/40 flex items-center justify-center border border-white/10 shadow-lg"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5 text-white">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
          </svg>
        </button>
        
        <button
          v-if="post.post_media.length > 1"
          @click.stop="navigateMedia('next')"
          class="absolute right-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md hover:bg-black/40 flex items-center justify-center border border-white/10 shadow-lg"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5 text-white">
            <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
          </svg>
        </button>
      </div>
    </div>    <!-- Thumbnail gallery - only show if there's more than one media item -->
    <div v-if="post.post_media.length > 1" class="relative px-0.5 mt-5">
      <!-- Gallery Heading -->
      <div class="flex items-center px-4 justify-between mb-4 relative">        
        <h3 class="font-medium text-slate-800 dark:text-slate-100 flex items-center space-x-2 relative">
          <span class="inline-flex items-center justify-center w-6 h-6 bg-blue-500 text-white rounded-md shadow-md">
            <UIcon name="i-heroicons-photo" class="w-3.5 h-3.5" />
          </span>
          <span>
            Gallery
          </span>
          <span class="text-xs flex items-center px-2 py-0.5 bg-blue-100 dark:bg-blue-900/30 rounded-full text-blue-700 dark:text-blue-300 font-medium">
            {{ post.post_media.length }} items
          </span>
        </h3>
        
        <!-- Media counter -->
        <div class="relative">
          <div class="px-3 py-1.5 bg-blue-50 dark:bg-slate-800 rounded-lg text-xs font-medium text-blue-700 dark:text-blue-300 border border-blue-100/50 dark:border-blue-800/50 shadow-md">
            <span class="flex items-center space-x-1.5">
              <UIcon name="i-heroicons-viewfinder-circle" class="w-3.5 h-3.5 text-blue-500 dark:text-blue-400" />
              <span>
                {{ activeIndex + 1 }}
                <span class="text-blue-400/80 dark:text-blue-500/70 font-normal mx-0.5">/</span>
                {{ post.post_media.length }}
              </span>
            </span>
          </div>
        </div>
      </div>
        <!-- Left navigation arrow -->
      <button
        v-show="canScrollLeft"
        @click="scrollThumbnails('left')"
        class="absolute -left-2.5 top-1/2 -translate-y-1/2 z-10 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 rounded-full p-2 shadow-md border border-gray-200 dark:border-gray-700"
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
      </button>

      <!-- Thumbnail container -->
      <div>
        
        <div
          class="absolute left-0 top-0 bottom-0 w-16 bg-gradient-to-r from-white/90 dark:from-slate-900/90 to-transparent z-[1] pointer-events-none backdrop-blur-md"
          v-if="canScrollLeft"
        ></div>

        <div
          class="absolute right-0 top-0 bottom-0 w-16 bg-gradient-to-l from-white/90 dark:from-slate-900/90 to-transparent z-[1] pointer-events-none backdrop-blur-md"
          v-if="canScrollRight"
        ></div>        <div
          ref="thumbnailsContainer"
          class="grid grid-cols-5 md:grid-cols-7 gap-2.5 overflow-x-auto scrollbar-hide scroll-smooth px-1 py-1 relative"
          @scroll="updateScrollIndicators"
        >
          <div
            v-for="(media, mediaIndex) in post.post_media"
            :key="media.id"
            class="relative cursor-pointer overflow-hidden h-[72px] sm:h-[76px] rounded-lg"
            :class="{
              'ring-2 ring-blue-500 dark:ring-blue-500 shadow-lg z-10':
                activeIndex === mediaIndex,
              'ring-1 ring-white/70 dark:ring-slate-700/90':
                activeIndex !== mediaIndex,
            }"
            @click="setActiveMedia(mediaIndex)"
          >
            <div class="h-full w-full overflow-hidden rounded-md">
              <img
                :src="media.image"
                :alt="`Media ${mediaIndex + 1}`"
                class="h-full w-full object-cover"
              />
            </div>

            <!-- Active thumbnail indicator -->
            <div
              v-if="activeIndex === mediaIndex"
              class="absolute bottom-0 left-0 right-0 h-1.5 bg-blue-500"
            ></div>            <!-- Media counter badge on thumbnails -->
            <div 
              class="absolute top-1 right-1 px-1.5 py-0.5 bg-black/50 rounded-full text-white text-[10px] font-medium shadow-sm border border-white/10 flex items-center"
            >
              <span>{{ mediaIndex + 1 }}</span>
            </div>
            
            <!-- Selection indicator -->
            <div
              v-if="activeIndex === mediaIndex" 
              class="absolute top-1 left-1 w-4 h-4 rounded-full bg-blue-500 flex items-center justify-center shadow-md"
            >
              <span class="text-white text-[8px]">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-2.5 h-2.5">
                  <path fill-rule="evenodd" d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z" clip-rule="evenodd" />
                </svg>
              </span>
            </div>
          </div>
        </div>
      </div>      <!-- Right navigation arrow -->
      <button
        v-show="canScrollRight"
        @click="scrollThumbnails('right')"
        class="absolute -right-2.5 top-1/2 -translate-y-1/2 z-10 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 rounded-full p-2 shadow-md border border-gray-200 dark:border-gray-700"
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

  // Ensure the active thumb is visible in the thumbnail container without scrolling the page
  nextTick(() => {
    if (!thumbnailsContainer.value) return;

    const container = thumbnailsContainer.value;
    const thumbnailElements = container.children;
    
    if (thumbnailElements && thumbnailElements[index]) {
      // Calculate position for scrolling within thumbnail container only
      const thumbnail = thumbnailElements[index];
      const containerLeft = container.scrollLeft;
      const containerWidth = container.clientWidth;
      const thumbLeft = thumbnail.offsetLeft;
      const thumbWidth = thumbnail.offsetWidth;
      
      // Only scroll the thumbnail container if the thumbnail is not fully visible
      if (thumbLeft < containerLeft || thumbLeft + thumbWidth > containerLeft + containerWidth) {
        container.scrollTo({
          left: thumbLeft - containerWidth / 2 + thumbWidth / 2,
          behavior: "smooth"
        });
      }
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
