<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl pt-3 flex-1 min-h-screen">
    <!-- Header Section -->
    <div class="mb-6">
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 px-2 py-4">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900 flex items-center">
              <div class="w-8 h-8 bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg flex items-center justify-center mr-3">
                <Star class="h-5 w-5 text-white" />
              </div>
              Workspaces
            </h1>
            <p class="mt-1 text-gray-600 text-sm sm:text-base">Browse gigs, manage orders, and offer your services</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-100">
      <!-- Tab Navigation -->
      <div class="border-b border-gray-100">
        <!-- Desktop View -->
        <nav class="hidden sm:flex space-x-8 px-6" aria-label="Tabs">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm transition-colors flex items-center',
              activeTab === tab.id
                ? 'border-purple-500 text-purple-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
          >
            <component :is="tab.icon" class="h-4 w-4 mr-2" />
            {{ tab.name }}
          </button>
        </nav>

        <!-- Mobile View - 2x2 Grid -->
        <div class="sm:hidden px-4 py-3">
          <div class="grid grid-cols-2 gap-1">
            <button
              v-for="tab in tabs"
              :key="tab.id"
              @click="activeTab = tab.id"
              :class="[
                'py-3 px-2 rounded-lg border-2 font-medium text-xs transition-colors',
                activeTab === tab.id
                  ? 'border-purple-500 text-purple-600 bg-purple-50'
                  : 'border-gray-200 text-gray-600 hover:text-gray-800 hover:border-gray-300'
              ]"
            >
              <div class="flex items-center justify-center space-x-1">
                <component :is="tab.icon" class="h-4 w-4" />
                <span class="leading-tight">{{ tab.name }}</span>
              </div>
            </button>
          </div>
        </div>
      </div>

      <!-- Tab Content -->
      <div class="sm:px-6 p-2">
        <!-- All Gigs Tab -->
        <div v-if="activeTab === 'all-gigs'">
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
                    placeholder="Search gigs..."
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
                    <FilterIcon class="h-4 w-4" />
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
                        <option value="rating">Highest Rated</option>
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
          <div v-if="isLoading" class="grid grid-cols-2 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-2">
            <div
              v-for="n in 8"
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

          <!-- Gigs Grid View -->
          <div v-if="!isLoading && viewMode === 'grid'" class="grid grid-cols-2 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-2">
            <div
              v-for="gig in filteredGigs"
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
                <button
                  class="absolute top-3 left-3 p-1.5 rounded-full bg-white/80 hover:bg-white transition-colors opacity-0 group-hover:opacity-100"
                  @click.stop="toggleFavorite(gig.id)"
                >
                  <Heart
                    class="h-4 w-4 text-gray-600"
                    :class="{ 'fill-red-500 text-red-500': gig.isFavorited }"
                  />
                </button>
              </div>
              
              <!-- Gig Content -->
              <div class="p-4">
                <!-- User Info -->
                <div class="flex items-center mb-3">
                  <img
                    :src="gig.user.avatar"
                    :alt="gig.user.name"
                    class="h-8 w-8 rounded-full object-cover cursor-pointer hover:ring-2 hover:ring-purple-400 transition-all"
                    @click.stop="navigateToProfile(gig.user.id)"
                  />
                  <div class="ml-2 flex-1 min-w-0">
                    <div class="flex items-center gap-1">
                      <p 
                        class="text-sm font-medium text-gray-900 cursor-pointer hover:text-purple-600 transition-colors truncate"
                        @click.stop="navigateToProfile(gig.user.id)"
                      >
                        {{ gig.user.name }}
                      </p>
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
                  @click.stop="openGigDetails(gig)"
                >
                  {{ gig.title }}
                </h3>
                
                <!-- Price and Action -->
                <div class="flex justify-between items-center">
                  <div class="flex items-center space-x-2">
                    <span class="text-xs text-gray-500">Starting at</span>
                  </div>
                  <div class="text-lg font-bold text-gray-900 inline-flex items-center">
                    <UIcon name="i-mdi:currency-bdt" class="text-lg" />{{ gig.price }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Gigs List View -->
          <div v-if="!isLoading && viewMode === 'list'" class="space-y-3">
            <div
              v-for="gig in filteredGigs"
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
                  <!-- Favorite Button -->
                  <button
                    class="absolute top-2 left-2 p-1.5 rounded-full bg-white/80 hover:bg-white transition-colors"
                    @click.stop="toggleFavorite(gig.id)"
                  >
                    <Heart
                      class="h-4 w-4 text-gray-600"
                      :class="{ 'fill-red-500 text-red-500': gig.isFavorited }"
                    />
                  </button>
                </div>
                
                <!-- Gig Content -->
                <div class="flex-1 p-4 flex flex-col justify-between">
                  <div>
                    <!-- Category Badge -->
                    <div class="flex items-center justify-between mb-2">
                      <span
                        class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                        :class="getCategoryBadgeClass(gig.category)"
                      >
                        {{ getCategoryLabel(gig.category) }}
                      </span>
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
                        class="h-6 w-6 rounded-full object-cover cursor-pointer hover:ring-2 hover:ring-purple-400 transition-all"
                        @click.stop="navigateToProfile(gig.user.id)"
                      />
                      <div class="ml-2 flex items-center flex-wrap gap-1">
                        <p 
                          class="text-xs font-medium text-gray-900 cursor-pointer hover:text-purple-600 transition-colors"
                          @click.stop="navigateToProfile(gig.user.id)"
                        >
                          {{ gig.user.name }}
                        </p>
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
                      <span class="flex items-center"><Eye class="h-3 w-3 mr-1" />{{ gig.views_count || 0 }}</span>
                      <span class="flex items-center"><ShoppingCart class="h-3 w-3 mr-1" />{{ gig.orders_count || 0 }}</span>
                    </div>
                    <div class="text-lg font-bold text-gray-900 inline-flex items-center"><UIcon name="i-mdi:currency-bdt" class="text-lg" />{{ gig.price }}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Empty state -->
          <div
            v-if="!isLoading && filteredGigs.length === 0"
            class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
          >
            <div class="text-center">
              <div class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Briefcase class="h-8 w-8 text-purple-600" />
              </div>
              <h3 class="text-lg font-semibold text-gray-900 mb-2">No gigs found</h3>
              <p class="text-gray-600 mb-4">
                Try adjusting your search criteria or browse different categories
              </p>
              <button
                @click="clearFilters"
                class="inline-flex items-center px-4 py-2 rounded-lg bg-purple-100 text-purple-700 hover:bg-purple-200 transition-colors"
              >
                Clear Filters
              </button>
            </div>
          </div>
        </div>

        <!-- My Gigs Tab -->
        <div v-else-if="activeTab === 'my-gigs'">
          <MyGigs @switchTab="activeTab = $event" />
        </div>

        <!-- Order Received Tab -->
        <div v-else-if="activeTab === 'my-orders'">
          <MyOrders @switchTab="activeTab = $event" />
        </div>

        <!-- Gig Ordered Tab -->
        <div v-else-if="activeTab === 'gig-ordered'">
          <GigOrdered @switchTab="activeTab = $event" />
        </div>

        <!-- Create Gig Tab -->
        <div v-else-if="activeTab === 'create-gig'">
          <CreateGig @gigCreated="handleGigCreated" @switchTab="activeTab = $event" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from "vue";
import { Star, Plus, Search, Heart, Briefcase, ShoppingCart, User, Package, LayoutGrid, List, Eye, Filter as FilterIcon, ChevronDown } from "lucide-vue-next";
import MyOrders from "~/components/business-network/MyOrders.vue";
import CreateGig from "~/components/business-network/CreateGig.vue";
import MyGigs from "~/components/business-network/MyGigs.vue";
import GigOrdered from "~/components/business-network/GigOrdered.vue";

// Page meta
definePageMeta({
  layout: "adsy-business-network",
  title: "Workspaces - Business Network",
  meta: [
    {
      name: "description",
      content: "Browse and discover professional gigs and services from talented individuals",
    },
    {
      name: "keywords",
      content: "gigs, services, freelance, workspace, business network, hire professionals",
    },
  ],
});

// Composables
const { user } = useAuth();
const { get, post } = useApi();
const toast = useToast();

// Tab State
const activeTab = ref('all-gigs');

// Tab Configuration
const tabs = ref([
  {
    id: 'all-gigs',
    name: 'All Gigs',
    icon: Star,
    count: null
  },
  {
    id: 'my-gigs',
    name: 'My Gigs',
    icon: User,
    count: null
  },
  {
    id: 'my-orders',
    name: 'Order Received',
    icon: ShoppingCart,
    count: 0
  },
  {
    id: 'gig-ordered',
    name: 'Gig Ordered',
    icon: Package,
    count: 0
  },
  {
    id: 'create-gig',
    name: 'Post A Gig',
    icon: Plus,
    count: null
  }
]);

// State
const isLoading = ref(true);
const searchQuery = ref("");
const selectedCategory = ref("");
const sortBy = ref("newest");
const viewMode = ref("grid");
const showFilterDropdown = ref(false);

// Gigs data from API
const gigs = ref([]);

// Fetch gigs from API
async function fetchGigs() {
  isLoading.value = true;
  try {
    const params = new URLSearchParams();
    if (selectedCategory.value) {
      params.append('category', selectedCategory.value);
    }
    if (searchQuery.value) {
      params.append('search', searchQuery.value);
    }
    
    // Map sort options to API ordering
    const orderingMap = {
      'newest': '-created_at',
      'oldest': 'created_at',
      'price-low': 'price',
      'price-high': '-price',
      'rating': '-views_count'
    };
    params.append('ordering', orderingMap[sortBy.value] || '-created_at');
    
    console.log('Fetching gigs from API...');
    const { data, error } = await get(`/workspace/gigs/?${params.toString()}`);
    console.log('API Response:', { data, error });
    
    if (error) {
      console.error('Error fetching gigs:', error);
      toast.add({
        title: 'Error',
        description: 'Failed to load gigs. Please try again.',
        color: 'red',
      });
      return;
    }
    
    // Transform API data to match frontend format
    const results = data?.results || data || [];
    console.log('Gigs results:', results.length, 'gigs found');
    
    gigs.value = results.map((gig) => ({
      id: gig.id,
      title: gig.title,
      price: parseFloat(gig.price),
      category: gig.category,
      image: gig.image_url || gig.image || '/images/placeholder-gig.png',
      user: {
        id: gig.user?.id,
        name: gig.user?.name || 'Unknown User',
        avatar: gig.user?.avatar || '/images/default-avatar.png',
        is_pro: gig.user?.is_pro,
        kyc: gig.user?.kyc,
      },
      rating: gig.rating || 0,
      reviews: gig.reviews || 0,
      isFavorited: gig.is_favorited || false,
      delivery_time: gig.delivery_time,
      revisions: gig.revisions,
      views_count: gig.views_count,
      orders_count: gig.orders_count,
    }));
    
    console.log('Gigs loaded:', gigs.value.length);
    
  } catch (err) {
    console.error('Error fetching gigs:', err);
  } finally {
    isLoading.value = false;
  }
}

// Watch for filter changes
watch([selectedCategory, sortBy], () => {
  fetchGigs();
});

// Debounced search
let searchTimeout = null;
watch(searchQuery, () => {
  if (searchTimeout) clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    fetchGigs();
  }, 300);
});

