<template>
  <div>
    <h3
      class="text-xs font-semibold text-gray-600 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
    >
      <div class="flex items-center">
        <Users class="h-3.5 w-3.5 mr-1.5" />
        <span>Top Contributors</span>
      </div>      <div
        @click="handleButtonClick('see_all_contributors'); showTopContributorsModal = true"
        class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center cursor-pointer hover:text-blue-700 transition-colors"
      >
        <span>See All</span>
        <div v-if="loadingButtons.has('see_all_contributors')" class="dotted-spinner blue ml-0.5"></div>
        <ChevronRight v-else class="h-3 w-3 ml-0.5" />
      </div>
    </h3>
    <div class="space-y-2">
      <div
        v-if="isLoading"
        class="flex justify-center items-center h-20 bg-gray-50 rounded-lg"
      >
        <div
          class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"
        ></div>
      </div>
      <a
        v-else
        v-for="(contributor, index) in contributors"
        :key="index"
        :href="`/business-network/profile/${contributor.id}`"
        class="flex items-center px-3 py-2 rounded-md hover:bg-gray-50 transition-colors"
        @click.prevent="$emit('navigation', `/business-network/profile/${contributor.id}`)"
      >
        <div class="relative">
          <img
            :src="contributor.image || '/static/frontend/images/placeholder.jpg'"
            :alt="contributor.name"
            class="size-7 rounded-full object-cover border-2 border-white shadow-sm"
          />
          <!-- Pro badge -->
          <div
            v-if="contributor.is_pro"
            class="absolute -bottom-1 -right-1 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full w-3 h-3 flex items-center justify-center text-xs font-semibold shadow-sm"
          >
            P
          </div>
        </div>
        <div class="ml-3 min-w-0">
          <h4 class="text-sm font-medium text-gray-800 truncate">
            {{ contributor.name }}
          </h4>
          <p class="text-xs text-gray-600 flex items-center">
            <FileText class="h-3 w-3 mr-1" />
            <span>{{ contributor.post_count || 0 }} posts</span>
            <Users class="h-3 w-3 mx-1" />
            <span>{{ contributor.follower_count || 0 }}</span>
          </p>
        </div>
        <div class="ml-auto">
          <div
            class="text-xs px-1.5 py-0.5 bg-blue-50 text-blue-600 rounded-md border border-blue-100"
          >
            <Trophy class="h-3 w-3" />
          </div>
        </div>
      </a>
    </div>

    <!-- Top Contributors Modal -->
    <TopContributorsModal 
      :is-open="showTopContributorsModal" 
      @close="showTopContributorsModal = false" 
      @navigate="handleNavigation" 
    />
  </div>
</template>

<script setup>
import { Users, ChevronRight, FileText, Trophy } from "lucide-vue-next";
import TopContributorsModal from './TopContributorsModal.vue';

const props = defineProps({
  contributors: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  }
});

// State
const showTopContributorsModal = ref(false);

// Loading state for buttons
const loadingButtons = ref(new Set());

// Handle button clicks with loading states
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
};

// Watch route changes to clear loading states
watch(() => useRoute().fullPath, () => {
  loadingButtons.value.clear();
});

// Events
const emit = defineEmits(['navigation']);

// Handle contributor navigation from modal
const handleNavigation = (path) => {
  emit('navigation', path);
};
</script>

<style scoped>
/* Add subtle hover effect for contributor items */
a {
  transition: all 0.2s ease;
}

a:hover {
  transform: translateX(2px);
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 0.75rem;
  height: 0.75rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.emerald {
  border-color: #059669;
}

.dotted-spinner.green {
  border-color: #16a34a;
}

.dotted-spinner.slate {
  border-color: #64748b;
}

.dotted-spinner.blue {
  border-color: #3b82f6;
}

.dotted-spinner.violet {
  border-color: #8b5cf6;
}

.dotted-spinner.white {
  border-color: #ffffff;
}

.dotted-spinner.primary {
  border-color: #059669;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>