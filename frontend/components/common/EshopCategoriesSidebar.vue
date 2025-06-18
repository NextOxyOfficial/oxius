<template>
  <!-- Categories Sidebar -->
  <transition name="slide">
    <div
      v-if="isOpen"
      class="fixed top-0 left-0 h-full z-40 bg-white dark:bg-gray-900 shadow-sm border-r border-gray-200 dark:border-gray-700 w-80 overflow-hidden flex flex-col"
    >
      <div class="pt-safe sticky top-0 z-10">
        <div
          class="p-4 border-b border-gray-200 dark:border-gray-800 flex items-center justify-between bg-white/95 dark:bg-gray-900/95 backdrop-blur-md mt-[60px] sm:mt-0"
        >
          <h2
            class="text-lg font-medium text-gray-800 dark:text-gray-300 flex items-center"
          >
            <UIcon
              name="i-heroicons-circle-stack"
              class="mr-2.5 size-5 text-emerald-500"
            />
            Categories
          </h2>
          <button
            @click="$emit('close')"
            class="p-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-600"
          >
            <UIcon name="i-heroicons-x-mark" class="size-5" />
          </button>
        </div>
      </div>

      <div class="overflow-y-auto flex-1 py-4 px-4">
        <!-- Featured Categories Section -->
        <div class="mb-4">
          <p
            class="text-xs font-medium uppercase tracking-wider text-gray-600 dark:text-gray-600 mb-3 ml-1"
          >
            BROWSE CATEGORIES
          </p>
          <ul class="space-y-0.5">
            <li v-for="category in displayedCategories" :key="category.id">
              <button
                @click="handleCategorySelect(category.id)"
                class="w-full text-left px-4 py-3 rounded-lg flex items-center gap-3.5 transition-all"
                :class="
                  selectedCategory === category.id
                    ? 'bg-emerald-200 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 font-medium'
                    : 'hover:bg-gray-100 dark:hover:bg-gray-800/60 text-gray-800 dark:text-gray-400'
                "
              >                <div
                  class="flex-shrink-0 size-8 flex items-center justify-center rounded-md bg-gray-100 dark:bg-gray-800"
                >                  <!-- Dynamic category icon/image -->
                  <img
                    v-if="shouldShowImage(category)"
                    :src="getCategoryImageUrl(category.image)"
                    :alt="category.name"
                    class="size-5 object-contain category-image rounded"
                    :class="{
                      'brightness-110 saturate-150': selectedCategory === category.id,
                      'brightness-95 saturate-100': selectedCategory !== category.id
                    }"
                    @error="onImageError($event, category)"
                    loading="lazy"
                  />
                  <UIcon
                    v-else
                    :name="getCategoryIcon(category.name)"
                    class="size-4.5"
                    :class="
                      selectedCategory === category.id
                        ? 'text-emerald-500'
                        : 'text-gray-600 dark:text-gray-600'
                    "
                  />
                </div>
                <span class="truncate font-medium">{{ category.name }}</span>
                <div
                  v-if="selectedCategory === category.id"
                  class="ml-auto flex-shrink-0 size-2 rounded-full bg-emerald-500"
                ></div>
              </button>
            </li>
          </ul>

          <div
            v-if="hasMoreCategoriesToLoad"
            class="pt-4 pb-2 flex justify-center"
          >
            <UButton
              @click="$emit('loadMore')"
              color="gray"
              variant="soft"
              size="sm"
              class="w-full"
            >
              <UIcon name="i-heroicons-arrow-down" class="size-4 mr-1" />
              Load more categories
            </UButton>
          </div>
        </div>

        <!-- Divider -->
        <div
          class="border-t border-gray-200 dark:border-gray-700/60 my-6"
        ></div>

        <!-- Sell on eShop Section - Enhanced Design -->
        <div class="relative overflow-hidden rounded-xl shadow-sm group">
          <!-- Gradient background with pattern -->
          <div
            class="absolute inset-0 bg-gradient-to-br from-emerald-500/90 via-emerald-600 to-emerald-700 opacity-90"
          ></div>
          <!-- Background pattern -->
          <div
            class="absolute inset-0 opacity-10 bg-[radial-gradient(circle_at_1px_1px,white_1px,transparent_0)]"
            style="background-size: 10px 10px"
          ></div>

          <div class="relative p-5 text-white">
            <div class="flex items-start">
              <div class="bg-white/20 backdrop-blur-sm p-2.5 rounded-lg mr-3">
                <UIcon name="i-heroicons-shopping-bag" class="size-6" />
              </div>
              <div>
                <h3 class="font-semibold text-lg text-white">
                  Become a Seller
                </h3>
                <p class="text-sm mt-1.5 text-white/90 leading-relaxed">
                  Start selling your products in our marketplace and reach
                  thousands of customers.
                </p>
              </div>
            </div>

            <UButton
              color="white"
              variant="solid"
              size="md"
              class="mt-4 w-full font-medium shadow-sm group-hover:shadow-sm transition-all"
              @click="$emit('sellerRegistration')"
            >
              <UIcon
                name="i-heroicons-arrow-right"
                class="mr-1.5 size-4 transition-transform group-hover:translate-x-0.5"
              />
              Start Selling Today
            </UButton>
          </div>
        </div>

        <!-- Customer Support Section -->
        <div
          class="mt-5 rounded-xl bg-white dark:bg-gray-800/70 border border-gray-100 dark:border-gray-700/50 shadow-sm p-4"
        >
          <h3
            class="font-medium text-gray-800 dark:text-gray-300 flex items-center"
          >
            <UIcon
              name="i-heroicons-chat-bubble-left-right"
              class="mr-2 size-5 text-blue-500"
            />
            Customer Support
          </h3>
          <p class="text-sm mt-2 text-gray-600 dark:text-gray-400">
            Our team is here to help you with any questions about your orders or
            products.
          </p>
          <div class="mt-3 flex gap-2">
            <UButton
              color="blue"
              variant="soft"
              size="sm"
              class="flex-1"
              @click="$emit('contactSupport', 'chat')"
            >
              <UIcon name="i-heroicons-chat-bubble-oval-left" class="mr-1.5" />
              Live Chat
            </UButton>
            <UButton
              color="gray"
              variant="outline"
              size="sm"
              class="flex-1"
              @click="$emit('contactSupport', 'email')"
            >
              <UIcon name="i-heroicons-envelope" class="mr-1.5" />
              Email
            </UButton>
          </div>
        </div>

        <!-- eShop Manager Button -->
        <div class="mt-6 mb-20">
          <UButton
            color="indigo"
            variant="solid"
            class="w-full group py-3 font-medium"
            @click="$emit('eshopManager')"
          >
            <div class="flex items-center justify-center">
              <UIcon
                name="i-heroicons-building-storefront"
                class="size-5 mr-2"
              />
              eShop Manager
            </div>
          </UButton>
        </div>
      </div>
    </div>
  </transition>

  <!-- Backdrop overlay when sidebar is open -->
  <div
    v-if="isOpen"
    class="fixed inset-0 bg-black/30 dark:bg-black/50 backdrop-blur-sm z-30"
    @click="$emit('close')"
  ></div>
