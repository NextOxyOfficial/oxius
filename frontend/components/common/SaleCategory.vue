<template>
  <div class="for-sale-section py-6 bg-white">
    <div class="container mx-auto px-2">
      <!-- Updated section header with linked buttons -->
      <div class="section-header sm:mb-8 mb-5 flex justify-between items-center">
        <div class="flex items-center gap-3">
          <h2 class="text-xl md:text-xl font-semibold">For Sale</h2>
          
        </div>
        <div  v-if="user" class="flex gap-2 sm:gap-3">
          <button 
            class="my-post-btn border border-gray-300 hover:bg-gray-50 rounded-md px-2 py-1 sm:px-3 sm:py-1.5 text-sm sm:text-sm flex items-center gap-1"
            @click="openMyPostsModal"
          >
            <Icon name="heroicons:document-text" size="16px" />
            My Posts
          </button>
          <button 
            class="post-sale-btn bg-primary hover:bg-primary/90 text-white rounded-md px-2 py-1 sm:px-3 sm:py-1.5 text-sm sm:text-sm flex items-center gap-1"
            @click="openPostSaleModal"
          >
            <Icon name="heroicons:plus-circle" size="16px" />
            Post a Sale
          </button>
        </div>
      </div>
      
      <!-- Dynamic banner ads with responsive layout -->
      <div class="banner-container mb-4 sm:mb-8">
        <div class="flex flex-col md:flex-row gap-2">
          <!-- Show loading placeholder when banners are loading -->
          <template v-if="isLoadingBanners">
            <div class="main-banner rounded-lg overflow-hidden md:w-1/2">
              <div class="w-full h-16 sm:h-20 md:h-32 bg-gray-200 animate-pulse"></div>
            </div>
            <div class="secondary-banner rounded-lg overflow-hidden md:w-1/2">
              <div class="w-full h-16 sm:h-20 md:h-32 bg-gray-200 animate-pulse"></div>
            </div>
          </template>
          
          <!-- Display banners when loaded -->
          <template v-else>
            <!-- Main banner -->
            <div v-if="banners.length > 0" class="main-banner rounded-lg overflow-hidden cursor-pointer md:w-1/2">
              <a :href="banners[0]?.link || '#'" class="block">
                <img 
                  :src="getImageUrl(banners[0]?.image)" 
                  :alt="banners[0]?.title || 'Promotion'" 
                  class="w-full h-16 sm:h-20 md:h-32 object-cover" 
                />
              </a>
            </div>
            
            <!-- Secondary banner -->
            <div v-if="banners.length > 1" class="secondary-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2">
              <a :href="banners[1]?.link || '#'" class="block">
                <img 
                  :src="getImageUrl(banners[1]?.image)" 
                  :alt="banners[1]?.title || 'Offer'" 
                  class="w-full h-16 sm:h-20 md:h-32 object-cover" 
                />
              </a>
            </div>
            
            <!-- Fallback banners if API returns empty data -->
            <div v-if="banners.length === 0" class="main-banner rounded-md overflow-hidden cursor-pointer md:w-1/2">
              <img src="https://via.placeholder.com/1200x80/3B82F6/FFFFFF?text=Special+Promotion" alt="Promotion" class="w-full h-16 sm:h-20 md:h-32 object-cover" />
            </div>
            
            <div v-if="banners.length <= 1" class="secondary-banner rounded-sm overflow-hidden cursor-pointer md:w-1/2">
              <img src="https://via.placeholder.com/1200x80/4F46E5/FFFFFF?text=Limited+Time+Offer" alt="Offer" class="w-full h-16 sm:h-20 md:h-32 object-cover" />
            </div>
          </template>
        </div>
      </div>
      
      <div class="category-tabs relative mb-6">
        <!-- Navigation buttons (only visible on mobile) -->
        <button 
          v-if="isMobile"
          @click="slideLeft" 
          class="slider-nav-btn left-0 transition-opacity duration-300 opacity-25 hover:opacity-70" 
          :class="{ 'cursor-not-allowed': isAtStart }"
          :disabled="isAtStart"
        >
          <Icon name="heroicons:chevron-left" size="18px" />
        </button>

        <!-- Categories slider with touch events -->
        <div 
          class="overflow-hidden" 
          ref="sliderContainer"
          @touchstart="handleTouchStart"
          @touchmove="handleTouchMove"
          @touchend="handleTouchEnd"
        >
          <div 
            class="categories-wrapper flex transition-all duration-500 ease-out mt-3"
            :style="{ transform: `translateX(-${scrollPosition}px)` }"
            ref="categoriesWrapper"
          >
            <!-- Show category loading placeholders when categories are loading -->
            <template v-if="isLoadingCategories">
              <div 
                v-for="index in 6" 
                :key="`placeholder-${index}`"
                class="category-item flex-shrink-0"
                :class="[isMobile ? 'w-1/5' : 'w-1/6']"
              >
                <div class="category-card transition-all duration-200 cursor-pointer h-full mx-1">
                  <div class="flex items-center justify-center h-full">
                    <div class="text-center py-2">
                      <div class="icon-container mx-auto mb-1 flex items-center justify-center bg-gray-200 rounded-full animate-pulse">
                        <div class="h-8 w-8"></div>
                      </div>
                      <div class="h-4 bg-gray-200 rounded w-16 mx-auto animate-pulse"></div>
                    </div>
                  </div>
                </div>
              </div>
            </template>
            
            <!-- Show loaded categories -->
            <template v-else>
              <div 
                v-for="(category) in categories" 
                :key="category.id"
                class="category-item flex-shrink-0"
                :class="[isMobile ? 'w-1/5' : 'w-1/6']"
                @click="selectCategory(category)"
              >
                <div 
                  class="category-card transition-all duration-200 cursor-pointer h-full mx-1"
                  :class="{ 
                    'category-active': selectedCategory === category.id,
                    'category-inactive': selectedCategory !== category.id
                  }"
                >
                  <div class="flex items-center justify-center h-full">
                    <div class="text-center py-2">
                      <div class="icon-container mx-auto mb-1 flex items-center justify-center">
                        <img v-if="category.icon" :src="getImageUrl(category.icon)" :alt="category.name" class="size-9 object-contain" />
                        <Icon v-else :name="getCategoryIcon(category.name)" size="22px" />
                      </div>
                      <span class="category-name font-medium text-sm">{{ category.name }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </div>

        <button 
          v-if="isMobile"
          @click="slideRight" 
          class="slider-nav-btn right-0 transition-opacity duration-300 opacity-25 hover:opacity-70"
          :class="{ 'cursor-not-allowed': isAtEnd }"
          :disabled="isAtEnd"
        >
          <Icon name="heroicons:chevron-right" size="18px" />
        </button>
      </div>

      <!-- Display section for selected category items with lazy loading -->
      <div class="selected-category-items mt-4" v-if="selectedCategory">
        <div class="flex justify-between items-center mb-3">
          <div>
            <h3 class="text-lg font-bold">{{ getSelectedCategoryName() }}</h3>
          </div>
          <NuxtLink :to="`/sale/for-sale?category=${selectedCategory}`" class="view-all-btn bg-primary hover:bg-primary/90 text-white rounded-md px-3 py-1 text-sm flex items-center gap-1">
            View All <Icon name="heroicons:arrow-right" size="14px" />
          </NuxtLink>
        </div>
        
        <!-- Lazy loading skeleton when loading -->
        <div v-if="isLoading" class="grid grid-cols-2 md:grid-cols-5 gap-2">
          <div v-for="i in (isMobile ? 4 : 5)" :key="i" class="item-card bg-white rounded-lg shadow-sm overflow-hidden border border-gray-100 animate-pulse">
            <div class="h-32 bg-gray-200"></div>
            <div class="p-3">
              <div class="h-4 bg-gray-200 rounded mb-2"></div>
              <div class="h-3 bg-gray-200 rounded w-3/4 mb-2"></div>
              <div class="flex justify-between items-center">
                <div class="h-5 bg-gray-200 rounded-full w-1/4"></div>
                <div class="h-6 w-6 rounded-full bg-gray-200"></div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Placeholder for items in the selected category -->
        <div v-else class="grid grid-cols-2 md:grid-cols-5 gap-2">
          <div v-for="i in (isMobile ? 4 : 5)" :key="i" class="item-card bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow overflow-hidden border border-gray-100">
            <div class="relative h-32 bg-gradient-to-br from-gray-200 to-gray-100">
              <span class="absolute top-2 left-2 bg-red-500 text-white text-xs px-2 py-0.5 rounded-md">Sale</span>
            </div>
            <div class="p-3">
              <div class="h-4 bg-gray-100 rounded mb-2"></div>
              <div class="h-3 bg-gray-100 rounded w-3/4 mb-2"></div>
              <div class="flex justify-between items-center">
                <div class="h-5 bg-primary/10 rounded-full w-1/4"></div>
                <div class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center">
                  <Icon name="heroicons:heart" size="12px" class="text-gray-400" />
                </div>
              </div>
            </div>
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

      <div v-if="user?.user" class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-3xl sm:w-full">
        <div class="bg-white px-2 pt-5 pb-4 sm:p-6 sm:pb-4">
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
              <PostSale :categories="categories" />
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

      <div v-if="user?.user" class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
        <div class="bg-white px-2 pt-5 pb-4 sm:p-6 sm:pb-4">
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
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useApi } from '~/composables/useApi';
import PostSale from '~/components/sale/PostSale.vue';
import MyPosts from '~/components/sale/MyPosts.vue';
const {user} =useAuth()

