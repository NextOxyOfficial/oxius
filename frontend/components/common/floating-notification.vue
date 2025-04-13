<template>
  <div class="notification-container">
    <!-- Notification Bell Button -->
    <button
      @click="toggleNotifications"
      class="fixed z-[9999999999] top-2/3 transform left-2 sm:left-4 bg-white dark:bg-slate-800 shadow-lg rounded-lg p-3 flex items-center space-x-2 notification-bell"
      :class="{ 'has-new': unreadCount > 0 }"
    >
      <UIcon
        :name="isOpen ? 'i-heroicons-bell-solid' : 'i-heroicons-bell'"
        class="w-5 h-5 text-slate-700 dark:text-slate-300"
      />
      <transition name="pulse">
        <div v-if="unreadCount > 0" class="notification-badge">
          {{ unreadCount > 99 ? "99+" : unreadCount }}
        </div>
      </transition>
    </button>

    <!-- Notifications Panel -->
    <transition name="slide-fade">
      <div v-if="isOpen" class="notifications-panel">
        <div class="panel-header">
          <h3>Notifications</h3>
          <div class="header-actions">
            <button
              v-if="unreadCount > 0"
              @click="markAllAsRead"
              class="mark-read-button"
            >
              Mark all as read
            </button>
          </div>
        </div>

        <div v-if="isLoading" class="loading-state">
          <div class="spinner"></div>
          <p>Loading notifications...</p>
        </div>

        <div v-else-if="notifications.length === 0" class="empty-state">
          <UIcon name="i-heroicons-inbox" class="empty-icon" />
          <p>No notifications</p>
          <p class="empty-subtext">You're all caught up!</p>
        </div>

        <div v-else class="notifications-list">
          <div
            v-for="notification in notifications"
            :key="notification.id"
            :class="['notification-item', { unread: !notification.read }]"
            @click="openNotification(notification)"
          >
            <!-- Notification Icon -->
            <div
              class="notification-icon"
              :class="getNotificationColorClass(notification.type)"
            >
              <UIcon :name="getNotificationIcon(notification.type)" />
            </div>

            <!-- Notification Content -->
            <div class="notification-content">
              <div class="notification-title">
                {{ notification.title }}
                <span v-if="!notification.read" class="unread-indicator"></span>
              </div>
              <p class="notification-message">{{ notification.message }}</p>
              <span class="notification-time">{{
                formatTime(notification.created_at)
              }}</span>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- Backdrop for mobile -->
    <div
      v-if="isOpen"
      class="notification-backdrop"
      @click="isOpen = false"
    ></div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from "vue";
import { formatDistanceToNow } from "date-fns";
import { useAuth } from "@/composables/useAuth";

const { user } = useAuth();

// State
const isOpen = ref(false);
const unreadCount = ref(0);
const notifications = ref([]);
const isLoading = ref(true);
const intervalId = ref(null);

// Toggle notification panel
function toggleNotifications() {
  isOpen.value = !isOpen.value;

  // If opening the panel, mark notifications as seen
  if (isOpen.value) {
    markNotificationsAsSeen();
  }
}

// Format time to relative format (e.g. "5 minutes ago")
function formatTime(timestamp) {
  if (!timestamp) return "";
  return formatDistanceToNow(new Date(timestamp), { addSuffix: true });
}

// Get appropriate icon based on notification type
function getNotificationIcon(type) {
  switch (type) {
    case "order_received":
      return "i-heroicons-shopping-bag";
    case "product_purchase":
      return "i-heroicons-shopping-cart";
    case "deposit":
      return "i-heroicons-arrow-down-tray";
    case "withdraw":
      return "i-heroicons-arrow-up-tray";
    case "transfer":
      return "i-heroicons-arrows-right-left";
    case "system_maintenance":
      return "i-heroicons-wrench-screwdriver";
    default:
      return "i-heroicons-bell";
  }
}

// Get color class based on notification type
function getNotificationColorClass(type) {
  switch (type) {
    case "order_received":
      return "bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400";
    case "product_purchase":
      return "bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400";
    case "deposit":
      return "bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400";
    case "withdraw":
      return "bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400";
    case "transfer":
      return "bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-400";
    case "system_maintenance":
      return "bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400";
    default:
      return "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400";
  }
}