// Computed properties - now just returns gigs since filtering is done on API
const filteredGigs = computed(() => {
  return gigs.value;
});

const hasActiveFilters = computed(() => {
  return selectedCategory.value || sortBy.value !== 'newest';
});

const activeFilterCount = computed(() => {
  let count = 0;
  if (selectedCategory.value) count++;
  if (sortBy.value !== 'newest') count++;
  return count;
});

// My gigs computed property - filter by current user
const myGigs = computed(() => {
  if (!user.value?.user) return [];
  
  // Filter gigs created by current user
  return gigs.value.filter(gig => 
    gig.user?.id === user.value.user.id
  );
});

// Tab counts computed property
const tabCounts = computed(() => ({
  'all-gigs': filteredGigs.value.length,
  'my-gigs': myGigs.value.length,
  'my-orders': 0, // Would be dynamic from API
  'create-gig': null
}));

// Methods
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

const toggleFavorite = async (gigId) => {
  if (!user.value?.user) {
    toast.add({
      title: "Authentication Required",
      description: "Please login to save favorites",
      color: "amber",
    });
    return;
  }

  try {
    const { data, error } = await post(`/workspace/gigs/${gigId}/favorite/`);
    
    if (error) {
      toast.add({
        title: "Error",
        description: "Failed to update favorite status",
        color: "red",
      });
      return;
    }
    
    // Update local state
    const gig = gigs.value.find(g => g.id === gigId);
    if (gig) {
      gig.isFavorited = data.is_favorited;
      toast.add({
        title: data.is_favorited ? "Added to Favorites" : "Removed from Favorites",
        description: `"${gig.title}" has been ${data.is_favorited ? 'added to' : 'removed from'} your favorites`,
        color: data.is_favorited ? "green" : "gray",
      });
    }
  } catch (err) {
    console.error('Error toggling favorite:', err);
  }
};

