<template>
  <div
    class="md:hidden fixed bottom-0 left-0 right-0 bg-gradient-to-r from-white/95 via-slate-50/95 to-white/95 backdrop-blur-lg border-t border-slate-200/40 z-50 shadow-[0_-4px_20px_rgba(0,0,0,0.06)] px-2 transition-all duration-500"
    :class="[
      // Hide on mobile when scrolling down
      isScrollingDown ? 'translate-y-full' : 'translate-y-0'
    ]"
  >
    <div
      class="absolute inset-0 bg-grid opacity-[0.015] pointer-events-none"
    ></div>
    <div
      v-if="user?.user?.id"
      class="flex justify-between items-center px-2 footer-menu"
    >
      <!-- Recent -->
      <NuxtLink
        to="/business-network"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300 menu-item"
        :class="
          $route.path === '/business-network'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-8 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:via-indigo-500 after:to-purple-500 after:shadow-sm'
            : 'text-gray-600 hover:text-blue-500'
        "
        @click="handleRecentClick"
      >
        <div class="relative">
          <div class="icon-wrapper">
            <Clock
              class="h-6 w-6 mb-1 transition-all duration-300 ease-out group-hover:scale-110 drop-shadow-sm"
              :class="
                $route.path === '/business-network'
                  ? 'text-blue-500'
                  : 'text-gray-600'
              "
            />
            <div
              v-if="$route.path === '/business-network'"
              class="icon-gradient-blue"
            ></div>
            <div class="icon-reflection"></div>
          </div>
          <span
            v-if="$route.path === '/business-network'"
            class="absolute inset-0 bg-blue-500/10 rounded-full animate-ping-slow opacity-75"
          ></span>
        </div>
        <span class="font-medium tracking-wide">Recent</span>
      </NuxtLink>

      <!-- Notifications -->
      <NuxtLink
        to="/business-network/notifications"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/business-network/notifications'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-8 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:via-indigo-500 after:to-purple-500 after:shadow-sm'
            : 'text-gray-600 hover:text-blue-500'
        "
      >
        <div class="relative">
          <div class="icon-wrapper">
            <Bell
              class="h-6 w-6 mb-1 transition-all duration-300 ease-out group-hover:scale-110 drop-shadow-sm"
              :class="
                $route.path === '/business-network/notifications'
                  ? 'text-red-500'
                  : 'text-gray-600'
              "
            />
            <div
              v-if="$route.path === '/business-network/notifications'"
              class="icon-gradient-red"
            ></div>
            <div class="icon-reflection"></div>
          </div>
          <span
            v-if="unreadCount > 0"
            class="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1 animate-pulse z-10"
          >
            {{ unreadCount > 99 ? "99+" : unreadCount }}
          </span>
        </div>
        <span class="font-medium tracking-wide">Notifications</span>
      </NuxtLink>
      <!-- Create Post Button (center) -->
      <button
        @click="handleCreatePostClick"
        class="flex flex-col items-center relative group transition-all duration-300 create-button-wrapper"
      >
        <div class="create-post-button">
          <div class="create-post-icon">
            <Plus class="h-7 w-7 text-white font-bold" />
          </div>
          <div class="create-post-backdrop"></div>
        </div>
      </button>

      <!-- Profile -->
      <NuxtLink
        :to="`/business-network/profile/${user?.user?.id}`"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === `/business-network/profile/${user?.user?.id}`
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-8 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:via-indigo-500 after:to-purple-500 after:shadow-sm'
            : 'text-gray-600 hover:text-blue-500'
        "
        @click="handleProfileClick"
      >
        <div class="relative">
          <div class="icon-wrapper">
            <User
              class="h-6 w-6 mb-1 transition-all duration-300 ease-out group-hover:scale-110 drop-shadow-sm"
              :class="
                $route.path === `/business-network/profile/${user?.user?.id}`
                  ? 'text-purple-500'
                  : 'text-gray-600'
              "
            />
            <div
              v-if="
                $route.path === `/business-network/profile/${user?.user?.id}`
              "
              class="icon-gradient-purple"
            ></div>
            <div class="icon-reflection"></div>
          </div>
        </div>        <span class="font-medium tracking-wide">Profile</span>
      </NuxtLink>

      <!-- Adsy Club -->
      <NuxtLink
        to="/"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-8 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:via-indigo-500 after:to-purple-500 after:shadow-sm'
            : 'text-gray-600 hover:text-blue-500'
        "
        @click="handleButtonClick('adsyclub_logged')"
      >
        <div class="relative">
          <div class="icon-wrapper">
            <div v-if="loadingButtons.has('adsyclub_logged')" class="dotted-spinner green mb-1"></div>
            <BarChart2
              v-else
              class="h-6 w-6 mb-1 transition-all duration-300 ease-out group-hover:scale-110 drop-shadow-sm"
              :class="$route.path === '/' ? 'text-green-500' : 'text-gray-600'"
            />
            <div v-if="$route.path === '/'" class="icon-gradient-green"></div>
            <div class="icon-reflection"></div>
          </div>
        </div>
        <span class="font-medium tracking-wide">AdsyClub</span>
      </NuxtLink>
    </div>
    <!-- Footer for non-logged in users -->
    <div v-else class="flex justify-between items-center px-2 footer-menu">
      <!-- Recent -->
      <NuxtLink
        to="/business-network"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300 menu-item"
        :class="
          $route.path === '/business-network'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-8 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:via-indigo-500 after:to-purple-500 after:shadow-sm'
            : 'text-gray-600 hover:text-blue-500'
        "
      >
        <div class="relative">
          <div class="icon-wrapper">
            <Clock
              class="h-6 w-6 mb-1 transition-all duration-300 ease-out group-hover:scale-110 drop-shadow-sm"
              :class="
                $route.path === '/business-network'
                  ? 'text-blue-500'
                  : 'text-gray-600'
              "
            />
            <div
              v-if="$route.path === '/business-network'"
              class="icon-gradient-blue"
            ></div>
            <div class="icon-reflection"></div>
          </div>
        </div>
        <span class="font-medium tracking-wide">Recent</span>
      </NuxtLink>

      <!-- Login -->
      <NuxtLink
        to="/auth/login"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/auth/login'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-8 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:via-indigo-500 after:to-purple-500 after:shadow-sm'
            : 'text-gray-600 hover:text-blue-500'
        "
      >
        <div class="relative">
          <div class="icon-wrapper">
            <User
              class="h-6 w-6 mb-1 transition-all duration-300 ease-out group-hover:scale-110 drop-shadow-sm"
              :class="
                $route.path === '/auth/login'
                  ? 'text-purple-500'
                  : 'text-gray-600'
              "
            />
            <div
              v-if="$route.path === '/auth/login'"
              class="icon-gradient-purple"
            ></div>
            <div class="icon-reflection"></div>
          </div>
        </div>
        <span class="font-medium tracking-wide">Login</span>
      </NuxtLink>
      <!-- Center element - just a placeholder for non-logged in users -->
      <div class="flex flex-col items-center opacity-50 create-button-wrapper">
        <div class="create-post-button-disabled">
          <Plus class="h-7 w-7 text-gray-300" />
        </div>
      </div>      <!-- Earn -->
      <NuxtLink
        to="/#micro-gigs"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/#micro-gigs'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-8 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:via-indigo-500 after:to-purple-500 after:shadow-sm'
            : 'text-gray-600 hover:text-blue-500'
        "
        @click="handleButtonClick('earn_guest')"
      >
        <div class="relative">
          <div class="icon-wrapper">
            <div v-if="loadingButtons.has('earn_guest')" class="dotted-spinner amber mb-1"></div>
            <UIcon
              v-else
              name="i-material-symbols-attach-money"
              class="h-6 w-6 mb-1 transition-all duration-300 ease-out group-hover:scale-110 drop-shadow-sm"
              :class="
                $route.path === '/#micro-gigs'
                  ? 'text-amber-500'
                  : 'text-gray-600'
              "
            />
            <div
              v-if="$route.path === '/#micro-gigs'"
              class="icon-gradient-gold"
            ></div>
            <div class="icon-reflection"></div>
          </div>
        </div>
        <span class="font-medium tracking-wide">Earn</span>
      </NuxtLink>      <!-- Adsy Club -->
      <NuxtLink
        to="/"
        class="flex flex-col items-center py-2 px-1.5 text-xs relative group transition-all duration-300"
        :class="
          $route.path === '/'
            ? 'text-blue-600 after:absolute after:bottom-0 after:left-1/2 after:-translate-x-1/2 after:w-8 after:h-0.5 after:rounded-full after:bg-gradient-to-r after:from-blue-500 after:via-indigo-500 after:to-purple-500 after:shadow-sm'
            : 'text-gray-600 hover:text-blue-500'
        "
        @click="handleButtonClick('adsyclub_guest')"
      >
        <div class="relative">
          <div class="icon-wrapper">
            <div v-if="loadingButtons.has('adsyclub_guest')" class="dotted-spinner green mb-1"></div>
            <BarChart2
              v-else
              class="h-6 w-6 mb-1 transition-all duration-300 ease-out group-hover:scale-110 drop-shadow-sm"
              :class="$route.path === '/' ? 'text-green-500' : 'text-gray-600'"
            />
            <div v-if="$route.path === '/'" class="icon-gradient-green"></div>
            <div class="icon-reflection"></div>
          </div>
        </div>
        <span class="font-medium tracking-wide">AdsyClub</span>
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
  Plus,
} from "lucide-vue-next";
import { useScrollDirection } from "~/composables/useScrollDirection";

