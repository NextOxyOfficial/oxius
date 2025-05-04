<template>
  <div class="mb-3">
    <!-- Main content area with enhanced premium image display -->
    <div class="relative overflow-hidden rounded-xl shadow-sm group transform transition-all duration-300 hover:shadow-lg hover:-translate-y-0.5">
      <div
        class="relative w-full cursor-pointer overflow-hidden transition-all duration-700 h-[320px] sm:h-[420px]"
        @click="$emit('open-media', post, activeIndex)"
      >
        <!-- Main image with premium hover effects -->
        <img
          :src="post.post_media[activeIndex].image"
          alt="Media"
          class="h-full w-full object-cover transition-all duration-700 ease-out group-hover:scale-[1.03] brightness-[0.98] group-hover:brightness-[1.02]"
        />

        <!-- Premium overlay gradients -->
        <div class="absolute inset-0 bg-gradient-to-t from-black/40 via-black/10 to-transparent opacity-60"></div>
        <div class="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-transparent opacity-60"></div>
        
        <!-- Radial glow on hover -->
        <div class="absolute inset-0 bg-radial-gradient opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"></div>
        
        <!-- Premium vignette effect -->
        <div class="absolute inset-0 bg-vignette-gradient opacity-40 pointer-events-none"></div>

        <!-- Glassmorphic image counter indicator -->
        <div class="absolute bottom-3.5 right-3.5 px-3 py-1.5 bg-black/25 backdrop-blur-md rounded-full text-white text-xs font-semibold flex items-center space-x-2 shadow-xl border border-white/10 transform transition-all duration-300 group-hover:scale-105">
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

    <!-- Enhanced thumbnail gallery with glassmorphism - only show if there's more than one media item -->
    <div v-if="post.post_media.length > 1" class="relative px-0.5 mt-2">
      <!-- Left navigation arrow with enhanced premium styling -->
      <button
        v-show="canScrollLeft"
        @click="scrollThumbnails('left')"
        class="absolute -left-1.5 top-1/2 -translate-y-1/2 z-10 bg-black/30 backdrop-blur-md hover:bg-black/50 text-white rounded-full p-1.5 shadow-md border border-white/10 transition-all duration-300 hover:-translate-x-0.5 hover:shadow-xl"
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

      <!-- Premium thumbnail container with gradient edges for better UX -->
      <div class="relative">
        <div
          class="absolute left-0 top-0 bottom-0 w-12 bg-gradient-to-r from-white/90 dark:from-slate-900/90 to-transparent z-[1] pointer-events-none backdrop-blur-[1px]"
          v-if="canScrollLeft"
        ></div>

        <div
          class="absolute right-0 top-0 bottom-0 w-12 bg-gradient-to-l from-white/90 dark:from-slate-900/90 to-transparent z-[1] pointer-events-none backdrop-blur-[1px]"
          v-if="canScrollRight"
        ></div>

        <div
          ref="thumbnailsContainer"
          class="grid grid-cols-5 md:grid-cols-7 gap-2 overflow-x-auto scrollbar-hide scroll-smooth px-1.5 py-1"
          @scroll="updateScrollIndicators"
        >
          <div
            v-for="(media, mediaIndex) in post.post_media"
            :key="media.id"
            class="relative cursor-pointer overflow-hidden h-16 sm:h-18 rounded-lg transition-all duration-300 hover:-translate-y-[2px] group/thumb"
            :class="{
              'ring-2 ring-blue-500 shadow-lg scale-[1.02] z-10 premium-thumb-active':
                activeIndex === mediaIndex,
              'opacity-90 hover:opacity-100 hover:shadow-sm ring-1 ring-gray-100/50 dark:ring-slate-800/70':
                activeIndex !== mediaIndex,
            }"
            @click="setActiveMedia(mediaIndex)"
          >
            <div class="h-full w-full overflow-hidden">
              <img
                :src="media.image"
                :alt="`Media ${mediaIndex + 1}`"
                class="h-full w-full object-cover transition-transform duration-500 group-hover/thumb:scale-105"
              />
            </div>

            <!-- Premium active thumbnail indicator with animation -->
            <div
              v-if="activeIndex === mediaIndex"
              class="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-400 to-blue-600 shadow-glow"
            ></div>

            <!-- Hover overlay with premium glassmorphism -->
            <div
              class="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent opacity-0 group-hover/thumb:opacity-100 transition-opacity duration-300"
            ></div>

            <!-- Media counter badge on thumbnails -->
            <div 
              class="absolute top-1 right-1 px-1.5 py-0.5 bg-black/50 backdrop-blur-sm rounded-full text-white text-[10px] font-medium opacity-0 group-hover/thumb:opacity-100 transition-opacity duration-300 border border-white/10 shadow-sm"
            >
              {{ mediaIndex + 1 }}
            </div>
            
            <!-- Download button removed from thumbnails -->
          </div>
        </div>
      </div>

      <!-- Right navigation arrow with enhanced premium styling -->
      <button
        v-show="canScrollRight"
        @click="scrollThumbnails('right')"
        class="absolute -right-1.5 top-1/2 -translate-y-1/2 z-10 bg-black/30 backdrop-blur-md hover:bg-black/50 text-white rounded-full p-1.5 shadow-md border border-white/10 transition-all duration-300 hover:translate-x-0.5 hover:shadow-xl"
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
</style>
