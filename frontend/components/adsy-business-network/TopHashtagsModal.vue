<template>
  <Teleport to="body">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-50 overflow-y-auto"
      :class="{ 'animate-fade-in': isModalOpen }"
      @click.self="closeModal"
    >
      <div
        class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
        aria-hidden="true"
        @click="isOpen = false"
      ></div>
      <div
        class="flex items-center sm:items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0 mt-0 sm:mt-20"
      >
        <div
          class="relative max-w-xl w-full mx-auto my-8 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-xl shadow-sm border border-white/20 dark:border-slate-700/40 overflow-hidden"
          :class="{ 'animate-modal-slide-up': isOpen }"
          @click.stop
        >
          <!-- Modal Header -->
          <div class="w-full overflow-hidden overflow-y-auto custom-scrollbar">
            <div
              class="p-5 border-b border-gray-200 dark:border-gray-800 flex justify-between items-center bg-gradient-to-r from-blue-600 to-indigo-600 text-white"
            >
              <h2 class="text-xl font-semibold flex items-center">
                <Hash class="h-5 w-5 mr-2" />
                Top 100 Trending Hashtags
              </h2>
              <button
                @click="closeModal"
                class="p-1.5 rounded-full bg-white/20 hover:bg-white/30 transition-colors"
                aria-label="Close modal"
              >
                <X class="h-5 w-5" />
              </button>
            </div>
          </div>

          <!-- Loading State -->
          <div
            v-if="isLoading"
            class="flex-1 flex flex-col items-center justify-center p-8"
          >
            <div class="relative">
              <div
                class="h-16 w-16 rounded-full border-4 border-gray-200 dark:border-gray-700"
              ></div>
              <div
                class="absolute top-0 left-0 h-16 w-16 rounded-full border-t-4 border-blue-600 animate-spin"
              ></div>
              <Hash class="h-8 w-8 text-blue-600 absolute top-4 left-4" />
            </div>
            <p class="mt-4 text-gray-500 dark:text-gray-500">
              Loading trending hashtags...
            </p>
          </div>

          <!-- Error State -->
          <div
            v-else-if="error"
            class="flex-1 flex flex-col items-center justify-center p-8 text-red-500"
          >
            <AlertCircle class="h-16 w-16 mb-4" />
            <p class="text-center">{{ error }}</p>
            <button
              @click="fetchTopHashtags"
              class="mt-6 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors flex items-center"
            >
              <RefreshCw class="h-4 w-4 mr-2" />
              Try Again
            </button>
          </div>

          <!-- Content with Search and Filter -->
          <div v-else class="flex-1 flex flex-col min-h-0 overflow-hidden">
            <div class="p-4 border-b border-gray-200 dark:border-gray-800">
              <div class="relative">
                <div
                  class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
                >
                  <Search class="h-5 w-5 text-gray-500" />
                </div>
                <input
                  type="search"
                  v-model="searchQuery"
                  class="w-full p-2.5 pl-10 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Search hashtags..."
                />
              </div>
            </div>

            <!-- Hashtags List -->
            <div class="flex-1 overflow-y-auto p-2 hashtags-container">
              <div class="overflow-hidden">
                <TransitionGroup
                  tag="ul"
                  class="divide-y divide-gray-200 dark:divide-gray-700"
                  enter-active-class="transition-all duration-300 ease-out"
                  enter-from-class="opacity-0 -translate-x-4"
                  enter-to-class="opacity-100 translate-x-0"
                  move-class="transition-transform duration-500"
                >
                  <li
                    v-for="(tag, index) in filteredHashtags"
                    :key="tag.id"
                    :style="{ animationDelay: `${index * 0.03}s` }"
                    class="hashtag-item py-3 px-4 hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors group"
                    @click="navigateToHashtag(tag)"
                  >
                    <div class="flex items-center gap-3">
                      <!-- Rank Badge -->
                      <div
                        class="w-8 h-8 flex items-center justify-center rounded-full shrink-0"
                        :class="getRankBadgeClass(index)"
                      >
                        <span class="font-semibold text-sm">{{ index + 1 }}</span>
                      </div>

                      <!-- Hashtag Info -->
                      <div class="flex flex-col flex-1 min-w-0">
                        <div class="flex items-center justify-between">
                          <h3
                            class="text-base font-semibold text-gray-700 dark:text-gray-200 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors truncate"
                          >
                            #{{ tag.tag }}
                          </h3>
                          <span
                            class="text-xs text-gray-500 dark:text-gray-500"
                          >
                            {{ tag.count }}
                            {{ tag.count === 1 ? "post" : "posts" }}
                          </span>
                        </div>

                        <!-- Popularity Bar -->
                        <div
                          class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5 mt-2 overflow-hidden"
                        >
                          <div
                            class="h-1.5 rounded-full popularity-bar transition-all group-hover:brightness-110"
                            :class="getBarColorClass(index)"
                            :style="{
                              width: `${(tag.count / maxCount) * 100}%`,
                            }"
                          ></div>
                        </div>
                      </div>

                      <!-- Arrow -->
                      <ChevronRight
                        class="h-4 w-4 text-gray-500 group-hover:text-blue-500 group-hover:translate-x-1 transition-all duration-300"
                      />
                    </div>
                  </li>
                </TransitionGroup>
              </div>

              <!-- Empty Result -->
              <div
                v-if="filteredHashtags.length === 0"
                class="flex flex-col items-center justify-center py-8 text-gray-500"
              >
                <Search class="h-12 w-12 mb-2 opacity-50" />
                <p class="text-center">
                  No hashtags found matching "{{ searchQuery }}"
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import {
  Hash,
  X,
  AlertCircle,
  RefreshCw,
  Search,
  ChevronRight,
  FileText,
} from "lucide-vue-next";

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(["close", "navigate"]);

