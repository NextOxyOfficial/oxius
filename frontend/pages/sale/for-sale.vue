<template>
  <div class="for-sale-page py-6">
    <div class="container mx-auto px-4">
      <div class="flex flex-col md:flex-row gap-6">
        <!-- Filters Sidebar -->
        <div class="w-full md:w-64 flex-shrink-0">
          <div class="bg-white rounded-lg shadow-md p-4">
            <h3 class="text-lg font-semibold mb-4">Filters</h3>
            
            <!-- Categories -->
            <div class="mb-6">
              <h4 class="font-medium text-gray-700 mb-2">Categories</h4>
              <div class="space-y-2">
                <div v-for="category in categories" :key="category.id" class="flex items-center">
                  <input 
                    type="radio" 
                    :id="`category-${category.id}`"
                    :value="category.id"
                    v-model="selectedCategory"
                    class="w-4 h-4 text-primary focus:ring-primary"
                  >
                  <label :for="`category-${category.id}`" class="ml-2 text-sm text-gray-700">
                    {{ category.name }}
                  </label>
                </div>
                <div class="flex items-center">
                  <input 
                    type="radio" 
                    id="category-all"
                    :value="null"
                    v-model="selectedCategory"
                    class="w-4 h-4 text-primary focus:ring-primary"
                  >
                  <label for="category-all" class="ml-2 text-sm text-gray-700">All Categories</label>
                </div>
              </div>
            </div>
            
            <!-- Price Range -->
            <div class="mb-6">
              <h4 class="font-medium text-gray-700 mb-2">Price Range</h4>
              <div class="flex flex-col space-y-2">
                <div class="flex gap-2">
                  <div class="w-1/2">
                    <input 
                      type="number" 
                      v-model="priceRange.min" 
                      placeholder="Min"
                      class="w-full border border-gray-300 rounded-md px-3 py-1 text-sm focus:ring-primary focus:border-primary"
                    >
                  </div>
                  <div class="w-1/2">
                    <input 
                      type="number" 
                      v-model="priceRange.max" 
                      placeholder="Max"
                      class="w-full border border-gray-300 rounded-md px-3 py-1 text-sm focus:ring-primary focus:border-primary"
                    >
                  </div>
                </div>
                <button 
                  @click="applyPriceFilter"
                  class="bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm py-1 px-3 rounded"
                >
                  Apply
                </button>
              </div>
            </div>
            
            <!-- Location -->
            <div class="mb-6">
              <h4 class="font-medium text-gray-700 mb-2">Location</h4>
              <select 
                v-model="selectedLocation" 
                class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-primary focus:border-primary"
              >
                <option value="">All Locations</option>
                <option v-for="location in locations" :key="location" :value="location">
                  {{ location }}
                </option>
              </select>
            </div>
            
            <!-- Posted Time -->
            <div class="mb-6">
              <h4 class="font-medium text-gray-700 mb-2">Posted Time</h4>
              <div class="space-y-2">
                <div v-for="(option, index) in timeOptions" :key="index" class="flex items-center">
                  <input 
                    type="radio" 
                    :id="`time-${index}`" 
                    :value="option.value" 
                    v-model="postedTime"
                    class="w-4 h-4 text-primary focus:ring-primary"
                  >
                  <label :for="`time-${index}`" class="ml-2 text-sm text-gray-700">{{ option.label }}</label>
                </div>
              </div>
            </div>
            
            <!-- Clear Filters -->
            <button 
              @click="resetFilters"
              class="w-full bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 py-2 px-4 rounded-md text-sm"
            >
              Clear All Filters
            </button>
          </div>
        </div>
        
        <!-- Content Area -->
        <div class="flex-grow">
          <!-- Header with breadcrumb and post button -->
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-4">
            <div class="breadcrumbs text-sm text-gray-500 mb-2 sm:mb-0">
              <NuxtLink to="/" class="hover:text-primary">Home</NuxtLink>
              <span class="mx-2">/</span>
              <span class="text-gray-700">For Sale</span>
              <span v-if="selectedCategoryName" class="mx-2">/</span>
              <span v-if="selectedCategoryName" class="text-gray-700">{{ selectedCategoryName }}</span>
            </div>
            
            <button 
              @click="openPostSaleModal"
              class="bg-primary hover:bg-primary/90 text-white px-3 py-2 rounded-md text-sm flex items-center gap-2"
            >
              <Icon name="heroicons:plus-circle" size="16px" />
              Post a Sale
            </button>
          </div>
          
          <!-- Search and Sort Controls -->
          <div class="bg-white rounded-lg shadow-md p-4 mb-4">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <!-- Search -->
              <div class="relative flex-grow">
                <input 
                  type="text"
                  v-model="searchQuery"
                  placeholder="Search listings..."
                  class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-2 focus:ring-primary focus:border-primary"
                >
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Icon name="heroicons:magnifying-glass" class="text-gray-400" size="16px" />
                </div>
              </div>
              
              <!-- Sort -->
              <div class="flex items-center gap-2">
                <span class="text-sm text-gray-600">Sort by:</span>
                <select 
                  v-model="sortOption"
                  class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-primary focus:border-primary"
                >
                  <option value="newest">Newest First</option>
                  <option value="oldest">Oldest First</option>
                  <option value="price_low">Price: Low to High</option>
                  <option value="price_high">Price: High to Low</option>
                </select>
              </div>
            </div>
          </div>
          
          <!-- Loading State -->
          <div v-if="isLoading" class="py-8 bg-white rounded-lg shadow-md text-center">
            <div class="inline-flex items-center px-4 py-2 font-semibold leading-6 text-sm text-gray-700">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Loading listings...
            </div>
          </div>
          
          <!-- No Results -->
          <div v-else-if="!filteredListings.length" class="py-8 bg-white rounded-lg shadow-md text-center">
            <div class="inline-flex flex-col items-center">
              <Icon name="heroicons:shopping-bag" size="48px" class="text-gray-300 mb-2" />
              <p class="text-gray-500">No listings found matching your criteria</p>
              <button 
                @click="resetFilters"
                class="mt-4 border border-gray-300 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-50"
              >
                Clear Filters
              </button>
            </div>
          </div>
          
          <!-- Listings Grid -->
          <div v-else>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              <div 
                v-for="listing in paginatedListings" 
                :key="listing.id"
                class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow"
              >
                <!-- Card Image -->
                <div class="relative h-48">
                  <img 
                    :src="listing.imageUrl" 
                    :alt="listing.title"
                    class="w-full h-full object-cover"
                  />
                  <span 
                    v-if="listing.featured"
                    class="absolute top-2 left-2 bg-yellow-500 text-white text-xs px-2 py-0.5 rounded-md"
                  >
                    Featured
                  </span>
                </div>
                
                <!-- Card Content -->
                <div class="p-4">
                  <h3 class="font-medium text-gray-900 mb-1 line-clamp-1">{{ listing.title }}</h3>
                  <p class="text-primary font-medium mb-2">৳{{ listing.price.toLocaleString() }}</p>
                  <p class="text-gray-600 text-sm mb-2 line-clamp-2">{{ listing.description }}</p>
                  
                  <div class="flex justify-between items-center">
                    <div class="text-sm text-gray-500 flex items-center">
                      <Icon name="heroicons:map-pin" size="14px" class="mr-1" />
                      <span>{{ listing.location }}</span>
                    </div>
                    <div class="text-xs text-gray-500">
                      {{ formatDate(listing.postedDate) }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Pagination -->
            <div v-if="totalPages > 1" class="mt-8 flex justify-center">
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
      </div>
    </div>
    
    <!-- Post Sale Modal -->
    <div v-if="showPostSaleModal" class="fixed inset-0 z-50 overflow-y-auto pt-16"> <!-- Added pt-16 for header spacing -->
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" @click="closePostSaleModal">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-3xl sm:w-full">
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <div class="flex justify-between items-center border-b pb-3 mb-4">
                  <h3 class="text-lg leading-6 font-medium text-gray-900">Post a Sale</h3>
                  <button 
                    type="button" 
                    class="text-gray-400 hover:text-gray-500"
                    @click="closePostSaleModal"
                  >
                    <Icon name="heroicons:x-mark" size="24px" />
                  </button>
                </div>
                <PostSale 
                  :categories="categories" 
                  :edit-post="postToEdit" 
                  @post-saved="handlePostSaved"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- My Posts Modal -->
    <div v-if="showMyPostsModal" class="fixed inset-0 z-50 overflow-y-auto pt-16"> <!-- Added pt-16 for header spacing -->
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" @click="closeMyPostsModal">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <div class="flex justify-between items-center border-b pb-3 mb-4">
                  <h3 class="text-lg leading-6 font-medium text-gray-900">My Posts</h3>
                  <button 
                    type="button" 
                    class="text-gray-400 hover:text-gray-500"
                    @click="closeMyPostsModal"
                  >
                    <Icon name="heroicons:x-mark" size="24px" />
                  </button>
                </div>
                <MyPosts 
                  @create-post="switchToPostSaleModal"
                  @edit-post="handleEditPost"
                  @delete-post="handleDeletePost"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import PostSale from '~/components/sale/PostSale.vue';
import MyPosts from '~/components/sale/MyPosts.vue';

const route = useRoute();

// Modal States
const showPostSaleModal = ref(false);
const showMyPostsModal = ref(false);

// Categories
const categories = ref([
  { id: 1, name: 'Properties', icon: 'heroicons:home-modern' },
  { id: 2, name: 'Vehicles', icon: 'heroicons:truck' },
  { id: 3, name: 'Electronics', icon: 'heroicons:device-phone-mobile' },
  { id: 4, name: 'Sports', icon: 'heroicons:trophy' },
  { id: 5, name: 'B2B', icon: 'heroicons:building-office' },
  { id: 6, name: 'Others', icon: 'heroicons:squares-plus' },
]);

// Locations
const locations = [
  'Dhaka',
  'Chittagong',
  'Khulna',
  'Rajshahi',
  'Sylhet',
  'Barisal',
  'Rangpur',
  'Mymensingh',
];

// Time filter options
const timeOptions = [
  { label: 'All Time', value: null },
  { label: 'Today', value: 'today' },
  { label: 'Last 3 days', value: '3days' },
  { label: 'Last week', value: 'week' },
  { label: 'Last month', value: 'month' },
];

// Filter states
const selectedCategory = ref(null);
const searchQuery = ref('');
const priceRange = ref({ min: null, max: null });
const selectedLocation = ref('');
const postedTime = ref(null);
const sortOption = ref('newest');

// Pagination
const currentPage = ref(1);
const itemsPerPage = 9;
const isLoading = ref(true);

// Mock data for listings - this would come from an API in a real app
const allListings = ref([
  {
    id: 1,
    title: 'iPhone 12 Pro Max - Like New',
    description: 'Selling my iPhone 12 Pro Max 256GB. Pacific Blue color. Like new condition with no scratches. Comes with original box and accessories. Battery health 92%.',
    price: 75000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=iPhone+12',
    location: 'Dhaka',
    categoryId: 3,
    featured: true,
    postedDate: new Date(2025, 4, 5) // May 5, 2025
  },
  {
    id: 2,
    title: 'Samsung 65" QLED Smart TV',
    description: 'Samsung 65" QLED 4K Smart TV with warranty until 2026. Perfect condition, selling due to moving abroad.',
    price: 120000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Samsung+TV',
    location: 'Dhaka',
    categoryId: 3,
    featured: false,
    postedDate: new Date(2025, 4, 1) // May 1, 2025
  },
  {
    id: 3,
    title: 'MacBook Pro 16" M2 Pro',
    description: 'MacBook Pro 16-inch with M2 Pro chip, 32GB RAM, 1TB SSD. Space Gray. Used for only 3 months.',
    price: 250000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=MacBook+Pro',
    location: 'Dhaka',
    categoryId: 3,
    featured: false,
    postedDate: new Date(2025, 4, 8) // May 8, 2025
  },
  {
    id: 4,
    title: 'Sony A7 III Camera with 2 Lenses',
    description: 'Sony A7 III mirrorless camera with 24-70mm and 70-200mm lenses. Includes extra batteries, memory cards, and carrying case.',
    price: 180000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Sony+Camera',
    location: 'Chittagong',
    categoryId: 3,
    featured: false,
    postedDate: new Date(2025, 3, 15) // Apr 15, 2025
  },
  {
    id: 5,
    title: 'Yamaha Acoustic Guitar',
    description: 'Yamaha F310 Acoustic Guitar. Great sound quality. Minor scratches but in excellent playing condition. Comes with case and strap.',
    price: 12000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Guitar',
    location: 'Dhaka',
    categoryId: 4,
    featured: false,
    postedDate: new Date(2025, 4, 3) // May 3, 2025
  },
  {
    id: 6,
    title: 'Royal Enfield Classic 350',
    description: 'Royal Enfield Classic 350 in Stealth Black. 2023 model with only 5000 km. Single owner with all documents up to date.',
    price: 350000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Royal+Enfield',
    location: 'Dhaka',
    categoryId: 2,
    featured: true,
    postedDate: new Date(2025, 3, 25) // Apr 25, 2025
  },
  {
    id: 7,
    title: 'PS5 with Extra Controller and Games',
    description: 'PlayStation 5 Disc Edition with extra DualSense controller and 5 games including FIFA 25 and God of War Ragnarök.',
    price: 65000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=PS5',
    location: 'Rajshahi',
    categoryId: 4,
    featured: false,
    postedDate: new Date(2025, 3, 10) // Apr 10, 2025
  },
  {
    id: 8,
    title: 'Dyson V11 Vacuum Cleaner',
    description: 'Dyson V11 Absolute cordless vacuum cleaner. Used for 6 months only. Comes with all attachments and wall mount.',
    price: 45000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Dyson+Vacuum',
    location: 'Dhaka',
    categoryId: 3,
    featured: false,
    postedDate: new Date(2025, 4, 7) // May 7, 2025
  },
  {
    id: 9,
    title: '2BR Apartment for Sale in Gulshan',
    description: '2 bedroom, 2 bathroom apartment in Gulshan-2. 1250 sqft with modern amenities, 24/7 security, and parking space. Ready to move in condition.',
    price: 8500000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Apartment',
    location: 'Dhaka',
    categoryId: 1,
    featured: true,
    postedDate: new Date(2025, 3, 20) // Apr 20, 2025
  },
  {
    id: 10,
    title: 'Toyota Corolla Cross Hybrid',
    description: '2024 Toyota Corolla Cross Hybrid. Only 8,000 km. Excellent fuel efficiency. Top-tier model with all features. Registration and insurance up to date.',
    price: 4500000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Toyota+Corolla',
    location: 'Sylhet',
    categoryId: 2,
    featured: false,
    postedDate: new Date(2025, 4, 2) // May 2, 2025
  },
  {
    id: 11,
    title: 'Commercial Space for Sale',
    description: 'Prime commercial space for sale in Motijheel. 3000 sqft on 3rd floor. Ready for office or retail business. Excellent location with high foot traffic.',
    price: 12000000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Commercial+Space',
    location: 'Dhaka',
    categoryId: 1,
    featured: false,
    postedDate: new Date(2025, 4, 6) // May 6, 2025
  },
  {
    id: 12,
    title: 'Dell XPS 15 Laptop',
    description: 'Dell XPS 15 (2025) with 11th Gen Intel Core i7, 32GB RAM, 1TB SSD, NVIDIA RTX 3050Ti. 4K OLED display. Used for 3 months only.',
    price: 150000,
    imageUrl: 'https://via.placeholder.com/300x300/3b82f6/FFFFFF?text=Dell+XPS',
    location: 'Khulna',
    categoryId: 3,
    featured: false,
    postedDate: new Date(2025, 4, 9) // May 9, 2025
  }
]);

// Filter listings based on selected filters
const filteredListings = computed(() => {
  let filtered = [...allListings.value];
  
  // Filter by category
  if (selectedCategory.value !== null) {
    filtered = filtered.filter(item => item.categoryId === selectedCategory.value);
  }
  
  // Filter by search query
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(item => 
      item.title.toLowerCase().includes(query) || 
      item.description.toLowerCase().includes(query)
    );
  }
  
  // Filter by price
  if (priceRange.value.min !== null && priceRange.value.min !== '') {
    filtered = filtered.filter(item => item.price >= priceRange.value.min);
  }
  
  if (priceRange.value.max !== null && priceRange.value.max !== '') {
    filtered = filtered.filter(item => item.price <= priceRange.value.max);
  }
  
  // Filter by location
  if (selectedLocation.value) {
    filtered = filtered.filter(item => item.location === selectedLocation.value);
  }
  
  // Filter by posted time
  if (postedTime.value) {
    const now = new Date();
    let cutoff = new Date();
    
    switch (postedTime.value) {
      case 'today':
        cutoff.setHours(0, 0, 0, 0);
        break;
      case '3days':
        cutoff.setDate(cutoff.getDate() - 3);
        break;
      case 'week':
        cutoff.setDate(cutoff.getDate() - 7);
        break;
      case 'month':
        cutoff.setMonth(cutoff.getMonth() - 1);
        break;
    }
    
    filtered = filtered.filter(item => item.postedDate >= cutoff);
  }
  
  // Sort listings
  switch (sortOption.value) {
    case 'newest':
      filtered.sort((a, b) => b.postedDate - a.postedDate);
      break;
    case 'oldest':
      filtered.sort((a, b) => a.postedDate - b.postedDate);
      break;
    case 'price_low':
      filtered.sort((a, b) => a.price - b.price);
      break;
    case 'price_high':
      filtered.sort((a, b) => b.price - a.price);
      break;
  }
  
  return filtered;
});

