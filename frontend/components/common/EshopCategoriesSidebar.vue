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
              >
                <div
                  class="flex-shrink-0 size-8 flex items-center justify-center rounded-md bg-gray-100 dark:bg-gray-800"
                >
                  <UIcon
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

// Get category icon by name
function getCategoryIcon(categoryName) {
  // Example mapping of category names to icons
  const iconMapping = {
    Electronics: "i-heroicons-device-mobile",
    Fashion: "i-heroicons-tshirt",
    Home: "i-heroicons-home",
    Beauty: "i-heroicons-sparkles",
    Sports: "i-heroicons-football",
  };
  return iconMapping[categoryName] || "i-heroicons-tag";
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
</style>
