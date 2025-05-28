<template>
  <div v-if="show" class="fixed inset-0 z-[1000] overflow-y-auto flex items-center justify-center bg-black bg-opacity-50">
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-bold flex items-center">
          <svg class="w-5 h-5 text-blue-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
          </svg>
          {{ $t('session_limit_reached') || 'Session Limit Reached' }}
        </h3>
        <button @click="$emit('close')" class="text-gray-500 hover:text-gray-700">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      
      <div class="mb-6">
        <div class="text-center mb-4">
          <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 mb-4">
            <svg class="h-8 w-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          </div>
          <h4 class="text-lg font-medium text-gray-900 mb-2">
            {{ $t('active_session_elsewhere') || 'Active Session On Another Device' }}
          </h4>
          <p class="text-gray-600">
            {{ $t('concurrent_session_message') || 'You have an active video session on another device or browser. Our premium subscription allows one active session at a time.' }}
          </p>
        </div>
        
        <div class="bg-yellow-50 p-4 rounded-lg border border-yellow-200">
          <div class="flex items-start">
            <svg class="w-5 h-5 text-yellow-500 mr-2 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2h-1V9z" clip-rule="evenodd" />
            </svg>
            <p class="text-sm text-yellow-700">
              {{ $t('force_session_info') || 'You can close your session on the other device and continue watching here, or continue watching on your other device.' }}
            </p>
          </div>
        </div>
      </div>
      
      <div class="flex flex-col sm:flex-row gap-3">
        <button 
          @click="forceClose" 
          class="flex-grow py-3 px-4 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white font-medium rounded-lg flex items-center justify-center"
        >
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z" />
          </svg>
          {{ $t('continue_here') || 'Continue Here' }}
        </button>
        <button 
          @click="$emit('close')" 
          class="flex-grow py-3 px-4 bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium rounded-lg"
        >
          {{ $t('cancel') || 'Cancel' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  show: {
    type: Boolean,
    required: true
  }
});

const emit = defineEmits(['close', 'force-close']);

function forceClose() {
  emit('force-close');
}
</script>
