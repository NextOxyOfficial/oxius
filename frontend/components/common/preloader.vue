<template>
  <div
    class="flex flex-col items-center justify-center p-4"
    :class="
      fullScreen
        ? 'fixed inset-0 z-[9999] bg-white/90 dark:bg-slate-900/85 backdrop-blur-md'
        : ''
    "
  >
    <div class="flex flex-col items-center justify-center gap-6">
      <!-- Spinner with rings -->
      <div class="relative w-20 h-20">
        <!-- Outer ring -->
        <div
          class="absolute w-full h-full rounded-full border-3 border-transparent border-t-primary-500 border-l-primary-500/50 shadow-[0_0_10px_rgba(59,130,246,0.1)] animate-spin-clockwise"
        ></div>

        <!-- Middle ring -->
        <div
          class="absolute top-0 left-0 right-0 bottom-0 m-auto w-3/4 h-3/4 rounded-full border-[2.5px] border-transparent border-r-blue-400 border-b-blue-400/60 shadow-[0_0_10px_rgba(59,130,246,0.1)] animate-spin-counter"
        ></div>

        <!-- Inner ring -->
        <div
          class="absolute top-0 left-0 right-0 bottom-0 m-auto w-1/2 h-1/2 rounded-full border-2 border-dotted border-blue-500/40 animate-spin"
        ></div>

        <!-- Logo center -->
        <div
          class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-gradient-to-br from-white to-slate-100 dark:from-slate-800 dark:to-slate-900 shadow-lg flex items-center justify-center animate-pulse z-10"
        >
          <span
            class="text-3xl font-bold text-primary-600 dark:text-primary-500 animate-text-glow"
            >{{ logoText }}</span
          >
        </div>

        <!-- Particles -->
        <div class="absolute inset-0 scale-[1.3] pointer-events-none">
          <span
            v-for="i in 8"
            :key="i"
            class="absolute w-[5px] h-[5px] bg-blue-400 rounded-full opacity-0"
            :class="`particle-${i}`"
          ></span>
        </div>
      </div>

      <!-- Loading text with dots -->
      <div v-if="text" class="flex items-center gap-2 animate-fade-in">
        <p class="text-sm font-medium text-slate-600 dark:text-slate-300">
          {{ text }}
        </p>
        <div class="flex items-center">
          <span
            class="w-1 h-1 bg-primary-500 rounded-full mx-0.5 animate-bounce-delay-1"
          ></span>
          <span
            class="w-1 h-1 bg-primary-500 rounded-full mx-0.5 animate-bounce-delay-2"
          ></span>
          <span
            class="w-1 h-1 bg-primary-500 rounded-full mx-0.5 animate-bounce-delay-3"
          ></span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  text: {
    type: String,
    default: "Loading",
  },
  logoText: {
    type: String,
    default: "A",
  },
  fullScreen: {
    type: Boolean,
    default: false,
  },
});
</script>

<style>
/* Custom animations that can't be done with default Tailwind classes */
@keyframes spin-clockwise {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@keyframes spin-counter {
  from {
    transform: rotate(360deg);
  }
  to {
    transform: rotate(0deg);
  }
}

@keyframes text-glow {
  0% {
    filter: brightness(1);
    text-shadow: 0 0 0 rgba(59, 130, 246, 0);
  }
  100% {
    filter: brightness(1.2);
    text-shadow: 0 0 8px rgba(59, 130, 246, 0.5);
  }
}

@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-spin-clockwise {
  animation: spin-clockwise 1.8s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite;
}

.animate-spin-counter {
  animation: spin-counter 2.4s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite;
}

.animate-text-glow {
  animation: text-glow 2s ease-in-out infinite alternate;
}

.animate-fade-in {
  animation: fade-in 0.5s ease-out forwards;
}

.animate-bounce-delay-1 {
  animation: bounce 1.4s infinite ease-in-out both;
  animation-delay: -0.32s;
}

.animate-bounce-delay-2 {
  animation: bounce 1.4s infinite ease-in-out both;
  animation-delay: -0.16s;
}

.animate-bounce-delay-3 {
  animation: bounce 1.4s infinite ease-in-out both;
}

@keyframes bounce {
  0%,
  80%,
  100% {
    transform: scale(0.8);
    opacity: 0.5;
  }
  40% {
    transform: scale(1.2);
    opacity: 1;
  }
}

/* Particle positions and animations */
.particle-1,
.particle-2,
.particle-3,
.particle-4,
.particle-5,
.particle-6,
.particle-7,
.particle-8 {
  animation: particle-float 3s ease-in-out infinite;
}

.particle-1 {
  top: 10%;
  left: 50%;
  animation-delay: 0s;
}
.particle-2 {
  top: 25%;
  left: 85%;
  animation-delay: 0.4s;
}
.particle-3 {
  top: 50%;
  left: 90%;
  animation-delay: 0.8s;
}
.particle-4 {
  top: 75%;
  left: 85%;
  animation-delay: 1.2s;
}
.particle-5 {
  top: 90%;
  left: 50%;
  animation-delay: 1.6s;
}
.particle-6 {
  top: 75%;
  left: 15%;
  animation-delay: 2s;
}
.particle-7 {
  top: 50%;
  left: 10%;
  animation-delay: 2.4s;
}
.particle-8 {
  top: 25%;
  left: 15%;
  animation-delay: 2.8s;
}

@keyframes particle-float {
  0% {
    transform: translateY(0) scale(0.5);
    opacity: 0;
  }
  25% {
    opacity: 0.8;
  }
  50% {
    transform: translateY(-15px) scale(1);
    opacity: 0.6;
  }
  75% {
    opacity: 0.8;
  }
  100% {
    transform: translateY(0) scale(0.5);
    opacity: 0;
  }
}
</style>
