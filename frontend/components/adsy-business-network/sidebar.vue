<template>
  <div>
    <!-- Mobile Overlay (shows when sidebar is open on mobile) -->
    <div 
      v-if="isMobile && isOpen" 
      class="fixed inset-0 bg-black/50 z-40 lg:hidden"
      @click="toggleSidebar"
    ></div>

    <!-- Sidebar -->
    <aside 
      :class="[
        'fixed top-0 bottom-0 left-0 z-50 flex flex-col bg-white border-r border-gray-200 transition-all duration-300 ease-in-out overflow-hidden',
        isMobile ? (isOpen ? 'translate-x-0 w-72' : '-translate-x-full') : 'w-72',
        'lg:translate-x-0'
      ]"
    >
      <!-- Sidebar Header -->
      <div class="h-16 flex items-center justify-between px-4 border-b border-gray-100">
        <div class="flex items-center overflow-hidden">
          <div class="flex-shrink-0">
            <div class="h-8 w-8 rounded-md bg-gradient-to-r from-blue-600 to-blue-600 flex items-center justify-center text-white font-bold">
              BN
            </div>
          </div>
          <h1 class="ml-2 text-lg font-semibold bg-gradient-to-r from-blue-600 to-blue-600 bg-clip-text text-transparent whitespace-nowrap">
            Business Network
          </h1>
        </div>
        <button 
          class="lg:hidden h-8 w-8 items-center justify-center rounded-md hover:bg-gray-100 text-gray-500"
          @click="toggleSidebar"
        >
          <X class="h-5 w-5" />
        </button>
      </div>

      <!-- Sidebar Content (Scrollable) -->
      <div class="flex-1 overflow-y-auto py-4 px-3 space-y-7">
        <!-- Main Menu Section -->
        <div>
          <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center">
            <Menu class="h-3.5 w-3.5 mr-1.5" />
            <span>Menu</span>
          </h3>
          <nav class="space-y-1">
            <a 
              v-for="item in mainMenu" 
              :key="item.path" 
              :href="item.path"
              :class="[
                'flex items-center px-3 py-2.5 rounded-md transition-colors group',
                item.active 
                  ? 'bg-blue-50 text-blue-600' 
                  : 'text-gray-700 hover:bg-gray-50'
              ]"
              @click="handleNavigation(item.path)"
            >
              <component :is="item.icon" :class="['h-5 w-5 mr-3', item.active ? 'text-blue-600' : 'text-gray-500 group-hover:text-gray-600']" />
              <span class="text-sm font-medium">{{ item.label }}</span>
              <div 
                v-if="item.badge" 
                class="ml-auto bg-blue-600 text-white text-xs rounded-full min-w-[20px] h-5 flex items-center justify-center px-1"
              >
                {{ item.badge }}
              </div>
            </a>
          </nav>
        </div>

        <!-- Useful Links Section -->
        <div>
          <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center">
            <Link class="h-3.5 w-3.5 mr-1.5" />
            <span>Useful Links</span>
          </h3>
          <div class="grid grid-cols-2 gap-2 px-3">
            <a 
              v-for="item in usefulLinks" 
              :key="item.path" 
              :href="item.path"
              class="flex flex-col items-center justify-center p-3 rounded-md bg-gray-50 border border-gray-100 hover:bg-blue-50 hover:border-blue-100 transition-all shadow-sm"
              @click="handleNavigation(item.path)"
            >
              <component :is="item.icon" class="h-5 w-5 mb-2 text-blue-600" />
              <span class="text-xs font-medium text-gray-700">{{ item.label }}</span>
            </a>
          </div>
        </div>

        <!-- Adsy News Section -->
        <div>
          <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between">
            <div class="flex items-center">
              <Newspaper class="h-3.5 w-3.5 mr-1.5" />
              <span>Adsy News</span>
            </div>
            <a href="/news" class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center" @click="handleNavigation('/news')">
              <span>Top 100</span>
              <ChevronRight class="h-3 w-3 ml-0.5" />
            </a>
          </h3>
          <div class="px-3 relative">
            <div class="overflow-hidden rounded-lg border border-gray-200 shadow-sm">
              <div 
                class="transition-transform duration-300 ease-in-out flex"
                :style="{ transform: `translateX(-${currentNewsIndex * 100}%)` }"
              >
                <a 
                  v-for="(news, index) in newsItems" 
                  :key="index"
                  :href="news.path"
                  class="w-full flex-shrink-0"
                  @click="handleNavigation(news.path)"
                >
                  <div class="aspect-[16/9] w-full bg-gray-100 relative">
                    <img :src="news.image" :alt="news.title" class="w-full h-full object-cover" />
                    <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent p-3">
                      <div class="flex items-center mb-1">
                        <span class="text-xs font-medium text-white bg-blue-600 px-2 py-0.5 rounded-sm">News</span>
                        <span class="text-xs text-white/80 ml-2 flex items-center">
                          <Clock class="h-3 w-3 mr-1" />
                          {{ news.date }}
                        </span>
                      </div>
                      <h4 class="text-sm font-medium text-white line-clamp-2">{{ news.title }}</h4>
                    </div>
                  </div>
                </a>
              </div>
            </div>
            <!-- News Controls -->
            <div class="flex justify-between items-center mt-2">
              <div class="flex space-x-1">
                <button 
                  v-for="(_, index) in newsItems" 
                  :key="index"
                  @click="currentNewsIndex = index"
                  :class="[
                    'h-1.5 rounded-full transition-all',
                    currentNewsIndex === index ? 'w-4 bg-blue-600' : 'w-1.5 bg-gray-300'
                  ]"
                ></button>
              </div>
              <div class="flex space-x-1">
                <button 
                  class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                  @click="prevNews"
                >
                  <ChevronLeft class="h-3 w-3" />
                </button>
                <button 
                  class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                  @click="nextNews"
                >
                  <ChevronRight class="h-3 w-3" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Hashtags Section -->
        <div>
          <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between">
            <div class="flex items-center">
              <Hash class="h-3.5 w-3.5 mr-1.5" />
              <span>Trending Hashtags</span>
            </div>
            <a href="/hashtags" class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center" @click="handleNavigation('/hashtags')">
              <span>Top 100</span>
              <ChevronRight class="h-3 w-3 ml-0.5" />
            </a>
          </h3>
          <div class="flex flex-wrap gap-2 px-3">
            <a 
              v-for="tag in hashtags" 
              :key="tag.name" 
              :href="`/hashtag/${tag.name}`"
              class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 hover:bg-blue-50 hover:text-blue-600 transition-colors"
              @click="handleNavigation(`/hashtag/${tag.name}`)"
            >
              <span>#{{ tag.name }}</span>
              <span class="ml-1 text-gray-500">{{ tag.count }}</span>
            </a>
          </div>
        </div>

        <!-- Products Slider -->
        <div>
          <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between">
            <div class="flex items-center">
              <ShoppingBag class="h-3.5 w-3.5 mr-1.5" />
              <span>Featured Products</span>
            </div>
            <div class="flex space-x-1">
              <button 
                class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                @click="prevProduct"
              >
                <ChevronLeft class="h-3 w-3" />
              </button>
              <button 
                class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
                @click="nextProduct"
              >
                <ChevronRight class="h-3 w-3" />
              </button>
            </div>
          </h3>
          <div class="px-3 relative">
            <div class="overflow-hidden rounded-lg border border-gray-200 shadow-sm">
              <div 
                class="transition-transform duration-300 ease-in-out flex"
                :style="{ transform: `translateX(-${currentProductIndex * 100}%)` }"
              >
                <a 
                  v-for="(product, index) in products" 
                  :key="index"
                  :href="product.path"
                  class="w-full flex-shrink-0"
                  @click="handleNavigation(product.path)"
                >
                  <div class="aspect-video w-full bg-gray-100 relative">
                    <img :src="product.image" :alt="product.name" class="w-full h-full object-cover" />
                    <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent p-3">
                      <div class="flex items-center justify-between mb-1">
                        <span class="text-white text-xs font-bold">${{ product.price }}</span>
                        <span class="text-xs bg-red-500 text-white px-1.5 py-0.5 rounded-sm">{{ product.discount }}% OFF</span>
                      </div>
                      <h4 class="text-white text-sm font-medium line-clamp-1">{{ product.name }}</h4>
                    </div>
                  </div>
                </a>
              </div>
            </div>
            <!-- Dots indicator -->
            <div class="flex justify-center mt-2 space-x-1">
              <button 
                v-for="(_, index) in products" 
                :key="index"
                @click="currentProductIndex = index"
                :class="[
                  'h-1.5 rounded-full transition-all',
                  currentProductIndex === index ? 'w-4 bg-blue-600' : 'w-1.5 bg-gray-300'
                ]"
              ></button>
            </div>
          </div>
        </div>

        <!-- Top Contributors -->
        <div>
          <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between">
            <div class="flex items-center">
              <Users class="h-3.5 w-3.5 mr-1.5" />
              <span>Top Contributors</span>
            </div>
            <a href="/contributors" class="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center" @click="handleNavigation('/contributors')">
              <span>Top 100</span>
              <ChevronRight class="h-3 w-3 ml-0.5" />
            </a>
          </h3>
          <div class="space-y-2">
            <a 
              v-for="(user, index) in topContributors.slice(0, 2)" 
              :key="index"
              :href="`/profile/${user.id}`"
              class="flex items-center px-3 py-2 rounded-md hover:bg-gray-50 transition-colors"
              @click="handleNavigation(`/profile/${user.id}`)"
            >
              <div class="relative">
                <img :src="user.avatar" :alt="user.name" class="h-10 w-10 rounded-full object-cover border-2 border-white shadow-sm" />
                <div class="absolute -top-1 -right-1 bg-blue-600 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center border border-white">
                  {{ user.rank }}
                </div>
              </div>
              <div class="ml-3 min-w-0">
                <h4 class="text-sm font-medium text-gray-800 truncate">{{ user.name }}</h4>
                <p class="text-xs text-gray-500 flex items-center">
                  <FileText class="h-3 w-3 mr-1" />
                  <span>{{ user.posts }} posts</span>
                  <Users class="h-3 w-3 mx-1" />
                  <span>{{ user.followers }}</span>
                </p>
              </div>
              <div class="ml-auto">
                <div class="text-xs px-1.5 py-0.5 bg-blue-50 text-blue-600 rounded-md border border-blue-100">
                  <Trophy class="h-3 w-3" />
                </div>
              </div>
            </a>
          </div>
        </div>
      </div>

      <!-- Sidebar Footer -->
      <div class="p-4 border-t border-gray-100 bg-gray-50">
        <div class="flex items-center">
          <div class="relative">
            <img 
              src="/images/placeholder.jpg?height=40&width=40" 
              alt="User avatar" 
              class="h-9 w-9 rounded-full object-cover border-2 border-white shadow-sm"
            />
            <div class="absolute bottom-0 right-0 h-3 w-3 bg-green-500 rounded-full border border-white"></div>
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium text-gray-700">Tom Cook</p>
            <p class="text-xs text-gray-500">View profile</p>
          </div>
          <div class="ml-auto flex space-x-1">
            <button class="p-1.5 rounded-full hover:bg-gray-200 text-gray-500">
              <Settings class="h-4 w-4" />
            </button>
            <button class="p-1.5 rounded-full hover:bg-gray-200 text-gray-500">
              <LogOut class="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </aside>

    <!-- Mobile Toggle Button -->
    <button 
      class="fixed bottom-24 left-4 md:top-4 md:bottom-auto z-30 lg:hidden h-10 w-10 rounded-full bg-white shadow-lg border border-gray-200 flex items-center justify-center"
      @click="toggleSidebar"
    >
      <Menu class="h-5 w-5 text-gray-600" />
    </button>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { 
  Home, User, Bell, Settings, ShoppingBag, DollarSign, 
  Store, Hash, ChevronLeft, ChevronRight, X, Menu, 
  Newspaper, LogOut, Award, Zap, Smartphone, Clock,
  Link, Users, FileText, Trophy
} from 'lucide-vue-next';

