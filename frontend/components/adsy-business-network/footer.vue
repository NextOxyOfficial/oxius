<template>
  <div
    class="md:hidden fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-md border-t border-gray-200/70 z-50 shadow-[0_-2px_10px_rgba(0,0,0,0.05)] px-2"
  >
    <div v-if="user?.user?.id" class="flex justify-between items-center px-2">
      <NuxtLink
        to="/business-network"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/business-network'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
        @click="handleRecentClick"
      >
        <div class="relative">
          <Clock
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="
              $route.path === '/business-network'
                ? 'text-blue-600 drop-shadow-md'
                : 'text-gray-500'
            "
          />
          <span v-if="$route.path === '/business-network'" class="absolute inset-0 bg-blue-500/10 rounded-full animate-ping-slow opacity-75"></span>
        </div>
        <span class="font-medium">Recent</span>
      </NuxtLink>
      
      <NuxtLink
        to="/business-network/notifications"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/business-network/notifications'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
      >
        <div class="relative">
          <Bell
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="
              $route.path === '/business-network/notifications'
                ? 'text-blue-600 drop-shadow-md'
                : 'text-gray-500'
            "
          />
          <span
            v-if="unreadCount > 0"
            class="absolute -top-1 -right-1 bg-gradient-to-r from-blue-600 to-indigo-600 text-white text-[10px] rounded-full min-w-[16px] h-4 flex items-center justify-center px-1 shadow-md border border-white/40 animate-pulse-slow"
          >
            {{ unreadCount }}
          </span>
        </div>
        <span class="font-medium">Notifications</span>
      </NuxtLink>
      
      <NuxtLink
        :to="`/business-network/profile/${user?.user?.id}`"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === `/business-network/profile/${user?.user?.id}`
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
        @click="handleProfileClick"
      >
        <div class="relative">
          <User
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="
              $route.path === `/business-network/profile/${user?.user?.id}`
                ? 'text-blue-600 drop-shadow-md'
                : 'text-gray-500'
            "
          />
        </div>
        <span class="font-medium">Profile</span>
      </NuxtLink>
      
      <NuxtLink
        to="/"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
      >
        <div class="relative">
          <BarChart2
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="$route.path === '/' ? 'text-blue-600 drop-shadow-md' : 'text-gray-500'"
          />
        </div>
        <span class="font-medium">Adsy Club</span>
      </NuxtLink>
      
      <NuxtLink
        to="/adsy-news"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/adsy-news'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
      >
        <div class="relative">
          <Newspaper
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="
              $route.path === '/adsy-news' ? 'text-blue-600 drop-shadow-md' : 'text-gray-500'
            "
          />
        </div>
        <span class="font-medium">Adsy News</span>
      </NuxtLink>
    </div>
    
    <div v-else class="flex justify-between items-center">
      <NuxtLink
        to="/business-network"
        class="flex flex-col items-center py-2 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/business-network'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
      >
        <div class="relative">
          <Clock
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="
              $route.path === '/business-network'
                ? 'text-blue-600 drop-shadow-md'
                : 'text-gray-500'
            "
          />
        </div>
        <span class="font-medium">Recent</span>
      </NuxtLink>
      
      <NuxtLink
        to="/auth/login"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/auth/login'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
      >
        <div class="relative">
          <UIcon
            name="i-ic-sharp-person"
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="
              $route.path === '/auth/login' ? 'text-blue-600 drop-shadow-md' : 'text-gray-500'
            "
          />
        </div>
        <span class="font-medium">Login</span>
      </NuxtLink>
      
      <NuxtLink
        to="/#micro-gigs"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/#micro-gigs'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
      >
        <div class="relative">
          <UIcon
            name="i-material-symbols-attach-money"
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="
              $route.path === '/#micro-gigs' ? 'text-blue-600 drop-shadow-md' : 'text-gray-500'
            "
          />
        </div>
        <span class="font-medium">Earn</span>
      </NuxtLink>
      
      <NuxtLink
        to="/"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
      >
        <div class="relative">
          <BarChart2
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="$route.path === '/' ? 'text-blue-600 drop-shadow-md' : 'text-gray-500'"
          />
        </div>
        <span class="font-medium">Adsy Club</span>
      </NuxtLink>
      
      <NuxtLink
        to="/adsy-news"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/adsy-news'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-6 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:to-indigo-500 after:shadow-sm'
            : 'text-gray-500 hover:text-blue-500'
        "
      >
        <div class="relative">
          <Newspaper
            class="h-6 w-6 mb-1 transition-transform duration-300 ease-out group-hover:scale-110"
            :class="
              $route.path === '/adsy-news' ? 'text-blue-600 drop-shadow-md' : 'text-gray-500'
            "
          />
        </div>
        <span class="font-medium">Adsy News</span>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
import {
  BarChart2,
  Bell,
  Bookmark,
  Clock,
  Home,
  Newspaper,
  User,
} from "lucide-vue-next";

const { user } = useAuth();
const eventBus = useEventBus();
const { unreadCount, fetchUnreadCount } = useNotifications();

// Fetch unread count when component is mounted
onMounted(() => {
  // Only fetch if user exists and is logged in
  if (user.value?.user?.id) {
    fetchUnreadCount();
  }
});

// Handle Recent menu click
function handleRecentClick() {
  // Emit a specific event for loading recent posts
  eventBus.emit('load-recent-posts');
  console.log('Emitted load-recent-posts event from footer');
}

// Handle Profile menu click
function handleProfileClick() {
  // Emit loading event for Profile menu
  eventBus.emit('start-loading-profile');
  console.log('Emitted start-loading-profile event from footer');
}
</script>

<style scoped>
/* Custom animation for slow ping effect on active icons */
@keyframes ping-slow {
  0% {
    transform: scale(0.8);
    opacity: 0.8;
  }
  50% {
    transform: scale(1.15);
    opacity: 0;
  }
  100% {
    transform: scale(0.8);
    opacity: 0;
  }
}

.animate-ping-slow {
  animation: ping-slow 2s cubic-bezier(0, 0, 0.2, 1) infinite;
}

/* Slow pulse animation for notification badge */
@keyframes pulse-slow {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.animate-pulse-slow {
  animation: pulse-slow 2s ease-in-out infinite;
}
</style>
