<template>
  <div class="fixed inset-0 z-50 overflow-auto bg-black/60 backdrop-blur-sm flex justify-center items-center p-4" v-if="show">
    <div class="bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-xl shadow-xl w-full max-w-xl flex flex-col transform transition-all border border-gray-200/50 dark:border-slate-700/50 overflow-hidden" style="max-height: 85vh; height: auto;">
      <!-- Header with gradient background -->
      <div class="px-6 py-4 border-b border-gray-200 dark:border-slate-700 flex items-center justify-between relative overflow-hidden">
        <!-- Background gradient pattern for added premium feel -->
        <div class="absolute inset-0 bg-gradient-to-br from-blue-50/30 to-indigo-50/30 dark:from-blue-900/10 dark:to-indigo-900/10 pointer-events-none"></div>
        <div class="absolute inset-0 opacity-5 bg-pattern"></div>
        
        <div class="flex items-center relative z-10">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
            {{ activeTab === 'followers' ? 'Followers' : 'Following' }}
            <span class="ml-2 px-2 py-0.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 text-xs font-medium rounded-full">
              {{ totalCount }}
            </span>
          </h3>
        </div>
        <button 
          @click="closeModal" 
          class="relative z-10 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 focus:outline-none p-1 rounded-full hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors"
        >
          <UIcon name="i-heroicons-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <!-- Tabs -->
      <div class="flex border-b border-gray-200 dark:border-slate-700 bg-gray-50 dark:bg-slate-800/80">
        <button 
          @click="activeTab = 'followers'" 
          class="flex-1 py-3 px-4 text-center focus:outline-none transition-colors duration-200 relative"
          :class="activeTab === 'followers' ? 'text-blue-600 dark:text-blue-400 font-medium' : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'"
        >
          <span class="relative z-10">Followers</span>
          <!-- Animated underline effect -->
          <div 
            v-if="activeTab === 'followers'" 
            class="absolute bottom-0 left-0 h-0.5 w-full bg-gradient-to-r from-blue-500 to-indigo-500 animate-fadeIn"
          ></div>
          <!-- Tab hover effect -->
          <div 
            class="absolute inset-0 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/10 dark:to-indigo-900/10 opacity-0 hover:opacity-100 transition-opacity -z-10"
          ></div>
        </button>
        <button 
          @click="activeTab = 'following'" 
          class="flex-1 py-3 px-4 text-center focus:outline-none transition-colors duration-200 relative"
          :class="activeTab === 'following' ? 'text-blue-600 dark:text-blue-400 font-medium' : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'"
        >
          <span class="relative z-10">Following</span>
          <!-- Animated underline effect -->
          <div 
            v-if="activeTab === 'following'" 
            class="absolute bottom-0 left-0 h-0.5 w-full bg-gradient-to-r from-blue-500 to-indigo-500 animate-fadeIn"
          ></div>
          <!-- Tab hover effect -->
          <div 
            class="absolute inset-0 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/10 dark:to-indigo-900/10 opacity-0 hover:opacity-100 transition-opacity -z-10"
          ></div>
        </button>
      </div>

      <!-- Search Input -->
      <div class="px-6 py-3 border-b border-gray-100 dark:border-slate-700/50">
        <div class="relative">
          <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <UIcon name="i-heroicons-magnifying-glass" class="w-4 h-4 text-gray-400" />
          </div>
          <input
            type="text"
            class="bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full pl-10 p-2.5 transition-colors"
            placeholder="Search by name or username"
            v-model="searchTerm"
          />
        </div>
      </div>      
      <!-- Loading Skeleton -->
      <div v-if="isLoading" class="overflow-y-auto flex-1 px-6 py-3">
        <div v-for="i in 5" :key="`skeleton-${i}`" class="flex items-center py-3 border-b border-gray-100 dark:border-slate-700/50 last:border-0 animate-pulse">
          <div class="w-12 h-12 rounded-full bg-gray-200 dark:bg-slate-600 overflow-hidden relative">
            <!-- Premium border for skeleton profile picture -->
            <div class="absolute inset-0 rounded-full bg-gradient-to-r from-blue-200 to-indigo-200 dark:from-blue-700 dark:to-indigo-700 p-0.5 -m-0.5 opacity-50"></div>
          </div>
          <div class="ml-3 flex-1">
            <div class="h-4 bg-gray-200 dark:bg-slate-600 rounded w-1/3 mb-2"></div>
            <div class="h-3 bg-gray-200 dark:bg-slate-600 rounded w-1/4"></div>
          </div>
          <div class="w-24 h-8 bg-gray-200 dark:bg-slate-600 rounded-md"></div>
        </div>      </div>

    <!-- User List -->
      <div v-else class="overflow-y-auto flex-1 px-4 py-2" style="min-height: 200px; max-height: 60vh;">
        <div v-if="filteredUsers.length === 0" class="flex flex-col items-center justify-center py-10 text-center">
          <div class="w-16 h-16 rounded-full bg-gray-100 dark:bg-slate-700 flex items-center justify-center mb-4">
            <UIcon name="i-heroicons-user-group" class="w-8 h-8 text-gray-300 dark:text-gray-600" />
          </div>
          <h3 class="text-lg font-medium text-gray-700 dark:text-gray-300 mb-1">
            {{ activeTab === 'followers' ? 'No followers found' : 'Not following anyone' }}
          </h3>
          <p v-if="searchTerm" class="text-sm text-gray-500 dark:text-gray-400 mb-4">
            Try a different search term
          </p>
        </div>
        <div v-else>
          <div v-for="user in filteredUsers" :key="user.id" class="flex items-center py-3 border-b border-gray-100 dark:border-slate-700/50 last:border-0 group hover:bg-gray-50 dark:hover:bg-slate-700/30 rounded-lg px-2 transition-all duration-200 ripple-effect transform hover:translate-x-1 shadow-soft">
            <!-- Clickable area that navigates to profile (wraps image and text) -->
            <div class="flex items-center flex-1 cursor-pointer" @click="navigateToProfile(user)">
              <div class="flex-shrink-0 relative">
                <!-- Premium border for profile picture -->
                <div class="absolute inset-0 rounded-full bg-gradient-to-r from-blue-300 to-indigo-400 dark:from-blue-600 dark:to-indigo-500 p-0.5 -m-0.5 opacity-80"></div>
                <div class="w-12 h-12 rounded-full overflow-hidden border-2 border-white dark:border-slate-700 relative">
                  <img 
                    :src="user.profile_image || '/static/frontend/images/placeholder.jpg'" 
                    :alt="user.full_name || user.username"
                    class="w-full h-full object-cover transition-all duration-500 group-hover:scale-105"
                    loading="lazy"
                    @error="handleImageError"
                  />
                </div>
              </div>
              <div class="ml-3 flex-1 min-w-0">
                <div class="text-sm font-medium text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 truncate block transition-colors">
                  {{ user.full_name || user.username }}
                  <UIcon 
                    v-if="user.kyc" 
                    name="i-mdi-check-decagram" 
                    class="inline-block w-4 h-4 text-blue-600 dark:text-blue-400 ml-1 animate-pulse-subtle" 
                  />
                </div>
                <p class="text-xs text-gray-500 dark:text-gray-400 truncate">
                  {{ user.profession || user.username }}
                </p>
              </div>
            </div>
            <div>
              <button 
                v-if="user.id !== currentUserId && currentUser?.value?.user?.id"
                :class="[
                  'text-sm font-medium px-3 py-1.5 rounded-md transition-all duration-300',
                  user.is_following
                    ? 'border border-gray-200 dark:border-slate-600 hover:bg-gray-50 dark:hover:bg-slate-700 text-gray-700 dark:text-white'
                    : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white shadow-sm hover:shadow'
                ]"
                @click.stop="toggleFollow(user)"
              >
                {{ user.is_following ? 'Following' : 'Follow' }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Load More -->
      <div v-if="hasMoreUsers && !isLoading && filteredUsers.length > 0" class="px-6 py-3 border-t border-gray-100 dark:border-slate-700 flex justify-center bg-gray-50 dark:bg-slate-800/80">
        <button 
          @click="loadMoreUsers" 
          class="text-blue-600 dark:text-blue-400 text-sm font-medium hover:text-blue-700 dark:hover:text-blue-300 focus:outline-none flex items-center gap-2 px-4 py-2 bg-blue-50 dark:bg-blue-900/20 rounded-full hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors"
          :disabled="loadingMore"
        >
          <UIcon v-if="loadingMore" name="i-heroicons-arrow-path" class="w-4 h-4 animate-spin" />
          <span v-if="loadingMore">Loading...</span>
          <span v-else>Load More</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useApi } from '~/composables/useApi';
