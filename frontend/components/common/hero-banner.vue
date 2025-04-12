<template>
  <div class="max-w-7xl w-full mx-auto">
    <div
      class="rounded-md overflow-hidden flex flex-col md:flex-row shadow-sm bg-gradient-to-br from-white to-gray-50"
    >
      <!-- Left side - Image Slider -->
      <div
        class="w-full md:w-3/5 h-[125px] sm:h-[175px] md:h-[200px] lg:h-[250px] relative"
      >
        <div
          v-for="(src, index) in sliderImages"
          :key="index"
          class="absolute inset-0 transition-opacity duration-500"
          :class="{
            'opacity-100': index === currentSlide,
            'opacity-0 pointer-events-none': index !== currentSlide,
          }"
        >
          <img
            :src="src"
            :alt="`Slide ${index + 1}`"
            class="w-full h-full object-cover"
          />
        </div>

        <!-- Slider navigation arrows -->
        <button
          @click="prevSlide"
          class="absolute left-3 top-1/2 -translate-y-1/2 bg-white/90 rounded-full p-1 sm:p-1.5 hover:bg-white z-10 shadow-sm"
          aria-label="Previous slide"
        >
          <ChevronLeft class="h-3 w-3 sm:h-4 sm:w-4" />
        </button>

        <button
          @click="nextSlide"
          class="absolute right-3 top-1/2 -translate-y-1/2 bg-white/90 rounded-full p-1 sm:p-1.5 hover:bg-white z-10 shadow-sm"
          aria-label="Next slide"
        >
          <ChevronRight class="h-3 w-3 sm:h-4 sm:w-4" />
        </button>

        <!-- Slider dots -->
        <div
          class="absolute bottom-2 left-1/2 -translate-x-1/2 flex space-x-1.5 z-10"
        >
          <button
            v-for="(_, index) in sliderImages"
            :key="index"
            @click="goToSlide(index)"
            class="w-1.5 h-1.5 sm:w-2 sm:h-2 rounded-full"
            :class="{
              'bg-white': index === currentSlide,
              'bg-white/60': index !== currentSlide,
            }"
            :aria-label="`Go to slide ${index + 1}`"
          ></button>
        </div>
      </div>

      <!-- Right side - text and buttons -->
      <div
        class="w-full md:w-2/5 p-4 sm:p-5 lg:p-6 flex flex-col justify-center bg-white"
      >
        <h1 class="text-lg font-semibold leading-tight text-gray-800">
          Bangladesh's 1st social business network!
        </h1>
        <p class="text-sm mt-1 sm:mt-2 text-gray-600">
          Earn money, sell products, post/find the services you need.
        </p>

        <div
          class="mt-3 sm:mt-4 lg:mt-5 grid-cols-2 gap-2 sm:gap-3 hidden sm:grid"
        >
          <a
            href="#micro-gigs"
            class="h-9 sm:h-10 border border-emerald-600 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-lg text-xs sm:text-sm font-medium flex items-center justify-center gap-1.5 shadow-sm"
          >
            <DollarSign class="h-3.5 w-3.5" />
            Earn Money
          </a>
          <NuxtLink
            to="/shop-manager"
            class="h-9 sm:h-10 border border-amber-600 bg-amber-50 hover:bg-amber-100 text-amber-700 rounded-lg text-xs sm:text-sm font-medium flex items-center justify-center gap-1.5 shadow-sm"
          >
            <ShoppingBag class="h-3.5 w-3.5" />
            Sell Products
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
  <div class="grid grid-cols-2 gap-2 sm:gap-3 sm:hidden mb-2 mt-2">
    <a
      href="#micro-gigs"
      class="h-9 sm:h-10 border border-emerald-600 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-lg text-xs sm:text-sm font-medium flex items-center justify-center gap-1.5 shadow-sm"
    >
      <DollarSign class="h-3.5 w-3.5" />
      Earn Money
    </a>
    <NuxtLink
      to="/shop-manager"
      class="h-9 sm:h-10 border border-amber-600 bg-amber-50 hover:bg-amber-100 text-amber-700 rounded-lg text-xs sm:text-sm font-medium flex items-center justify-center gap-1.5 shadow-sm"
    >
      <ShoppingBag class="h-3.5 w-3.5" />
      Sell Products
    </NuxtLink>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from "vue";
import {
  ChevronLeft,
  ChevronRight,
  DollarSign,
  ShoppingBag,
  PlusCircle,
} from "lucide-vue-next";

// Sample slider images - replace with your actual images
const sliderImages = [
  "/placeholder.svg?height=600&width=1000",
  "/placeholder.svg?height=600&width=1000",
  "/placeholder.svg?height=600&width=1000",
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
/* Any additional component-specific styles can go here */
</style>
