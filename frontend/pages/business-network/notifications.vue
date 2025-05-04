<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 pt-3 flex-1">
    <p class="text-2xl font-semibold text-gray-900 mb-4">
      <Bell class="inline-block mr-2" />
      Notifications
    </p>

    <!-- Filter tabs - simplified to only All Notifications -->
    <div class="border-b border-gray-200 mb-4">
      <div class="flex space-x-4">
        <button
          class="px-3 py-2 text-sm font-medium transition-colors relative text-blue-600 border-b-2 border-blue-500"
        >
          All Notifications
          <span
            v-if="unreadCount > 0"
            class="ml-1.5 inline-flex items-center justify-center rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-700"
          >
            {{ unreadCount }}
          </span>
        </button>
      </div>
    </div>

    <!-- Notifications content -->
    <div class="space-y-4">
      <!-- Loading state -->
      <div v-if="loading" class="py-12 flex flex-col items-center justify-center">
        <Loader2 class="h-12 w-12 text-blue-500 animate-spin mb-4" />
        <p class="text-gray-500 text-center">Loading notifications...</p>
      </div>

      <!-- Empty state -->
      <div
        v-else-if="filteredNotifications.length === 0"
        class="py-16 flex flex-col items-center justify-center bg-gray-50 rounded-xl border border-gray-100"
      >
        <div class="bg-gray-100 p-4 rounded-full mb-4">
          <Bell class="h-12 w-12 text-gray-400" />
        </div>
        <h3 class="text-lg font-medium text-gray-900 mb-2">No notifications yet</h3>
        <p class="text-gray-500 text-sm max-w-sm text-center">
          When someone interacts with your content or mentions you, you'll see it here
        </p>
      </div>

      <!-- Notification list -->
      <TransitionGroup
        name="notification-list"
        tag="div"
        class="space-y-3"
      >
        <div
          v-for="notification in filteredNotifications"
          :key="notification.id"
          class="bg-white rounded-lg border shadow-sm overflow-hidden transition-all duration-300 hover:shadow-md"
          :class="[!notification.read ? 'border-blue-200' : 'border-gray-200']"
        >
          <!-- Notification item with different styling based on type -->
          <div
            class="flex p-4 cursor-pointer"
            @click="openNotification(notification)"
          >
            <!-- Left side: Avatar -->
            <div class="flex-shrink-0 mr-4">
              <div class="relative">
                <img
                  :src="notification.actor?.image || '/placeholder.svg'"
                  :alt="notification.actor?.name"
                  class="h-12 w-12 rounded-full object-cover border-2"
                  :class="[
                    !notification.read 
                      ? 'border-blue-500' 
                      : 'border-gray-200'
                  ]"
                />
                <!-- Icon badge based on notification type -->
                <div 
                  class="absolute -bottom-1 -right-1 rounded-full p-1 shadow-sm"
                  :class="getNotificationTypeClass(notification.type)"
                >
                  <component
                    :is="getNotificationIcon(notification.type)"
                    class="h-3.5 w-3.5 text-white"
                  />
                </div>
              </div>
            </div>

            <!-- Right side: Content -->
            <div class="flex-1 min-w-0">
              <!-- Notification content -->
              <div>
                <p class="text-sm text-gray-900">
                  <span class="font-medium">{{ notification.actor?.name }}</span>
                  <span> {{ getNotificationText(notification) }}</span>
                </p>
                <p 
                  v-if="notification.content" 
                  class="mt-1 text-sm text-gray-600 line-clamp-1"
                >
                  {{ notification.content }}
                </p>
              </div>

              <!-- Notification metadata -->
              <div class="mt-2 flex items-center">
                <!-- Time -->
                <span class="text-xs text-gray-500">
                  {{ formatTimeAgo(notification.created_at) }}
                </span>
                
                <!-- Unread indicator -->
                <span
                  v-if="!notification.read"
                  class="ml-2 h-2 w-2 rounded-full bg-blue-500"
                ></span>
              </div>
            </div>

            <!-- Mark as read button -->
            <div class="ml-4 flex-shrink-0 flex items-start">
              <button
                v-if="!notification.read"
                @click.stop="markAsRead(notification.id)"
                class="rounded-full p-1 hover:bg-gray-100 transition-colors"
                aria-label="Mark as read"
              >
                <Check class="h-4 w-4 text-gray-500" />
              </button>
            </div>
          </div>
        </div>
      </TransitionGroup>

      <!-- Load more button -->
      <div v-if="hasMoreNotifications" class="flex justify-center pt-4 pb-8">
        <button
          @click="loadMoreNotifications"
          class="inline-flex items-center justify-center rounded-md text-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-blue-200 bg-white hover:bg-blue-50 h-10 px-4 py-2"
          :disabled="loadingMore"
        >
          <Loader2
            v-if="loadingMore"
            class="h-4 w-4 mr-2 animate-spin"
          />
          <span v-else>Load more</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import {
  Bell,
  Check,
  Heart,
  MessageCircle,
  UserPlus,
  BadgeCheck,
  Loader2,
  Star,
  Send,
} from "lucide-vue-next";

definePageMeta({
  layout: "adsy-business-network",
});

// API and auth
const { get, put } = useApi();
const { user } = useAuth();
const toast = useToast();
const route = useRoute();

// State
const loading = ref(true);
const loadingMore = ref(false);
const notifications = ref([]);
const page = ref(1);
const hasMoreNotifications = ref(false);
const unreadCount = ref(0);

// Notification types
const notificationTypes = {
  FOLLOW: 'follow',
  LIKE_POST: 'like_post',
  LIKE_COMMENT: 'like_comment',
  COMMENT: 'comment',
  REPLY: 'reply',
  MENTION: 'mention',
  SOLUTION: 'solution',
};

