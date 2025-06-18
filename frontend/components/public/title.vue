<template>
  <div class="flex items-center justify-between mb-2 md:mb-6 sm:px-6">
    <div>
      <div class="py-4 text-start relative">
        <h1
          class="text-lg sm:text-xl ml-3 font-semibold bg-clip-text text-transparent bg-gradient-to-r from-emerald-600 to-teal-500 inline-block"
        >
          {{ $t("classified_service") }}
        </h1>
        <!-- Header underline -->
        <div
          class="h-1 ml-4 w-20 mx-auto mt-2 rounded-full bg-gradient-to-r from-emerald-400 to-teal-400"
        ></div>
      </div>
    </div>    
    <UButton
      to="/my-classified-services"
      class="relative overflow-hidden bg-white hover:bg-gray-50 text-emerald-600 font-medium rounded-lg shadow-sm hover:shadow-sm transition-all duration-300 transform hover:scale-105 border border-dashed border-green-600 max-sm:!text-sm mr-2"
      :ui="{
        size: {
          sm: 'text-sm',
        },
        padding: {
          sm: 'px-3 py-1.5',
        },
        icon: {
          size: {
            sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
          },
        },
      }"
      @click="handleButtonClick('post-free-ad')"
    >
      <!-- Button Content with Icon -->
      <div class="relative z-10 flex items-center justify-center space-x-2">
        <!-- Icon Container -->
        <div class="icon-plus-container">
          <div v-if="loadingButtons.has('post-free-ad')" class="dotted-spinner emerald"></div>
          <UIcon
            v-else
            name="i-heroicons-plus-circle"
            class="text-lg text-emerald-600"
          />
        </div>

        <!-- Text -->
        <span v-if="!loadingButtons.has('post-free-ad')" class="text-xs font-medium">{{ $t("post_free_ad") }}</span>
      </div>
    </UButton>  </div>
</template>

<script setup>
// Loading state for buttons
const loadingButtons = ref(new Set());

// Function to handle button click and show loading
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
  // Remove loading state after navigation (cleanup happens in route change)
  setTimeout(() => {
    loadingButtons.value.delete(buttonId);
  }, 3000); // Fallback timeout
};

// Watch for route changes to clear loading states
const route = useRoute();
watch(() => route.path, () => {
  loadingButtons.value.clear();
});
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

.icon-plus-container {
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.emerald {
  border-color: #059669;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
