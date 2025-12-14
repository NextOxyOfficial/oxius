<template>
  <!-- Sidebar with filters - Commercial Compact Design -->
  <div
    class="filter-sidebar lg:w-64 bg-white rounded-xl shadow-sm border border-gray-200/80"
    :class="[
      isMobileFilterOpen ? 'mobile-sidebar-open' : 'mobile-sidebar-closed',
      'lg:block',
    ]"
  >
    <!-- Mobile Header -->
    <div
      class="lg:hidden sticky top-0 flex items-center justify-between px-3 py-2.5 border-b border-gray-200 bg-gradient-to-r from-emerald-600 to-emerald-700 z-20 rounded-t-xl"
    >
      <h2 class="text-base font-semibold text-white">
        <span class="flex items-center gap-2">
          <UIcon name="i-heroicons-squares-2x2" class="h-4 w-4" />
          Categories
        </span>
      </h2>
      <UButton
        icon="i-heroicons-x-mark"
        size="xs"
        color="white"
        variant="ghost"
        class="ml-auto hover:bg-white/20"
        @click="toggleMobileSidebar"
        aria-label="Close"
      />
    </div>

    <!-- Main Content Area -->
    <div
      class="overflow-y-auto sidebar-content p-3 flex-grow sidebar-scrollable-content"
    >
      <!-- Categories Section - Compact List -->
      <div class="mb-4">
        <div class="hidden lg:flex items-center gap-2 mb-3 pb-2 border-b border-gray-100">
          <div class="w-7 h-7 rounded-lg bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center">
            <UIcon name="i-heroicons-squares-2x2" class="w-4 h-4 text-white" />
          </div>
          <div>
            <h2 class="text-sm font-bold text-gray-800">Categories</h2>
            <p class="text-[10px] text-gray-500">Browse by category</p>
          </div>
        </div>
        <ul class="space-y-0.5">
          <!-- All Categories option -->
          <li>
            <button
              @click="selectCategory(null)"
              class="w-full text-left px-2.5 py-2 rounded-lg flex items-center justify-between transition-all duration-200 group"
              :class="
                !selectedCategory
                  ? 'bg-gradient-to-r from-emerald-50 to-emerald-100 text-emerald-700 font-semibold border border-emerald-200'
                  : 'text-gray-700 hover:bg-gray-50 border border-transparent'
              "
            >
              <span class="flex items-center gap-2">
                <div 
                  class="w-6 h-6 rounded-md flex items-center justify-center transition-colors"
                  :class="!selectedCategory ? 'bg-emerald-500 text-white' : 'bg-gray-100 text-gray-500 group-hover:bg-emerald-100 group-hover:text-emerald-600'"
                >
                  <UIcon name="i-heroicons-home" class="w-3.5 h-3.5" />
                </div>
                <span class="text-[13px]">All Categories</span>
              </span>
              <span
                class="text-[11px] px-2 py-0.5 rounded-full font-semibold"
                :class="!selectedCategory ? 'bg-emerald-500 text-white' : 'bg-gray-100 text-gray-600'"
              >
                {{ totalListings }}
              </span>
            </button>
          </li>
          <!-- Individual categories -->
          <li v-for="category in categories" :key="category.id">
            <button
              @click="selectCategory(category.id)"
              class="w-full text-left px-2.5 py-2 rounded-lg flex items-center justify-between transition-all duration-200 group"
              :class="
                selectedCategory === category.id
                  ? 'bg-gradient-to-r from-emerald-50 to-emerald-100 text-emerald-700 font-semibold border border-emerald-200'
                  : 'text-gray-700 hover:bg-gray-50 border border-transparent'
              "
            >
              <span class="flex items-center gap-2">
                <div 
                  class="w-6 h-6 rounded-md flex items-center justify-center transition-colors overflow-hidden"
                  :class="selectedCategory === category.id ? 'bg-emerald-500' : 'bg-gray-100 group-hover:bg-emerald-100'"
                >
                  <img
                    v-if="category.icon"
                    :src="category.icon"
                    :alt="category.name"
                    class="w-4 h-4 object-contain"
                  />
                  <UIcon
                    v-else
                    :name="getCategoryIcon(category.id, category.name)"
                    class="w-3.5 h-3.5"
                    :class="selectedCategory === category.id ? 'text-white' : 'text-gray-500 group-hover:text-emerald-600'"
                  />
                </div>
                <span class="text-[13px] truncate max-w-[120px]">{{ category.name }}</span>
              </span>
              <span
                class="text-[11px] px-2 py-0.5 rounded-full font-semibold min-w-[28px] text-center"
                :class="selectedCategory === category.id ? 'bg-emerald-500 text-white' : 'bg-gray-100 text-gray-600'"
              >
                {{ category?.post_count || 0 }}
              </span>
            </button>
          </li>
        </ul>
      </div>

      <!-- Post Ad CTA - Compact Commercial Design -->
      <div class="mb-4">
        <div
          class="bg-gradient-to-br from-emerald-500 via-emerald-600 to-teal-600 p-3 rounded-xl shadow-lg relative overflow-hidden"
        >
          <!-- Background Pattern -->
          <div class="absolute top-0 right-0 w-20 h-20 bg-white/10 rounded-full -translate-y-10 translate-x-10"></div>
          <div class="absolute bottom-0 left-0 w-16 h-16 bg-white/5 rounded-full translate-y-8 -translate-x-8"></div>
          
          <div class="relative z-10">
            <div class="flex items-center gap-2 mb-2">
              <div class="w-8 h-8 bg-white/20 rounded-lg flex items-center justify-center">
                <UIcon name="i-heroicons-megaphone" class="w-4 h-4 text-white" />
              </div>
              <div>
                <h3 class="text-sm font-bold text-white">Sell Your Items</h3>
                <p class="text-[10px] text-emerald-100">Reach thousands of buyers</p>
              </div>
            </div>
            <NuxtLink
              to="/sale/my-posts?tab=post-sale"
              class="w-full flex items-center justify-center gap-1.5 px-3 py-2 bg-white text-emerald-700 rounded-lg hover:bg-emerald-50 transition-all text-xs font-bold shadow-sm"
              @click="handleButtonClick('post-your-ad-1')"
            >
              <div
                v-if="loadingButtons.has('post-your-ad-1')"
                class="dotted-spinner emerald h-3 w-3"
              ></div>
              <UIcon v-else name="i-heroicons-plus-circle" class="h-3.5 w-3.5" />
              <span v-if="!loadingButtons.has('post-your-ad-1')">Post Free Ad</span>
            </NuxtLink>
          </div>
        </div>
      </div>

      <!-- Sponsored Ad Section - Compact -->
      <div class="mb-4" v-if="saleHorizontalAds.length > 0">
        <div class="flex items-center gap-1.5 mb-2">
          <UIcon name="i-heroicons-sparkles" class="w-3 h-3 text-amber-500" />
          <span class="text-[10px] uppercase text-gray-500 font-semibold tracking-wide">Sponsored</span>
        </div>

        <!-- Compact Ad Card -->
        <NuxtLink
          class="block bg-gradient-to-br from-amber-50 to-orange-50 rounded-lg border border-amber-200/60 overflow-hidden group cursor-pointer hover:shadow-sm transition-all duration-300"
          :to="saleHorizontalAds[0]?.link || '#'"
          :target="saleHorizontalAds[0]?.open_external ? '_blank' : '_self'"
        >
          <div class="relative h-24 overflow-hidden">
            <img
              :src="saleHorizontalAds[0]?.image"
              alt="Ad"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
            <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
            <div class="absolute top-2 right-2">
              <span class="text-[9px] bg-amber-500 text-white px-1.5 py-0.5 rounded font-bold">AD</span>
            </div>
            <div class="absolute bottom-2 left-2 right-2">
              <h4 class="font-semibold text-white text-xs line-clamp-1">{{ saleHorizontalAds[0]?.title }}</h4>
              <p class="text-amber-100 text-[10px] mt-0.5">{{ saleHorizontalAds[0]?.offer_title }}</p>
            </div>
          </div>
        </NuxtLink>
      </div>

      <!-- Featured Deal - Compact Vertical Banner -->
      <div class="mb-4" v-if="saleVerticalAds.length > 0">
        <div class="flex items-center gap-1.5 mb-2">
          <UIcon name="i-heroicons-fire" class="w-3 h-3 text-red-500" />
          <span class="text-[10px] uppercase text-gray-500 font-semibold tracking-wide">Hot Deal</span>
        </div>

        <NuxtLink
          :to="saleVerticalAds[0]?.link || '#'"
          :target="saleVerticalAds[0]?.open_external ? '_blank' : '_self'"
          class="block bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm group cursor-pointer hover:shadow-lg transition-all duration-300"
        >
          <div class="relative h-48 overflow-hidden">
            <img
              :src="saleVerticalAds[0]?.image"
              alt="Featured Deal"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
            <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent"></div>
            <div class="absolute top-2 left-2">
              <span class="bg-red-500 text-white text-[9px] px-2 py-1 rounded-full font-bold flex items-center gap-1">
                <UIcon name="i-heroicons-bolt" class="w-2.5 h-2.5" />
                {{ saleVerticalAds[0]?.offer_title || 'Limited Offer' }}
              </span>
            </div>
            <div class="absolute bottom-0 left-0 right-0 p-3">
              <h4 class="font-bold text-white text-sm line-clamp-2">{{ saleVerticalAds[0]?.title }}</h4>
              <p class="text-gray-200 text-[10px] mt-1 line-clamp-1">{{ saleVerticalAds[0]?.description }}</p>
              <div class="mt-2 flex items-center gap-1 text-emerald-400 text-[10px] font-semibold">
                <span>Shop Now</span>
                <UIcon name="i-heroicons-arrow-right" class="w-3 h-3" />
              </div>
            </div>
          </div>
        </NuxtLink>
      </div>

      <!-- Quick Stats -->
      <div class="bg-gray-50 rounded-lg p-3 border border-gray-100">
        <div class="grid grid-cols-2 gap-2">
          <div class="text-center">
            <div class="text-lg font-bold text-emerald-600">{{ totalListings }}</div>
            <div class="text-[10px] text-gray-500">Total Ads</div>
          </div>
          <div class="text-center">
            <div class="text-lg font-bold text-blue-600">{{ categories?.length || 0 }}</div>
            <div class="text-[10px] text-gray-500">Categories</div>
          </div>
        </div>
      </div>
    </div>
    <!-- Fixed bottom CTA for mobile - Compact -->
    <div
      class="lg:hidden sticky bottom-0 p-2.5 bg-gradient-to-r from-emerald-600 to-teal-600 border-t border-emerald-500 shadow-lg z-20"
    >
      <NuxtLink
        to="/sale/my-posts?tab=post-sale"
        class="w-full flex items-center justify-center gap-1.5 py-2.5 bg-white text-emerald-700 rounded-lg font-bold text-sm shadow-sm hover:bg-emerald-50 transition-colors"
        @click="handleButtonClick('post-your-ad-2')"
      >
        <div
          v-if="loadingButtons.has('post-your-ad-2')"
          class="dotted-spinner emerald w-4 h-4"
        ></div>
        <UIcon v-else name="i-heroicons-plus-circle" class="w-4 h-4" />
        <span v-if="!loadingButtons.has('post-your-ad-2')">Post Free Ad</span>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
