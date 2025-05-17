<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="isOpen"
        class="fixed inset-0 z-[99] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 overflow-hidden"
        @click.self="closeModal"
      >
        <Transition
          enter-active-class="transition-all duration-300 ease-out"
          enter-from-class="opacity-0 translate-y-8 scale-95"
          enter-to-class="opacity-100 translate-y-0 scale-100"
          leave-active-class="transition-all duration-200 ease-in"
          leave-from-class="opacity-100 translate-y-0 scale-100"
          leave-to-class="opacity-0 translate-y-8 scale-95"
        >
          <div
            v-if="isOpen"
            class="bg-white dark:bg-gray-900 rounded-xl max-w-2xl w-full max-h-[80vh] overflow-hidden shadow-sm flex flex-col"
            @click.stop
          >
            <!-- Modal Header -->
            <div class="p-5 border-b border-gray-200 dark:border-gray-800 flex justify-between items-center bg-gradient-to-r from-amber-500 to-yellow-500 text-white">
              <h2 class="text-xl font-semibold flex items-center">
                <Trophy class="h-5 w-5 mr-2" />
                All Contributors
              </h2>
              <button
                @click="closeModal"
                class="p-1.5 rounded-full bg-white/20 hover:bg-white/30 transition-colors"
                aria-label="Close modal"
              >
                <X class="h-5 w-5" />
              </button>
            </div>

            <!-- Loading State -->
            <div
              v-if="isLoading"
              class="flex-1 flex flex-col items-center justify-center p-8"
            >
              <div class="relative">
                <div class="h-16 w-16 rounded-full border-4 border-gray-200 dark:border-gray-700"></div>
                <div class="absolute top-0 left-0 h-16 w-16 rounded-full border-t-4 border-amber-500 animate-spin"></div>
                <Trophy class="h-8 w-8 text-amber-500 absolute top-4 left-4" />
              </div>
              <p class="mt-4 text-gray-600 dark:text-gray-400">Loading contributors...</p>
            </div>

            <!-- Error State -->
            <div
              v-else-if="error"
              class="flex-1 flex flex-col items-center justify-center p-8 text-red-500"
            >
              <AlertCircle class="h-16 w-16 mb-4" />
              <p class="text-center">{{ error }}</p>
              <button
                @click="fetchContributors"
                class="mt-6 px-4 py-2 bg-amber-500 text-white rounded-md hover:bg-amber-600 transition-colors flex items-center"
              >
                <RefreshCw class="h-4 w-4 mr-2" />
                Try Again
              </button>
            </div>

            <!-- Content with Search and Filter -->
            <div v-else class="flex-1 flex flex-col min-h-0 overflow-hidden">
              <div class="p-4 border-b border-gray-200 dark:border-gray-800">
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                    <Search class="h-5 w-5 text-gray-500" />
                  </div>
                  <input
                    type="search"
                    v-model="searchQuery"
                    class="w-full p-2.5 pl-10 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-amber-500"
                    placeholder="Search contributors..."
                  />
                </div>
              </div>

              <!-- Contributors List -->
              <div class="flex-1 overflow-y-auto p-2 contributors-container">
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
                      v-for="(contributor, index) in filteredContributors"
                      :key="contributor.id"
                      :style="{ animationDelay: `${index * 0.03}s` }"
                      class="contributor-item py-3 px-4 hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-colors group"
                      @click="navigateToProfile(contributor)"
                    >
                      <div class="flex items-center gap-3">
                        <!-- Rank Badge -->
                        <div 
                          class="w-8 h-8 flex items-center justify-center rounded-full shrink-0"
                          :class="getRankBadgeClass(index)"
                        >
                          <span class="font-semibold text-sm">{{ index + 1 }}</span>
                        </div>
                        
                        <!-- Profile Image -->
                        <div class="relative">
                          <img 
                            :src="contributor.image || '/static/frontend/avatar.png'" 
                            :alt="contributor.name"
                            class="w-10 h-10 rounded-full object-cover border-2 border-white shadow-sm"
                          />
                        </div>
                        
                        <!-- Contributor Info -->
                        <div class="flex flex-col flex-1 min-w-0">
                          <div class="flex items-center justify-between">
                            <h3 class="text-base font-semibold text-gray-900 dark:text-gray-100 group-hover:text-amber-500 dark:group-hover:text-amber-400 transition-colors truncate">
                              {{ contributor.name }}
                            </h3>
                          </div>
                          
                          <!-- Main stats: Post count and Follower count -->
                          <div class="flex text-xs text-gray-500 mt-1 gap-4">
                            <div class="flex items-center">
                              <FileText class="h-3 w-3 mr-1" />
                              <span>{{ contributor.post_count || 0 }} posts</span>
                            </div>
                            <div class="flex items-center">
                              <Users class="h-3 w-3 mr-1" />
                              <span>{{ contributor.follower_count || 0 }} followers</span>
                            </div>
                          </div>
                          
                          <!-- Profession and Company -->
                          <div class="flex text-xs text-gray-500 mt-1 gap-4 overflow-hidden">
                            <div v-if="contributor?.profession" class="flex items-center overflow-hidden">
                              <Briefcase class="h-3 w-3 mr-1 shrink-0" />
                              <span class="truncate">{{ contributor.profession }}</span>
                            </div>
                            <div v-if="contributor?.company" class="flex items-center overflow-hidden">
                              <Building class="h-3 w-3 mr-1 shrink-0" />
                              <span class="truncate">{{ contributor.company }}</span>
                            </div>
                          </div>
                        </div>
                        
                        <!-- Arrow -->
                        <ChevronRight class="h-4 w-4 text-gray-400 group-hover:text-amber-500 group-hover:translate-x-1 transition-all duration-300" />
                      </div>
                    </li>
                  </TransitionGroup>
                </div>
                
                <!-- Empty Result -->
                <div v-if="filteredContributors.length === 0" class="flex flex-col items-center justify-center py-8 text-gray-500">
                  <Search class="h-12 w-12 mb-2 opacity-50" />
                  <p class="text-center">No contributors found matching "{{ searchQuery }}"</p>
                </div>
              </div>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { Trophy, X, AlertCircle, RefreshCw, Search, ChevronRight, FileText, Users, Building, Briefcase } from "lucide-vue-next";
