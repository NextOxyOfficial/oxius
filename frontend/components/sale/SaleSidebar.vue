<template>  <!-- Sidebar with filters -->
  <div
    class="filter-sidebar lg:w-72 bg-white rounded-lg shadow-sm border border-gray-100"
    :class="[
      isMobileFilterOpen ? 'mobile-sidebar-open' : 'mobile-sidebar-closed',
      'lg:block',
    ]"
  >
    <!-- Mobile Header -->
    <div class="lg:hidden sticky top-0 flex items-center justify-between p-4 border-b border-gray-100 bg-white z-20">
      <h2 class="text-lg font-medium text-primary-700">
        <span class="flex items-center gap-2">
          <UIcon name="i-heroicons-funnel" class="h-5 w-5" />
          Browse Filters
        </span>
      </h2>
      <UButton
        icon="i-heroicons-x-mark"
        size="sm"
        color="primary"
        variant="soft"
        class="ml-auto"
        @click="toggleMobileSidebar"
        aria-label="Close Filters"
      />
    </div>

    <!-- Main Content Area -->
    <div class="overflow-y-auto sidebar-content p-5 flex-grow sidebar-scrollable-content">
      <!-- Categories Section -->
      <div class="mb-6 border-b border-gray-100 pb-6">
        <h2 class="text-base font-semibold text-gray-800 mb-4 flex items-center">
          <UIcon name="i-heroicons-squares-2x2" class="w-5 h-5 mr-2 text-primary-600" />
          Categories
        </h2>
        <ul class="space-y-1.5">
          <!-- All Categories option -->
          <li>
            <button
              @click="selectCategory(null)"
              class="w-full text-left px-3 py-2 rounded-md flex items-center justify-between transition-colors duration-200"
              :class="
                !selectedCategory
                  ? 'bg-primary-100 text-primary-700 font-medium shadow-sm'
                  : 'text-gray-800 hover:bg-gray-50'
              "
            >
              <span class="flex items-center gap-2">
                <UIcon name="i-heroicons-home" class="w-4 h-4" />
                All Categories
              </span>
              <span
                class="bg-primary-100 text-primary-600 text-xs px-2 py-0.5 rounded-full font-medium"
              >
                {{ totalListings }}
              </span>
            </button>
          </li>
          <!-- Individual categories -->
          <li v-for="category in categories" :key="category.id" class="mb-1">
            <div>
              <button
                @click="selectCategory(category.id)"
                class="w-full text-left px-3 py-2 rounded-md flex items-center justify-between transition-colors duration-200"
                :class="
                  selectedCategory === category.id
                    ? 'bg-primary-50 text-primary-700 font-medium shadow-sm'
                    : 'text-gray-800 hover:bg-gray-50'
                "
              >
                <span class="flex items-center gap-2">
                  <UIcon :name="getCategoryIcon(category.id)" class="w-4 h-4" />
                  {{ category.name }}
                </span>

                <div class="flex items-center">
                  <span
                    :class="[
                      'text-xs px-2 py-0.5 rounded-full',
                      selectedCategory === category.id 
                        ? 'bg-primary-100 text-primary-600 font-medium' 
                        : 'bg-gray-100 text-gray-600'
                    ]"
                  >
                    {{ category?.post_count }}
                  </span>
                </div>
              </button>
            </div>
          </li>
        </ul>
      </div>
      
      <!-- Post Ad CTA for Desktop & Tablets (Moved from bottom) -->
      <div class="mb-6">
        <div
          class="bg-gradient-to-r from-primary-50 to-primary-100 p-4 rounded-lg border border-primary-200 shadow-sm"
        >
          <h3
            class="text-base font-medium text-primary-700 mb-2 flex items-center gap-1"
          >
            <UIcon name="i-heroicons-tag" class="w-4 h-4" />
            Looking to List a Sale?
          </h3>          <p class="text-sm text-gray-600 mb-3">
            List your items easily and reach thousands of potential buyers in your
            area.
          </p>
          <UButton
            to="/sale/my-posts?tab=post-sale"
            color="primary"
            size="sm"
            class="w-full flex items-center justify-center gap-1 shadow-sm"
          >
            <UIcon name="i-heroicons-plus-circle" class="w-4 h-4" />
            Post Your Ad
          </UButton>
        </div>
      </div>

      <!-- Sponsored Ad Section -->
      <div class="mb-6">
        <h3
          class="text-xs uppercase text-gray-600 font-medium mb-3 flex items-center gap-1.5 border-b border-gray-100 pb-2"
        >
          <UIcon name="i-heroicons-sparkles" class="w-4 h-4 text-amber-500" />
          Sponsored
        </h3>

        <!-- Small Regular Ad Card - Improved Design -->
        <div
          class="bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm mb-4 group cursor-pointer hover:shadow-sm transition-all duration-300"
        >
          <div class="flex">
            <div class="w-1/3 bg-gray-50">
              <div class="relative h-full overflow-hidden">
                <img
                  src="https://picsum.photos/300/150?ad=2"
                  alt="Ad"
                  class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                />
                <div class="absolute inset-0 bg-gradient-to-tr from-primary-900/10 to-transparent"></div>
              </div>
            </div>
            <div class="w-2/3 p-3">
              <div class="flex items-start justify-between">
                <h4 class="font-medium text-gray-800 text-sm group-hover:text-primary-600 transition-colors">
                  Latest Electronics
                </h4>
                <span class="text-xs bg-amber-100 text-amber-600 px-1.5 py-0.5 rounded font-medium">Ad</span>
              </div>
              <p class="text-primary-600 text-xs font-medium mt-1">
                Discounts up to 30%
              </p>
              <div class="mt-2 text-xs text-gray-600">Limited time offer</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Long Sponsored Banner - Enhanced Design -->
      <div class="mb-6">
        <h3
          class="text-xs uppercase text-gray-600 font-medium mb-3 flex items-center gap-1.5 border-b border-gray-100 pb-2"
        >
          <UIcon name="i-heroicons-megaphone" class="w-4 h-4 text-blue-500" />
          Featured Deal
        </h3>

        <div
          class="bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm group cursor-pointer hover:shadow-sm transition-all duration-300"
        >
          <div class="relative">
            <img
              src="https://picsum.photos/300/600?ad=special"
              alt="Special Featured Deal"
              class="w-full h-96 object-cover group-hover:scale-105 transition-transform duration-700 ease-in-out"
            />
            <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent"></div>
            <div class="absolute top-3 left-3">
              <span
                class="bg-blue-500 text-white text-xs px-2 py-1 rounded-full font-medium flex items-center gap-1 shadow-sm"
              >
                <UIcon name="i-heroicons-clock" class="w-3 h-3" />
                Limited Time
              </span>
            </div>
            <div
              class="absolute bottom-0 left-0 w-full p-4"
            >
              <h4 class="font-semibold text-white text-base">Summer Sale</h4>
              <p class="text-blue-50 text-sm font-medium mt-1">
                Up to 50% off on selected items
              </p>
              <UButton href='/eshop' color="white" class="mt-3 shadow-sm hover:bg-white hover:text-blue-600 transition-colors" variant="solid">
                Shop Now
              </UButton>
            </div>
          </div>
        </div>
      </div>
    </div>    <!-- Fixed bottom CTA for mobile -->
    <div class="lg:hidden sticky bottom-0 p-4 bg-white border-t border-gray-100 shadow-sm z-20">
      <UButton
        to="/sale/my-posts?tab=post-sale"
        color="primary"
        size="sm"
        class="w-full flex items-center justify-center gap-1 shadow-sm"
      >
        <UIcon name="i-heroicons-plus-circle" class="w-4 h-4" />
        Post Your Ad
      </UButton>
    </div>
  </div>