const { isScrollingDown, isScrollingUp } = useScrollDirection();

const { user } = useAuth();
const eventBus = useEventBus();
const { unreadCount, fetchUnreadCount } = useNotifications();

// Loading state for buttons
const loadingButtons = ref(new Set());

// Handle button clicks with loading states
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
};

// Watch route changes to clear loading states
watch(() => useRoute().fullPath, () => {
  loadingButtons.value.clear();
});

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
  eventBus.emit("load-recent-posts");
}

// Handle Profile menu click
function handleProfileClick() {
  // Emit loading event for Profile menu
  eventBus.emit("start-loading-profile");
}

// Handle Create Post button click
function handleCreatePostClick() {
  const createPostEventBus = useEventBus("create-post-event");
  createPostEventBus.emit("open-create-post-modal");
}
</script>

<style scoped>
/* Background pattern */
.bg-grid {
  background-image: radial-gradient(circle, currentColor 1px, transparent 1px);
  background-size: 20px 20px;
}

/* Icon wrapper for positioning gradients */
.icon-wrapper {
  position: relative;
  width: 24px;
  height: 24px;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 4px;
}

/* Gradient overlays for active icons - different color schemes */
.icon-gradient-blue {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #60a5fa, #3b82f6, #2563eb);
  background-clip: text;
  -webkit-background-clip: text;
  mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='12' cy='12' r='10'%3E%3C/circle%3E%3Cpolyline points='12 6 12 12 16 14'%3E%3C/polyline%3E%3C/svg%3E")
    no-repeat center;
  mask-size: contain;
  -webkit-mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='12' cy='12' r='10'%3E%3C/circle%3E%3Cpolyline points='12 6 12 12 16 14'%3E%3C/polyline%3E%3C/svg%3E")
    no-repeat center;
  -webkit-mask-size: contain;
}

