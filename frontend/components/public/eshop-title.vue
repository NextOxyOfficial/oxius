<template>  <div class="flex items-center justify-between mb-2">
    <div class="inline-flex items-center">
      <UIcon name="i-heroicons-shopping-bag" class="w-8 h-8 text-emerald-600" />
      <div class="py-4 text-start">
        <h1
          class="text-xl md:text-xl ml-2 font-semibold text-gray-800"
        >
          {{ $t("eshop_manager") }}
        </h1>
      </div>
    </div>
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
