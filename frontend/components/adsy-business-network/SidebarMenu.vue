<template>
  <div class="relative">
    <div
      class="absolute inset-0 bg-gradient-to-br from-blue-50/30 to-purple-50/30 rounded-lg backdrop-blur-sm z-0"
    ></div>    <!-- Create Post Button (Added at top of menu) - Now only shown for logged in users -->
    <button
        v-if="user?.user"
        @click="handleButtonClick('create_post'); openCreatePostModal()"
        class="w-full flex items-center px-3 py-2.5 mb-2 rounded-lg bg-gradient-to-r from-blue-500 to-indigo-600 text-white hover:shadow-sm transition-all duration-200 group relative overflow-hidden"
      >
        <!-- Background glow effect -->
        <div class="absolute inset-0 bg-white/10 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
        
        <!-- Icon -->
        <div class="relative z-10 p-1.5 rounded-md mr-2 bg-white/20 flex items-center justify-center">
          <div v-if="loadingButtons.has('create_post')" class="dotted-spinner white"></div>
          <Plus v-else class="h-4 w-4 text-white" />
        </div>
        
        <!-- Label -->
        <span class="text-sm font-medium transition-all duration-300 group-hover:translate-x-1">
          Create Post
        </span>
      </button>
    <div class="relative z-10 mt-4">
      <h3
        class="text-xs font-semibold text-gray-600 uppercase tracking-wider px-3 mb-3 flex items-center"
      >
        <div
          class="p-1 bg-gradient-to-r from-blue-500 to-purple-500 rounded-md mr-2"
        >
          <Menu class="h-3 w-3 text-white" />
        </div>
        <span>Menu</span>
      </h3>
      
      
      
      <nav class="space-y-1 px-2">
        <NuxtLink
          v-for="item in menuItems"
          :key="item.path"
          :to="item.path"
          @click="handleMenuClick(item.path)"
          class="flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 group relative overflow-hidden"
          :class="{
            'menu-item-active': item.path === route.path,
            'menu-item-inactive': item.path !== route.path,
          }"
        >
          <!-- Background elements for premium look -->
          <div
            v-if="item.path === route.path"
            class="absolute inset-0 bg-gradient-to-r from-blue-500 to-indigo-600 opacity-20 rounded-lg"
          ></div>
          <div
            class="absolute left-0 top-0 h-full w-1.5 rounded-l-lg transition-all duration-300"
            :class="
              item.path === route.path
                ? getMenuItemColor(item.label, 'indicator')
                : 'opacity-0'
            "
          ></div>

          <!-- Icon with dynamic color based on menu item -->
          <div
            class="relative z-10 p-1.5 rounded-md mr-2 transition-all duration-300 flex items-center justify-center"
            :class="[
              item.path === route.path
                ? getMenuItemColor(item.label, 'bg')
                : 'bg-gray-100 group-hover:bg-gray-200',
            ]"
          >
            <component
              :is="item.icon"
              class="h-4 w-4 transition-all duration-300"
              :class="[
                item.path === route.path
                  ? 'text-white'
                  : getMenuItemColor(item.label, 'icon'),
              ]"
            />
            <!-- Notification badge on icon -->
            <span
              v-if="item.badge && item.badge > 0 && item.label === 'Notifications'"
              class="absolute -top-1.5 -right-1.5 flex items-center justify-center w-4 h-4 text-xs font-semibold text-white bg-red-500 rounded-full"
            >
              {{ item.badge > 99 ? '99+' : item.badge }}
            </span>
          </div>

          <!-- Label with dynamic styling -->
          <span
            class="text-sm font-medium transition-all duration-300 group-hover:translate-x-1"
            :class="[
              item.path === route.path
                ? getMenuItemColor(item.label, 'text')
                : 'text-gray-800 group-hover:text-gray-800',
            ]"
          >
            {{ item.label }}

            <!-- "New" badge for exclusive features -->
            <span
              v-if="item.isNew"
              class="ml-1.5 inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-gradient-to-r from-pink-500 to-rose-500 text-white"
            >
              New
            </span>

            <!-- "Beta" badge for beta features -->
            <span
              v-if="item.isBeta"
              class="ml-1.5 inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-gradient-to-r from-orange-500 to-amber-500 text-white"
            >
              Beta
            </span>
          </span>

          <!-- Badge with enhanced styling - only show if greater than 0 -->
          <div
            v-if="item.badge && item.badge > 0"
            class="ml-auto transition-all duration-300 px-2 py-0.5 text-xs rounded-full flex items-center justify-center font-medium"
            :class="getMenuItemColor(item.label, 'badge')"
          >
            {{ item.badge }}
          </div>
        </NuxtLink>
      </nav>
    </div>
  </div>
</template>

<script setup>
import {
  Home,
  User,
  Bell,
  Settings,
  Hash,
  Menu,
  Zap,
  Globe,
  Plus,
  Star
} from "lucide-vue-next";
import { useNotifications } from "~/composables/useNotifications";

const props = defineProps({
  isMobile: Boolean,
});