.icon-gradient-red {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #f87171, #ef4444, #dc2626);
  background-clip: text;
  -webkit-background-clip: text;
  mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9'%3E%3C/path%3E%3Cpath d='M13.73 21a2 2 0 0 1-3.46 0'%3E%3C/path%3E%3C/svg%3E")
    no-repeat center;
  mask-size: contain;
  -webkit-mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9'%3E%3C/path%3E%3Cpath d='M13.73 21a2 2 0 0 1-3.46 0'%3E%3C/path%3E%3C/svg%3E")
    no-repeat center;
  -webkit-mask-size: contain;
}

.icon-gradient-purple {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #c084fc, #a855f7, #7e22ce);
  background-clip: text;
  -webkit-background-clip: text;
  mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2'%3E%3C/path%3E%3Ccircle cx='12' cy='7' r='4'%3E%3C/circle%3E%3C/svg%3E")
    no-repeat center;
  mask-size: contain;
  -webkit-mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2'%3E%3C/path%3E%3Ccircle cx='12' cy='7' r='4'%3E%3C/circle%3E%3C/svg%3E")
    no-repeat center;
  -webkit-mask-size: contain;
}

.icon-gradient-green {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #4ade80, #22c55e, #16a34a);
  background-clip: text;
  -webkit-background-clip: text;
  mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cline x1='12' y1='20' x2='12' y2='10'%3E%3C/line%3E%3Cline x1='18' y1='20' x2='18' y2='4'%3E%3C/line%3E%3Cline x1='6' y1='20' x2='6' y2='16'%3E%3C/line%3E%3C/svg%3E")
    no-repeat center;
  mask-size: contain;
  -webkit-mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cline x1='12' y1='20' x2='12' y2='10'%3E%3C/line%3E%3Cline x1='18' y1='20' x2='18' y2='4'%3E%3C/line%3E%3Cline x1='6' y1='20' x2='6' y2='16'%3E%3C/line%3E%3C/svg%3E")
    no-repeat center;
  -webkit-mask-size: contain;
}