// Mark all notifications as read
async function markAllAsRead() {
  try {
    await fetch("/api/notifications/mark-all-read", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
    });

    // Update local state
    notifications.value = notifications.value.map((notification) => ({
      ...notification,
      read: true,
    }));

    updateUnreadCount();
  } catch (error) {
    console.error("Error marking notifications as read:", error);
  }
}

// Mark notifications as seen (when opening the panel)
async function markNotificationsAsSeen() {
  try {
    const unreadIds = notifications.value
      .filter((n) => !n.read)
      .map((n) => n.id);

    if (unreadIds.length === 0) return;

    await fetch("/api/notifications/mark-as-seen", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ ids: unreadIds }),
      credentials: "include",
    });
  } catch (error) {
    console.error("Error marking notifications as seen:", error);
  }
}

// Update the unread count
function updateUnreadCount() {
  unreadCount.value = notifications.value.filter((n) => !n.read).length;
}

// Handle click on notification
async function openNotification(notification) {
  try {
    // Mark as read in the database
    if (!notification.read) {
      await fetch(`/api/notifications/${notification.id}/mark-read`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        credentials: "include",
      });

      // Update local state
      const index = notifications.value.findIndex(
        (n) => n.id === notification.id
      );
      if (index !== -1) {
        notifications.value[index].read = true;
        updateUnreadCount();
      }
    }

    // Handle navigation based on notification type and reference
    if (notification.link) {
      window.location.href = notification.link;
    } else {
      // Navigate based on type and reference_id
      switch (notification.type) {
        case "order_received":
          if (notification.reference_id) {
            window.location.href = `/orders/${notification.reference_id}`;
          }
          break;

        case "product_purchase":
          if (notification.reference_id) {
            window.location.href = `/purchases/${notification.reference_id}`;
          }
          break;

        case "deposit":
        case "withdraw":
        case "transfer":
          window.location.href = "/deposit-withdraw";
          break;

        default:
          // Do nothing for system maintenance
          break;
      }
    }
  } catch (error) {
    console.error("Error handling notification click:", error);
  }
}

// Fetch notifications data from the API
async function fetchNotifications() {
  if (!user.value) return;

  isLoading.value = true;

  try {
    const response = await fetch("/api/notifications", {
      credentials: "include",
    });

    if (!response.ok) {
      throw new Error("Failed to fetch notifications");
    }

    const data = await response.json();

    // Filter notifications by types we want to display
    const validTypes = [
      "order_received",
      "product_purchase",
      "deposit",
      "withdraw",
      "transfer",
      "system_maintenance",
    ];

    notifications.value = data.filter((n) => validTypes.includes(n.type));
    updateUnreadCount();
  } catch (error) {
    console.error("Error fetching notifications:", error);
  } finally {
    isLoading.value = false;
  }
}

// Setup event listeners and polling
onMounted(() => {
  // Initial fetch
  fetchNotifications();

  // Set up polling every 30 seconds
  intervalId.value = setInterval(fetchNotifications, 30000);

  // Clean up on unmount
  onUnmounted(() => {
    if (intervalId.value) {
      clearInterval(intervalId.value);
    }
  });
});

// Watch for user changes to refetch notifications
watch(
  () => user.value,
  (newUser) => {
    if (newUser) {
      fetchNotifications();
    } else {
      notifications.value = [];
      unreadCount.value = 0;
    }
  }
);
</script>

<style scoped>
.notification-container {
  position: relative;
}

.notification-bell {
  position: relative;
  transition: all 0.2s ease;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.dark .notification-bell {
  border-color: rgba(255, 255, 255, 0.1);
}

.notification-bell:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12);
}

.notification-bell:active {
  transform: translateY(0);
}

.notification-bell.has-new {
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(79, 209, 197, 0.4);
  }
  70% {
    box-shadow: 0 0 0 6px rgba(79, 209, 197, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(79, 209, 197, 0);
  }
}

