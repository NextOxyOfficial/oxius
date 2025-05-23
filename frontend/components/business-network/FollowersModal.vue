<template>
  <div 
    class="fixed inset-0 z-50 overflow-auto bg-black/60 flex justify-center items-center p-4" 
    v-if="show"
    role="dialog"
    aria-modal="true"
    aria-labelledby="modal-title"
    @keydown.esc="closeModal"
    tabindex="-1"
    ref="modalRef"
  >
    <div class="bg-white dark:bg-slate-800 rounded-md shadow-md w-full max-w-xl flex flex-col border border-gray-200 dark:border-slate-700 overflow-hidden" style="max-height: 85vh; height: auto;">
      <!-- Header -->
      <div class="px-6 py-4 border-b border-gray-200 dark:border-slate-700 flex items-center justify-between">        
        <div class="flex items-center">
          <h3 id="modal-title" class="text-lg font-semibold text-gray-900 dark:text-white flex items-center">
            {{ activeTab === 'followers' ? 'Followers' : 'Following' }}
            <span class="ml-2 px-2 py-0.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 text-xs font-medium rounded">
              {{ totalCount }}
            </span>
          </h3>
        </div>        
        <button 
          @click="closeModal" 
          class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 p-1 rounded"
          aria-label="Close modal"
          ref="closeButtonRef"
        >
          <UIcon name="i-heroicons-x-mark" class="w-5 h-5" aria-hidden="true" />
        </button>
      </div>
      <!-- Tabs -->
      <div class="flex border-b border-gray-200 dark:border-slate-700 bg-gray-50 dark:bg-slate-800/80" role="tablist">
        <button 
          @click="activeTab = 'followers'" 
          class="flex-1 py-3 px-4 text-center"
          :class="activeTab === 'followers' ? 'text-blue-600 dark:text-blue-400 font-medium border-b-2 border-blue-500' : 'text-gray-500 dark:text-gray-400'"
          role="tab"
          :aria-selected="activeTab === 'followers'"
          id="followers-tab"
          aria-controls="followers-panel"
        >
          <span>Followers</span>
        </button>        
        <button 
          @click="activeTab = 'following'" 
          class="flex-1 py-3 px-4 text-center"
          :class="activeTab === 'following' ? 'text-blue-600 dark:text-blue-400 font-medium border-b-2 border-blue-500' : 'text-gray-500 dark:text-gray-400'"
          role="tab"
          :aria-selected="activeTab === 'following'"
          id="following-tab"
          aria-controls="following-panel"
        >
          <span>Following</span>
        </button>
      </div>      
      <!-- Search Input -->
      <div class="px-6 py-3 border-b border-gray-100 dark:border-slate-700/50">
        <div class="relative">
          <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <UIcon name="i-heroicons-magnifying-glass" class="w-4 h-4 text-gray-400" aria-hidden="true" />
          </div>
          <input
            type="text"
            class="bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 text-gray-900 dark:text-white text-sm rounded-lg block w-full pl-10 p-2.5"
            placeholder="Search by name or username"
            v-model="searchTerm"
            aria-label="Search users"
          />
        </div>
      </div>      
      <!-- Loading Skeleton -->
      <div v-if="isLoading" class="overflow-y-auto flex-1 px-6 py-3">
        <p class="sr-only" role="status">Loading users, please wait...</p>
        <div v-for="i in 5" :key="`skeleton-${i}`" class="flex items-center py-3 border-b border-gray-100 dark:border-slate-700/50 last:border-0">
          <div class="w-12 h-12 rounded-full bg-gray-200 dark:bg-slate-600 overflow-hidden">
            <!-- Simple skeleton circle -->
          </div>
          <div class="ml-3 flex-1">
            <div class="h-4 bg-gray-200 dark:bg-slate-600 rounded w-1/3 mb-2">
            </div>
            <div class="h-3 bg-gray-200 dark:bg-slate-600 rounded w-1/4">
            </div>
          </div>
          <div class="w-24 h-8 bg-gray-200 dark:bg-slate-600 rounded-md">
          </div>
        </div>
      </div>    
      <!-- User List -->
      <div v-else class="overflow-y-auto flex-1 px-4 py-2" style="min-height: 200px; max-height: 60vh;" 
        :role="activeTab === 'followers' ? 'tabpanel' : 'tabpanel'" 
        :id="activeTab === 'followers' ? 'followers-panel' : 'following-panel'" 
        :aria-labelledby="activeTab === 'followers' ? 'followers-tab' : 'following-tab'"
        aria-live="polite"
      ><div v-if="filteredUsers.length === 0" class="flex flex-col items-center justify-center py-10 text-center">
          <p class="sr-only" role="status">{{ activeTab === 'followers' ? 'No followers found' : 'Not following anyone' }}</p>
          <div class="w-16 h-16 rounded-full bg-gray-100 dark:bg-slate-700 flex items-center justify-center mb-4">
            <UIcon name="i-heroicons-user-group" class="w-8 h-8 text-gray-300 dark:text-gray-600" aria-hidden="true" />
          </div>
          <h3 class="text-lg font-medium text-gray-700 dark:text-gray-300 mb-1">
            {{ activeTab === 'followers' ? 'No followers found' : 'Not following anyone' }}
          </h3>
          <p v-if="searchTerm" class="text-sm text-gray-500 dark:text-gray-400 mb-4">
            Try a different search term
          </p>
        </div>
        <div v-else>          
          <div v-for="user in filteredUsers" :key="user.id" class="flex items-center py-3 border-b border-gray-100 dark:border-slate-700/50 last:border-0 px-2">
            <!-- Clickable area that navigates to profile (wraps image and text) -->
            <div class="flex items-center flex-1 cursor-pointer" @click="navigateToProfile(user)">
              <div class="flex-shrink-0">                
              <div class="w-12 h-12 rounded-full overflow-hidden border border-gray-200 dark:border-slate-700 bg-gray-50 dark:bg-slate-800">
                  <!-- Show user icon when no image is available -->
                  <div v-if="!user.profile_image" class="w-full h-full flex items-center justify-center">
                    <UIcon name="i-heroicons-user" class="w-7 h-7 text-gray-400" />
                  </div>
                  <!-- Display the image when available -->
                  <img 
                    v-else
                    :src="formatImageUrl(user.profile_image)" 
                    :alt="user.full_name || user.username"
                    class="w-full h-full object-cover"
                    loading="lazy"
                    @error="handleImageError"
                    referrerpolicy="no-referrer"
                    aria-hidden="false"
                  />
                </div>
              </div>              
              <div class="ml-3 flex-1 min-w-0">                
                <div class="text-sm font-medium text-gray-900 dark:text-white truncate block">
                  {{ user.full_name || user.username }}
                  <UIcon 
                    v-if="user.kyc" 
                    name="i-mdi-check-decagram" 
                    class="inline-block w-4 h-4 text-blue-600 dark:text-blue-400 ml-1"
                    aria-label="Verified user"
                    role="img"
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
                  'text-sm font-medium px-3 py-1 rounded-md min-w-[90px] text-center',
                  user.is_following
                    ? 'border border-gray-200 dark:border-slate-600 text-gray-700 dark:text-white'
                    : 'bg-blue-500 text-white'
                ]"
                @click.stop="toggleFollow(user)"
                :disabled="user.isFollowLoading"
                aria-label="Toggle follow status"
              >
                <span class="flex items-center justify-center gap-1">
                  <!-- Loading indicator - fixed width to prevent layout shift -->
                  <div v-if="user.isFollowLoading" class="h-3 w-3 border-2 border-t-transparent border-current rounded-full">
                  </div>
                  <!-- Text for button -->
                  <span>{{ user.isFollowLoading ? 'Loading...' : (user.is_following ? 'Following' : 'Follow') }}
                  </span>
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>        
      <!-- Load More -->
      <div v-if="hasMoreUsers && !isLoading && filteredUsers.length > 0" class="px-6 py-3 border-t border-gray-100 dark:border-slate-700 flex justify-center bg-gray-50 dark:bg-slate-800/80">
        <button 
          @click="loadMoreUsers" 
          class="text-blue-600 dark:text-blue-400 text-sm font-medium px-4 py-2 bg-white dark:bg-slate-700 rounded-md border border-gray-200 dark:border-slate-600 min-w-[100px] text-center"
          :disabled="loadingMore"
          aria-label="Load more users"
        >
          <span v-if="loadingMore">Loading...</span>
          <span v-else>Load More</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue';
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

