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

    <!-- Enhanced Search Dropdown with Improved Animation -->
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
        class="absolute top-full right-0 mt-2 w-72 sm:w-96 bg-white dark:bg-gray-800 rounded-xl shadow-professional border border-gray-200 dark:border-gray-700 overflow-hidden z-50 search-dropdown-container"
        role="dialog"
        aria-modal="true"
        aria-label="Search dialog"
      >
        <!-- Enhanced Search Header -->
        <div class="p-3 bg-gray-50 dark:bg-gray-800/80 border-b border-gray-200 dark:border-gray-700 backdrop-blur-sm">
          <h4 class="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400 font-medium mb-2 px-1">Search</h4>
          <div class="relative">
            <input
              type="text"
              placeholder="Type to search..."
              v-model="searchQuery"
              class="w-full pl-10 pr-10 py-2.5 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-500/70 border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 text-gray-800 dark:text-gray-200 transition-all duration-300 shadow-sm search-input"
              ref="searchInput"
            />
            <div class="absolute left-3 top-2.5 text-gray-500 dark:text-gray-400">
              <SearchIcon class="h-4.5 w-4.5" />
            </div>
            
            <div class="absolute right-3 top-2.5 flex items-center gap-2">
              <span v-if="isLoading" class="loading-spinner"></span>
              <button
                v-if="searchQuery"
                @click="clearSearch"
                class="rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 p-1 transition-colors"
              >
                <XIcon class="h-3.5 w-3.5 text-gray-500 dark:text-gray-400" />
              </button>
            </div>
          </div>
        </div>

        <!-- Enhanced Search Results with Improved Rendering and Keyword Highlighting -->
        <div
          v-if="searchQuery && searchResults.length > 0"
          class="max-h-80 overflow-y-auto search-results-container"
        >
          <div class="py-2 px-1">
            <p class="text-xs text-gray-500 dark:text-gray-400 mb-1.5 px-3">
              Results for "<span class="font-medium text-blue-600 dark:text-blue-400">{{ searchQuery }}</span>"
            </p>
          
            <div
              v-for="(result, index) in limitedSearchResults"
              :key="result.id"
              class="p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 cursor-pointer transition-colors duration-150 rounded-lg mx-1 mb-0.5 group"
              @click="selectArticle(result)"
              :class="{'border-b border-gray-100 dark:border-gray-800': index < limitedSearchResults.length - 1}"
            >
              <div class="flex items-start justify-between">
                <div class="flex-1 min-w-0">
                  <!-- Highlighted title with keyword matches -->
                  <p class="text-sm font-medium text-gray-900 dark:text-gray-100 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors line-clamp-2">
                    <span v-html="highlightMatches(result.title, searchQuery)"></span>
                  </p>
                  
                  <!-- Content preview with highlighted matches (if available) -->
                  <p v-if="result.post_text" class="text-xs text-gray-500 dark:text-gray-400 mt-1 line-clamp-2">
                    <span v-html="getContentPreview(result.post_text, searchQuery)"></span>
                  </p>
                  
                  <div class="flex flex-wrap gap-1 mt-1.5">
                    <span
                      v-for="tag in result.post_tags"
                      :key="tag.id"
                      class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                      :class="isTagMatched(tag.tag, searchQuery) ? 
                        'bg-blue-100 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300' : 
                        'bg-gray-100 dark:bg-gray-800/80 text-gray-600 dark:text-gray-400'"
                    >
                      #<span v-html="highlightMatches(tag.tag, searchQuery)"></span>
                    </span>
                  </div>
                </div>
                
                <div class="flex-shrink-0 ml-3">
                  <div class="h-6 w-6 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center group-hover:bg-blue-100 dark:group-hover:bg-blue-800/30 transition-colors">
                    <ArrowRight class="h-3.5 w-3.5 text-gray-500 dark:text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors" />
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div class="flex justify-center p-3 border-t border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-800/50">
            <button
              @click="viewAllResults"
              class="inline-flex items-center justify-center gap-1.5 py-2 px-4 text-xs font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors w-full"
            >
              View all results
              <ArrowRight class="h-3 w-3" />
            </button>
          </div>
        </div>

        <!-- Enhanced No Results Message -->
        <div
          v-if="searchQuery && !isLoading && searchResults.length === 0"
          class="p-6 text-center"
        >
          <div class="w-12 h-12 rounded-full bg-gray-100 dark:bg-gray-800 mx-auto mb-3 flex items-center justify-center">
            <SearchOffIcon class="h-6 w-6 text-gray-400 dark:text-gray-500" />
          </div>
          <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">No results found</p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">We couldn't find anything for "{{ searchQuery }}"</p>
          <div class="text-xs text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/80 rounded-lg p-3 max-w-xs mx-auto border border-gray-100 dark:border-gray-700">
            <p class="font-medium mb-1">Suggestions:</p>
            <ul class="text-gray-500 dark:text-gray-400 text-left space-y-1 pl-4 list-disc">
              <li>Try different keywords</li>
              <li>Check for typos</li>
              <li>Use more general terms</li>
            </ul>
          </div>
        </div>

        <!-- Enhanced Empty State -->
        <div 
          v-if="!searchQuery" 
          class="p-6 text-center"
        >
          <div class="w-16 h-16 rounded-full bg-blue-50 dark:bg-blue-900/20 mx-auto mb-3 flex items-center justify-center">
            <SearchIcon class="h-7 w-7 text-blue-500 dark:text-blue-400" />
          </div>
          <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Search the platform</p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mb-4">Find posts, topics, and more</p>
          
          <div class="mt-4 space-y-2 text-xs text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/80 rounded-lg p-3 border border-gray-100 dark:border-gray-700">
            <p class="font-medium">Try searching for:</p>
            <div class="flex flex-wrap gap-1.5 justify-center mt-2">
              <button 
                v-for="(suggestion, i) in searchSuggestions" 
                :key="i"
                @click="setSearchQuery(suggestion)"
                class="px-2.5 py-1.5 bg-white dark:bg-gray-900 rounded-md border border-gray-200 dark:border-gray-700 hover:border-blue-200 dark:hover:border-blue-800 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors text-gray-700 dark:text-gray-300"
              >
                {{ suggestion }}
              </button>
            </div>
          </div>
          
          <div class="mt-4 text-xs text-gray-400 dark:text-gray-500 flex justify-center items-center gap-1.5">
            <kbd class="px-2 py-1 bg-gray-100 dark:bg-gray-800 rounded-md text-gray-500 dark:text-gray-400 font-mono">ESC</kbd> 
            to close
          </div>
        </div>

        <!-- Loading State -->
        <div
          v-if="searchQuery && isLoading && searchResults.length === 0"
          class="p-8 text-center"
        >
          <div class="loading-spinner mx-auto mb-3"></div>
          <p class="text-sm text-gray-500 dark:text-gray-400">Searching...</p>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { SearchIcon, XIcon, ArrowRightIcon as ArrowRight } from "lucide-vue-next";
