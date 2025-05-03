<template>
  <div class="mb-3">
    <!-- Main content area with primary image display -->
    <div class="relative overflow-hidden rounded-lg mb-1.5 shadow-sm group">
      <div
        class="relative w-full cursor-pointer overflow-hidden transition-all duration-300 h-[320px] sm:h-[400px] group-hover:shadow-sm"
        @click="$emit('open-media', post, activeIndex)"
      >
        <img
          :src="post.post_media[activeIndex].image"
          alt="Media"
          class="h-full w-full object-cover transition-transform duration-700 group-hover:scale-[1.02]"
        />

        <!-- Premium overlay gradients -->
        <div
          class="absolute inset-0 bg-gradient-to-t from-black/30 via-transparent to-transparent opacity-60"
        ></div>
        <div
          class="absolute inset-0 bg-gradient-to-b from-black/20 via-transparent to-transparent opacity-40"
        ></div>

        <!-- Image counter indicator -->
        <div
          class="absolute bottom-3 right-3 px-2.5 py-1 bg-black/50 backdrop-blur-sm rounded-full text-white text-xs font-medium flex items-center space-x-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
        >
          <span>{{ activeIndex + 1 }}</span>
          <span class="text-white/70">/</span>
          <span>{{ post.post_media.length }}</span>
        </div>
      </div>
    </div>

    <!-- Thumbnail row - only show if there's more than one media item -->
    <div v-if="post.post_media.length > 1" class="relative px-1.5">
      <!-- Left navigation arrow with premium styling -->
      <button
        v-show="canScrollLeft"
        @click="scrollThumbnails('left')"
        class="absolute -left-1 top-1/2 -translate-y-1/2 z-10 bg-black/30 backdrop-blur-md hover:bg-black/50 text-white rounded-full p-1.5 shadow-md border border-white/10 transition-all duration-300 hover:-translate-x-0.5"
        aria-label="Previous thumbnails"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2"
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

      <!-- Enhanced thumbnail container with gradient edges -->
      <div class="relative">
        <div
          class="absolute left-0 top-0 bottom-0 w-10 bg-gradient-to-r from-white to-transparent z-[1] pointer-events-none"
          v-if="canScrollLeft"
        ></div>

        <div
          class="absolute right-0 top-0 bottom-0 w-10 bg-gradient-to-l from-white to-transparent z-[1] pointer-events-none"
          v-if="canScrollRight"
        ></div>

        <div
          ref="thumbnailsContainer"
          class="grid grid-cols-4 md:grid-cols-6 gap-1.5 overflow-x-auto scrollbar-hide scroll-smooth px-1.5 py-1"
        >
          <div
            v-for="(media, mediaIndex) in post.post_media"
            :key="media.id"
            class="relative cursor-pointer overflow-hidden h-16 sm:h-20 rounded-md transition-all duration-300 hover:translate-y-[-2px] group/thumb"
            :class="{
              'ring-2 ring-blue-500 shadow-md scale-[1.02] z-10':
                activeIndex === mediaIndex,
              'opacity-80 hover:opacity-100 hover:shadow-sm':
                activeIndex !== mediaIndex,
            }"
            @click="setActiveMedia(mediaIndex)"
          >
            <img
              :src="media.image"
              :alt="`Media ${mediaIndex + 1}`"
              class="h-full w-full object-cover"
            />

            <!-- Premium active thumbnail indicator -->
            <div
              v-if="activeIndex === mediaIndex"
              class="absolute bottom-0 left-0 right-0 h-1 bg-blue-500 shadow-sm"
            ></div>

            <!-- Hover overlay -->
            <div
              class="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent opacity-0 group-hover/thumb:opacity-100 transition-opacity"
            ></div>

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
      </div>

      <!-- Right navigation arrow with premium styling -->
      <button
        v-show="canScrollRight"
        @click="scrollThumbnails('right')"
        class="absolute -right-1 top-1/2 -translate-y-1/2 z-10 bg-black/30 backdrop-blur-md hover:bg-black/50 text-white rounded-full p-1.5 shadow-md border border-white/10 transition-all duration-300 hover:translate-x-0.5"
        aria-label="Next thumbnails"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2"
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

// Handle thumbnail scrolling
const scrollThumbnails = (direction) => {
  if (!thumbnailsContainer.value) return;

  const container = thumbnailsContainer.value;
  const scrollAmount =
    direction === "left"
      ? -1 * container.clientWidth * 0.8
      : container.clientWidth * 0.8;

  container.scrollBy({
    left: scrollAmount,
    behavior: "smooth",
  });
};

// Update scroll indicators
const updateScrollIndicators = () => {
  if (!thumbnailsContainer.value) return;

  const container = thumbnailsContainer.value;
  canScrollLeft.value = container.scrollLeft > 0;
  canScrollRight.value =
    container.scrollLeft < container.scrollWidth - container.clientWidth - 5; // 5px buffer
};

// Check if the device is mobile
const checkMobile = () => {
  isMobile.value = window.innerWidth < 640; // sm breakpoint in Tailwind
};

// Lifecycle hooks
onMounted(() => {
  checkMobile();
  window.addEventListener("resize", checkMobile);

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

/* Premium animation for image transitions */
@keyframes subtleZoom {
  from {
    transform: scale(1);
  }
  to {
    transform: scale(1.05);
  }
}

/* Premium animation for thumbnail selection */
@keyframes pulseGlow {
  0% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.7);
  }
  70% {
    box-shadow: 0 0 0 6px rgba(59, 130, 246, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0);
  }
}

/* Apply the animation to active thumbnails */
.ring-blue-500 {
  animation: pulseGlow 2s infinite;
}
</style>
