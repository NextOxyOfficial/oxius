<template>
  <div>
    <!-- Filters and Search Bar -->
    <div class="mb-6">
      <div class="flex items-center justify-between gap-3">
        <!-- Search Bar -->
        <div class="flex-1 max-w-md">
          <div class="relative">
            <Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search my gigs..."
              class="w-full h-[34px] pl-10 pr-4 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 transition-colors"
            />
          </div>
        </div>
        
        <!-- Right Side Controls -->
        <div class="flex items-center space-x-2">
          <!-- Filter Button with Dropdown -->
          <div class="relative">
            <button
              @click="showFilterDropdown = !showFilterDropdown"
              class="flex items-center space-x-2 px-3 h-[34px] text-sm border border-gray-200 rounded-md hover:bg-gray-50 transition-colors"
              :class="{ 'bg-purple-50 border-purple-300': hasActiveFilters }"
            >
              <Filter class="h-4 w-4" />
              <span class="hidden sm:inline">Filter</span>
              <span v-if="activeFilterCount > 0" class="bg-purple-600 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                {{ activeFilterCount }}
              </span>
              <ChevronDown class="h-4 w-4" />
            </button>
            
            <!-- Filter Dropdown -->
            <div 
              v-if="showFilterDropdown"
              class="absolute right-0 mt-2 w-72 bg-white rounded-lg shadow-lg border border-gray-200 z-50 p-4 space-y-4"
            >
              <!-- Category Filter -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
                <select 
                  v-model="selectedCategory"
                  class="w-full px-3 py-2 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500"
                >
                  <option value="">All Categories</option>
                  <option value="design">Design & Creative</option>
                  <option value="development">Programming & Tech</option>
                  <option value="writing">Writing & Translation</option>
                  <option value="marketing">Digital Marketing</option>
                  <option value="business">Business & Consulting</option>
                </select>
              </div>
              
              <!-- Status Filter -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select 
                  v-model="selectedStatus"
                  class="w-full px-3 py-2 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500"
                >
                  <option value="">All Status</option>
                  <option value="active">Active</option>
                  <option value="paused">Paused</option>
                  <option value="draft">Draft</option>
                  <option value="deleted">Deleted</option>
                </select>
              </div>
              
              <!-- Sort By -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Sort By</label>
                <select 
                  v-model="sortBy"
                  class="w-full px-3 py-2 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500"
                >
                  <option value="newest">Newest First</option>
                  <option value="oldest">Oldest First</option>
                  <option value="price-low">Price: Low to High</option>
                  <option value="price-high">Price: High to Low</option>
                  <option value="most-views">Most Views</option>
                  <option value="most-orders">Most Orders</option>
                </select>
              </div>
              
              <!-- Clear Filters Button -->
              <button
                v-if="hasActiveFilters"
                @click="clearFilters"
                class="w-full py-2 text-sm text-purple-600 hover:text-purple-700 font-medium"
              >
                Clear All Filters
              </button>
            </div>
          </div>
          
          <!-- View Toggle -->
          <div class="flex items-center border border-gray-200 rounded-md p-1">
            <button
              @click="viewMode = 'grid'"
              :class="[
                'p-1.5 rounded transition-colors',
                viewMode === 'grid' ? 'bg-purple-100 text-purple-600' : 'text-gray-400 hover:text-gray-600'
              ]"
            >
              <LayoutGrid class="h-4 w-4" />
            </button>
            <button
              @click="viewMode = 'list'"
              :class="[
                'p-1.5 rounded transition-colors',
                viewMode === 'list' ? 'bg-purple-100 text-purple-600' : 'text-gray-400 hover:text-gray-600'
              ]"
            >
              <List class="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Click outside to close dropdown -->
    <div v-if="showFilterDropdown" class="fixed inset-0 z-40" @click="showFilterDropdown = false"></div>

    <!-- Loading Skeleton -->
    <div v-if="isLoading" class="grid grid-cols-2 gap-2">
      <div
        v-for="n in 4"
        :key="n"
        class="bg-white border border-gray-100 rounded-lg overflow-hidden animate-pulse"
      >
        <div class="h-48 bg-gray-200"></div>
        <div class="p-4">
          <div class="flex items-center mb-3">
            <div class="h-8 w-8 rounded-full bg-gray-200"></div>
            <div class="ml-2 space-y-1">
              <div class="h-3 w-20 bg-gray-200 rounded"></div>
              <div class="h-2 w-16 bg-gray-200 rounded"></div>
            </div>
          </div>
          <div class="h-4 bg-gray-200 rounded mb-2"></div>
          <div class="h-4 bg-gray-200 rounded w-3/4 mb-3"></div>
          <div class="flex justify-between">
            <div class="h-3 w-16 bg-gray-200 rounded"></div>
            <div class="h-5 w-12 bg-gray-200 rounded"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Results Header -->
    <div v-if="!isLoading && filteredMyGigs.length > 0" class="flex items-center justify-between mb-4">
      <p class="text-sm text-gray-600">{{ filteredMyGigs.length }} gig{{ filteredMyGigs.length !== 1 ? 's' : '' }} found</p>
      <button
        v-if="hasActiveFilters"
        @click="clearFilters"
        class="text-sm text-purple-600 hover:text-purple-700 font-medium"
      >
        Clear Filters
      </button>
    </div>

    <!-- Grid View -->
    <div v-if="!isLoading && filteredMyGigs.length > 0 && viewMode === 'grid'" class="grid grid-cols-2 gap-2">
      <div
        v-for="gig in filteredMyGigs"
        :key="gig.id"
        class="bg-white border border-gray-100 rounded-lg overflow-hidden hover:shadow-sm transition-all duration-200 cursor-pointer group"
        @click="openGigDetails(gig)"
      >
        <!-- Gig Image -->
        <div class="relative h-48 overflow-hidden">
          <img
            :src="gig.image"
            :alt="gig.title"
            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
          />
          <div class="absolute top-3 right-3">
            <span
              class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
              :class="getCategoryBadgeClass(gig.category)"
            >
              {{ getCategoryLabel(gig.category) }}
            </span>
          </div>
          <!-- Status Badge -->
          <div class="absolute top-3 left-3">
            <span :class="getStatusBadgeClass(gig.status || 'active')">
              {{ getStatusLabel(gig.status || 'active') }}
            </span>
          </div>
          <!-- Settings Button -->
          <button
            class="absolute bottom-3 right-3 p-1.5 rounded-full bg-white/80 hover:bg-white transition-colors opacity-0 group-hover:opacity-100"
            @click.stop="openSettings(gig)"
          >
            <Settings class="h-4 w-4 text-gray-600" />
          </button>
        </div>
        
        <!-- Gig Content -->
        <div class="p-4">
          <!-- User Info -->
          <div class="flex items-center mb-3">
            <img
              :src="gig.user.avatar"
              :alt="gig.user.name"
              class="h-8 w-8 rounded-full object-cover"
            />
            <div class="ml-2 flex-1 min-w-0">
              <div class="flex items-center gap-1">
                <p class="text-sm font-medium text-gray-900 truncate">{{ gig.user.name }}</p>
                <!-- Verified Badge -->
                <UIcon v-if="gig.user.kyc" name="i-heroicons-check-badge-solid" class="w-4 h-4 text-blue-500 flex-shrink-0" />
                <!-- Pro Badge -->
                <span v-if="gig.user.is_pro" class="flex-shrink-0 inline-flex items-center px-1 py-0.5 rounded text-[10px] font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white">
                  PRO
                </span>
              </div>
              <div class="flex items-center">
                <Star class="h-3 w-3 text-yellow-400 fill-current" />
                <span class="text-xs text-gray-600 ml-1">{{ gig.rating }} ({{ gig.reviews }})</span>
              </div>
            </div>
          </div>
          
          <!-- Gig Title -->
          <h3 
            class="text-sm font-semibold text-gray-900 mb-2 line-clamp-2 group-hover:text-purple-600 transition-colors cursor-pointer"
          >
            {{ gig.title }}
          </h3>
          
          <!-- Stats Row -->
          <div class="flex items-center justify-between text-xs text-gray-500 mb-2">
            <span class="flex items-center"><Eye class="h-3 w-3 mr-1" />{{ gig.views_count || 0 }}</span>
            <span class="flex items-center"><ShoppingCart class="h-3 w-3 mr-1" />{{ gig.orders_count || 0 }}</span>
          </div>
          
          <!-- Price -->
          <div class="flex justify-between items-center">
            <span class="text-xs text-gray-500">Starting at</span>
            <div class="text-lg font-bold text-gray-900 inline-flex items-center">
              <UIcon name="i-mdi:currency-bdt" class="text-lg" />{{ gig.price }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- List View -->
    <div v-if="!isLoading && filteredMyGigs.length > 0 && viewMode === 'list'" class="space-y-3">
      <div
        v-for="gig in filteredMyGigs"
        :key="gig.id"
        class="bg-white border border-gray-100 rounded-lg overflow-hidden hover:shadow-sm transition-all duration-200 cursor-pointer group"
        @click="openGigDetails(gig)"
      >
        <div class="flex">
          <!-- Gig Image -->
          <div class="relative w-40 h-32 sm:w-48 sm:h-36 flex-shrink-0 overflow-hidden">
            <img
              :src="gig.image"
              :alt="gig.title"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
            />
            <!-- Status Badge -->
            <div class="absolute top-2 left-2">
              <span :class="getStatusBadgeClass(gig.status || 'active')">
                {{ getStatusLabel(gig.status || 'active') }}
              </span>
            </div>
          </div>
          
          <!-- Gig Content -->
          <div class="flex-1 p-4 flex flex-col justify-between">
            <div>
              <!-- Category and Settings -->
              <div class="flex items-center justify-between mb-2">
                <span
                  class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                  :class="getCategoryBadgeClass(gig.category)"
                >
                  {{ getCategoryLabel(gig.category) }}
                </span>
                <button
                  class="p-1.5 rounded-full hover:bg-gray-100 transition-colors"
                  @click.stop="openSettings(gig)"
                >
                  <Settings class="h-4 w-4 text-gray-400 hover:text-gray-600" />
                </button>
              </div>
              
              <!-- Gig Title -->
              <h3 class="text-sm sm:text-base font-semibold text-gray-900 mb-2 line-clamp-2 group-hover:text-purple-600 transition-colors">
                {{ gig.title }}
              </h3>
              
              <!-- User Info -->
              <div class="flex items-center mb-2">
                <img
                  :src="gig.user.avatar"
                  :alt="gig.user.name"
                  class="h-6 w-6 rounded-full object-cover"
                />
                <div class="ml-2 flex items-center flex-wrap gap-1">
                  <p class="text-xs font-medium text-gray-900">{{ gig.user.name }}</p>
                  <!-- Verified Badge -->
                  <UIcon v-if="gig.user.kyc" name="i-heroicons-check-badge-solid" class="w-3.5 h-3.5 text-blue-500 flex-shrink-0" />
                  <!-- Pro Badge -->
                  <span v-if="gig.user.is_pro" class="flex-shrink-0 inline-flex items-center px-1 py-0.5 rounded text-[10px] font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white">
                    PRO
                  </span>
                  <Star class="h-3 w-3 text-yellow-400 fill-current ml-1" />
                  <span class="text-xs text-gray-600">{{ gig.rating }} ({{ gig.reviews }})</span>
                </div>
              </div>
            </div>
            
            <!-- Bottom Row: Stats and Price -->
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4 text-xs text-gray-500">
                <span class="flex items-center"><Eye class="h-3 w-3 mr-1" />{{ gig.views_count || 0 }} views</span>
                <span class="flex items-center"><ShoppingCart class="h-3 w-3 mr-1" />{{ gig.orders_count || 0 }} orders</span>
              </div>
              <div class="text-lg font-bold text-gray-900 inline-flex items-center"><UIcon name="i-mdi:currency-bdt" class="text-lg" />{{ gig.price }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State for My Gigs -->
    <div v-if="!isLoading && myGigs.length === 0" class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200">
      <div class="text-center">
        <div class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <Briefcase class="h-8 w-8 text-purple-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">No gigs created yet</h3>
        <p class="text-gray-600 mb-4">Start earning by creating your first gig</p>
        <button 
          @click="$emit('switchTab', 'create-gig')"
          class="inline-flex items-center px-6 py-3 rounded-lg bg-purple-600 text-white hover:bg-purple-700 transition-colors font-medium"
        >
          <Plus class="h-4 w-4 mr-2" />
          Create Your First Gig
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Star, Heart, Briefcase, Settings, LayoutGrid, List, Eye, ShoppingCart, Plus, Search, Filter, ChevronDown } from "lucide-vue-next";
import { ref, computed, watch, onMounted } from "vue";

// Emits
defineEmits(['switchTab']);

// Composables
const { user } = useAuth();
const { get } = useApi();
const toast = useToast();

// State
const viewMode = ref('list');
const searchQuery = ref('');
const selectedCategory = ref('');
const selectedStatus = ref('');
const sortBy = ref('newest');
const showFilterDropdown = ref(false);
const isLoading = ref(true);
const myGigs = ref([]);

// Fetch my gigs from API
async function fetchMyGigs() {
  isLoading.value = true;
  try {
    const params = new URLSearchParams();
    
    // Add category filter
    if (selectedCategory.value) {
      params.append('category', selectedCategory.value);
    }
    
    // Add status filter
    if (selectedStatus.value) {
      params.append('status', selectedStatus.value);
    }
    
    // Add search
    if (searchQuery.value) {
      params.append('search', searchQuery.value);
    }
    
    // Add ordering
    const orderingMap = {
      'newest': '-created_at',
      'oldest': 'created_at',
      'price-low': 'price',
      'price-high': '-price',
      'most-views': '-views_count',
      'most-orders': '-orders_count'
    };
    params.append('ordering', orderingMap[sortBy.value] || '-created_at');
    
    const { data, error } = await get(`/workspace/gigs/my/?${params.toString()}`);
    
    if (error) {
      console.error('Error fetching my gigs:', error);
      myGigs.value = [];
      return;
    }
    
    const results = data?.results || data || [];
    myGigs.value = results.map(gig => ({
      id: gig.id,
      title: gig.title,
      description: gig.description,
      price: parseFloat(gig.price),
      category: gig.category,
      status: gig.status || 'active',
      image: gig.image_url || gig.image || '/images/placeholder-gig.png',
      user: {
        id: gig.user?.id,
        name: gig.user?.name || 'Unknown User',
        avatar: gig.user?.avatar || '/images/default-avatar.png',
        is_pro: gig.user?.is_pro || false,
        kyc: gig.user?.kyc || false,
      },
      rating: gig.rating || 0,
      reviews: gig.reviews || 0,
      views_count: gig.views_count || 0,
      orders_count: gig.orders_count || 0,
      created_at: gig.created_at,
    }));
  } catch (err) {
    console.error('Error fetching my gigs:', err);
    myGigs.value = [];
  } finally {
    isLoading.value = false;
  }
}

// Watch for filter changes and refetch
watch([selectedCategory, selectedStatus, sortBy], () => {
  fetchMyGigs();
});

// Debounced search
let searchTimeout = null;
watch(searchQuery, () => {
  if (searchTimeout) clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    fetchMyGigs();
  }, 300);
});

