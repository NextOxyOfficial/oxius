<template>
  <div>
    <h3
      class="text-xs font-semibold text-gray-600 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
    >
      <div class="flex items-center">
        <Hash class="h-3.5 w-3.5 mr-1.5" />
        <span>Trending Hashtags</span>
      </div>      <div
        @click="handleButtonClick('top100')"
        class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center cursor-pointer hover:text-blue-700 transition-colors"
      >
        <span>Top 100</span>
        <div v-if="loadingButtons.top100" class="spinner-blue ml-0.5"></div>
        <ChevronRight v-else class="h-3 w-3 ml-0.5" />
      </div>
    </h3>
    <div class="px-3">
      <div
        v-if="isLoading"
        class="text-sm text-gray-600 py-2"
      >
        Loading trending hashtags...
      </div>
      <div
        v-else-if="tags.length === 0"
        class="text-sm text-gray-600 py-2"
      >
        No trending hashtags available.
      </div>
      <ul v-else class="space-y-1 divide-y divide-gray-100">
        <li
          v-for="(tag, index) in tags.slice(0, 7)"
          :key="tag.id"
          class="py-1.5 group cursor-pointer"
          @click="$emit('tag-click', tag)"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <div class="p-1 rounded bg-blue-50 group-hover:bg-blue-100 transition-colors mr-2">
                <Hash class="h-3 w-3 text-blue-600" />
              </div>
              <span class="text-sm text-gray-800 font-medium group-hover:text-blue-600 transition-colors">
                #{{ tag.tag }}
              </span>
            </div>
            <div class="text-xs text-gray-600">
              {{ tag.count || '0' }}
            </div>
          </div>
          <!-- Progress bar showing popularity -->
          <div class="w-full h-1 bg-gray-100 rounded-full mt-1 overflow-hidden">
            <div 
              class="h-1 bg-blue-500 rounded-full transition-all group-hover:bg-blue-600"
              :style="{
                width: `${getPercentage(tag)}%`
              }"
            ></div>
          </div>
        </li>
      </ul>
    </div>

    <!-- Top Hashtags Modal -->
    <TopHashtagsModal 
      :is-open="showTopHashtagsModal" 
      @close="showTopHashtagsModal = false" 
      @navigate="handleTagNavigation" 
    />
  </div>
</template>

<script setup>
import { Hash, ChevronRight } from "lucide-vue-next";
import TopHashtagsModal from './TopHashtagsModal.vue';

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
    default: 7
  }
});

// State
const showTopHashtagsModal = ref(false);
const loadingButtons = ref({});

// Handle button click with loading state
const handleButtonClick = (buttonId) => {
  loadingButtons.value[buttonId] = true;
  
  if (buttonId === 'top100') {
    showTopHashtagsModal.value = true;
  }
  
  // Clear loading state after a brief delay
  setTimeout(() => {
    loadingButtons.value[buttonId] = false;
  }, 800);
};

// Clear loading states on route change
watch(() => useRoute().path, () => {
  loadingButtons.value = {};
});

// Emit events for tag click
const emit = defineEmits(['tag-click']);

// Handle tag click from modal
const handleTagNavigation = (tag) => {
  emit('tag-click', tag);
};

// Calculate percentage for progress bar width
const getPercentage = (tag) => {
  if (!props.tags.length) return 0;
  
  // Find max count
  const maxCount = Math.max(...props.tags.map(t => t.count || 0));
  if (maxCount <= 0) return 0;
  
  // Calculate percentage (minimum 10% for visibility)
  return Math.max(10, ((tag.count || 0) / maxCount) * 100);
};
</script>

<style scoped>
/* Add subtle hover animation */
li.group {
  transition: transform 0.2s ease;
}

li.group:hover {
  transform: translateX(2px);
}

/* Blue dotted spinner */
.spinner-blue {
  width: 12px;
  height: 12px;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>