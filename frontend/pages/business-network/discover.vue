<template>
  <div class="mx-auto px-4 sm:px-6 lg:px-8 max-w-4xl mt-6">
    <!-- Header -->
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900 mb-2">Discover People</h1>
      <p class="text-gray-600">Find and connect with interesting people in the business network</p>
    </div>

    <!-- Search Bar -->
    <div class="mb-6">
      <div class="relative">
        <Search class="absolute left-3 top-3 h-5 w-5 text-gray-400" />
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search people by name or username..."
          class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          @input="handleSearch"
        />
      </div>
    </div>

    <!-- Filter Tabs -->
    <div class="mb-6">
      <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8">
          <button
            v-for="filter in filterOptions"
            :key="filter.key"
            @click="activeFilter = filter.key"
            :class="[
              'whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm',
              activeFilter === filter.key
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
          >
            {{ filter.label }}
          </button>
        </nav>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <div v-for="i in 9" :key="i" class="bg-white rounded-lg border border-gray-200 p-4">
        <div class="flex items-center space-x-3 mb-3">
          <div class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"></div>
          <div class="flex-1 space-y-2">
            <div class="h-4 bg-gray-200 rounded animate-pulse w-3/4"></div>
            <div class="h-3 bg-gray-200 rounded animate-pulse w-1/2"></div>
          </div>
        </div>
        <div class="h-8 bg-gray-200 rounded animate-pulse"></div>
      </div>
    </div>

    <!-- User Grid -->
    <div v-else-if="users.length > 0" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <div
        v-for="user in users"
        :key="user.id"
        class="bg-white rounded-lg border border-gray-200 hover:shadow-md transition-shadow p-4"
      >
        <!-- User Info -->
        <div class="flex items-center space-x-3 mb-3">
          <NuxtLink :to="`/business-network/profile/${user.id}`">
            <img
              :src="user.image || '/static/frontend/images/placeholder.jpg'"
              :alt="getUserDisplayName(user)"
              class="w-12 h-12 rounded-full object-cover border-2 border-white shadow-sm"
            />
          </NuxtLink>
          <div class="flex-1 min-w-0">
            <NuxtLink 
              :to="`/business-network/profile/${user.id}`"
              class="block"
            >
              <h3 class="font-semibold text-gray-900 truncate hover:text-blue-600 transition-colors">
                {{ getUserDisplayName(user) }}
              </h3>
            </NuxtLink>
            <p v-if="user.username" class="text-sm text-gray-600 truncate">@{{ user.username }}</p>
          </div>
        </div>

        <!-- Stats -->
        <div class="flex justify-between text-sm text-gray-600 mb-3">
          <span class="flex items-center">
            <FileText class="h-4 w-4 mr-1" />
            {{ user.post_count || 0 }} posts
          </span>
          <span class="flex items-center">
            <Users class="h-4 w-4 mr-1" />
            {{ formatFollowerCount(user.follower_count || 0) }} followers
          </span>
        </div>

        <!-- Mutual connections -->
        <div v-if="user.mutual_connections > 0" class="text-xs text-blue-600 mb-3">
          {{ user.mutual_connections }} mutual connection{{ user.mutual_connections > 1 ? 's' : '' }}
        </div>

        <!-- Follow Button -->
        <button
          @click="toggleFollow(user)"
          :disabled="user.isFollowing === 'pending'"
          class="w-full px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          :class="getFollowButtonClass(user)"
        >
          <span v-if="user.isFollowing === 'pending'" class="flex items-center justify-center">
            <Loader2 class="h-4 w-4 animate-spin mr-1" />
            Loading...
          </span>
          <span v-else-if="user.isFollowing" class="flex items-center justify-center">
            <UserCheck class="h-4 w-4 mr-1" />
            Following
          </span>
          <span v-else class="flex items-center justify-center">
            <UserPlus class="h-4 w-4 mr-1" />
            Follow
          </span>
        </button>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!loading" class="text-center py-12">
      <Users class="h-16 w-16 text-gray-300 mx-auto mb-4" />
      <h3 class="text-lg font-medium text-gray-900 mb-2">No users found</h3>
      <p class="text-gray-600">
        {{ searchQuery ? 'Try adjusting your search terms' : 'No users match the current filter' }}
      </p>
    </div>

    <!-- Pagination -->
    <div v-if="pagination.total > pagination.pageSize" class="mt-8 flex justify-center">
      <nav class="flex items-center space-x-2">
        <button
          @click="changePage(pagination.currentPage - 1)"
          :disabled="pagination.currentPage <= 1"
          class="px-3 py-2 text-sm text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Previous
        </button>
        
        <span class="px-3 py-2 text-sm text-gray-700">
          Page {{ pagination.currentPage }} of {{ Math.ceil(pagination.total / pagination.pageSize) }}
        </span>
        
        <button
          @click="changePage(pagination.currentPage + 1)"
          :disabled="pagination.currentPage >= Math.ceil(pagination.total / pagination.pageSize)"
          class="px-3 py-2 text-sm text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Next
        </button>
      </nav>
    </div>
  </div>
