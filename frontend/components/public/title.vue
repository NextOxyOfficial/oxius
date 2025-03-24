<template>
  <div class="flex items-center justify-between mb-6 md:mb-8">
    <div>
      <div class="py-4 text-start relative">
        <h1
          class="text-2xl md:text-4xl ml-3 font-bold bg-clip-text text-transparent bg-gradient-to-r from-emerald-600 to-teal-500 inline-block"
        >
          {{ $t("classified_service") }}
        </h1>
        <!-- Header underline -->
        <div
          class="h-1 ml-2 w-32 mx-auto mt-2 rounded-full bg-gradient-to-r from-emerald-400 to-teal-400"
        ></div>

        <!-- Floating particles around header - FIXED -->
        <div
          v-for="n in 5"
          :key="`header-particle-${n}`"
          class="absolute w-1.5 h-1.5 rounded-full bg-emerald-400/50 service-particle"
          :style="{
            top: `${50 + (Math.random() * 30 - 15)}%`,
            left: `${50 + (Math.random() * 60 - 30)}%`,
            animationDelay: `${Math.random() * 2}s`,
            animationDuration: `${3 + Math.random() * 2}s`,
          }"
        ></div>
      </div>
    </div>

    <UButton
      to="/my-classified-services"
      class="relative overflow-hidden bg-white hover:bg-gray-50 text-emerald-600 font-medium rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105 border border-dashed border-green-600 max-sm:!text-sm mr-2"
      :ui="{
        size: {
          sm: 'text-sm',
        },
        padding: {
          sm: 'px-3 py-2 md:px-3.5 md:py-2.5',
        },
        icon: {
          size: {
            sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
          },
        },
      }"
    >
      <!-- Ripple Effect Background -->
      <span class="absolute inset-0 overflow-hidden">
        <span
          class="absolute inset-0 scale-0 rounded-full bg-emerald-200/70 group-hover:animate-ripple"
        ></span>
      </span>

      <!-- Button Content with Icon -->
      <div class="relative z-10 flex items-center justify-center space-x-2">
        <!-- Icon Container -->
        <div class="icon-plus-container">
          <UIcon
            name="i-heroicons-plus-circle"
            class="text-2xl text-emerald-600 animate-pulse-icon"
          />
        </div>

        <!-- Text -->
        <span class="text-xs font-medium">{{ $t("post_free_ad") }}</span>
      </div>
    </UButton>
  </div>
</template>

<style scoped>
.pulse-effect {
  position: relative;
}

.pulse-effect::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border-radius: 0.375rem;
  animation: buttonPulse 2s infinite;
  box-shadow: 0 0 0 0 rgba(79, 70, 229, 0.7);
}

@keyframes floatIcon {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

@keyframes pulse {
  0% {
    transform: scale(0.8);
    opacity: 0.7;
  }
  50% {
    transform: scale(1);
    opacity: 0.3;
  }
  100% {
    transform: scale(0.8);
    opacity: 0.7;
  }
}

@keyframes bounce {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-5px);
  }
}

@keyframes buttonPulse {
  0% {
    box-shadow: 0 0 0 0 rgba(79, 70, 229, 0.7);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(79, 70, 229, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(79, 70, 229, 0);
  }
}
/* Add this to your existing styles */
@keyframes blink {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0;
  }
}

.animate-blink {
  animation: blink 1s infinite;
}

.fade-enter-active,
.fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
@keyframes ripple {
  0% {
    transform: scale(0);
    opacity: 0.5;
  }
  100% {
    transform: scale(6);
    opacity: 0;
  }
}

@keyframes bounce-gentle {
  0%,
  100% {
    transform: translateY(0) translateX(0);
    opacity: 0.5;
  }
  50% {
    transform: translateY(-20px) translateX(10px);
    opacity: 1;
  }
}

.animate-ripple {
  animation: ripple 1s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}

.animate-bounce-gentle {
  animation: bounce-gentle 2s ease-in-out infinite;
}

