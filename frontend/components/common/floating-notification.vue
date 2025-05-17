<template>
  <div class="notification-container">
    <!-- Notification Bell Button with Premium Effect -->
    <button
      @click="toggleNotifications"
      class="notification-bell-button"
      :class="{ 'has-new': unreadCount > 0 }"
    >
      <div class="bell-inner">
        <UIcon
          :name="isOpen ? 'i-heroicons-bell-alert' : 'i-heroicons-bell'"
          class="w-5 h-5 text-slate-700 dark:text-slate-300"
        />
        <transition name="pulse">
          <div v-if="unreadCount > 0" class="notification-badge">
            {{ unreadCount > 99 ? "99+" : unreadCount }}
          </div>
        </transition>
      </div>
    </button>

    <!-- Notifications Panel with Premium Design -->
    <transition name="slide-fade">
      <div v-if="isOpen" class="notifications-panel relative">
        <div class="panel-header">
          <h3 class="flex items-center gap-2">
            <UIcon name="i-heroicons-bell-alert" class="w-5 h-5 text-indigo-500" />
            Notifications
          </h3>
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
          <div class="premium-spinner"></div>
          <p>Loading notifications...</p>
        </div>

        <div v-else-if="notifications.length === 0" class="empty-state">
          <div class="empty-icon-wrapper">
            <UIcon name="i-heroicons-inbox" class="empty-icon" />
          </div>
          <p>No notifications</p>
          <p class="empty-subtext">You're all caught up!</p>
        </div>

        <div v-else class="notifications-list">
          <div
            v-for="notification in notifications"
            :key="notification.id"
            class="notification-item"
            :class="[
              { unread: !notification.read },
              getNotificationTypeClass(notification.type)
            ]"
            @click="openNotification(notification)"
          >
            <div class="notification-icon-wrapper">
              <UIcon :name="getNotificationIcon(notification.type)" />
              <div class="notification-glow"></div>
            </div>

            <div class="notification-content">
              <div class="notification-title">
                {{ getNotificationTitle(notification) }}
                <span v-if="!notification.read" class="unread-indicator"></span>
              </div>
              <p class="notification-message">{{ notification.message }}</p>
              <div class="notification-meta">
                <span class="notification-time">
                  {{ formatTime(notification.created_at) }}
                </span>
                <span v-if="notification.amount" class="notification-amount">
                  {{ formatAmount(notification.amount) }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- Premium Backdrop -->
    <div
      v-if="isOpen"
      class="notification-backdrop"
      @click="closeNotifications"
    ></div>
  </div>
</template>

<script setup>

const notificationTypes = {
  DEPOSIT: 'deposit',
  WITHDRAW: 'withdraw',
  TRANSFER: 'transfer',
  ORDER_RECEIVED: 'order_received',
  KYC_APPROVED: 'kyc_approved',
  RECHARGE_SUCCESS: 'recharge_success',
  PRO_UPGRADED: 'pro_upgraded'
};

// State management
const isOpen = ref(false)
const isLoading = ref(false)
const notifications = ref([])
const unreadCount = ref(0)

// Toggle notifications panel
const toggleNotifications = async () => {
  isOpen.value = !isOpen.value
  
  if (isOpen.value) {
    await fetchNotifications()
  }
}

// Close notifications panel
const closeNotifications = () => {
  isOpen.value = false
}

// Fetch notifications
const fetchNotifications = async () => {
  try {
    isLoading.value = true
    // Replace with your actual API call
    const response = await fetch('/api/notifications')
    const data = await response.json()
    notifications.value = data.notifications
    unreadCount.value = data.notifications.filter(n => !n.read).length
  } catch (error) {
    console.error('Error fetching notifications:', error)
  } finally {
    isLoading.value = false
  }
}

// Mark all as read
const markAllAsRead = async () => {
  try {
    // Replace with your actual API call
    await fetch('/api/notifications/mark-all-read', {
      method: 'POST'
    })
    notifications.value = notifications.value.map(n => ({
      ...n,
      read: true
    }))
    unreadCount.value = 0
  } catch (error) {
    console.error('Error marking notifications as read:', error)
  }
}

// Open notification
const openNotification = async (notification) => {
  if (!notification.read) {
    try {
      // Replace with your actual API call
      await fetch(`/api/notifications/${notification.id}/mark-read`, {
        method: 'POST'
      })
      notification.read = true
      unreadCount.value--
    } catch (error) {
      console.error('Error marking notification as read:', error)
    }
  }

  // Handle notification click based on type
  switch (notification.type) {
    case notificationTypes.DEPOSIT:
    case notificationTypes.WITHDRAW:
    case notificationTypes.TRANSFER:
      navigateTo('/wallet/transactions')
      break
    case notificationTypes.ORDER_RECEIVED:
      navigateTo(`/orders/${notification.orderId}`)
      break
    case notificationTypes.KYC_APPROVED:
      navigateTo('/profile/verification')
      break
    case notificationTypes.RECHARGE_SUCCESS:
      navigateTo('/mobile/recharge-history')
      break
    case notificationTypes.PRO_UPGRADED:
      navigateTo('/subscription')
      break
  }

  closeNotifications()
}

// Format time
const formatTime = (date) => {
  const now = new Date()
  const notificationDate = new Date(date)
  const diffInSeconds = Math.floor((now - notificationDate) / 1000)

  if (diffInSeconds < 60) return 'Just now'
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`
  return notificationDate.toLocaleDateString()
}

// Get notification type class
function getNotificationTypeClass(type) {
  const classes = {
    [notificationTypes.DEPOSIT]: 'notification-deposit',
    [notificationTypes.WITHDRAW]: 'notification-withdraw',
    [notificationTypes.TRANSFER]: 'notification-transfer',
    [notificationTypes.ORDER_RECEIVED]: 'notification-order',
    [notificationTypes.KYC_APPROVED]: 'notification-kyc',
    [notificationTypes.RECHARGE_SUCCESS]: 'notification-recharge',
    [notificationTypes.PRO_UPGRADED]: 'notification-pro'
  };
  return classes[type] || '';
}

// Get notification icon
function getNotificationIcon(type) {
  const icons = {
    [notificationTypes.DEPOSIT]: 'i-heroicons-arrow-down-circle',
    [notificationTypes.WITHDRAW]: 'i-heroicons-arrow-up-circle',
    [notificationTypes.TRANSFER]: 'i-heroicons-arrows-right-left',
    [notificationTypes.ORDER_RECEIVED]: 'i-heroicons-shopping-bag',
    [notificationTypes.KYC_APPROVED]: 'i-heroicons-check-badge',
    [notificationTypes.RECHARGE_SUCCESS]: 'i-heroicons-device-phone-mobile',
    [notificationTypes.PRO_UPGRADED]: 'i-heroicons-star'
  };
  return icons[type] || 'i-heroicons-bell';
}

// Get notification title
function getNotificationTitle(notification) {
  const titles = {
    [notificationTypes.DEPOSIT]: 'Deposit Successful',
    [notificationTypes.WITHDRAW]: 'Withdrawal Processed',
    [notificationTypes.TRANSFER]: 'Transfer Complete',
    [notificationTypes.ORDER_RECEIVED]: 'New Order Received',
    [notificationTypes.KYC_APPROVED]: 'KYC Verified',
    [notificationTypes.RECHARGE_SUCCESS]: 'Recharge Successful',
    [notificationTypes.PRO_UPGRADED]: 'Welcome to Pro!'
  };
  return titles[notification.type] || notification.title;
}

// Format amount with currency
function formatAmount(amount) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'BDT'
  }).format(amount);
}
</script>

<style scoped>
/* Add these new styles to your existing CSS */

.notification-bell-button {
  @apply fixed z-[9999999999] top-2/3 transform left-2 sm:left-4 
         bg-white dark:bg-slate-800 rounded-lg p-3
         transition-all duration-300 ease-out;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.bell-inner {
  @apply relative flex items-center justify-center;
}

.notification-icon-wrapper {
  @apply relative w-10 h-10 rounded-full flex items-center justify-center;
}

.notification-glow {
  @apply absolute inset-0 rounded-full opacity-25;
  animation: glow 2s infinite;
}

/* Notification Type Specific Styles */
.notification-deposit .notification-icon-wrapper {
  @apply bg-green-100 text-green-600;
}

.notification-withdraw .notification-icon-wrapper {
  @apply bg-red-100 text-red-600;
}

.notification-transfer .notification-icon-wrapper {
  @apply bg-blue-100 text-blue-600;
}

.notification-order .notification-icon-wrapper {
  @apply bg-purple-100 text-purple-600;
}

.notification-kyc .notification-icon-wrapper {
  @apply bg-teal-100 text-teal-600;
}

.notification-recharge .notification-icon-wrapper {
  @apply bg-orange-100 text-orange-600;
}

.notification-pro .notification-icon-wrapper {
  @apply bg-amber-100 text-amber-600;
}

/* Premium Spinner */
.premium-spinner {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(to right, #6366f1, #8b5cf6);
  animation: spin 1s linear infinite;
  position: relative;
}

.premium-spinner::before {
  content: '';
  position: absolute;
  inset: 2px;
  background: white;
  border-radius: 50%;
}

/* Glow Animation */
@keyframes glow {
  0%, 100% {
    transform: scale(1);
    opacity: 0.5;
  }
  50% {
    transform: scale(1.2);
    opacity: 0.8;
  }
}

/* Enhanced Notification Item */
.notification-item {
  @apply relative overflow-hidden transition-all duration-300 ease-out;
}

.notification-item::before {
  content: '';
  @apply absolute inset-0 opacity-0 transition-opacity duration-300;
  background: linear-gradient(to right, rgba(99, 102, 241, 0.1), transparent);
}

.notification-item:hover::before {
  @apply opacity-100;
}

.notification-meta {
  @apply flex justify-between items-center mt-2 text-xs text-gray-500;
}

.notification-amount {
  @apply font-semibold text-indigo-600 dark:text-indigo-400;
}

/* Dark Mode Enhancements */
.dark .premium-spinner::before {
  background: #1e293b;
}

.dark .notification-item::before {
  background: linear-gradient(to right, rgba(99, 102, 241, 0.2), transparent);
}

/* Add to your existing styles */
.notifications-panel {
  @apply fixed right-2 sm:right-4 top-16 w-96 max-w-[calc(100vw-1rem)] 
         bg-white dark:bg-slate-800 rounded-xl shadow-sm 
         border border-gray-200 dark:border-gray-700
         overflow-hidden z-[9999999999];
  max-height: calc(100vh - 5rem);
}

.panel-header {
  @apply flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700;
}

.mark-read-button {
  @apply text-sm text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 
         dark:hover:text-indigo-300 font-medium transition-colors;
}

.notifications-list {
  @apply divide-y divide-gray-200 dark:divide-gray-700 overflow-y-auto;
  max-height: calc(100vh - 12rem);
}

.notification-item {
  @apply flex items-start gap-4 p-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 
         cursor-pointer transition-colors;
}

.notification-content {
  @apply flex-1;
}

.notification-title {
  @apply text-sm font-medium text-gray-700 dark:text-white mb-1 flex items-center gap-2;
}

.unread-indicator {
  @apply w-2 h-2 rounded-full bg-indigo-500;
}

.notification-message {
  @apply text-sm text-gray-500 dark:text-gray-400;
}

.notification-backdrop {
  @apply fixed inset-0 bg-black/20 dark:bg-black/40 z-[999999999];
}

/* Animations */
.slide-fade-enter-active,
.slide-fade-leave-active {
  transition: all 0.3s ease-out;
}

.slide-fade-enter-from {
  transform: translateX(20px);
  opacity: 0;
}

.slide-fade-leave-to {
  transform: translateX(20px);
  opacity: 0;
}

.pulse-enter-active {
  animation: pulse 0.3s ease-out;
}

@keyframes pulse {
  0% {
    transform: scale(0.9);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>