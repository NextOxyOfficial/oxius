<template>
    <div class="max-w-2xl mx-auto p-4">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold">Notifications</h1>
        <button 
          class="px-3 py-1.5 border border-gray-200 rounded-md text-sm hover:bg-gray-50"
          @click="markAllAsRead"
          :disabled="unreadCount === 0"
        >
          Mark all as read
        </button>
      </div>
  
      <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <div class="flex border-b border-gray-200">
          <button 
            v-for="tab in tabs" 
            :key="tab.value"
            :class="[
              'px-4 py-3 text-sm font-medium transition-colors relative',
              activeTab === tab.value 
                ? 'text-blue-500 border-b-2 border-blue-500' 
                : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
            ]"
            @click="activeTab = tab.value"
          >
            {{ tab.label }}
            <span 
              v-if="tab.value === 'all' && unreadCount > 0" 
              class="ml-2 bg-blue-500 text-white text-xs rounded-full px-2 py-0.5"
            >
              {{ unreadCount }}
            </span>
          </button>
        </div>
        
        <div class="p-4">
          <!-- All Notifications -->
          <div v-if="activeTab === 'all'" class="space-y-2">
            <div 
              v-for="notification in notifications" 
              :key="notification.id"
              :class="[
                'block p-3 rounded-lg border transition-colors',
                notification.read
                  ? 'border-gray-100 bg-white hover:bg-gray-50'
                  : 'border-blue-500/20 bg-blue-500/5 hover:bg-blue-500/10'
              ]"
              @click="markAsRead(notification.id)"
            >
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 mt-1">
                  <div v-if="notification.user">
                    <img
                      :src="notification.user.avatar"
                      :alt="notification.user.name"
                      class="w-10 h-10 rounded-full"
                    />
                  </div>
                  <div v-else class="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center">
                    <component :is="getNotificationIcon(notification.type)" class="h-4 w-4" :class="getIconColor(notification.type)" />
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-start justify-between">
                    <p class="text-sm">
                      <span v-if="notification.user" class="font-medium">{{ notification.user.name }} </span>
                      <span class="text-gray-700">{{ notification.content }}</span>
                    </p>
                    <span v-if="!notification.read" class="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full"></span>
                  </div>
                  <p class="text-xs text-gray-500 mt-1">{{ formatTimeAgo(notification.timestamp) }}</p>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Unread Notifications -->
          <div v-else-if="activeTab === 'unread'" class="space-y-2">
            <div v-if="unreadNotifications.length > 0">
              <div 
                v-for="notification in unreadNotifications" 
                :key="notification.id"
                class="block p-3 rounded-lg border border-blue-500/20 bg-blue-500/5 hover:bg-blue-500/10 transition-colors"
                @click="markAsRead(notification.id)"
              >
                <div class="flex items-start gap-3">
                  <div class="flex-shrink-0 mt-1">
                    <div v-if="notification.user">
                      <img
                        :src="notification.user.avatar"
                        :alt="notification.user.name"
                        class="w-10 h-10 rounded-full"
                      />
                    </div>
                    <div v-else class="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center">
                      <component :is="getNotificationIcon(notification.type)" class="h-4 w-4" :class="getIconColor(notification.type)" />
                    </div>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-start justify-between">
                      <p class="text-sm">
                        <span v-if="notification.user" class="font-medium">{{ notification.user.name }} </span>
                        <span class="text-gray-700">{{ notification.content }}</span>
                      </p>
                      <span class="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full"></span>
                    </div>
                    <p class="text-xs text-gray-500 mt-1">{{ formatTimeAgo(notification.timestamp) }}</p>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="text-center py-10">
              <BellIcon class="h-12 w-12 text-gray-300 mx-auto mb-3" />
              <h3 class="text-lg font-medium text-gray-900">All caught up!</h3>
              <p class="text-gray-500 mt-1">You have no unread notifications.</p>
            </div>
          </div>
          
          <!-- Mentions Notifications -->
          <div v-else-if="activeTab === 'mentions'" class="space-y-2">
            <div v-if="mentionNotifications.length > 0">
              <div 
                v-for="notification in mentionNotifications" 
                :key="notification.id"
                :class="[
                  'block p-3 rounded-lg border transition-colors',
                  notification.read
                    ? 'border-gray-100 bg-white hover:bg-gray-50'
                    : 'border-blue-500/20 bg-blue-500/5 hover:bg-blue-500/10'
                ]"
                @click="markAsRead(notification.id)"
              >
                <div class="flex items-start gap-3">
                  <div class="flex-shrink-0 mt-1">
                    <img
                      :src="notification.user.avatar"
                      :alt="notification.user.name"
                      class="w-10 h-10 rounded-full"
                    />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex items-start justify-between">
                      <p class="text-sm">
                        <span class="font-medium">{{ notification.user.name }} </span>
                        <span class="text-gray-700">{{ notification.content }}</span>
                      </p>
                      <span v-if="!notification.read" class="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full"></span>
                    </div>
                    <p class="text-xs text-gray-500 mt-1">{{ formatTimeAgo(notification.timestamp) }}</p>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="text-center py-10">
              <StarIcon class="h-12 w-12 text-gray-300 mx-auto mb-3" />
              <h3 class="text-lg font-medium text-gray-900">No mentions yet</h3>
              <p class="text-gray-500 mt-1">When someone mentions you, it will appear here.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
    definePageMeta({
        layout: "businessnetwork",
    });
  import { 
    Bell as BellIcon,
    Heart as HeartIcon,
    MessageCircle as MessageCircleIcon,
    UserPlus as UserPlusIcon,
    Star as StarIcon,
    Calendar as CalendarIcon
  } from 'lucide-vue-next';
  
  // Tabs
  const tabs = [
    { label: 'All', value: 'all' },
    { label: 'Unread', value: 'unread' },
    { label: 'Mentions', value: 'mentions' },
  ];
  
  // State
  const activeTab = ref('all');
  const notifications = ref([
    {
      id: "1",
      type: "like",
      user: {
        id: "user-1",
        name: "Emma Johnson",
        avatar: "/placeholder.svg?height=40&width=40",
      },
      content: "liked your post about Market Analysis",
      timestamp: "2023-04-18T14:30:00Z",
      read: false,
      actionUrl: "/post/123",
    },
    {
      id: "2",
      type: "comment",
      user: {
        id: "user-2",
        name: "Liam Smith",
        avatar: "/placeholder.svg?height=40&width=40",
      },
      content: "commented on your post about Quarterly Report",
      timestamp: "2023-04-18T12:15:00Z",
      read: false,
      actionUrl: "/post/124",
    },
    {
      id: "3",
      type: "follow",
      user: {
        id: "user-3",
        name: "Olivia Williams",
        avatar: "/placeholder.svg?height=40&width=40",
      },
      content: "started following you",
      timestamp: "2023-04-17T22:45:00Z",
      read: true,
      actionUrl: "/profile/user-3",
    },
    {
      id: "4",
      type: "mention",
      user: {
        id: "user-4",
        name: "Noah Brown",
        avatar: "/placeholder.svg?height=40&width=40",
      },
      content: "mentioned you in a comment",
      timestamp: "2023-04-17T18:20:00Z",
      read: true,
      actionUrl: "/post/125#comment-456",
    },
    {
      id: "5",
      type: "event",
      content: "Reminder: Virtual Networking Event tomorrow at 3 PM",
      timestamp: "2023-04-17T09:10:00Z",
      read: false,
      actionUrl: "/events/789",
    },
    {
      id: "6",
      type: "system",
      content: "Your profile has been verified",
      timestamp: "2023-04-16T15:30:00Z",
      read: true,
      actionUrl: "/profile",
    },
    {
      id: "7",
      type: "like",
      user: {
        id: "user-5",
        name: "Ava Jones",
        avatar: "/placeholder.svg?height=40&width=40",
      },
      content: "and 5 others liked your post about Team Building",
      timestamp: "2023-04-16T11:45:00Z",
      read: true,
      actionUrl: "/post/126",
    },
    {
      id: "8",
      type: "comment",
      user: {
        id: "user-6",
        name: "Elijah Davis",
        avatar: "/placeholder.svg?height=40&width=40",
      },
      content: "replied to your comment on Product Launch",
      timestamp: "2023-04-15T20:15:00Z",
      read: true,
      actionUrl: "/post/127#comment-789",
    },
  ]);
  
  // Computed
  const unreadNotifications = computed(() => {
    return notifications.value.filter(n => !n.read);
  });
  
  const mentionNotifications = computed(() => {
    return notifications.value.filter(n => n.type === 'mention');
  });
  
  const unreadCount = computed(() => {
    return unreadNotifications.value.length;
  });
  
  // Methods
  const formatTimeAgo = (dateString) => {
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
  };
  
  const getNotificationIcon = (type) => {
    switch (type) {
      case "like":
        return HeartIcon;
      case "comment":
        return MessageCircleIcon;
      case "follow":
        return UserPlusIcon;
      case "mention":
        return StarIcon;
      case "event":
        return CalendarIcon;
      default:
        return BellIcon;
    }
  };
  
  const getIconColor = (type) => {
    switch (type) {
      case "like":
        return "text-red-500";
      case "comment":
        return "text-blue-500";
      case "follow":
        return "text-green-500";
      case "mention":
        return "text-yellow-500";
      case "event":
        return "text-purple-500";
      default:
        return "text-gray-500";
    }
  };
  
  const markAsRead = (id) => {
    const index = notifications.value.findIndex(n => n.id === id);
    if (index !== -1) {
      notifications.value[index].read = true;
    }
  };
  
  const markAllAsRead = () => {
    notifications.value = notifications.value.map(n => ({ ...n, read: true }));
  };
  </script>