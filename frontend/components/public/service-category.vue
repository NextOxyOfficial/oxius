<template>
  <div class="premium-background p-4 md:p-6 relative overflow-hidden">
    <!-- Premium background effects -->
    <div
      class="absolute inset-0 bg-gradient-to-br from-gray-50 via-white to-gray-50 z-0"
    ></div>

    <!-- Animated background patterns (reduced number for performance) -->
    <div class="absolute inset-0 z-0 opacity-30">
      <!-- Floating circles -->
      <div
        v-for="n in 8"
        :key="`circle-${n}`"
        class="absolute rounded-full bg-gradient-to-br"
        :class="
          n % 2 === 0
            ? 'from-green-200/20 to-emerald-200/20'
            : 'from-emerald-200/20 to-green-200/20'
        "
        :style="{
          width: `${20 + Math.random() * 60}px`,
          height: `${20 + Math.random() * 60}px`,
          top: `${Math.random() * 100}%`,
          left: `${Math.random() * 100}%`,
          animation: `float-bg ${
            5 + Math.random() * 10
          }s infinite ease-in-out ${Math.random() * 5}s`,
          opacity: 0.1 + Math.random() * 0.3,
        }"
      ></div>

      <!-- Light beam effect -->
      <div
        class="absolute -inset-[10%] bg-gradient-to-r from-transparent via-green-200/30 to-transparent animate-light-beam"
      ></div>
    </div>

    <!-- Content container -->
    <div class="relative z-10">
      <!-- Service categories grid -->
      <div
        class="grid grid-cols-2 sm:grid-cols-3 lg:flex justify-center lg:flex-wrap gap-3 mt-6"
      >
        <div
          v-for="service in displayedServices"
          :key="service.id"
          class="relative overflow-hidden rounded-xl border-2 border-dashed border-green-500 transition-all duration-500 cursor-pointer group backdrop-blur-[1px] lg:w-[150px]"
          :class="{
            'border-green-600 shadow-xl -translate-y-1':
              hoveredId === service.id,
            'scale-95': clickedId === service.id,
          }"
          @mouseenter="hoveredId = service.id"
          @mouseleave="hoveredId = null"
          @click="handleCardClick(service.id, service.business_type)"
        >
          <!-- Premium background effects -->
          <div
            class="absolute inset-0 bg-gradient-to-br from-green-50 to-emerald-50 transition-all duration-500"
          ></div>

          <!-- Premium hover gradient overlay -->
          <div
            class="absolute inset-0 bg-gradient-to-br from-green-100/50 to-emerald-100/50 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
          ></div>

          <!-- Shimmer effect -->
          <div
            class="absolute inset-0 opacity-0 group-hover:opacity-30 z-0 transition-opacity duration-500"
            :style="{
              background:
                'linear-gradient(115deg, transparent 25%, rgba(76, 175, 80, 0.2) 45%, rgba(76, 175, 80, 0.3) 55%, transparent 70%)',
              backgroundSize: '200% 100%',
              animation: 'shimmer 8s infinite linear',
            }"
          ></div>

          <!-- Click spinner effect -->
          <div
            v-if="clickedId === service.id"
            class="absolute inset-0 z-20 flex items-center justify-center bg-green-50/50 backdrop-blur-sm"
          >
            <div class="relative">
              <div
                class="w-12 h-12 border-3 border-green-200 border-t-green-500 rounded-full animate-spin"
              ></div>
              <div
                class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-8 h-8 border-3 border-emerald-200 border-b-emerald-500 rounded-full animate-spin-reverse"
              ></div>
              <div
                class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-gradient-to-br from-green-500 to-emerald-500 rounded-full animate-pulse-fast"
              ></div>
            </div>
          </div>

          <ULink
            :to="`/classified-categories/${service.id}?business_type=${service.business_type}`"
            active-class="text-primary"
            inactive-class="text-gray-500 dark:text-gray-400"
            class="relative z-10 flex flex-col items-center justify-center p-3 sm:p-2.5"
          >
            <!-- Premium icon container with enhanced animations -->
            <div
              class="mb-3 w-16 h-16 flex items-center justify-center rounded-full transition-all duration-500 backdrop-blur-[1px] relative"
              :class="[
                getContainerAnimation(service.id),
                { 'shadow-premium scale-110': hoveredId === service.id },
              ]"
              :style="{
                background:
                  hoveredId === service.id
                    ? 'linear-gradient(135deg, rgba(255,255,255,1) 0%, rgba(236,253,245,1) 100%)'
                    : 'linear-gradient(135deg, rgba(255,255,255,1) 0%, rgba(249,250,251,1) 100%)',
              }"
            >
              <!-- Premium inner glow -->
              <div
                class="absolute inset-0 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-500"
                :style="{
                  boxShadow: 'inset 0 0 15px rgba(22, 163, 74, 0.2)',
                  animation: 'pulse-glow 3s infinite ease-in-out',
                }"
              ></div>

              <!-- Service image with enhanced animations -->
              <NuxtImg
                :src="service?.image"
                :title="service.title"
                class="size-9 transition-all duration-500 relative z-10"
                :class="getIconAnimation(service.id)"
              />
            </div>

            <!-- Premium text with enhanced animations -->
            <div class="relative overflow-hidden">
              <h3
                class="text-md transition-all duration-500 font-medium text-center"
                :class="[
                  getTextAnimation(service.id),
                  {
                    'font-semibold text-green-800': hoveredId === service.id,
                    'text-gray-700': hoveredId !== service.id,
                  },
                ]"
              >
                {{ service.title }}
              </h3>

              <!-- Text highlight effect -->
              <span
                v-if="hoveredId === service.id"
                class="absolute inset-0 bg-gradient-to-r from-transparent via-green-100/30 to-transparent animate-text-shine"
              ></span>
            </div>

            <!-- Premium bottom accent with enhanced animation -->
            <div
              class="absolute bottom-0 left-0 right-0 h-1.5 bg-gradient-to-r from-green-400 to-emerald-400 transition-transform duration-500 origin-left"
              :class="{
                'scale-x-100': hoveredId === service.id,
                'scale-x-0': hoveredId !== service.id,
              }"
            ></div>

            <!-- Premium corner accent -->
            <div
              class="absolute bottom-0 right-0 w-0 h-0 transition-all duration-500 opacity-0 group-hover:opacity-100"
              :style="{
                borderStyle: 'solid',
                borderWidth:
                  hoveredId === service.id ? '0 0 12px 12px' : '0 0 8px 8px',
                borderColor: 'transparent transparent #22c55e transparent',
              }"
            ></div>
          </ULink>
        </div>

        <!-- Empty state with premium design -->
        <div
          v-if="services && !services.count"
          class="col-span-2 sm:col-span-3 w-full py-16 relative overflow-hidden rounded-xl border-2 border-dashed border-green-500 transition-all duration-500 backdrop-blur-[1px]"
        >
          <!-- Premium background effects -->
          <div
            class="absolute inset-0 bg-gradient-to-br from-green-50 to-emerald-50 transition-all duration-500"
          ></div>

          <!-- Decorative elements with premium styling -->
          <div
            class="absolute top-0 right-0 w-32 h-32 bg-green-100 rounded-full translate-x-16 -translate-y-16 opacity-70 blur-2xl animate-pulse-bg"
          ></div>
          <div
            class="absolute bottom-0 left-0 w-24 h-24 bg-amber-100 rounded-full -translate-x-12 translate-y-12 opacity-70 blur-2xl animate-pulse-bg"
            style="animation-delay: 1s"
          ></div>

          <!-- Animated search illustration with premium styling -->
          <div class="mb-6 relative z-10">
            <div class="search-animation mx-auto">
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="search-icon text-green-500 animate-pulse-premium"
              />
              <div class="search-pulse bg-green-200/50"></div>
              <div class="search-location">
                <UIcon
                  name="i-heroicons-map-pin"
                  class="location-pin text-green-600 animate-bounce-premium"
                />
              </div>
            </div>
          </div>

          <!-- Message with premium styling -->
          <p
            class="text-gray-600 max-w-md mx-auto mb-6 fade-in-up-delay relative"
          >
            দুঃখিত, এই নামে কোনো ক্যাটাগরি খুঁজে পাওয়া যায়নি
            <!-- Text highlight effect -->
            <span
              class="absolute inset-0 bg-gradient-to-r from-transparent via-green-100/30 to-transparent animate-text-shine"
            ></span>
          </p>
        </div>
      </div>

      <!-- See More Button -->
      <div v-if="hasMoreServices" class="flex justify-center mt-8">
        <button
          @click="showMoreServices"
          class="group relative px-6 py-3 overflow-hidden rounded-lg bg-gradient-to-r from-green-500 to-emerald-500 text-white font-medium shadow-lg hover:shadow-xl transition-all duration-300"
        >
          <!-- Button background effects -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-green-600 to-emerald-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
          ></div>

          <!-- Shimmer effect -->
          <div
            class="absolute inset-0 opacity-0 group-hover:opacity-30 transition-opacity duration-300"
            :style="{
              background:
                'linear-gradient(115deg, transparent 25%, rgba(255, 255, 255, 0.4) 45%, rgba(255, 255, 255, 0.5) 55%, transparent 70%)',
              backgroundSize: '200% 100%',
              animation: 'shimmer 3s infinite linear',
            }"
          ></div>

          <!-- Button text -->
          <span class="relative z-10 flex items-center">
            <span>আরও দেখুন</span>
            <UIcon
              name="i-heroicons-chevron-down"
              class="ml-2 group-hover:animate-bounce-subtle"
            />
          </span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  services: Object,
});