// Loading state for buttons
const { get } = useApi();
const saleHorizontalAds = ref([]);
const saleVerticalAds = ref([]);
const loadingButtons = ref(new Set());

async function getSaleHorizontalAds() {
  try {
    const response = await get(`/sale/sponsored-horizontal/`);
    saleHorizontalAds.value = response.data;
  } catch (error) {
    console.error("Error fetching horizontal ads:", error);
  }
}
await getSaleHorizontalAds();
async function getSaleVerticalAds() {
  try {
    const response = await get(`/sale/sponsored-vertical/`);
    saleVerticalAds.value = response.data;
  } catch (error) {
    console.error("Error fetching vertical ads:", error);
  }
}
await getSaleVerticalAds();

// Function to handle button click and show loading
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
  // Remove loading state after navigation (cleanup happens in route change)
  setTimeout(() => {
    loadingButtons.value.delete(buttonId);
  }, 3000); // Fallback timeout
};

// Watch for route changes to clear loading states
const route = useRoute();
watch(
  () => route.path,
  () => {
    loadingButtons.value.clear();
  }
);

const props = defineProps({
  isMobileFilterOpen: {
    type: Boolean,
    default: false,
  },
  categories: {
    type: Array,
    default: () => [],
  },
  totalListings: {
    type: Number,
    default: 0,
  },
  selectedCategory: {
    type: [Number, String, null],
    default: null,
  },
  selectedSubcategory: {
    type: [String, null],
    default: null,
  },
  expandedCategories: {
    type: Object,
    default: () => ({}),
  },
});