</template>

<script setup>
// Props
const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  displayedCategories: {
    type: Array,
    default: () => [],
  },
  selectedCategory: {
    type: [String, Number, null],
    default: null,
  },
  hasMoreCategoriesToLoad: {
    type: Boolean,
    default: false,
  },
});

// Emits
const emit = defineEmits([
  "close",
  "categorySelect",
  "loadMore",
  "sellerRegistration",
  "contactSupport",
  "eshopManager",
]);

// Reactive data for tracking image load errors
const imageErrors = ref(new Set());

// Watch for category changes to reset image errors
watch(() => props.displayedCategories, () => {
  imageErrors.value.clear();
}, { deep: true });

// Get category image URL
function getCategoryImageUrl(imagePath) {
  if (!imagePath) return '';
  
  let finalUrl;
  
  // Handle different URL formats
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    finalUrl = imagePath;
  } else if (imagePath.startsWith('/media/')) {
    finalUrl = imagePath;
  } else if (imagePath.startsWith('media/')) {
    finalUrl = `/${imagePath}`;
  } else if (imagePath.startsWith('images/') || imagePath.includes('images/')) {
    // Django ImageField typically uploads to media/images/
    finalUrl = `/media/${imagePath}`;
  } else {
    // Default to media/category_icons/ folder for backward compatibility
    finalUrl = `/media/category_icons/${imagePath}`;
  }
  
  return finalUrl;
}

