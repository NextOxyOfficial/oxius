<template>
  <div 
    ref="containerRef"
    class="pull-to-refresh-container"
    :class="{
      'pulling': isPulling,
      'refreshing': isRefreshing,
      'touch-device': isTouchDevice,
    }"
  >
    <!-- Pull to Refresh Indicator -->
    <PullToRefreshIndicator
      v-if="enabled"
      :is-pulling="isPulling"
      :is-refreshing="isRefreshing"
      :pull-distance="pullDistance"
      :pull-progress="pullProgress"
      :pull-opacity="pullOpacity"
      :refresh-ready="refreshReady"
      :show-indicator="showIndicator"
      :show-overlay="showOverlay"
      :pull-text="pullText"
      :release-text="releaseText"
      :refreshing-text="refreshingText"
      :theme="theme"
    />

    <!-- Content Wrapper -->
    <div 
      class="content-wrapper"
      :style="contentStyle"
    >
      <slot />
    </div>

    <!-- Auto Reload Feature -->
    <div
      v-if="autoReload && autoReloadEnabled"
      class="auto-reload-indicator"
      :class="{ 'visible': showAutoReloadIndicator }"
    >
      <div class="auto-reload-content">
        <UIcon name="i-heroicons-arrow-path" class="w-4 h-4 animate-spin" />
        <span class="text-sm">Auto-refreshing in {{ autoReloadCountdown }}s</span>
        <button
          @click="cancelAutoReload"
          class="cancel-btn"
        >
          <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
        </button>
      </div>
    </div>

    <!-- Network Status Indicator -->
    <div
      v-if="showNetworkStatus && !isOnline"
      class="network-status offline"
    >
      <UIcon name="i-heroicons-wifi-slash" class="w-4 h-4" />
      <span>You're offline</span>
    </div>    <!-- Refresh Success Toast -->
    <Teleport to="body">
      <div
        v-if="showSuccessToast"
        class="refresh-success-toast"
        @click="hideSuccessToast"
      >
        <div class="toast-content">
          <UIcon name="i-heroicons-check-circle" class="w-5 h-5 text-green-600 flex-shrink-0" />
          <span>{{ successMessage }}</span>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { usePullToRefresh } from '~/composables/usePullToRefresh';
import PullToRefreshIndicator from './PullToRefreshIndicator.vue';

