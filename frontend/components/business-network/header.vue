<template>
    <header class="sticky top-0 z-10 bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between shadow-sm">
      <h1 class="text-xl font-semibold text-gray-800 bg-gradient-to-r from-blue-500 to-blue-600 bg-clip-text text-transparent">
        {{ pageTitle }}
      </h1>
      <div class="flex items-center space-x-2">
        <button class="p-2 rounded-full hover:bg-gray-100 transition-colors" @click="openSearch">
          <SearchIcon class="h-5 w-5 text-gray-600" />
        </button>
        <div class="relative">
          <button class="p-2 rounded-full hover:bg-gray-100 transition-colors">
            <BellIcon class="h-5 w-5 text-gray-600" />
            <span v-if="notificationCount > 0" class="absolute top-0 right-0 bg-red-500 text-white text-xs rounded-full h-4 w-4 flex items-center justify-center">
              {{ notificationCount > 9 ? '9+' : notificationCount }}
            </span>
          </button>
        </div>
        <div class="relative">
          <button class="flex items-center gap-2 p-1 rounded-full hover:bg-gray-100 transition-colors">
            <img 
              src="/images/placeholder.jpg?height=32&width=32" 
              alt="Profile" 
              class="h-8 w-8 rounded-full"
            />
          </button>
        </div>
      </div>
    </header>
  </template>
  
  <script setup>
  import { 
    Search as SearchIcon,
    Bell as BellIcon
  } from 'lucide-vue-next';
  
  const route = useRoute();
  const { openSearch } = inject('modalState');
  
  // Notification count (would come from a store in a real app)
  const notificationCount = 5;
  
  // Compute page title based on current route
  const pageTitle = computed(() => {
    let title = 'Business Network'; // Default title
  
    const path = route.path;
    
    if (path === '/') title = 'Business Network';
    if (path === '/notifications') title = 'Notifications';
    if (path === '/profile') title = 'Profile';
    if (path === '/dashboard') title = 'Dashboard';
    if (path === '/saved') title = 'Saved Posts';
    if (path === '/settings') title = 'Settings';
    
    return title;
  });
  </script>