.icon-gradient-orange {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #fb923c, #f97316, #ea580c);
  background-clip: text;
  -webkit-background-clip: text;
  mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='4' width='18' height='18' rx='2' ry='2'%3E%3C/rect%3E%3Cline x1='16' y1='2' x2='16' y2='6'%3E%3C/line%3E%3Cline x1='8' y1='2' x2='8' y2='6'%3E%3C/line%3E%3Cline x1='3' y1='10' x2='21' y2='10'%3E%3C/line%3E%3C/svg%3E")
    no-repeat center;
  mask-size: contain;
  -webkit-mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='4' width='18' height='18' rx='2' ry='2'%3E%3C/rect%3E%3Cline x1='16' y1='2' x2='16' y2='6'%3E%3C/line%3E%3Cline x1='8' y1='2' x2='8' y2='6'%3E%3C/line%3E%3Cline x1='3' y1='10' x2='21' y2='10'%3E%3C/line%3E%3C/svg%3E")
    no-repeat center;
  -webkit-mask-size: contain;
}

.icon-gradient-gold {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #fbbf24, #f59e0b, #d97706);
  background-clip: text;
  -webkit-background-clip: text;
  mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'%3E%3Cpath fill='currentColor' d='M12.6 11.992v-5.586q0-.176-.141-.318q-.14-.142-.318-.142H9.075q-.176 0-.318.142t-.142.318v1.585q0 .176.142.318q.142.142.318.142h1.585v3.563q0 .175.142.317q.142.142.318.142h.3q.176 0 .318-.142q.142-.142.142-.318m-1.159 3.086q-1.888 0-3.56-.712t-2.91-1.951q-1.24-1.24-1.952-2.91Q2.308 8.406 2.308 6.52t.711-3.56q.712-1.674 1.952-2.911Q6.21-.19 7.881-.902t3.56-.712q1.887 0 3.56.712t2.91 1.951q1.24 1.237 1.952 2.91q.711 1.674.711 3.561t-.711 3.56q-.712 1.671-1.952 2.91q-1.237 1.24-2.91 1.952q-1.673.711-3.56.711'/%3E%3C/svg%3E")
    no-repeat center;
  mask-size: contain;
  -webkit-mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath fill='currentColor' d='M12.6 11.992v-5.586q0-.176-.141-.318q-.14-.142-.318-.142H9.075q-.176 0-.318.142t-.142.318v1.585q0 .176.142.318q.142.142.318.142h1.585v3.563q0 .175.142.317q.142.142.318.142h.3q.176 0 .318-.142q.142-.142.142-.318m-1.159 3.086q-1.888 0-3.56-.712t-2.91-1.951q-1.24-1.24-1.952-2.91Q2.308 8.406 2.308 6.52t.711-3.56q.712-1.674 1.952-2.911Q6.21-.19 7.881-.902t3.56-.712q1.887 0 3.56.712t2.91 1.951q1.24 1.237 1.952 2.91q.711 1.674.711 3.561t-.711 3.56q-.712 1.671-1.952 2.91q-1.237 1.24-2.91 1.952q-1.673.711-3.56.711'/%3E%3C/svg%3E")
    no-repeat center;
  -webkit-mask-size: contain;
}

