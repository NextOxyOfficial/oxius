<template>
  <div class="my-posts-container">
    <!-- Top Header Section with Stats - More Compact -->
    <div class="mb-3 bg-white rounded-lg shadow-md overflow-hidden">
      <div class="bg-gradient-to-r from-primary to-primary/80 p-3 text-white">
        <h2 class="text-lg font-bold">My Listings</h2>
        <p class="text-white/80 text-xs">Manage your sale posts and track their performance</p>
      </div>
      
      <!-- Stats Cards - Smaller and More Compact -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-2 p-2">
        <div class="stat-card bg-white border border-gray-100 rounded-lg p-2 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-500 text-xs">Total Listings</p>
              <p class="text-lg font-bold text-gray-800">{{ allPosts.length }}</p>
            </div>
            <div class="rounded-full bg-primary/10 p-1.5">
              <Icon name="heroicons:document-text" class="h-4 w-4 text-primary" />
            </div>
          </div>
        </div>
        
        <div class="stat-card bg-white border border-gray-100 rounded-lg p-2 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-500 text-xs">Active</p>
              <p class="text-lg font-bold text-green-600">{{ activePosts }}</p>
            </div>
            <div class="rounded-full bg-green-100 p-1.5">
              <Icon name="heroicons:check-circle" class="h-4 w-4 text-green-600" />
            </div>
          </div>
        </div>
        
        <div class="stat-card bg-white border border-gray-100 rounded-lg p-2 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-500 text-xs">Pending</p>
              <p class="text-lg font-bold text-yellow-600">{{ pendingPosts }}</p>
            </div>
            <div class="rounded-full bg-yellow-100 p-1.5">
              <Icon name="heroicons:clock" class="h-4 w-4 text-yellow-600" />
            </div>
          </div>
        </div>
        
        <div class="stat-card bg-white border border-gray-100 rounded-lg p-2 shadow-sm hover:shadow-md transition-shadow">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-500 text-xs">Sold</p>
              <p class="text-lg font-bold text-blue-600">{{ soldPosts }}</p>
            </div>
            <div class="rounded-full bg-blue-100 p-1.5">
              <Icon name="heroicons:banknotes" class="h-4 w-4 text-blue-600" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-lg shadow-md overflow-hidden">
      <!-- Search and Filter Controls - More Compact -->
      <div class="p-3 border-b border-gray-100">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <!-- Search Input -->
          <div class="relative flex-grow max-w-md">
            <input 
              type="text"
              v-model="searchQuery"
              placeholder="Search your listings..."
              class="w-full border border-gray-300 rounded-lg pl-8 pr-3 py-1.5 focus:ring-primary focus:border-primary text-sm"
            >
            <div class="absolute inset-y-0 left-0 pl-2 flex items-center pointer-events-none">
              <Icon name="heroicons:magnifying-glass" class="text-gray-400" size="14px" />
            </div>
          </div>
          
          <div class="flex items-center gap-2">
            <!-- Sort Dropdown -->
            <div class="relative">
              <select 
                v-model="sortOption"
                class="appearance-none border border-gray-300 rounded-lg pl-2 pr-7 py-1.5 bg-white focus:ring-primary focus:border-primary text-xs"
              >
                <option value="newest">Newest First</option>
                <option value="oldest">Oldest First</option>
                <option value="price_high">Price: High to Low</option>
                <option value="price_low">Price: Low to High</option>
              </select>
              <div class="absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none">
                <Icon name="heroicons:chevron-down" class="text-gray-400" size="12px" />
              </div>
            </div>
            
            <!-- Create New Post Button -->
            <button 
              @click="$emit('create-post')"
              class="flex-shrink-0 bg-primary text-white px-3 py-1.5 rounded-lg hover:bg-primary/90 transition-colors text-xs flex items-center gap-1"
            >
              <Icon name="heroicons:plus" size="12px" />
              <span>New Listing</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Custom Tabs - More Compact -->
      <div class="px-3 pt-1 bg-gray-50">
        <div class="flex flex-wrap overflow-x-auto hide-scrollbar">
          <button 
            v-for="(tab, index) in tabs" 
            :key="index"
            :class="[
              'mr-1 px-3 py-2 border-b-2 text-xs font-medium transition-all',
              activeTab === tab.id 
                ? 'border-primary text-primary bg-white rounded-t-lg' 
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
            @click="activeTab = tab.id"
          >
            {{ tab.name }}
            <span 
              :class="[
                'ml-1 px-1.5 py-0.5 rounded-full text-xs',
                activeTab === tab.id 
                  ? 'bg-primary/10 text-primary' 
                  : 'bg-gray-100 text-gray-600'
              ]"
            >
              {{ tab.count }}
            </span>
          </button>
        </div>
      </div>

      <!-- Loading State - More Compact -->
      <div v-if="isLoading" class="py-6 text-center bg-white">
        <div class="inline-flex flex-col items-center">
          <div class="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary mb-2"></div>
          <p class="text-gray-600 text-xs">Loading your listings...</p>
        </div>
      </div>

      <!-- Empty State - More Compact -->
      <div v-else-if="!filteredPosts.length" class="py-8 text-center bg-white">
        <div class="inline-flex flex-col items-center">
          <div class="bg-gray-100 rounded-full p-3 mb-3">
            <Icon name="heroicons:document-plus" size="32px" class="text-gray-400" />
          </div>
          <h3 class="text-sm font-medium text-gray-800 mb-1">No listings found</h3>
          <p class="text-gray-500 mb-4 max-w-md mx-auto text-xs">
            {{ 
              searchQuery 
                ? "No listings match your search criteria. Try a different search term." 
                : "You don't have any listings in this category yet. Create your first listing now!"
            }}
          </p>
          <button 
            class="bg-primary text-white px-3 py-1.5 rounded-lg hover:bg-primary/90 transition-colors text-xs flex items-center gap-1"
            @click="$emit('create-post')"
          >
            <Icon name="heroicons:plus-circle" size="14px" />
            Create a Listing
          </button>
        </div>
      </div>

      <!-- Posts List View - Compact List Design -->
      <div v-else class="bg-white">
        <div class="space-y-1 p-2">
          <div 
            v-for="post in filteredPosts" 
            :key="post.id"
            class="border border-gray-200 rounded-lg overflow-hidden hover:bg-gray-50 transition-colors"
          >
            <div class="flex p-2">
              <!-- Post Image (Smaller) -->
              <div class="h-16 w-16 flex-shrink-0">
                <img 
                  :src="post.imageUrl" 
                  :alt="post.title" 
                  class="h-16 w-16 object-cover rounded"
                />
              </div>
              
              <!-- Post Details -->
              <div class="ml-3 flex-grow flex flex-col">
                <div class="flex justify-between items-start">
                  <h3 class="text-sm font-medium text-gray-900 line-clamp-1">{{ post.title }}</h3>
                  <div 
                    :class="[
                      'px-1.5 py-0.5 text-xs font-medium rounded-full text-xs',
                      getStatusClass(post.status)
                    ]"
                  >
                    {{ post.status }}
                  </div>
                </div>
                
                <p class="mt-0.5 text-primary font-medium text-xs">৳{{ post.price.toLocaleString() }}</p>
                <p class="mt-0.5 text-gray-600 line-clamp-1 text-xs">{{ post.description }}</p>
                
                <div class="mt-1 flex justify-between items-center">
                  <div class="flex items-center text-xs text-gray-500">
                    <Icon name="heroicons:calendar" class="mr-1 text-gray-400" size="10px" />
                    <span>{{ formatDate(post.postedDate) }}</span>
                  </div>
                  
                  <div class="flex space-x-1">
                    <button 
                      @click="editPost(post)"
                      class="text-primary hover:text-primary/80 p-1"
                      title="Edit"
                    >
                      <Icon name="heroicons:pencil-square" size="14px" />
                    </button>
                    <button 
                      @click="updateStatus(post)"
                      class="text-blue-500 hover:text-blue-700 p-1"
                      title="Change Status"
                    >
                      <Icon name="heroicons:arrow-path" size="14px" />
                    </button>
                    <button 
                      @click="confirmDelete(post)"
                      class="text-red-500 hover:text-red-700 p-1"
                      title="Delete"
                    >
                      <Icon name="heroicons:trash" size="14px" />
                    </button>
                  </div>
                </div>
                
                <div v-if="post.featured" class="absolute top-2 left-2">
                  <span class="bg-yellow-400 text-yellow-900 px-1.5 py-0.5 text-xxs rounded-full shadow-sm">
                    Featured
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Pagination - More Compact -->
      <div v-if="totalPages > 1" class="p-2 bg-gray-50 border-t border-gray-100 flex justify-center">
        <nav class="flex items-center space-x-1">
          <button 
            class="px-2 py-1 rounded-md border border-gray-300 text-gray-600 hover:bg-gray-50 disabled:opacity-50 text-xs"
            :disabled="currentPage === 1"
            @click="currentPage = Math.max(1, currentPage - 1)"
          >
            <Icon name="heroicons:chevron-left" size="12px" />
          </button>
          
          <div v-for="page in paginationPages" :key="page" class="hidden md:block">
            <button 
              v-if="page !== '...'"
              :class="[
                'px-2 py-1 rounded-md text-xs',
                currentPage === page
                  ? 'bg-primary text-white'
                  : 'border border-gray-300 text-gray-600 hover:bg-gray-50'
              ]"
              @click="currentPage = page"
            >
              {{ page }}
            </button>
            <span v-else class="px-1 py-1 text-gray-500 text-xs">...</span>
          </div>
          
          <div class="md:hidden px-2 py-1 text-gray-600 text-xs">
            {{ currentPage }} / {{ totalPages }}
          </div>
          
          <button 
            class="px-2 py-1 rounded-md border border-gray-300 text-gray-600 hover:bg-gray-50 disabled:opacity-50 text-xs"
            :disabled="currentPage === totalPages"
            @click="currentPage = Math.min(totalPages, currentPage + 1)"
          >
            <Icon name="heroicons:chevron-right" size="12px" />
          </button>
        </nav>
      </div>
    </div>

    <!-- Status Update Modal - More Compact -->
    <div v-if="showStatusModal" class="fixed inset-0 z-50 overflow-y-auto">
      <div class="flex items-center justify-center min-h-screen p-3">
        <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="showStatusModal = false"></div>
        
        <div class="bg-white rounded-lg shadow-lg w-full max-w-sm mx-auto z-10 overflow-hidden">
          <div class="p-3 border-b border-gray-200">
            <h3 class="text-sm font-medium text-gray-900">Change Status</h3>
          </div>
          <div class="p-3 space-y-3">
            <p class="text-gray-600 text-xs">Select the new status for "<span class="font-medium">{{ selectedPost?.title }}</span>"</p>
            
            <div class="space-y-1">
              <label 
                v-for="status in availableStatuses" 
                :key="status.value"
                class="flex items-center p-2 border rounded-lg cursor-pointer transition-colors"
                :class="newStatus === status.value ? 'border-primary bg-primary/5' : 'border-gray-200 hover:bg-gray-50'"
              >
                <input 
                  type="radio" 
                  :value="status.value" 
                  v-model="newStatus" 
                  class="hidden" 
                />
                <div :class="`rounded-full p-1.5 ${status.bgColor} mr-2`">
                  <Icon :name="status.icon" class="h-3 w-3" :class="status.iconColor" />
                </div>
                <div>
                  <div class="font-medium text-xs">{{ status.label }}</div>
                  <div class="text-xxs text-gray-500">{{ status.description }}</div>
                </div>
              </label>
            </div>
          </div>
          <div class="flex justify-end gap-2 p-3 border-t border-gray-200 bg-gray-50">
            <button 
              @click="showStatusModal = false"
              class="px-3 py-1.5 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 text-xs"
            >
              Cancel
            </button>
            <button 
              @click="saveStatusChange"
              class="px-3 py-1.5 bg-primary text-white rounded-md hover:bg-primary/90 text-xs"
            >
              Save Changes
            </button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Delete Confirmation Modal - More Compact -->
    <div v-if="showDeleteModal" class="fixed inset-0 z-50 overflow-y-auto">
      <div class="flex items-center justify-center min-h-screen p-3">
        <div class="fixed inset-0 bg-black bg-opacity-50 transition-opacity" @click="showDeleteModal = false"></div>
        
        <div class="bg-white rounded-lg shadow-lg w-full max-w-sm mx-auto z-10 overflow-hidden">
          <div class="p-4">
            <div class="flex items-center justify-center w-8 h-8 mx-auto bg-red-100 rounded-full mb-3">
              <Icon name="heroicons:exclamation-triangle" class="h-4 w-4 text-red-600" />
            </div>
            <h3 class="text-sm font-medium text-center text-gray-900 mb-1">Confirm Deletion</h3>
            <p class="text-gray-600 text-center mb-4 text-xs">
              Are you sure you want to delete "<span class="font-medium">{{ selectedPost?.title }}</span>"? This action cannot be undone.
            </p>
            <div class="flex justify-center gap-2">
              <button 
                @click="showDeleteModal = false"
                class="px-3 py-1.5 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 text-xs"
              >
                Cancel
              </button>
              <button 
                @click="deletePost"
                class="px-3 py-1.5 bg-red-600 text-white rounded-md hover:bg-red-700 text-xs"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';

