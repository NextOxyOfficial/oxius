<template>
  <UContainer class="py-4 md:py-6">
    <div class="min-h-screen">
      <!-- Modern Hero Banner with Layered Design -->
      <div class="relative bg-white rounded-xl md:rounded-2xl shadow-sm mb-8 md:mb-10 overflow-hidden">
        <div class="absolute inset-0 z-0">
          <!-- Banner Background with Blurred Bottom Edge -->
          <div 
            class="h-40 sm:h-48 md:h-60 w-full bg-cover bg-center relative after:absolute after:bottom-0 after:left-0 after:w-full after:h-16 sm:after:h-24 after:bg-gradient-to-t after:from-white after:to-transparent"
            :style="{
              backgroundImage: storeDetails?.store_banner
                ? `url(${storeDetails?.store_banner})`
                : 'url(\'/images/placeholder.jpg?height=800&width=1600\')',
            }"
          >
            <!-- Color Overlay -->
            <div class="absolute inset-0 bg-indigo-900/40 mix-blend-multiply"></div>
            
            <!-- Upload Banner Button -->
            <button
              v-if="isOwner"
              @click="showBannerUpload = true"
              class="absolute top-3 right-3 md:top-4 md:right-4 z-30 bg-white/80 hover:bg-white backdrop-blur-sm text-gray-800 font-medium px-2 py-1 md:px-3 md:py-1.5 rounded text-xs md:text-sm flex items-center gap-1 md:gap-1.5 shadow-sm hover:shadow transition-all"
            >
              <Camera class="w-3 h-3 md:w-4 md:h-4" />
              <span>{{ storeDetails?.store_banner ? "Update Cover" : "Add Cover" }}</span>
            </button>
          </div>
        </div>
        
        <!-- Store Content Section -->
        <div class="relative z-10 pt-20 sm:pt-24 md:pt-32 px-4 sm:px-6 md:px-8 pb-5 md:pb-6">
          <!-- Store Info Flex Container -->
          <div class="flex flex-col md:flex-row md:items-end gap-4 md:gap-6 lg:gap-8">
            <!-- Store Logo with Border -->
            <div class="flex-shrink-0 -mt-20 pt-2 md:-mt-24 lg:-mt-28 relative mx-auto md:mx-0">
              <div class="h-24 w-24 md:h-28 md:w-28 lg:h-32 lg:w-32 rounded-xl bg-white p-1.5 shadow-md">
                <div class="w-full h-full rounded-lg overflow-hidden bg-gray-100">
                  <img 
                    v-if="storeDetails?.store_logo"
                    :src="storeDetails?.store_logo" 
                    alt="Store Logo" 
                    class="w-full h-full object-cover"
                  />
                  <div
                    v-else
                    class="w-full h-full bg-gradient-to-br from-indigo-500 to-blue-600 flex items-center justify-center text-white font-bold text-2xl md:text-3xl"
                  >
                    {{ getInitials(storeDetails?.store_name || "Store") }}
                  </div>
                </div>
                
                <!-- Logo Upload Button -->
                <button
                  v-if="isOwner"
                  @click="showLogoUpload = true"
                  class="absolute -right-2 -bottom-1 z-30 bg-white shadow text-gray-700 rounded-full p-1.5 hover:bg-gray-50 transition-colors"
                >
                  <ImageIcon class="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
            
            <!-- Store Name and Description -->
            <div class="flex-grow text-center md:text-left">
              <h1 class="text-xl sm:text-2xl md:text-3xl font-bold text-gray-900">
                {{ storeDetails?.store_name || "Store Name" }}
              </h1>
              <p class="text-gray-600 text-sm md:text-base mt-1.5 md:mt-2 max-w-2xl" :class="isSeeMore ? '' : 'line-clamp-2'">
                {{ storeDetails?.store_description || "Store description will appear here." }}
              </p>
              <UButton
                v-if="storeDetails?.store_description"
                @click="isSeeMore = !isSeeMore"
                :label="isSeeMore ? 'Read Less' : 'Read More'"
                variant="link"
                size="xs"
                color="gray"
                class="ml-0 pl-0 mt-1"
              />
            </div>
            
            <!-- Store Actions -->
            <div class="mt-3 md:mt-0 flex-shrink-0 text-center md:text-left">
              <UButton 
                v-if="isOwner"
                icon="i-heroicons-adjustments-horizontal" 
                size="sm" 
                color="indigo"
                @click="$router.push('/shop-manager')"
              >
                Manage Store
              </UButton>
            </div>
          </div>
          
          <!-- Store Info Badges -->
          <div class="flex flex-wrap justify-center md:justify-start gap-2 mt-3 md:mt-4">
            <span 
              v-if="storeDetails?.store_address" 
              class="inline-flex items-center bg-gray-100 text-gray-800 rounded-full px-3 py-1 text-xs"
            >
              <MapPin class="w-3 h-3 mr-1" />
              {{ storeDetails?.store_address }}
            </span>
            <span 
              v-if="storeDetails?.phone" 
              class="inline-flex items-center bg-gray-100 text-gray-800 rounded-full px-3 py-1 text-xs"
            >
              <Phone class="w-3 h-3 mr-1" />
              {{ storeDetails?.phone }}
            </span>
            <span 
              class="inline-flex items-center bg-indigo-100 text-indigo-800 rounded-full px-3 py-1 text-xs"
            >
              <UIcon name="i-heroicons-shopping-bag" class="w-3 h-3 mr-1" />
              {{ products.length }} Products
            </span>
          </div>
        </div>
      </div>
      
      <!-- Products Section with Improved Layout -->
      <div class="grid grid-cols-12 gap-x-0 gap-y-3 md:gap-3">
        <!-- Mobile Search Bar - Visible only on small screens -->
        <div class="col-span-12 md:hidden">
          <div class="relative">
            <input
              type="text"
              v-model="searchValue"
              @keyup.enter="handleSearch"
              class="w-full bg-white border border-gray-200 rounded-lg py-2.5 pl-10 pr-3 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-300"
              placeholder="Search products..."
            />
            <Search class="absolute left-3 top-3 w-4 h-4 text-gray-400" />
            <button 
              v-if="searchValue"
              @click="searchValue = ''" 
              class="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
            >
              <X class="w-4 h-4" />
            </button>
          </div>
        </div>
        
        <!-- Mobile Categories Horizontal Scroll - Visible only on small screens -->
        <div class="col-span-12 md:hidden mt-2">
          <div class="flex overflow-x-auto gap-2 pb-1.5 hide-scrollbar">
            <button
              @click="selectedCategory = null"
              class="flex-shrink-0 px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap text-sm"
              :class="selectedCategory === null 
                ? 'bg-indigo-100 text-indigo-800 font-medium' 
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'"
            >
              All Products ({{ products.length }})
            </button>
            
            <button
              v-for="category in uniqueCategories"
              :key="category.id"
              @click="selectedCategory = category.id"
              class="flex-shrink-0 px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap text-sm"
              :class="selectedCategory === category.id 
                ? 'bg-indigo-100 text-indigo-800 font-medium' 
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'"
            >
              {{ category.name }} ({{ getProductCountByCategory(category.id) }})
            </button>
          </div>
        </div>
        
        <!-- Desktop Sidebar: Search and Filters - Hidden on mobile -->
        <div class="hidden md:block md:col-span-4 lg:col-span-3">
          <div class="bg-white rounded-xl shadow-sm p-5 mb-4 sticky top-4">
            <!-- Search Input -->
            <div class="mb-5">
              <label class="block text-sm font-medium text-gray-700 mb-2">Search Products</label>
              <div class="relative">
                <input
                  type="text"
                  v-model="searchValue"
                  @keyup.enter="handleSearch"
                  class="w-full bg-gray-50 border border-gray-200 rounded-md py-2 pl-8 pr-3 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-300"
                  placeholder="Find products..."
                />
                <Search class="absolute left-2.5 top-2.5 w-3.5 h-3.5 text-gray-400" />
                
                <button 
                  v-if="searchValue"
                  @click="searchValue = ''" 
                  class="absolute right-2.5 top-2.5 text-gray-400 hover:text-gray-600"
                >
                  <X class="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
            
            <!-- Category Filter -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="block text-sm font-medium text-gray-700">Categories</label>
                <button 
                  v-if="selectedCategory"
                  @click="selectedCategory = null"
                  class="text-xs text-indigo-600 hover:text-indigo-800"
                >
                  Clear
                </button>
              </div>
              <div class="space-y-1.5 max-h-72 overflow-y-auto pr-1 hide-scrollbar">
                <button
                  @click="selectedCategory = null"
                  class="flex items-center justify-between w-full py-1.5 px-2.5 rounded-md text-sm transition-colors"
                  :class="selectedCategory === null ? 'bg-indigo-50 text-indigo-700 font-medium' : 'text-gray-700 hover:bg-gray-50'"
                >
                  <span>All Products</span>
                  <span class="text-xs py-0.5 px-1.5 rounded bg-gray-100">{{ products.length }}</span>
                </button>
                
                <button
                  v-for="category in uniqueCategories"
                  :key="category.id"
                  @click="selectedCategory = category.id"
                  class="flex items-center justify-between w-full py-1.5 px-2.5 rounded-md text-sm transition-colors"
                  :class="selectedCategory === category.id ? 'bg-indigo-50 text-indigo-700 font-medium' : 'text-gray-700 hover:bg-gray-50'"
                >
                  <span class="truncate mr-1">{{ category.name }}</span>
                  <span class="text-xs py-0.5 px-1.5 rounded bg-gray-100">{{ getProductCountByCategory(category.id) }}</span>
                </button>
              </div>
            </div>
            
            <!-- Additional Filter Section (optional) -->
            <div class="mt-6 pt-5 border-t border-gray-100">
              <h3 class="text-sm font-medium text-gray-700 mb-3">Store Information</h3>
              <div class="flex flex-col space-y-2">
                <div v-if="storeDetails.email" class="text-sm text-gray-500 flex items-center">
                  <UIcon name="i-heroicons-envelope" class="w-4 h-4 mr-2 text-gray-400" />
                  <span>{{ storeDetails.email }}</span>
                </div>
                <div v-if="storeDetails.phone" class="text-sm text-gray-500 flex items-center">
                  <UIcon name="i-heroicons-phone" class="w-4 h-4 mr-2 text-gray-400" />
                  <span>{{ storeDetails.phone }}</span>
                </div>
                <div v-if="storeDetails.store_address" class="text-sm text-gray-500 flex items-start">
                  <UIcon name="i-heroicons-map-pin" class="w-4 h-4 mr-2 text-gray-400 mt-0.5" />
                  <span>{{ storeDetails.store_address }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Main Content: Product Grid -->
        <div class="col-span-12 md:col-span-8 lg:col-span-9">
          <!-- Products Header -->
          <div class="flex items-center justify-between mb-4 md:mb-6">
            <div>
              <h2 class="text-lg md:text-xl font-bold text-gray-800">
                {{ selectedCategory ? uniqueCategories.find(c => c.id === selectedCategory)?.name : 'All Products' }}
                <span class="text-sm font-normal text-gray-500 ml-2">({{ filteredProducts.length }})</span>
              </h2>
            </div>
            
            <!-- Clear Filters Button -->
            <UButton 
              v-if="searchValue || selectedCategory"
              size="xs"
              color="gray"
              variant="soft"
              @click="clearFilters"
              icon="i-heroicons-x-mark"
            >
              Clear Filters
            </UButton>
          </div>
          
          <!-- Products Grid with Responsive Layout -->
          <div v-if="isLoading" class="flex justify-center py-16">
            <UIcon name="i-heroicons-arrow-path" class="animate-spin h-8 w-8 text-gray-300" />
          </div>
          
          <div 
            v-else-if="filteredProducts.length > 0"
            class="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-2"
          >
            <CommonProductCard
              v-for="product in filteredProducts"
              :key="product.id"
              :product="product"
              class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden transition-all duration-300 hover:-translate-y-0.5 hover:shadow-md"
            />
          </div>
          
          <!-- Empty State -->
          <div
            v-else
            class="bg-white rounded-xl border border-gray-100 shadow-sm py-12 md:py-16 px-6 md:px-8 text-center"
          >
            <div class="flex justify-center">
              <div class="bg-gray-100 rounded-full p-4">
                <UIcon name="i-heroicons-rectangle-stack" class="h-6 w-6 md:h-8 md:w-8 text-gray-400" />
              </div>
            </div>
            <h3 class="mt-4 text-base md:text-lg font-medium text-gray-800">No Products Found</h3>
            <p class="mt-2 text-sm md:text-base text-gray-500 max-w-md mx-auto">
              We couldn't find any products matching your current selection. Try changing your search or selecting a different category.
            </p>
            <UButton
              v-if="searchValue || selectedCategory"
              color="gray"
              variant="soft"
              class="mt-5 md:mt-6"
              @click="clearFilters"
            >
              Clear Filters
            </UButton>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Modals remain unchanged -->
    <!-- ...existing code... -->
  </UContainer>
</template>

<script setup>
const { get, patch } = useApi();
const router = useRoute();
const toast = useToast();
const products = ref([]);
const storeDetails = ref({});
const { user, token } = useAuth();
const isLoading = ref(false);
const isSeeMore = ref(false);

// Check if current user is store owner
const isOwner = computed(() => {
  return (
    user.value?.user?.store_username === storeDetails.value?.store_username
  );
});

import {
  Search,
  MapPin,
  Clock,
  Mail,
  ChevronRight,
  X,
  Camera,
  ImageIcon,
  Heart,
  Truck,
  PackageX,
  Phone,
  LocateIcon,
} from "lucide-vue-next";

// Helper to get initials from name
const getInitials = (name) => {
  if (!name) return "";
  return name
    .split(" ")
    .map((word) => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
};

async function getMyProducts() {
  isLoading.value = true;
  try {
    const response = await get(`/store/${router.params.id}/products/`);
    products.value = response.data;
    console.log("Products loaded:", products.value.length);
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error loading products",
      description: "Could not load products. Please try again later.",
      color: "red",
    });
    products.value = [];
  } finally {
    isLoading.value = false;
  }
}