.notification-badge {
  position: absolute;
  top: -6px;
  right: -6px;
  background: linear-gradient(to bottom right, #f97316, #ef4444);
  color: white;
  border-radius: 9999px;
  font-size: 0.7rem;
  font-weight: 600;
  min-width: 18px;
  height: 18px;
  padding: 0 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 4px rgba(239, 68, 68, 0.3);
  border: 1px solid white;
}

.dark .notification-badge {
  border-color: #1e293b;
}

.notifications-panel {
  position: fixed;
  top: 50%;
  left: 3.5rem;
  transform: translateY(-50%);
  width: 320px;
  max-width: calc(100vw - 5rem);
  background-color: white;
  border-radius: 0.75rem;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1),
    0 8px 10px -6px rgba(0, 0, 0, 0.1);
  border: 1px solid rgba(0, 0, 0, 0.05);
  overflow: hidden;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
  z-index: 9999999998;
}

.dark .notifications-panel {
  background-color: #1e293b;
  border-color: rgba(255, 255, 255, 0.1);
}

.panel-header {
  padding: 1rem;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dark .panel-header {
  border-bottom-color: #334155;
}

.panel-header h3 {
  font-weight: 600;
  font-size: 1rem;
  color: #1e293b;
}

.dark .panel-header h3 {
  color: #f8fafc;
}

.header-actions {
  display: flex;
  align-items: center;
}

.mark-read-button {
  font-size: 0.75rem;
  color: #6366f1;
  background: none;
  border: none;
  cursor: pointer;
}

.dark .mark-read-button {
  color: #818cf8;
}

.mark-read-button:hover {
  text-decoration: underline;
}

.notifications-list {
  overflow-y: auto;
  flex-grow: 1;
  max-height: calc(80vh - 60px);
}

.notification-item {
  padding: 1rem;
  display: flex;
  border-bottom: 1px solid #f1f5f9;
  transition: background-color 0.2s;
  cursor: pointer;
}

.dark .notification-item {
  border-bottom-color: #334155;
}

.notification-item:hover {
  background-color: #f8fafc;
}

.dark .notification-item:hover {
  background-color: #0f172a;
}

.notification-item.unread {
  background-color: rgba(99, 102, 241, 0.05);
}

.dark .notification-item.unread {
  background-color: rgba(99, 102, 241, 0.1);
}

.notification-item.unread:hover {
  background-color: rgba(99, 102, 241, 0.08);
}

.dark .notification-item.unread:hover {
  background-color: rgba(99, 102, 241, 0.15);
}

.notification-icon {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 0.75rem;
  flex-shrink: 0;
}

.notification-icon > svg {
  width: 1.25rem;
  height: 1.25rem;
}

.notification-content {
  flex-grow: 1;
  min-width: 0;
}

.notification-title {
  font-weight: 500;
  color: #1e293b;
  margin-bottom: 0.25rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.dark .notification-title {
  color: #f1f5f9;
}

.unread-indicator {
  width: 0.5rem;
  height: 0.5rem;
  background-color: #6366f1;
  border-radius: 50%;
}

.notification-message {
  color: #64748b;
  font-size: 0.875rem;
  margin-bottom: 0.5rem;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.dark .notification-message {
  color: #cbd5e1;
}

.notification-time {
  color: #94a3b8;
  font-size: 0.75rem;
}

.dark .notification-time {
  color: #64748b;
}

.loading-state,
.empty-state {
  padding: 3rem 1rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #94a3b8;
  text-align: center;
}

.spinner {
  width: 2rem;
  height: 2rem;
  border: 3px solid #f1f5f9;
  border-top-color: #6366f1;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

.dark .spinner {
  border-color: #334155;
  border-top-color: #818cf8;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.empty-icon {
  width: 3rem;
  height: 3rem;
  color: #cbd5e1;
  margin-bottom: 1rem;
}

.dark .empty-icon {
  color: #475569;
}

.empty-subtext {
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

.notification-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.3);
  z-index: 9999999990;
}

/* Animation classes */
.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-fade-enter-from,
.slide-fade-leave-to {
  opacity: 0;
  transform: translate3d(-20px, -50%, 0);
}

.pulse-enter-active {
  animation: badge-pulse 0.5s cubic-bezier(0.4, 0, 0.6, 1);
}

@keyframes badge-pulse {
  0%,
  100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.9;
    transform: scale(1.1);
  }
}

/* Responsive adjustments */
@media (max-width: 640px) {
  .notifications-panel {
    width: calc(100vw - 4rem);
    max-height: 60vh;
  }
}
</style>
