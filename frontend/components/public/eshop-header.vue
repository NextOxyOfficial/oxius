<template>
  <div
    class="py-3 backdrop-blur-sm max-sm:bg-slate-200/70 bg-white shadow-sm rounded-b-lg transition-all duration-300 z-[99999999] w-full"
    :class="[
      isScrolled
        ? 'fixed top-0 left-0 right-0 backdrop-blur-sm max-sm:bg-slate-200/70 bg-white shadow-sm rounded-b-lg border-gray-200/50 dark:border-gray-800/50'
        : 'sticky top-0 w-full shadow-sm',
      'sm:py-3 py-1.5', // Smaller padding on mobile
    ]"
  >
    <UContainer class="px-2">
      <div class="flex items-center justify-between gap-2">
        <!-- Sidebar toggle button for mobile -->
        <button
          @click="toggleSidebar"
          class="inline-flex items-center justify-center p-2 rounded-lg border border-gray-200/80 dark:border-gray-700/80 bg-white/90 dark:bg-gray-800/80 backdrop-blur-sm hover:bg-gray-50 dark:hover:bg-gray-700/70 transition-all duration-200 shadow-sm hover:shadow flex-shrink-0 group mr-2"
          :class="{
            'text-emerald-500 border-emerald-200 dark:border-emerald-800/50':
              isSidebarOpen,
          }"
        >
          <span class="sr-only">Toggle categories</span>
          <UIcon
            name="i-heroicons-bars-3"
            class="size-5 transition-transform group-hover:scale-110"
          />
        </button>

        <PublicEshopLogo />
        <div class="flex-1">
          <UInput
            v-model="headerSearchQuery"
            icon="i-heroicons-magnifying-glass-20-solid"
            size="sm"
            color="green"
            :trailing="false"
            placeholder="Search products, brands, categories..."
            @input="handleSearchInput"
            @keydown.enter="handleSearchEnter"
          />
        </div>
      </div>
    </UContainer>
  </div>
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
