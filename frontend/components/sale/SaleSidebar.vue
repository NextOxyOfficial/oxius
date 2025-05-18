<template>
  <!-- Sidebar with filters -->
  <div
    class="filter-sidebar lg:w-72 bg-white rounded-lg shadow-sm border border-gray-100 overflow-auto"
    :class="[
      isMobileFilterOpen ? 'mobile-sidebar-open' : 'mobile-sidebar-closed',
      'lg:block',
    ]"
  >
    <div class="p-5 max-sm:pt-4 border-b border-gray-100 bg-white z-10">
      <!-- Mobile Close Button -->
      <div class="flex items-center justify-between mb-4 lg:hidden">
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

      <!-- Categories Section -->
      <div class="mb-6">
        <h2 class="text-lg font-medium text-gray-700 mb-3">Categories</h2>
        <ul class="space-y-1">
          <!-- All Categories option -->
          <li>
            <button
              @click="selectCategory(null)"
              class="w-full text-left px-2 py-1.5 rounded-md flex items-center justify-between"
              :class="
                !selectedCategory
                  ? 'bg-primary/10 text-primary font-medium'
                  : 'text-gray-700 hover:bg-gray-100'
              "
            >
              <span class="flex items-center gap-2">
                <UIcon name="i-heroicons-squares-2x2" class="w-5 h-5" />
                All Categories
              </span>
              <span
                class="bg-gray-100 text-gray-500 text-xs px-2 py-0.5 rounded-full"
              >
                {{ totalListings }}
              </span>
            </button>
          </li>
          <!-- Individual categories -->
          <li v-for="category in categories" :key="category.id" class="mb-0.5">
            <div>
              <button
                @click="selectCategory(category.id)"
                class="w-full text-left px-2 py-1.5 rounded-md flex items-center justify-between"
                :class="
                  selectedCategory === category.id
                    ? 'bg-primary/10 text-primary font-medium'
                    : 'text-gray-700 hover:bg-gray-100'
                "
              >
                <span class="flex items-center gap-2">
                  <UIcon :name="getCategoryIcon(category.id)" class="w-5 h-5" />
                  {{ category.name }}
                </span>

                <div class="flex items-center">
                  <span
                    class="bg-gray-100 text-gray-500 text-xs px-2 py-0.5 rounded-full mr-1"
                  >
                    {{ category?.post_count }}
                  </span>
                  <!-- <UButton
                    v-if="hasSubcategories(category)"
                    variant="ghost"
                    color="gray"
                    size="xs"
                    class="p-0 h-6 w-6"
                    :icon="
                      expandedCategories.id === category.id
                        ? 'i-heroicons-minus-small'
                        : 'i-heroicons-plus-small'
                    "
                    @click.stop="toggleSubcategories(category)"
                  /> -->
                </div>
              </button>

              <!-- Subcategories -->
              <!-- <transition
                enter-active-class="transition-all duration-200 ease-out"
                leave-active-class="transition-all duration-150 ease-in"
                enter-from-class="opacity-0 max-h-0"
                enter-to-class="opacity-100 max-h-40"
                leave-from-class="opacity-100 max-h-40"
                leave-to-class="opacity-0 max-h-0"
              >
                <ul
                  v-if="
                    expandedCategories?.child_categories?.length > 0 &&
                    hasSubcategories(category)
                  "
                  class="ml-5 mt-1 space-y-1 overflow-hidden border-l-2 border-gray-100 pl-2"
                >
                  <li
                    v-for="subcategory in category.child_categories"
                    :key="subcategory.id"
                  >
                    <button
                      @click.stop="selectSubcategory(subcategory.id)"
                      class="w-full text-left px-2 py-1.5 rounded-md flex items-center justify-between text-sm"
                      :class="
                        selectedSubcategory === subcategory.id
                          ? 'bg-primary/10 text-primary font-medium'
                          : 'text-gray-500 hover:bg-gray-100'
                      "
                    >
                      <span>{{ subcategory.name }}</span>
                      <span class="text-xs text-gray-500">
                        {{ subcategory.count }}
                      </span>
                    </button>
                  </li>
                </ul>
              </transition> -->
            </div>
          </li>
        </ul>
      </div>

      <!-- Looking to List a Sale? Section -->
      <div
        class="mb-6 bg-gradient-to-r from-primary/5 to-primary/10 p-4 rounded-lg border border-primary/20"
      >
        <h3
          class="text-base font-medium text-primary mb-2 flex items-center gap-1"
        >
          <UIcon name="i-heroicons-tag" class="w-4 h-4" />
          Looking to List a Sale?
        </h3>
        <p class="text-sm text-gray-500 mb-3">
          List your items easily and reach thousands of potential buyers in your
          area.
        </p>
        <UButton
          to="/sale/post"
          color="primary"
          size="sm"
          class="w-full flex items-center justify-center gap-1"
        >
          <UIcon name="i-heroicons-plus-circle" class="w-4 h-4" />
          Post Your Ad
        </UButton>
      </div>

      <!-- Sponsored Ads -->
      <div class="mb-6">
        <h3
          class="text-xs uppercase text-gray-500 font-medium mb-2 flex items-center gap-1"
        >
          <UIcon name="i-heroicons-sparkles" class="w-4 h-4 text-amber-500" />
          Sponsored
        </h3>

        <!-- Premium Ad Card -->
        <div
          class="bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm mb-3 group cursor-pointer hover:shadow-sm transition-shadow"
        >
          <div class="relative">
            <img
              src="https://picsum.photos/300/150?ad=1"
              alt="Premium Ad"
              class="w-full h-32 object-cover group-hover:scale-105 transition-transform duration-300"
            />
            <div class="absolute top-2 left-2">
              <span
                class="bg-amber-500 text-white text-xs px-2 py-0.5 rounded font-medium"
                >Premium</span
              >
            </div>
          </div>
          <div class="p-3">
            <h4 class="font-medium text-gray-700">Luxury Apartments</h4>
            <p class="text-primary text-sm font-medium">
              Starting at ৳8,500,000
            </p>
          </div>
        </div>

        <!-- Regular Ad Card -->
        <div
          class="bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm group cursor-pointer hover:shadow-sm transition-shadow"
        >
          <div class="flex">
            <div class="w-1/3">
              <img
                src="https://picsum.photos/300/150?ad=2"
                alt="Ad"
                class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
              />
            </div>
            <div class="w-2/3 p-3">
              <h4 class="font-medium text-gray-700 text-sm">
                Latest Electronics
              </h4>
              <p class="text-primary text-xs font-medium">
                Discounts up to 30%
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Long Height Banner -->
      <div class="mb-6">
        <h3
          class="text-xs uppercase text-gray-500 font-medium mb-2 flex items-center gap-1"
        >
          <UIcon name="i-heroicons-megaphone" class="w-4 h-4 text-blue-500" />
          Featured Deal
        </h3>

        <div
          class="bg-white rounded-lg border border-blue-200 overflow-hidden shadow-sm group cursor-pointer hover:shadow-sm transition-shadow"
        >
          <div class="relative">
            <img
              src="https://picsum.photos/300/600?ad=special"
              alt="Special Featured Deal"
              class="w-full h-96 object-cover group-hover:scale-102 transition-transform duration-500"
            />
            <div class="absolute top-2 left-2">
              <span
                class="bg-blue-500 text-white text-xs px-2 py-0.5 rounded font-medium"
                >Limited Time</span
              >
            </div>
            <div
              class="absolute bottom-0 left-0 w-full bg-gradient-to-t from-black/80 to-transparent p-4"
            >
              <h4 class="font-medium text-white text-base">Summer Sale</h4>
              <p class="text-blue-200 text-sm font-medium mt-1">
                Up to 50% off on selected items
              </p>
              <UButton size="xs" color="white" class="mt-2" variant="solid">
                Shop Now
              </UButton>
            </div>
          </div>
        </div>
      </div>

      <!-- Additional filter sections can go here -->
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
}