// Simplified - no filtering by tab type
const filteredNotifications = computed(() => notifications.value);

// Load notifications on mount
onMounted(async () => {
  await fetchNotifications();
});

// Fetch notifications from API
async function fetchNotifications() {
  try {
    loading.value = true;
    const res = await get(`/bn/notifications/?page=${page.value}`);
    
    if (res.data) {
      notifications.value = res.data.results;
      hasMoreNotifications.value = !!res.data.next;
      
      // Count unread notifications
      unreadCount.value = notifications.value.filter(n => !n.read).length;
    }
  } catch (error) {
    console.error('Error fetching notifications:', error);
    toast.add({ 
      title: 'Failed to load notifications',
      color: 'red'
    });
  } finally {
    loading.value = false;
  }
}

// Load more notifications
async function loadMoreNotifications() {
  if (loadingMore.value || !hasMoreNotifications.value) return;
  
  try {
    loadingMore.value = true;
    page.value += 1;
    
    const res = await get(`/bn/notifications/?page=${page.value}`);
    
    if (res.data) {
      notifications.value = [...notifications.value, ...res.data.results];
      hasMoreNotifications.value = !!res.data.next;
    }
  } catch (error) {
    console.error('Error loading more notifications:', error);
    toast.add({
      title: 'Failed to load more notifications',
      color: 'red'
    });
  } finally {
    loadingMore.value = false;
  }
}

// Mark a notification as read
async function markAsRead(id) {
  try {
    await put(`/bn/notifications/${id}/read/`, {
      read: true
    });
    
    // Update local state
    const notification = notifications.value.find(n => n.id === id);
    if (notification) {
      notification.read = true;
      unreadCount.value = Math.max(0, unreadCount.value - 1);
    }
  } catch (error) {
    console.error('Error marking notification as read:', error);
  }
}

// Mark all notifications as read
async function markAllAsRead() {
  try {
    await put('/bn/notifications/mark-all-read/');
    
    // Update local state
    notifications.value.forEach(notification => {
      notification.read = true;
    });
    
    unreadCount.value = 0;
    
    toast.add({
      title: 'All notifications marked as read',
      color: 'green'
    });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    toast.add({
      title: 'Failed to mark all as read',
      color: 'red'
    });
  }
}

// Get notification type class for styling
function getNotificationTypeClass(type) {
  switch (type) {
    case notificationTypes.FOLLOW:
      return 'bg-blue-500';
    case notificationTypes.LIKE_POST:
    case notificationTypes.LIKE_COMMENT:
      return 'bg-red-500';
    case notificationTypes.COMMENT:
    case notificationTypes.REPLY:
      return 'bg-green-500';
    case notificationTypes.MENTION:
      return 'bg-purple-500';
    case notificationTypes.SOLUTION:
      return 'bg-amber-500';
    default:
      return 'bg-gray-500';
  }
}

// Get notification icon based on type
function getNotificationIcon(type) {
  switch (type) {
    case notificationTypes.FOLLOW:
      return UserPlus;
    case notificationTypes.LIKE_POST:
    case notificationTypes.LIKE_COMMENT:
      return Heart;
    case notificationTypes.COMMENT:
    case notificationTypes.REPLY:
      return MessageCircle;
    case notificationTypes.MENTION:
      return Send;
    case notificationTypes.SOLUTION:
      return Star;
    default:
      return Bell;
  }
}

// Get notification text based on type
function getNotificationText(notification) {
  switch (notification.type) {
    case notificationTypes.FOLLOW:
      return ' started following you';
    case notificationTypes.LIKE_POST:
      return ' liked your post';
    case notificationTypes.LIKE_COMMENT:
      return ' liked your comment';
    case notificationTypes.COMMENT:
      return ' commented on your post';
    case notificationTypes.REPLY:
      return ' replied to your comment';
    case notificationTypes.MENTION:
      return ' mentioned you in a post';
    case notificationTypes.SOLUTION:
      return ' marked your advice as a solution';
    default:
      return ' interacted with your content';
  }
}

// Open notification
function openNotification(notification) {
  // Mark as read when clicked
  if (!notification.read) {
    markAsRead(notification.id);
  }
  
  // Navigate to the appropriate page based on notification type
  switch (notification.type) {
    case notificationTypes.FOLLOW:
      navigateTo(`/business-network/profile/${notification.actor?.id}`);
      break;
    case notificationTypes.LIKE_POST:
    case notificationTypes.COMMENT:
    case notificationTypes.MENTION:
      navigateTo(`/business-network/posts/${notification.target_id}`);
      break;
    case notificationTypes.LIKE_COMMENT:
    case notificationTypes.REPLY:
      navigateTo(`/business-network/posts/${notification.parent_id}`);
      break;
    case notificationTypes.SOLUTION:
      navigateTo(`/business-network/mindforce/${notification.target_id}`);
      break;
    default:
      navigateTo('/business-network');
  }
}

// Format time ago 
function formatTimeAgo(dateString) {
  if (!dateString) return "";

  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${diffInSeconds} ${diffInSeconds === 1 ? "second" : "seconds"} ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} ${diffInMinutes === 1 ? "minute" : "minutes"} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} ${diffInHours === 1 ? "hour" : "hours"} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${diffInMonths} ${diffInMonths === 1 ? "month" : "months"} ago`;
}
</script>

<style scoped>
/* Animation for notification list */
.notification-list-enter-active,
.notification-list-leave-active {
  transition: all 0.5s ease;
}

.notification-list-enter-from,
.notification-list-leave-to {
  opacity: 0;
  transform: translateY(30px);
}

/* Additional styling */
:deep(.lucide) {
  stroke-width: 1.5px;
}

@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}
</style>