<template>
  <div class="py-2 md:p-6">
    <div
      class="grid grid-cols-3 sm:grid-cols-4 lg:flex justify-center lg:flex-wrap gap-1.5 sm:gap-3 mt-4 sm:mt-6"
    >
      <div
        v-for="service in services?.results"
        :key="service.id"
        class="relative rounded-xl border-2 border-dashed border-green-500 transition-all duration-300 cursor-pointer lg:w-[180px]"
        :class="{ 'border-green-600 shadow-sm': hoveredId === service.id }"
        @mouseenter="hoveredId = service.id"
        @mouseleave="hoveredId = null"
        @click="handleCardClick(service.id, service.business_type)"
      >
        <!-- Simple background -->
        <div class="absolute inset-0 bg-green-50"></div>

        <!-- Loading Spinner (Redesigned) -->
        <div
          v-if="clickedId === service.id"
          class="absolute inset-0 bg-green-50/80 backdrop-blur-sm z-20 flex items-center justify-center overflow-hidden"
        >
          <!-- SVG Spinner -->
          <div class="relative">
            <!-- Outer Ring -->
            <svg class="w-12 h-12 animate-spin-slow" viewBox="0 0 50 50">
              <circle
                class="stroke-green-500"
                cx="25"
                cy="25"
                r="20"
                fill="none"
                stroke-width="4"
                stroke-dasharray="60, 100"
              />
            </svg>

            <!-- Inner Ring -->
            <svg
              class="w-8 h-8 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 animate-spin-reverse"
              viewBox="0 0 50 50"
            >
              <circle
                class="stroke-green-600"
                cx="25"
                cy="25"
                r="15"
                fill="none"
                stroke-width="3"
                stroke-dasharray="40, 80"
              />
            </svg>

            <!-- Center Dot -->
            <div
              class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-green-600 rounded-full animate-pulse"
            ></div>
          </div>

          <!-- Optional Loading Text -->
          <span
            class="absolute bottom-4 text-sm font-medium text-green-800 animate-pulse"
          >
            লোড হচ্ছে...
          </span>
        </div>

        <ULink
          :to="`/classified-categories/${service.slug}`"
          class="relative z-10 flex flex-col items-center justify-center p-3 sm:p-2.5"
        >
          <!-- Icon container with animations (preserved) -->
          <div
            class="mb-3 w-16 h-16 flex items-center justify-center rounded-full bg-white relative"
            :class="[getContainerAnimation(service.id)]"
          >
            <!-- Service image with animations (preserved) -->
            <NuxtImg
              :src="service?.image"
              :title="service.title"
              class="size-9 z-10"
              :class="getIconAnimation(service.id)"
            />
          </div>

          <!-- Text with animations (preserved) -->
          <h3
            class="text-sm font-medium text-center"
            :class="[
              getTextAnimation(service.id),
              {
                'text-green-700': hoveredId === service.id,
                'text-gray-500': hoveredId !== service.id,
              },
            ]"
          >
            {{ service.title }}
          </h3>

          <!-- Simple bottom accent -->
          <div
            class="absolute bottom-0 left-0 right-0 h-1.5 bg-green-400 transition-transform duration-300 origin-left"
            :class="{
              'scale-x-100': hoveredId === service.id,
              'scale-x-0': hoveredId !== service.id,
            }"
          ></div>
        </ULink>
      </div>

      <!-- Simplified empty state -->
      <div
        v-if="services && !services.count"
        class="col-span-3 w-full py-12 px-2 relative rounded-xl border-2 border-dashed border-green-500 bg-green-50 text-center overflow-hidden"
      >
        <!-- Animated Background Pattern (subtle) -->
        <div class="absolute inset-0 opacity-10 bg-grid-pattern"></div>

        <!-- Icon Container with Both Animated Icons -->
        <div class="relative flex flex-col items-center justify-center mb-2">
          <!-- Magnifying Glass with Search Animation -->
          <div class="animate-search-motion mb-1">
            <UIcon
              name="i-heroicons-magnifying-glass"
              class="w-12 h-12 text-green-600"
            />
          </div>
        </div>

        <!-- Message -->
        <p class="text-gray-800 font-medium max-w-md mx-auto">
          {{ $t("category_search_text") }}
        </p>

        <!-- Optional Helper Text -->
        <p class="text-gray-500 text-sm mt-2 max-w-md mx-auto">
          {{ $t("category_search_text2") }}
        </p>
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

// Handle card click with spinner effect
const handleCardClick = (id, businessType) => {
  clickedId.value = id;

  // Simulate loading process - will be replaced by actual navigation
  setTimeout(() => {
    clickedId.value = null;
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

// Functions to get animations based on service ID (preserved)
const getContainerAnimation = (id) => {
  const safeId = typeof id === "number" ? id : parseInt(id) || 1;
  return containerAnimations[safeId % containerAnimations.length];
};

const getIconAnimation = (id) => {
  const safeId = typeof id === "number" ? id : parseInt(id) || 1;
  return iconAnimations[(safeId * 7) % iconAnimations.length];
};

const getTextAnimation = (id) => {
  const safeId = typeof id === "number" ? id : parseInt(id) || 1;
  return textAnimations[(safeId * 3) % textAnimations.length];
};
</script>

<style>
/* Preserved container animations */
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

/* Preserved icon animations */
@keyframes pulse-premium {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.15);
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
  }
  50% {
    transform: scale(1.06);
    opacity: 0.9;
  }
}

/* Preserved text animations */
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

/* Magnifying Glass Search Animation */
@keyframes search-motion {
  0%,
  100% {
    transform: translateX(0) rotate(0deg) scale(1);
  }
  25% {
    transform: translateX(-8px) rotate(-15deg) scale(1.05);
  }
  50% {
    transform: translateX(0) rotate(0deg) scale(1);
  }
  75% {
    transform: translateX(8px) rotate(15deg) scale(1.05);
  }
}

.animate-search-motion {
  animation: search-motion 3s ease-in-out infinite;
  display: inline-block;
}

/* Optional: Background Pattern */
.bg-grid-pattern {
  background-image: linear-gradient(
      0deg,
      transparent 24%,
      rgba(0, 0, 0, 0.05) 25%,
      rgba(0, 0, 0, 0.05) 26%,
      transparent 27%,
      transparent 74%,
      rgba(0, 0, 0, 0.05) 75%,
      rgba(0, 0, 0, 0.05) 76%,
      transparent 77%,
      transparent
    ),
    linear-gradient(
      90deg,
      transparent 24%,
      rgba(0, 0, 0, 0.05) 25%,
      rgba(0, 0, 0, 0.05) 26%,
      transparent 27%,
      transparent 74%,
      rgba(0, 0, 0, 0.05) 75%,
      rgba(0, 0, 0, 0.05) 76%,
      transparent 77%,
      transparent
    );
  background-size: 50px 50px;
}
/* Modern Spinner Animations */
@keyframes spin-slow {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

@keyframes spin-reverse {
  0% {
    transform: translate(-50%, -50%) rotate(0deg);
  }
  100% {
    transform: translate(-50%, -50%) rotate(-360deg);
  }
}

.animate-spin-slow {
  animation: spin-slow 2s linear infinite;
}

.animate-spin-reverse {
  animation: spin-reverse 1.5s linear infinite;
}
</style>