import { useAuth } from '~/composables/useAuth';
import { navigateTo } from '#app';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  userId: {
    type: String,
    required: true,
  },
  initialTab: {
    type: String,
    default: 'followers',
    validator: (value) => ['followers', 'following'].includes(value),
  },
  followersCount: {
    type: Number,
    default: 0,
  },
  followingCount: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['close', 'follow-changed']);

// Composables
const { get, post, del } = useApi();
const { user: currentUser } = useAuth();

// State variables
const activeTab = ref(props.initialTab);
const users = ref([]);
const isLoading = ref(false);
const loadingMore = ref(false);
const searchTerm = ref('');
const page = ref(1);
const hasMoreUsers = ref(true);
const currentUserId = computed(() => currentUser?.value?.user?.id);
const totalCountValue = ref(0);

// Get total count based on active tab
const totalCount = computed(() => {
  // Return the value from the API if available, otherwise fall back to the props
  if (totalCountValue.value > 0) {
    return totalCountValue.value;
  }
  return activeTab.value === 'followers' ? props.followersCount : props.followingCount;
});

// Filter users based on search term
const filteredUsers = computed(() => {
  if (!searchTerm.value) return users.value;
  
  const term = searchTerm.value.toLowerCase();
  return users.value.filter(user => {
    const fullName = (user.full_name || '').toLowerCase();
    const username = (user.username || '').toLowerCase();
    return fullName.includes(term) || username.includes(term);
  });
});

