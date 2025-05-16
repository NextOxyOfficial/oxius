<template>
  <!-- Enhanced header with gradient background and glass morphism effect -->
  <div
    class="relative overflow-hidden rounded-xl bg-gradient-to-br from-blue-500 via-indigo-500 to-purple-600 p-4 sm:p-6 mb-4 sm:mb-8 shadow-sm"
  >
    <div
      class="flex flex-col md:flex-row justify-between items-start md:items-center z-10 relative gap-4"
    >
      <div class="text-white w-full animate-fade-in-up">
        <div class="flex flex-col justify-between items-start w-full">
          <div>
            <h1 class="text-xl sm:text-3xl font-semibold flex items-center">
              MindForce
              <div
                class="shimmer-badge ml-3 h-5 px-2 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center text-xs"
              >
                <span class="font-medium">Collaborative Problem-Solving Network</span>
              </div>
            </h1>
            <p class="text-blue-100 mt-1 text-md sm:text-base">
              Raise your mind to help others! Connect and solve problems together.
            </p>
          </div>
          <button
            @click="emit('create')"
            class="mt-4 sm:mt-0 inline-flex items-center justify-center rounded-md text-sm transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-white text-blue-700 hover:bg-blue-50 h-10 px-2 shadow-sm hover:shadow-sm transform hover:-translate-y-0.5 group relative overflow-hidden"
            :disabled="isCreating"
          >
            <span class="relative z-10 flex items-center">
              <span v-if="isCreating" class="flex items-center">
                <svg
                  class="animate-spin -ml-1 mr-2 h-4 w-4"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                Loading...
              </span>
              <span v-else class="flex items-center">
                <Plus class="h-4 w-4 mr-2 group-hover:rotate-90 transition-transform" />
                Post a Problem
              </span>
            </span>
            <span
              class="absolute inset-0 bg-gradient-to-r from-white/90 to-blue-50 opacity-0 group-hover:opacity-100 transition-opacity"
            ></span>
          </button>
        </div>
      </div>
    </div>

    <!-- Decorative elements with animation -->
    <div
      class="absolute top-0 right-0 -mt-16 -mr-16 h-64 w-64 rounded-full bg-blue-400 opacity-20 blur-3xl animate-pulse-slow"
    ></div>
    <div
      class="absolute bottom-0 left-0 -mb-16 -ml-16 h-64 w-64 rounded-full bg-indigo-400 opacity-20 blur-3xl animate-float"
    ></div>
    <!-- Additional decorative elements -->
    <div class="absolute inset-0 bg-grid-pattern opacity-5"></div>

    <!-- Enhanced decorative icon -->
    <div class="absolute right-0 bottom-0 opacity-10 animate-float-subtle">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="180"
        height="180"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="text-white"
      >
        <path
          d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"
        ></path>
        <polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline>
        <line x1="12" y1="22.08" x2="12" y2="12"></line>
      </svg>
    </div>
  </div>
</template>

<script setup>
import { Plus } from "lucide-vue-next";
import { ref } from "vue";

defineProps({
  isCreating: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['create']);
</script>