const emit = defineEmits(['menu-click']);

const route = useRoute();
const router = useRouter();
const { user } = useAuth();
const { unreadCount } = useNotifications();

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

// Create a reactive menu array that updates when unreadCount changes
const mainMenu = computed(() => [
  {
    label: "Recent",
    path: "/business-network",
    icon: Zap,
    active: true,
  },
  {
    label: "Profile",
    path: `/business-network/profile/${user.value?.user?.id}`,
    icon: User,
    active: false,
  },
 
  {
    label: "MindForce",
    path: `/business-network/mindforce`,
    icon: Hash,
    active: false,
    isNew: true,
  },
  {
    label: "Workspaces",
    path: `/business-network/workspaces`,
    icon: Star,
    active: false,
    isBeta: true,
  },
  {
    label: "Notifications",
    path: "/business-network/notifications",
    icon: Bell,
    badge: unreadCount.value,
    active: false,
  },
  {
    label: "Settings",
    path: "/settings",
    icon: Settings,
    active: false,
  },
]);

const guestMenu = [
  {
    label: "Recent",
    path: "/business-network",
    icon: Globe,
    active: true,
  },
  {
    label: "MindForce",
    path: `/business-network/mindforce`,
    icon: Hash,
    active: false,
    isNew: true,
  },
  {
    label: "Login",
    path: `/auth/login`,
    icon: User,
    active: false,
  },
];

// Choose which menu to display based on user auth status
const menuItems = computed(() => {
  return user.value?.user ? mainMenu.value : guestMenu;
});

// Add a method to handle menu clicks with loading states
const handleMenuClick = (path) => {
  emit('menu-click', path);
};

// New method to open create post modal
const openCreatePostModal = () => {
  const eventBus = useEventBus('create-post-event'); // Use a specific named event bus
  eventBus.emit("open-create-post-modal");
};


// Helper function to get dynamic colors for menu items
const getMenuItemColor = (label, type) => {
  const colorMappings = {
    Recent: {
      bg: "bg-gradient-to-r from-blue-500 to-blue-600",
      icon: "text-blue-500 group-hover:text-blue-600",
      text: "text-blue-700",
      badge: "bg-blue-100 text-blue-600",
      indicator: "bg-blue-500",
    },
    Profile: {
      bg: "bg-gradient-to-r from-purple-500 to-purple-600",
      icon: "text-purple-500 group-hover:text-purple-600",
      text: "text-purple-700",
      badge: "bg-purple-100 text-purple-600",
      indicator: "bg-purple-500",
    },
    MindForce: {
      bg: "bg-gradient-to-r from-emerald-500 to-emerald-600",
      icon: "text-emerald-500 group-hover:text-emerald-600",
      text: "text-emerald-700",
      badge: "bg-emerald-100 text-emerald-600",
      indicator: "bg-emerald-500",
    },
    Workspaces: {
      bg: "bg-gradient-to-r from-purple-500 to-purple-600",
      icon: "text-purple-500 group-hover:text-purple-600",
      text: "text-purple-700",
      badge: "bg-purple-100 text-purple-600",
      indicator: "bg-purple-500",
    },
    Notifications: {
      bg: "bg-gradient-to-r from-amber-500 to-amber-600",
      icon: "text-amber-500 group-hover:text-amber-600",
      text: "text-amber-700",
      badge: "bg-amber-100 text-amber-600",
      indicator: "bg-amber-500",
    },
    Settings: {
      bg: "bg-gradient-to-r from-gray-500 to-gray-600",
      icon: "text-gray-600 group-hover:text-gray-600",
      text: "text-gray-800",
      badge: "bg-gray-100 text-gray-600",
      indicator: "bg-gray-500",
    },
    Login: {
      bg: "bg-gradient-to-r from-indigo-500 to-indigo-600",
      icon: "text-indigo-500 group-hover:text-indigo-600",
      text: "text-indigo-700",
      badge: "bg-indigo-100 text-indigo-600",
      indicator: "bg-indigo-500",
    },
  };

  // Default fallback colors if label not found
  const defaultColors = {
    bg: "bg-gradient-to-r from-blue-500 to-indigo-600",
    icon: "text-blue-500 group-hover:text-blue-600",
    text: "text-blue-700",
    badge: "bg-blue-100 text-blue-600",
    indicator: "bg-blue-500",
  };

  return colorMappings[label]?.[type] || defaultColors[type];
};
</script>

<style scoped>
/* Menu Section Premium Styles */
.menu-item-active {
  position: relative;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
  transform: translateY(0);
  transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.menu-item-inactive {
  position: relative;
  transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.menu-item-inactive:hover {
  background: linear-gradient(to right, #f9fafb 0%, #f3f4f6 100%);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  transform: translateY(-1px) scale(1.005);
}

.menu-item-active:active,
.menu-item-inactive:active {
  transform: translateY(1px) scale(0.99);
  transition: all 0.1s cubic-bezier(0.25, 0.8, 0.25, 1);
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1rem;
  height: 1rem;
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

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>