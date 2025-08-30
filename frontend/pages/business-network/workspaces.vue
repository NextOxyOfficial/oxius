<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl pt-3 flex-1 min-h-screen">
    <!-- Header Section -->
    <div class="mb-6">
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 px-6 py-4">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900 flex items-center">
              <div class="w-8 h-8 bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg flex items-center justify-center mr-3">
                <Star class="h-5 w-5 text-white" />
              </div>
              Workspaces
            </h1>
            <p class="mt-1 text-gray-600">Manage and organize your collaborative workspaces</p>
          </div>
          <div class="flex items-center space-x-3">
            <button
              v-if="user?.user"
              class="inline-flex items-center px-4 py-2 rounded-lg bg-gradient-to-r from-purple-500 to-purple-600 text-white hover:from-purple-600 hover:to-purple-700 transition-all duration-200 shadow-sm"
            >
              <Plus class="h-4 w-4 mr-2" />
              Create Workspace
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-100">
      <!-- Content Area -->
      <div class="px-2 py-3 pb-8">
        <div class="space-y-4 min-h-[400px]">
          <!-- Loading state -->
          <div v-if="isLoading" class="space-y-4">
            <div
              v-for="i in 3"
              :key="i"
              class="bg-white border border-gray-100 rounded-lg px-4 py-6 animate-pulse"
            >
              <div class="flex justify-between items-start mb-4">
                <div class="flex items-center">
                  <div class="h-12 w-12 rounded-lg bg-gray-200"></div>
                  <div class="ml-4">
                    <div class="h-5 w-40 bg-gray-200 rounded"></div>
                    <div class="h-3 w-32 bg-gray-200 rounded mt-2"></div>
                  </div>
                </div>
                <div class="h-6 w-20 bg-gray-200 rounded-full"></div>
              </div>
              <div class="flex space-x-4 mt-4">
                <div class="h-4 w-24 bg-gray-200 rounded"></div>
                <div class="h-4 w-24 bg-gray-200 rounded"></div>
              </div>
            </div>
          </div>

          <!-- Empty state -->
          <div
            v-else
            class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
          >
            <div class="text-center">
              <div class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Star class="h-8 w-8 text-purple-600" />
              </div>
              <h3 class="text-lg font-semibold text-gray-900 mb-2">Welcome to Workspaces</h3>
              <p class="text-gray-600 mb-4 max-w-md">
                This is your workspace management area. Here you'll be able to create, organize, 
                and collaborate on various projects and tasks.
              </p>
              <div class="text-sm text-gray-500 bg-gray-100 rounded-lg p-4 max-w-sm mx-auto">
                <strong>Ready for your design instructions!</strong><br>
                This page is prepared and waiting for your specific workspace features and functionality.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Star, Plus } from "lucide-vue-next";

// Page meta
definePageMeta({
  layout: "adsy-business-network",
  title: "Workspaces - Business Network",
  meta: [
    {
      name: "description",
      content: "Manage and organize your collaborative workspaces",
    },
    {
      name: "keywords",
      content: "workspace, collaboration, organize, projects, business network",
    },
  ],
});

// Composables
const { user } = useAuth();

// State
const isLoading = ref(false);

// Simulate loading state for demonstration
onMounted(() => {
  isLoading.value = true;
  setTimeout(() => {
    isLoading.value = false;
  }, 1000);
});
</script>

<style scoped>
/* Prevent layout shifts and improve scrolling */
.mx-auto {
  scroll-behavior: smooth;
}

/* Prevent transitions on layout-affecting properties */
* {
  transition-property: background-color, border-color, color, fill, stroke, opacity, box-shadow;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 150ms;
}

/* Ensure stable layout */
.space-y-4 {
  contain: layout;
}

/* Content container for stable layouts */
.content-container {
  contain: layout style;
  will-change: auto;
}

/* Prevent content jumping */
.min-h-\[400px\] {
  min-height: 400px;
  contain: layout style;
}

/* Fix scrollbar stability */
html {
  overflow-y: scroll;
}

/* Force proper viewport behavior */
@media (max-width: 640px) {
  html,
  body {
    max-width: 100%;
    overflow-x: hidden;
  }
}

/* Prevent layout shift on empty states */
.py-16 {
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Stabilize loading states */
.animate-pulse {
  contain: layout;
}

/* Prevent scrollbar jumping */
body {
  scrollbar-gutter: stable;
}
</style>
