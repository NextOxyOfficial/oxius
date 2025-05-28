<template>
  <div
    class="flex flex-col sm:flex-row justify-between items-center px-3 sm:px-5 py-3 sm:py-4 border-b border-slate-100 dark:border-slate-700 gap-3 sm:gap-6 bg-white dark:bg-slate-800/50"
  >
    <!-- Enhanced tabs with animated indicator -->
    <div
      class="relative bg-slate-50 dark:bg-slate-800 rounded-lg inline-flex shadow-sm w-full sm:w-auto overflow-hidden"
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

    <!-- Enhanced searchbox with premium styling -->
    <div class="w-full sm:max-w-64 md:max-w-80">
      <div class="relative w-full group">
        <div
          class="absolute left-3 top-2.5 h-5 w-5 text-slate-400 dark:text-slate-500 transition-all group-hover:text-blue-500"
        >
          <Search class="h-4 w-4" />
        </div>

        <div
          v-if="isSearching"
          class="absolute right-3 top-2.5 h-5 w-5 flex items-center justify-center"
        >
          <svg
            class="animate-spin h-4 w-4 text-blue-500"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              class="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              stroke-width="4"
            ></circle>
            <path
              class="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            ></path>
          </svg>
        </div>

        <input
          type="text"
          placeholder="Search problems..."
          class="flex h-10 w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-md ring-offset-background placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-blue-400 dark:focus:border-blue-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 dark:focus-visible:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-50 pl-10 pr-10 transition-all shadow-sm"
          v-model="searchQueryModel"
          @input="handleSearch"
        />

        <!-- Animated glow effect on focus -->
        <div
          class="absolute inset-0 rounded-lg -z-10 opacity-0 group-focus-within:opacity-100 bg-gradient-to-r from-blue-400/20 via-violet-400/20 to-blue-400/20 blur-md transition-opacity"
        ></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Search } from "lucide-vue-next";
import { ref, computed, onMounted } from "vue";

const props = defineProps({
  tabs: {
    type: Array,
    required: true,
  },
  activeTab: {
    type: String,
    required: true,
  },
  searchQuery: {
    type: String,
    default: "",
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(["update:activeTab", "update:searchQuery", "search"]);

const searchQueryModel = computed({
  get: () => props.searchQuery,
  set: value => emit("update:searchQuery", value),
});

const handleSearch = () => {
  emit("search");
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

/* Handle responsive tabs */
@media (max-width: 640px) {
  .tab-indicator {
    width: calc(100% / v-bind("tabs.length")) !important;
  }
}
</style>
