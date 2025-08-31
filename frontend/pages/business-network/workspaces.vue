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
          <div class="grid grid-cols-2 gap-2">
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
      <div class="sm:p-6 p-1">
        <!-- All Gigs Tab -->
        <div v-if="activeTab === 'all-gigs'">
          <!-- Filters and Search Bar -->
          <div class="mb-6">
            <!-- Desktop Layout -->
            <div class="hidden sm:flex sm:items-center sm:justify-between gap-4">
              <!-- Search Bar -->
              <div class="flex-1 max-w-md">
                <div class="relative">
                  <Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <input
                    v-model="searchQuery"
                    type="text"
                    placeholder="Search gigs..."
                    class="w-full pl-10 pr-4 py-1.5 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                  />
                </div>
              </div>
              
              <!-- Filter Buttons -->
              <div class="flex items-center space-x-3">
                <select 
                  v-model="selectedCategory"
                  class="px-3 py-1.5 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                >
                  <option value="">All Categories</option>
                  <option value="design">Design & Creative</option>
                  <option value="development">Programming & Tech</option>
                  <option value="writing">Writing & Translation</option>
                  <option value="marketing">Digital Marketing</option>
                  <option value="business">Business & Consulting</option>
                </select>
                
                <select 
                  v-model="sortBy"
                  class="px-3 py-1.5 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                >
                  <option value="newest">Newest First</option>
                  <option value="oldest">Oldest First</option>
                  <option value="price-low">Price: Low to High</option>
                  <option value="price-high">Price: High to Low</option>
                  <option value="rating">Highest Rated</option>
                </select>
              </div>
            </div>

            <!-- Mobile Layout -->
            <div class="sm:hidden space-y-3">
              <!-- Filter Buttons First -->
              <div class="flex items-center space-x-3">
                <select 
                  v-model="selectedCategory"
                  class="flex-1 px-3 py-1.5 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                >
                  <option value="">All Categories</option>
                  <option value="design">Design & Creative</option>
                  <option value="development">Programming & Tech</option>
                  <option value="writing">Writing & Translation</option>
                  <option value="marketing">Digital Marketing</option>
                  <option value="business">Business & Consulting</option>
                </select>
                
                <select 
                  v-model="sortBy"
                  class="flex-1 px-3 py-1.5 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                >
                  <option value="newest">Newest First</option>
                  <option value="oldest">Oldest First</option>
                  <option value="price-low">Price: Low to High</option>
                  <option value="price-high">Price: High to Low</option>
                  <option value="rating">Highest Rated</option>
                </select>
              </div>
              
              <!-- Search Bar Below -->
              <div class="relative">
                <Search class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  v-model="searchQuery"
                  type="text"
                  placeholder="Search gigs..."
                  class="w-full pl-10 pr-4 py-1.5 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 transition-colors"
                />
              </div>
            </div>
          </div>

          <!-- Gigs Grid -->
          <div class="grid grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-2">
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
                    class="h-8 w-8 rounded-full object-cover"
                  />
                  <div class="ml-2">
                    <p class="text-sm font-medium text-gray-900">{{ gig.user.name }}</p>
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
                  <div class="text-lg font-bold text-gray-900">
                    ${{ gig.price }}
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
          <MyGigs :gigs="dummyGigs" @switchTab="activeTab = $event" />
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
import { Star, Plus, Search, Heart, Briefcase, ShoppingCart, User, Package } from "lucide-vue-next";
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

