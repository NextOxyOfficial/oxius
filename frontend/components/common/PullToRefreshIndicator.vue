<template>
  <Transition
    enter-active-class="transition-all duration-300 ease-out"
    enter-from-class="opacity-0 -translate-y-full"
    enter-to-class="opacity-100 translate-y-0"
    leave-active-class="transition-all duration-200 ease-in"
    leave-from-class="opacity-100 translate-y-0"
    leave-to-class="opacity-0 -translate-y-full"
  >
    <div
      v-if="visible"
      class="fixed top-0 left-0 right-0 z-50 bg-gradient-to-r from-emerald-500 to-blue-500 text-white"
      :style="{ transform: `translateY(${Math.max(0, pullDistance - 60)}px)` }"
    >
      <div class="flex items-center justify-center py-3 px-4">
        <!-- Refresh Icon with Animation -->
        <div class="relative flex items-center space-x-3">
          <!-- Spinning Loader when refreshing -->
          <div
            v-if="isRefreshing"
            class="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"
          ></div>
          
          <!-- Pull Progress Indicator -->
          <div
            v-else
            class="relative w-6 h-6 flex items-center justify-center"
          >
            <!-- Circular Progress -->
            <svg
              class="w-6 h-6 transform -rotate-90"
              viewBox="0 0 24 24"
            >
              <circle
                cx="12"
                cy="12"
                r="10"
                stroke="white"
                stroke-opacity="0.3"
                stroke-width="2"
                fill="none"
              />
              <circle
                cx="12"
                cy="12"
                r="10"
                stroke="white"
                stroke-width="2"
                fill="none"
                stroke-linecap="round"
                :stroke-dasharray="62.83185307179586"
                :stroke-dashoffset="62.83185307179586 * (1 - pullProgress)"
                class="transition-all duration-150 ease-out"
              />
            </svg>
            
            <!-- Arrow Icon -->
            <UIcon
              :name="willRefresh ? 'i-heroicons-arrow-up' : 'i-heroicons-arrow-down'"
              class="absolute w-3 h-3 text-white transition-transform duration-200"
              :class="{ 'rotate-180': willRefresh }"
            />
          </div>
          
          <!-- Status Text -->
          <div class="flex flex-col">
            <span class="text-sm font-medium">
              {{ statusText }}
            </span>
            <span v-if="!isRefreshing" class="text-xs opacity-75">
              {{ pullPercentage }}% {{ willRefresh ? 'Release to refresh' : 'Pull down' }}
            </span>
          </div>
        </div>
      </div>
      
      <!-- Progress Bar -->
      <div class="absolute bottom-0 left-0 right-0 h-0.5 bg-white/20">
        <div
          class="h-full bg-white transition-all duration-150 ease-out"
          :style="{ width: `${pullPercentage}%` }"
        ></div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  isRefreshing: {
    type: Boolean,
    default: false
  },
  pullDistance: {
    type: Number,
    default: 0
  },
  pullProgress: {
    type: Number,
    default: 0
  },
  willRefresh: {
    type: Boolean,
    default: false
  },
  pullPercentage: {
    type: Number,
    default: 0
  }
});

// Status text based on current state
const statusText = computed(() => {
  if (props.isRefreshing) {
    return 'Refreshing...';
  }
  if (props.willRefresh) {
    return 'Release to refresh';
  }
  return 'Pull to refresh';
});
</script>

<style scoped>
/* Additional custom animations if needed */
.pull-indicator-enter-active,
.pull-indicator-leave-active {
  transition: all 0.3s ease;
}

.pull-indicator-enter-from,
.pull-indicator-leave-to {
  opacity: 0;
  transform: translateY(-100%);
}
</style>