async function getStoreDetails() {
  isLoading.value = true;
  try {
    const { data } = await get(`/store/${router.params.id}/`);
    storeDetails.value = data;
    console.log("Store details loaded successfully");
  } catch (error) {
    console.error("Error fetching store details:", error);
    toast.add({
      title: "Error loading store",
      description: "Could not load store details. Please try again later.",
      color: "red",
    });
  } finally {
    isLoading.value = false;
  }
}

// State for category filtering
const selectedCategory = ref(null);
const searchFocused = ref(false);
const searchValue = ref("");
const visibleSections = reactive({
  categories: false,
  details: false,
  cta: false,
});
const bannerImage = ref(null);
const logoImage = ref(null);
const showBannerUpload = ref(false);
const showLogoUpload = ref(false);

// Get unique categories from products
const uniqueCategories = computed(() => {
  if (!products.value || products.value.length === 0) return [];

  const categories = [];
  const map = new Map();

  products.value.forEach((product) => {
    if (product.category_details && !map.has(product.category_details.id)) {
      map.set(product.category_details.id, true);
      categories.push(product.category_details);
    }
  });

  return categories;
});

// Filter products by selected category
const filteredProducts = computed(() => {
  let result = products.value;

  // Filter by category if selected
  if (selectedCategory.value) {
    result = result.filter(
      (product) => product.category === selectedCategory.value
    );
  }

  // Filter by search term if present
  if (searchValue.value.trim()) {
    const searchTerm = searchValue.value.toLowerCase().trim();
    result = result.filter(
      (product) =>
        product.name?.toLowerCase().includes(searchTerm) ||
        product.description?.toLowerCase().includes(searchTerm) ||
        product.price?.toString().includes(searchTerm)
    );
  }

  return result;
});

