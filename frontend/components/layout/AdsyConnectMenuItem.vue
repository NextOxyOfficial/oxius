<template>
  <div class="relative">
    <!-- Desktop Menu Item -->
    <NuxtLink
      to="/inbox"
      class="hidden lg:flex items-center space-x-2 px-3 py-2 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
      :class="{ 'bg-green-50 text-green-700': $route.path === '/inbox' }"
    >
      <UIcon name="i-heroicons-chat-bubble-left-right" class="w-5 h-5" />
      <span class="font-medium">AdsyConnect</span>
      
      <!-- Unread Badge -->
      <div
        v-if="unreadCount > 0"
        class="flex items-center justify-center w-5 h-5 bg-red-500 text-white text-xs font-bold rounded-full"
      >
        {{ unreadCount > 99 ? '99+' : unreadCount }}
      </div>
    </NuxtLink>

    <!-- Mobile Menu Item -->
    <NuxtLink
      to="/inbox"
      class="lg:hidden flex items-center justify-between p-4 hover:bg-gray-50 transition-colors"
      :class="{ 'bg-green-50': $route.path === '/inbox' }"
    >
      <div class="flex items-center space-x-3">
        <div class="flex items-center justify-center w-10 h-10 bg-green-100 rounded-lg">
          <UIcon name="i-heroicons-chat-bubble-left-right" class="w-5 h-5 text-green-600" />
        </div>
        <div>
          <p class="font-medium text-gray-900">AdsyConnect</p>
          <p class="text-sm text-gray-500">Chat with community</p>
        </div>
      </div>
      
      <div class="flex items-center space-x-2">
        <div
          v-if="unreadCount > 0"
          class="flex items-center justify-center w-6 h-6 bg-red-500 text-white text-xs font-bold rounded-full"
        >
          {{ unreadCount > 99 ? '99+' : unreadCount }}
        </div>
        <UIcon name="i-heroicons-chevron-right" class="w-5 h-5 text-gray-400" />
      </div>
    </NuxtLink>
  </div>
</template>

<script setup lang="ts">
// Get unread count from AdsyChat
const { unreadCount } = useAdsyChat()
</script>