import { ref, computed, watch } from "vue";

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
const contributors = ref([]);
const searchQuery = ref("");

// Computed properties
const filteredContributors = computed(() => {
  if (!searchQuery.value.trim()) {
    return contributors.value;
  }
  
  const query = searchQuery.value.trim().toLowerCase();
  return contributors.value.filter(contributor => 
    contributor.name.toLowerCase().includes(query) || 
    (contributor.profession && contributor.profession.toLowerCase().includes(query)) ||
    (contributor.company && contributor.company.toLowerCase().includes(query))
  );
});

// Methods
const fetchContributors = async () => {
  isLoading.value = true;
  error.value = null;
  
  try {
    // Fetch top contributors from the API endpoint
    const response = await get("/top-contributors/");
    if (response.data) {
      contributors.value = response.data;
    } else {
      throw new Error("Unexpected response format");
    }
    
  } catch (err) {
    console.error("Error fetching contributors:", err);
    error.value = "Failed to load contributors. Please try again later.";
  } finally {
    isLoading.value = false;
  }
};

const closeModal = () => {
  emit("close");
};

const navigateToProfile = (contributor) => {
  emit("navigate", `/business-network/profile/${contributor.id}`);
  closeModal();
};

// Get position-based styling for rank badges
const getRankBadgeClass = (index) => {
  if (index === 0) return "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300"; // 1st place
  if (index === 1) return "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300"; // 2nd place
  if (index === 2) return "bg-amber-100/80 text-amber-700 dark:bg-amber-900/20 dark:text-amber-400"; // 3rd place
  return "bg-amber-50 text-amber-700 dark:bg-amber-900/10 dark:text-amber-300"; // Rest
};

// Watch for open state changes to fetch data when modal opens
watch(
  () => props.isOpen,
  (isOpen) => {
    if (isOpen) {
      fetchContributors();
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
.contributors-container {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.contributors-container::-webkit-scrollbar {
  width: 6px;
}

.contributors-container::-webkit-scrollbar-track {
  background: transparent;
}

.contributors-container::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 20px;
}

.contributor-item {
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

/* Hover effects */
.contributor-item:hover {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}
</style>