const hoveredId = ref(null);
const clickedId = ref(null);
const itemsPerPage = ref(12);
const currentPage = ref(1);

// Computed property for displayed services
const displayedServices = computed(() => {
  if (!props.services?.results) return [];

  const featuredServices = props.services.results;
  return featuredServices.slice(0, itemsPerPage.value * currentPage.value);
});

// Check if there are more services to show
const hasMoreServices = computed(() => {
  if (!props.services?.results) return false;

  const featuredServices = props.services.results;
  return featuredServices.length > itemsPerPage.value * currentPage.value;
});

// Function to show more services
const showMoreServices = () => {
  currentPage.value++;
};

// Handle card click with spinner effect
const handleCardClick = (id, businessType) => {
  clickedId.value = id;

  // Simulate loading process - will be replaced by actual navigation
  setTimeout(() => {
    clickedId.value = null;
    // Navigation will happen through ULink
  }, 800);
};

// Five core animations for containers
const containerAnimations = [
  "animate-float-up-down",
  "animate-float-left-right",
  "animate-pulse-grow",
  "animate-bounce-subtle",
  "animate-wiggle",
];

// Five core animations for icons
const iconAnimations = [
  "animate-pulse-premium",
  "animate-bounce-premium",
  "animate-shake-premium",
  "animate-float-3d",
  "animate-breathe-premium",
];

