<template>
  <div class="rounded-t-sm mt-16">
    <!-- Mobile Overlay (shows when sidebar is open on mobile) -->
    <div
      v-if="isMobile && cart.burgerMenu"
      class="fixed inset-0 bg-black/50 z-40 lg:hidden"
      @click="cart.toggleBurgerMenu()"
    ></div>

    <!-- Sidebar -->
    <aside
      :class="[
        'sm:max-h-screen fixed sm:static top-14 bottom-0 pb-16 sm:pb-0 z-50 flex flex-col bg-white border-r border-gray-200 transition-all duration-300 ease-in-out rounded-t-sm',
        isMobile
          ? cart.burgerMenu
            ? 'translate-x-0 w-72'
            : '-translate-x-full'
          : 'w-72',
        '',
      ]"
    >
      <!-- Sidebar Header -->
      <div
        class="h-12 mt-2 flex items-center justify-between px-4 border-gray-100 relative"
      >
        <button
          v-if="cart.burgerMenu"
          class="fixed flex top-3 -right-10 lg:hidden h-8 w-8 items-center justify-center rounded-md bg-gray-200 text-gray-500"
          @click="cart.toggleBurgerMenu()"
        >
          <X class="h-5 w-5" />
        </button>
      </div>

      <!-- Sidebar Content (Scrollable) -->
      <div class="flex-1 overflow-y-auto py-4 px-2 space-y-7 -mt-12 sm:-mt-10">
        <!-- Main Menu Section -->
        <SidebarMenu :isMobile="isMobile" @menu-click="handleMenuClick" />

        <!-- Create Workspace Modal -->
        <Teleport to="body">
          <div
            v-if="isCreateWorkspaceModalOpen"
            class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center"
            @click="isCreateWorkspaceModalOpen = false"
          >
            <div
              class="bg-white rounded-lg max-w-md w-full p-6 shadow-sm"
              @click.stop
            >
              <h3 class="text-lg font-semibold mb-4">Create Workspace</h3>
              <form @submit.prevent="createWorkspace">
                <div class="mb-4">
                  <label
                    for="workspaceName"
                    class="block text-sm font-medium text-gray-700 mb-1"
                  >
                    Workspace Name
                  </label>
                  <input
                    id="workspaceName"
                    v-model="newWorkspaceName"
                    type="text"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-600"
                    placeholder="Enter workspace name"
                  />
                </div>
                <div class="flex justify-end space-x-2">
                  <button
                    type="button"
                    class="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
                    @click="isCreateWorkspaceModalOpen = false"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                  >
                    Create
                  </button>
                </div>
              </form>
            </div>         
           </div>
        </Teleport>        
        <!-- Useful Links Section -->
        <SidebarUsefulLinks />
        
        <!-- Gold Sponsor Modal -->
        <Teleport to="body">
          <GoldSponsorModal 
            :is-open="isGoldSponsorModalOpen" 
            @close="isGoldSponsorModalOpen = false" 
            @submit="handleGoldSponsorSubmit" 
          />
        </Teleport>
          <!-- Become Gold Sponsor Section -->        
           <div class="p-3 bg-gradient-to-br from-amber-50 to-yellow-50 dark:from-amber-900/10 dark:to-yellow-900/10 rounded-xl border border-amber-100/50 dark:border-amber-900/30 mt-1 mb-4 relative overflow-hidden">
          <!-- Shimmering effect at top -->
          <div class="absolute top-0 left-0 right-0 h-1 overflow-hidden">
            <div class="h-full w-full bg-gradient-to-r from-amber-500/0 via-amber-500 to-amber-500/0 animate-shimmer"></div>
          </div>
          
          <div class="flex flex-col">            <h3 class="text-sm font-semibold mb-2 flex items-center">
              <div class="w-5 h-5 flex items-center justify-center mr-1.5 relative">
                <div class="absolute inset-0 rounded-full golden-border"></div>
                <span class="text-amber-500 relative z-10 text-lg">✦</span>
              </div>
              <span class="text-gold-gradient">My Gold Sponsorships</span>
            </h3>            
            <!-- Stats cards with improved design -->
            <div class="grid grid-cols-2 gap-2 mb-3">
              <div class="bg-white dark:bg-slate-700/80 rounded-lg p-2 text-center shadow-sm border border-amber-100 dark:border-amber-800/30">
                <div v-if="isLoadingSponsors" class="animate-pulse h-6 bg-amber-100/50 dark:bg-amber-900/30 rounded w-10 mx-auto mb-1"></div>
                <div v-else class="text-lg font-semibold text-amber-600 dark:text-amber-400">
                  {{ goldSponsorsCount }}
                </div>
                <div class="text-xs text-gray-600 dark:text-gray-400">Active Sponsorships</div>
              </div>
              <div 
                class="bg-white dark:bg-slate-700/80 rounded-lg p-2 text-center shadow-sm border border-amber-100 dark:border-amber-800/30 group relative"
                title="Total number of times your sponsors have been viewed"
              >              
                <div v-if="isLoadingSponsors" class="animate-pulse h-6 bg-amber-100/50 dark:bg-amber-900/30 rounded w-16 mx-auto mb-1"></div>
                <div v-else class="text-lg font-semibold text-amber-600 dark:text-amber-400">
                  {{ sponsorViews.toLocaleString() }}
                </div>
                <div class="text-xs text-gray-600 dark:text-gray-400 flex items-center justify-center">
                  Total Views
                  <UIcon name="i-heroicons-information-circle" class="w-3 h-3 ml-0.5 text-gray-400" />
                </div>
              </div>
            </div>                <!-- My Sponsorships List -->
            <div v-if="isLoadingSponsors" class="mb-3">
              <h4 class="text-xs text-gray-600 dark:text-gray-400 mb-1.5">My Sponsorships:</h4>
              <ul class="space-y-1.5">
                <li v-for="i in 2" :key="i" class="flex items-center animate-pulse">
                  <div class="h-5 w-5 rounded-full overflow-hidden mr-2 bg-amber-100/50 dark:bg-amber-900/30 flex-shrink-0"></div>
                  <div class="h-3 bg-amber-100/50 dark:bg-amber-900/30 rounded w-20"></div>
                </li>
              </ul>
            </div>
            <div v-else-if="featuredSponsors && featuredSponsors.length > 0" class="mb-3">
              <h4 class="text-xs text-gray-600 dark:text-gray-400 mb-1.5">My Sponsorships:</h4>
              <ul class="space-y-1.5">
                <li 
                  v-for="(sponsor, index) in featuredSponsors" 
                  :key="index"
                  class="flex items-center justify-between text-xs"
                >
                  <div class="flex items-center overflow-hidden">
                    <div class="h-5 w-5 rounded-full overflow-hidden mr-2 border border-amber-200 dark:border-amber-700 flex-shrink-0">
                      <img 
                        :src="sponsor.image || '/static/frontend/avatar.png'" 
                        :alt="sponsor.name"
                        class="h-full w-full object-cover"
                      />
                    </div>
                    <span class="text-gray-700 dark:text-gray-300 truncate" :title="sponsor.name">
                      {{ sponsor.name }}
                    </span>
                  </div>
                  <!-- Status badge -->
                  <span 
                    class="text-xs px-1.5 py-0.5 rounded-full capitalize"
                    :class="{
                      'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400': sponsor.status === 'active',
                      'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400': sponsor.status === 'pending',
                      'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400': sponsor.status === 'rejected',
                      'bg-gray-100 text-gray-800 dark:bg-gray-800/20 dark:text-gray-400': !sponsor.status || sponsor.status === 'inactive'
                    }"
                  >
                    {{ sponsor.status || 'inactive' }}
                  </span>
                </li>
              </ul>
            </div>
            <div v-else-if="goldSponsorsCount > 0" class="mb-3 text-xs text-center text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/50 rounded-lg p-2">
              You have {{ goldSponsorsCount }} sponsorship(s) pending approval
            </div>
            <div v-else class="mb-3 text-xs text-center text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/50 rounded-lg p-2">
              You don't have any active sponsorships yet
            </div>
            
            <p class="text-xs text-gray-600 dark:text-gray-300 mb-3">
              Become a Gold Sponsor and showcase your business to our entire network with premium visibility.
            </p>
            
            <div class="space-y-2">              <button 
                @click="isGoldSponsorModalOpen = true"
                class="w-full py-2 rounded-md bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-600 hover:to-yellow-600 text-white text-sm font-medium shadow-sm transition-all duration-200 flex items-center justify-center group"
              >
                <span>Become Gold Sponsor</span>
                <UIcon name="i-heroicons-plus" class="ml-1 w-3.5 h-3.5 group-hover:scale-110 transition-transform" />
              </button>
            </div>
          </div>
        </div>

        <!-- Adsy News Section -->
        <SidebarNews
          :news-items="newsItems"
          :is-loading="isLoadingNews"
          @navigation="handleNavigation"
        />

        <!-- Hashtags Section -->
        <SidebarHashtags
          :tags="tags"
          :is-loading="false"
          @tag-click="handleTagClick"
        />

        <!-- Products Slider -->
        <SidebarFeaturedProduct
          :product="displayProduct"
          :is-loading="isLoadingProducts"
          @refresh="changeRandomProduct"
          @navigation="handleNavigation"
        />

        <!-- Top Contributors -->
        <SidebarContributors
          :contributors="topContributors"
          :is-loading="isLoadingContributors"
          @navigation="handleNavigation"
        />
      </div>
    </aside>
  </div>
