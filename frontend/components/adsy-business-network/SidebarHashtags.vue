<template>
  <div>
    <h3
      class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
    >
      <div class="flex items-center">
        <Hash class="h-3.5 w-3.5 mr-1.5" />
        <span>Trending Hashtags</span>
      </div>
      <div
        class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center"
      >
        <span>Top 100</span>
        <ChevronRight class="h-3 w-3 ml-0.5" />
      </div>
    </h3>
    <div class="flex flex-wrap gap-2 px-3">
      <p
        v-if="isLoading"
        class="text-sm text-gray-500 py-2"
      >
        Loading trending hashtags...
      </p>
      <p
        v-else-if="tags.length === 0"
        class="text-sm text-gray-500 py-2"
      >
        No trending hashtags available.
      </p>
      <p
        v-for="tag in tags.slice(0, maxTags)"
        :key="tag.id"
        class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 hover:bg-blue-50 hover:text-blue-600 transition-colors"
        @click="$emit('tag-click', tag)"
      >
        <span>#{{ tag.tag }}</span>
      </p>
    </div>
  </div>
</template>

<script setup>
import { Hash, ChevronRight } from "lucide-vue-next";

// Props definition
const props = defineProps({
  tags: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  maxTags: {
    type: Number,
    default: 30
  }
});

// Emit events for tag click
const emit = defineEmits(['tag-click']);
</script>

<style scoped>
/* Hover animation for hashtags */
.inline-flex {
  cursor: pointer;
}
</style>