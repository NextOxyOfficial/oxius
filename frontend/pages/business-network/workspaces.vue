<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl pt-3 flex-1 min-h-screen">
    <!-- Header Section -->
    <div class="mb-6">
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 px-6 py-4">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900 flex items-center">
              <div class="w-8 h-8 bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg flex items-center justify-center mr-3">
                <Star class="h-5 w-5 text-white" />
              </div>
              Workspaces
            </h1>
            <p class="mt-1 text-gray-600">Manage and organize your collaborative workspaces</p>
          </div>
          <div class="flex items-center space-x-3">
            <button
              v-if="user?.user"
              class="inline-flex items-center px-4 py-2 rounded-lg bg-gradient-to-r from-purple-500 to-purple-600 text-white hover:from-purple-600 hover:to-purple-700 transition-all duration-200 shadow-sm"
            >
              <Plus class="h-4 w-4 mr-2" />
              Create Workspace
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-100">
      <!-- Filters and Search Bar -->
      <div class="border-b border-gray-100 px-6 py-4">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
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
              class="px-3 py-1.5 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 bg-white min-w-[140px] transition-colors"
            >
              <option value="">All Categories</option>
              <option value="design">Design & Creative</option>
              <option value="development">Programming & Tech</option>
              <option value="marketing">Digital Marketing</option>
              <option value="writing">Writing & Translation</option>
              <option value="business">Business</option>
            </select>
            
            <select 
              v-model="sortBy"
              class="px-3 py-1.5 text-sm border border-gray-200 rounded-md focus:ring-1 focus:ring-purple-500 focus:border-purple-500 bg-white min-w-[120px] transition-colors"
            >
              <option value="newest">Newest</option>
              <option value="popular">Most Popular</option>
              <option value="price-low">Price: Low to High</option>
              <option value="price-high">Price: High to Low</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Content Area -->
      <div class="p-2">
        <div class="space-y-6 min-h-[400px]">
          <!-- Loading state -->
          <div v-if="isLoading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-2">
            <div
              v-for="i in 8"
              :key="i"
              class="bg-white border border-gray-100 rounded-lg overflow-hidden animate-pulse"
            >
              <div class="h-48 bg-gray-200"></div>
              <div class="p-4">
                <div class="flex items-center mb-3">
                  <div class="h-8 w-8 rounded-full bg-gray-200"></div>
                  <div class="ml-2 h-4 w-24 bg-gray-200 rounded"></div>
                </div>
                <div class="h-5 w-full bg-gray-200 rounded mb-2"></div>
                <div class="h-4 w-3/4 bg-gray-200 rounded mb-3"></div>
                <div class="flex justify-between items-center">
                  <div class="h-4 w-20 bg-gray-200 rounded"></div>
                  <div class="h-6 w-16 bg-gray-200 rounded"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- Gigs Grid -->
          <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-2">
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
                <h3 class="text-sm font-semibold text-gray-900 mb-2 line-clamp-2 group-hover:text-purple-600 transition-colors">
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
      </div>
    </div>
  </div>
</template>

<script setup>
import { Star, Plus, Search, Heart, Briefcase } from "lucide-vue-next";

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
    user: {
      name: "Sarah Johnson",
      avatar: "https://images.unsplash.com/photo-1494790108755-2616b612b789?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.9,
    reviews: 127,
    isFavorited: false,
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
  },
  {
    id: 3,
    title: "I will write compelling copy for your marketing campaigns",
    price: 45,
    category: "writing",
    image: "https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=400&h=300&fit=crop",
    user: {
      name: "Emma Davis",
      avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.8,
    reviews: 203,
    isFavorited: false,
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
  // TODO: Implement gig details modal or navigation
  console.log('Opening gig details:', gig);
  toast.add({
    title: "Gig Details",
    description: `Viewing details for: ${gig.title}`,
    color: "blue",
  });
};

const clearFilters = () => {
  searchQuery.value = "";
  selectedCategory.value = "";
  sortBy.value = "newest";
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