// State
const { get } = useApi();
const isLoading = ref(true);
const error = ref(null);
const hashtags = ref([]);
const searchQuery = ref("");

// Computed properties
const maxCount = computed(() => {
  if (!hashtags.value.length) return 1;
  return Math.max(...hashtags.value.map((tag) => tag.count));
});

const filteredHashtags = computed(() => {
  if (!searchQuery.value.trim()) {
    return hashtags.value;
  }

  const query = searchQuery.value.trim().toLowerCase();
  return hashtags.value.filter((tag) => tag.tag.toLowerCase().includes(query));
});

// Methods
const fetchTopHashtags = async () => {
  isLoading.value = true;
  error.value = null;

  try {
    // First try to get from top-tags endpoint
    const response = await get("/bn/top-tags/");
    if (response.data && Array.isArray(response.data)) {
      hashtags.value = response.data;
    } else {
      // Fallback to trending-tags endpoint if first one fails
      const fallbackResponse = await get("/bn/trending-tags/?limit=100");
      if (fallbackResponse.data && Array.isArray(fallbackResponse.data)) {
        hashtags.value = fallbackResponse.data;
      } else {
        throw new Error("Unexpected response format from both endpoints");
      }
    }

    // Apply animation delay for staggered appearance
    hashtags.value = hashtags.value.map((tag, index) => ({
      ...tag,
      animationDelay: `${index * 0.05}s`, // 50ms delay between each item
    }));
  } catch (err) {
    console.error("Error fetching top hashtags:", err);
    error.value = "Failed to load trending hashtags. Please try again later.";
  } finally {
    isLoading.value = false;
  }
};

const closeModal = () => {
  emit("close");
};

const navigateToHashtag = (tag) => {
  emit("navigate", tag);
  closeModal();
};

// Utility methods to add visual appeal

// Get position-based styling for rank badges
const getRankBadgeClass = (index) => {
  if (index === 0)
    return "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300"; // 1st place
  if (index === 1)
    return "bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-400"; // 2nd place
  if (index === 2)
    return "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300"; // 3rd place
  return "bg-blue-50 text-blue-700 dark:bg-blue-900/20 dark:text-blue-300"; // Rest
};

// Get color class for popularity bar based on rank
const getBarColorClass = (index) => {
  if (index === 0) return "bg-gradient-to-r from-yellow-400 to-yellow-500"; // 1st
  if (index === 1) return "bg-gradient-to-r from-gray-400 to-gray-500"; // 2nd
  if (index === 2) return "bg-gradient-to-r from-amber-400 to-amber-500"; // 3rd
  if (index < 10) return "bg-gradient-to-r from-blue-400 to-blue-500"; // Top 10
  return "bg-gradient-to-r from-indigo-400 to-indigo-500"; // Rest
};

// Watch for open state changes to fetch data when modal opens
watch(
  () => props.isOpen,
  (isOpen) => {
    if (isOpen) {
      fetchTopHashtags();
    }
  }
);

// Keyboard handlers
onMounted(() => {
  const handleEscape = (e) => {
    if (e.key === "Escape" && props.isOpen) {
      closeModal();
    }
  };

  document.addEventListener("keydown", handleEscape);

  onUnmounted(() => {
    document.removeEventListener("keydown", handleEscape);
  });
});
</script>

<style scoped>
.hashtags-container {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.hashtags-container::-webkit-scrollbar {
  width: 6px;
}

.hashtags-container::-webkit-scrollbar-track {
  background: transparent;
}

.hashtags-container::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 20px;
}

.hashtag-item {
  animation: fadeInRight 0.5s ease-out forwards;
  opacity: 0;
}

@keyframes fadeInRight {
  from {
    opacity: 0;
    transform: translateX(-10px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.popularity-bar {
  animation: growWidth 1s ease-out forwards;
  transform-origin: left;
}

@keyframes growWidth {
  from {
    transform: scaleX(0);
  }
  to {
    transform: scaleX(1);
  }
}

/* Hover effects */
.hashtag-item:hover {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}
</style>