const openGigDetails = (gig) => {
  console.log('Opening gig details:', gig);
  
  // Navigate to the workspace details page using query parameters
  try {
    navigateTo(`/business-network/workspace-details?id=${gig.id}`);
  } catch (error) {
    console.error('Navigation error:', error);
    // Fallback navigation
    window.location.href = `/business-network/workspace-details?id=${gig.id}`;
  }
};

const navigateToProfile = (userId) => {
  if (!userId) return;
  
  try {
    navigateTo(`/business-network/profile/${userId}`);
  } catch (error) {
    console.error('Navigation error:', error);
    window.location.href = `/business-network/profile/${userId}`;
  }
};

const clearFilters = () => {
  searchQuery.value = "";
  selectedCategory.value = "";
  sortBy.value = "newest";
  showFilterDropdown.value = false;
  fetchGigs();
};

// Gig Creation Handler
const handleGigCreated = (gigData) => {
  // Refresh gigs list to include the new gig
  fetchGigs();
  
  // Switch to all gigs tab to show the new gig
  activeTab.value = 'all-gigs';
  
  toast.add({
    title: "Gig Created",
    description: "Your gig has been created successfully!",
    color: "green",
  });
};

// Fetch gigs on mount
onMounted(() => {
  fetchGigs();
});
</script>