const emit = defineEmits(['create-post', 'edit-post', 'delete-post']);

// Tab options with dynamic counts from filtered posts
const tabs = computed(() => [
  { id: 'all', name: 'All Listings', count: allPosts.value.length },
  { id: 'active', name: 'Active', count: activePosts.value },
  { id: 'pending', name: 'Pending', count: pendingPosts.value },
  { id: 'sold', name: 'Sold', count: soldPosts.value },
  { id: 'featured', name: 'Featured', count: featuredPosts.value },
]);

// Stats computed properties
const activePosts = computed(() => allPosts.value.filter(post => post.status === 'Active').length);
const pendingPosts = computed(() => allPosts.value.filter(post => post.status === 'Pending').length);
const soldPosts = computed(() => allPosts.value.filter(post => post.status === 'Sold').length);
const featuredPosts = computed(() => allPosts.value.filter(post => post.featured).length);

// UI state
const activeTab = ref('all');
const isLoading = ref(true);
const currentPage = ref(1);
const postsPerPage = 10; // Increased posts per page for list view
const sortOption = ref('newest');
const searchQuery = ref('');
const openDropdown = ref(null);

// Modals
const showStatusModal = ref(false);
const showDeleteModal = ref(false);
const selectedPost = ref(null);
const newStatus = ref(null);