// Subcategory selection function
function selectSubcategory(subcategoryId) {
  emits("select-subcategory", subcategoryId);
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
    6: "i-heroicons-square-3-stack-3d",
  };
  return iconMapping[categoryId] || "i-heroicons-squares-2x2";
}

// Get category count

// Check if category has subcategories
function hasSubcategories(category) {
  // This would be replaced with actual subcategory check from API data
  return category.sub_categories_count > 0;
}

// Get subcategories for a category
function getSubcategories(categoryId) {
  // Sample subcategories - would be replaced with API data
  const subcategoryMap = {
    1: [
      { id: "1-1", name: "Apartments", count: 23 },
      { id: "1-2", name: "Houses", count: 15 },
      { id: "1-3", name: "Land", count: 7 },
    ],
    2: [
      { id: "2-1", name: "Cars", count: 18 },
      { id: "2-2", name: "Motorcycles", count: 9 },
      { id: "2-3", name: "Commercial", count: 5 },
    ],
    3: [
      { id: "3-1", name: "Phones", count: 14 },
      { id: "3-2", name: "Computers", count: 8 },
      { id: "3-3", name: "TVs", count: 5 },
    ],
  };

  return subcategoryMap[categoryId] || [];
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
    transition: transform 0.3s ease-in-out;
  }

  .mobile-sidebar-closed {
    transform: translateX(-100%);
  }

  .mobile-sidebar-open {
    transform: translateX(0);
    box-shadow: 4px 0 10px rgba(0, 0, 0, 0.1);
  }
}
</style>
