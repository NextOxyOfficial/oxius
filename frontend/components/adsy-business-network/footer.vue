<script setup lang="ts">
import { BarChart2, Bell, Bookmark, Clock, Home, Newspaper, User } from 'lucide-vue-next';

</script>

<template>

<div class="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50 shadow-lg">
        <div class="flex justify-between items-center px-2">
          <NuxtLink
            to="/business-network/"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-gray-500"
          >
            <div class="relative">
              <Clock class="h-6 w-6 mb-1 text-gray-500" />
            </div>
            <span>Recent</span>
          </NuxtLink>
          <NuxtLink
            to="/business-network/notifications"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-gray-500"
          >
            <div class="relative">
              <Bell class="h-6 w-6 mb-1 text-gray-500" />
              <span class="absolute -top-1 -right-1 bg-blue-600 text-white text-[10px] rounded-full min-w-[16px] h-4 flex items-center justify-center px-1">
                5
              </span>
            </div>
            <span>Notifications</span>
          </NuxtLink>
          <NuxtLink
            to="/business-network/profile"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
          >
            <div class="relative">
              <User class="h-6 w-6 mb-1 text-blue-600" />
            </div>
            <span>Profile</span>
          </NuxtLink>
          <NuxtLink
            to="/dashboard"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-gray-500"
          >
            <div class="relative">
              <BarChart2 class="h-6 w-6 mb-1 text-gray-500" />
            </div>
            <span>Adsy Club</span>
          </NuxtLink>
          <NuxtLink
            to="/saved"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-gray-500"
          >
            <div class="relative">
              <Newspaper class="h-6 w-6 mb-1 text-gray-500" />
            </div>
            <span>Adsy News</span>
          </NuxtLink>
        </div>
      </div>
</template>