// Status options
const availableStatuses = [
  { 
    value: 'Active', 
    label: 'Active', 
    description: 'Listing is live and visible to all users',
    icon: 'heroicons:check-circle',
    iconColor: 'text-green-600',
    bgColor: 'bg-green-100'
  },
  { 
    value: 'Pending', 
    label: 'Pending', 
    description: 'Listing is awaiting approval',
    icon: 'heroicons:clock',
    iconColor: 'text-yellow-600',
    bgColor: 'bg-yellow-100' 
  },
  { 
    value: 'Sold', 
    label: 'Sold', 
    description: 'Item has been sold',
    icon: 'heroicons:banknotes',
    iconColor: 'text-blue-600',
    bgColor: 'bg-blue-100'
  },
  { 
    value: 'Paused', 
    label: 'Paused', 
    description: 'Temporarily hide the listing',
    icon: 'heroicons:pause',
    iconColor: 'text-gray-600',
    bgColor: 'bg-gray-100'
  }
];

// Mock data for posts - this would come from an API in a real app
const allPosts = ref([
  {
    id: 1,
    title: 'iPhone 12 Pro Max - Like New',
    description: 'Selling my iPhone 12 Pro Max 256GB. Pacific Blue color. Like new condition with no scratches.',
    price: 75000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=iPhone+12',
    location: 'Gulshan, Dhaka',
    status: 'Active',
    featured: true,
    views: 128,
    postedDate: new Date(2025, 4, 5) // May 5, 2025
  },
  {
    id: 2,
    title: 'Samsung 65" QLED Smart TV',
    description: 'Samsung 65" QLED 4K Smart TV with warranty until 2026. Perfect condition.',
    price: 120000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Samsung+TV',
    location: 'Banani, Dhaka',
    status: 'Active',
    featured: false,
    views: 87,
    postedDate: new Date(2025, 4, 1) // May 1, 2025
  },
  {
    id: 3,
    title: 'MacBook Pro 16" M2 Pro',
    description: 'MacBook Pro 16-inch with M2 Pro chip, 32GB RAM, 1TB SSD. Space Gray.',
    price: 250000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=MacBook+Pro',
    location: 'Dhanmondi, Dhaka',
    status: 'Pending',
    featured: false,
    views: 42,
    postedDate: new Date(2025, 4, 8) // May 8, 2025
  },
  {
    id: 4,
    title: 'Sony A7 III Camera with 2 Lenses',
    description: 'Sony A7 III mirrorless camera with 24-70mm and 70-200mm lenses.',
    price: 180000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Sony+Camera',
    location: 'Uttara, Dhaka',
    status: 'Sold',
    featured: false,
    views: 204,
    postedDate: new Date(2025, 3, 15) // Apr 15, 2025
  },
  {
    id: 5,
    title: 'Yamaha Acoustic Guitar',
    description: 'Yamaha F310 Acoustic Guitar. Great sound quality. Minor scratches.',
    price: 12000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Guitar',
    location: 'Mirpur, Dhaka',
    status: 'Active',
    featured: false,
    views: 76,
    postedDate: new Date(2025, 4, 3) // May 3, 2025
  },
  {
    id: 6,
    title: 'Royal Enfield Classic 350',
    description: 'Royal Enfield Classic 350 in Stealth Black. 2023 model with only 5000 km.',
    price: 350000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Royal+Enfield',
    location: 'Mohammadpur, Dhaka',
    status: 'Active',
    featured: true,
    views: 158,
    postedDate: new Date(2025, 3, 25) // Apr 25, 2025
  },
  {
    id: 7,
    title: 'PS5 with Extra Controller and Games',
    description: 'PlayStation 5 Disc Edition with extra DualSense controller and 5 games.',
    price: 65000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=PS5',
    location: 'Bashundhara, Dhaka',
    status: 'Sold',
    featured: false,
    views: 112,
    postedDate: new Date(2025, 3, 10) // Apr 10, 2025
  },
  {
    id: 8,
    title: 'Dyson V11 Vacuum Cleaner',
    description: 'Dyson V11 Absolute cordless vacuum cleaner. Used for 6 months only.',
    price: 45000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Dyson+Vacuum',
    location: 'Lalmatia, Dhaka',
    status: 'Active',
    featured: false,
    views: 68,
    postedDate: new Date(2025, 4, 7) // May 7, 2025
  }
]);

