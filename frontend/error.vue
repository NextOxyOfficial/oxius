<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div class="text-center">
        <UIcon name="i-heroicons-exclamation-triangle" class="mx-auto h-20 w-20 text-red-500" />
        <h2 class="mt-6 text-3xl font-extrabold text-gray-900">
          Oops! Something went wrong
        </h2>
        <p class="mt-2 text-sm text-gray-600">
          {{ error.statusMessage || 'An unexpected error occurred' }}
        </p>
        <div class="mt-8 space-y-4">
          <UButton 
            @click="handleError" 
            color="primary" 
            size="lg" 
            block
            label="Try Again"
          />
          <UButton 
            @click="handleClearError" 
            variant="ghost" 
            size="lg" 
            block
            label="Go Home"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps(['error']);

const handleError = () => {
  // Reload the current page
  if (process.client) {
    window.location.reload();
  }
};

const handleClearError = async () => {
  // Clear the error and navigate to home
  clearError();
  await navigateTo('/');
};
</script>
