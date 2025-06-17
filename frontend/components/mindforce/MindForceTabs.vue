<template>
  <div
    class="flex justify-center items-center px-3 sm:px-5 py-3 sm:py-4 border-b border-slate-100 dark:border-slate-700 bg-white dark:bg-slate-800/50"
  >
    <!-- Enhanced tabs with animated indicator -->
    <div
      class="relative bg-slate-50 dark:bg-slate-800 rounded-lg inline-flex shadow-sm overflow-hidden"
    >
      <div
        class="absolute h-full transition-all duration-300 bg-white dark:bg-slate-700 rounded-md shadow-sm tab-indicator"
        :style="{
          width: `${100 / tabs.length}%`,
          transform: `translateX(${tabs.findIndex(t => t.value === activeTab) * 100}%)`,
        }"
      ></div>

      <button
        v-for="tab in tabs"
        :key="tab.value"
        @click="$emit('update:activeTab', tab.value)"
        :class="[
          'relative px-3 sm:px-5 py-2 font-medium transition-all text-sm z-10 flex-1 text-center',
          activeTab === tab.value
            ? 'text-blue-600 dark:text-blue-400'
            : 'text-slate-500 dark:text-slate-400 hover:text-gray-600 dark:hover:text-slate-300',
        ]"
      >
        {{ tab.label }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from "vue";

const props = defineProps({
  tabs: {
    type: Array,
    required: true,
  },
  activeTab: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(["update:activeTab"]);

// Add subtle animation on mount
onMounted(() => {
  const tabsElement = document.querySelector(".tab-indicator");
  if (tabsElement) {
    tabsElement.classList.add("animate-pulse-once");
    setTimeout(() => {
      tabsElement.classList.remove("animate-pulse-once");
    }, 1000);
  }
});
</script>

<style scoped>
/* Tab indicator animation */
@keyframes pulse-once {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.animate-pulse-once {
  animation: pulse-once 1s;
}

/* Handle responsive tabs */
@media (max-width: 640px) {
  .tab-indicator {
    width: calc(100% / v-bind("tabs.length")) !important;
  }
}
</style>
