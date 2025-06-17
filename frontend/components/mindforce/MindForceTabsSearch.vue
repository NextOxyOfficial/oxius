<template>
  <div
    class="px-3 sm:px-5 py-3 sm:py-4 border-b border-slate-100 dark:border-slate-700 bg-white dark:bg-slate-800/50"
  >
    <!-- Enhanced tabs with animated indicator -->
    <div
      class="relative bg-slate-100 dark:bg-slate-800 rounded-lg flex shadow-sm overflow-hidden w-full max-w-2xl mx-auto"
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
          'relative px-2 sm:px-4 py-2.5 font-medium transition-all text-xs sm:text-sm z-10 flex-1 text-center min-w-0',
          activeTab === tab.value
            ? 'text-blue-600 dark:text-blue-400'
            : 'text-slate-500 dark:text-slate-400 hover:text-gray-600 dark:hover:text-slate-300',
        ]"
      >
        <span class="truncate block">{{ getTabLabel(tab.label) }}</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from "vue";

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

// Helper function to shorten tab labels on mobile
const getTabLabel = (label) => {
  // Use computed to make it reactive to screen size
  if (typeof window !== 'undefined' && window.innerWidth < 640) {
    const shortLabels = {
      "Active Problems": "Active",
      "Solved Problems": "Solved", 
      "My Problems": "My Posts"
    };
    return shortLabels[label] || label;
  }
  return label;
};

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

/* Ensure tabs fit properly on all screen sizes */
@media (max-width: 480px) {
  .tab-indicator {
    border-radius: 6px;
  }
}

/* Handle very small screens */
@media (max-width: 320px) {
  button span {
    font-size: 0.75rem;
  }
}
</style>