// Debug: Log categories to see the structure
import { watch } from "vue";
watch(
  () => props.categories,
  (newCategories) => {
    if (newCategories?.length > 0) {
    }
  },
  { immediate: true }
);

const emits = defineEmits([
  "toggle-mobile-sidebar",
  "select-category",
  "select-subcategory",
  "toggle-subcategories",
]);

// Function to toggle mobile sidebar
function toggleMobileSidebar() {
  emits("toggle-mobile-sidebar");
}

// Category selection function
function selectCategory(categoryId) {
  emits("select-category", categoryId);

  // Close the sidebar on mobile when a category is selected
  if (typeof window !== "undefined" && window.innerWidth < 1024) {
    toggleMobileSidebar();
  }
}

// Subcategory selection function
function selectSubcategory(subcategoryId) {
  emits("select-subcategory", subcategoryId);

  // Close the sidebar on mobile when a subcategory is selected
  if (typeof window !== "undefined" && window.innerWidth < 1024) {
    toggleMobileSidebar();
  }
}

// Toggle subcategories function
function toggleSubcategories(category) {
  emits("toggle-subcategories", category);
}

// Get category icon - now with better fallbacks based on category names
function getCategoryIcon(categoryId, categoryName = "") {
  // First try ID-based mapping for known categories
  const idIconMapping = {
    1: "i-heroicons-home", // Home & Garden
    2: "i-heroicons-truck", // Vehicles
    3: "i-heroicons-device-phone-mobile", // Electronics/Mobile
    4: "i-heroicons-trophy", // Sports & Hobbies
    5: "i-heroicons-building-office-2", // Real Estate/Property
    6: "i-heroicons-cube", // Products/Items
    7: "i-heroicons-computer-desktop", // Electronics/Computers
    8: "i-heroicons-musical-note", // Entertainment/Music
    9: "i-heroicons-sparkles", // Fashion/Beauty
    10: "i-heroicons-academic-cap", // Education/Books
    11: "i-heroicons-briefcase", // Business/Services
    12: "i-heroicons-heart", // Health & Wellness
    13: "i-heroicons-wrench-screwdriver", // Tools & Equipment
    14: "i-heroicons-gift", // Gifts & Collectibles
    15: "i-heroicons-camera", // Photography
    16: "i-heroicons-beaker", // Baby & Kids
    17: "i-heroicons-shopping-bag", // Shopping/Retail
    18: "i-heroicons-cog-6-tooth", // Machinery/Industrial
    19: "i-heroicons-puzzle-piece", // Games & Toys
    20: "i-heroicons-map", // Travel & Tourism
  };

  if (idIconMapping[categoryId]) {
    return idIconMapping[categoryId];
  }

  // Fallback to name-based mapping (case insensitive)
  const lowerName = categoryName.toLowerCase();
  if (
    lowerName.includes("vehicle") ||
    lowerName.includes("car") ||
    lowerName.includes("bike")
  ) {
    return "i-heroicons-truck";
  }
  if (
    lowerName.includes("home") ||
    lowerName.includes("house") ||
    lowerName.includes("property")
  ) {
    return "i-heroicons-home";
  }
  if (
    lowerName.includes("electronic") ||
    lowerName.includes("mobile") ||
    lowerName.includes("phone")
  ) {
    return "i-heroicons-device-phone-mobile";
  }
  if (
    lowerName.includes("fashion") ||
    lowerName.includes("cloth") ||
    lowerName.includes("beauty")
  ) {
    return "i-heroicons-sparkles";
  }
  if (
    lowerName.includes("sport") ||
    lowerName.includes("game") ||
    lowerName.includes("toy")
  ) {
    return "i-heroicons-trophy";
  }
  if (
    lowerName.includes("business") ||
    lowerName.includes("service") ||
    lowerName.includes("job")
  ) {
    return "i-heroicons-briefcase";
  }

  // Default fallback
  return "i-heroicons-squares-2x2";
}
</script>

