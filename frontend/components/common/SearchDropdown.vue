<template>
  <div class="relative search-button-container">
    <button
      class="flex items-center justify-center h-9 w-9 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors group"
      @click="toggleSearchDropdown"
      aria-label="Search"
    >
      <SearchIcon
        class="h-[18px] w-[18px] text-gray-600 dark:text-gray-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
      />
    </button>

    <!-- Search Dropdown with Enhanced Animation -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 scale-95 -translate-y-2"
      enter-to-class="opacity-100 scale-100 translate-y-0"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100 scale-100 translate-y-0"
      leave-to-class="opacity-0 scale-95 -translate-y-2"
    >
      <div
        v-if="showSearchDropdown"
        class="absolute top-full right-0 mt-2 w-72 sm:w-80 bg-white dark:bg-gray-800 rounded-xl shadow-xl border border-gray-200 dark:border-gray-700 overflow-hidden z-50 search-dropdown-container"
      >
        <!-- Search Input with Focus Animation -->
        <div class="p-3 border-b border-gray-200 dark:border-gray-700">
          <div class="relative">
            <input
              type="text"
              placeholder="Search topics..."
              v-model="searchQuery"
              class="w-full pl-9 pr-8 py-2.5 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-500/70 border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-800 dark:text-gray-200 transition-all duration-300 search-input"
              ref="searchInput"
            />
            <SearchIcon class="absolute left-3 top-2.5 h-4 w-4 text-gray-500 dark:text-gray-400" />
            <button
              v-if="searchQuery"
              @click="clearSearch"
              class="absolute right-2.5 top-2.5 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 p-1 transition-colors"
            >
              <XIcon class="h-3.5 w-3.5 text-gray-500 dark:text-gray-400" />
            </button>
          </div>
        </div>

        <!-- Search Results with Optimized Rendering -->
        <div
          v-if="searchQuery && searchResults.length > 0"
          class="divide-y divide-gray-100 dark:divide-gray-800 max-h-80 overflow-y-auto"
        >
          <div
            v-for="result in limitedSearchResults"
            :key="result.id"
            class="p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 cursor-pointer transition-colors duration-150"
            @click="selectArticle(result)"
          >
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
              {{ result.title }}
            </p>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              <span
                class="bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 px-2 py-0.5 rounded-full text-xs"
              >
                {{ getCategoryName(result.categoryId) }}
              </span>
            </p>
          </div>
        </div>

        <!-- No Results Message -->
        <div
          v-if="searchQuery && searchResults.length === 0"
          class="p-4 text-center text-gray-500 dark:text-gray-400"
        >
          No results found for "{{ searchQuery }}"
        </div>

        <!-- Empty State -->
        <div v-if="!searchQuery" class="p-4 text-center">
          <div class="text-gray-400 dark:text-gray-500 mb-2">
            <SearchIcon class="h-5 w-5 mx-auto mb-2" />
            Type to start searching...
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-500">Press ESC to close</div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, nextTick, onMounted, onUnmounted, computed } from "vue";
import { SearchIcon, XIcon } from "lucide-vue-next";
const { get } = useApi();
const showSearchDropdown = ref(false);
const searchQuery = ref("");
const searchResults = ref([]);

// Limit search results to improve rendering performance
const limitedSearchResults = computed(() => {
  // Limiting to first 10 results for better performance
  return searchResults.value.slice(0, 10);
});

// Toggle search dropdown visibility
const toggleSearchDropdown = () => {
  showSearchDropdown.value = !showSearchDropdown.value;
  if (showSearchDropdown.value) {
    nextTick(() => {
      const searchInput = document.querySelector(".search-input");
      if (searchInput) {
        searchInput.focus();
      }
    });
  }
};

// Clear search input
const clearSearch = () => {
  searchQuery.value = "";
  nextTick(() => {
    const searchInput = document.querySelector(".search-input");
    if (searchInput) {
      searchInput.focus();
    }
  });
};

// This function would need to be implemented based on your actual data structure
const getCategoryName = categoryId => {
  // Placeholder - implement based on your actual categories data
  return "Category";
};

// This function would need to be implemented based on your navigation logic
const selectArticle = article => {
  // Placeholder - implement based on your navigation needs
  showSearchDropdown.value = false;
};

// Handle clicks outside of search dropdown to close it
const handleClickOutside = event => {
  const searchDropdown = document.querySelector(".search-dropdown-container");
  const searchButton = document.querySelector(".search-button-container");

  if (
    showSearchDropdown.value &&
    searchDropdown &&
    !searchDropdown.contains(event.target) &&
    searchButton &&
    !searchButton.contains(event.target)
  ) {
    showSearchDropdown.value = false;
  }
};

// Use lifecycle hooks to add and remove the global listener
onMounted(() => {
  nextTick(() => {
    document.addEventListener("click", handleClickOutside, true);

    // Add keyboard event listener for ESC key
    document.addEventListener("keydown", e => {
      if (e.key === "Escape" && showSearchDropdown.value) {
        showSearchDropdown.value = false;
      }
    });
  });
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside, true);
  document.removeEventListener("keydown", e => {
    if (e.key === "Escape" && showSearchDropdown.value) {
      showSearchDropdown.value = false;
    }
  });
});

// Expose methods and reactive state for parent components
defineExpose({
  toggleSearchDropdown,
  showSearchDropdown,
  searchQuery,
  searchResults,
});

watch(searchQuery, async newValue => {
  // Trigger search logic here
  if (newValue) {
    // Fetch search results
    const res = await get(`/bn/mindforce/?search=${newValue}`);
    searchResults.value = res.data;
  } else {
    searchResults.value = [];
  }
});
</script>

<style scoped>
/* Glass effect for header */
.backdrop-blur-sm {
  backdrop-filter: blur(8px);
}

/* Custom shadow for dropdown */
.search-dropdown-container {
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
}

/* Improved search input focus styles */
.search-input:focus {
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.3);
}

/* Improve scrollbar for search results */
.search-dropdown-container div {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.search-dropdown-container div::-webkit-scrollbar {
  width: 4px;
}

.search-dropdown-container div::-webkit-scrollbar-track {
  background: transparent;
}

.search-dropdown-container div::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 9999px;
}

/* Mobile adjustments - FIXED POSITIONING */
@media (max-width: 640px) {
  .search-dropdown-container {
    position: fixed;
    width: calc(100% - 2rem);
    max-width: 400px;
    left: 50%;
    transform: translateX(-50%);
    top: 5rem;
    margin: 0 auto;
    z-index: 1000;
  }
}
</style>