/* 3D reflection highlight effect */
.icon-reflection {
  position: absolute;
  inset: 2px 2px 12px 12px;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.4), transparent);
  border-radius: 50% 50% 0 0;
  transform: rotate(-10deg);
  opacity: 0;
  transition: opacity 0.3s ease;
}

.icon-wrapper:hover .icon-reflection {
  opacity: 0.7;
}

/* Custom animation for slow ping effect on active icons */
@keyframes ping-slow {
  0% {
    transform: scale(0.8);
    opacity: 0.6;
  }
  50% {
    transform: scale(1.2);
    opacity: 0;
  }
  100% {
    transform: scale(0.8);
    opacity: 0;
  }
}

.animate-ping-slow {
  animation: ping-slow 2.5s cubic-bezier(0, 0, 0.2, 1) infinite;
}

/* Slow pulse animation for notification badge */
@keyframes pulse-slow {
  0% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.05);
    opacity: 0.8;
    box-shadow: 0 0 6px rgba(239, 68, 68, 0.5);
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.animate-pulse-slow {
  animation: pulse-slow 2s ease-in-out infinite;
}

/* Create Post Button Styles */
.create-button-wrapper {
  position: relative;
  display: flex;
  justify-content: center;
  width: 20%; /* Equal width for all 5 items */
  transform: translateY(-10px); /* Restore the more elevated appearance */
}

.create-post-button {
  width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  transition: all 0.3s ease;
}

.create-post-icon {
  width: 45px;
  height: 45px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3b82f6, #6366f1, #8b5cf6);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  z-index: 2;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.5);
  transition: all 0.3s ease;
}

/* Enhanced shadow for create button to give it more elevation */
.create-post-button::before {
  content: "";
  position: absolute;
  inset: -3px;
  border-radius: 50%;
  background: radial-gradient(
    circle at center,
    rgba(59, 130, 246, 0.15),
    transparent 70%
  );
  z-index: 0;
  filter: blur(4px);
}

.create-post-button:hover .create-post-icon {
  transform: scale(1.05);
  box-shadow: 0 6px 15px rgba(59, 130, 246, 0.6);
}

.create-post-button:active .create-post-icon {
  transform: scale(0.95);
}

.create-post-backdrop {
  position: absolute;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: rgba(219, 234, 254, 0.2);
  filter: blur(8px);
  z-index: 1;
  transform: scale(0.7);
  opacity: 0;
  transition: all 0.3s ease;
}

.create-post-button:hover .create-post-backdrop {
  transform: scale(1.2);
  opacity: 0.6;
}

/* Disabled create post button */
.create-post-button-disabled {
  width: 45px;
  height: 45px;
  border-radius: 50%;
  background: rgba(203, 213, 225, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

/* Footer menu layout */
.footer-menu {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  width: 100%;
  padding-top: 4px;
  padding-bottom: 4px;
}

/* Menu item styles for equal spacing */
.menu-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 20%;
}

/* Make all menu items equal width */
.flex.justify-between.items-center.px-2 {
  display: flex;
  justify-content: space-between;
}

.flex.justify-between.items-center.px-2 > * {
  width: 20%; /* Equal width for all 5 menu items */
  display: flex;
  justify-content: center;
}

@keyframes pulse-glow {
  0% {
    box-shadow: 0 0 5px rgba(59, 130, 246, 0.5);
  }
  50% {
    box-shadow: 0 0 20px rgba(59, 130, 246, 0.8);
  }
  100% {
    box-shadow: 0 0 5px rgba(59, 130, 246, 0.5);
  }
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1.5rem;
  height: 1.5rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.emerald {
  border-color: #059669;
}

.dotted-spinner.green {
  border-color: #16a34a;
}

.dotted-spinner.slate {
  border-color: #64748b;
}

.dotted-spinner.blue {
  border-color: #3b82f6;
}

.dotted-spinner.violet {
  border-color: #8b5cf6;
}

.dotted-spinner.white {
  border-color: #ffffff;
}

.dotted-spinner.primary {
  border-color: #059669;
}

.dotted-spinner.amber {
  border-color: #f59e0b;
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
