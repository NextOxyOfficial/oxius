<template>
  <div class="mx-auto sm:px-6 lg:px-8 max-w-7xl pt-3 flex-1 min-h-screen">
    <!-- Header Section -->
    <div class="mb-2">
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
            @click="navigateToTab(tab.id)"
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm transition-colors flex items-center',
              tab.id === 'all-gigs'
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
              @click="navigateToTab(tab.id)"
              :class="[
                'py-3 px-2 rounded-lg border-2 font-medium text-xs transition-colors',
                tab.id === 'all-gigs'
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

      <!-- Tab Content - Gig Details -->
      <div class="sm:px-6 pt-4 px-1">
        <!-- Loading State -->
        <div v-if="isLoading" class="animate-pulse py-6">
          <!-- Breadcrumb skeleton -->
          <div class="flex items-center space-x-2 mb-6">
            <div class="h-4 w-20 bg-gray-200 rounded"></div>
            <div class="h-4 w-4 bg-gray-200 rounded"></div>
            <div class="h-4 w-32 bg-gray-200 rounded"></div>
          </div>

          <!-- Main content skeleton -->
          <div class="aspect-video rounded-lg bg-gray-200 mb-4"></div>
          <div class="h-8 w-3/4 bg-gray-200 rounded mb-4"></div>
          <div class="flex items-center mb-6 p-4 bg-gray-50 rounded-lg">
            <div class="h-12 w-12 rounded-full bg-gray-200 mr-4"></div>
            <div class="flex-1">
              <div class="h-5 w-32 bg-gray-200 rounded mb-2"></div>
              <div class="h-4 w-24 bg-gray-200 rounded"></div>
            </div>
          </div>
          <div class="space-y-2 mb-6">
            <div class="h-4 w-full bg-gray-200 rounded"></div>
            <div class="h-4 w-5/6 bg-gray-200 rounded"></div>
            <div class="h-4 w-4/5 bg-gray-200 rounded"></div>
          </div>
          <div class="h-12 w-32 bg-gray-200 rounded"></div>
        </div>

        <!-- Gig Not Found -->
        <div v-else-if="!gig" class="text-center py-16">
          <div class="mx-auto h-24 w-24 rounded-full bg-gray-100 flex items-center justify-center mb-4">
            <AlertTriangle class="h-12 w-12 text-gray-400" />
          </div>
          <h3 class="text-xl font-medium text-gray-900 mb-2">Workspace Not Found</h3>
          <p class="text-gray-600 mb-6">The workspace you're looking for doesn't exist or has been removed.</p>
          <NuxtLink 
            to="/business-network/workspaces"
            class="inline-flex items-center px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 transition-colors"
          >
            <ArrowLeft class="w-4 h-4 mr-2" />
            Back to Workspaces
          </NuxtLink>
        </div>

        <!-- Gig Details -->
        <div v-else>
          <!-- Breadcrumb -->
          <nav class="flex items-center space-x-2 text-sm text-gray-600 pt-1 pb-3">
            <NuxtLink to="/business-network/workspaces" class="hover:text-purple-600 transition-colors">
              Workspaces
            </NuxtLink>
            <ChevronRight class="h-4 w-4" />
            <span class="text-gray-900 font-medium">{{ gig.title }}</span>
          </nav>

          <!-- Main Content -->
          <div class="bg-white rounded-xl overflow-hidden">
            <div class="p-2">
              <!-- Hero Image Slider -->
              <div class="relative mb-8">
                <div class="aspect-video rounded-lg overflow-hidden bg-gray-100 relative">
                  <!-- Slider Container -->
                  <div 
                    class="flex transition-transform duration-300 ease-in-out h-full"
                    :style="{ transform: `translateX(-${currentImageIndex * 100}%)` }"
                  >
                    <div 
                      v-for="(image, index) in gigImages" 
                      :key="index"
                      class="w-full h-full flex-shrink-0"
                    >
                      <img
                        :src="image"
                        :alt="`${gig.title} - Image ${index + 1}`"
                        class="w-full h-full object-cover"
                      />
                    </div>
                  </div>
                  
                  <!-- Navigation Arrows -->
                  <button 
                    v-if="gigImages.length > 1"
                    @click="prevImage"
                    class="absolute left-2 top-1/2 -translate-y-1/2 w-10 h-10 bg-white/80 hover:bg-white rounded-full flex items-center justify-center shadow-md transition-all"
                  >
                    <ChevronLeft class="w-6 h-6 text-gray-700" />
                  </button>
                  <button 
                    v-if="gigImages.length > 1"
                    @click="nextImage"
                    class="absolute right-2 top-1/2 -translate-y-1/2 w-10 h-10 bg-white/80 hover:bg-white rounded-full flex items-center justify-center shadow-md transition-all"
                  >
                    <ChevronRight class="w-6 h-6 text-gray-700" />
                  </button>
                </div>
                
                <!-- Dots Indicator -->
                <div v-if="gigImages.length > 1" class="flex justify-center gap-2 mt-4">
                  <button
                    v-for="(_, index) in gigImages"
                    :key="index"
                    @click="currentImageIndex = index"
                    :class="[
                      'w-2.5 h-2.5 rounded-full transition-all',
                      currentImageIndex === index 
                        ? 'bg-purple-600 w-6' 
                        : 'bg-gray-300 hover:bg-gray-400'
                    ]"
                  />
                </div>
              </div>

            <!-- Title and Description -->
            <div class="mb-8">
              <h1 class="text-2xl font-bold text-gray-900 mb-4">{{ gig.title }}</h1>
              
              <!-- Seller Info -->
              <div class="flex items-center mb-6 p-4 bg-gray-50 rounded-lg">
                <!-- Avatar with Pro ring -->
                <div class="relative mr-4">
                  <div 
                    v-if="gig.user.is_pro"
                    class="absolute inset-0 rounded-full border-2 border-transparent bg-gradient-to-r from-amber-400 to-orange-500 p-[2px]"
                  >
                    <div class="w-full h-full rounded-full bg-gray-50"></div>
                  </div>
                  <img
                    :src="gig.user.avatar"
                    :alt="gig.user.name"
                    class="relative h-12 w-12 rounded-full object-cover cursor-pointer hover:ring-2 hover:ring-purple-400 transition-all"
                    @click="navigateToProfile(gig.user.id)"
                  />
                </div>
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <h3 
                      class="font-semibold text-gray-900 cursor-pointer hover:text-purple-600 transition-colors"
                      @click="navigateToProfile(gig.user.id)"
                    >
                      {{ gig.user.name }}
                    </h3>
                    <!-- Verified Badge -->
                    <UIcon v-if="gig.user.kyc" name="i-heroicons-check-badge-solid" class="w-5 h-5 text-blue-500" title="Verified" />
                    <!-- Pro Badge -->
                    <span v-if="gig.user.is_pro" class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white">
                      PRO
                    </span>
                  </div>
                  <div class="flex items-center mt-1">
                    <div class="flex items-center">
                      <Star 
                        v-for="i in 5" 
                        :key="i" 
                        class="h-4 w-4"
                        :class="i <= Math.round(gig.rating) ? 'text-yellow-400 fill-current' : 'text-gray-300'"
                      />
                    </div>
                    <span class="text-sm text-gray-600 ml-2">
                      {{ gig.rating }} 
                      (<button 
                        @click="scrollToReviews" 
                        class="text-purple-600 hover:text-purple-700 hover:underline transition-colors cursor-pointer"
                      >{{ gig.reviews }} reviews</button>)
                    </span>
                  </div>
                </div>
              </div>

              <!-- Description -->
              <div class="prose max-w-none">
                <h3 class="text-lg font-semibold text-gray-900 mb-3">About This Gig</h3>
                <p class="text-gray-600 leading-relaxed mb-4">
                  {{ getGigDescription(gig) }}
                </p>
                
                <h4 class="font-semibold text-gray-900 mb-3">What You'll Get:</h4>
                <ul class="space-y-2">
                  <li v-for="feature in getGigFeatures(gig)" :key="feature" class="flex items-start">
                    <Check class="h-5 w-5 text-green-500 mr-2 mt-0.5 flex-shrink-0" />
                    <span class="text-gray-600">{{ feature }}</span>
                  </li>
                </ul>

                <h4 class="font-semibold text-gray-900 mb-3 mt-6">Skills & Expertise:</h4>
                <div class="flex flex-wrap gap-2 mb-8">
                  <span
                    v-for="skill in getGigSkills(gig)"
                    :key="skill"
                    class="px-3 py-1 bg-purple-100 text-purple-700 rounded-full text-sm font-medium"
                  >
                    {{ skill }}
                  </span>
                </div>

                <!-- Pricing and Package Details -->
                <div class="bg-white rounded-lg border border-gray-200 p-3 mb-8">
                  <div class="grid grid-cols-1 md:grid-cols-2 mb-6">
                    <!-- Left: Price -->
                    <div class="text-center md:text-left">
                      <div class="text-3xl font-bold text-gray-900 mb-2 inline-flex items-center">
                        <UIcon name="i-mdi:currency-bdt" class="text-3xl" />{{ gig.price }}
                      </div>
                      <p class="text-gray-600 text-sm">Starting price</p>
                    </div>

                    <!-- Right: Package Features -->
                    <div class="space-y-3">
                      <div class="flex items-center justify-between text-sm">
                        <span class="text-gray-600">Delivery Time</span>
                        <span class="font-medium text-gray-900">3-5 days</span>
                      </div>
                      <div class="flex items-center justify-between text-sm">
                        <span class="text-gray-600">Revisions</span>
                        <span class="font-medium text-gray-900">3 included</span>
                      </div>
                      <div class="flex items-center justify-between text-sm">
                        <span class="text-gray-600">Category</span>
                        <span class="font-medium text-purple-600">{{ getCategoryLabel(gig.category) }}</span>
                      </div>
                    </div>
                  </div>

                  <!-- Action Buttons -->
                  <div class="flex flex-col sm:flex-row gap-3 mb-6">
                    <button
                      @click="handleOrder"
                      class="flex-1 bg-purple-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-purple-700 transition-colors"
                    >
                      <span class="inline-flex items-center">Order (<UIcon name="i-mdi:currency-bdt" />{{ gig.price }})</span>
                    </button>
                    <button
                      @click="handleContact"
                      class="flex-1 border border-gray-300 text-gray-700 py-3 px-4 rounded-lg font-medium hover:bg-gray-50 transition-colors inline-flex items-center justify-center gap-2"
                    >
                      <img src="/images/chat_icon.png" alt="AdsyConnect" class="w-5 h-5" />
                      Contact Seller
                    </button>
                  </div>

                  <!-- Trust Indicators and Share -->
                  <div class="pt-6 border-t border-gray-200">
                    <div class="flex items-center justify-center space-x-6 text-sm text-gray-600">
                      <div class="flex items-center">
                        <Eye class="h-4 w-4 mr-1" />
                        <span>{{ formatViewCount(gig.views_count || 0) }} views</span>
                      </div>
                      <div class="flex items-center">
                        <Clock class="h-4 w-4 mr-1" />
                        <span>{{ getActiveStatus(gig.updated_at) }}</span>
                      </div>
                      <button
                        @click="handleShare"
                        class="flex items-center space-x-2 text-sm text-gray-600 hover:text-purple-600 transition-colors"
                      >
                        <Share2 class="h-4 w-4" />
                        <span>Share</span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Related Gigs Section -->
            <div class="border-t pt-8 mb-8">
              <div class="flex items-center justify-between mb-6">
                <h3 class="text-lg font-semibold text-gray-900">Similar gigs you may like</h3>
                <NuxtLink 
                  to="/business-network/workspaces"
                  class="text-purple-600 hover:text-purple-700 text-sm font-medium transition-colors"
                >
                  View All
                </NuxtLink>
              </div>
              
              <!-- Mobile: 1 gig, Desktop: 2 gigs grid -->
              <div 
                ref="relatedGigsContainer"
                class="grid grid-cols-1 sm:grid-cols-2 gap-4"
              >
                <div 
                  v-for="relatedGig in relatedGigs.slice(0, 2)" 
                  :key="relatedGig.id"
                  class="bg-white rounded-lg border border-gray-200 hover:border-purple-300 transition-all hover:shadow-sm cursor-pointer"
                  @click="navigateTo(`/business-network/workspace-details?id=${relatedGig.id}`)"
                >
                  <!-- Gig Image -->
                  <div class="aspect-video rounded-t-lg overflow-hidden">
                    <img
                      :src="relatedGig.image"
                      :alt="relatedGig.title"
                      class="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                    />
                  </div>
                  
                  <!-- Gig Content -->
                  <div class="p-4">
                    <h4 class="font-semibold text-gray-900 mb-2 line-clamp-2 hover:text-purple-600 transition-colors">
                      {{ relatedGig.title }}
                    </h4>
                    
                    <!-- Seller Info -->
                    <div class="flex items-center mb-3">
                      <img
                        :src="relatedGig.user.avatar"
                        :alt="relatedGig.user.name"
                        class="h-6 w-6 rounded-full mr-2 cursor-pointer hover:ring-2 hover:ring-purple-400 transition-all"
                        @click.stop="navigateToProfile(relatedGig.user.id)"
                      />
                      <div class="flex items-center gap-1 flex-1 min-w-0">
                        <span 
                          class="text-sm text-gray-600 cursor-pointer hover:text-purple-600 transition-colors truncate"
                          @click.stop="navigateToProfile(relatedGig.user.id)"
                        >
                          {{ relatedGig.user.name }}
                        </span>
                        <!-- Verified Badge -->
                        <UIcon v-if="relatedGig.user.kyc" name="i-heroicons-check-badge-solid" class="w-4 h-4 text-blue-500 flex-shrink-0" />
                        <!-- Pro Badge -->
                        <span v-if="relatedGig.user.is_pro" class="flex-shrink-0 inline-flex items-center px-1 py-0.5 rounded text-[10px] font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white">
                          PRO
                        </span>
                      </div>
                    </div>
                    
                    <!-- Rating and Price -->
                    <div class="flex items-center justify-between">
                      <div class="flex items-center">
                        <Star class="h-4 w-4 text-yellow-400 fill-current mr-1" />
                        <span class="text-sm font-medium text-gray-900">{{ relatedGig.rating }}</span>
                        <span class="text-sm text-gray-500 ml-1">({{ relatedGig.reviews }})</span>
                      </div>
                      <div class="text-lg font-bold text-gray-900 inline-flex items-center">
                        <UIcon name="i-mdi:currency-bdt" class="text-lg" />{{ relatedGig.price }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Reviews Section -->
            <div id="reviews-section" class="border-t pt-8">
              <div class="flex items-center justify-between mb-6">
                <h3 class="text-lg font-semibold text-gray-900">Reviews ({{ totalReviewsCount }})</h3>
                <div class="flex items-center">
                  <Star class="h-5 w-5 text-yellow-400 fill-current mr-1" />
                  <span class="font-semibold text-gray-900">{{ gig.rating }}</span>
                  <span class="text-gray-600 ml-1">out of 5</span>
                </div>
              </div>

              <!-- Reviews Loading (Initial) -->
              <div v-if="isLoadingReviews && reviews.length === 0" class="space-y-4">
                <div v-for="i in 3" :key="i" class="bg-gray-50 rounded-lg p-4 animate-pulse">
                  <div class="flex items-start space-x-3">
                    <div class="w-10 h-10 rounded-full bg-gray-200"></div>
                    <div class="flex-1 space-y-2">
                      <div class="h-4 bg-gray-200 rounded w-1/4"></div>
                      <div class="h-3 bg-gray-200 rounded w-1/6"></div>
                      <div class="h-3 bg-gray-200 rounded w-full mt-2"></div>
                      <div class="h-3 bg-gray-200 rounded w-3/4"></div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Reviews List -->
              <div v-else-if="reviews.length > 0" class="space-y-4">
                <!-- Showing count -->
                <p class="text-sm text-gray-500 mb-4">
                  Showing {{ reviews.length }} of {{ totalReviewsCount }} reviews
                </p>
                
                <div 
                  v-for="review in reviews" 
                  :key="review.id"
                  class="bg-gray-50 rounded-lg p-4"
                >
                  <div class="flex items-start space-x-3">
                    <!-- Reviewer Avatar -->
                    <img 
                      :src="review.user.avatar || '/images/default-avatar.png'" 
                      :alt="review.user.name"
                      class="w-10 h-10 rounded-full object-cover"
                    />
                    <div class="flex-1">
                      <!-- Reviewer Info -->
                      <div class="flex items-center justify-between mb-1">
                        <div class="flex items-center gap-2">
                          <span class="font-medium text-gray-900">{{ review.user.name }}</span>
                          <!-- Verified Badge -->
                          <UIcon v-if="review.user.kyc" name="i-heroicons-check-badge-solid" class="w-4 h-4 text-blue-500" />
                          <!-- Pro Badge -->
                          <span v-if="review.user.is_pro" class="inline-flex items-center px-1 py-0.5 rounded text-[10px] font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white">
                            PRO
                          </span>
                        </div>
                        <span class="text-xs text-gray-500">{{ formatReviewDate(review.created_at) }}</span>
                      </div>
                      
                      <!-- Rating Stars -->
                      <div class="flex items-center mb-2">
                        <div class="flex">
                          <Star 
                            v-for="star in 5" 
                            :key="star"
                            class="h-4 w-4"
                            :class="star <= review.rating ? 'text-yellow-400 fill-current' : 'text-gray-300'"
                          />
                        </div>
                        <span class="text-sm text-gray-600 ml-2">{{ review.rating }}/5</span>
                      </div>
                      
                      <!-- Review Comment -->
                      <p class="text-gray-700 text-sm">{{ review.comment }}</p>
                    </div>
                  </div>
                </div>
                
                <!-- Load More Button -->
                <div v-if="hasMoreReviews" class="text-center pt-4">
                  <button
                    @click="loadMoreReviews"
                    :disabled="isLoadingMoreReviews"
                    class="inline-flex items-center px-6 py-2.5 border border-purple-300 text-purple-600 rounded-lg hover:bg-purple-50 transition-colors font-medium text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <span v-if="isLoadingMoreReviews" class="inline-flex items-center">
                      <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-purple-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Loading...
                    </span>
                    <span v-else>
                      See More Reviews ({{ totalReviewsCount - reviews.length }} remaining)
                    </span>
                  </button>
                </div>
              </div>
              
              <!-- No Reviews -->
              <div v-else-if="!isLoadingReviews" class="text-center py-8 bg-gray-50 rounded-lg">
                <Star class="h-12 w-12 text-gray-300 mx-auto mb-3" />
                <p class="text-gray-500 text-sm">No reviews yet. Be the first to review!</p>
              </div>
            </div>
          </div>
        </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { 
  Star, Eye, Clock, Check, Heart, Share2, ChevronRight, ChevronLeft, ArrowLeft, 
  AlertTriangle, User, ShoppingCart, Package, Plus
} from 'lucide-vue-next';

// Page meta
definePageMeta({
  layout: "adsy-business-network",
  title: "Workspace Details - Business Network",
});

// Router
const router = useRouter();

// Tab Configuration
const tabs = [
  { id: 'all-gigs', name: 'All Gigs', icon: Star },
  { id: 'my-gigs', name: 'My Gigs', icon: User },
  { id: 'my-orders', name: 'Order Received', icon: ShoppingCart },
  { id: 'gig-ordered', name: 'Gig Ordered', icon: Package },
  { id: 'create-gig', name: 'Post A Gig', icon: Plus }
];

// Navigate to tab
const navigateToTab = (tabId) => {
  router.push({ path: '/business-network/workspaces', query: { tab: tabId } });
};

// Composables
const route = useRoute();
const toast = useToast();
const { user } = useAuth();
const { get } = useApi();

// State
const isLoading = ref(true);
const gig = ref(null);
const relatedGigsData = ref([]);
const reviews = ref([]);
const isLoadingReviews = ref(false);
const isLoadingMoreReviews = ref(false);
const reviewsPage = ref(1);
const reviewsPerPage = 10;
const totalReviewsCount = ref(0);
const hasMoreReviews = computed(() => reviews.value.length < totalReviewsCount.value);

// Related gigs infinite scroll state
const relatedGigsContainer = ref(null);
const currentRelatedIndex = ref(0);
const isLoadingMoreRelated = ref(false);
const relatedGigsPage = ref(1);
const hasMoreRelatedGigs = ref(true);

// Image slider state
const currentImageIndex = ref(0);

// Computed: Get all gig images (main + gallery if available)
const gigImages = computed(() => {
  if (!gig.value) return [];
  
  const images = [];
  
  // Add main image
  if (gig.value.image) {
    images.push(gig.value.image);
  }
  
  // Add gallery images if available
  if (gig.value.gallery && Array.isArray(gig.value.gallery)) {
    images.push(...gig.value.gallery);
  }
  
  // If no images, return placeholder
  if (images.length === 0) {
    return ['/images/placeholder-gig.png'];
  }
  
  return images;
});

// Slider navigation methods
const nextImage = () => {
  if (currentImageIndex.value < gigImages.value.length - 1) {
    currentImageIndex.value++;
  } else {
    currentImageIndex.value = 0; // Loop back to first
  }
};

const prevImage = () => {
  if (currentImageIndex.value > 0) {
    currentImageIndex.value--;
  } else {
    currentImageIndex.value = gigImages.value.length - 1; // Loop to last
  }
};

// Helper functions
const getCategoryLabel = (category) => {
  const labels = {
    design: 'Design & Creative',
    development: 'Programming & Tech',
    writing: 'Writing & Translation',
    marketing: 'Digital Marketing',
    business: 'Business & Consulting',
  };
  return labels[category] || 'Other';
};

// Format view count (e.g., 1.2K, 5.3M)
const formatViewCount = (count) => {
  if (count >= 1000000) {
    return (count / 1000000).toFixed(1) + 'M';
  }
  if (count >= 1000) {
    return (count / 1000).toFixed(1) + 'K';
  }
  return count.toString();
};

// Get active status based on last update
const getActiveStatus = (updatedAt) => {
  if (!updatedAt) return 'Active';
  
  const now = new Date();
  const updated = new Date(updatedAt);
  const diffMs = now - updated;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  
  if (diffMins < 5) return 'Active now';
  if (diffMins < 60) return `Active ${diffMins}m ago`;
  if (diffHours < 24) return `Active ${diffHours}h ago`;
  if (diffDays < 7) return `Active ${diffDays}d ago`;
  return 'Active this week';
};

const getGigDescription = (gig) => {
  const descriptions = {
    design: "Transform your brand with professional design that captures your vision and engages your audience. I specialize in creating visually stunning designs that make a lasting impression.",
    development: "Build robust, scalable applications with modern technologies and best practices. I deliver clean, maintainable code that grows with your business needs.",
    writing: "Craft compelling content that resonates with your target audience and drives action. My writing combines creativity with strategy to achieve your business goals.",
    marketing: "Develop comprehensive marketing strategies that increase your online presence and drive meaningful engagement with your target audience.",
    business: "Get expert insights and strategic guidance to accelerate your business growth and overcome challenges with proven methodologies."
  };
  return descriptions[gig.category] || "Professional service delivery with attention to detail and commitment to excellence.";
};

const getGigFeatures = (gig) => {
  // If the gig has its own features array (from CreateGig form), use that
  if (gig.features && Array.isArray(gig.features) && gig.features.length > 0) {
    return gig.features;
  }
  
  // Otherwise, use default features based on category
  const features = {
    design: [
      "Custom design concepts",
      "Unlimited revisions", 
      "High-resolution files",
      "Commercial license included",
      "24/7 support"
    ],
    development: [
      "Responsive design",
      "Clean, documented code",
      "Browser compatibility",
      "Performance optimization",
      "Post-launch support"
    ],
    writing: [
      "Original content",
      "SEO optimization", 
      "Multiple revisions",
      "Plagiarism-free guarantee",
      "Fast turnaround"
    ],
    marketing: [
      "Strategy development",
      "Content calendar",
      "Performance analytics",
      "Competitor analysis",
      "Monthly reports"
    ],
    business: [
      "Market analysis",
      "Strategic planning",
      "ROI projections", 
      "Implementation roadmap",
      "Follow-up consultation"
    ]
  };
  return features[gig.category] || ["Professional delivery", "Quality guarantee", "Timely completion"];
};

const getGigSkills = (gig) => {
  const skills = {
    design: ["Adobe Creative Suite", "Figma", "Brand Identity", "Logo Design", "UI/UX"],
    development: ["React", "Node.js", "JavaScript", "HTML/CSS", "API Integration"],
    writing: ["Content Strategy", "SEO Writing", "Copywriting", "Technical Writing", "Proofreading"],
    marketing: ["Social Media", "Google Ads", "Content Marketing", "Analytics", "Email Marketing"],
    business: ["Strategic Planning", "Market Research", "Financial Analysis", "Project Management", "Leadership"]
  };
  return skills[gig.category] || ["Professional Service"];
};

// Computed properties
const relatedGigs = computed(() => {
  return relatedGigsData.value;
});

// Methods
const scrollToReviews = () => {
  const reviewsSection = document.getElementById('reviews-section');
  if (reviewsSection) {
    reviewsSection.scrollIntoView({
      behavior: 'smooth',
      block: 'start'
    });
  }
};

// Fetch reviews from API with pagination
const fetchReviews = async (gigId, page = 1, append = false) => {
  if (page === 1) {
    isLoadingReviews.value = true;
  } else {
    isLoadingMoreReviews.value = true;
  }
  
  try {
    const { data, error } = await get(`/workspace/gigs/${gigId}/reviews/?page=${page}&page_size=${reviewsPerPage}`);
    
    if (error) {
      console.error('Error fetching reviews:', error);
      if (!append) {
        reviews.value = [];
        totalReviewsCount.value = 0;
      }
      return;
    }
    
    // Get total count from API response
    const total = data?.count || data?.results?.length || (Array.isArray(data) ? data.length : 0);
    totalReviewsCount.value = total;
    
    const results = data?.results || data || [];
    const mappedReviews = results.map(review => ({
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      created_at: review.created_at,
      user: {
        id: review.user?.id,
        name: review.user?.name || 'Anonymous',
        avatar: review.user?.avatar || '/images/default-avatar.png',
        is_pro: review.user?.is_pro || false,
        kyc: review.user?.kyc || false,
      }
    }));
    
    if (append) {
      reviews.value = [...reviews.value, ...mappedReviews];
    } else {
      reviews.value = mappedReviews;
    }
    
    reviewsPage.value = page;
  } catch (err) {
    console.error('Error fetching reviews:', err);
    if (!append) {
      reviews.value = [];
      totalReviewsCount.value = 0;
    }
  } finally {
    isLoadingReviews.value = false;
    isLoadingMoreReviews.value = false;
  }
};

// Load more reviews
const loadMoreReviews = async () => {
  if (gig.value?.id && hasMoreReviews.value && !isLoadingMoreReviews.value) {
    await fetchReviews(gig.value.id, reviewsPage.value + 1, true);
  }
};

// Format review date
const formatReviewDate = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) {
    return 'Today';
  } else if (diffDays === 1) {
    return 'Yesterday';
  } else if (diffDays < 7) {
    return `${diffDays} days ago`;
  } else if (diffDays < 30) {
    const weeks = Math.floor(diffDays / 7);
    return `${weeks} week${weeks > 1 ? 's' : ''} ago`;
  } else if (diffDays < 365) {
    const months = Math.floor(diffDays / 30);
    return `${months} month${months > 1 ? 's' : ''} ago`;
  } else {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  }
};