<style scoped>
/* Mobile sidebar styles - Compact Commercial */
@media (max-width: 1023px) {
  .filter-sidebar {
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    width: 80%;
    max-width: 280px;
    z-index: 50;
    transition: transform 0.25s ease-out, box-shadow 0.25s ease;
    padding-top: 48px;
    padding-bottom: 60px;
    display: flex;
    flex-direction: column;
    background-color: #ffffff;
    border-radius: 0 16px 16px 0;
  }

  .mobile-sidebar-closed {
    transform: translateX(-100%);
    box-shadow: none;
  }

  .mobile-sidebar-open {
    transform: translateX(0);
    box-shadow: 0 0 40px rgba(0, 0, 0, 0.2);
  }

  .sidebar-scrollable-content {
    max-height: calc(100vh - 108px);
    scrollbar-width: thin;
    scrollbar-color: rgba(16, 185, 129, 0.3) transparent;
  }

  .sidebar-scrollable-content::-webkit-scrollbar {
    width: 3px;
  }

  .sidebar-scrollable-content::-webkit-scrollbar-track {
    background: transparent;
  }

  .sidebar-scrollable-content::-webkit-scrollbar-thumb {
    background-color: rgba(16, 185, 129, 0.3);
    border-radius: 10px;
  }
}

/* Desktop styles - Compact */
@media (min-width: 1024px) {
  .filter-sidebar {
    transition: all 0.2s ease;
    border-radius: 12px;
    position: sticky;
    top: 80px;
    max-height: calc(100vh - 100px);
  }

  .filter-sidebar:hover {
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
  }

  .sidebar-scrollable-content {
    max-height: calc(100vh - 120px);
    scrollbar-width: thin;
    scrollbar-color: rgba(16, 185, 129, 0.3) transparent;
  }

  .sidebar-scrollable-content::-webkit-scrollbar {
    width: 3px;
  }

  .sidebar-scrollable-content::-webkit-scrollbar-track {
    background: transparent;
  }
  
  .sidebar-scrollable-content::-webkit-scrollbar-thumb {
    background-color: rgba(16, 185, 129, 0.3);
    border-radius: 10px;
  }
}

/* Dotted Spinner Styles */
.dotted-spinner {
  border: 2px dotted #10b981;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  flex-shrink: 0;
}

.dotted-spinner.white {
  border-color: #ffffff;
}

.dotted-spinner.emerald {
  border-color: #10b981;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