// Fetch on mount
onMounted(() => {
  fetchMyGigs();
});

// Computed - just return the fetched gigs since filtering is done on backend
const filteredMyGigs = computed(() => {
  return myGigs.value;
});

const hasActiveFilters = computed(() => {
  return searchQuery.value || selectedCategory.value || selectedStatus.value || sortBy.value !== 'newest';
});

const activeFilterCount = computed(() => {
  let count = 0;
  if (selectedCategory.value) count++;
  if (selectedStatus.value) count++;
  if (sortBy.value !== 'newest') count++;
  return count;
});

// Methods
const openGigDetails = (gig) => {
  navigateTo(`/business-network/workspace-details?id=${gig.id}`);
};

const openSettings = (gig) => {
  toast.add({
    title: "Gig Settings",
    description: `Opening settings for "${gig.title}"`,
    color: "blue",
  });
  // TODO: Open settings modal or navigate to edit page
};

const clearFilters = () => {
  searchQuery.value = '';
  selectedCategory.value = '';
  selectedStatus.value = '';
  sortBy.value = 'newest';
  showFilterDropdown.value = false;
  fetchMyGigs();
};

const getCategoryLabel = (category) => {
  const labels = {
    design: 'Design',
    development: 'Development', 
    marketing: 'Marketing',
    writing: 'Writing',
    business: 'Business'
  };
  return labels[category] || category;
};

const getCategoryBadgeClass = (category) => {
  const classes = {
    design: 'bg-pink-100 text-pink-800',
    development: 'bg-blue-100 text-blue-800',
    marketing: 'bg-green-100 text-green-800',
    writing: 'bg-yellow-100 text-yellow-800',
    business: 'bg-purple-100 text-purple-800'
  };
  return classes[category] || 'bg-gray-100 text-gray-800';
};

const getStatusBadgeClass = (status) => {
  const classes = {
    'active': 'bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium',
    'paused': 'bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full text-xs font-medium',
    'draft': 'bg-gray-100 text-gray-800 px-2 py-1 rounded-full text-xs font-medium',
    'deleted': 'bg-red-100 text-red-800 px-2 py-1 rounded-full text-xs font-medium'
  };
  return classes[status?.toLowerCase()] || 'bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium';
};

const getStatusLabel = (status) => {
  const labels = {
    'active': 'Active',
    'paused': 'Paused',
    'draft': 'Draft',
    'deleted': 'Deleted'
  };
  return labels[status?.toLowerCase()] || 'Active';
};
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
</style>
