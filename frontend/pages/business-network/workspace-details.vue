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
                  class="h-12 w-12 rounded-full object-cover mr-4"
                />
                <div class="flex-1">
                  <h3 class="font-semibold text-gray-900">{{ gig.user.name }}</h3>
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
                <button class="px-4 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 transition-colors">
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
              
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
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
                        class="h-6 w-6 rounded-full mr-2"
                      />
                      <span class="text-sm text-gray-600">{{ relatedGig.user.name }}</span>
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

              <!-- Sample Review -->
              <div class="space-y-4">
                <div class="p-4 bg-gray-50 rounded-lg">
                  <div class="flex items-start justify-between mb-3">
                    <div class="flex items-center">
                      <img
                        src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=40&h=40&fit=crop&crop=face"
                        alt="Reviewer"
                        class="h-8 w-8 rounded-full object-cover mr-3"
                      />
                      <div>
                        <h4 class="font-medium text-gray-900">John Smith</h4>
                        <div class="flex items-center">
                          <Star v-for="i in 5" :key="i" class="h-3 w-3 text-yellow-400 fill-current" />
                          <span class="text-xs text-gray-500 ml-1">2 days ago</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <p class="text-gray-600 text-sm">
                    Excellent work! The delivery was on time and exceeded my expectations. Highly recommended!
                  </p>
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

// State
const isLoading = ref(true);
const gig = ref(null);

// Dummy data for the workspaces (matching the parent page)
const dummyGigs = [
  {
    id: 1,
    title: "I will design a modern and professional logo for your business",
    price: 25,
    category: "design",
    image: "https://images.unsplash.com/photo-1626785774573-4b799315345d?w=800&h=600&fit=crop",
    user: {
      id: 1,
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
    image: "https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=800&h=600&fit=crop",
    user: {
      id: 2,
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
    image: "https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=800&h=600&fit=crop",
    user: {
      id: 3,
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
    image: "https://images.unsplash.com/photo-1611926653458-09294b3142bf?w=800&h=600&fit=crop",
    user: {
      id: 4,
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
    image: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=600&fit=crop",
    user: {
      id: 5,
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
    image: "https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=800&h=600&fit=crop",
    user: {
      id: 6,
      name: "Lisa Park",
      avatar: "https://images.unsplash.com/photo-1544723795-3fb6469f5b39?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.8,
    reviews: 91,
    isFavorited: true,
  },
  {
    id: 7,
    title: "I will design eye-catching social media graphics and banners",
    price: 35,
    category: "design",
    image: "https://images.unsplash.com/photo-1611224923853-80b023f02d71?w=800&h=600&fit=crop",
    user: {
      id: 7,
      name: "Carlos Martinez",
      avatar: "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=100&h=100&fit=crop&crop=face",
    },
    rating: 4.7,
    reviews: 156,
    isFavorited: false,
  }
];

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
  if (!gig.value) return [];
  
  // Get gigs from the same category, excluding the current gig
  return dummyGigs
    .filter(g => g.category === gig.value.category && g.id !== gig.value.id)
    .slice(0, 3); // Show 3 for desktop, responsive grid will handle mobile (2 items)
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

const fetchGig = () => {
  const gigId = parseInt(route.query.id);
  if (!gigId) {
    gig.value = null;
    return;
  }

  const foundGig = dummyGigs.find(g => g.id === gigId);
  if (foundGig) {
    gig.value = foundGig;
    
    // Update page title
    useHead({
      title: `${foundGig.title} - Business Network`,
      meta: [
        { name: 'description', content: getGigDescription(foundGig) }
      ]
    });
  } else {
    gig.value = null;
  }
};

// Lifecycle
onMounted(() => {
  isLoading.value = true;
  
  // Simulate API call
  setTimeout(() => {
    fetchGig();
    isLoading.value = false;
  }, 800);
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