// Filter posts based on active tab and search query
const filteredPosts = computed(() => {
  // First filter by tab
  let posts = [];
  switch (activeTab.value) {
    case 'all':
      posts = [...allPosts.value];
      break;
    case 'active':
      posts = allPosts.value.filter(post => post.status === 'Active');
      break;
    case 'pending':
      posts = allPosts.value.filter(post => post.status === 'Pending');
      break;
    case 'sold':
      posts = allPosts.value.filter(post => post.status === 'Sold');
      break;
    case 'featured':
      posts = allPosts.value.filter(post => post.featured);
      break;
    default:
      posts = [...allPosts.value];
  }
  
  // Then filter by search query
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    posts = posts.filter(post => 
      post.title.toLowerCase().includes(query) || 
      post.description.toLowerCase().includes(query) ||
      post.location.toLowerCase().includes(query)
    );
  }
  
  // Sort posts
  switch (sortOption.value) {
    case 'newest':
      posts.sort((a, b) => b.postedDate - a.postedDate);
      break;
    case 'oldest':
      posts.sort((a, b) => a.postedDate - b.postedDate);
      break;
    case 'price_high':
      posts.sort((a, b) => b.price - a.price);
      break;
    case 'price_low':
      posts.sort((a, b) => a.price - b.price);
      break;
  }
  
  return posts;
});