// Add a function to handle search submission (for Enter key or button click)
function handleSearch() {
  // Trigger filtering by setting the search value
  console.log("Searching for:", searchValue.value);
  // You could add additional logic here if needed
}

// Helper function to get product count by category
function getProductCountByCategory(categoryId) {
  return products.value.filter((product) => product.category === categoryId)
    .length;
}

// Add function to clear filters
function clearFilters() {
  searchValue.value = '';
  selectedCategory.value = null;
}

// Refs
const bannerRef = ref(null);
const categoriesRef = ref(null);
const detailsRef = ref(null);
const ctaRef = ref(null);

// Handle file uploads with improved error handling
async function handleBannerUpload(e) {
  const files = Array.from(e.target.files);
  const file = files[0];
  if (!file) return;

  try {
    isLoading.value = true;

    // Validate file size (limit to 2MB)
    if (file.size > 2 * 1024 * 1024) {
      throw new Error("File size exceeds 2MB limit");
    }

    // Validate file type
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      throw new Error("Only JPEG, PNG, and WEBP formats are allowed");
    }

    // Convert file to base64
    const base64 = await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = (error) => reject(error);
      reader.readAsDataURL(file);
    });

    // Set local state for preview
    bannerImage.value = base64;

    // Make API call with the proper headers
    const response = await patch(`/store/${router.params.id}/`, {
      store_banner: base64,
    });

    // Show success message
    toast.add({
      title: "Banner Updated",
      description: "Your store banner has been successfully updated",
      color: "green",
    });

    // Hide the upload modal
    showBannerUpload.value = false;

    // Update store details with new data
    storeDetails.value = response.data;
  } catch (error) {
    console.error("Error uploading banner:", error);
    toast.add({
      title: "Upload Failed",
      description:
        error.message || "Could not upload banner. Please try again.",
      color: "red",
    });
  } finally {
    isLoading.value = false;
    // Refresh store details
    await getStoreDetails();
  }
}

