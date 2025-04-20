<template>
    <div class="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50 shadow-lg">
      <div class="flex justify-between items-center px-2">
        <NuxtLink 
          v-for="item in menuItems" 
          :key="item.path" 
          :to="item.path" 
          class="flex flex-col items-center py-3 px-3 text-xs relative"
          :class="[
            $route.path === item.path 
              ? 'text-blue-500 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-500' 
              : 'text-gray-500'
          ]"
        >
          <div class="relative">
            <component 
              :is="item.icon" 
              class="h-6 w-6 mb-1" 
              :class="$route.path === item.path ? 'text-blue-500' : 'text-gray-500'" 
            />
            <span 
              v-if="item.badge" 
              class="absolute -top-1 -right-1 bg-blue-500 text-white text-[10px] rounded-full min-w-[16px] h-4 flex items-center justify-center px-1"
            >
              {{ item.badge }}
            </span>
          </div>
          <span>{{ item.title }}</span>
        </NuxtLink>
      </div>
    </div>
  </template>
  
  <script setup>
  import { 
    Home as HomeIcon,
    Bell as BellIcon,
    User as UserIcon,
    BarChart2 as BarChart2Icon,
    Bookmark as BookmarkIcon
  } from 'lucide-vue-next';
  
  const menuItems = [
    {
      title: "Home",
      icon: HomeIcon,
      path: "/",
    },
    {
      title: "Notifications",
      icon: BellIcon,
      path: "/notifications",
      badge: 5,
    },
    {
      title: "Profile",
      icon: UserIcon,
      path: "/profile",
    },
    {
      title: "Dashboard",
      icon: BarChart2Icon,
      path: "/dashboard",
    },
    {
      title: "Saved",
      icon: BookmarkIcon,
      path: "/saved",
    },
  ];
  </script>