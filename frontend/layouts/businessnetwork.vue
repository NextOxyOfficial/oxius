<template>
    <div class="min-h-screen bg-gray-50">
      <div class="flex h-screen overflow-hidden">
        <!-- Sidebar (Desktop) -->
        <BusinessNetworkSidebar />
  
        <!-- Main Content -->
        <div class="flex-1 md:ml-64 flex flex-col">
          <!-- Header -->
          <BusinessNetworkHeader />
  
          <!-- Main Content Area -->
          <main class="flex-1 overflow-auto pb-20 md:pb-0">
            <slot />
          </main>
  
          <!-- Footer Navigation (Mobile) -->
          <BusinessNetworkFooter />
  
          <!-- Create Post Button -->
          <button 
            class="fixed bottom-24 right-4 md:bottom-4 rounded-full h-14 w-14 shadow-lg bg-gradient-to-r from-blue-500 to-blue-600 hover:shadow-xl transition-all duration-300 hover:scale-105 border-none z-40 flex items-center justify-center text-white"
            @click="openCreatePost"
          >
            <PlusIcon class="h-6 w-6" />
          </button>
        </div>
      </div>
  
      <!-- Modals -->
      <BusinessNetworkCreatePostModal 
        v-if="isCreatePostOpen" 
        @close="closeCreatePost" 
      />
      <BusinessNetworkSearchOverlay 
        v-if="isSearchOpen" 
        @close="closeSearch" 
      />
      <BusinessNetworkMediaViewer 
        v-if="activeMedia" 
        :media="activeMedia" 
        @close="closeMediaViewer" 
      />
    </div>
  </template>
  
  <script setup>
  import { Plus as PlusIcon } from 'lucide-vue-next';
  
  const isCreatePostOpen = ref(false);
  const isSearchOpen = ref(false);
  const activeMedia = ref(null);
  
  // Methods
  const openCreatePost = () => {
    isCreatePostOpen.value = true;
  };
  
  const closeCreatePost = () => {
    isCreatePostOpen.value = false;
  };
  
  const openSearch = () => {
    isSearchOpen.value = true;
  };
  
  const closeSearch = () => {
    isSearchOpen.value = false;
  };
  
  const openMediaViewer = (media) => {
    activeMedia.value = media;
  };
  
  const closeMediaViewer = () => {
    activeMedia.value = null;
  };
  
  // Provide shared state to child components
  provide('modalState', {
    isCreatePostOpen,
    isSearchOpen,
    activeMedia,
    openCreatePost,
    closeCreatePost,
    openSearch,
    closeSearch,
    openMediaViewer,
    closeMediaViewer
  });
  </script>
  
  <style>
  .fade-enter-active,
  .fade-leave-active {
    transition: opacity 0.2s ease;
  }
  
  .fade-enter-from,
  .fade-leave-to {
    opacity: 0;
  }
  
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  .animate-fade-in {
    animation: fadeIn 0.5s ease-out forwards;
  }
  
  html {
    scroll-behavior: smooth;
  }
  </style>