</template>

<script setup>
import { X } from "lucide-vue-next";
import { useNotifications } from "~/composables/useNotifications";
import SidebarMenu from "./SidebarMenu.vue";
import SidebarNews from "./SidebarNews.vue";
import SidebarHashtags from "./SidebarHashtags.vue";
import SidebarFeaturedProduct from "./SidebarFeaturedProduct.vue";
import SidebarContributors from "./SidebarContributors.vue";
import SidebarUsefulLinks from "./SidebarUsefulLinks.vue";
import GoldSponsorModal from "../business-network/GoldSponsorModal.vue";

// State
const isOpen = ref(false);
const isMobile = ref(false);
const { user } = useAuth();
const { get, post } = useApi();
const cart = useStoreCart();
const route = useRoute();
const router = useRouter();
const toast = useToast();
const tags = ref([]); // Will be populated from hashtags
const displayProduct = ref(null);
const allProducts = ref([]); // Store all fetched products
const workspaces = ref([]); // Predefined workspaces with # prefix
const isCreateWorkspaceModalOpen = ref(false);
const newWorkspaceName = ref(""); // Store new workspace name
const { unreadCount, fetchUnreadCount } = useNotifications();

// Gold Sponsor modal
const isGoldSponsorModalOpen = ref(false);
const goldSponsorsCount = ref(0); // Start with zero until fetched from API
const sponsorViews = ref(0); // Start with zero until fetched from API
const featuredSponsors = ref([]); // Will hold a few featured sponsors
const isLoadingSponsors = ref(false); // Loading state for gold sponsor data