// Five core animations for text
const textAnimations = [
  "animate-text-pulse",
  "animate-text-wave",
  "animate-text-glow",
  "animate-text-float",
  "animate-text-highlight",
];

// Functions to get animations based on service ID
const getContainerAnimation = (id) => {
  // Ensure we have a valid number
  const safeId = typeof id === "number" ? id : parseInt(id) || 1;
  // Use modulo to cycle through animations
  return containerAnimations[safeId % containerAnimations.length];
};

// Get icon animation with randomization
const getIconAnimation = (id) => {
  // Ensure we have a valid number
  const safeId = typeof id === "number" ? id : parseInt(id) || 1;
  // Use a different formula to ensure variety
  return iconAnimations[(safeId * 7) % iconAnimations.length];
};

// Get text animation
const getTextAnimation = (id) => {
  // Ensure we have a valid number
  const safeId = typeof id === "number" ? id : parseInt(id) || 1;
  // Use a different formula to ensure variety
  return textAnimations[(safeId * 3) % textAnimations.length];
};
</script>

<style>
/* Base animations */
@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

@keyframes float-up-down {
  0% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-5px);
  }
  100% {
    transform: translateY(0px);
  }
}

@keyframes float-left-right {
  0% {
    transform: translateX(0px);
  }
  50% {
    transform: translateX(5px);
  }
  100% {
    transform: translateX(0px);
  }
}