// Get selected category name
const selectedCategoryName = computed(() => {
  if (!selectedCategory.value) return null;
  const category = categories.value.find(cat => cat.id === selectedCategory.value);
  return category ? category.name : null;
});

// Pagination
const totalPages = computed(() => Math.ceil(filteredListings.value.length / itemsPerPage));

const paginatedListings = computed(() => {
  const startIndex = (currentPage.value - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  return filteredListings.value.slice(startIndex, endIndex);
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

// Reset to page 1 when filters change
watch([selectedCategory, searchQuery, selectedLocation, postedTime], () => {
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

// Filter handlers
const applyPriceFilter = () => {
  // Already handled via computed properties
  currentPage.value = 1;
};

const resetFilters = () => {
  selectedCategory.value = null;
  searchQuery.value = '';
  priceRange.value = { min: null, max: null };
  selectedLocation.value = '';
  postedTime.value = null;
  sortOption.value = 'newest';
  currentPage.value = 1;
};

// Modal handlers
const openPostSaleModal = () => {
  showPostSaleModal.value = true;
  showMyPostsModal.value = false;
};

const closePostSaleModal = () => {
  showPostSaleModal.value = false;
};

const openMyPostsModal = () => {
  showMyPostsModal.value = true;
  showPostSaleModal.value = false;
};

const closeMyPostsModal = () => {
  showMyPostsModal.value = false;
};

const switchToPostSaleModal = () => {
  showMyPostsModal.value = false;
  showPostSaleModal.value = true;
};

// Post actions
const postToEdit = ref(null);

const handleEditPost = (post) => {
  console.log('Edit post received:', post);
  // Set the post to be edited
  postToEdit.value = post;
  // Open the post sale modal with the post data
  showPostSaleModal.value = true;
  // Close the MyPosts modal if it's open
  showMyPostsModal.value = false;
};

const handleDeletePost = (postId) => {
  // Here you would implement delete functionality, possibly making an API call
  console.log('Delete post with ID:', postId);
  // In a real app, you would remove the post from the listings after successful deletion
};

const handlePostSaved = () => {
  console.log('Post saved successfully');
  // Close the modal after saving the post
  closePostSaleModal();
};

// Initialize
onMounted(() => {
  // Check URL parameters for initial category selection
  const categoryParam = route.query.category;
  if (categoryParam) {
    selectedCategory.value = parseInt(categoryParam);
  }
  
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

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>