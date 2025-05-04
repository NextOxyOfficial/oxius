<template>
  <div class="flex flex-col justify-between !items-center px-3 sm:px-5 py-3 sm:py-4 border-b border-gray-100 gap-3 sm:gap-4">
    <div class="bg-gray-50 rounded-lg inline-flex shadow-sm w-full sm:w-auto">
      <button
        v-for="tab in tabs"
        :key="tab.value"
        @click="$emit('update:activeTab', tab.value)"
        :class="[
          'relative px-1.5 sm:px-4 py-2 font-medium transition-all text-sm duration-200 ease-in-out',
          activeTab === tab.value
            ? 'text-blue-600 bg-white rounded-md shadow-sm'
            : 'text-gray-500 hover:text-gray-600',
        ]"
      >
        {{ tab.label }}
      </button>
    </div>

    <div class="w-full sm:max-w-64 md:max-w-80">
      <div class="relative w-full">
        <Search class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
        <svg
          v-if="isSearching"
          class="animate-spin absolute right-3 top-2.5 h-4 w-4 text-gray-400"
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
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          ></path>
        </svg>
        <input
          type="text"
          placeholder="Search problems..."
          class="flex h-10 w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-md ring-offset-background file:border-0 file:bg-transparent file:text-md file:font-medium placeholder:text-gray-400 focus:border-blue-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-blue-400 disabled:cursor-not-allowed disabled:opacity-50 pl-10 pr-10 transition-all"
          v-model="searchQueryModel"
          @input="handleSearch"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { Search } from "lucide-vue-next";
import { ref, computed } from "vue";

const props = defineProps({
  tabs: {
    type: Array,
    required: true
  },
  activeTab: {
    type: String,
    required: true
  },
  searchQuery: {
    type: String,
    default: ""
  },
  isSearching: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['update:activeTab', 'update:searchQuery', 'search']);

const searchQueryModel = computed({
  get: () => props.searchQuery,
  set: (value) => emit('update:searchQuery', value)
});

const handleSearch = () => {
  emit('search');
};
</script>