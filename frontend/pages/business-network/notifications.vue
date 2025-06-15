<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header Section - Stripe Style -->
    <div class="bg-white border-b border-gray-200">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="py-6">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-2xl font-semibold text-gray-900">Notifications</h1>
              <p class="text-sm text-gray-600 mt-1">Stay updated with your business network activity</p>
            </div>
            <div v-if="unreadCount > 0" class="flex items-center">
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                {{ unreadCount }} unread
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="max-w-4xl mx-auto sm:px-6 lg:px-8">
      <!-- Loading state -->
      <div
        v-if="loading"
        class="bg-white rounded-lg border border-gray-200 p-8"
      >
        <div class="flex items-center justify-center">
          <Loader2 class="h-6 w-6 text-gray-400 animate-spin mr-3" />
          <span class="text-gray-600">Loading notifications...</span>
        </div>
      </div>

      <!-- Empty state -->
      <div
        v-else-if="filteredNotifications.length === 0"
        class="bg-white rounded-lg border border-gray-200 p-12 text-center"
      >
        <div class="w-12 h-12 mx-auto bg-gray-100 rounded-full flex items-center justify-center mb-4">
          <Bell class="h-6 w-6 text-gray-400" />
        </div>
        <h3 class="text-lg font-medium text-gray-900 mb-2">No notifications</h3>
        <p class="text-gray-500 max-w-sm mx-auto">
          When someone interacts with your content or mentions you, notifications will appear here.
        </p>
      </div>

      <!-- Notifications List - Stripe Style -->
      <div v-else class="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <TransitionGroup name="notification-list" tag="div">
          <div
            v-for="(notification, index) in filteredNotifications"
            :key="notification.id"
            class="group cursor-pointer transition-colors hover:bg-gray-50"
            :class="[
              index !== filteredNotifications.length - 1 ? 'border-b border-gray-100' : '',
              !notification.read ? 'bg-blue-50/30' : ''
            ]"
            @click="openNotification(notification)"
          >
            <div class="px-6 py-4">
              <div class="flex items-start space-x-4">
                <!-- Avatar -->
                <div class="flex-shrink-0">
                  <div class="relative">
                    <img
                      :src="notification.actor?.image || '/placeholder.svg'"
                      :alt="notification.actor?.name"
                      class="h-10 w-10 rounded-full object-cover"
                    />
                    <!-- Type badge -->
                    <div
                      class="absolute -bottom-1 -right-1 w-5 h-5 rounded-full flex items-center justify-center"
                      :class="getNotificationTypeClass(notification.type)"
                    >
                      <component
                        :is="getNotificationIcon(notification.type)"
                        class="h-2.5 w-2.5 text-white"
                      />
                    </div>
                  </div>
                </div>

                <!-- Content -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-center justify-between">
                    <div class="flex-1">
                      <p class="text-sm text-gray-900">
                        <span class="font-medium">{{ notification.actor?.name }}</span>
                        <span class="text-gray-700">{{ getNotificationText(notification) }}</span>
                      </p>
                      <p
                        v-if="notification.content"
                        class="mt-1 text-sm text-gray-600 line-clamp-2"
                      >
                        {{ notification.content }}
                      </p>
                    </div>
                    <div class="flex items-center space-x-3 ml-4">
                      <!-- Time -->
                      <span class="text-xs text-gray-500 whitespace-nowrap">
                        {{ formatTimeAgo(notification.created_at) }}
                      </span>
                      <!-- Unread indicator -->
                      <div v-if="!notification.read" class="w-2 h-2 bg-blue-500 rounded-full"></div>
                      <!-- Mark as read button -->
                      <button
                        v-if="!notification.read"
                        @click.stop="markAsRead(notification.id)"
                        class="opacity-0 group-hover:opacity-100 p-1 rounded-full hover:bg-gray-200 transition-all"
                        aria-label="Mark as read"
                      >
                        <Check class="h-4 w-4 text-gray-500" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </TransitionGroup>
      </div>

      <!-- Load more button -->
      <div v-if="hasMoreNotifications" class="mt-6 text-center">
        <button
          @click="loadMoreNotifications"
          class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
          :disabled="loadingMore"
        >
          <Loader2 v-if="loadingMore" class="h-4 w-4 mr-2 animate-spin" />
          <span v-else>Load more notifications</span>
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
  FOLLOW: "follow",
  LIKE_POST: "like_post",
  LIKE_COMMENT: "like_comment",
  COMMENT: "comment",
  REPLY: "reply",
  MENTION: "mention",
  SOLUTION: "solution",
  GIFT_DIAMONDS: "gift_diamonds", // Added new notification type
};

