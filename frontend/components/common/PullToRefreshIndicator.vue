<template>
  <!-- Pull to Refresh Indicator -->
  <Teleport to="body">
    <div
      v-if="showIndicator && (isPulling || isRefreshing)"
      class="pull-to-refresh-indicator"
      :class="{
        'pulling': isPulling,
        'refreshing': isRefreshing,
        'ready': refreshReady,
      }"
      :style="{
        transform: `translateY(${Math.max(0, pullDistance - 60)}px)`,
        opacity: pullOpacity,
      }"
    >
      <div class="indicator-container">
        <!-- Pull Arrow -->
        <div
          v-if="!isRefreshing"
          class="pull-arrow"
          :class="{ 'arrow-ready': refreshReady }"
          :style="{
            transform: `rotate(${refreshReady ? 180 : pullProgress * 180}deg)`,
          }"
        >
          <UIcon name="i-heroicons-arrow-down" class="w-5 h-5" />
        </div>

        <!-- Loading Spinner -->
        <div
          v-else
          class="loading-spinner"
        >
          <UIcon name="i-heroicons-arrow-path" class="w-5 h-5 animate-spin" />
        </div>

        <!-- Progress Ring -->
        <svg
          class="progress-ring"
          width="40"
          height="40"
          viewBox="0 0 40 40"
        >
          <circle
            class="progress-ring-background"
            cx="20"
            cy="20"
            r="16"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            opacity="0.2"
          />
          <circle
            class="progress-ring-progress"
            cx="20"
            cy="20"
            r="16"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            :stroke-dasharray="circumference"
            :stroke-dashoffset="progressOffset"
            stroke-linecap="round"
            transform="rotate(-90 20 20)"
          />
        </svg>
      </div>

      <!-- Status Text -->
      <div class="status-text">
        <span v-if="isRefreshing" class="refreshing-text">
          {{ refreshingText }}
        </span>
        <span v-else-if="refreshReady" class="ready-text">
          {{ releaseText }}
        </span>
        <span v-else class="pull-text">
          {{ pullText }}
        </span>
      </div>
    </div>
  </Teleport>

  <!-- Page Overlay during refresh -->
  <div
    v-if="isRefreshing && showOverlay"
    class="refresh-overlay"
  >
    <div class="overlay-content">
      <div class="overlay-spinner">
        <UIcon name="i-heroicons-arrow-path" class="w-8 h-8 animate-spin text-primary-600" />
      </div>
      <p class="overlay-text">{{ refreshingText }}</p>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  // Pull to refresh state
  isPulling: {
    type: Boolean,
    default: false,
  },
  isRefreshing: {
    type: Boolean,
    default: false,
  },
  pullDistance: {
    type: Number,
    default: 0,
  },
  pullProgress: {
    type: Number,
    default: 0,
  },
  pullOpacity: {
    type: Number,
    default: 0,
  },
  refreshReady: {
    type: Boolean,
    default: false,
  },

  // Appearance options
  showIndicator: {
    type: Boolean,
    default: true,
  },
  showOverlay: {
    type: Boolean,
    default: false,
  },
  
  // Text options
  pullText: {
    type: String,
    default: 'Pull down to refresh',
  },
  releaseText: {
    type: String,
    default: 'Release to refresh',
  },
  refreshingText: {
    type: String,
    default: 'Refreshing...',
  },

  // Theme
  theme: {
    type: String,
    default: 'light', // light, dark, auto
    validator: (value) => ['light', 'dark', 'auto'].includes(value),
  },
});

// Progress ring calculations
const radius = 16;
const circumference = 2 * Math.PI * radius;

const progressOffset = computed(() => {
  return circumference - (props.pullProgress * circumference);
});
</script>

<style scoped>
.pull-to-refresh-indicator {
  @apply fixed left-1/2 transform -translate-x-1/2 z-50;
  @apply flex flex-col items-center justify-center;
  @apply bg-white dark:bg-gray-800 rounded-2xl shadow-lg;
  @apply px-6 py-4 min-w-[200px];
  @apply border border-gray-200 dark:border-gray-700;
  @apply backdrop-blur-sm bg-white/90 dark:bg-gray-800/90;
  top: 80px; /* Sufficient margin to avoid header */
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  pointer-events: none;
  user-select: none;
}