</template>

<script setup>
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
  if (typeof window !== 'undefined' && window.innerWidth < 1024) {
    toggleMobileSidebar();
  }
}

// Subcategory selection function
function selectSubcategory(subcategoryId) {
  emits("select-subcategory", subcategoryId);
  
  // Close the sidebar on mobile when a subcategory is selected
  if (typeof window !== 'undefined' && window.innerWidth < 1024) {
    toggleMobileSidebar();
  }
}

// Toggle subcategories function
function toggleSubcategories(category) {
  emits("toggle-subcategories", category);
}

// Get category icon
function getCategoryIcon(categoryId) {
  const iconMapping = {
    1: "i-heroicons-home",
    2: "i-heroicons-truck",
    3: "i-heroicons-device-phone-mobile",
    4: "i-heroicons-trophy",
    5: "i-heroicons-building-office-2",
    6: "i-heroicons-square-3-stack-3d",  };
  return iconMapping[categoryId] || "i-heroicons-squares-2x2";
}
</script>

<style scoped>
/* Mobile sidebar styles */
@media (max-width: 1023px) {
  .filter-sidebar {
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    width: 85%;
    max-width: 320px;
    z-index: 50;
    transition: transform 0.3s ease-in-out, box-shadow 0.3s ease;
    padding-top: 60px; /* Add padding for header */
    padding-bottom: 80px; /* Add padding for footer */
    display: flex;
    flex-direction: column;
    background-color: #ffffff;
  }

  .mobile-sidebar-closed {
    transform: translateX(-100%);
    box-shadow: none;
  }

  .mobile-sidebar-open {
    transform: translateX(0);
    box-shadow: 0 0 25px rgba(0, 0, 0, 0.15);
  }
  
  .sidebar-scrollable-content {
    max-height: calc(100vh - 140px);
    scrollbar-width: thin;
    scrollbar-color: rgba(0, 0, 0, 0.2) transparent;
  }

  .sidebar-scrollable-content::-webkit-scrollbar {
    width: 4px;
  }

  .sidebar-scrollable-content::-webkit-scrollbar-track {
    background: transparent;
  }

  .sidebar-scrollable-content::-webkit-scrollbar-thumb {
    background-color: rgba(0, 0, 0, 0.2);
    border-radius: 10px;
  }
}

/* Desktop styles */
@media (min-width: 1024px) {
  .filter-sidebar {
    transition: all 0.3s ease;
    border-radius: 0.5rem;
  }

  .filter-sidebar:hover {
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);
  }
  
  .sidebar-scrollable-content {
    scrollbar-width: thin;
    scrollbar-color: rgba(0, 0, 0, 0.2) transparent;
  }
  
  .sidebar-scrollable-content::-webkit-scrollbar {
    width: 4px;
  }

  .sidebar-scrollable-content::-webkit-scrollbar-track {
    background: transparent;
  }

  .sidebar-scrollable-content::-webkit-scrollbar-thumb {
    background-color: rgba(0, 0, 0, 0.2);
    border-radius: 10px;
  }
}
</style>