</template>

<script setup>
import { Search, Users, UserPlus, UserCheck, Loader2, FileText } from 'lucide-vue-next'

// Meta
definePageMeta({
  layout: 'adsy-business-network',
  middleware: 'auth'
})

// Get API utilities
const { get, post: apiPost } = useApi()
const { user: currentUser } = useAuth()
const toast = useToast()

// Reactive data
const users = ref([])
const loading = ref(true)
const searchQuery = ref('')
const activeFilter = ref('suggestions')
const searchTimeout = ref(null)

const pagination = ref({
  currentPage: 1,
  pageSize: 12,
  total: 0
})

const filterOptions = [
  { key: 'suggestions', label: 'Suggested for you' },
  { key: 'active', label: 'Most active' },
  { key: 'popular', label: 'Most followed' },
  { key: 'recent', label: 'Recently joined' }
]

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

// Fetch users
const fetchUsers = async (page = 1) => {
  try {
    loading.value = true
    
    let endpoint = '/bn/user-suggestions/'
    const params = {
      page,
      page_size: pagination.value.pageSize
    }
    
    // Adjust endpoint based on filter
    if (activeFilter.value !== 'suggestions') {
      endpoint = '/bn/user-search/'
      params.filter = activeFilter.value
    }
    
    // Add search query if exists
    if (searchQuery.value.trim()) {
      params.q = searchQuery.value.trim()
      endpoint = '/bn/user-search/'
    }
    
    const response = await get(endpoint, { params })
    
    if (response?.data) {
      // Handle both paginated and non-paginated responses
      if (response.data.results) {
        users.value = response.data.results.map(user => ({
          ...user,
          isFollowing: false,
          mutual_connections: user.mutual_connections || 0
        }))
        pagination.value.total = response.data.count || 0
      } else {
        users.value = response.data.map(user => ({
          ...user,
          isFollowing: false,
          mutual_connections: user.mutual_connections || 0
        }))
        pagination.value.total = response.data.length || 0
      }
    } else {
      users.value = []
      pagination.value.total = 0
    }
  } catch (err) {
    console.error('Error fetching users:', err)
    users.value = []
    pagination.value.total = 0
  } finally {
    loading.value = false
  }
}

// Handle search input
const handleSearch = () => {
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value)
  }
  
  searchTimeout.value = setTimeout(() => {
    pagination.value.currentPage = 1
    fetchUsers(1)
  }, 500)
}

// Change page
const changePage = (page) => {
  if (page >= 1 && page <= Math.ceil(pagination.value.total / pagination.value.pageSize)) {
    pagination.value.currentPage = page
    fetchUsers(page)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

// Toggle follow status
const toggleFollow = async (user) => {
  if (!currentUser?.value?.user?.id || user.isFollowing === 'pending') return
  
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
    } else {
      throw new Error('Failed to update follow status')
    }
  } catch (err) {
    console.error('Error toggling follow:', err)
    user.isFollowing = originalState
    
    toast?.add?.({
      title: 'Error',
      description: 'Failed to update follow status',
      color: 'red'
    })
  }
}

// Watch for filter changes
watch(activeFilter, () => {
  pagination.value.currentPage = 1
  fetchUsers(1)
})

// Initial load
onMounted(() => {
  fetchUsers()
})
</script>
