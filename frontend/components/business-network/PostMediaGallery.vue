<template>
  <div class="mb-3">
    <!-- Main content area with primary image display -->
    <div class="relative overflow-hidden rounded-md mb-1">
      <div
        class="relative w-full cursor-pointer overflow-hidden transition-transform hover:scale-[1.01] h-[320px] sm:h-[400px]"
        @click="$emit('open-media', post, activeIndex)"
      >
        <img
          :src="post.post_media[activeIndex].image"
          alt="Media"
          class="h-full w-full object-cover"
        />
        <div
          v-if="post.post_media[activeIndex].type === 'video'"
          class="absolute inset-0 flex items-center justify-center"
        >
          <div
            class="h-12 w-12 rounded-full bg-black/50 backdrop-blur-sm flex items-center justify-center"
          >
            <div
              class="h-0 w-0 border-y-8 border-y-transparent border-l-12 border-l-white ml-1"
            ></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Thumbnail row - only show if there's more than one media item -->
    <div v-if="post.post_media.length > 1" class="relative">
      <!-- Left navigation arrow - only show if there are more thumbnails to scroll to -->
      <button 
        v-show="canScrollLeft" 
        @click="scrollThumbnails('left')"
        class="absolute left-0 top-1/2 -translate-y-1/2 z-10 bg-black/40 backdrop-blur-sm hover:bg-black/60 text-white rounded-full p-1 shadow-sm transition-all"
        aria-label="Previous thumbnails"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
        </svg>
      </button>

      <!-- Thumbnails container -->
      <div 
        ref="thumbnailsContainer" 
        class="grid grid-flow-col gap-1 overflow-x-auto scrollbar-hide scroll-smooth"
        :style="{
          'grid-template-columns': `repeat(${post.post_media.length}, minmax(${thumbWidth}px, 1fr))`,
        }"
      >
        <div
          v-for="(media, mediaIndex) in post.post_media"
          :key="media.id"
          class="relative cursor-pointer overflow-hidden h-16 sm:h-20 rounded-md transition-all"
          :class="{
            'ring-2 ring-blue-500 opacity-100': activeIndex === mediaIndex,
            'opacity-70 hover:opacity-100': activeIndex !== mediaIndex
          }"
          @click="setActiveMedia(mediaIndex)"
        >
          <img
            :src="media.image"
            :alt="`Media ${mediaIndex + 1}`"
            class="h-full w-full object-cover"
          />
          <div
            v-if="media.type === 'video'"
            class="absolute inset-0 flex items-center justify-center"
          >
            <div
              class="h-5 w-5 rounded-full bg-black/50 backdrop-blur-sm flex items-center justify-center"
            >
              <div
                class="h-0 w-0 border-y-2 border-y-transparent border-l-3 border-l-white ml-0.5"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Right navigation arrow - only show if there are more thumbnails to scroll to -->
      <button 
        v-show="canScrollRight" 
        @click="scrollThumbnails('right')"
        class="absolute right-0 top-1/2 -translate-y-1/2 z-10 bg-black/40 backdrop-blur-sm hover:bg-black/60 text-white rounded-full p-1 shadow-sm transition-all"
        aria-label="Next thumbnails"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, watch } from 'vue';

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

// Computed values
const visibleThumbs = computed(() => isMobile.value ? 4 : 6);
const thumbWidth = computed(() => isMobile.value ? 70 : 80);

// Set the active media
const setActiveMedia = (index) => {
  activeIndex.value = index;
  
  // Ensure the active thumb is visible by scrolling to it
  nextTick(() => {
    if (!thumbnailsContainer.value) return;
    
    const thumbnailElements = thumbnailsContainer.value.children;
    if (thumbnailElements && thumbnailElements[index]) {
      thumbnailElements[index].scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'center'
      });
    }
  });
};

// Handle thumbnail scrolling
const scrollThumbnails = (direction) => {
  if (!thumbnailsContainer.value) return;
  
  const container = thumbnailsContainer.value;
  const scrollAmount = direction === 'left' 
    ? -1 * container.clientWidth * 0.8 
    : container.clientWidth * 0.8;
  
  container.scrollBy({
    left: scrollAmount,
    behavior: 'smooth'
  });
};

// Update scroll indicators
const updateScrollIndicators = () => {
  if (!thumbnailsContainer.value) return;
  
  const container = thumbnailsContainer.value;
  canScrollLeft.value = container.scrollLeft > 0;
  canScrollRight.value = container.scrollLeft < container.scrollWidth - container.clientWidth - 5; // 5px buffer
};

// Check if the device is mobile
const checkMobile = () => {
  isMobile.value = window.innerWidth < 640; // sm breakpoint in Tailwind
};

// Lifecycle hooks
onMounted(() => {
  checkMobile();
  window.addEventListener('resize', checkMobile);
  
  // Initialize scroll indicators
  updateScrollIndicators();
  
  if (thumbnailsContainer.value) {
    thumbnailsContainer.value.addEventListener('scroll', updateScrollIndicators);
  }
  
  // Initial check for right scroll indicator
  nextTick(() => {
    if (thumbnailsContainer.value) {
      canScrollRight.value = thumbnailsContainer.value.scrollWidth > thumbnailsContainer.value.clientWidth;
    }
  });
});

// Watch for post media changes to update scroll indicators
watch(() => props.post.post_media, () => {
  nextTick(updateScrollIndicators);
}, { deep: true });
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

/* Optional: Add a subtle gradient fade on the right/left to indicate more content */
.thumbnail-fade-right::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  height: 100%;
  width: 20px;
  background: linear-gradient(to right, transparent, white);
  pointer-events: none;
}

.thumbnail-fade-left::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  width: 20px;
  background: linear-gradient(to left, transparent, white);
  pointer-events: none;
}
</style>
