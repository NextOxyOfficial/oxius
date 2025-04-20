<template>
    <div class="hidden md:flex md:flex-col md:w-64 md:fixed md:inset-y-0 bg-white border-r border-gray-200">
      <div class="flex items-center px-4 py-3 border-b border-gray-200">
        <div class="flex items-center gap-2">
          <div class="relative h-8 w-8">
            <img src="/images/placeholder.jpg?height=32&width=32" alt="Logo" class="rounded-md" />
          </div>
          <span class="text-lg font-semibold bg-gradient-to-r from-blue-500 to-blue-600 bg-clip-text text-transparent">
            Business Network
          </span>
        </div>
      </div>
      <div class="flex flex-col flex-1 overflow-y-auto">
        <nav class="flex-1 px-2 py-4 space-y-1">
          <NuxtLink 
            v-for="item in menuItems" 
            :key="item.path" 
            :to="item.path" 
            class="flex items-center px-3 py-2 text-sm rounded-md transition-colors"
            :class="[
              $route.path === item.path 
                ? 'font-medium bg-blue-500/10 text-blue-500' 
                : 'text-gray-500 hover:bg-gray-100'
            ]"
          >
            <component :is="item.icon" class="h-5 w-5 mr-2" :class="$route.path === item.path ? 'text-blue-500' : 'text-gray-500'" />
            <span>{{ item.title }}</span>
          </NuxtLink >
        </nav>
        <div class="p-4 border-t border-gray-200">
          <div class="space-y-2">
            <NuxtLink  to="/settings" class="flex items-center px-3 py-2 text-sm rounded-md text-gray-500 hover:bg-gray-100">
              <SettingsIcon class="h-5 w-5 mr-2 text-gray-500" />
              <span>Settings</span>
            </NuxtLink >
            <button 
              class="flex items-center px-3 py-2 text-sm rounded-md text-gray-500 hover:bg-gray-100 w-full text-left"
              @click="logout"
            >
              <LogOutIcon class="h-5 w-5 mr-2 text-gray-500" />
              <span>Logout</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
  import { NuxtLink } from '#components';
import { 
    Home as HomeIcon,
    Bell as BellIcon,
    User as UserIcon,
    BarChart2 as BarChart2Icon,
    Bookmark as BookmarkIcon,
    Settings as SettingsIcon,
    LogOut as LogOutIcon,
    Clock
  } from 'lucide-vue-next';
  
  const router = useRouter();
  const route = useRoute();
  
  const menuItems = [
    {
      title: "Recent",
      icon: Clock,
      path: "/business-network/",
    },
    {
      title: "Notifications",
      icon: BellIcon,
      path: "/business-network/notifications",
      badge: 5,
    },
    {
      title: "Profile",
      icon: UserIcon,
      path: "/business-network/profile",
    },
    {
      title: "Dashboard",
      icon: BarChart2Icon,
      path: "/business-network/dashboard",
    },
    {
      title: "Saved",
      icon: BookmarkIcon,
      path: "/business-network/saved",
    },
  ];
  
  const logout = () => {
    // In a real app, you would call your auth service to log out
    console.log('Logging out...');
    // Then redirect to login page
    router.push('/login');
  };
  </script>