// Pagination logic
const totalPages = computed(() => Math.ceil(filteredPosts.value.length / postsPerPage));

const displayedPosts = computed(() => {
  const startIndex = (currentPage.value - 1) * postsPerPage;
  const endIndex = startIndex + postsPerPage;
  return filteredPosts.value.slice(startIndex, endIndex);
});

// Generate pagination numbers with ellipsis for large page counts
const paginationPages = computed(() => {
  if (totalPages.value <= 5) { // Reduced from 7 to 5 to save space
    return Array.from({ length: totalPages.value }, (_, i) => i + 1);
  }
  
  const pages = [];
  
  if (currentPage.value <= 3) {
    // Near beginning: show first 3 pages, then ellipsis, then last page
    for (let i = 1; i <= 3; i++) pages.push(i);
    pages.push('...');
    pages.push(totalPages.value);
  } else if (currentPage.value >= totalPages.value - 2) {
    // Near end: show first page, then ellipsis, then last 3 pages
    pages.push(1);
    pages.push('...');
    for (let i = totalPages.value - 2; i <= totalPages.value; i++) pages.push(i);
  } else {
    // In middle: show first page, ellipsis, current, ellipsis, last page
    pages.push(1);
    pages.push('...');
    pages.push(currentPage.value);
    pages.push('...');
    pages.push(totalPages.value);
  }
  
  return pages;
});