const { get } = useApi();
const showSearchDropdown = ref(false);
const searchQuery = ref("");
const searchResults = ref([]);
const isLoading = ref(false);

// Added search suggestions
const searchSuggestions = [
  "Marketing", 
  "Finance", 
  "Leadership", 
  "Technology", 
  "Innovation",
  "Business"
];

// Custom icon for no results state
const SearchOffIcon = {
  name: 'SearchOffIcon',
  props: {
    size: {
      type: String,
      default: '24'
    },
    color: {
      type: String,
      default: 'currentColor'
    }
  },
  setup(props) {
    return () => h('svg', {
      xmlns: 'http://www.w3.org/2000/svg',
      width: props.size,
      height: props.size,
      viewBox: '0 0 24 24',
      fill: 'none',
      stroke: props.color,
      strokeWidth: '2',
      strokeLinecap: 'round',
      strokeLinejoin: 'round'
    }, [
      h('path', { d: 'M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0' }),
      h('path', { d: 'M21 21l-6 -6' }),
      h('path', { d: 'M3 3l18 18' })
    ]);
  }
};

// Limit search results to improve rendering performance
const limitedSearchResults = computed(() => {
  // Limiting to first 8 results for better performance
  return searchResults.value.slice(0, 8);
});

// Highlight search term matches in text
const highlightMatches = (text, query) => {
  if (!query || !text) return text;
  
  // Escape special regex characters to prevent errors
  const escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  
  // Create a regex pattern that matches whole words or parts
  const pattern = new RegExp(`(${escapedQuery.split(/\s+/).join('|')})`, 'gi');
  
  return text.replace(pattern, '<span class="bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300 px-0.5 rounded">$1</span>');
};