async function handleLogoUpload(e) {
  const files = Array.from(e.target.files);
  const file = files[0];
  if (!file) return;

  try {
    isLoading.value = true;

    // Validate file size (limit to 1MB)
    if (file.size > 1 * 1024 * 1024) {
      throw new Error("File size exceeds 1MB limit");
    }

    // Validate file type
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      throw new Error("Only JPEG, PNG, and WEBP formats are allowed");
    }

    // Convert file to base64
    const base64 = await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = (error) => reject(error);
      reader.readAsDataURL(file);
    });

    // Set local state for preview
    logoImage.value = base64;

    // Make API call with the proper headers
    const response = await patch(`/store/${router.params.id}/`, {
      store_logo: base64,
    });

    // Show success message
    toast.add({
      title: "Logo Updated",
      description: "Your store logo has been successfully updated",
      color: "green",
    });

    // Hide the upload modal
    showLogoUpload.value = false;

    // Update store details with new data
    storeDetails.value = response.data;
  } catch (error) {
    console.error("Error uploading logo:", error);
    toast.add({
      title: "Upload Failed",
      description: error.message || "Could not upload logo. Please try again.",
      color: "red",
    });
  } finally {
    isLoading.value = false;
    // Refresh store details
    await getStoreDetails();
  }
}