// Handle image load errors
function onImageError(event, category) {
  // Track failed images
  imageErrors.value.add(category.id);
}

// Check if image should be shown (not in error state)
function shouldShowImage(category) {
  const hasImage = category.image && category.image.trim();
  const notInError = !imageErrors.value.has(category.id);
  
  return hasImage && notInError;
}

// Get category icon by name (fallback for categories without images)
function getCategoryIcon(categoryName) {
  // Enhanced mapping of category names to icons
  const iconMapping = {
    // Technology & Electronics
    Electronics: "i-heroicons-device-phone-mobile",
    Computer: "i-heroicons-computer-desktop",
    Mobile: "i-heroicons-device-phone-mobile",
    Laptop: "i-heroicons-computer-desktop",
    Gaming: "i-heroicons-puzzle-piece",
    
    // Fashion & Apparel
    Fashion: "i-heroicons-sparkles",
    Clothing: "i-heroicons-sparkles",
    Shoes: "i-heroicons-sparkles",
    Accessories: "i-heroicons-sparkles",
    Jewelry: "i-heroicons-sparkles",
    
    // Home & Living
    Home: "i-heroicons-home",
    Furniture: "i-heroicons-home",
    Kitchen: "i-heroicons-home",
    Garden: "i-heroicons-home",
    Appliances: "i-heroicons-home",
    
    // Health & Beauty
    Beauty: "i-heroicons-heart",
    Health: "i-heroicons-heart",
    Skincare: "i-heroicons-heart",
    Makeup: "i-heroicons-heart",
    Wellness: "i-heroicons-heart",
    
    // Sports & Recreation
    Sports: "i-heroicons-trophy",
    Fitness: "i-heroicons-trophy",
    Outdoor: "i-heroicons-trophy",
    
    // Food & Groceries
    Food: "i-heroicons-shopping-bag",
    Groceries: "i-heroicons-shopping-bag",
    Beverages: "i-heroicons-shopping-bag",
    
    // Books & Education
    Books: "i-heroicons-book-open",
    Education: "i-heroicons-book-open",
    Stationery: "i-heroicons-book-open",
    
    // Automotive
    Automotive: "i-heroicons-truck",
    Car: "i-heroicons-truck",
    Vehicle: "i-heroicons-truck",
    
    // Default categories
    Others: "i-heroicons-tag",
    Miscellaneous: "i-heroicons-tag",
  };
  
  // Case-insensitive matching
  const normalizedName = categoryName ? categoryName.toLowerCase() : '';
  const matchedKey = Object.keys(iconMapping).find(key => 
    key.toLowerCase() === normalizedName || 
    normalizedName.includes(key.toLowerCase())
  );
  
  return iconMapping[matchedKey] || iconMapping[categoryName] || "i-heroicons-tag";
}

// Handle category selection
function handleCategorySelect(categoryId) {
  emit("categorySelect", categoryId);
  // Remove the automatic close emit - let the parent handle closing
  // emit('close')
}
</script>

<style scoped>
/* Sidebar slide animation */
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s ease;
}

.slide-enter-from,
.slide-leave-to {
  transform: translateX(-100%);
}

/* Category image styling */
.category-image {
  transition: all 0.2s ease;
  border-radius: 4px;
}

.category-image:hover {
  transform: scale(1.05);
}

/* Loading state for images */
.category-image-loading {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
}

@keyframes loading {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

/* Dark mode image adjustments */
.dark .category-image {
  filter: brightness(0.9);
}

.dark .category-image:hover {
  filter: brightness(1.1);
}

/* Hide scrollbar */
.overflow-y-auto {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* Internet Explorer 10+ */
}

.overflow-y-auto::-webkit-scrollbar {
  display: none; /* WebKit */
}

/* Alternative class for hiding scrollbar if needed */
.hide-scrollbar {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* Internet Explorer 10+ */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none; /* WebKit */
}
</style>