const { get } = useApi();

// State for categories and banners now from API
const categories = ref([]);
const banners = ref([]);
const selectedCategory = ref(null);
const scrollPosition = ref(0);
const sliderContainer = ref(null);
const categoriesWrapper = ref(null);
const isLoading = ref(false);
const isMobile = ref(false);

// Add loading states for initial data fetching
const isLoadingCategories = ref(true);
const isLoadingBanners = ref(true);

// Touch handling variables
const touchStartX = ref(0);
const touchEndX = ref(0);
const minSwipeDistance = 50;

const isAtStart = computed(() => scrollPosition.value <= 0);
const isAtEnd = computed(() => {
  if (!categoriesWrapper.value || !sliderContainer.value) return true;
  return scrollPosition.value + sliderContainer.value.clientWidth >= categoriesWrapper.value.scrollWidth;
});

// Helper function to construct full image URL
const getImageUrl = (path) => {
  if (!path) return '';
  const { staticURL } = useApi();
  
  // If path already starts with http(s) or //, it's a full URL
  if (path.match(/^(https?:)?\/\//)) {
    return path;
  }
  
  // Otherwise prepend static URL
  return `${staticURL}${path}`;
}

// Get appropriate icon for a category based on its name
const getCategoryIcon = (categoryName) => {
  const iconMap = {
    'Properties': 'heroicons:home-modern',
    'Vehicles': 'heroicons:truck',
    'Electronics': 'heroicons:device-phone-mobile',
    'Sports': 'heroicons:trophy',
    'B2B': 'heroicons:building-office',
    'Fashion': 'heroicons:shopping-bag',
    'Services': 'heroicons:wrench',
    'Jobs': 'heroicons:briefcase',
    'Pets': 'heroicons:heart',
    'Books': 'heroicons:book-open',
    'Furniture': 'heroicons:table',
  };
  
  return iconMap[categoryName] || 'heroicons:squares-plus'; // Default to 'squares-plus' for unknown categories
};

// Select a category with lazy loading simulation
const selectCategory = (category) => {
  if (selectedCategory.value === category.id) return;
  
  isLoading.value = true;
  selectedCategory.value = category.id;
  
  // Simulate API request delay - in a real app, you would fetch actual items for this category
  setTimeout(() => {
    isLoading.value = false;
  }, 800);
};

// Get the name of the selected category
const getSelectedCategoryName = () => {
  const found = categories.value.find(cat => cat.id === selectedCategory.value);
  return found ? found.name : '';
};

// Slide the categories left
const slideLeft = () => {
  if (scrollPosition.value <= 0) return;
  
  // On mobile, we show 5 categories at once out of 6
  const containerWidth = sliderContainer.value.clientWidth;
  const itemWidth = containerWidth / 5; // Show 5 items on mobile
  scrollPosition.value = Math.max(0, scrollPosition.value - itemWidth);
};

// Slide the categories right
const slideRight = () => {
  if (!categoriesWrapper.value || !sliderContainer.value) return;
  
  const containerWidth = sliderContainer.value.clientWidth;
  const maxScroll = categoriesWrapper.value.scrollWidth - containerWidth;
  
  if (scrollPosition.value >= maxScroll) return;
  
  const itemWidth = containerWidth / 5; // Show 5 items on mobile
  scrollPosition.value = Math.min(maxScroll, scrollPosition.value + itemWidth);
};

// Touch event handlers
const handleTouchStart = (e) => {
  touchStartX.value = e.changedTouches[0].screenX;
};

const handleTouchMove = (e) => {
  // Prevent default to stop page scrolling while swiping categories
  e.preventDefault();
};

const handleTouchEnd = (e) => {
  touchEndX.value = e.changedTouches[0].screenX;
  handleSwipe();
};

const handleSwipe = () => {
  const distance = touchStartX.value - touchEndX.value;
  
  if (Math.abs(distance) < minSwipeDistance) return;
  
  if (distance > 0) {
    // Swipe left to right (show more categories)
    slideRight();
  } else {
    // Swipe right to left (show previous categories)
    slideLeft();
  }
};

// Fetch categories from the backend
const fetchCategories = async () => {
  try {
    isLoadingCategories.value = true;
    const response = await get('/api/for-sale-categories/');
    if (response.data && Array.isArray(response.data)) {
      categories.value = response.data;
      
      // Set initial category if available
      if (categories.value.length > 0) {
        selectedCategory.value = categories.value[0].id;
      }
    } else {
      // Fallback to default categories if API returns invalid data
      console.error('Invalid category data received from API');
      setDefaultCategories();
    }
  } catch (error) {
    console.error('Error fetching sale categories:', error);
    // Fallback to default categories if API fails
    setDefaultCategories();
  } finally {
    isLoadingCategories.value = false;
  }
};

// Fetch banners from the backend
const fetchBanners = async () => {
  try {
    isLoadingBanners.value = true;
    const response = await get('/api/for-sale-banners/');
    if (response.data && Array.isArray(response.data)) {
      banners.value = response.data;
    }
  } catch (error) {
    console.error('Error fetching sale banners:', error);
    // Banners will remain an empty array if API fails
  } finally {
    isLoadingBanners.value = false;
  }
};

// Set default categories if API fails
const setDefaultCategories = () => {
  categories.value = [
    { id: 1, name: 'Properties', icon: 'heroicons:home-modern' },
    { id: 2, name: 'Vehicles', icon: 'heroicons:truck' },
    { id: 3, name: 'Electronics', icon: 'heroicons:device-phone-mobile' },
    { id: 4, name: 'Sports', icon: 'heroicons:trophy' },
    { id: 5, name: 'B2B', icon: 'heroicons:building-office' },
    { id: 6, name: 'Others', icon: 'heroicons:squares-plus' },
  ];
  selectedCategory.value = categories.value[0].id;
};

// Handle screen resize
const checkIfMobile = () => {
  isMobile.value = window.innerWidth < 768;
  
  // Reset scroll position when switching between mobile and desktop
  if (!isMobile.value) {
    scrollPosition.value = 0;
  }
};

// Initialize on mount
onMounted(async () => {
  // Fetch data from API
  await Promise.all([fetchCategories(), fetchBanners()]);
  
  // Check device type initially
  checkIfMobile();
  
  // Add resize event listener
  window.addEventListener('resize', checkIfMobile);
});

// Clean up event listener
onUnmounted(() => {
  window.removeEventListener('resize', checkIfMobile);
});

// Modal states
const showPostSaleModal = ref(false);
const showMyPostsModal = ref(false);

// Open modals for buttons
const openMyPostsModal = () => {
  showMyPostsModal.value = true;
  showPostSaleModal.value = false;
};

const closeMyPostsModal = () => {
  showMyPostsModal.value = false;
};

const openPostSaleModal = () => {
  showPostSaleModal.value = true;
  showMyPostsModal.value = false;
};

const closePostSaleModal = () => {
  showPostSaleModal.value = false;
};

const switchToPostSaleModal = () => {
  showMyPostsModal.value = false;
  showPostSaleModal.value = true;
};

// Post actions
const handleEditPost = (post) => {
  // Here you would implement edit functionality, possibly pre-filling the PostSale form
  console.log('Edit post:', post);
  // For now, just open the post sale modal
  openPostSaleModal();
};

const handleDeletePost = (postId) => {
  // Here you would implement delete functionality, possibly making an API call
  console.log('Delete post with ID:', postId);
  // In a real app, you would remove the post from the listings after successful deletion
};
</script>

<style scoped>
.category-tabs {
  position: relative;
  width: calc(100% - 4px);
  margin: 0 auto;
}

.slider-nav-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  z-index: 10;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background-color: white;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
  cursor: pointer;
}

.category-card {
  border-bottom: 2px solid transparent;
  border-radius: 0;
  background-color: white;
}

.category-active {
  border-color: #3B82F6;
  background-color: rgb(249 250 251);
}

.category-inactive:hover {
  background-color: rgb(249 250 251);
}

.icon-container {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.categories-wrapper {
  touch-action: pan-x;
}

/* Animation for loading skeleton */
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.animate-pulse {
  animation: pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Responsive settings */
@media (min-width: 768px) {
  /* Desktop: show all 6 categories */
  .category-item {
    width: 16.666667%; /* 1/6 */
  }

  /* Hide navigation buttons on desktop as all categories are visible */
  .slider-nav-btn {
    display: none;
  }
}

@media (max-width: 767px) {
  /* Mobile: show 5 categories at once */
  .category-item {
    width: 20%; /* 1/5 */
  }

  /* Show navigation buttons on mobile */
  .slider-nav-btn {
    display: flex;
  }
}

/* Add extra small breakpoint for button labels */
@media (min-width: 480px) {
  .xs\:inline {
    display: inline;
  }
}

/* Banner styles */
.banner-container {
  width: 100%;
}
</style>