// Initialize component
onMounted(async () => {
  // Get initial data
  await Promise.all([getStoreDetails(), getMyProducts()]);

  // If there's only one category, auto-select it
  if (uniqueCategories.value.length === 1) {
    selectedCategory.value = uniqueCategories.value[0].id;
  }

  // Enhanced scroll effects with IntersectionObserver for better performance
  const observerOptions = {
    root: null,
    rootMargin: "0px",
    threshold: 0.2,
  };

  const sectionObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.target === categoriesRef.value) {
        visibleSections.categories = entry.isIntersecting;
      } else if (entry.target === detailsRef.value) {
        visibleSections.details = entry.isIntersecting;
      } else if (entry.target === ctaRef.value) {
        visibleSections.cta = entry.isIntersecting;
      }
    });
  }, observerOptions);

  // Handle parallax effect
  const handleScroll = () => {
    if (bannerRef.value) {
      const scrollPosition = window.scrollY;
      const translateY = Math.min(scrollPosition * 0.3, 100); // Limit the movement
      bannerRef.value.style.transform = `translateY(${translateY}px)`;
    }
  };

  // Observe sections for animations
  if (categoriesRef.value) sectionObserver.observe(categoriesRef.value);
  if (detailsRef.value) sectionObserver.observe(detailsRef.value);
  if (ctaRef.value) sectionObserver.observe(ctaRef.value);

  window.addEventListener("scroll", handleScroll);
  handleScroll(); // Initial call

  // Clean up event listeners and observers
  onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
    sectionObserver.disconnect();
  });
});
</script>

<style>
/* Remove any unnecessary animations to keep the design clean */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  transition: all 0.2s ease;
}

/* Add new style for hiding scrollbars while allowing scrolling */
.hide-scrollbar {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none;  /* Chrome, Safari and Opera */
}
</style>
