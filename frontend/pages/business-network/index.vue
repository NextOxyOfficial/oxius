<template>
    <div class="max-w-3xl mx-auto py-4 px-4">
      <div class="mb-4 flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Home</h1>
        <div class="flex gap-2">
          <button 
            class="p-2 rounded-md border border-gray-200 hover:bg-gray-50"
            @click="showFilters = !showFilters"
          >
            <FilterIcon class="h-5 w-5 text-gray-500" />
          </button>
          <button 
            class="p-2 rounded-md border border-gray-200 hover:bg-gray-50"
            @click="refreshPosts"
          >
            <RefreshCwIcon class="h-5 w-5 text-gray-500" />
          </button>
        </div>
      </div>
  
      <div v-if="showFilters" class="mb-4 p-4 bg-white rounded-lg border border-gray-200 shadow-sm">
        <BusinessNetworkCategoryFilter 
          v-model="selectedCategories" 
          :available-categories="availableCategories" 
        />
      </div>
  
      <BusinessNetworkPostList :filter="{ categories: selectedCategories }" />
    </div>
  </template>
  
  <script setup>
  
definePageMeta({
  layout: "businessnetwork",
});
  import { 
    Filter as FilterIcon,
    RefreshCw as RefreshCwIcon
  } from 'lucide-vue-next';
  
  // State
  const showFilters = ref(false);
  const selectedCategories = ref([]);
  
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
  
  // Methods
  const refreshPosts = () => {
    // This would trigger a refresh in the PostList component
    // In a real app, you might use a more sophisticated approach
    window.location.reload();
  };
  </script>