// Dummy gigs data
const dummyGigs = ref([
  {
    id: 1,
    title: "I will design a modern and professional logo for your business",
    price: 25,
    category: "design",
    image: "https://images.unsplash.com/photo-1626785774573-4b799315345d?w=400&h=300&fit=crop",
    sellerId: 1, // This gig belongs to current user for demo
    user: {
      name: "Sarah Johnson",
      avatar: "https://images.unsplash.com/photo-1494790108755-2616b612b789?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.9,
    reviews: 127,
    isFavorited: false,
    views: 1234,
    orders: 15,
    impressions: 2890,
    features: [
      "Custom logo design in multiple formats",
      "3 initial concepts to choose from",
      "Unlimited revisions until you're satisfied",
      "High-resolution files (PNG, SVG, PDF)",
      "Commercial usage rights included"
    ],
    deliveryTime: "3",
    revisions: "unlimited"
  },
  {
    id: 2,
    title: "I will develop a responsive React web application for your startup",
    price: 150,
    category: "development",
    image: "https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=400&h=300&fit=crop",
    user: {
      name: "Mike Chen",
      avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face",
    },
    rating: 5.0,
    reviews: 89,
    isFavorited: true,
    features: [
      "Fully responsive web application",
      "Modern React with hooks and context",
      "API integration and state management",
      "Cross-browser compatibility testing",
      "2 weeks of post-launch support"
    ],
    deliveryTime: "14",
    revisions: "3"
  },
  {
    id: 3,
    title: "I will write compelling copy for your marketing campaigns",
    price: 45,
    category: "writing",
    image: "https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=400&h=300&fit=crop",
    sellerId: 1, // This gig also belongs to current user for demo
    user: {
      name: "Emma Davis",
      avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.8,
    reviews: 203,
    isFavorited: false,
    views: 987,
    orders: 8,
    impressions: 1456,
  },
  {
    id: 4,
    title: "I will create engaging social media content and strategy",
    price: 75,
    category: "marketing",
    image: "https://images.unsplash.com/photo-1611926653458-09294b3142bf?w=400&h=300&fit=crop",
    user: {
      name: "Alex Rodriguez",
      avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.7,
    reviews: 156,
    isFavorited: false,
  },
  {
    id: 5,
    title: "I will provide business consultation and strategic planning",
    price: 200,
    category: "business",
    image: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=300&fit=crop",
    user: {
      name: "David Wilson",
      avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.9,
    reviews: 74,
    isFavorited: false,
  },
  {
    id: 6,
    title: "I will create stunning UI/UX designs for mobile applications",
    price: 120,
    category: "design",
    image: "https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=400&h=300&fit=crop",
    user: {
      name: "Lisa Park",
      avatar: "https://images.unsplash.com/photo-1544723795-3fb6469f5b39?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.8,
    reviews: 91,
    isFavorited: true,
  },
  {
    id: 7,
    title: "I will build a custom WordPress website with e-commerce functionality",
    price: 300,
    category: "development",
    image: "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&h=300&fit=crop",
    user: {
      name: "James Thompson",
      avatar: "https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.9,
    reviews: 67,
    isFavorited: false,
  },
  {
    id: 8,
    title: "I will translate your content to multiple languages professionally",
    price: 35,
    category: "writing",
    image: "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=400&h=300&fit=crop",
    user: {
      name: "Maria Garcia",
      avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.6,
    reviews: 134,
    isFavorited: false,
  },
]);

// Computed properties
const filteredGigs = computed(() => {
  let filtered = [...dummyGigs.value];

  // Filter by search query
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(gig => 
      gig.title.toLowerCase().includes(query) ||
      gig.user.name.toLowerCase().includes(query)
    );
  }

  // Filter by category
  if (selectedCategory.value) {
    filtered = filtered.filter(gig => gig.category === selectedCategory.value);
  }

  // Sort
  switch (sortBy.value) {
    case 'popular':
      filtered.sort((a, b) => (b.rating * b.reviews) - (a.rating * a.reviews));
      break;
    case 'price-low':
      filtered.sort((a, b) => a.price - b.price);
      break;
    case 'price-high':
      filtered.sort((a, b) => b.price - a.price);
      break;
    case 'newest':
    default:
      // Keep original order (newest first)
      break;
  }

  return filtered;
});

// My gigs computed property - filter by current user
const myGigs = computed(() => {
  if (!user.value?.user) return [];
  
  // Filter gigs created by current user
  return dummyGigs.value.filter(gig => 
    gig.user.name === user.value.user.username || 
    gig.user.name === user.value.user.first_name + ' ' + user.value.user.last_name ||
    gig.sellerId === user.value.user.id
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

const toggleFavorite = (gigId) => {
  if (!user.value?.user) {
    toast.add({
      title: "Authentication Required",
      description: "Please login to save favorites",
      color: "amber",
    });
    return;
  }

  const gig = dummyGigs.value.find(g => g.id === gigId);
  if (gig) {
    gig.isFavorited = !gig.isFavorited;
    toast.add({
      title: gig.isFavorited ? "Added to Favorites" : "Removed from Favorites",
      description: `"${gig.title}" has been ${gig.isFavorited ? 'added to' : 'removed from'} your favorites`,
      color: gig.isFavorited ? "green" : "gray",
    });
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

const clearFilters = () => {
  searchQuery.value = "";
  selectedCategory.value = "";
  sortBy.value = "newest";
};

// Gig Creation Handler
const handleGigCreated = (gigData) => {
  // Create the new gig object
  const newGigData = {
    id: dummyGigs.value.length + 1,
    title: gigData.title,
    price: gigData.price,
    category: gigData.category,
    image: "https://images.unsplash.com/photo-1626785774573-4b799315345d?w=400&h=300&fit=crop",
    user: gigData.user,
    rating: 0,
    reviews: 0,
    isFavorited: false,
  };

  // Add to gigs list
  dummyGigs.value.unshift(newGigData);
  
  // Switch to all gigs tab to show the new gig
  activeTab.value = 'all-gigs';
};

// Simulate loading state
onMounted(() => {
  isLoading.value = true;
  setTimeout(() => {
    isLoading.value = false;
  }, 1200);
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
</style>
