<template>
    <div class="min-h-screen mt-16 sm:mt-16 bg-gradient-to-b from-gray-50 to-white">
      <!-- Header -->
      <header class="sticky sm:hidden top-0 z-10 bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between shadow-sm">
        <h1 class="text-xl pl-6 font-semibold text-gray-800 bg-gradient-to-r from-blue-600 to-blue-600 bg-clip-text text-transparent">
          Notifications
        </h1>
        <div class="flex items-center space-x-2">
          <button class="p-2 rounded-full hover:bg-gray-100 transition-colors" @click="isFilterOpen = true">
            <Filter class="h-5 w-5 text-gray-600" />
          </button>
          <button 
            class="p-2 rounded-full hover:bg-gray-100 transition-colors"
            @click="markAllAsRead"
            v-if="hasUnreadNotifications"
          >
           
          </button>
        </div>
      </header>
  
      <div class="max-w-2xl mx-auto pb-20">
        <!-- Notification Filters (Desktop) -->
        <div class="hidden md:flex border-b border-gray-200 overflow-x-auto">
          <button 
            v-for="filter in notificationFilters" 
            :key="filter.value"
            @click="activeFilter = filter.value"
            :class="[
              'px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors relative',
              activeFilter === filter.value 
                ? 'text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600' 
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            ]"
          >
            {{ filter.label }}
            <span 
              v-if="filter.value === 'all' && unreadCount > 0" 
              class="ml-1 bg-blue-600 text-white text-xs rounded-full px-1.5 py-0.5 min-w-[20px] inline-flex justify-center"
            >
              {{ unreadCount }}
            </span>
          </button>
        </div>
  
        <!-- Notifications List -->
        <div class="divide-y divide-gray-100">
          <div v-if="loading" class="flex justify-center py-8">
            <div class="h-8 w-8 animate-spin text-blue-600">
              <Loader2 />
            </div>
          </div>
  
          <div v-else-if="filteredNotifications.length === 0" class="py-12 text-center">
            <div class="flex flex-col items-center">
              <div class="bg-gray-100 rounded-full p-4 mb-3">
                <Bell class="h-8 w-8 text-gray-400" />
              </div>
              <h3 class="text-lg font-medium text-gray-900 mb-1">No notifications</h3>
              <p class="text-sm text-gray-500 max-w-sm">
                {{ activeFilter === 'all' ? "You don't have any notifications yet." : "You don't have any notifications in this category." }}
              </p>
            </div>
          </div>
  
          <div 
            v-for="(notification, index) in filteredNotifications" 
            :key="notification.id"
            :class="[
              'p-4 transition-colors hover:bg-gray-50',
              notification.read ? 'bg-white' : 'bg-blue-50/30'
            ]"
            @click="markAsRead(notification)"
            :style="{
              animationDelay: `${index * 0.05}s`,
              animation: 'fadeIn 0.5s ease-out forwards'
            }"
          >
            <!-- Notification Item -->
            <div class="flex items-start gap-3">
              <!-- Notification Icon -->
              <div :class="[
                'rounded-full p-2 flex-shrink-0',
                getNotificationIconClass(notification.type)
              ]">
                <component :is="getNotificationIcon(notification.type)" class="h-5 w-5" />
              </div>
  
              <!-- Notification Content -->
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between gap-2">
                  <div>
                    <!-- User who triggered the notification -->
                    <div class="flex items-center gap-1.5 mb-1">
                      <img 
                        :src="notification.user.avatar" 
                        :alt="notification.user.fullName" 
                        class="w-5 h-5 rounded-full"
                      />
                      <span class="font-medium text-sm">{{ notification.user.fullName }}</span>
                      <span v-if="!notification.read" class="h-2 w-2 rounded-full bg-blue-600"></span>
                    </div>
                    
                    <!-- Notification message -->
                    <p class="text-sm text-gray-700">
                      {{ notification.message }}
                      <span v-if="notification.postTitle" class="font-medium">{{ notification.postTitle }}</span>
                    </p>
                    
                    <!-- Notification time -->
                    <p class="text-xs text-gray-500 mt-1">{{ formatTimeAgo(notification.timestamp) }}</p>
                  </div>
  
                  <!-- Notification Action -->
                  <div class="flex-shrink-0">
                    <img 
                      v-if="notification.postImage" 
                      :src="notification.postImage" 
                      :alt="notification.postTitle || 'Post image'" 
                      class="w-12 h-12 object-cover rounded-md"
                    />
                    <button 
                      v-if="notification.type === 'follow' && !notification.user.isFollowing"
                      class="text-xs h-7 rounded-full px-3 bg-blue-600 text-white flex items-center gap-1"
                      @click.stop="followUser(notification.user)"
                    >
                      <UserPlus class="h-3 w-3" />
                      Follow
                    </button>
                    <button 
                      v-else-if="notification.type === 'follow' && notification.user.isFollowing"
                      class="text-xs h-7 rounded-full px-3 border border-gray-200 text-gray-700 flex items-center gap-1"
                      @click.stop="unfollowUser(notification.user)"
                    >
                      <Check class="h-3 w-3" />
                      Following
                    </button>
                  </div>
                </div>
              </div>
            </div>
  
            <!-- Notification Actions -->
            <div class="mt-2 ml-10 flex items-center gap-4">
              <button 
                v-if="notification.type === 'comment' || notification.type === 'mention' || notification.type === 'reply'"
                class="text-xs text-blue-600 hover:underline"
                @click.stop="viewPost(notification)"
              >
                Reply
              </button>
              <button 
                v-if="notification.type === 'like' || notification.type === 'comment' || notification.type === 'mention'"
                class="text-xs text-blue-600 hover:underline"
                @click.stop="viewPost(notification)"
              >
                View post
              </button>
              <button 
                class="text-xs text-gray-500 hover:text-gray-700"
                @click.stop="removeNotification(notification)"
              >
                Remove
              </button>
            </div>
          </div>
        </div>
  
        <!-- Load More Button -->
        <div v-if="filteredNotifications.length > 0 && hasMoreNotifications" class="flex justify-center py-6">
          <button 
            class="px-4 py-2 text-sm text-blue-600 border border-blue-200 rounded-md hover:bg-blue-50 transition-colors"
            @click="loadMoreNotifications"
            :disabled="loadingMore"
          >
            <span v-if="loadingMore" class="flex items-center">
              <Loader2 class="h-4 w-4 mr-2 animate-spin" />
              Loading...
            </span>
            <span v-else>Load more notifications</span>
          </button>
        </div>
      </div>
  
      <!-- Footer Menu (Mobile) -->
      <div class="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50 shadow-lg">
        <div class="flex justify-between items-center px-2">
          <NuxtLink
            to="/"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-gray-500"
          >
            <div class="relative">
              <Home class="h-6 w-6 mb-1 text-gray-500" />
            </div>
            <span>Recent</span>
          </NuxtLink>
          <NuxtLink
            to="/notifications"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
          >
            <div class="relative">
              <Bell class="h-6 w-6 mb-1 text-blue-600" />
              <span v-if="unreadCount > 0" class="absolute -top-1 -right-1 bg-blue-600 text-white text-[10px] rounded-full min-w-[16px] h-4 flex items-center justify-center px-1">
                {{ unreadCount }}
              </span>
            </div>
            <span>Notifications</span>
          </NuxtLink>
          <NuxtLink
            to="/profile"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-gray-500"
          >
            <div class="relative">
              <User class="h-6 w-6 mb-1 text-gray-500" />
            </div>
            <span>Profile</span>
          </NuxtLink>
          <NuxtLink
            to="/dashboard"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-gray-500"
          >
            <div class="relative">
              <BarChart2 class="h-6 w-6 mb-1 text-gray-500" />
            </div>
            <span>Dashboard</span>
          </NuxtLink>
          <NuxtLink
            to="/saved"
            class="flex flex-col items-center py-3 px-3 text-xs relative text-gray-500"
          >
            <div class="relative">
              <Bookmark class="h-6 w-6 mb-1 text-gray-500" />
            </div>
            <span>Saved</span>
          </NuxtLink>
        </div>
      </div>
  
      <!-- Filter Modal (Mobile) -->
      <Teleport to="body">
        <div v-if="isFilterOpen" class="fixed inset-0 z-[9999] bg-black/50 flex items-end md:items-center justify-center p-4" @click="isFilterOpen = false">
          <div class="bg-white rounded-t-xl md:rounded-xl w-full max-w-md overflow-hidden" @click.stop>
            <div class="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="font-semibold">Filter Notifications</h3>
              <button @click="isFilterOpen = false">
                <X class="h-5 w-5" />
              </button>
            </div>
            <div class="p-4">
              <div class="space-y-2">
                <button 
                  v-for="filter in notificationFilters" 
                  :key="filter.value"
                  @click="selectFilter(filter.value)"
                  class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors"
                  :class="{ 'bg-blue-50': activeFilter === filter.value }"
                >
                  <div class="flex items-center gap-3">
                    <div :class="[
                      'rounded-full p-2',
                      filter.value === 'all' ? 'bg-blue-100 text-blue-600' : getFilterIconClass(filter.value)
                    ]">
                      <component :is="getFilterIcon(filter.value)" class="h-5 w-5" />
                    </div>
                    <span class="font-medium">{{ filter.label }}</span>
                  </div>
                  <Check v-if="activeFilter === filter.value" class="h-5 w-5 text-blue-600" />
                </button>
              </div>
            </div>
            
          </div>
        </div>
      </Teleport>
    </div>
  </template>
  
  <script setup>
  definePageMeta({
    layout: 'adsy-business-network',
  });
  import { ref, computed, onMounted } from 'vue';
  import { 
    Bell, Filter, Heart, MessageCircle, UserPlus, 
    AtSign, Share2, Star, Award, Zap, Check, X, Loader2,
    Home, User, BarChart2, Bookmark, Users, Mail, Tag
  } from 'lucide-vue-next';
  
  // State
  const notifications = ref([]);
  const loading = ref(true);
  const loadingMore = ref(false);
  const page = ref(1);
  const hasMoreNotifications = ref(true);
  const activeFilter = ref('all');
  const isFilterOpen = ref(false);
  
  // Notification filters
  const notificationFilters = [
    { label: 'All notifications', value: 'all' },
    { label: 'Likes', value: 'like' },
    { label: 'Comments', value: 'comment' },
    { label: 'Follows', value: 'follow' },
    { label: 'Mentions', value: 'mention' },
    { label: 'Network', value: 'network' },
    { label: 'System', value: 'system' }
  ];
  
  // Sample user data
  const users = Array.from({ length: 20 }, (_, i) => ({
    id: `user-${i + 1}`,
    fullName: [
      "Emma Johnson",
      "Liam Smith",
      "Olivia Williams",
      "Noah Brown",
      "Ava Jones",
      "Elijah Davis",
      "Sophia Miller",
      "James Wilson",
      "Charlotte Moore",
      "Benjamin Taylor",
      "Amelia Anderson",
      "Lucas Thomas",
      "Mia Jackson",
      "Mason White",
      "Harper Harris",
      "Ethan Martin",
      "Evelyn Thompson",
      "Alexander Garcia",
      "Abigail Martinez",
      "Michael Robinson",
    ][i],
    avatar: `/images/placeholder.jpg?height=40&width=40`,
    isFollowing: Math.random() > 0.5,
  }));
  
  // Generate notifications
  const generateNotifications = (start, count) => {
    const types = ['like', 'comment', 'follow', 'mention', 'reply', 'network', 'system'];
    const postTitles = [
      "Business Strategy Update: Market Analysis",
      "Quarterly Report: Financial Performance",
      "Team Building Workshop Results",
      "Product Launch Announcement",
      "Industry Trends Analysis",
      "Leadership Development Program",
      "Customer Feedback Summary",
      "Project Management Best Practices"
    ];
    
    const messages = {
      like: "liked your post",
      comment: "commented on your post",
      follow: "started following you",
      mention: "mentioned you in a comment",
      reply: "replied to your comment",
      network: "joined your network",
      system: "Your post is trending in Business Strategy"
    };
  
    return Array.from({ length: count }, (_, i) => {
      const id = start + i;
      const type = types[Math.floor(Math.random() * (types.length - 1))]; // Exclude system for most
      const isSystem = type === 'system';
      const user = isSystem ? null : users[Math.floor(Math.random() * users.length)];
      const postTitle = type !== 'follow' ? postTitles[Math.floor(Math.random() * postTitles.length)] : null;
      const hasImage = ['like', 'comment', 'mention'].includes(type) && Math.random() > 0.5;
      
      return {
        id,
        type,
        user: isSystem ? { 
          id: 'system', 
          fullName: 'Business Network', 
          avatar: '/images/placeholder.jpg?height=40&width=40',
          isFollowing: false
        } : user,
        message: messages[type],
        postTitle,
        postImage: hasImage ? `/images/placeholder.jpg?height=100&width=100` : null,
        timestamp: new Date(Date.now() - (id * 1000 * 60 * Math.floor(Math.random() * 60 * 24))).toISOString(),
        read: Math.random() > 0.3, // 30% unread
        postId: `post-${Math.floor(Math.random() * 100)}`
      };
    });
  };
  
  // Computed properties
  const filteredNotifications = computed(() => {
    if (activeFilter.value === 'all') {
      return notifications.value;
    }
    return notifications.value.filter(notification => notification.type === activeFilter.value);
  });
  
  const unreadCount = computed(() => {
    return notifications.value.filter(notification => !notification.read).length;
  });
  
  const hasUnreadNotifications = computed(() => {
    return unreadCount.value > 0;
  });
  
  // Methods
  const loadNotifications = () => {
    loading.value = true;
    
    // Simulate API call
    setTimeout(() => {
      notifications.value = generateNotifications(1, 20);
      loading.value = false;
    }, 1000);
  };
  
  const loadMoreNotifications = () => {
    if (loadingMore.value) return;
    
    loadingMore.value = true;
    
    // Simulate API call
    setTimeout(() => {
      const newNotifications = generateNotifications(notifications.value.length + 1, 10);
      notifications.value = [...notifications.value, ...newNotifications];
      loadingMore.value = false;
      page.value++;
      
      // Simulate end of notifications after page 3
      if (page.value >= 3) {
        hasMoreNotifications.value = false;
      }
    }, 1000);
  };
  
  const markAsRead = (notification) => {
    if (!notification.read) {
      notification.read = true;
    }
  };
  
  const markAllAsRead = () => {
    notifications.value.forEach(notification => {
      notification.read = true;
    });
  };
  
  const removeNotification = (notification) => {
    notifications.value = notifications.value.filter(n => n.id !== notification.id);
  };
  
  const followUser = (user) => {
    user.isFollowing = true;
  };
  
  const unfollowUser = (user) => {
    user.isFollowing = false;
  };
  
  const viewPost = (notification) => {
    // Navigate to post
    console.log(`Navigating to post: ${notification.postId}`);
    // In a real app, you would use router.push or similar
  };
  
  const selectFilter = (filter) => {
    activeFilter.value = filter;
    isFilterOpen.value = false;
  };
  
  // Helper functions
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
      case 'like': return Heart;
      case 'comment': return MessageCircle;
      case 'follow': return UserPlus;
      case 'mention': return AtSign;
      case 'reply': return MessageCircle;
      case 'network': return Users;
      case 'system': return Zap;
      default: return Bell;
    }
  };
  
  const getNotificationIconClass = (type) => {
    switch (type) {
      case 'like': return 'bg-red-100 text-red-600';
      case 'comment': return 'bg-green-100 text-green-600';
      case 'follow': return 'bg-blue-100 text-blue-600';
      case 'mention': return 'bg-purple-100 text-purple-600';
      case 'reply': return 'bg-teal-100 text-teal-600';
      case 'network': return 'bg-indigo-100 text-indigo-600';
      case 'system': return 'bg-amber-100 text-amber-600';
      default: return 'bg-gray-100 text-gray-600';
    }
  };
  
  const getFilterIcon = (filter) => {
    switch (filter) {
      case 'like': return Heart;
      case 'comment': return MessageCircle;
      case 'follow': return UserPlus;
      case 'mention': return AtSign;
      case 'network': return Users;
      case 'system': return Zap;
      default: return Bell;
    }
  };
  
  const getFilterIconClass = (filter) => {
    switch (filter) {
      case 'like': return 'bg-red-100 text-red-600';
      case 'comment': return 'bg-green-100 text-green-600';
      case 'follow': return 'bg-blue-100 text-blue-600';
      case 'mention': return 'bg-purple-100 text-purple-600';
      case 'network': return 'bg-indigo-100 text-indigo-600';
      case 'system': return 'bg-amber-100 text-amber-600';
      default: return 'bg-gray-100 text-gray-600';
    }
  };
  
  // Initialize
  onMounted(() => {
    loadNotifications();
  });
  </script>
  
  <style scoped>
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  </style>