// Watch for tab changes to fetch new data
watch(activeTab, () => {
  resetData();
  fetchUsers();
});

// Watch for search term changes to reset pagination
watch(searchTerm, () => {
  if (searchTerm.value) {
    // If searching, don't reset the full data, just filter it
    hasMoreUsers.value = false;
  } else {
    // If cleared search, restore pagination status
    hasMoreUsers.value = users.value.length < totalCount.value;
  }
});

// Watch for show prop changes
watch(() => props.show, (newVal) => {
  if (newVal) {
    resetData();
    fetchUsers();
  }
});

// Reset data for a new fetch
function resetData() {
  users.value = [];
  page.value = 1;
  hasMoreUsers.value = true;
  searchTerm.value = '';
}

// Fetch users based on active tab
async function fetchUsers() {
  if (!props.userId) return;
  
  isLoading.value = true;
  try {
    const endpoint = activeTab.value === 'followers' 
      ? `/bn/users/${props.userId}/followers/` 
      : `/bn/users/${props.userId}/following/`;
    
    console.log('Fetching from endpoint:', endpoint);
    
    const { data } = await get(endpoint, {
      params: { page: page.value, page_size: 20 }
    });
    
    console.log('User data from API:', data);
    
    if (data && data.results && Array.isArray(data.results)) {
      // Process the user data array to ensure consistent structure
      const processedUsers = data.results.map(item => {
        // Extract user from either follower_details or following_details
        const userDetails = activeTab.value === 'followers' 
          ? item.follower_details 
          : item.following_details;
        
        if (!userDetails) {
          console.log('Missing user details for item:', item);
          return null;
        }
        
        // Create a unified user object with consistent properties
        return {
          id: userDetails.id,
          username: userDetails.username,
          full_name: userDetails.first_name && userDetails.last_name 
            ? `${userDetails.first_name} ${userDetails.last_name}` 
            : userDetails.name || userDetails.username,
          profile_image: userDetails.profile_image || userDetails.avatar,
          profession: userDetails.profession || userDetails.title,
          is_following: !!item.is_following,
          kyc: userDetails.kyc
        };
      }).filter(user => user !== null); // Remove any null entries
      
      if (page.value === 1) {
        users.value = processedUsers;
      } else {
        users.value = [...users.value, ...processedUsers];
      }
      
      hasMoreUsers.value = !!data.next;
      totalCountValue.value = data.count || totalCountValue.value;
    } else {
      console.error('Invalid response format:', data);
    }
  } catch (error) {
    console.error(`Error fetching ${activeTab.value}:`, error);  } finally {
    isLoading.value = false;
    loadingMore.value = false;
  }
}

