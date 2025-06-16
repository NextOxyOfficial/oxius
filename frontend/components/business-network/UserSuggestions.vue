<template>
  <div class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-6 shadow-sm">
    <!-- Header -->
    <div class="px-4 py-3 border-b border-gray-100 bg-gradient-to-r from-blue-50 to-indigo-50">
      <div class="flex items-center">
        <Users class="h-5 w-5 text-blue-600 mr-2" />
        <h3 class="text-sm font-semibold text-gray-800">Follow the people you may know</h3>
      </div>
    </div>

    <!-- User Suggestions -->
    <div class="p-4">      
        <div v-if="loading" class="space-y-4">
        <!-- Skeleton loaders -->
        <div v-for="i in (isDesktop ? 3 : 2)" :key="i" class="flex items-center space-x-3">
          <div class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"></div>
          <div class="flex-1 space-y-2">
            <div class="h-4 bg-gray-200 rounded animate-pulse w-3/4"></div>
            <div class="h-3 bg-gray-200 rounded animate-pulse w-1/2"></div>
          </div>
          <div class="h-8 bg-gray-200 rounded animate-pulse w-16"></div>
        </div>
      </div><div v-else-if="displayedSuggestions.length > 0" class="space-y-4">
        <div 
          v-for="user in displayedSuggestions" 
          :key="user.id"
          class="flex items-center justify-between hover:bg-gray-50 rounded-lg p-2 transition-colors"
        >
          <!-- User Info -->
          <div class="flex items-center space-x-3 flex-1">
            <!-- Profile Picture -->
            <NuxtLink :to="`/business-network/profile/${user.id}`">
              <img
                :src="user.image || '/static/frontend/images/placeholder.jpg'"
                :alt="getUserDisplayName(user)"
                class="w-12 h-12 rounded-full object-cover border-2 border-white shadow-sm hover:shadow-md transition-shadow"
              />
            </NuxtLink>
            
            <!-- User Details -->
            <div class="flex-1 min-w-0">
              <NuxtLink 
                :to="`/business-network/profile/${user.id}`"
                class="block"
              >
                <h4 class="font-semibold text-gray-900 truncate hover:text-blue-600 transition-colors">
                  {{ getUserDisplayName(user) }}
                </h4>
              </NuxtLink>
              <div class="flex items-center space-x-3 text-sm text-gray-600">
                <span v-if="user.username" class="truncate">@{{ user.username }}</span>
                <span class="flex items-center">
                  <Users class="h-3 w-3 mr-1" />
                  {{ formatFollowerCount(user.follower_count || 0) }} followers
                </span>
              </div>
              <!-- Mutual connections -->
              <div v-if="user.mutual_connections > 0" class="text-xs text-blue-600 mt-1">
                {{ user.mutual_connections }} mutual connection{{ user.mutual_connections > 1 ? 's' : '' }}
              </div>
            </div>
          </div>

          <!-- Follow Button -->
          <button
            @click="toggleFollow(user)"
            :disabled="user.isFollowing === 'pending'"
            class="px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            :class="getFollowButtonClass(user)"
          >
            <span v-if="user.isFollowing === 'pending'" class="flex items-center">
              <Loader2 class="h-4 w-4 animate-spin mr-1" />
              Loading...
            </span>
            <span v-else-if="user.isFollowing" class="flex items-center">
              <UserCheck class="h-4 w-4 mr-1" />
              Following
            </span>
            <span v-else class="flex items-center">
              <UserPlus class="h-4 w-4 mr-1" />
              Follow
            </span>
          </button>
        </div>
      </div>

      <!-- Empty state -->
      <div v-else-if="!loading" class="text-center py-6">
        <Users class="h-12 w-12 text-gray-300 mx-auto mb-2" />
        <p class="text-gray-500 text-sm">No suggestions available right now</p>
      </div>
    </div>    <!-- View All Link -->
    <div v-if="displayedSuggestions.length > 0" class="px-4 py-3 border-t border-gray-100 bg-gray-50">
      <NuxtLink 
        to="/business-network/discover"
        class="text-sm text-blue-600 hover:text-blue-800 font-medium transition-colors"
      >
        View all suggestions →
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
import { Users, UserPlus, UserCheck, Loader2 } from 'lucide-vue-next'