<style scoped>
/* Prevent layout shifts and improve scrolling */
.mx-auto {
  scroll-behavior: smooth;
}

/* Prevent transitions on layout-affecting properties */
* {
  transition-property: background-color, border-color, color, fill, stroke, opacity, box-shadow;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 150ms;
}

/* Ensure stable layout */
.space-y-4 {
  contain: layout;
}

/* Content container for stable layouts */
.content-container {
  contain: layout style;
  will-change: auto;
}

/* Prevent content jumping */
.min-h-\[400px\] {
  min-height: 400px;
  contain: layout style;
}

/* Fix scrollbar stability */
html {
  overflow-y: scroll;
}

/* Force proper viewport behavior */
@media (max-width: 640px) {
  html,
  body {
    max-width: 100%;
    overflow-x: hidden;
  }
}

/* Prevent layout shift on empty states */
.py-16 {
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Stabilize loading states */
.animate-pulse {
  contain: layout;
}

/* Prevent scrollbar jumping */
body {
  scrollbar-gutter: stable;
}

/* Custom line clamp utility */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Hover effects for gig cards */
.group:hover .group-hover\:scale-105 {
  transform: scale(1.05);
}

.group:hover .group-hover\:text-purple-600 {
  color: rgb(147 51 234);
}

.group:hover .group-hover\:opacity-100 {
  opacity: 1;
}

/* Grid responsive adjustments */
@media (min-width: 1280px) {
  .xl\:grid-cols-4 {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}

@media (min-width: 1024px) {
  .lg\:grid-cols-3 {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (min-width: 768px) {
  .md\:grid-cols-2 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

/* Smooth animations for favorites */
.heart-animation {
  transition: all 0.2s ease-in-out;
}

.heart-animation:hover {
  transform: scale(1.1);
}

/* Hide scrollbar for horizontal scroll */
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
</style>