// Load more users when scrolling
function loadMoreUsers() {
  if (loadingMore.value || !hasMoreUsers.value) return;
  
  loadingMore.value = true;
  page.value += 1;
  fetchUsers();
}

// Toggle follow status for a user
async function toggleFollow(user) {
  if (!currentUser?.value?.user?.id) return;
  
  try {
    const isCurrentlyFollowing = user.is_following;
    
    // Optimistic UI update
    user.is_following = !isCurrentlyFollowing;    
    if (isCurrentlyFollowing) {
      // Unfollow user
      await del(`/bn/users/${user.id}/unfollow/`);
    } else {
      // Follow user
      await post(`/bn/users/${user.id}/follow/`);
    }
    
    // Notify parent component that follow status has changed
    emit('follow-changed', {
      userId: user.id,
      isFollowing: user.is_following
    });
  } catch (error) {
    console.error('Error toggling follow status:', error);
    // Revert the optimistic update on error
    user.is_following = !user.is_following;
  }
}

// Navigate to user profile
function navigateToProfile(user) {
  // Close the modal first
  closeModal();
  // Navigate to the user's profile page
  navigateTo(`/business-network/profile/${user.id}`);
}

// Handle image loading errors
function handleImageError(event) {
  // Replace with placeholder image if the profile image fails to load
  event.target.src = '/static/frontend/images/placeholder.jpg';
}

// Close the modal
function closeModal() {
  emit('close');
}
</script>

<style scoped>
/* Smooth scrolling for user list */
.overflow-y-auto {
  scroll-behavior: smooth;
}

/* Animation for modal */
.transform {
  transition: transform 0.3s ease-out, opacity 0.3s ease;
}

/* Add focus styles for better accessibility */
button:focus {
  outline: 2px solid rgba(59, 130, 246, 0.5);
  outline-offset: 2px;
}

/* Custom scrollbar */
.overflow-y-auto::-webkit-scrollbar {
  width: 6px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.03);
  border-radius: 10px;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background: rgba(59, 130, 246, 0.2);
  border-radius: 10px;
}

.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: rgba(59, 130, 246, 0.4);
}

/* Dark mode adjustments */
.dark .overflow-y-auto::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
}

.dark .overflow-y-auto::-webkit-scrollbar-thumb {
  background: rgba(99, 102, 241, 0.3);
}

.dark .overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: rgba(99, 102, 241, 0.5);
}

/* Animation for pulse effect */
@keyframes pulse-subtle {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Animation for fade in */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.animate-fadeIn {
  animation: fadeIn 0.5s ease forwards;
}

/* Click ripple effect animation */
@keyframes ripple {
  0% {
    transform: scale(0);
    opacity: 0.5;
  }
  100% {
    transform: scale(1.5);
    opacity: 0;
  }
}

.ripple-effect {
  position: relative;
  overflow: hidden;
}

.ripple-effect::after {
  content: "";
  display: block;
  position: absolute;
  width: 100%;
  height: 100%;
  top: 0;
  left: 0;
  pointer-events: none;
  background-image: radial-gradient(circle, rgba(99, 102, 241, 0.4) 10%, transparent 10.01%);
  background-repeat: no-repeat;
  background-position: 50%;
  transform: scale(10);
  opacity: 0;
  transition: transform 0.5s, opacity 0.5s;
}

.ripple-effect:active::after {
  transform: scale(0);
  opacity: 0.3;
  transition: 0s;
  animation: ripple 0.5s ease-out;
}

/* Background pattern */
.bg-pattern {
  background-image: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%239C92AC' fill-opacity='0.08'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}

/* Premium shadow effects for cards */
.shadow-soft {
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03), 0 6px 15px rgba(0, 0, 0, 0.02),
    0 12px 30px rgba(0, 0, 0, 0.01);
  transition: all 0.3s ease;
}

.shadow-soft:hover {
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05), 0 10px 25px rgba(0, 0, 0, 0.04),
    0 15px 35px rgba(0, 0, 0, 0.02);
}
</style>