const props = defineProps({
  // Core functionality
  enabled: {
    type: Boolean,
    default: true,
  },
  refreshCallback: {
    type: Function,
    required: true,
  },

  // Pull to refresh options
  threshold: {
    type: Number,
    default: 100,  // Increased from 80
  },
  maxPullDistance: {
    type: Number,
    default: 150,  // Increased from 120
  },
  resistance: {
    type: Number,
    default: 3.0,  // Increased from 2.5
  },
  hapticFeedback: {
    type: Boolean,
    default: true,
  },
  touchStartDelay: {
    type: Number,
    default: 300,  // New option: delay before activating pull
  },
  minPullDistance: {
    type: Number,
    default: 30,   // New option: minimum distance to consider as pull vs tap
  },

  // Appearance
  showIndicator: {
    type: Boolean,
    default: true,
  },
  showOverlay: {
    type: Boolean,
    default: false,
  },
  theme: {
    type: String,
    default: 'auto',
    validator: (value) => ['light', 'dark', 'auto'].includes(value),
  },

  // Text customization
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
  successMessage: {
    type: String,
    default: 'Content updated!',
  },

  // Auto reload feature
  autoReload: {
    type: Boolean,
    default: false,
  },
  autoReloadInterval: {
    type: Number,
    default: 300000, // 5 minutes
  },
  autoReloadCountdownDuration: {
    type: Number,
    default: 10, // 10 seconds countdown
  },

  // Network status
  showNetworkStatus: {
    type: Boolean,
    default: true,
  },

  // Content animation
  enableContentAnimation: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['refresh-start', 'refresh-end', 'refresh-success', 'refresh-error']);

// Container reference
const containerRef = ref(null);

// Success toast state
const showSuccessToast = ref(false);
const successToastTimeout = ref(null);

// Auto reload state
const autoReloadEnabled = ref(false);
const autoReloadCountdown = ref(0);
const autoReloadTimer = ref(null);
const autoReloadCountdownTimer = ref(null);
const showAutoReloadIndicator = ref(false);

// Network status
const isOnline = ref(true);

// Initialize pull to refresh
const {
  isRefreshing,
  isPulling,
  pullDistance,
  pullProgress,
  pullOpacity,
  refreshReady,
  isTouchDevice,
  initializePullToRefresh,
  manualRefresh,
  cleanup,
} = usePullToRefresh(async () => {
  emit('refresh-start');
  
  try {
    // Check if we're online first
    if (!navigator.onLine) {
      throw new Error("You're offline. Please check your internet connection.");
    }
    
    await props.refreshCallback();
    showRefreshSuccessToast();
    emit('refresh-success');
  } catch (error) {
    console.error('Refresh failed:', error);
    // Show offline message if network is the issue
    if (!navigator.onLine || (error?.message && error.message.includes('network') || error.message.includes('offline'))) {
      updateOnlineStatus(); // Update the online status indicator
    }
    emit('refresh-error', error);
  } finally {
    emit('refresh-end');
  }
}, {
  threshold: props.threshold,
  maxPullDistance: props.maxPullDistance,
  resistance: props.resistance,
  hapticFeedback: props.hapticFeedback,
  touchStartDelay: props.touchStartDelay,
  minPullDistance: props.minPullDistance,
});

// Content animation style
const contentStyle = computed(() => {
  if (!props.enableContentAnimation) return {};
  
  const translateY = isPulling.value && !isRefreshing.value 
    ? Math.min(pullDistance.value / 4, 20) 
    : 0;
  
  return {
    transform: `translateY(${translateY}px)`,
    transition: isPulling.value ? 'none' : 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
  };
});

// Show success toast
const showRefreshSuccessToast = () => {
  showSuccessToast.value = true;
  
  if (successToastTimeout.value) {
    clearTimeout(successToastTimeout.value);
  }
  
  successToastTimeout.value = setTimeout(() => {
    hideSuccessToast();
  }, 3000);
};

// Hide success toast
const hideSuccessToast = () => {
  showSuccessToast.value = false;
  if (successToastTimeout.value) {
    clearTimeout(successToastTimeout.value);
    successToastTimeout.value = null;
  }
};

// Auto reload functionality
const startAutoReload = () => {
  if (!props.autoReload) return;
  
  autoReloadEnabled.value = true;
  
  autoReloadTimer.value = setTimeout(() => {
    startAutoReloadCountdown();
  }, props.autoReloadInterval);
};

const startAutoReloadCountdown = () => {
  autoReloadCountdown.value = props.autoReloadCountdownDuration;
  showAutoReloadIndicator.value = true;
  
  autoReloadCountdownTimer.value = setInterval(() => {
    autoReloadCountdown.value--;
    
    if (autoReloadCountdown.value <= 0) {
      executeAutoReload();
    }
  }, 1000);
};

const executeAutoReload = () => {
  cancelAutoReload();
  manualRefresh();
  
  // Restart auto reload cycle
  setTimeout(() => {
    startAutoReload();
  }, 5000);
};

const cancelAutoReload = () => {
  showAutoReloadIndicator.value = false;
  
  if (autoReloadTimer.value) {
    clearTimeout(autoReloadTimer.value);
    autoReloadTimer.value = null;
  }
  
  if (autoReloadCountdownTimer.value) {
    clearInterval(autoReloadCountdownTimer.value);
    autoReloadCountdownTimer.value = null;
  }
  
  // Restart auto reload cycle
  setTimeout(() => {
    startAutoReload();
  }, 60000); // Wait 1 minute before restarting
};

// Network status monitoring
const updateOnlineStatus = () => {
  isOnline.value = navigator.onLine;
};

// Manual refresh method (exposed to parent)
const refresh = async () => {
  await manualRefresh();
};

// Initialize everything
onMounted(() => {
  if (props.enabled) {
    initializePullToRefresh(containerRef.value);
  }
  
  if (props.autoReload) {
    startAutoReload();
  }
  
  if (props.showNetworkStatus) {
    updateOnlineStatus();
    window.addEventListener('online', updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);
  }
});

// Cleanup
onUnmounted(() => {
  cleanup();
  hideSuccessToast();
  cancelAutoReload();
  
  if (props.showNetworkStatus) {
    window.removeEventListener('online', updateOnlineStatus);
    window.removeEventListener('offline', updateOnlineStatus);
  }
});

// Expose methods to parent
defineExpose({
  refresh,
  isRefreshing,
  isPulling,
  manualRefresh,
});
</script>

<style scoped>
.pull-to-refresh-container {
  @apply relative min-h-screen;
  @apply overflow-hidden;
  background: var(--color-gray-50, #f9fafb);
}

.pull-to-refresh-container.touch-device {
  @apply touch-pan-y;
  /* Optimize for touch interactions */
  -webkit-overflow-scrolling: touch;
  overscroll-behavior-y: none;
}

.content-wrapper {
  @apply relative z-10;
  @apply min-h-screen;
}

/* Auto reload indicator */
.auto-reload-indicator {
  @apply fixed bottom-20 left-1/2 transform -translate-x-1/2;
  @apply z-50 transition-all duration-300;
  @apply opacity-0 translate-y-4 pointer-events-none;
}

.auto-reload-indicator.visible {
  @apply opacity-100 translate-y-0 pointer-events-auto;
}

.auto-reload-content {
  @apply bg-white dark:bg-gray-800 rounded-full shadow-lg;
  @apply px-4 py-2 flex items-center gap-2;
  @apply border border-gray-200 dark:border-gray-700;
  @apply text-gray-700 dark:text-gray-300;
}

.cancel-btn {
  @apply p-1 rounded-full;
  @apply hover:bg-gray-100 dark:hover:bg-gray-700;
  @apply transition-colors duration-200;
}

/* Network status indicator */
.network-status {
  @apply fixed top-20 left-1/2 transform -translate-x-1/2;
  @apply z-50 px-4 py-2 rounded-full;
  @apply flex items-center gap-2 text-sm font-medium;
  @apply transition-all duration-300;
}

.network-status.offline {
  @apply bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300;
  @apply border border-red-200 dark:border-red-700;
}

/* Success toast */
.refresh-success-toast {
  @apply fixed top-20 left-1/2 transform -translate-x-1/2;
  @apply z-50 cursor-pointer;
  @apply transition-all duration-300;
  animation: successToastSlide 0.3s ease-out;
}

.toast-content {
  @apply bg-green-50 dark:bg-green-900/30 rounded-full;
  @apply px-4 py-2 flex items-center gap-2;
  @apply border border-green-200 dark:border-green-700;
  @apply text-green-700 dark:text-green-300 text-sm font-medium;
  min-width: 200px; /* Increased minimum width to fit content */
  white-space: nowrap; /* Prevent text wrapping */
  display: inline-flex; /* Use inline-flex for better spacing control */
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .pull-to-refresh-container {
    background: var(--color-gray-900, #111827);
  }
}

/* Animations */
@keyframes successToastSlide {
  from {
    opacity: 0;
    transform: translateX(-50%) translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }
}

/* Mobile optimizations */
@media (max-width: 640px) {
  .auto-reload-indicator {
    @apply bottom-16;
  }
  
  .auto-reload-content {
    @apply px-3 py-2 text-sm;
  }
  
  .network-status {
    @apply top-16 text-xs px-3 py-1;
  }
    .refresh-success-toast {
    @apply top-16;
    width: 90vw; /* Use viewport width on mobile */
    max-width: 300px; /* Set maximum width */
  }
  
  .toast-content {
    @apply px-3 py-2 text-xs;
    width: 100%; /* Fill the container */
    justify-content: center; /* Center content */
  }
}

/* Accessibility */
@media (prefers-reduced-motion: reduce) {
  .pull-to-refresh-container,
  .content-wrapper,
  .auto-reload-indicator,
  .network-status,
  .refresh-success-toast {
    transition: none !important;
    animation: none !important;
  }
}

/* High contrast mode */
@media (prefers-contrast: high) {
  .auto-reload-content,
  .network-status,
  .toast-content {
    @apply border-2;
  }
}
</style>
