<template>
    <div 
      class="fixed inset-0 bg-black/50 backdrop-blur-sm z-[9999] flex items-center justify-center p-4"
      @click="$emit('close')"
    >
      <div 
        class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-hidden"
        @click.stop
      >
        <div class="p-4 border-b border-gray-200 sticky top-0 bg-white">
          <div class="flex items-center gap-3">
            <div class="relative flex-1">
              <div class="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                <SearchIcon class="h-5 w-5 text-gray-400" />
              </div>
              <input
                ref="searchInput"
                type="text"
                placeholder="Search business network..."
                class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                v-model="searchQuery"
              />
            </div>
            <button class="p-2 rounded-full hover:bg-gray-100" @click="$emit('close')">
              <XIcon class="h-5 w-5" />
            </button>
          </div>
        </div>
  
        <div class="p-3 border-b border-gray-200">
          <h3 class="text-sm font-medium text-gray-500 mb-2">Filter by Category</h3>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="category in availableCategories"
              :key="category"
              :class="[
                'text-xs px-3 py-1 rounded-full transition-colors',
                selectedCategories.includes(category)
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              ]"
              @click="toggleCategory(category)"
            >
              {{ category }}
            </button>
          </div>
        </div>
  
        <div class="overflow-y-auto max-h-[calc(90vh-142px)]">
          <div v-if="searchResults.length > 0" class="p-4">
            <ul class="space-y-3">
              <li v-for="(result, index) in searchResults" :key="index">
                <button
                  class="flex items-center gap-3 w-full p-3 hover:bg-gray-50 rounded-lg transition-colors"
                  @click="handleSearch(result)"
                >
                  <div class="bg-gray-100 rounded-full p-2">
                    <SearchIcon class="h-4 w-4 text-gray-500" />
                  </div>
                  <span class="text-gray-800">{{ result }}</span>
                </button>
              </li>
              <li>
                <button
                  class="flex items-center justify-between w-full p-3 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors mt-2"
                  @click="handleSearchAll"
                >
                  <span class="font-medium text-blue-500">
                    {{ selectedCategories.length > 0
                      ? `Search "${searchQuery}" in ${selectedCategories.length} categories`
                      : `See all results for "${searchQuery}"` }}
                  </span>
                  <ArrowRightIcon class="h-4 w-4 text-blue-500" />
                </button>
              </li>
            </ul>
          </div>
  
          <div v-if="searchQuery.length === 0" class="p-4">
            <h3 class="text-sm font-medium text-gray-500 mb-2">Recent Searches</h3>
            <ul class="space-y-3">
              <li v-for="(term, index) in recentSearches" :key="index">
                <button
                  class="flex items-center gap-3 w-full p-3 hover:bg-gray-50 rounded-lg transition-colors"
                  @click="handleSearch(term)"
                >
                  <div class="bg-gray-100 rounded-full p-2">
                    <ClockIcon class="h-4 w-4 text-gray-500" />
                  </div>
                  <span class="text-gray-800">{{ term }}</span>
                </button>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref, computed, onMounted, nextTick } from 'vue';
  import { useRouter } from 'vue-router';
  import { 
    Search as SearchIcon,
    X as XIcon,
    Clock as ClockIcon,
    ArrowRight as ArrowRightIcon
  } from 'lucide-vue-next';
  import { useSearch } from '../../composables/useSearch';
  
  const emit = defineEmits(['close', 'search']);
  const router = useRouter();
  const { saveRecentSearch, getRecentSearches } = useSearch();
  
  // Refs
  const searchInput = ref(null);
  
  // State
  const searchQuery = ref('');
  const selectedCategories = ref([]);
  const recentSearches = ref([]);
  
  // Available categories
  const availableCategories = [
    "Marketing",
    "Finance",
    "Operations",
    "Leadership",
    "Technology",
    "HR",
    "Sales",
    "Strategy",
  ];
  
  // Computed
  const searchResults = computed(() => {
    if (searchQuery.value.length === 0) return [];
    
    // Simulate search results
    let results = [
      `${searchQuery.value}`, 
      `${searchQuery.value} trends`, 
      `${searchQuery.value} examples`, 
      `${searchQuery.value} best practices`, 
      `${searchQuery.value} tips`
    ];
  
    // If categories are selected, add them to the results
    if (selectedCategories.value.length > 0) {
      results = results.map(result => 
        `${result} in ${selectedCategories.value.join(", ")}`
      );
    }
  
    return results;
  });
  
  // Methods
  const toggleCategory = (category) => {
    const index = selectedCategories.value.indexOf(category);
    if (index === -1) {
      selectedCategories.value.push(category);
    } else {
      selectedCategories.value.splice(index, 1);
    }
  };
  
  const handleSearch = (term) => {
    searchQuery.value = term;
    
    // Save to recent searches
    if (term.trim() !== "") {
      saveRecentSearch(term);
      loadRecentSearches();
    }
    
    // Navigate to search results page
    router.push({
      path: '/search',
      query: { 
        q: term,
        categories: selectedCategories.value.join(',')
      }
    });
    
    emit('search', {
      query: term,
      categories: selectedCategories.value
    });
    
    emit('close');
  };
  
  const handleSearchAll = () => {
    if (searchQuery.value.trim()) {
      handleSearch(searchQuery.value);
    }
  };
  
  const loadRecentSearches = async () => {
    recentSearches.value = await getRecentSearches();
  };
  
  // Lifecycle hooks
  onMounted(async () => {
    // Load recent searches
    await loadRecentSearches();
    
    // Focus search input
    nextTick(() => {
      searchInput.value?.focus();
    });
  });
  </script>