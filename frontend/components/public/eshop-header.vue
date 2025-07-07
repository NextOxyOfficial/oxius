<template>
  <header
    class="bg-white border-b border-gray-200 transition-all duration-300 z-[99999999] w-full"
    :class="[
      isScrolled
        ? 'fixed top-0 left-0 right-0 shadow-sm'
        : 'sticky top-0 shadow-sm',
    ]"
  >
    <UContainer class="pl-2 py-1.5">
      <div class="flex items-center justify-between gap-2">
        <!-- Left Section: Sidebar Toggle + Logo -->
        <div class="flex items-center gap-3">
          <!-- Sidebar toggle button -->
          <button
            @click="toggleSidebar"
            class="inline-flex items-center justify-center p-1.5 rounded-lg border border-gray-300 bg-white hover:bg-gray-50 transition-all duration-200 shadow-sm hover:shadow-md flex-shrink-0 group"
            :class="{
              'text-emerald-600 border-emerald-300 bg-emerald-50 hover:bg-emerald-100':
                isSidebarOpen,
              'text-gray-700 hover:text-gray-900': !isSidebarOpen,
            }"
          >
            <span class="sr-only">Toggle categories</span>
            <UIcon
              name="i-heroicons-bars-3"
              class="size-5 transition-transform group-hover:scale-110"
            />
          </button>

          <!-- Logo -->
          <div class="flex-shrink-0">
            <PublicEshopLogo />
          </div>
        </div>

        <!-- Center Section: Search Bar -->
        <div class="flex-1 max-w-2xl mx-2">
          <div class="relative">
            <UInput
              v-model="headerSearchQuery"
              icon="i-heroicons-magnifying-glass-20-solid"
              size="lg"
              color="emerald"
              variant="outline"
              :trailing="false"
              placeholder="Search products, brands, categories..."
              class="w-full"
              :ui="{
                wrapper: 'relative',
                base: 'relative block w-full disabled:cursor-not-allowed disabled:opacity-75 focus:outline-none border-0',
                form: 'form-input',
                rounded: 'rounded-full',
                placeholder: 'placeholder-gray-400',
                size: {
                  lg: 'text-base py-2 px-4'
                },
                icon: {
                  base: 'flex-shrink-0 text-gray-400',
                  color: 'text-gray-400',
                  size: {
                    lg: 'h-5 w-5'
                  }
                },
                color: {
                  emerald: {
                    outline: 'shadow-sm bg-white dark:bg-gray-900 text-gray-900 dark:text-white ring-1 ring-inset ring-gray-300 dark:ring-gray-700 focus:ring-2 focus:ring-emerald-500 dark:focus:ring-emerald-400'
                  }
                },
                default: {
                  size: 'lg',
                  color: 'emerald',
                  variant: 'outline'
                }
              }"
              @input="handleSearchInput"
              @keydown.enter="handleSearchEnter"
            />
          </div>
        </div>
      </div>
    </UContainer>
  </header>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from "vue";

// Handle scroll events
const isScrolled = ref(false);
const handleScroll = () => {
  isScrolled.value = window.scrollY > 80;
};

// Header search functionality
const headerSearchQuery = ref("");

// Debounced search function
let searchTimeout = null;
function handleSearchInput() {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    emitSearchEvent();
  }, 300); // Slightly faster debounce for header search
}

function handleSearchEnter() {
  clearTimeout(searchTimeout);
  emitSearchEvent();
}

function emitSearchEvent() {
  if (process.client) {
    window.dispatchEvent(
      new CustomEvent("eshop-header-search", {
        detail: { searchQuery: headerSearchQuery.value },
      })
    );
  }
}

// Listen for search updates from the main page to sync the header input
const handleSearchSync = (event) => {
  headerSearchQuery.value = event.detail.searchQuery || "";
};

// Sidebar state management using event emitter
const isSidebarOpen = ref(false);

// Create event bus for sidebar communication
const toggleSidebar = () => {
  isSidebarOpen.value = !isSidebarOpen.value;
  // Emit event to communicate with page components
  if (process.client) {
    window.dispatchEvent(
      new CustomEvent("eshop-sidebar-toggle", {
        detail: { isOpen: isSidebarOpen.value },
      })
    );
  }
};

// Listen for sidebar state changes from other components
const handleSidebarStateChange = (event) => {
  isSidebarOpen.value = event.detail.isOpen;
};

onMounted(() => {
  window.addEventListener("scroll", handleScroll);

  // Listen for sidebar state updates
  if (process.client) {
    window.addEventListener(
      "eshop-sidebar-state-update",
      handleSidebarStateChange
    );

    // Listen for search synchronization from main page
    window.addEventListener("eshop-search-sync", handleSearchSync);
  }
});

onBeforeUnmount(() => {
  window.removeEventListener("scroll", handleScroll);

  if (process.client) {
    window.removeEventListener(
      "eshop-sidebar-state-update",
      handleSidebarStateChange
    );

    window.removeEventListener("eshop-search-sync", handleSearchSync);
  }
});
</script>
