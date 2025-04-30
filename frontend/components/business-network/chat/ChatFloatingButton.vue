<template>
    <div>
      <!-- Floating Chat Button -->
      <button 
        @click="toggleChat" 
        class="fixed bottom-44 right-4 lg:right-[22%] right-5 bg-gradient-to-r from-blue-500 to-indigo-600 text-white shadow-xl rounded-full p-3 flex items-center justify-center transition-all duration-300 hover:shadow-indigo-500/20 hover:scale-105 group"
        :class="{ 'animate-bounce': hasNewMessage, 'rotate-0': !showChat, 'rotate-90': showChat }"
      >
        <span v-if="unreadCount > 0" class="absolute -top-2 -right-2 bg-red-500 text-white text-xs font-bold px-2 py-0.5 rounded-full min-w-[20px] flex items-center justify-center">
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
        
        <svg 
          xmlns="http://www.w3.org/2000/svg" 
          class="h-6 w-6 transition-transform duration-300" 
          :class="{ 'rotate-0': !showChat, 'rotate-45': showChat }"
          fill="none" 
          viewBox="0 0 24 24" 
          stroke="currentColor"
        >
          <path 
            v-if="!showChat" 
            stroke-linecap="round" 
            stroke-linejoin="round" 
            stroke-width="2" 
            d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
          />
          <path 
            v-else 
            stroke-linecap="round" 
            stroke-linejoin="round" 
            stroke-width="2" 
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>
  
      <!-- Chat Interface Modal -->
      <div 
        v-if="showChat" 
        class="fixed bottom-[90px] right-5 z-40 w-[95%] md:w-[400px] lg:w-[450px] h-[600px] max-h-[80vh] bg-white dark:bg-gray-800 rounded-xl shadow-2xl border border-gray-200 dark:border-gray-700 overflow-hidden transition-all duration-500 transform"
        :class="{ 
          'translate-y-0 opacity-100': showChat, 
          'translate-y-10 opacity-0': !showChat 
        }"
      >
        <!-- Header Handle Bar for Mobile -->
        <div class="absolute top-0 left-0 right-0 bg-gray-100 dark:bg-gray-700 py-1 md:hidden">
          <div class="w-12 h-1 rounded-full bg-gray-300 dark:bg-gray-600 mx-auto"></div>
        </div>
        
        <!-- Chat Interface Component -->
        <!-- Chat Interface Component -->
        <BusinessNetworkChatInterface :is-floating="true" />
      </div>
  
      <!-- Backdrop for mobile -->
      <div 
        v-if="showChat" 
        class="fixed inset-0 bg-black/30 z-30 md:hidden backdrop-blur-sm" 
        @click="showChat = false"
      ></div>
    </div>
  </template>
  
  <script setup>
  import { ref, onMounted, onUnmounted } from 'vue';
  import BusinessNetworkChatInterface from './ChatInterface.vue';
  
  // State
  const showChat = ref(false);
  const unreadCount = ref(0);
  const hasNewMessage = ref(false);
  
  // Methods
  const toggleChat = () => {
    showChat.value = !showChat.value;
    if (showChat.value) {
      unreadCount.value = 0;
      hasNewMessage.value = false;
    }
  };
  
  // Mock new message notification for demo purposes
  // You would replace this with your actual notification system
  let messageInterval;
  
  onMounted(() => {
    // Simulate incoming messages every 30 seconds
    messageInterval = setInterval(() => {
      if (!showChat.value) {
        unreadCount.value += 1;
        hasNewMessage.value = true;
        
        // Stop bounce animation after 3 seconds
        setTimeout(() => {
          hasNewMessage.value = false;
        }, 3000);
      }
    }, 30000);
  });
  
  onUnmounted(() => {
    clearInterval(messageInterval);
  });
  </script>
  
  <style scoped>
  /* Custom animations */
  @keyframes bounce {
    0%, 100% {
      transform: translateY(0);
    }
    50% {
      transform: translateY(-10px);
    }
  }
  
  .animate-bounce {
    animation: bounce 1s ease infinite;
  }
  
  /* Mobile styles */
  @media (max-width: 768px) {
    button {
      width: 56px;
      height: 56px;
    }
  }
  </style>