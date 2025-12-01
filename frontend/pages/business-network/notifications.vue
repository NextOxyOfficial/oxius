<template>  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl pt-3 flex-1">    <!-- Filter tabs - simplified to only All Notifications -->
    <div class="border-b border-gray-200 mb-4">
      <div class="flex space-x-4">
        <button
          class="px-3 py-2 text-sm font-medium transition-colors relative text-blue-600 border-b-2 border-blue-500"
        >
          All Notifications
        </button>
      </div>
    </div>

    <!-- Notifications content -->
    <div class="space-y-4">
      <!-- Loading state -->
      <div
        v-if="loading"
        class="py-12 flex flex-col items-center justify-center"
      >
        <div class="shimmer-loader mb-4">
          <Loader2 class="h-12 w-12 text-blue-500 animate-spin" />
        </div>
        <p class="text-gray-600 text-center">Loading notifications...</p>
      </div>

      <!-- Empty state with enhanced styling -->
      <div
        v-else-if="filteredNotifications.length === 0"
        class="py-16 flex flex-col items-center justify-center bg-gradient-to-b from-gray-50 to-white rounded-xl border border-gray-100 shadow-sm"
      >
        <div class="bg-blue-100 p-5 rounded-full mb-5 pulse-animation">
          <Bell class="h-12 w-12 text-blue-500" />
        </div>
        <h3 class="text-xl font-semibold text-gray-800 mb-2">
          No notifications yet
        </h3>
        <p class="text-gray-600 text-sm max-w-sm text-center">
          When someone interacts with your content or mentions you, you'll see
          it here
        </p>
      </div>      <!-- Notification list with Stripe-style design -->
      <div v-else class="bg-white border border-gray-200 rounded-lg overflow-hidden">
        <TransitionGroup name="notification-list" tag="div">
          <div
            v-for="(notification, index) in filteredNotifications"
            :key="notification.id"
            class="border-b border-gray-100 last:border-b-0 transition-all duration-200 hover:bg-gray-50 cursor-pointer"
            :class="[
              !notification.read ? 'bg-blue-50/30' : 'bg-white',
            ]"
            @click="openNotification(notification)"
          >
            <!-- Notification item with Stripe-style layout -->
            <div class="flex items-start p-4">              <!-- Left side: Avatar with enhanced styling -->
              <div class="flex-shrink-0 mr-4">
                <div class="relative">
                  <!-- Profile image with fallback -->
                  <div v-if="notification.actor?.image" class="relative">
                    <img
                      :src="notification.actor.image"
                      :alt="notification.actor?.name"
                      class="h-12 w-12 rounded-full object-cover border-2 shadow-sm"
                      :class="[
                        !notification.read
                          ? 'border-blue-500 ring-2 ring-blue-100 ring-opacity-50'
                          : 'border-gray-200',
                      ]"
                      @error="handleImageError"
                    />
                  </div>
                  <!-- Placeholder avatar -->
                  <div v-else class="h-12 w-12 rounded-full flex items-center justify-center border-2 shadow-sm bg-gradient-to-br from-blue-100 to-blue-200"
                    :class="[
                      !notification.read
                        ? 'border-blue-500 ring-2 ring-blue-100 ring-opacity-50'
                        : 'border-gray-200',
                    ]"
                  >
                    <span class="text-blue-600 font-semibold text-lg">
                      {{ getInitials(notification.actor?.name) }}
                    </span>
                  </div>
                  <!-- Icon badge based on notification type with enhanced styling -->
                  <div
                    class="absolute -bottom-1 -right-1 rounded-full p-1.5 shadow-sm"
                    :class="getNotificationTypeClass(notification.type)"
                  >
                    <component
                      :is="getNotificationIcon(notification.type)"
                      class="h-3.5 w-3.5 text-white"
                    />
                  </div>
                </div>
              </div>

              <!-- Right side: Content with enhanced styling for unread notifications -->
              <div class="flex-1 min-w-0">
                <!-- Notification content -->
                <div>
                  <!-- Workspace notification display -->
                  <template v-if="notification.source === 'workspace'">
                    <p
                      class="text-sm text-gray-800"
                      :class="{ 'font-semibold': !notification.read }"
                    >
                      {{ notification.title }}
                    </p>
                    <p
                      v-if="notification.body"
                      class="mt-1 text-sm text-gray-600 line-clamp-2"
                      :class="{ 'text-gray-700': !notification.read }"
                    >
                      {{ notification.body }}
                    </p>
                  </template>
                  <!-- Social notification display -->
                  <template v-else>
                    <p
                      class="text-sm text-gray-800"
                      :class="{ 'font-semibold': !notification.read }"
                    >
                      <span
                        class="font-medium"
                        :class="{ 'font-semibold': !notification.read }"
                        >{{ notification.actor?.name }}</span
                      >
                      <span> {{ getNotificationText(notification) }}</span>
                    </p>
                    <p
                      v-if="notification.content"
                      class="mt-1 text-sm text-gray-600 line-clamp-1"
                      :class="{ 'text-gray-800': !notification.read }"
                    >
                      {{ notification.content }}
                    </p>
                  </template>
                </div>

                <!-- Notification metadata -->
                <div class="mt-2 flex items-center">
                  <!-- Time -->
                  <span class="text-xs text-gray-600">
                    {{ formatTimeAgo(notification.created_at) }}
                  </span>

                  <!-- Unread indicator with animation -->
                  <span
                    v-if="!notification.read"
                    class="ml-2 h-2 w-2 rounded-full bg-blue-500 pulse-dot"
                  ></span>
                </div>
              </div>

              <!-- Mark as read button with enhanced styling -->
              <div class="ml-4 flex-shrink-0 flex items-start">
                <button
                  v-if="!notification.read"
                  @click.stop="markAsRead(notification.id)"
                  class="rounded-full p-1.5 hover:bg-blue-50 transition-colors transform hover:scale-110"
                  aria-label="Mark as read"
                >
                  <Check class="h-4 w-4 text-blue-500" />
                </button>
              </div>
            </div>
          </div>
        </TransitionGroup>
      </div>
      <!-- Load more button with enhanced styling -->
      <div v-if="hasMoreNotifications" class="flex justify-center pt-4 pb-24 mb-8">
        <button
          @click="loadMoreNotifications"
          class="inline-flex items-center justify-center rounded-md text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-blue-200 bg-white hover:bg-blue-50 h-10 px-6 py-2 shadow-sm hover:shadow-sm transform hover:translate-y-[-2px]"
          :disabled="loadingMore"
        >
          <Loader2 v-if="loadingMore" class="h-4 w-4 mr-2 animate-spin" />
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
  FOLLOW: "follow",
  LIKE_POST: "like_post",
  LIKE_COMMENT: "like_comment",
  COMMENT: "comment",
  REPLY: "reply",
  MENTION: "mention",
  SOLUTION: "solution",
  GIFT_DIAMONDS: "gift_diamonds",
  // Workspace notification types
  NEW_ORDER: "new_order",
  ORDER_ACCEPTED: "order_accepted",
  ORDER_DECLINED: "order_declined",
  ORDER_DELIVERED: "order_delivered",
  ORDER_COMPLETED: "order_completed",
  ORDER_CANCELLED: "order_cancelled",
  ORDER_REOPENED: "order_reopened",
  GIG_SUBMITTED: "gig_submitted",
  GIG_APPROVED: "gig_approved",
  GIG_REJECTED: "gig_rejected",
  DISPUTE_RAISED: "dispute_raised",
  DISPUTE_RESOLVED: "dispute_resolved",
};

