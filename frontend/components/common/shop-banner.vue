<template>
  <div class="mb-4">
    <div class="max-w-7xl w-full mx-auto">
      <div
        class="rounded-md overflow-hidden shadow-sm bg-gradient-to-br from-slate-50 to-white border border-gray-100"
      >
        <div class="flex flex-col md:flex-row">
          <!-- Left side - Image Slider with reduced height -->
          <div class="w-full relative overflow-hidden">
            <!-- Aspect ratio container - reduced by ~10% -->
            <div class="relative pb-[40.625%] md:pb-[40.4%] lg:pb-[40.625%]">
              <div
                v-for="(src, index) in sliderImages"
                :key="index"
                class="absolute inset-0 transition-all duration-700 ease-in-out transform"
                :class="{
                  'opacity-100 scale-100': index === currentSlide,
                  'opacity-0 scale-105': index !== currentSlide,
                }"
              >
                <!-- Gradient overlay -->
                <div
                  class="absolute inset-0 bg-gradient-to-r from-black/30 to-transparent z-10"
                ></div>
                <img
                  :src="src"
                  :alt="`Slide ${index + 1}`"
                  class="w-full h-full object-cover"
                />
              </div>
            </div>

            <!-- Navigation arrows - slightly reduced size -->
            <button
              @click="prevSlide"
              class="absolute left-3 top-1/2 -translate-y-1/2 bg-white/10 backdrop-blur-sm hover:bg-white/20 rounded-full p-1.5 sm:p-2 z-20 transition-all duration-300 border border-white/20"
              aria-label="Previous slide"
            >
              <ChevronLeft class="h-4 w-4 text-white" />
            </button>

            <button
              @click="nextSlide"
              class="absolute right-3 top-1/2 -translate-y-1/2 bg-white/10 backdrop-blur-sm hover:bg-white/20 rounded-full p-1.5 sm:p-2 z-20 transition-all duration-300 border border-white/20"
              aria-label="Next slide"
            >
              <ChevronRight class="h-4 w-4 text-white" />
            </button>

            <!-- Slider indicators - moved up slightly -->
            <div
              class="absolute bottom-3 left-1/2 -translate-x-1/2 flex space-x-2 z-20"
            >
              <button
                v-for="(_, index) in sliderImages"
                :key="index"
                @click="goToSlide(index)"
                class="w-2 h-2 rounded-full transition-all duration-300"
                :class="{
                  'bg-white scale-110': index === currentSlide,
                  'bg-white/40 hover:bg-white/60': index !== currentSlide,
                }"
                :aria-label="`Go to slide ${index + 1}`"
              ></button>
            </div>
          </div>

          <!-- Right side - Premium content area -->
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import {
  ChevronLeft,
  ChevronRight,
  DollarSign,
  ShoppingBag,
  Clock,
  Shield,
  UserCheck,
} from "lucide-vue-next";

// Sample slider images - replace with your actual images
const sliderImages = [
  "/img/banner1.jpg",
  "/img/banner2.jpg",
  "/img/banner3.jpg",
];

const currentSlide = ref(0);
let intervalId = null;

const nextSlide = () => {
  currentSlide.value =
    currentSlide.value === sliderImages.length - 1 ? 0 : currentSlide.value + 1;
};

const prevSlide = () => {
  currentSlide.value =
    currentSlide.value === 0 ? sliderImages.length - 1 : currentSlide.value - 1;
};

const goToSlide = (index) => {
  currentSlide.value = index;
};

// Start auto-sliding when component is mounted
onMounted(() => {
  intervalId = setInterval(() => {
    nextSlide();
  }, 5000); // Change slide every 5 seconds
});

// Clean up interval when component is unmounted
onUnmounted(() => {
  if (intervalId) {
    clearInterval(intervalId);
  }
});
</script>

<style scoped>
.btn-primary {
  @apply h-10 sm:h-11 bg-transparent border-2 border-emerald-500 text-emerald-600 rounded-lg text-xs sm:text-sm font-medium transition-all duration-300 flex items-center justify-center hover:bg-emerald-50 hover:border-emerald-600 hover:text-emerald-700;
}

.btn-secondary {
  @apply h-10 sm:h-11 bg-transparent border-2 border-amber-500 text-amber-600 rounded-lg text-xs sm:text-sm font-medium transition-all duration-300 flex items-center justify-center hover:bg-amber-50 hover:border-amber-600 hover:text-amber-700;
}

.text-shadow {
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
}
</style>