.scale-102 {
  --tw-scale-x: 1.02;
  --tw-scale-y: 1.02;
  transform: translate(var(--tw-translate-x), var(--tw-translate-y))
    rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y))
    scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y));
}
/* Improved Icon Animation */
@keyframes pulse-icon {
  0%,
  100% {
    transform: scale(1) rotate(0deg);
    opacity: 1;
  }
  25% {
    transform: scale(1.1) rotate(5deg);
    opacity: 0.9;
  }
  75% {
    transform: scale(0.95) rotate(-5deg);
    opacity: 0.95;
  }
}

.animate-pulse-icon {
  animation: pulse-icon 2s ease-in-out infinite !important;
  display: inline-block !important;
}

.icon-plus-container {
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Fix for animation conflicts - Namespaced Animations */
@keyframes service-float-particle {
  0%,
  100% {
    transform: translateY(0) translateX(0);
    opacity: 0.5;
  }
  50% {
    transform: translateY(-20px) translateX(10px);
    opacity: 1;
  }
}

@keyframes search-float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

@keyframes search-pulse {
  0% {
    transform: scale(0.8);
    opacity: 0.7;
  }
  50% {
    transform: scale(1);
    opacity: 0.3;
  }
  100% {
    transform: scale(0.8);
    opacity: 0.7;
  }
}

/* Optimized animations with hardware acceleration */
.service-particle {
  will-change: transform, opacity;
  animation: service-float-particle 3s ease-in-out infinite;
  animation-fill-mode: both;
  animation-play-state: running;
}

.search-icon {
  will-change: transform;
  animation: search-float 3s ease-in-out infinite;
  animation-play-state: running;
  z-index: 2;
}

.search-pulse {
  will-change: transform, opacity;
  animation: search-pulse 2s infinite;
  animation-play-state: running;
}

/* Improved cursor blink with better performance */
@keyframes cursor-blink {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0;
  }
}

.animate-cursor-blink {
  animation: cursor-blink 1s infinite;
  animation-fill-mode: both;
  will-change: opacity;
}

/* ===== NAMESPACED PARTICLE ANIMATIONS ===== */
@keyframes service-float-particle {
  0%,
  100% {
    transform: translateY(0) translateX(0);
    opacity: 0.5;
  }
  50% {
    transform: translateY(-20px) translateX(10px);
    opacity: 1;
  }
}

.service-particle {
  will-change: transform, opacity;
  animation-name: service-float-particle !important;
  animation-duration: 3s;
  animation-timing-function: ease-in-out;
  animation-iteration-count: infinite;
  animation-fill-mode: both;
  /* Prevent animation from being overridden */
  animation-play-state: running !important;
  position: absolute;
  z-index: 1;
}

/* ===== SEARCH ANIMATION COMPONENTS ===== */
@keyframes search-float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

@keyframes search-pulse {
  0% {
    transform: scale(0.8);
    opacity: 0.7;
  }
  50% {
    transform: scale(1);
    opacity: 0.3;
  }
  100% {
    transform: scale(0.8);
    opacity: 0.7;
  }
}

/* ===== CURSOR ANIMATION ===== */
@keyframes cursor-blink {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0;
  }
}

.animate-cursor-blink {
  animation: cursor-blink 1s infinite;
  animation-fill-mode: both;
  will-change: opacity;
}

/* ===== BUTTON ANIMATIONS ===== */
@keyframes ripple {
  0% {
    transform: scale(0);
    opacity: 0.5;
  }
  100% {
    transform: scale(6);
    opacity: 0;
  }
}

.animate-ripple {
  animation: ripple 1s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}

/* ===== ICON ANIMATION ===== */
@keyframes pulse-icon {
  0%,
  100% {
    transform: scale(1) rotate(0deg);
    opacity: 1;
  }
  25% {
    transform: scale(1.1) rotate(5deg);
    opacity: 0.9;
  }
  75% {
    transform: scale(0.95) rotate(-5deg);
    opacity: 0.95;
  }
}

.animate-pulse-icon {
  animation: pulse-icon 2s ease-in-out infinite !important;
  display: inline-block !important;
  transform-origin: center;
}

/* Keep existing utility animations */
.fade-enter-active,
.fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* Other existing styles can remain */
</style>
