<template>
  <UContainer>
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <div class="flex items-center justify-between mb-3">
      <h2 class="text-lg font-semibold text-gray-800">Select Your Batch</h2>
      <span class="bg-blue-100 text-blue-700 text-xs px-2 py-1 rounded-full">Step 1 of 4</span>
    </div>
    <div class="grid grid-cols-2 gap-3">
      <div 
        @click="$emit('select-batch', 'SSC')" 
        class="p-3 border rounded-lg cursor-pointer transition-all hover:shadow-sm hover:border-blue-300"
        :class="{ 'border-blue-500 bg-blue-50 shadow-sm': selectedBatch === 'SSC', 'border-gray-200': selectedBatch !== 'SSC' }"
      >
        <div class="flex items-center space-x-2">
          <div class="p-1.5 bg-blue-100 rounded-lg">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>
          <div>
            <h3 class="font-medium">SSC</h3>
            <p class="text-xs text-gray-600">Class 9-10</p>
          </div>
        </div>
      </div>
      
      <div 
        @click="$emit('select-batch', 'HSC')" 
        class="p-3 border rounded-lg cursor-pointer transition-all hover:shadow-sm hover:border-blue-300"
        :class="{ 'border-blue-500 bg-blue-50 shadow-sm': selectedBatch === 'HSC', 'border-gray-200': selectedBatch !== 'HSC' }"
      >
        <div class="flex items-center space-x-2">
          <div class="p-1.5 bg-purple-100 rounded-lg">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <div>
            <h3 class="font-medium">HSC</h3>
            <p class="text-xs text-gray-600">Class 11-12</p>
          </div>
        </div>
      </div>
    </div>
  </div>
  </UContainer>

</template>

<script setup>
defineProps({
  selectedBatch: {
    type: String,
    default: null
  }
});

defineEmits(['select-batch']);
</script>