@keyframes pulse-grow {
  0% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
  100% {
    transform: scale(1);
  }
}

@keyframes bounce-subtle {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-8px);
  }
}

@keyframes wiggle {
  0%,
  100% {
    transform: translateX(0);
  }
  25% {
    transform: translateX(-3px);
  }
  75% {
    transform: translateX(3px);
  }
}

/* Premium icon animations */
@keyframes pulse-premium {
  0%,
  100% {
    transform: scale(1);
    filter: saturate(100%);
  }
  50% {
    transform: scale(1.15);
    filter: saturate(120%) brightness(1.1);
  }
}

@keyframes bounce-premium {
  0%,
  100% {
    transform: translateY(0) scale(1);
  }
  40% {
    transform: translateY(-7px) scale(1.1);
  }
  60% {
    transform: translateY(-4px) scale(1.05);
  }
}

@keyframes shake-premium {
  0%,
  100% {
    transform: translateX(0) rotate(0deg);
  }
  20% {
    transform: translateX(-3px) rotate(-5deg);
  }
  40% {
    transform: translateX(3px) rotate(5deg);
  }
  60% {
    transform: translateX(-3px) rotate(-3deg);
  }
  80% {
    transform: translateX(3px) rotate(3deg);
  }
}

@keyframes float-3d {
  0%,
  100% {
    transform: translateZ(0) translateY(0) rotate(0deg);
  }
  33% {
    transform: translateZ(8px) translateY(-4px) rotate(5deg);
  }
  66% {
    transform: translateZ(4px) translateY(2px) rotate(-5deg);
  }
}

@keyframes breathe-premium {
  0%,
  100% {
    transform: scale(1);
    opacity: 1;
    filter: brightness(1);
  }
  50% {
    transform: scale(1.06);
    opacity: 0.9;
    filter: brightness(1.1);
  }
}

/* Premium text animations */
@keyframes text-pulse {
  0%,
  100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.9;
    transform: scale(1.02);
  }
}

@keyframes text-wave {
  0%,
  100% {
    transform: translateY(0);
  }
  25% {
    transform: translateY(-2px);
  }
  50% {
    transform: translateY(0);
  }
  75% {
    transform: translateY(2px);
  }
}

@keyframes text-glow {
  0%,
  100% {
    text-shadow: 0 0 0 transparent;
  }
  50% {
    text-shadow: 0 0 3px rgba(22, 163, 74, 0.5);
  }
}

@keyframes text-float {
  0%,
  100% {
    transform: translateY(0) translateX(0);
  }
  25% {
    transform: translateY(-1px) translateX(1px);
  }
  50% {
    transform: translateY(0) translateX(0);
  }
  75% {
    transform: translateY(1px) translateX(-1px);
  }
}

@keyframes text-highlight {
  0%,
  100% {
    background-position: -100% 0;
  }
  50% {
    background-position: 200% 0;
  }
}