// Refs for focus management
const modalRef = ref(null);
const closeButtonRef = ref(null);
const previousFocus = ref(null);

// Focus management
onMounted(() => {
  // Store the element that had focus before opening the modal
  if (typeof document !== 'undefined') {
    previousFocus.value = document.activeElement;
  }
});

watch(() => props.show, (isVisible) => {
  if (isVisible) {
    // Focus the modal when it opens
    nextTick(() => {
      if (modalRef.value) {
        modalRef.value.focus();
      }
    });
  } else if (previousFocus.value) {
    // Return focus to the previously focused element when modal closes
    nextTick(() => {
      previousFocus.value.focus();
    });
  }
});

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

// Updated fetchUsers function with better profile image debugging
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
        }        // Determine the best profile image to use
        let profileImage = null;
        if (userDetails.profile_image) {
          profileImage = userDetails.profile_image;
        } else if (userDetails.avatar) {
          profileImage = userDetails.avatar;
        } else if (userDetails.image) {
          profileImage = userDetails.image;
        }
        
        console.log(`User ${userDetails.username}: Using profile image: ${profileImage}`);
          
        // Create a unified user object with consistent properties
        return {
          id: userDetails.id,
          username: userDetails.username,
          full_name: userDetails.first_name && userDetails.last_name 
            ? `${userDetails.first_name} ${userDetails.last_name}` 
            : userDetails.name || userDetails.username,
          profile_image: profileImage,
          profession: userDetails.profession || userDetails.title,
          is_following: !!item.is_following,
          kyc: userDetails.kyc,
          isFollowLoading: false // Initialize loading state for each user
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
    console.error(`Error fetching ${activeTab.value}:`, error);
  } finally {
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
  
  // Prevent multiple clicks if already processing
  if (user.isFollowLoading) return;
  
  try {
    // Set loading state
    user.isFollowLoading = true;
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
  } finally {
    // Always clear the loading state
    user.isFollowLoading = false;
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
  if (event && event.target) {
    const originalSrc = event.target.src;
    console.log(`Image failed to load: ${originalSrc}`);
    
    // Check if this is already a fallback image to prevent infinite loops
    if (event.target.classList.contains('fallback-image')) {
      console.log('Already using fallback image, not replacing again');
      return;
    }
    
    // Try to use a robust placeholder path
    const placeholderPath = '/static/frontend/images/placeholder.jpg';
    
    // Set a direct path to the placeholder image
    event.target.src = placeholderPath;
    
    // Add a class to indicate it's a fallback image
    event.target.classList.add('fallback-image');
    
    // Log the error for debugging
    console.log(`Image loading error handled, replaced ${originalSrc} with ${placeholderPath}`);
    
    // Prevent further error loops
    event.target.onerror = null;
  }
}

// Format image URL to ensure proper display
function formatImageUrl(url) {
  if (!url || typeof url !== 'string') return '';
  
  // Clean the URL first
  let formattedUrl = url.trim();
  
  // Handle protocol-relative URLs
  if (formattedUrl.startsWith('//')) {
    formattedUrl = 'https:' + formattedUrl;
  }
  // Handle relative URLs
  else if (!formattedUrl.startsWith('http') && !formattedUrl.startsWith('/')) {
    formattedUrl = '/' + formattedUrl;
  }
  
  // Fix double slashes in paths (but not in protocol)
  if (formattedUrl.includes('//') && !formattedUrl.startsWith('http')) {
    formattedUrl = formattedUrl.replace(/([^:])\/\//g, '$1/');
  }
  
  // Add timestamp to bypass cache
  const timestamp = Date.now();
  return formattedUrl.includes('?') ? 
    `${formattedUrl}&t=${timestamp}` : 
    `${formattedUrl}?t=${timestamp}`;
}

// Close the modal
function closeModal() {
  emit('close');
}
</script>

<style scoped>
/* Basic styling for scrollbars */
.overflow-y-auto::-webkit-scrollbar {
  width: 6px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.03);
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.1);
}

/* Fallback image styling */
.fallback-image {
  object-fit: cover;
  background-color: #f3f4f6;
}

/* Focus styling for better keyboard navigation */
:focus-visible {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}

/* Make sure the modal is keyboard navigable */
[role="dialog"] {
  outline: none;
}
</style>