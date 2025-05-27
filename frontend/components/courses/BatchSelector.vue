<template>
  <div class="bg-white rounded-lg shadow-md p-6">
    <h2 class="text-xl font-bold mb-4">Select Your Batch</h2>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div 
        @click="$emit('select-batch', 'SSC')" 
        class="p-4 border rounded-lg cursor-pointer transition-all hover:bg-blue-50"
        :class="{ 'border-blue-500 bg-blue-50': selectedBatch === 'SSC' }"
      >
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-blue-100 rounded-lg">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>
          <div>
            <h3 class="font-medium">SSC</h3>
            <p class="text-sm text-gray-600">Class 9-10</p>
          </div>
        </div>
      </div>
      
      <div 
        @click="$emit('select-batch', 'HSC')" 
        class="p-4 border rounded-lg cursor-pointer transition-all hover:bg-blue-50"
        :class="{ 'border-blue-500 bg-blue-50': selectedBatch === 'HSC' }"
      >
        <div class="flex items-center space-x-3">
          <div class="p-2 bg-purple-100 rounded-lg">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <div>
            <h3 class="font-medium">HSC</h3>
            <p class="text-sm text-gray-600">Class 11-12</p>
          </div>
        </div>
      </div>
    </div>
  </div>
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
