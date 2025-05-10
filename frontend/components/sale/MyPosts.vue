<template>
  <div class="my-posts-container">
    <div class="bg-white rounded-lg shadow-md p-6">
      <h2 class="text-2xl font-semibold mb-6">My Posts</h2>

      <!-- Listing Filters/Tabs -->
      <div class="mb-6 border-b border-gray-200">
        <ul class="flex flex-wrap -mb-px">
          <li class="mr-4" v-for="(tab, index) in tabs" :key="index">
            <button 
              :class="[
                'inline-block py-2 px-1 border-b-2',
                activeTab === tab.id 
                  ? 'border-primary text-primary font-medium' 
                  : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
              ]"
              @click="activeTab = tab.id"
            >
              {{ tab.name }}
              <span 
                class="ml-1 bg-gray-100 text-gray-700 px-2 py-0.5 rounded-full text-xs"
              >
                {{ tab.count }}
              </span>
            </button>
          </li>
        </ul>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="py-8 text-center">
        <div class="inline-flex items-center px-4 py-2 font-semibold leading-6 text-sm text-gray-700">
          <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Loading posts...
        </div>
      </div>

      <!-- Empty State -->
      <div v-else-if="!filteredPosts.length" class="py-8 text-center">
        <div class="inline-flex flex-col items-center">
          <Icon name="heroicons:document-text" size="48px" class="text-gray-300 mb-2" />
          <p class="text-gray-500">No posts found in this category</p>
          <button 
            class="mt-4 bg-primary text-white px-4 py-2 rounded-md hover:bg-primary/90"
            @click="$emit('create-post')"
          >
            Post a Sale
          </button>
        </div>
      </div>

      <!-- Posts List -->
      <div v-else class="space-y-4">
        <div 
          v-for="post in filteredPosts" 
          :key="post.id"
          class="border border-gray-200 rounded-lg overflow-hidden"
        >
          <div class="flex flex-col md:flex-row">
            <!-- Post Image -->
            <div class="md:w-48 h-48 md:h-auto flex-shrink-0">
              <img 
                :src="post.imageUrl" 
                :alt="post.title" 
                class="w-full h-full object-cover"
              />
            </div>
            
            <!-- Post Details -->
            <div class="p-4 flex flex-col justify-between flex-grow">
              <div>
                <div class="flex justify-between items-start">
                  <h3 class="text-lg font-medium text-gray-900">{{ post.title }}</h3>
                  <div 
                    :class="[
                      'px-2 py-1 text-xs font-medium rounded-full',
                      getStatusClass(post.status)
                    ]"
                  >
                    {{ post.status }}
                  </div>
                </div>
                
                <p class="mt-1 text-primary font-medium">৳{{ post.price.toLocaleString() }}</p>
                <p class="mt-2 text-gray-600 line-clamp-2">{{ post.description }}</p>
                
                <div class="mt-2 flex items-center text-sm text-gray-500">
                  <Icon name="heroicons:map-pin" class="mr-1" size="16px" />
                  {{ post.location }}
                </div>
              </div>
              
              <div class="mt-4 flex justify-between items-center">
                <div class="text-sm text-gray-500">
                  Posted {{ formatDate(post.postedDate) }}
                </div>
                <div class="flex space-x-2">
                  <button 
                    class="text-sm text-primary hover:text-primary/80"
                    @click="editPost(post)"
                  >
                    Edit
                  </button>
                  <span class="text-gray-300">|</span>
                  <button 
                    class="text-sm text-red-500 hover:text-red-700"
                    @click="confirmDelete(post)"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Pagination -->
      <div v-if="filteredPosts.length && totalPages > 1" class="mt-6 flex justify-center">
        <nav class="flex items-center space-x-1">
          <button 
            class="px-3 py-1 rounded-md border border-gray-300 text-gray-600 hover:bg-gray-50"
            :disabled="currentPage === 1"
            @click="currentPage = Math.max(1, currentPage - 1)"
          >
            <Icon name="heroicons:chevron-left" size="16px" />
          </button>
          
          <div v-for="page in paginationPages" :key="page" class="hidden md:block">
            <button 
              v-if="page !== '...'"
              :class="[
                'px-3 py-1 rounded-md',
                currentPage === page
                  ? 'bg-primary text-white'
                  : 'border border-gray-300 text-gray-600 hover:bg-gray-50'
              ]"
              @click="currentPage = page"
            >
              {{ page }}
            </button>
            <span v-else class="px-2 py-1 text-gray-500">...</span>
          </div>
          
          <div class="md:hidden px-3 py-1 text-gray-600">
            {{ currentPage }} / {{ totalPages }}
          </div>
          
          <button 
            class="px-3 py-1 rounded-md border border-gray-300 text-gray-600 hover:bg-gray-50"
            :disabled="currentPage === totalPages"
            @click="currentPage = Math.min(totalPages, currentPage + 1)"
          >
            <Icon name="heroicons:chevron-right" size="16px" />
          </button>
        </nav>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';

const emit = defineEmits(['create-post', 'edit-post', 'delete-post']);

// Tab options
const tabs = [
  { id: 'all', name: 'All Posts', count: 8 },
  { id: 'active', name: 'Active', count: 5 },
  { id: 'pending', name: 'Pending', count: 1 },
  { id: 'sold', name: 'Sold', count: 2 },
];

const activeTab = ref('all');
const isLoading = ref(true);
const currentPage = ref(1);
const postsPerPage = 5;

