<template>
    <div class="mb-4">
      <h3 class="text-sm font-medium text-gray-700 mb-2">Filter by Category</h3>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="category in availableCategories"
          :key="category"
          :class="[
            'text-xs px-3 py-1 rounded-full transition-colors',
            modelValue.includes(category)
              ? 'bg-blue-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
          ]"
          @click="toggleCategory(category)"
        >
          {{ category }}
        </button>
      </div>
      <div v-if="modelValue.length > 0" class="mt-2 flex justify-between">
        <span class="text-xs text-gray-500">{{ modelValue.length }} categories selected</span>
        <button 
          class="text-xs text-blue-500 hover:underline"
          @click="clearAll"
        >
          Clear all
        </button>
      </div>
    </div>
  </template>
  
  <script setup>
  const props = defineProps({
    modelValue: {
      type: Array,
      default: () => []
    },
    availableCategories: {
      type: Array,
      default: () => [
        "Marketing",
        "Finance",
        "Operations",
        "Leadership",
        "Technology",
        "HR",
        "Sales",
        "Strategy",
      ]
    }
  });
  
  const emit = defineEmits(['update:modelValue']);
  
  const toggleCategory = (category) => {
    const selected = [...props.modelValue];
    const index = selected.indexOf(category);
    
    if (index === -1) {
      selected.push(category);
    } else {
      selected.splice(index, 1);
    }
    
    emit('update:modelValue', selected);
  };
  
  const clearAll = () => {
    emit('update:modelValue', []);
  };
  </script>