const handleOrder = () => {
  if (!user.value) {
    toast.add({
      title: "Login Required",
      description: "Please login to place an order.",
      color: "orange",
    });
    return;
  }

  toast.add({
    title: "Order Process",
    description: `Proceeding to order "${gig.value.title}" for $${gig.value.price}`,
    color: "blue",
  });
};

const handleContact = () => {
  if (!user.value) {
    toast.add({
      title: "Login Required",
      description: "Please login to contact the seller.",
      color: "orange",
    });
    return;
  }

  // Navigate to AdsyConnect inbox with seller's user ID to open chat
  const sellerId = gig.value.user.id;
  router.push({
    path: '/inbox',
    query: { chat_with: sellerId }
  });
};

const handleShare = async () => {
  const shareData = {
    title: gig.value?.title || 'Check out this gig',
    text: `Check out this amazing gig: ${gig.value?.title}`,
    url: window.location.href,
  };
  
  // Try native share first (mobile)
  if (navigator.share && navigator.canShare && navigator.canShare(shareData)) {
    try {
      await navigator.share(shareData);
      return;
    } catch (err) {
      // User cancelled or share failed, fall through to clipboard
      if (err.name === 'AbortError') return;
    }
  }
  
  // Fallback to clipboard
  try {
    await navigator.clipboard.writeText(window.location.href);
    toast.add({
      title: "Link Copied!",
      description: "Gig link copied to clipboard",
      color: "green",
    });
  } catch (err) {
    // Final fallback for older browsers
    const textArea = document.createElement('textarea');
    textArea.value = window.location.href;
    document.body.appendChild(textArea);
    textArea.select();
    document.execCommand('copy');
    document.body.removeChild(textArea);
    toast.add({
      title: "Link Copied!",
      description: "Gig link copied to clipboard",
      color: "green",
    });
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

const fetchGig = async () => {
  const gigId = route.query.id;
  if (!gigId) {
    gig.value = null;
    isLoading.value = false;
    return;
  }

  isLoading.value = true;
  currentImageIndex.value = 0; // Reset slider when loading new gig
  
  try {
    // Fetch gig details from API
    const { data, error } = await get(`/workspace/gigs/${gigId}/`);
    
    if (error || !data) {
      console.error('Error fetching gig:', error);
      gig.value = null;
      toast.add({
        title: 'Error',
        description: 'Failed to load gig details.',
        color: 'red',
      });
      return;
    }
    
    // Transform API data
    gig.value = {
      id: data.id,
      title: data.title,
      description: data.description,
      price: parseFloat(data.price),
      category: data.category,
      image: data.image_url || data.image || '/images/placeholder-gig.png',
      user: {
        id: data.user?.id,
        name: data.user?.name || 'Unknown User',
        avatar: data.user?.avatar || '/images/default-avatar.png',
        is_pro: data.user?.is_pro,
        kyc: data.user?.kyc,
      },
      rating: data.rating || 0,
      reviews: data.reviews || 0,
      isFavorited: data.is_favorited || false,
      delivery_time: data.delivery_time || 3,
      revisions: data.revisions || 2,
      views_count: data.views_count || 0,
      orders_count: data.orders_count || 0,
    };
    
    // Update page title
    useHead({
      title: `${gig.value.title} - Business Network`,
      meta: [
        { name: 'description', content: data.description || getGigDescription(gig.value) }
      ]
    });
    
    // Fetch related gigs
    await fetchRelatedGigs(gig.value.category, gigId);
    
    // Reset reviews pagination and fetch first page
    reviews.value = [];
    reviewsPage.value = 1;
    totalReviewsCount.value = 0;
    await fetchReviews(gigId, 1, false);
    
  } catch (err) {
    console.error('Error fetching gig:', err);
    gig.value = null;
  } finally {
    isLoading.value = false;
  }
};

const fetchRelatedGigs = async (category, currentGigId, append = false) => {
  if (isLoadingMoreRelated.value) return;
  
  try {
    if (!append) {
      relatedGigsPage.value = 1;
      hasMoreRelatedGigs.value = true;
    }
    
    isLoadingMoreRelated.value = true;
    const { data, error } = await get(`/workspace/gigs/?category=${category}&page=${relatedGigsPage.value}&page_size=6`);
    
    if (error || !data) {
      if (!append) relatedGigsData.value = [];
      hasMoreRelatedGigs.value = false;
      return;
    }
    
    const results = data?.results || data || [];
    const filteredResults = results
      .filter(g => g.id !== currentGigId)
      .map(g => ({
        id: g.id,
        title: g.title,
        price: parseFloat(g.price),
        category: g.category,
        image: g.image_url || g.image || '/images/placeholder-gig.png',
        user: {
          id: g.user?.id,
          name: g.user?.name || 'Unknown User',
          avatar: g.user?.avatar || '/images/default-avatar.png',
          is_pro: g.user?.is_pro || false,
          kyc: g.user?.kyc || false,
        },
        rating: g.rating || 0,
        reviews: g.reviews || 0,
      }));
    
    if (append) {
      // Filter out duplicates
      const existingIds = new Set(relatedGigsData.value.map(g => g.id));
      const newGigs = filteredResults.filter(g => !existingIds.has(g.id));
      relatedGigsData.value = [...relatedGigsData.value, ...newGigs];
    } else {
      relatedGigsData.value = filteredResults;
    }
    
    // Check if there are more gigs
    hasMoreRelatedGigs.value = results.length >= 6;
  } catch (err) {
    console.error('Error fetching related gigs:', err);
    if (!append) relatedGigsData.value = [];
  } finally {
    isLoadingMoreRelated.value = false;
  }
};

// Handle scroll for infinite loading on mobile
const handleRelatedGigsScroll = (event) => {
  const container = event.target;
  const cardWidth = container.querySelector('div[class*="flex-shrink-0"]')?.offsetWidth || 300;
  
  // Update current index for dots
  currentRelatedIndex.value = Math.round(container.scrollLeft / (cardWidth + 12)); // 12 is gap
  
  // Check if scrolled near the end (within 100px)
  const isNearEnd = container.scrollLeft + container.clientWidth >= container.scrollWidth - 100;
  
  if (isNearEnd && hasMoreRelatedGigs.value && !isLoadingMoreRelated.value && gig.value) {
    relatedGigsPage.value++;
    fetchRelatedGigs(gig.value.category, gig.value.id, true);
  }
};

// Lifecycle
onMounted(() => {
  fetchGig();
});

// Watch for route changes
watch(() => route.query.id, () => {
  if (route.query.id) {
    fetchGig();
  }
});
</script>

<style scoped>
.prose {
  max-width: none;
}

.prose p {
  margin-bottom: 1rem;
}

.prose h3 {
  margin-top: 2rem;
  margin-bottom: 1rem;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.animate-fadeIn {
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
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