@keyframes text-shine {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

/* Background animations */
@keyframes float-bg {
  0%,
  100% {
    transform: translateY(0) translateX(0);
  }
  50% {
    transform: translateY(-30px) translateX(20px);
  }
}

@keyframes pulse-bg {
  0%,
  100% {
    transform: scale(1) rotate(0deg);
    opacity: 0.3;
  }
  50% {
    transform: scale(1.1) rotate(5deg);
    opacity: 0.5;
  }
}

@keyframes light-beam {
  0% {
    transform: translateX(-100%) skewX(-15deg);
  }
  100% {
    transform: translateX(100%) skewX(-15deg);
  }
}

/* Spinner animations */
@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

@keyframes spin-reverse {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(-360deg);
  }
}

@keyframes pulse-fast {
  0%,
  100% {
    transform: scale(0.95);
    opacity: 0.8;
  }
  50% {
    transform: scale(1.05);
    opacity: 1;
  }
}

/* Animation classes */
.animate-float-up-down {
  animation: float-up-down 3s ease-in-out infinite;
}

.animate-float-left-right {
  animation: float-left-right 3s ease-in-out infinite;
}

.animate-pulse-grow {
  animation: pulse-grow 2.5s ease-in-out infinite;
}

.animate-bounce-subtle {
  animation: bounce-subtle 2.8s ease-in-out infinite;
}

.animate-wiggle {
  animation: wiggle 3.5s ease-in-out infinite;
}

.animate-pulse-premium {
  animation: pulse-premium 1.5s ease-in-out infinite;
}

.animate-bounce-premium {
  animation: bounce-premium 1.8s ease infinite;
}

.animate-shake-premium {
  animation: shake-premium 2s ease-in-out infinite;
}

.animate-float-3d {
  animation: float-3d 2.2s ease-in-out infinite;
}

.animate-breathe-premium {
  animation: breathe-premium 2s ease-in-out infinite;
}

.animate-text-pulse {
  animation: text-pulse 2.2s ease-in-out infinite;
}

.animate-text-wave {
  animation: text-wave 2.7s ease-in-out infinite;
}

.animate-text-glow {
  animation: text-glow 2.5s ease-in-out infinite;
}

.animate-text-float {
  animation: text-float 3s ease-in-out infinite;
}

.animate-text-highlight {
  animation: text-highlight 3.5s ease-in-out infinite;
}

.animate-text-shine {
  animation: text-shine 2s linear infinite;
}

.animate-light-beam {
  animation: light-beam 8s infinite linear;
}

.animate-spin {
  animation: spin 1.5s linear infinite;
}

.animate-spin-reverse {
  animation: spin-reverse 1.2s linear infinite;
}

.animate-pulse-fast {
  animation: pulse-fast 0.8s ease-in-out infinite;
}

/* Premium shadow */
.shadow-premium {
  box-shadow: 0 10px 25px -5px rgba(22, 163, 74, 0.3),
    0 8px 10px -6px rgba(22, 163, 74, 0.2);
}

/* Premium background */
.premium-background {
  position: relative;
  background-color: #f9fafb;
  overflow: hidden;
}

/* Search animation styles */
.search-animation {
  position: relative;
  width: 80px;
  height: 80px;
}

.search-icon {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 2.5rem;
  z-index: 2;
}

.search-pulse {
  position: absolute;

  width: 60px;
  height: 60px;
  border-radius: 50%;
  animation: search-pulse 2s infinite ease-in-out;
  z-index: 1;
}

.search-location {
  position: absolute;
  top: 20%;
  right: 10%;
  animation: location-bounce 1.5s infinite ease-in-out;
}

.location-pin {
  font-size: 1.5rem;
}

@keyframes search-pulse {
  0%,
  100% {
    transform: translate(-50%, -50%) scale(1);
    opacity: 0.5;
  }
  50% {
    transform: translate(-50%, -50%) scale(1.2);
    opacity: 0.8;
  }
}

@keyframes location-bounce {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

.fade-in-up-delay {
  animation: fade-in-up 1s ease-out 0.5s both;
}

@keyframes fade-in-up {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