// Get a content preview with highlighted keywords
const getContentPreview = (content, query) => {
  if (!content) return '';
  if (!query) return content.substring(0, 100) + '...';
  
  // Extract a relevant portion of the content containing the search term
  const escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const pattern = new RegExp(`(${escapedQuery.split(/\s+/).join('|')})`, 'i');
  const matchIndex = content.search(pattern);
  
  if (matchIndex >= 0) {
    // Get text around the match
    const start = Math.max(0, matchIndex - 40);
    const end = Math.min(content.length, matchIndex + 60);
    let preview = content.substring(start, end);
    
    // Add ellipsis if we're not starting from the beginning
    if (start > 0) preview = '...' + preview;
    // Add ellipsis if we're not ending at the end
    if (end < content.length) preview = preview + '...';
    
    return highlightMatches(preview, query);
  }
  
  // If no match found, just show the beginning
  return content.substring(0, 100) + '...';
};

// Check if a tag matches the search query
const isTagMatched = (tag, query) => {
  if (!tag || !query) return false;
  
  const normalizedTag = tag.toLowerCase();
  const normalizedQuery = query.toLowerCase();
  
  // Check if any word in the query matches the tag
  return normalizedQuery.split(/\s+/).some(word => normalizedTag.includes(word));
};

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

// Set search query from suggestions
const setSearchQuery = (query) => {
  searchQuery.value = query;
};

// Navigate to all results page
const viewAllResults = () => {
  if (searchQuery.value) {
    navigateTo(`/business-network/search-results/${encodeURIComponent(searchQuery.value)}`);
    showSearchDropdown.value = false;
  }
};

// This function would need to be implemented based on your navigation logic
const selectArticle = (article) => {
  // Navigate to the article or perform action
  showSearchDropdown.value = false;
};

// Handle clicks outside of search dropdown to close it
const handleClickOutside = (event) => {
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
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && showSearchDropdown.value) {
        showSearchDropdown.value = false;
      }
    });
  });
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside, true);
  document.removeEventListener("keydown", (e) => {
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

// Debounce function to limit API calls
const debounce = (fn, wait) => {
  let timeout;
  return function(...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => fn.apply(this, args), wait);
  };
};

// Debounced search function
const debouncedSearch = debounce(async (query) => {
  isLoading.value = true;
  try {
    const res = await get(`/bn/posts/search/?q=${query}&page=1`);
    searchResults.value = res.data?.results || [];
  } catch (error) {
    console.error('Search error:', error);
    searchResults.value = [];
  } finally {
    isLoading.value = false;
  }
}, 300);

watch(searchQuery, (newValue) => {
  // Reset results when query is empty
  if (!newValue) {
    searchResults.value = [];
    isLoading.value = false;
    return;
  }
  
  // Only search if query is at least 2 characters
  if (newValue.length >= 2) {
    debouncedSearch(newValue);
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

/* Professional shadow for dropdown */
.shadow-professional {
  box-shadow: 
    0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -2px rgba(0, 0, 0, 0.05),
    0 0 0 1px rgba(0, 0, 0, 0.05);
}

/* Loading spinner animation */
.loading-spinner {
  display: inline-block;
  width: 16px;
  height: 16px;
  border: 2px solid rgba(59, 130, 246, 0.3);
  border-radius: 50%;
  border-top-color: rgba(59, 130, 246, 0.8);
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Improved search input focus styles */
.search-input:focus {
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.3);
}

/* Enhanced scrollbar for search results */
.search-results-container {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.search-results-container::-webkit-scrollbar {
  width: 4px;
}

.search-results-container::-webkit-scrollbar-track {
  background: transparent;
}

.search-results-container::-webkit-scrollbar-thumb {
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

/* Keyword highlight animation */
:deep(.bg-yellow-100) {
  position: relative;
  animation: highlight-pulse 2s infinite;
}

@keyframes highlight-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.8; }
}

/* Improve line clamp for multi-line text */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;  
  overflow: hidden;
  word-break: break-word;
}

/* Fix for v-html content styling */
:deep(span) {
  vertical-align: middle;
}
</style>