// Reset to page 1 when filters change
watch([activeTab, searchQuery, sortOption], () => {
  currentPage.value = 1;
});

// Format date helper
const formatDate = (date) => {
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays}d ago`;
  
  return date.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
};

// Status badge color helper
const getStatusClass = (status) => {
  switch (status.toLowerCase()) {
    case 'active': return 'bg-green-100 text-green-800';
    case 'pending': return 'bg-yellow-100 text-yellow-800';
    case 'sold': return 'bg-blue-100 text-blue-800';
    case 'paused': return 'bg-gray-100 text-gray-800';
    default: return 'bg-gray-100 text-gray-800';
  }
};

// Status update modal
const updateStatus = (post) => {
  selectedPost.value = post;
  newStatus.value = post.status;
  showStatusModal.value = true;
};

const saveStatusChange = () => {
  // Update post status - in a real app, you would call an API here
  if (selectedPost.value && newStatus.value) {
    const postIndex = allPosts.value.findIndex(p => p.id === selectedPost.value.id);
    if (postIndex !== -1) {
      allPosts.value[postIndex].status = newStatus.value;
    }
  }
  showStatusModal.value = false;
};

// Delete confirmation modal
const confirmDelete = (post) => {
  selectedPost.value = post;
  showDeleteModal.value = true;
};

const deletePost = () => {
  // Delete post - in a real app, you would call an API here
  if (selectedPost.value) {
    emit('delete-post', selectedPost.value.id);
    
    // Remove from local state
    allPosts.value = allPosts.value.filter(p => p.id !== selectedPost.value.id);
  }
  showDeleteModal.value = false;
};

// View and edit handlers
const editPost = (post) => {
  emit('edit-post', post);
};

// Simulate loading data from API
onMounted(() => {
  // Simulate loading data from API
  setTimeout(() => {
    isLoading.value = false;
  }, 1000);
});
</script>

<style scoped>
.line-clamp-1 {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.hide-scrollbar {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none;  /* Chrome, Safari and Opera */
}

.text-xxs {
  font-size: 0.65rem;
  line-height: 1rem;
}
</style>