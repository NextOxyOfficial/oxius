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
        <SidebarMenu 
          :isMobile="isMobile" 
          @menu-click="handleMenuClick" 
        />

        <!-- Workspaces Section -->
        <!-- (This section is commented out in the original code) -->
        
        <!-- Create Workspace Modal -->
        <Teleport to="body">
          <div
            v-if="isCreateWorkspaceModalOpen"
            class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4"
            @click="isCreateWorkspaceModalOpen = false"
          >
            <div
              class="bg-white rounded-lg max-w-md w-full p-6 shadow-lg"
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

// State
const isOpen = ref(false);
const isMobile = ref(false);
const { user } = useAuth();
const { get, post } = useApi();
const cart = useStoreCart();
const route = useRoute();
const tags = ref([]); // Will be populated from hashtags
const displayProduct = ref(null);
const allProducts = ref([]); // Store all fetched products
const workspaces = ref([]); // Predefined workspaces with # prefix
const isCreateWorkspaceModalOpen = ref(false);
const newWorkspaceName = ref(""); // Store new workspace name
const { unreadCount, fetchUnreadCount } = useNotifications();

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
    // Use the correct API endpoint for trending hashtags
    const response = await get("/news/tags/?limit=30");
    if (response.data && response.data.results) {
      // Ensure each tag has an ID and properly map the data structure
      const hashtagData = response.data.results.map((tag) => ({
        id: tag.id || Math.random().toString(36).substr(2, 9), // Ensure each tag has an id
        tag: tag.tag || tag.name || "",
        count: tag.posts_count || tag.count || 0,
      }));
      tags.value = hashtagData; // This is what's displayed in the template
      console.log("Hashtags loaded successfully:", tags.value.length);
    } else {
      console.warn("Unexpected hashtags response format:", response.data);
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
          { id: '1', tag: 'adsy', count: 120 },
          { id: '2', tag: 'business', count: 85 },
          { id: '3', tag: 'network', count: 74 },
          { id: '4', tag: 'tech', count: 63 },
          { id: '5', tag: 'startup', count: 57 }
        ];
        console.log("Using default hashtags as fallback");
      }
    }
  } catch (error) {
    console.error("Error fetching hashtags:", error);
    // Set default tags if fetch fails
    tags.value = [
      { id: '1', tag: 'adsy', count: 120 },
      { id: '2', tag: 'business', count: 85 },
      { id: '3', tag: 'network', count: 74 },
      { id: '4', tag: 'tech', count: 63 },
      { id: '5', tag: 'startup', count: 57 }
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

// Methods
const handleNavigation = (path) => {
  // Close sidebar on mobile when navigating
  if (isMobile.value) {
    isOpen.value = false;
    cart.burgerMenu = false;
    document.body.style.overflow = "";
  }

  // In a real app, you would use router.push(path) here
  console.log(`Navigating to: ${path}`);
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
  console.log(`Tag clicked: ${tag.tag}`);
  // Implement the navigation or filtering by tag functionality
  handleNavigation(`/hashtag/${tag.tag}`);
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
</style>