// State
const isOpen = ref(false);
const isMobile = ref(false);
const currentProductIndex = ref(0);
const currentNewsIndex = ref(0);

// Main Menu Items
const mainMenu = [
  { 
    label: 'Recent', 
    path: '/', 
    icon: Home,
    active: true
  },
  { 
    label: 'Profile', 
    path: '/profile', 
    icon: User,
    active: false
  },
  { 
    label: 'Notifications', 
    path: '/notifications', 
    icon: Bell,
    badge: 5,
    active: false
  },
  { 
    label: 'Settings', 
    path: '/settings', 
    icon: Settings,
    active: false
  }
];

// Useful Links
const usefulLinks = [
  {
    label: 'eShop',
    path: '/shop',
    icon: ShoppingBag
  },
  {
    label: 'Earn Money',
    path: '/earn',
    icon: DollarSign
  },
  {
    label: 'Sell Products',
    path: '/sell',
    icon: Store
  },
  {
    label: 'Mobile Recharge',
    path: '/recharge',
    icon: Smartphone
  }
];

// News Items
const newsItems = [
  {
    title: 'New marketplace features launched for business owners',
    date: 'Today',
    path: '/news/marketplace-features',
    image: '/images/placeholder.jpg?height=160&width=280'
  },
  {
    title: 'Business Network reaches 1 million users milestone',
    date: 'Yesterday',
    path: '/news/million-users',
    image: '/images/placeholder.jpg?height=160&width=280'
  },
  {
    title: 'Upcoming webinar: Digital Marketing Trends for 2023',
    date: '3 days ago',
    path: '/news/webinar-marketing',
    image: '/images/placeholder.jpg?height=160&width=280'
  }
];

