<template>
  <div 
    :class="[
      'bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex flex-col transition-all duration-300 ease-in-out z-20',
      'w-80 md:w-20 md:hover:w-80 group/sidebar',
      isSidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0',
      'fixed md:static inset-y-0 left-0'
    ]"
  >
    <!-- User profile header -->
    <div class="p-4 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center">
      <div class="flex items-center">
        <div class="relative">
          <img 
            src="https://randomuser.me/api/portraits/men/32.jpg" 
            alt="Your profile" 
            class="w-10 h-10 rounded-full object-cover border-2 border-white dark:border-gray-700 shadow-sm"
          />
          <div class="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-white dark:border-gray-800"></div>
        </div>
        <div class="ml-3 hidden md:group-hover/sidebar:block transition-all duration-300">
          <h3 class="text-sm font-semibold text-gray-900 dark:text-white">Alex Johnson</h3>
          <p class="text-xs text-green-500">Online</p>
        </div>
      </div>
      <div class="flex space-x-2 hidden md:group-hover/sidebar:flex">
        <button class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition">
          <settings-icon class="w-5 h-5" />
        </button>
      </div>
    </div>

    <!-- Search -->
    <div class="p-4 border-b border-gray-200 dark:border-gray-700">
      <div class="relative hidden md:group-hover/sidebar:block">
        <search-icon class="absolute left-3 top-3 text-gray-400 dark:text-gray-500 w-5 h-5" />
        <input 
          type="text" 
          placeholder="Search chats..." 
          class="w-full py-2 pl-10 pr-4 bg-gray-100 dark:bg-gray-700 rounded-lg text-sm text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500 transition-all"
          :value="searchQuery"
          @input="$emit('update-search-query', $event.target.value)"
          @keyup="$emit('search')"
        />
      </div>
      <div class="md:group-hover/sidebar:hidden flex justify-center">
        <button class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition">
          <search-icon class="w-5 h-5" />
        </button>
      </div>
    </div>

    <!-- Conversation list -->
    <div class="flex-1 overflow-y-auto">
      <div class="py-2">
        <!-- AdsyAi Chat Option -->
        <div 
          @click="$emit('start-adsyai-chat')"
          class="flex items-center px-4 py-3 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-gray-700 border-b border-gray-100 dark:border-gray-700"
        >
          <div class="relative">
            <div class="w-10 h-10 rounded-full bg-gradient-to-r from-purple-500 to-indigo-600 flex items-center justify-center text-white">
              <bot-icon class="w-6 h-6" />
            </div>
            <div class="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-green-500 border-2 border-white dark:border-gray-800"></div>
          </div>
          <div class="ml-3 flex-1 overflow-hidden hidden md:group-hover/sidebar:block">
            <div class="flex justify-between items-center">
              <h3 class="text-sm font-medium text-gray-900 dark:text-white truncate">AdsyAi Assistant</h3>
              <span class="text-xs text-gray-500 dark:text-gray-400">Always online</span>
            </div>
            <div class="flex justify-between items-center">
              <p class="text-xs text-gray-500 dark:text-gray-400 truncate">Ask me anything about study, business, or more!</p>
            </div>
          </div>
        </div>

        <!-- Loading state for search -->
        <div v-if="isSearching" class="flex justify-center items-center py-8 hidden md:group-hover/sidebar:flex">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
        </div>

        <!-- No results state -->
        <div v-else-if="searchQuery && filteredChats.length === 0" class="px-4 py-8 text-center text-gray-500 dark:text-gray-400 hidden md:group-hover/sidebar:block">
          No chats found
        </div>

        <!-- Groups -->
        <div v-else>
          <h4 class="px-4 py-2 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase hidden md:group-hover/sidebar:block">Groups</h4>
          
          <div 
            v-for="group in filteredGroups"
            :key="'group-' + group.id"
            @click="$emit('select-conversation', group.id)"
            :class="[
              'flex items-center px-4 py-3 cursor-pointer transition-colors',
              activeChat.id === group.id ? 'bg-primary-50 dark:bg-gray-700' : 'hover:bg-gray-50 dark:hover:bg-gray-700'
            ]"
          >
            <div class="relative">
              <div class="w-10 h-10 rounded-full bg-gray-200 dark:bg-gray-700 relative">
                <div class="absolute top-0 left-0 w-6 h-6 rounded-full overflow-hidden border-2 border-white dark:border-gray-800">
                  <img 
                    :src="group.members && group.members[0] ? group.members[0].avatar : 'https://randomuser.me/api/portraits/men/32.jpg'" 
                    class="w-full h-full object-cover"
                    alt="Member"
                  />
                </div>
                <div class="absolute bottom-0 right-0 w-6 h-6 rounded-full overflow-hidden border-2 border-white dark:border-gray-800">
                  <img 
                    :src="group.members && group.members[1] ? group.members[1].avatar : 'https://randomuser.me/api/portraits/women/44.jpg'" 
                    class="w-full h-full object-cover"
                    alt="Member"
                  />
                </div>
              </div>
            </div>
            <div class="ml-3 flex-1 overflow-hidden hidden md:group-hover/sidebar:block">
              <div class="flex justify-between items-center">
                <h3 class="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {{ group.name }}
                  <span class="ml-1 text-xs text-gray-500 dark:text-gray-400">({{ group.members ? group.members.length : 0 }})</span>
                </h3>
                <span class="text-xs text-gray-500 dark:text-gray-400">{{ group.time }}</span>
              </div>
              <div class="flex justify-between items-center">
                <p class="text-xs text-gray-500 dark:text-gray-400 truncate">
                  {{ group.lastMessage }}
                </p>
                <div v-if="group.unread > 0" class="ml-2 bg-primary-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                  {{ group.unread }}
                </div>
              </div>
            </div>
          </div>

          <!-- Friends -->
          <h4 class="px-4 py-2 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase hidden md:group-hover/sidebar:block mt-4">Friends</h4>
          <div 
            v-for="friend in filteredFriends"
            :key="'friend-' + friend.id"
            @click="$emit('select-conversation', friend.id)"
            :class="[
              'flex items-center px-4 py-3 cursor-pointer transition-colors',
              activeChat.id === friend.id ? 'bg-primary-50 dark:bg-gray-700' : 'hover:bg-gray-50 dark:hover:bg-gray-700'
            ]"
          >
            <div class="relative">
              <img 
                :src="friend.avatar" 
                :alt="friend.name" 
                class="w-10 h-10 rounded-full object-cover"
              />
              <div 
                :class="[
                  'absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white dark:border-gray-800',
                  friend.online ? 'bg-green-500' : 'bg-gray-300 dark:bg-gray-500'
                ]"
              ></div>
            </div>
            <div class="ml-3 flex-1 overflow-hidden hidden md:group-hover/sidebar:block">
              <div class="flex justify-between items-center">
                <h3 class="text-sm font-medium text-gray-900 dark:text-white truncate">{{ friend.name }}</h3>
                <span class="text-xs text-gray-500 dark:text-gray-400">{{ friend.time }}</span>
              </div>
              <div class="flex justify-between items-center">
                <p class="text-xs text-gray-500 dark:text-gray-400 truncate">{{ friend.lastMessage }}</p>
                <div v-if="friend.unread > 0" class="ml-2 bg-primary-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                  {{ friend.unread }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Lazy loading indicator at the bottom -->
        <div v-if="isLoadingMore" class="flex justify-center items-center py-4 hidden md:group-hover/sidebar:flex">
          <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-primary-500"></div>
        </div>
      </div>
    </div>

    <!-- New Conversation/Group Button -->
    <div class="p-4 border-t border-gray-200 dark:border-gray-700">
      <div class="flex space-x-2">
        <button 
          @click="$emit('show-new-conversation')"
          class="flex-1 flex items-center justify-center space-x-1 bg-primary-500 hover:bg-primary-600 text-white py-2 px-3 rounded-lg transition-colors duration-200"
        >
          <message-square-plus-icon class="h-4 w-4" />
          <span class="hidden md:group-hover/sidebar:inline-block text-sm">Chat</span>
        </button>
        <button 
          @click="$emit('show-create-group')"
          class="flex-1 flex items-center justify-center space-x-1 bg-green-500 hover:bg-green-600 text-white py-2 px-3 rounded-lg transition-colors duration-200"
        >
          <users-icon class="h-4 w-4" />
          <span class="hidden md:group-hover/sidebar:inline-block text-sm">Group</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { 
  Settings as SettingsIcon,
  Search as SearchIcon,
  MessageSquarePlus as MessageSquarePlusIcon,
  Bot as BotIcon,
  Users as UsersIcon 
} from 'lucide-vue-next';

const props = defineProps({
  friends: {
    type: Array,
    required: true
  },
  groups: {
    type: Array,
    required: true
  },
  searchQuery: {
    type: String,
    default: ''
  },
  activeChat: {
    type: Object,
    required: true
  },
  isSearching: {
    type: Boolean,
    default: false
  },
  isLoadingMore: {
    type: Boolean,
    default: false
  },
  isSidebarOpen: {
    type: Boolean,
    default: true
  }
});

const emit = defineEmits([
  'toggle-sidebar', 
  'select-conversation', 
  'search',
  'update-search-query',
  'start-adsyai-chat',
  'show-new-conversation',
  'show-create-group'
]);

const filteredFriends = computed(() => {
  if (!props.searchQuery) {
    return props.friends;
  }
  return props.friends.filter(friend =>
    friend.name.toLowerCase().includes(props.searchQuery.toLowerCase())
  );
});

const filteredGroups = computed(() => {
  if (!props.searchQuery) {
    return props.groups;
  }
  return props.groups.filter(group =>
    group.name.toLowerCase().includes(props.searchQuery.toLowerCase())
  );
});

const filteredChats = computed(() => {
  return [...filteredGroups.value, ...filteredFriends.value];
});
</script>