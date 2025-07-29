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
      />
      <CommonProductDetailsCard
        :seeDetails="false"
        :currentProduct="currentProduct"
        :increaseProductViews="increaseProductViews"
        v-else
      />
    </UContainer>
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

// Sidebar state
const isSidebarOpen = ref(false);
const displayedCategories = ref([]);
const hasMoreCategoriesToLoad = ref(false);
const isLoadingMoreCategories = ref(false);
const categories = ref([]);

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