// Hashtags
const hashtags = [
  { name: 'business', count: 1243 },
  { name: 'marketing', count: 982 },
  { name: 'startup', count: 753 },
  { name: 'innovation', count: 621 },
  { name: 'technology', count: 589 },
  { name: 'leadership', count: 432 }
];

// Products
const products = [
  {
    name: 'Business Strategy Masterclass',
    price: 49.99,
    discount: 20,
    image: '/images/placeholder.jpg?height=150&width=250',
    path: '/product/business-strategy'
  },
  {
    name: 'Marketing Analytics Tool',
    price: 29.99,
    discount: 15,
    image: '/images/placeholder.jpg?height=150&width=250',
    path: '/product/marketing-analytics'
  },
  {
    name: 'Leadership Development Course',
    price: 79.99,
    discount: 25,
    image: '/images/placeholder.jpg?height=150&width=250',
    path: '/product/leadership'
  }
];

// Top Contributors
const topContributors = [
  {
    id: 1,
    name: 'Emma Johnson',
    avatar: '/images/placeholder.jpg?height=40&width=40',
    posts: 142,
    followers: 2.5 + 'k',
    rank: '1'
  },
  {
    id: 2,
    name: 'Liam Smith',
    avatar: '/images/placeholder.jpg?height=40&width=40',
    posts: 98,
    followers: 1.8 + 'k',
    rank: '2'
  },
  {
    id: 3,
    name: 'Olivia Williams',
    avatar: '/images/placeholder.jpg?height=40&width=40',
    posts: 87,
    followers: 1.2 + 'k',
    rank: '3'
  }
];