.indicator-container {
  @apply relative flex items-center justify-center w-10 h-10 mb-2;
}

.pull-arrow {
  @apply absolute inset-0 flex items-center justify-center;
  @apply text-gray-500 dark:text-gray-400;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.pull-arrow.arrow-ready {
  @apply text-emerald-600 dark:text-emerald-400;
  transform: rotate(180deg) scale(1.1);
}

.loading-spinner {
  @apply absolute inset-0 flex items-center justify-center;
  @apply text-emerald-600 dark:text-emerald-400;
}

.progress-ring {
  @apply absolute inset-0 text-emerald-600 dark:text-emerald-400;
  transition: all 0.2s ease-out;
}

.progress-ring-background {
  @apply text-gray-300 dark:text-gray-600;
}

.progress-ring-progress {
  transition: stroke-dashoffset 0.2s ease-out;
}

.status-text {
  @apply text-sm font-medium text-center;
  @apply text-gray-700 dark:text-gray-300;
}

.ready-text {
  @apply text-emerald-600 dark:text-emerald-400 font-semibold;
}

.refreshing-text {
  @apply text-emerald-600 dark:text-emerald-400;
}

/* Indicator animations */
.pull-to-refresh-indicator.pulling {
  animation: pullBounce 0.3s ease-out;
}

.pull-to-refresh-indicator.refreshing {
  animation: refreshPulse 1.5s ease-in-out infinite;
}

.pull-to-refresh-indicator.ready {
  animation: readyGlow 0.5s ease-out;
}

/* Refresh overlay */
.refresh-overlay {
  @apply fixed inset-0 z-40;
  @apply bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm;
  @apply flex items-center justify-center;
  animation: fadeIn 0.3s ease-out;
}

.overlay-content {
  @apply flex flex-col items-center justify-center;
  @apply bg-white dark:bg-gray-800 rounded-2xl shadow-xl;
  @apply px-8 py-6 border border-gray-200 dark:border-gray-700;
  animation: slideUp 0.3s ease-out;
}

.overlay-spinner {
  @apply mb-3;
}

.overlay-text {
  @apply text-sm font-medium text-gray-700 dark:text-gray-300;
}

/* Animations */
@keyframes pullBounce {
  0% {
    transform: translateX(-50%) scale(0.9);
    opacity: 0;
  }
  100% {
    transform: translateX(-50%) scale(1);
    opacity: 1;
  }
}

@keyframes refreshPulse {
  0%, 100% {
    transform: translateX(-50%) scale(1);
  }
  50% {
    transform: translateX(-50%) scale(1.05);
  }
}

@keyframes readyGlow {
  0% {
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }
  50% {
    box-shadow: 0 10px 15px -3px rgba(16, 185, 129, 0.3);
  }
  100% {
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  }
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Responsive design */
@media (max-width: 480px) {
  .pull-to-refresh-indicator {
    @apply min-w-[180px] px-4 py-3;
  }
  
  .overlay-content {
    @apply px-6 py-4 mx-4;
  }
}

/* Dark mode enhancements */
@media (prefers-color-scheme: dark) {
  .pull-to-refresh-indicator {
    @apply bg-gray-800/95 border-gray-700/50;
  }
  
  .refresh-overlay {
    @apply bg-gray-900/90;
  }
  
  .overlay-content {
    @apply bg-gray-800/95 border-gray-700/50;
  }
}

/* High contrast mode */
@media (prefers-contrast: high) {
  .pull-to-refresh-indicator {
    @apply border-2 border-gray-900 dark:border-gray-100;
  }
  
  .pull-arrow,
  .loading-spinner,
  .progress-ring {
    @apply text-gray-900 dark:text-gray-100;
  }
}

/* Reduce motion for accessibility */
@media (prefers-reduced-motion: reduce) {
  .pull-to-refresh-indicator,
  .refresh-overlay,
  .overlay-content,
  .pull-arrow,
  .progress-ring-progress {
    animation: none !important;
    transition: none !important;
  }
  
  .loading-spinner .animate-spin {
    animation: none !important;
  }
}
</style>