// Mock data for posts - this would come from an API in a real app
const allPosts = ref([
  {
    id: 1,
    title: 'iPhone 12 Pro Max - Like New',
    description: 'Selling my iPhone 12 Pro Max 256GB. Pacific Blue color. Like new condition with no scratches. Comes with original box and accessories. Battery health 92%.',
    price: 75000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=iPhone+12',
    location: 'Gulshan, Dhaka',
    status: 'Active',
    postedDate: new Date(2025, 4, 5) // May 5, 2025
  },
  {
    id: 2,
    title: 'Samsung 65" QLED Smart TV',
    description: 'Samsung 65" QLED 4K Smart TV with warranty until 2026. Perfect condition, selling due to moving abroad.',
    price: 120000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Samsung+TV',
    location: 'Banani, Dhaka',
    status: 'Active',
    postedDate: new Date(2025, 4, 1) // May 1, 2025
  },
  {
    id: 3,
    title: 'MacBook Pro 16" M2 Pro',
    description: 'MacBook Pro 16-inch with M2 Pro chip, 32GB RAM, 1TB SSD. Space Gray. Used for only 3 months.',
    price: 250000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=MacBook+Pro',
    location: 'Dhanmondi, Dhaka',
    status: 'Pending',
    postedDate: new Date(2025, 4, 8) // May 8, 2025
  },
  {
    id: 4,
    title: 'Sony A7 III Camera with 2 Lenses',
    description: 'Sony A7 III mirrorless camera with 24-70mm and 70-200mm lenses. Includes extra batteries, memory cards, and carrying case.',
    price: 180000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Sony+Camera',
    location: 'Uttara, Dhaka',
    status: 'Sold',
    postedDate: new Date(2025, 3, 15) // Apr 15, 2025
  },
  {
    id: 5,
    title: 'Yamaha Acoustic Guitar',
    description: 'Yamaha F310 Acoustic Guitar. Great sound quality. Minor scratches but in excellent playing condition. Comes with case and strap.',
    price: 12000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Guitar',
    location: 'Mirpur, Dhaka',
    status: 'Active',
    postedDate: new Date(2025, 4, 3) // May 3, 2025
  },
  {
    id: 6,
    title: 'Royal Enfield Classic 350',
    description: 'Royal Enfield Classic 350 in Stealth Black. 2023 model with only 5000 km. Single owner with all documents up to date.',
    price: 350000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Royal+Enfield',
    location: 'Mohammadpur, Dhaka',
    status: 'Active',
    postedDate: new Date(2025, 3, 25) // Apr 25, 2025
  },
  {
    id: 7,
    title: 'PS5 with Extra Controller and Games',
    description: 'PlayStation 5 Disc Edition with extra DualSense controller and 5 games including FIFA 25 and God of War Ragnarök.',
    price: 65000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=PS5',
    location: 'Bashundhara, Dhaka',
    status: 'Sold',
    postedDate: new Date(2025, 3, 10) // Apr 10, 2025
  },
  {
    id: 8,
    title: 'Dyson V11 Vacuum Cleaner',
    description: 'Dyson V11 Absolute cordless vacuum cleaner. Used for 6 months only. Comes with all attachments and wall mount.',
    price: 45000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Dyson+Vacuum',
    location: 'Lalmatia, Dhaka',
    status: 'Active',
    postedDate: new Date(2025, 4, 7) // May 7, 2025
  }
]);

// Filter posts based on active tab
const filteredPosts = computed(() => {
  const posts = activeTab.value === 'all'
    ? allPosts.value
    : allPosts.value.filter(post => post.status.toLowerCase() === activeTab.value);
  
  // Sort by latest first
  return [...posts].sort((a, b) => b.postedDate - a.postedDate);
});

// Pagination logic
const totalPages = computed(() => Math.ceil(filteredPosts.value.length / postsPerPage));

const paginatedPosts = computed(() => {
  const startIndex = (currentPage.value - 1) * postsPerPage;
  const endIndex = startIndex + postsPerPage;
  return filteredPosts.value.slice(startIndex, endIndex);
});

// Generate pagination numbers with ellipsis for large page counts
const paginationPages = computed(() => {
  if (totalPages.value <= 7) {
    return Array.from({ length: totalPages.value }, (_, i) => i + 1);
  }
  
  const pages = [];
  
  if (currentPage.value <= 3) {
    // Near beginning: show first 5 pages, then ellipsis, then last page
    for (let i = 1; i <= 5; i++) pages.push(i);
    pages.push('...');
    pages.push(totalPages.value);
  } else if (currentPage.value >= totalPages.value - 2) {
    // Near end: show first page, then ellipsis, then last 5 pages
    pages.push(1);
    pages.push('...');
    for (let i = totalPages.value - 4; i <= totalPages.value; i++) pages.push(i);
  } else {
    // In middle: show first page, ellipsis, current-1, current, current+1, ellipsis, last page
    pages.push(1);
    pages.push('...');
    for (let i = currentPage.value - 1; i <= currentPage.value + 1; i++) pages.push(i);
    pages.push('...');
    pages.push(totalPages.value);
  }
  
  return pages;
});

// Reset to page 1 when switching tabs
watch(activeTab, () => {
  currentPage.value = 1;
});

// Format date helper
const formatDate = (date) => {
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;
  
  return date.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
};

// Status badge color helper
const getStatusClass = (status) => {
  switch (status.toLowerCase()) {
    case 'active': return 'bg-green-100 text-green-800';
    case 'pending': return 'bg-yellow-100 text-yellow-800';
    case 'sold': return 'bg-gray-100 text-gray-800';
    default: return 'bg-gray-100 text-gray-800';
  }
};

// Action handlers
const editPost = (post) => {
  emit('edit-post', post);
};

const confirmDelete = (post) => {
  if (confirm(`Are you sure you want to delete "${post.title}"?`)) {
    emit('delete-post', post.id);
  }
};

// Simulate loading data from API
onMounted(() => {
  setTimeout(() => {
    isLoading.value = false;
  }, 1000);
});
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>