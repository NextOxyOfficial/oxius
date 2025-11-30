<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl pt-3 flex-1 min-h-screen">
    <!-- Loading State -->
    <div v-if="isLoading" class="animate-pulse">
      <!-- Breadcrumb skeleton -->
      <div class="flex items-center space-x-2 mb-6">
        <div class="h-4 w-20 bg-gray-200 rounded"></div>
        <div class="h-4 w-4 bg-gray-200 rounded"></div>
        <div class="h-4 w-32 bg-gray-200 rounded"></div>
      </div>

      <!-- Main content skeleton -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="p-6 lg:p-8">
          <!-- Hero Image skeleton -->
          <div class="relative mb-8">
            <div class="aspect-video rounded-lg bg-gray-200 mb-4"></div>
            <!-- Gallery thumbnails skeleton -->
            <div class="flex space-x-2">
              <div v-for="i in 4" :key="i" class="w-16 h-16 rounded-md bg-gray-200"></div>
            </div>
          </div>

          <!-- Title skeleton -->
          <div class="mb-8">
            <div class="h-8 w-3/4 bg-gray-200 rounded mb-4"></div>
            
            <!-- Seller info skeleton -->
            <div class="flex items-center mb-6 p-4 bg-gray-50 rounded-lg">
              <div class="h-12 w-12 rounded-full bg-gray-200 mr-4"></div>
              <div class="flex-1">
                <div class="h-5 w-32 bg-gray-200 rounded mb-2"></div>
                <div class="h-4 w-24 bg-gray-200 rounded"></div>
              </div>
              <div class="h-10 w-24 bg-gray-200 rounded"></div>
            </div>

            <!-- Description skeleton -->
            <div class="space-y-4 mb-8">
              <div class="h-6 w-40 bg-gray-200 rounded"></div>
              <div class="space-y-2">
                <div class="h-4 w-full bg-gray-200 rounded"></div>
                <div class="h-4 w-5/6 bg-gray-200 rounded"></div>
                <div class="h-4 w-4/5 bg-gray-200 rounded"></div>
              </div>
              
              <div class="h-5 w-32 bg-gray-200 rounded mt-6"></div>
              <div class="space-y-2">
                <div v-for="i in 5" :key="i" class="flex items-center">
                  <div class="h-4 w-4 bg-gray-200 rounded mr-2"></div>
                  <div class="h-4 w-48 bg-gray-200 rounded"></div>
                </div>
              </div>

              <div class="h-5 w-40 bg-gray-200 rounded mt-6"></div>
              <div class="flex flex-wrap gap-2">
                <div v-for="i in 5" :key="i" class="h-8 w-20 bg-gray-200 rounded-full"></div>
              </div>
            </div>

            <!-- Pricing skeleton -->
            <div class="bg-white rounded-lg border border-gray-200 p-6 mb-8">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                <!-- Price skeleton -->
                <div class="text-center md:text-left">
                  <div class="h-12 w-24 bg-gray-200 rounded mb-2"></div>
                  <div class="h-4 w-20 bg-gray-200 rounded"></div>
                </div>
                <!-- Package details skeleton -->
                <div class="space-y-3">
                  <div v-for="i in 3" :key="i" class="flex justify-between items-center">
                    <div class="h-4 w-20 bg-gray-200 rounded"></div>
                    <div class="h-4 w-16 bg-gray-200 rounded"></div>
                  </div>
                </div>
              </div>
              
              <!-- Action buttons skeleton -->
              <div class="flex flex-col sm:flex-row gap-3 mb-6">
                <div class="flex-1 h-12 bg-gray-200 rounded-lg"></div>
                <div class="flex-1 h-12 bg-gray-200 rounded-lg"></div>
              </div>
              
              <!-- Trust indicators skeleton -->
              <div class="pt-6 border-t border-gray-200">
                <div class="flex items-center justify-center space-x-6">
                  <div class="h-4 w-16 bg-gray-200 rounded"></div>
                  <div class="h-4 w-20 bg-gray-200 rounded"></div>
                  <div class="h-4 w-12 bg-gray-200 rounded"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- Reviews skeleton -->
          <div class="border-t pt-8">
            <div class="flex items-center justify-between mb-6">
              <div class="h-6 w-32 bg-gray-200 rounded"></div>
              <div class="h-6 w-24 bg-gray-200 rounded"></div>
            </div>
            
            <!-- Sample review skeleton -->
            <div class="p-4 bg-gray-50 rounded-lg">
              <div class="flex items-start mb-3">
                <div class="h-8 w-8 rounded-full bg-gray-200 mr-3"></div>
                <div>
                  <div class="h-4 w-24 bg-gray-200 rounded mb-1"></div>
                  <div class="h-3 w-20 bg-gray-200 rounded"></div>
                </div>
              </div>
              <div class="space-y-2">
                <div class="h-3 w-full bg-gray-200 rounded"></div>
                <div class="h-3 w-3/4 bg-gray-200 rounded"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
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
      <nav class="flex items-center space-x-2 text-sm text-gray-600 mb-6">
        <NuxtLink to="/business-network/workspaces" class="hover:text-purple-600 transition-colors">
          Workspaces
        </NuxtLink>
        <ChevronRight class="h-4 w-4" />
        <span class="text-gray-900 font-medium">{{ gig.title }}</span>
      </nav>

      <!-- Main Content -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div class="sm:p-5 p-2">
          <!-- Hero Image -->
            <div class="relative mb-8">
              <div class="aspect-video rounded-lg overflow-hidden bg-gray-100">
                <img
                  :src="gig.image"
                  :alt="gig.title"
                  class="w-full h-full object-cover"
                />
              </div>
              <!-- Gallery thumbnails -->
              <div class="flex space-x-2 mt-4">
                <div
                  v-for="i in 4"
                  :key="i"
                  class="w-16 h-16 rounded-md overflow-hidden bg-gray-100 cursor-pointer border-2 border-transparent hover:border-purple-500 transition-colors"
                >
                  <img
                    :src="gig.image"
                    :alt="`${gig.title} view ${i}`"
                    class="w-full h-full object-cover"
                  />
                </div>
              </div>
            </div>

            <!-- Title and Description -->
            <div class="mb-8">
              <h1 class="text-2xl font-bold text-gray-900 mb-4">{{ gig.title }}</h1>
              
              <!-- Seller Info -->
              <div class="flex items-center mb-6 p-4 bg-gray-50 rounded-lg">
                <img
                  :src="gig.user.avatar"
                  :alt="gig.user.name"
                  class="h-12 w-12 rounded-full object-cover mr-4 cursor-pointer hover:ring-2 hover:ring-purple-400 transition-all"
                  @click="navigateToProfile(gig.user.id)"
                />
                <div class="flex-1">
                  <h3 
                    class="font-semibold text-gray-900 cursor-pointer hover:text-purple-600 transition-colors"
                    @click="navigateToProfile(gig.user.id)"
                  >
                    {{ gig.user.name }}
                  </h3>
                  <div class="flex items-center mt-1">
                    <div class="flex items-center">
                      <Star v-for="i in 5" :key="i" class="h-4 w-4 text-yellow-400 fill-current" />
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
                <button 
                  @click="navigateToProfile(gig.user.id)"
                  class="px-4 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
                >
                  Visit Profile
                </button>
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
                <div class="bg-white rounded-lg border border-gray-200 p-6 mb-8">
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                    <!-- Left: Price -->
                    <div class="text-center md:text-left">
                      <div class="text-3xl font-bold text-gray-900 mb-2">${{ gig.price }}</div>
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
                      Order (${{ gig.price }})
                    </button>
                    <button
                      @click="handleContact"
                      class="flex-1 border border-gray-300 text-gray-700 py-3 px-4 rounded-lg font-medium hover:bg-gray-50 transition-colors"
                    >
                      Contact Seller
                    </button>
                  </div>

                  <!-- Trust Indicators and Share -->
                  <div class="pt-6 border-t border-gray-200">
                    <div class="flex items-center justify-center space-x-6 text-sm text-gray-600">
                      <div class="flex items-center">
                        <Eye class="h-4 w-4 mr-1" />
                        <span>{{ Math.floor(Math.random() * 500) + 100 }} views</span>
                      </div>
                      <div class="flex items-center">
                        <Clock class="h-4 w-4 mr-1" />
                        <span>Active now</span>
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
              
              <div class="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-3 gap-2">
                <div 
                  v-for="relatedGig in relatedGigs" 
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
                      <span 
                        class="text-sm text-gray-600 cursor-pointer hover:text-purple-600 transition-colors"
                        @click.stop="navigateToProfile(relatedGig.user.id)"
                      >
                        {{ relatedGig.user.name }}
                      </span>
                    </div>
                    
                    <!-- Rating and Price -->
                    <div class="flex items-center justify-between">
                      <div class="flex items-center">
                        <Star class="h-4 w-4 text-yellow-400 fill-current mr-1" />
                        <span class="text-sm font-medium text-gray-900">{{ relatedGig.rating }}</span>
                        <span class="text-sm text-gray-500 ml-1">({{ relatedGig.reviews }})</span>
                      </div>
                      <div class="text-lg font-bold text-gray-900">
                        ${{ relatedGig.price }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Reviews Section -->
            <div id="reviews-section" class="border-t pt-8">
              <div class="flex items-center justify-between mb-6">
                <h3 class="text-lg font-semibold text-gray-900">Reviews ({{ gig.reviews }})</h3>
                <div class="flex items-center">
                  <Star class="h-5 w-5 text-yellow-400 fill-current mr-1" />
                  <span class="font-semibold text-gray-900">{{ gig.rating }}</span>
                  <span class="text-gray-600 ml-1">out of 5</span>
                </div>
              </div>

              <!-- Reviews List - Will be populated from API -->
              <div v-if="gig.reviews > 0" class="space-y-4">
                <p class="text-gray-500 text-sm">Reviews will be loaded from the database.</p>
              </div>
              <div v-else class="text-center py-6">
                <p class="text-gray-500 text-sm">No reviews yet. Be the first to review!</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
</template>

<script setup>
import { 
  Star, Eye, Clock, Check, Heart, Share2, ChevronRight, ArrowLeft, 
  AlertTriangle
} from 'lucide-vue-next';

// Page meta
definePageMeta({
  layout: "adsy-business-network",
  title: "Workspace Details - Business Network",
});

// Composables
const route = useRoute();
const toast = useToast();
const { user } = useAuth();
const { get } = useApi();

// State
const isLoading = ref(true);
const gig = ref(null);
const relatedGigsData = ref([]);

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

  toast.add({
    title: "Contact Seller",
    description: `Opening chat with ${gig.value.user.name}`,
    color: "green",
  });
};

const handleShare = () => {
  if (navigator.share) {
    navigator.share({
      title: gig.value.title,
      text: `Check out this amazing gig: ${gig.value.title}`,
      url: window.location.href,
    });
  } else {
    navigator.clipboard.writeText(window.location.href);
    toast.add({
      title: "Link Copied",
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
    
  } catch (err) {
    console.error('Error fetching gig:', err);
    gig.value = null;
  } finally {
    isLoading.value = false;
  }
};

const fetchRelatedGigs = async (category, currentGigId) => {
  try {
    const { data, error } = await get(`/workspace/gigs/?category=${category}`);
    
    if (error || !data) {
      relatedGigsData.value = [];
      return;
    }
    
    const results = data?.results || data || [];
    relatedGigsData.value = results
      .filter(g => g.id !== currentGigId)
      .slice(0, 3)
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
        },
        rating: g.rating || 0,
        reviews: g.reviews || 0,
      }));
  } catch (err) {
    console.error('Error fetching related gigs:', err);
    relatedGigsData.value = [];
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
</style>