const props = defineProps({
  currentUserId: {
    type: [String, Number],
    default: null
  }
})

// Get API utilities
const { get, post: apiPost } = useApi()
const toast = useToast()

// Reactive data
const suggestions = ref([])
const loading = ref(true)
const error = ref(null)

// Responsive display logic
const isDesktop = ref(true)
const displayedSuggestions = computed(() => {
  const maxUsers = isDesktop.value ? 3 : 2
  return suggestions.value.slice(0, maxUsers)
})

// Check screen size
const checkScreenSize = () => {
  if (process.client) {
    isDesktop.value = window.innerWidth >= 768 // md breakpoint
  }
}

// Listen for window resize
onMounted(() => {
  checkScreenSize()
  if (process.client) {
    window.addEventListener('resize', checkScreenSize)
  }
})

onUnmounted(() => {
  if (process.client) {
    window.removeEventListener('resize', checkScreenSize)
  }
})

// Get user display name
const getUserDisplayName = (user) => {
  if (user.first_name && user.last_name) {
    return `${user.first_name} ${user.last_name}`
  }
  return user.username || 'Unknown User'
}

// Format follower count
const formatFollowerCount = (count) => {
  if (count >= 1000000) {
    return `${(count / 1000000).toFixed(1)}M`
  } else if (count >= 1000) {
    return `${(count / 1000).toFixed(1)}K`
  }
  return count.toString()
}

// Get follow button styling
const getFollowButtonClass = (user) => {
  if (user.isFollowing === 'pending') {
    return 'bg-gray-100 text-gray-600 cursor-not-allowed'
  } else if (user.isFollowing) {
    return 'bg-green-100 text-green-700 hover:bg-green-200 border border-green-200'
  } else {
    return 'bg-blue-600 text-white hover:bg-blue-700 active:bg-blue-800'
  }
}

// Fetch user suggestions
const fetchSuggestions = async () => {
  try {
    loading.value = true
    error.value = null
    
    const { get } = useApi()
    const response = await get('/bn/user-suggestions/')
    
    if (response?.data) {
      suggestions.value = response.data?.map(user => ({
        ...user,
        isFollowing: false,
        mutual_connections: user.mutual_connections || 0
      })) || []
    } else {
      suggestions.value = []
    }
  } catch (err) {
    console.error('Error fetching user suggestions:', err)
    error.value = 'Failed to load suggestions'
    suggestions.value = []
  } finally {
    loading.value = false
  }
}

// Toggle follow status
const toggleFollow = async (user) => {
  if (!props.currentUserId || user.isFollowing === 'pending') return
  
  const originalState = user.isFollowing
  
  try {
    user.isFollowing = 'pending'
    
    const endpoint = originalState 
      ? `/bn/users/${user.id}/unfollow/`
      : `/bn/users/${user.id}/follow/`
    
    const response = await apiPost(endpoint, {})
    
    if (response) {
      user.isFollowing = !originalState
      
      // Update follower count
      if (user.isFollowing) {
        user.follower_count = (user.follower_count || 0) + 1
      } else {
        user.follower_count = Math.max((user.follower_count || 0) - 1, 0)
      }
        // Remove from suggestions if followed (optional)
      if (user.isFollowing) {
        const index = suggestions.value.findIndex(s => s.id === user.id)
        if (index > -1) {
          suggestions.value.splice(index, 1)
          // Refresh suggestions if we have fewer than required
          if (displayedSuggestions.value.length < (isDesktop.value ? 3 : 2) && suggestions.value.length === 0) {
            setTimeout(() => fetchSuggestions(), 1000) // Refresh after 1 second
          }
        }
      }
    } else {
      throw new Error('Failed to update follow status')
    }
  } catch (err) {
    console.error('Error toggling follow:', err)
    user.isFollowing = originalState // Revert on error
    
    // Show error message
    toast?.add?.({
      title: 'Error',
      description: 'Failed to update follow status',
      color: 'red'
    })
  }
}

// Lifecycle
onMounted(() => {
  fetchSuggestions()
})

// Expose methods for parent component
defineExpose({
  refreshSuggestions: fetchSuggestions
})
</script>

<style scoped>
/* Add any additional custom styles here */
.transition-all {
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}
</style>