// Methods
const toggleSidebar = () => {
  isOpen.value = !isOpen.value;
  
  // Prevent body scroll when sidebar is open on mobile
  if (isOpen.value && isMobile.value) {
    document.body.style.overflow = 'hidden';
  } else {
    document.body.style.overflow = '';
  }
};

const handleNavigation = (path) => {
  // Close sidebar on mobile when navigating
  if (isMobile.value) {
    isOpen.value = false;
    document.body.style.overflow = '';
  }
  
  // In a real app, you would use router.push(path) here
  console.log(`Navigating to: ${path}`);
};

const nextProduct = () => {
  currentProductIndex.value = (currentProductIndex.value + 1) % products.length;
};

const prevProduct = () => {
  currentProductIndex.value = (currentProductIndex.value - 1 + products.length) % products.length;
};

const nextNews = () => {
  currentNewsIndex.value = (currentNewsIndex.value + 1) % newsItems.length;
};

const prevNews = () => {
  currentNewsIndex.value = (currentNewsIndex.value - 1 + newsItems.length) % newsItems.length;
};

const checkMobile = () => {
  isMobile.value = window.innerWidth < 1024; // lg breakpoint
  
  // Auto-close sidebar on mobile when resizing
  if (isMobile.value) {
    isOpen.value = false;
  }
};

// Lifecycle hooks
onMounted(() => {
  // Initial check for mobile
  checkMobile();
  
  // Add resize listener
  window.addEventListener('resize', checkMobile);
  
  // Auto-rotate products every 5 seconds
  const productInterval = setInterval(() => {
    nextProduct();
  }, 5000);
  
  // Auto-rotate news every 7 seconds
  const newsInterval = setInterval(() => {
    nextNews();
  }, 7000);
  
  // Cleanup
  onUnmounted(() => {
    window.removeEventListener('resize', checkMobile);
    clearInterval(productInterval);
    clearInterval(newsInterval);
  });
});
</script>

<style scoped>
/* Ensure smooth scrolling */
.overflow-y-auto {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.overflow-y-auto::-webkit-scrollbar {
  width: 4px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: transparent;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 20px;
}

/* Line clamp for text truncation */
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