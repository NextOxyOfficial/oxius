<template>
  <PublicSection>
    <!-- Categories Sidebar Component -->
    <CommonEshopCategoriesSidebar
      :isOpen="isSidebarOpen"
      :displayedCategories="displayedCategories"
      :selectedCategory="null"
      :hasMoreCategoriesToLoad="hasMoreCategoriesToLoad"
      :isLoadingMore="isLoadingMoreCategories"
      @close="toggleSidebar"
      @categorySelect="navigateToCategory"
      @loadMore="loadMoreCategories"
      @sellerRegistration="goToSellerRegistration"
      @contactSupport="contactSupport"
      @eshopManager="navigateToEshopManager"
    />

    <UContainer>
      <CommonProductDetailsCard2
        :currentProduct="currentProduct"
        v-if="currentProduct.is_advanced"
        :increaseProductViews="increaseProductViews"
        @close-and-reopen-modal="handleModalProductChange"
      />
      <CommonProductDetailsCard
        :seeDetails="false"
        :currentProduct="currentProduct"
        :increaseProductViews="increaseProductViews"
        @close-and-reopen-modal="handleModalProductChange"
        v-else
      />
    </UContainer>

    <!-- Product Quick View Modal -->
    <UModal v-model="isQuickViewModalOpen" :ui="modalUiConfig">
      <div>
        <div class="bg-white dark:bg-slate-800 rounded-xl">
          <CommonProductDetailsCard
            :current-product="selectedModalProduct"
            :modal="true"
            :seeDetails="true"
            @close-modal="closeQuickViewModal"
            @close-and-reopen-modal="handleNestedModalProductChange"
          />
        </div>
      </div>
    </UModal>
  </PublicSection>
</template>

<script setup>
import { CommonEshopCategoriesSidebar } from "#components";
import { onMounted, onUnmounted, ref } from "vue";

definePageMeta({
  layout: "eshop",
});
const { get, patch } = useApi();
const route = useRoute();
const router = useRouter();

const currentProduct = ref({});

// Quick view modal state
const isQuickViewModalOpen = ref(false);
const selectedModalProduct = ref({});

// Sidebar state
const isSidebarOpen = ref(false);
const displayedCategories = ref([]);
const hasMoreCategoriesToLoad = ref(false);
const isLoadingMoreCategories = ref(false);
const categories = ref([]);

const modalUiConfig = computed(() => ({
  width: "w-full sm:max-w-4xl",
  height: "h-auto",
  container: "flex flex-col h-auto mt-20 p-0 sm:p-0",
  padding: "p-0",
  transition: {
    enter: "duration-300 ease-out",
    enterFrom: "opacity-0 scale-95",
    enterTo: "opacity-100 scale-100",
    leave: "duration-200 ease-in",
    leaveFrom: "opacity-100 scale-100",
    leaveTo: "opacity-0 scale-95",
  },
}));

// Data fetching
async function fetchCategories() {
  try {
    const res = await get("/product-categories/");
    categories.value = res.data;
    displayedCategories.value = res.data.slice(0, 10);
    hasMoreCategoriesToLoad.value = res.data.length > 10;
  } catch (error) {
    console.error("Error fetching categories:", error);
  }
}

// Sidebar functions
function toggleSidebar() {
  isSidebarOpen.value = !isSidebarOpen.value;
}

function navigateToCategory(categoryId) {
  // Find category to get its slug
  const category = categories.value.find((cat) => cat.id === categoryId);
  if (category && category.slug) {
    router.push(`/eshop?category=${category.slug}`);
  } else {
    router.push("/eshop");
  }
  toggleSidebar();
}

function loadMoreCategories() {
  if (isLoadingMoreCategories.value || !hasMoreCategoriesToLoad.value) return;

  isLoadingMoreCategories.value = true;
  const currentCount = displayedCategories.value.length;
  const nextBatch = categories.value.slice(currentCount, currentCount + 10);
  displayedCategories.value.push(...nextBatch);
  hasMoreCategoriesToLoad.value =
    displayedCategories.value.length < categories.value.length;
  isLoadingMoreCategories.value = false;
}

function goToSellerRegistration() {
  router.push("/shop-manager");
  toggleSidebar();
}

function contactSupport() {
  router.push("/contact-us");
  toggleSidebar();
}

function navigateToEshopManager() {
  router.push("/shop-manager");
}

// Listen for sidebar toggle from header
const handleHeaderSidebarToggle = (event) => {
  isSidebarOpen.value = event.detail.isOpen;
};

async function getProduct() {
  try {
    const { data } = await get(`/products/${route.params.id}/`);
    currentProduct.value = data;
  } catch (error) {
    console.error(error);
  }
}

await Promise.all([getProduct(), fetchCategories()]);

async function increaseProductViews() {
  try {
    const { data } = await patch(`/products/${currentProduct.value.slug}/`, {
      views: currentProduct.value.views + 1,
    });
  } catch (error) {
    console.error(error);
  }
}

// Handle modal product change for quick view in "More from this store" section
function handleModalProductChange(newProduct) {
  // Open the quick view modal with the selected product
  selectedModalProduct.value = newProduct;
  isQuickViewModalOpen.value = true;
}

// Close the quick view modal
function closeQuickViewModal() {
  isQuickViewModalOpen.value = false;
}

// Handle nested modal product changes (when changing products within the modal)
function handleNestedModalProductChange(newProduct) {
  // Update the modal to show the new product
  selectedModalProduct.value = newProduct;
}

onMounted(() => {
  // Listen for sidebar toggle from header
  if (process.client) {
    window.addEventListener("eshop-sidebar-toggle", handleHeaderSidebarToggle);
  }
});

onUnmounted(() => {
  // Clean up event listeners
  if (process.client) {
    window.removeEventListener(
      "eshop-sidebar-toggle",
      handleHeaderSidebarToggle
    );
  }
});
</script>