// Loading states
const isLoadingNews = ref(false);
const isLoadingProducts = ref(false);
const isLoadingContributors = ref(false);

// News Items
const newsItems = ref([]);

// Enhanced fetchNewsItems function to handle retries and validate API response
async function fetchNewsItems() {
  isLoadingNews.value = true;
  let retries = 3;

  while (retries > 0) {
    try {
      const response = await get("/news/posts/?limit=20");
      if (
        response.data &&
        Array.isArray(response.data.results) &&
        response.data.results.length > 0
      ) {
        const allNews = response.data.results;
        newsItems.value = allNews.slice(0, 5); // Limit to 5 items
        break;
      } else {
        console.warn("Unexpected news response format:", response.data);
        newsItems.value = [];
      }
    } catch (error) {
      console.error("Error fetching news:", error);
    }
    retries--;
    if (retries > 0) await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  isLoadingNews.value = false;
}

// Hashtags
async function fetchHashtags() {
  try {
    // Set loading state
    const isLoadingHashtags = ref(true);

    // Use the top-tags endpoint as primary source for trending hashtags
    const response = await get("/bn/top-tags/");
    if (response.data && Array.isArray(response.data)) {
      // Ensure each tag has an ID and properly map the data structure
      const hashtagData = response.data.map((tag) => ({
        id: tag.id || Math.random().toString(36).substr(2, 9),
        tag: tag.tag || "",
        count: tag.count || 0,
      }));

      // Take only the top trending hashtags (sorted by count)
      tags.value = hashtagData.sort((a, b) => b.count - a.count).slice(0, 30); // Get top 30 for potential display

      console.log(
        "Hashtags loaded successfully from top-tags:",
        tags.value.length
      );
    } else {
      console.warn(
        "Unexpected hashtags response format from top-tags:",
        response.data
      );
      // Try alternative endpoint as fallback
      const fallbackResponse = await get("/bn/trending-tags/?limit=30");
      if (fallbackResponse.data && Array.isArray(fallbackResponse.data)) {
        const hashtagData = fallbackResponse.data.map((tag) => ({
          id: tag.id || Math.random().toString(36).substr(2, 9),
          tag: tag.tag || tag.name || "",
          count: tag.count || 0,
        }));
        tags.value = hashtagData;
        console.log("Hashtags loaded from fallback:", tags.value.length);
      } else {
        // If both attempts fail, set some default tags so UI isn't empty
        tags.value = [
          { id: "1", tag: "adsy", count: 120 },
          { id: "2", tag: "business", count: 85 },
          { id: "3", tag: "network", count: 74 },
          { id: "4", tag: "tech", count: 63 },
          { id: "5", tag: "startup", count: 57 },
          { id: "6", tag: "marketing", count: 49 },
          { id: "7", tag: "innovation", count: 43 },
        ];
        console.log("Using default hashtags as fallback");
      }
    }
  } catch (error) {
    console.error("Error fetching hashtags:", error);
    // Set default tags if fetch fails
    tags.value = [
      { id: "1", tag: "adsy", count: 120 },
      { id: "2", tag: "business", count: 85 },
      { id: "3", tag: "network", count: 74 },
      { id: "4", tag: "tech", count: 63 },
      { id: "5", tag: "startup", count: 57 },
      { id: "6", tag: "marketing", count: 49 },
      { id: "7", tag: "innovation", count: 43 },
    ];
    console.log("Using default hashtags due to error");
  }
}

// Workspaces
async function fetchWorkspaces() {
  try {
    const response = await get("/bn/workspaces/");
    workspaces.value = response.data;
  } catch (error) {
    console.error("Error fetching workspaces:", error);
    workspaces.value = [];
  }
}

// Create Workspace
async function createWorkspace() {
  if (!newWorkspaceName.value.trim()) {
    toast.add({ title: "Workspace name cannot be empty" });
    return;
  }

  if (!user.value) {
    toast.add({ title: "Please login to create a workspace" });
    return;
  }

  try {
    const response = await post("/bn/workspaces/", {
      name: newWorkspaceName.value,
    });
    if (response.data) {
      await fetchWorkspaces();
      toast.add({ title: "Workspace created successfully!" });
      newWorkspaceName.value = "";
    }
  } catch (error) {
    console.log(error);
  }
}

// Products
async function fetchProducts() {
  isLoadingProducts.value = true;
  let retries = 3;

  while (retries > 0) {
    try {
      const response = await get("/all-products/?limit=20&is_featured=true");
      if (
        response.data &&
        Array.isArray(response.data.results) &&
        response.data.results.length > 0
      ) {
        allProducts.value = response.data.results;
        displayProduct.value = allProducts.value[0]; // Display the first product
        break;
      } else {
        console.warn("Unexpected products response format:", response.data);
        allProducts.value = [];
        displayProduct.value = null;
      }
    } catch (error) {
      console.error("Error fetching products:", error);
    }
    retries--;
    if (retries > 0) await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  isLoadingProducts.value = false;
}

// Add a function to display a new random product
const changeRandomProduct = () => {
  if (allProducts.value.length === 0) return;

  const currentIndex = allProducts.value.findIndex(
    (p) => p.id === displayProduct.value?.id
  );

  let newIndex;
  do {
    newIndex = Math.floor(Math.random() * allProducts.value.length);
  } while (newIndex === currentIndex && allProducts.value.length > 1);

  displayProduct.value = allProducts.value[newIndex];
};

// Top Contributors
const topContributors = ref([]);

// Enhanced fetchTopContributors function to handle retries and validate API response
async function fetchTopContributors() {
  isLoadingContributors.value = true;

  try {
    const response = await get("/top-contributors/");
    if (response.data) {
      topContributors.value = response.data;
    } else {
      console.warn("Unexpected contributors response format:", response.data);
      topContributors.value = [];
    }
  } catch (error) {
    console.error("Error fetching contributors:", error);
  } finally {
    isLoadingContributors.value = false;
  }
}

// Gold Sponsors Data
async function fetchGoldSponsorsData() {
  try {
    isLoadingSponsors.value = true;
    
    // Use the correct API endpoint with the /api prefix
    console.log("Fetching gold sponsors data...");
    const response = await get("/api/bn/gold-sponsors/stats/");
    console.log("Full gold sponsors API response:", response);
    
    if (response && response.data) {
      console.log("Gold sponsors API data:", response.data);
      
      // Update the counts with real values from the API
      goldSponsorsCount.value = response.data.active_count || 0;
      console.log("Set goldSponsorsCount to:", goldSponsorsCount.value);
      
      sponsorViews.value = response.data.total_views || 0;
      console.log("Set sponsorViews to:", sponsorViews.value);
      
      // Update the featured sponsors list if available
      if (response.data.featured_sponsors && Array.isArray(response.data.featured_sponsors)) {
        console.log("Featured sponsors from API:", response.data.featured_sponsors);
        console.log("Number of featured sponsors:", response.data.featured_sponsors.length);
        
        // Debug each sponsor
        response.data.featured_sponsors.forEach((sponsor, index) => {
          console.log(`Sponsor ${index + 1}:`, {
            id: sponsor.id,
            name: sponsor.name,
            status: sponsor.status,
            image: sponsor.image,
          });
        });
        
        featuredSponsors.value = response.data.featured_sponsors;
        console.log("Updated featuredSponsors.value length:", featuredSponsors.value.length);
        console.log("After setting, featuredSponsors contains:", JSON.stringify(featuredSponsors.value));
      } else {
        console.warn("No featured sponsors in response or invalid format", response.data);
        if (response.data.featured_sponsors) {
          console.warn("featured_sponsors exists but is not an array:", typeof response.data.featured_sponsors);
        } else {
          console.warn("featured_sponsors is missing entirely from response");
        }
        featuredSponsors.value = []; // Clear the list if no sponsors available
        console.log("Cleared featuredSponsors, length is now:", featuredSponsors.value.length);
      }
      
      // Log successful fetch for debugging
      console.log("Gold sponsors data processing complete:", {
        activeCount: goldSponsorsCount.value,
        totalViews: sponsorViews.value,
        featuredSponsors: featuredSponsors.value.length
      });
    } else {
      console.error("Invalid response format from gold sponsors API:", response);
      featuredSponsors.value = [];
    }
  } catch (error) {
    console.error("Error fetching gold sponsors data:", error);
    // Keep the default values if the API fails
    featuredSponsors.value = [];
  } finally {
    isLoadingSponsors.value = false;
  }
}

// Methods
const handleNavigation = (path) => {
  // Close sidebar on mobile when navigating
  if (isMobile.value) {
    isOpen.value = false;
    cart.burgerMenu = false;
    document.body.style.overflow = "";
  }

  // Use router to navigate to the path
  navigateTo(path);
};

// Add a method to handle menu clicks with loading states
const handleMenuClick = (path) => {
  // Close sidebar on mobile
  if (isMobile.value) {
    isOpen.value = false;
    cart.burgerMenu = false;
    document.body.style.overflow = "";
  }

  // Trigger appropriate loading state based on the path
  const eventBus = useEventBus();
  if (path.includes("/profile/")) {
    // For profile pages, emit the profile loading event
    eventBus.emit("start-loading-profile");
    console.log("Emitted start-loading-profile event");
  } else if (path === "/business-network") {
    // For main feed, emit the recent posts loading event
    eventBus.emit("load-recent-posts");
    console.log("Emitted load-recent-posts event");
  }
};

const handleTagClick = (tag) => {
  console.log(`Tag clicked:`, tag);
  // Implement the navigation or filtering by tag functionality
  handleNavigation(`/business-network/search-results/${tag.tag}`);
};

// Handle Gold Sponsor form submission
const handleGoldSponsorSubmit = async (formData) => {
  try {
    console.log("Gold Sponsor application submitted:", formData);
    // Submit the data to the backend with the correct API endpoint
    const response = await post("/api/bn/gold-sponsors/apply/", formData);
    
    if (response.error) {
      throw new Error(response.error);
    }
    
    // Show success message
    toast.add({
      title: "Application Submitted",
      description: "Your Gold Sponsor application has been received. We'll contact you soon.",
      color: "green",
    });
    
    // After successful submission, refresh the gold sponsors data
    await fetchGoldSponsorsData();
  } catch (error) {
    console.error("Error submitting gold sponsor application:", error);
    toast.add({
      title: "Submission Failed",
      description: "There was an error submitting your application. Please try again.",
      color: "red",
    });
  }
};

// Updated the toggleSidebar function to handle mobile screen issues and ensure proper state management.
const toggleSidebar = () => {
  isOpen.value = !isOpen.value;

  // Prevent body scroll when sidebar is open on mobile
  if (isOpen.value && isMobile.value) {
    document.body.style.overflow = "hidden";
  } else {
    document.body.style.overflow = "";
  }

  // Ensure cart.burgerMenu state syncs with isOpen
  if (isMobile.value) {
    cart.burgerMenu = isOpen.value;
  }
};

// Check if screen is mobile size and manage sidebar state accordingly
const checkMobile = () => {
  isMobile.value = window.innerWidth < 1024; // lg breakpoint

  // Auto-close sidebar on mobile when resizing
  if (isMobile.value) {
    isOpen.value = false;
    cart.burgerMenu = false;
    document.body.style.overflow = "";
  }
};

// Lifecycle hooks
onMounted(async () => {
  // Initial check for mobile
  checkMobile();

  // Add resize listener
  window.addEventListener("resize", checkMobile);

  // Fetch unread notification count if user is logged in
  if (user.value?.user?.id) {
    await fetchUnreadCount();
  }
  // Fetch dynamic data regardless of login status
  try {
    await Promise.all([
      fetchNewsItems(),
      fetchHashtags(),
      fetchProducts(),
      fetchTopContributors(),
      fetchGoldSponsorsData(),
    ]);

    // Only fetch workspaces if the user is logged in
    if (user.value?.user?.id) {
      await fetchWorkspaces();
    }
  } catch (error) {
    console.error("Error fetching sidebar content:", error);
  }

  // Auto-change product every 10 seconds
  const productInterval = setInterval(() => {
    changeRandomProduct();
  }, 10000);

  // Cleanup
  onUnmounted(() => {
    window.removeEventListener("resize", checkMobile);
    clearInterval(productInterval);
  });
});
</script>

<style scoped>
/* Hide scrollbars but maintain scrolling functionality */
.overflow-y-auto {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}

.overflow-y-auto::-webkit-scrollbar {
  display: none; /* Chrome, Safari and Opera */
  width: 0;
}

/* Pulsing effect for badges */
[class*="bg-blue-100"],
[class*="bg-purple-100"],
[class*="bg-emerald-100"],
[class*="bg-amber-100"] {
  position: relative;
  overflow: hidden;
}

[class*="bg-blue-100"]:after,
[class*="bg-purple-100"]:after,
[class*="bg-emerald-100"]:after,
[class*="bg-amber-100"]:after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border-radius: inherit;
  box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7);
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(255, 255, 255, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(255, 255, 255, 0);
  }
}

/* Updated hover color for sidebar items */
nav a:hover {
  background-color: #e0f7fa; /* Light cyan hover color */
}

button:hover {
  background-color: #c4eef3; /* Light cyan hover color */
}

/* Shimmer animation for gold sponsor section */
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 2s infinite;
}

/* Gold gradient text effect */
.text-gold-gradient {
  background: linear-gradient(to right, #f59e0b, #fbbf24);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  color: transparent;
  font-weight: 600;
}

/* Golden border effect */
.golden-border {
  border: 2px solid;
  border-image-slice: 1;
  border-image-source: linear-gradient(to right, #f59e0b, #fbbf24);
}
</style>
