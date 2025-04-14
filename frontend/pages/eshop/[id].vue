<template>
  <UContainer>
    <div
      class="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-50"
    >
      <!-- Banner Section with Parallax Effect -->
      <div class="relative w-full max-sm:mt-6 min-h-[300px] sm:h-[60vh]">
        <div
          ref="bannerRef"
          class="absolute inset-0 w-full h-[60%] transition-transform duration-300 max-sm:hidden"
        >
          <div
            class="absolute inset-0 bg-gradient-to-r from-slate-900/80 to-slate-800/80 mix-blend-multiply"
          ></div>
          <div
            class="absolute inset-0 bg-cover bg-center"
            :style="{
              backgroundImage: storeDetails?.store_banner
                ? `url(${storeDetails?.store_banner})`
                : 'url(\'/placeholder.svg?height=800&width=1600\')',
            }"
          ></div>
          <div
            class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/30"
          ></div>

          <!-- Banner upload button -->
          <div v-if="isOwner" class="absolute top-4 right-4 z-20">
            <UButton
              type="button"
              class="rounded-full bg-white/20 backdrop-blur-md border-white/30 text-white hover:bg-white/30 hover:text-white px-3 py-1.5 text-sm font-medium inline-flex items-center"
              @click="showBannerUpload = true"
            >
              <Camera class="w-4 h-4 mr-2" />
              {{
                storeDetails?.store_banner ? "Change Banner" : "Upload Banner"
              }}
            </UButton>
          </div>

          <!-- Animated particles -->
          <div class="absolute inset-0 opacity-30">
            <div
              v-for="(_, i) in 20"
              :key="i"
              class="absolute rounded-full bg-white"
              :style="{
                width: `${Math.random() * 4 + 1}px`,
                height: `${Math.random() * 4 + 1}px`,
                top: `${Math.random() * 100}%`,
                left: `${Math.random() * 100}%`,
                opacity: Math.random() * 0.5 + 0.3,
                animation: `float ${Math.random() * 8 + 8}s linear infinite`,
                animationDelay: `${Math.random() * 5}s`,
              }"
            ></div>
          </div>
        </div>

        <!-- Banner Upload Modal -->
        <Teleport to="body">
          <div
            v-if="showBannerUpload"
            class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
          >
            <div class="sm:max-w-[500px] bg-white rounded-lg shadow-xl w-full">
              <div class="p-6">
                <div class="flex items-center justify-between mb-4">
                  <h3 class="text-lg font-semibold">Upload Banner</h3>
                  <button
                    type="button"
                    class="rounded-full h-8 w-8 p-0 flex items-center justify-center hover:bg-slate-100"
                    @click="showBannerUpload = false"
                  >
                    <X class="h-4 w-4" />
                  </button>
                </div>
                <p class="text-slate-500 text-sm mb-4">
                  Upload a new banner image for your profile.
                </p>

                <label
                  class="flex flex-col items-center justify-center w-full h-40 border-2 border-dashed border-slate-300 rounded-lg cursor-pointer bg-slate-50 hover:bg-slate-100 transition-colors"
                >
                  <div
                    class="flex flex-col items-center justify-center pt-5 pb-6"
                  >
                    <Camera class="w-10 h-10 mb-3 text-slate-400" />
                    <p class="mb-2 text-sm text-slate-500">
                      <span class="font-semibold">Click to upload</span> or drag
                      and drop
                    </p>
                    <p class="text-xs text-slate-500">
                      PNG, JPG or WEBP (Recommended: 1600×800)
                    </p>
                  </div>
                  <input
                    type="file"
                    class="hidden"
                    accept="image/*"
                    @change="handleBannerUpload"
                  />
                </label>

                <div class="flex justify-end mt-4">
                  <button
                    type="button"
                    class="px-4 py-2 border border-slate-300 rounded-md text-sm font-medium hover:bg-slate-50"
                    @click="showBannerUpload = false"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </div>
        </Teleport>

        <!-- Vendor Info Card at Bottom of Banner -->
        <div
          class="sm:absolute max-sm:top-0 sm:bottom-0 sm:left-1/2 sm:-translate-x-1/2 sm:translate-y-1/2 md:-translate-y-2/3 sm:w-[90%] max-w-4xl z-10"
          :class="isSeeMore ? 'md:translate-y-0' : ''"
        >
          <div
            class="border-none shadow-lg sm:shadow-2xl bg-slate-50/95 backdrop-blur-md rounded-2xl overflow-hidden animate-fade-in-up relative"
          >
            <div
              class="absolute inset-0 bg-gradient-to-r from-slate-100/50 to-white/50 opacity-80"
            ></div>
            <div
              class="absolute inset-0 bg-grid-slate-200/50 [mask-image:linear-gradient(to_bottom,white,transparent)]"
            ></div>
            <div
              class="p-4 md:p-6 flex flex-col md:flex-row gap-4 items-center relative"
            >
              <div
                class="relative h-20 w-20 md:h-28 md:w-28 rounded-2xl overflow-hidden ring-4 ring-white shadow-lg transform transition-transform hover:scale-105 group"
              >
                <div
                  class="absolute inset-0 bg-gradient-to-br from-slate-700 to-slate-900 group-hover:from-slate-600 group-hover:to-slate-800 transition-colors duration-300"
                ></div>
                <div
                  class="absolute inset-0 flex items-center justify-center text-white font-bold text-2xl"
                >
                  <span v-if="!storeDetails?.store_logo">Logo</span>
                </div>
                <div
                  class="absolute inset-0 bg-cover bg-center opacity-80 group-hover:opacity-100 transition-opacity duration-300"
                  :style="{
                    backgroundImage: storeDetails?.store_logo
                      ? `url(${storeDetails?.store_logo})`
                      : 'url(\'/placeholder.svg?height=200&width=200\')',
                  }"
                ></div>

                <!-- Logo upload button -->
                <div
                  v-if="isOwner"
                  class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-black/50 cursor-pointer"
                  @click="showLogoUpload = true"
                >
                  <div
                    class="flex flex-col items-center justify-center text-white text-xs"
                  >
                    <ImageIcon class="w-6 h-6 mb-1" />
                    <span>{{
                      storeDetails?.store_logo ? "Change Logo" : "Upload Logo"
                    }}</span>
                  </div>
                </div>
              </div>
              <div class="flex-1 text-center md:text-left">
                <h1
                  class="text-3xl md:text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-slate-900 to-slate-700"
                >
                  {{ storeDetails?.store_name || "Store Name" }}
                </h1>
                <p
                  class="text-slate-600 mt-1"
                  :class="isSeeMore ? '' : 'line-clamp-2'"
                >
                  {{
                    storeDetails?.store_description ||
                    "Store description will appear here"
                  }}
                </p>
                <UButton
                  v-if="storeDetails?.store_description"
                  @click="isSeeMore = !isSeeMore"
                  :label="isSeeMore ? 'See Less' : 'See More'"
                  variant="link"
                  size="sm"
                  color="blue"
                />
                <div
                  class="flex flex-wrap gap-2 mt-4 justify-center md:justify-start"
                >
                  <span
                    class="px-3 py-1 bg-white shadow-sm hover:shadow transition-shadow duration-300 rounded-full text-sm flex items-center"
                    v-if="storeDetails?.store_address"
                  >
                    <MapPin class="w-3 h-3 mr-1" />
                    {{ storeDetails?.store_address }}
                  </span>
                  <span
                    v-if="storeDetails?.phone"
                    class="px-3 py-1 bg-white shadow-sm hover:shadow transition-shadow duration-300 rounded-full text-sm flex items-center"
                  >
                    <Phone class="w-3 h-3 mr-1" />
                    {{ storeDetails?.phone || "" }}
                  </span>
                </div>
              </div>
              <div class="flex gap-2">
                <UButton
                  type="button"
                  variant="outline"
                  class="rounded-full border border-slate-300 hover:bg-slate-100 transition-all duration-300 hover:scale-105 transform px-4 py-2 font-medium"
                >
                  Follow
                </UButton>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div
        class="container mx-auto sm:pt-48 md:pt-0"
        :class="isSeeMore ? 'mt-96 md:mt-3' : 'mt-8 md:-mt-14'"
      >
        <!-- Enhanced Search Section - No Dropdown -->
        <div class="mb-7">
          <div
            :class="`relative max-w-2xl mx-auto transition-all duration-300 ease-out ${
              searchFocused ? 'scale-105' : 'scale-100'
            }`"
          >
            <!-- Animated background glow -->
            <div
              :class="`absolute inset-0 bg-gradient-to-r from-slate-300/70 via-slate-200/70 to-slate-300/70 rounded-full blur-xl transition-all duration-300 ${
                searchFocused ? 'opacity-100 scale-105' : 'opacity-70 scale-100'
              }`"
            ></div>

            <!-- Search input container -->
            <div class="relative z-10">
              <div class="relative overflow-hidden rounded-full shadow-xl">
                <div
                  :class="`absolute inset-0 bg-white/90 backdrop-blur-md transition-opacity duration-200 ${
                    searchFocused ? 'opacity-100' : 'opacity-90'
                  }`"
                ></div>

                <div class="relative flex items-center p-1">
                  <div
                    :class="`p-2 transition-all duration-200 ${
                      searchFocused ? 'text-slate-800' : 'text-slate-400'
                    }`"
                  >
                    <Search class="h-5 w-5" />
                  </div>
                  <input
                    type="text"
                    placeholder="Search premium products..."
                    class="border-0 bg-transparent text-base w-16 sm:w-auto py-2 md:py-3 px-2 flex-1 placeholder:text-slate-400 focus:outline-none"
                    @focus="searchFocused = true"
                    @blur="searchFocused = false"
                    v-model="searchValue"
                  />
                  <button
                    v-if="searchValue"
                    class="mr-2 h-8 w-8 rounded-full p-0 flex items-center justify-center hover:bg-slate-100"
                    @click="searchValue = ''"
                  >
                    <X class="h-4 w-4" />
                  </button>
                  <button
                    :class="`rounded-full mr-1 transition-all duration-200 text-white px-3 py-1 md:px-4 md:py-2 ${
                      searchFocused
                        ? 'bg-slate-800 hover:bg-slate-700'
                        : 'bg-slate-700 hover:bg-slate-600'
                    }`"
                  >
                    Search
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Categories & Products Section -->
        <div class="mb-16 sm:mt-8">
          <!-- Category Tabs -->
          <div
            ref="categoriesRef"
            :class="`flex flex-col items-center sm:mt-12 transition-all duration-500 transform ${
              visibleSections.categories
                ? 'opacity-100 translate-y-0'
                : 'opacity-0 translate-y-10'
            }`"
          >
            <div class="flex flex-wrap justify-center gap-3 max-w-3xl">
              <span
                class="px-4 py-3 text-sm cursor-pointer bg-white hover:bg-slate-50 shadow-md hover:shadow-lg transition-all duration-200 border border-slate-100 rounded-xl group"
                :class="{
                  'bg-slate-800 text-slate-500 ': selectedCategory === null,
                }"
                @click="selectedCategory = null"
                style="
                  animation: fadeInUp 0.3s ease-out forwards;
                  animation-delay: 0ms;
                "
              >
                <span class="relative z-10">All Products</span>
                <span
                  class="ml-2 px-2 py-0.5 text-xs bg-slate-100 group-hover:bg-slate-200 rounded-full transition-colors duration-200 text-slate-500"
                >
                  {{ products.length }}
                </span>
              </span>

              <span
                v-for="category in uniqueCategories"
                :key="category.id"
                class="px-4 py-3 text-sm cursor-pointer bg-white hover:bg-slate-50 shadow-md hover:shadow-lg transition-all duration-200 border border-slate-100 rounded-xl group"
                :class="{
                  'bg-slate-800 text-slate-500 ':
                    selectedCategory === category.id,
                }"
                @click="selectedCategory = category.id"
                style="animation: fadeInUp 0.3s ease-out forwards"
                :style="{ animationDelay: `${50}ms` }"
              >
                <span class="relative z-10">{{ category.name }}</span>
                <span
                  class="ml-2 px-2 py-0.5 text-xs bg-slate-100 group-hover:bg-slate-200 rounded-full transition-colors duration-200 text-slate-500"
                >
                  {{ getProductCountByCategory(category.id) }}
                </span>
              </span>
            </div>
          </div>

          <!-- Products Display Section -->
          <div
            class="mt-6 sm:mt-12 grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2 sm:gap-6"
          >
            <CommonProductCard
              v-for="product in filteredProducts"
              :key="product.id"
              :product="product"
            />

            <!-- Empty State -->
            <div
              v-if="filteredProducts.length === 0"
              class="col-span-full flex flex-col items-center justify-center py-12 text-center"
            >
              <div
                class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4"
              >
                <PackageX class="w-8 h-8 text-slate-400" />
              </div>
              <h3 class="font-medium text-slate-800 text-lg mb-1">
                No Products Found
              </h3>
              <p class="text-slate-500 max-w-sm">
                There are no products available in this category. Try selecting
                a different category.
              </p>
            </div>
          </div>
        </div>

        <!-- Vendor Details with Animation -->
        <div
          ref="detailsRef"
          :class="`grid grid-cols-1 md:grid-cols-2 gap-6 my-16 max-w-5xl mx-auto transition-all duration-500 transform w-fit ${
            visibleSections.details
              ? 'opacity-100 translate-y-0'
              : 'opacity-0 translate-y-10'
          }`"
        >
          <div
            class="overflow-hidden border-none shadow-lg hover:shadow-xl transition-all duration-300 group rounded-xl relative"
            :style="{
              animation: 'fadeInUp 0.3s ease-out forwards',
              opacity: 0,
              transform: 'translateY(20px)',
            }"
          >
            <div
              class="absolute inset-0 bg-gradient-to-br from-slate-50 to-white opacity-80"
            ></div>
            <div
              class="absolute inset-0 bg-grid-slate-100 [mask-image:linear-gradient(to_bottom,white,transparent)]"
            ></div>
            <div class="p-6 relative">
              <div class="flex flex-col items-center text-center">
                <div
                  class="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center mb-4 group-hover:bg-slate-800 group-hover:text-white transition-all duration-300 transform group-hover:scale-110 shadow-md group-hover:shadow-xl"
                >
                  <component :is="Mail" class="w-5 h-5" />
                </div>

                <h3 class="font-semibold text-lg mb-2">Email</h3>
                <p class="text-slate-600 whitespace-pre-line">
                  {{ storeDetails?.email }}
                </p>
              </div>
            </div>
          </div>
          <div
            class="overflow-hidden border-none shadow-lg hover:shadow-xl transition-all duration-300 group rounded-xl relative"
            :style="{
              animation: 'fadeInUp 0.3s ease-out forwards',
              opacity: 0,
              transform: 'translateY(20px)',
            }"
          >
            <div
              class="absolute inset-0 bg-gradient-to-br from-slate-50 to-white opacity-80"
            ></div>
            <div
              class="absolute inset-0 bg-grid-slate-100 [mask-image:linear-gradient(to_bottom,white,transparent)]"
            ></div>
            <div class="p-6 relative">
              <div class="flex flex-col items-center text-center">
                <div
                  class="w-16 h-16 rounded-full bg-slate-100 flex items-center justify-center mb-4 group-hover:bg-slate-800 group-hover:text-white transition-all duration-300 transform group-hover:scale-110 shadow-md group-hover:shadow-xl"
                >
                  <component :is="LocateIcon" class="w-5 h-5" />
                </div>

                <h3 class="font-semibold text-lg mb-2">Address</h3>
                <p class="text-slate-600 whitespace-pre-line">
                  {{ storeDetails?.store_address }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Call to Action with Animation -->
        <div
          ref="ctaRef"
          :class="`relative mt-20 mb-10 max-w-5xl mx-auto overflow-hidden rounded-2xl transition-all duration-500 transform ${
            visibleSections.cta
              ? 'opacity-100 translate-y-0'
              : 'opacity-0 translate-y-10'
          }`"
        >
          <div
            class="absolute inset-0 bg-gradient-to-r from-slate-800 to-slate-900"
          ></div>

          <!-- Animated particles -->
          <div class="absolute inset-0 opacity-30">
            <div
              v-for="(_, i) in 15"
              :key="i"
              class="absolute rounded-full bg-white"
              :style="{
                width: `${Math.random() * 4 + 1}px`,
                height: `${Math.random() * 4 + 1}px`,
                top: `${Math.random() * 100}%`,
                left: `${Math.random() * 100}%`,
                opacity: Math.random() * 0.5 + 0.3,
                animation: `float ${Math.random() * 8 + 8}s linear infinite`,
                animationDelay: `${Math.random() * 5}s`,
              }"
            ></div>
          </div>

          <div
            class="absolute inset-0 opacity-20"
            style="
              background-image: url('/placeholder.svg?height=400&width=1200');
              background-size: cover;
              background-position: center;
            "
          ></div>
          <div
            class="relative p-8 md:p-12 flex flex-col md:flex-row items-center justify-between gap-6"
          >
            <div class="text-center md:text-left">
              <h2 class="text-2xl md:text-3xl font-bold text-white mb-2">
                Ready to explore our products?
              </h2>
              <p class="text-slate-300">
                Follow us and join thousands of satisfied customers today.
              </p>
            </div>
            <p
              class="rounded-full bg-white text-slate-900 hover:bg-slate-100 px-4 py-2 h-auto text-base lg:text-lg font-medium shadow-xl hover:shadow-2xl transition-all duration-300 hover:scale-105 transform group w-64"
            >
              Thanks for visiting our store
            </p>
          </div>
        </div>
      </div>

      <!-- Logo Upload Modal -->
      <Teleport to="body">
        <div
          v-if="showLogoUpload"
          class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        >
          <div class="sm:max-w-[425px] bg-white rounded-lg shadow-xl w-full">
            <div class="p-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold">Upload Logo</h3>
                <button
                  type="button"
                  class="rounded-full h-8 w-8 p-0 flex items-center justify-center hover:bg-slate-100"
                  @click="showLogoUpload = false"
                >
                  <X class="h-4 w-4" />
                </button>
              </div>
              <p class="text-slate-500 text-sm mb-4">
                Upload a new logo for your vendor profile.
              </p>

              <label
                class="flex flex-col items-center justify-center w-full h-40 border-2 border-dashed border-slate-300 rounded-lg cursor-pointer bg-slate-50 hover:bg-slate-100 transition-colors"
              >
                <div
                  class="flex flex-col items-center justify-center pt-5 pb-6"
                >
                  <ImageIcon class="w-10 h-10 mb-3 text-slate-400" />
                  <p class="mb-2 text-sm text-slate-500">
                    <span class="font-semibold">Click to upload</span> or drag
                    and drop
                  </p>
                  <p class="text-xs text-slate-500">
                    PNG, JPG or WEBP (Recommended: Square image)
                  </p>
                </div>
                <input
                  type="file"
                  class="hidden"
                  accept="image/*"
                  @change="handleLogoUpload"
                />
              </label>

              <div class="flex justify-end mt-4">
                <button
                  type="button"
                  class="px-4 py-2 border border-slate-300 rounded-md text-sm font-medium hover:bg-slate-50"
                  @click="showLogoUpload = false"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
    </div>
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

import { is } from "date-fns/locale";
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
  if (!selectedCategory.value) return products.value;
  return products.value.filter(
    (product) => product.category === selectedCategory.value
  );
});

// Helper function to get product count by category
function getProductCountByCategory(categoryId) {
  return products.value.filter((product) => product.category === categoryId)
    .length;
}

// State variables
const scrolled = ref(false);

const selectedProduct = ref(null);
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

await Promise.all([getStoreDetails(), getMyProducts()]);
// Initialize component
onMounted(async () => {
  // Get initial data

  // If there's only one category, auto-select it
  if (uniqueCategories.value.length === 1) {
    selectedCategory.value = uniqueCategories.value[0].id;
  }

  // Setup scroll effects with proper cleanup
  const handleScroll = () => {
    if (window.scrollY > 50) {
      scrolled.value = true;
    } else {
      scrolled.value = false;
    }

    // Check if sections are visible
    const isVisible = (element) => {
      if (!element) return false;
      const rect = element.getBoundingClientRect();
      return rect.top < window.innerHeight * 0.8 && rect.bottom >= 0;
    };

    visibleSections.categories = isVisible(categoriesRef.value);
    visibleSections.details = isVisible(detailsRef.value);
    visibleSections.cta = isVisible(ctaRef.value);
  };

  window.addEventListener("scroll", handleScroll);
  handleScroll();

  onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
  });
});
</script>

<style>
@keyframes float {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-15px);
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes animate-grid {
  0% {
    background-position: 0 0;
  }
  100% {
    background-position: 100% 100%;
  }
}

.animate-fade-in-up {
  animation: fadeInUp 0.5s ease-out forwards;
}

.animate-fade-in {
  animation: fadeIn 0.3s ease-out forwards;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.bg-grid-slate-100 {
  background-image: linear-gradient(to right, #f1f5f9 1px, transparent 1px),
    linear-gradient(to bottom, #f1f5f9 1px, transparent 1px);
  background-size: 20px 20px;
}

.bg-grid-slate-200 {
  background-image: linear-gradient(to right, #e2e8f0 1px, transparent 1px),
    linear-gradient(to bottom, #e2e8f0 1px, transparent 1px);
  background-size: 20px 20px;
}
</style>