// Workspace notifications state
const workspaceNotifications = ref([]);

// Combine all notifications sorted by date
const filteredNotifications = computed(() => {
  const allNotifications = [
    ...notifications.value.map(n => ({ ...n, source: 'social' })),
    ...workspaceNotifications.value.map(n => ({ ...n, source: 'workspace' }))
  ];
  
  // Sort by created_at descending
  return allNotifications.sort((a, b) => {
    const dateA = new Date(a.created_at);
    const dateB = new Date(b.created_at);
    return dateB - dateA;
  });
});

onMounted(async () => {
  await Promise.all([
    fetchNotifications(),
    fetchWorkspaceNotifications()
  ]);
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

// Fetch workspace notifications
async function fetchWorkspaceNotifications() {
  try {
    const res = await get('/notifications/');
    
    if (res.data) {
      const results = res.data.results || res.data || [];
      // Transform workspace notifications to match the format
      workspaceNotifications.value = results.map(n => ({
        id: `ws-${n.id}`,
        type: n.notification_type || 'workspace',
        actor: {
          id: n.actor_id,
          name: n.title?.replace(/^[^\s]+\s/, '') || 'Workspace',
          image: null
        },
        content: n.body,
        title: n.title,
        body: n.body,
        read: n.is_read,
        created_at: n.created_at,
        data: n.data || {},
        source: 'workspace'
      }));
    }
  } catch (error) {
    console.error("Error fetching workspace notifications:", error);
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
    // Workspace notification types
    case notificationTypes.NEW_ORDER:
      return "bg-green-500";
    case notificationTypes.ORDER_ACCEPTED:
      return "bg-blue-500";
    case notificationTypes.ORDER_DECLINED:
    case notificationTypes.ORDER_CANCELLED:
      return "bg-red-500";
    case notificationTypes.ORDER_DELIVERED:
      return "bg-purple-500";
    case notificationTypes.ORDER_COMPLETED:
      return "bg-green-600";
    case notificationTypes.ORDER_REOPENED:
      return "bg-orange-500";
    case notificationTypes.GIG_SUBMITTED:
      return "bg-blue-400";
    case notificationTypes.GIG_APPROVED:
      return "bg-green-500";
    case notificationTypes.GIG_REJECTED:
      return "bg-red-500";
    case notificationTypes.DISPUTE_RAISED:
      return "bg-red-600";
    case notificationTypes.DISPUTE_RESOLVED:
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
    // Workspace types - all use Bell for now
    case notificationTypes.NEW_ORDER:
    case notificationTypes.ORDER_ACCEPTED:
    case notificationTypes.ORDER_DECLINED:
    case notificationTypes.ORDER_DELIVERED:
    case notificationTypes.ORDER_COMPLETED:
    case notificationTypes.ORDER_CANCELLED:
    case notificationTypes.ORDER_REOPENED:
    case notificationTypes.GIG_SUBMITTED:
    case notificationTypes.GIG_APPROVED:
    case notificationTypes.GIG_REJECTED:
    case notificationTypes.DISPUTE_RAISED:
    case notificationTypes.DISPUTE_RESOLVED:
      return Bell;
    default:
      return Bell;
  }
}

// Get notification text based on type
function getNotificationText(notification) {
  // For workspace notifications, use the body directly
  if (notification.source === 'workspace') {
    return '';  // Title and body are shown separately
  }
  
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
  // Mark as read when clicked (only for social notifications)
  if (!notification.read && notification.source !== 'workspace') {
    markAsRead(notification.id);
  }
  
  // Handle workspace notifications
  if (notification.source === 'workspace') {
    // Navigate to workspaces page with appropriate tab
    const data = notification.data || {};
    if (data.order_id) {
      // Navigate to workspaces with order tab
      navigateTo('/business-network/workspaces?tab=order-received');
    } else if (data.gig_id) {
      // Navigate to workspaces with gigs tab
      navigateTo('/business-network/workspaces?tab=my-gigs');
    } else {
      navigateTo('/business-network/workspaces');
    }
    return;
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

// Get initials from name for placeholder
function getInitials(name) {
  if (!name) return '?';
  
  const words = name.trim().split(' ');
  if (words.length === 1) {
    return words[0].charAt(0).toUpperCase();
  }
  
  return (words[0].charAt(0) + words[words.length - 1].charAt(0)).toUpperCase();
}

// Handle image loading errors
function handleImageError(event) {
  // Hide the broken image
  event.target.style.display = 'none';
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

/* Enhanced styling */
:deep(.lucide) {
  stroke-width: 1.5px;
}

/* Premium Animations */
@keyframes pulse {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

@keyframes pulse-slow {
  0%,
  100% {
    transform: scale(1);
    opacity: 0.2;
  }
  50% {
    transform: scale(1.05);
    opacity: 0.25;
  }
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

@keyframes grow {
  from {
    transform: scaleX(0);
  }
  to {
    transform: scaleX(1);
  }
}

@keyframes pulse-dot {
  0%,
  100% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.2);
    opacity: 0.8;
  }
}

@keyframes fade-in-up {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}

/* Apply animations */
.animate-pulse-slow {
  animation: pulse-slow 6s infinite ease-in-out;
}

.animate-float {
  animation: float 8s infinite ease-in-out;
}

.animate-grow {
  animation: grow 0.3s ease-out forwards;
}

.animate-fade-in-up {
  animation: fade-in-up 0.5s ease-out forwards;
}

.animate-fade-in {
  animation: fade-in-up 0.5s ease-out forwards;
  animation-delay: 0.2s;
  opacity: 0;
}

.pulse-dot {
  animation: pulse-dot 2s infinite;
}

.pulse-animation {
  animation: pulse 3s infinite;
}

/* Glass morphism and premium effects */
.glow-subtle {
  box-shadow: 0 0 15px rgba(59, 130, 246, 0.15);
}

.shimmer-badge {
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0.1),
    rgba(255, 255, 255, 0.2),
    rgba(255, 255, 255, 0.1)
  );
  background-size: 200% 100%;
  animation: shimmer 3s infinite linear;
}

.shimmer-loader {
  position: relative;
  overflow: hidden;
  border-radius: 50%;
}

.shimmer-loader::after {
  content: "";
  position: absolute;
  top: -50%;
  left: -50%;
  right: -50%;
  bottom: -50%;
  background: linear-gradient(
    90deg,
    transparent,
    rgba(255, 255, 255, 0.2),
    transparent
  );
  animation: shimmer 2s infinite linear;
}

/* Background pattern for header */
.bg-grid-pattern {
  background-image: radial-gradient(
    circle,
    rgba(255, 255, 255, 0.1) 1px,
    transparent 1px
  );
  background-size: 20px 20px;
}
</style>