// Simplified - no filtering by tab type
const filteredNotifications = computed(() => notifications.value);

// Load notifications on mount
onMounted(async () => {
  await fetchNotifications();
  // Automatically mark all notifications as read when visiting the page
  if (unreadCount.value > 0) {
    await markAllAsRead();
  }
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
      unreadCount.value = notifications.value.filter((n) => !n.read).length;
    }
  } catch (error) {
    console.error("Error fetching notifications:", error);
    toast.add({
      title: "Failed to load notifications",
      color: "red",
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
    console.error("Error loading more notifications:", error);
    toast.add({
      title: "Failed to load more notifications",
      color: "red",
    });
  } finally {
    loadingMore.value = false;
  }
}

// Mark a notification as read
async function markAsRead(id) {
  try {
    await put(`/bn/notifications/${id}/read/`, {
      read: true,
    });

    // Update local state
    const notification = notifications.value.find((n) => n.id === id);
    if (notification) {
      notification.read = true;
      unreadCount.value = Math.max(0, unreadCount.value - 1);
    }
  } catch (error) {
    console.error("Error marking notification as read:", error);
  }
}

// Mark all notifications as read
async function markAllAsRead() {
  try {
    await put("/bn/notifications/mark-all-read/");

    // Update local state
    notifications.value.forEach((notification) => {
      notification.read = true;
    });

    unreadCount.value = 0;
  } catch (error) {
    console.error("Error marking all notifications as read:", error);
  }
}

// Get notification type class for styling
function getNotificationTypeClass(type) {
  switch (type) {
    case notificationTypes.FOLLOW:
      return "bg-blue-500";
    case notificationTypes.LIKE_POST:
    case notificationTypes.LIKE_COMMENT:
      return "bg-red-500";
    case notificationTypes.COMMENT:
    case notificationTypes.REPLY:
      return "bg-green-500";
    case notificationTypes.MENTION:
      return "bg-purple-500";
    case notificationTypes.SOLUTION:
      return "bg-amber-500";
    case notificationTypes.GIFT_DIAMONDS:
      return "bg-teal-500";
    default:
      return "bg-gray-500";
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
    case notificationTypes.GIFT_DIAMONDS:
      return BadgeCheck;
    default:
      return Bell;
  }
}

// Get notification text based on type
function getNotificationText(notification) {
  switch (notification.type) {
    case notificationTypes.FOLLOW:
      return " started following you";
    case notificationTypes.LIKE_POST:
      return " liked your post";
    case notificationTypes.LIKE_COMMENT:
      return " liked your comment";
    case notificationTypes.COMMENT:
      return " commented on your post";
    case notificationTypes.REPLY:
      return " replied to your comment";
    case notificationTypes.MENTION:
      return " mentioned you in a post";
    case notificationTypes.SOLUTION:
      return " marked your advice as a solution";
    case notificationTypes.GIFT_DIAMONDS:
      return " sent you gift diamonds";
    default:
      return " interacted with your content";
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
      navigateTo("/business-network");
  }
}

// Format time ago
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${Math.abs(diffInSeconds)} ${
      diffInSeconds === 1 ? "second" : "seconds"
    } ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${Math.abs(diffInMinutes)} ${
      diffInMinutes === 1 ? "minute" : "minutes"
    } ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${Math.abs(diffInHours)} ${
      diffInHours === 1 ? "hour" : "hours"
    } ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${Math.abs(diffInDays)} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${Math.abs(diffInMonths)} ${
    diffInMonths === 1 ? "month" : "months"
  } ago`;
};
</script>

<style scoped>
/* Clean transition animations */
.notification-list-enter-active,
.notification-list-leave-active {
  transition: all 0.3s ease;
}

.notification-list-enter-from,
.notification-list-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* Line clamp utility */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Subtle hover effects for better UX */
.group:hover .opacity-0 {
  opacity: 1;
}

/* Smooth transitions */
* {
  transition-property: color, background-color, border-color, opacity, transform;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 150ms;
}

/* Focus styles for accessibility */
button:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}

/* Better loading state */
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.animate-spin {
  animation: spin 1s linear infinite;
}
</style>
