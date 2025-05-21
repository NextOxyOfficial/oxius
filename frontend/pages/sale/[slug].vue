<template>
  <div class="max-w-6xl mx-auto my-4">
    <!-- Main Product Section -->
    <div class="grid grid-cols-1 lg:grid-cols-5 gap-8">
      <!-- Gallery Section - 3 columns on large screens -->
      <div class="lg:col-span-3 relative">
        <div
          ref="galleryRef"
          class="relative aspect-video bg-gray-100 rounded-lg overflow-hidden border border-gray-200"
          @touchstart="handleTouchStart"
          @touchmove="handleTouchMove"
          @touchend="handleTouchEnd"
        >
          <img
            :src="
              product.images[currentImageIndex]?.image || '/placeholder.svg'
            "
            :alt="product.title"
            class="absolute inset-0 w-full h-full object-cover"
          />
          <button
            class="absolute left-3 top-1/2 -translate-y-1/2 rounded-full bg-white/90 hover:bg-white p-2 transition-all duration-200"
            @click="prevImage"
          >
            <ChevronLeft class="h-4 w-4 text-gray-700" />
          </button>
          <button
            class="absolute right-3 top-1/2 -translate-y-1/2 rounded-full bg-white/90 hover:bg-white p-2 transition-all duration-200"
            @click="nextImage"
          >
            <ChevronRight class="h-4 w-4 text-gray-700" />
          </button>
          <div class="absolute bottom-3 right-3 flex space-x-2">
            <button
              class="bg-white/90 hover:bg-white text-gray-800 text-xs h-7 px-3 rounded-md transition-all duration-200 flex items-center"
              @click="downloadImage"
            >
              <Download class="h-3 w-3 mr-1" />
              Download
            </button>
            <span
              class="bg-white/90 text-gray-800 text-xs px-3 py-1.5 rounded-md"
            >
              {{ currentImageIndex + 1 }}/{{ product.images?.length }}
            </span>
          </div>
        </div>

        <!-- Thumbnail Gallery -->
        <div class="flex mt-3 space-x-2 overflow-x-auto pb-2">
          <div
            v-for="(image, index) in product?.images"
            :key="index"
            :class="`relative w-16 h-16 flex-shrink-0 cursor-pointer rounded-md overflow-hidden border-2 transition-all duration-200 ${
              index === currentImageIndex
                ? 'border-emerald-600'
                : 'border-transparent'
            }`"
            @click="selectImage(index)"
          >
            <img
              :src="image.image || '/placeholder.svg'"
              :alt="`Thumbnail ${index + 1}`"
              class="absolute inset-0 w-full h-full object-cover"
            />
          </div>
        </div>
      </div>

      <!-- Product Info - 2 columns on large screens -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg p-3 border border-gray-200">
          <div class="flex justify-between items-start">
            <h1 class="text-xl font-bold text-gray-800">
              {{ product?.title }}
            </h1>
            <div class="flex space-x-2">
              <button
                class="text-gray-400 hover:text-emerald-600 p-1 transition-colors duration-200"
                @click="handleShare"
              >
                <Share2 class="h-5 w-5" />
              </button>
            </div>
          </div>

          <div class="mt-2 flex items-center text-xs text-gray-500">
            <span class="font-medium text-gray-600 mr-2"
              >Ad ID: {{ product?.id }}</span
            >
            <span class="flex items-center">
              <Calendar class="h-3 w-3 mr-1" />
              {{ formatDate(product?.created_at) }}
            </span>
          </div>

          <div class="mt-4">
            <span class="text-2xl font-bold text-emerald-600"
              >${{ product?.price.toLocaleString() }}</span
            >
          </div>

          <div class="mt-4 grid grid-cols-2 gap-4">
            <div class="flex items-center">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <Tag class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-xs font-medium text-gray-500">Category</div>
                <div class="text-sm text-gray-700">
                  {{ product.category_details?.name }}
                </div>
              </div>
            </div>

            <div class="flex items-center">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <Layers class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-xs font-medium text-gray-500">
                  Sub-Category
                </div>
                <div class="text-sm text-gray-700">
                  {{ product?.child_category_details?.name }}
                </div>
              </div>
            </div>

            <div class="flex items-center">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <ShieldCheck class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-xs font-medium text-gray-500">Condition</div>
                <div class="text-sm text-gray-700">{{ product.condition }}</div>
              </div>
            </div>

            <div class="flex items-center">
              <div
                class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center mr-3"
              >
                <MapPin class="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <div class="text-xs font-medium text-gray-500">Location</div>
                <div class="text-sm text-gray-700">
                  {{
                    product?.division && product?.district && product?.area
                      ? `${product?.division}, ${product?.district}, ${product?.area}`
                      : `All Over Bagnladesh`
                  }}
                </div>
              </div>
            </div>
          </div>

          <!-- Financing Banner -->
          <div
            class="mt-5 overflow-hidden rounded-lg border border-emerald-100"
          >
            <div class="bg-gradient-to-r from-emerald-600 to-emerald-700 p-5">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="font-bold text-white text-sm">Need financing?</h3>
                  <p class="text-emerald-100 text-xs mt-1">
                    Get pre-approved in minutes
                  </p>
                  <div class="mt-3 flex items-center">
                    <div class="flex -space-x-1">
                      <div
                        class="h-6 w-6 rounded-full bg-white flex items-center justify-center text-emerald-600 text-xs"
                      >
                        $
                      </div>
                      <div
                        class="h-6 w-6 rounded-full bg-white flex items-center justify-center text-emerald-600 text-xs"
                      >
                        %
                      </div>
                      <div
                        class="h-6 w-6 rounded-full bg-white flex items-center justify-center text-emerald-600 text-xs"
                      >
                        ✓
                      </div>
                    </div>
                    <span class="ml-2 text-white text-xs font-medium"
                      >Competitive rates available</span
                    >
                  </div>
                </div>
                <div>
                  <button
                    class="bg-white hover:bg-gray-50 text-emerald-600 text-sm px-4 py-2 rounded-md transition-all duration-200"
                  >
                    Apply Now
                  </button>
                </div>
              </div>
            </div>
            <div class="h-1 w-full bg-emerald-600"></div>
          </div>

          <div class="mt-4 flex justify-between">
            <button
              class="flex-1 mr-2 text-xs py-2 rounded-md border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-600"
            >
              <Flag class="h-3 w-3 mr-1" />
              Report Ad
            </button>
            <button
              class="flex-1 text-xs py-2 rounded-md border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-600"
              @click="handleShare"
            >
              <Share2 class="h-3 w-3 mr-1" />
              Share
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Details Section -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mt-8">
      <!-- Product Details - 2 columns on large screens -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg overflow-hidden border border-gray-200">
          <div class="p-3">
            <h2 class="text-lg font-bold mb-4 text-gray-800 flex items-center">
              <ClipboardList class="h-5 w-5 mr-2 text-emerald-600" />
              Details
            </h2>
            <p
              class="text-gray-600 whitespace-pre-line text-sm leading-relaxed"
            >
              {{ product?.description }}
            </p>

            <div class="my-6 border-t border-gray-100"></div>

            <div>
              <h3
                class="text-base font-semibold mb-3 text-gray-800 flex items-center"
              >
                <MapPin class="h-4 w-4 mr-2 text-emerald-600" />
                Location
              </h3>
              <div
                v-if="product?.division && product?.district && product?.area"
                class="text-sm text-gray-700"
              >
                {{
                  product?.division && product?.district && product?.area
                    ? `${product?.detailed_address}`
                    : `All Over Bagnladesh`
                }}
              </div>
            </div>
          </div>
        </div>

        <!-- Safety Tips -->
        <div
          class="bg-white rounded-lg overflow-hidden mt-6 border border-gray-200"
        >
          <div class="p-6">
            <div class="flex items-center mb-4">
              <ShieldCheck class="h-5 w-5 text-emerald-600 mr-2" />
              <h2 class="text-lg font-bold text-gray-800">Safety Tips</h2>
            </div>
            <ul class="space-y-3 text-gray-600 text-sm">
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Meet in a safe, public place</span>
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Don't pay or transfer money in advance</span>
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Inspect the item before purchasing</span>
              </li>
              <li class="flex items-start">
                <div class="bg-emerald-50 rounded-full p-1 mr-3 mt-0.5">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </div>
                <span>Be wary of unrealistic offers or prices</span>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Seller Info - 1 column on large screens -->
      <div class="lg:col-span-1">
        <div class="bg-white rounded-lg overflow-hidden border border-gray-200">
          <div class="p-6">
            <h2 class="text-lg font-bold mb-4 text-gray-800 flex items-center">
              <User class="h-5 w-5 mr-2 text-emerald-600" />
              Seller Information
            </h2>
            <div class="flex items-center">
              <div
                class="h-12 w-12 rounded-full bg-gray-200 overflow-hidden mr-4 border border-gray-200"
              >
                <img
                  :src="
                    product.user_details?.image || '/static/frontend/avatar.png'
                  "
                  :alt="product.user_details?.name"
                  class="h-full w-full object-cover"
                />
              </div>
              <div>
                <h3 class="font-semibold text-gray-800">
                  {{ product.user_details?.name }}
                </h3>
                <p class="text-xs text-gray-500">
                  Member since
                  {{ formatDate(product.user_details.date_joined) }}
                </p>
              </div>
            </div>

            <div class="mt-4 space-y-3 bg-gray-50 p-4 rounded-md">
              <div class="flex justify-between text-sm">
                <span class="text-gray-600">Total Listings</span>
                <span class="font-medium text-gray-800">{{
                  product.user_details?.sale_post_count
                }}</span>
              </div>

              <div class="flex justify-between items-center text-sm">
                <span class="text-gray-600">Phone</span>
                <div class="flex items-center">
                  <span class="font-medium mr-2 text-gray-800">
                    {{
                      showPhone
                        ? product?.user_details?.phone
                        : maskPhoneNumber(product?.user_details?.phone)
                    }}
                  </span>
                  <button
                    class="h-6 w-6 p-0 text-emerald-600 hover:text-emerald-600"
                    @click="toggleShowPhone"
                  >
                    <component :is="showPhone ? EyeOff : Eye" class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>

            <button
              class="w-full mt-4 text-sm border border-gray-200 rounded-md py-2 flex items-center justify-center hover:bg-gray-50 transition-colors duration-200 text-gray-700"
              @click="
                navigateTo('/sale/user-profile/' + product.user_details?.id)
              "
            >
              <User class="h-4 w-4 mr-2 text-emerald-600" />
              View Seller Profile
            </button>

            <a
              href="#"
              class="mt-3 text-emerald-600 hover:text-emerald-600 text-xs flex items-center justify-center"
            >
              View more listings from this seller
              <ChevronRight class="h-3 w-3 ml-1" />
            </a>
          </div>
        </div>
      </div>
    </div>

    <!-- Similar Listings -->
    <div class="mt-8">
      <div class="flex items-center justify-between mb-4 px-3">
        <h2 class="text-lg font-bold text-gray-800 flex items-center">
          <LayoutGrid class="h-5 w-5 mr-2 text-emerald-600" />
          Similar Listings You May Like
        </h2>
        <NuxtLink
          href="/sale"
          class="text-emerald-600 hover:text-emerald-600 text-xs flex items-center"
        >
          View all
          <ChevronRight class="h-3 w-3 ml-1" />
        </NuxtLink>
      </div>

      <div class="grid grid-cols-2 md:grid-cols-4 gap-2 px-1">
        <div
          v-for="item in similarProducts.slice(0, 4)"
          :key="item.id"
          class="bg-white rounded-lg overflow-hidden group border border-gray-200 hover:border-emerald-200 transition-all duration-300"
        >
          <div class="relative aspect-video">
            <img
              :src="item?.main_image || '/placeholder.svg'"
              :alt="item?.title"
              class="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
          </div>
          <div class="p-4">
            <h3 class="font-semibold truncate text-sm text-gray-800">
              {{ item.title }}
            </h3>
            <div class="flex justify-between items-center mt-2">
              <span class="font-bold text-emerald-600 text-sm"
                >${{ item?.price.toLocaleString() }}</span
              >
              <button
                class="text-gray-400 hover:text-emerald-600 h-6 w-6 p-0 transition-colors duration-200"
              >
                <ExternalLink class="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Share Dialog -->
    <div
      v-if="shareDialogOpen"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      @click="closeShareDialog"
    >
      <div
        class="bg-white rounded-lg max-w-md w-full mx-4 border border-gray-200"
        @click.stop
      >
        <div class="flex justify-between items-center p-5 border-b">
          <h3 class="font-semibold text-gray-800">Share this listing</h3>
          <button
            @click="closeShareDialog"
            class="text-gray-400 hover:text-gray-600 transition-colors duration-200"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
        <div class="p-5">
          <div class="flex items-center space-x-2">
            <div class="flex-1">
              <div
                class="flex items-center justify-between rounded-md border border-gray-200 px-3 py-2"
              >
                <span class="text-xs truncate text-gray-600">{{
                  shareUrl
                }}</span>
              </div>
            </div>
            <button
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-600 text-white rounded-md text-sm transition-colors duration-200"
              @click="copyToClipboard"
            >
              Copy
            </button>
          </div>

          <div class="mt-5">
            <h4 class="text-sm font-medium mb-3 text-gray-700">Share via</h4>
            <div class="grid grid-cols-2 gap-3">
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-700"
                @click="shareViaMedia('facebook')"
              >
                <span
                  class="w-5 h-5 bg-blue-600 text-white rounded flex items-center justify-center mr-2 text-xs"
                  >f</span
                >
                Facebook
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-700"
                @click="shareViaMedia('twitter')"
              >
                <span
                  class="w-5 h-5 bg-sky-500 text-white rounded flex items-center justify-center mr-2 text-xs"
                  >t</span
                >
                Twitter
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-700"
                @click="shareViaMedia('whatsapp')"
              >
                <span
                  class="w-5 h-5 bg-emerald-500 text-white rounded flex items-center justify-center mr-2 text-xs"
                  >w</span
                >
                WhatsApp
              </button>
              <button
                class="flex items-center justify-center py-2 px-4 rounded-md border border-gray-200 hover:bg-gray-50 transition-colors duration-200 text-gray-700"
                @click="shareViaMedia('email')"
              >
                <span
                  class="w-5 h-5 bg-gray-700 text-white rounded flex items-center justify-center mr-2 text-xs"
                  >@</span
                >
                Email
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from "vue";
import {
  Calendar,
  MapPin,
  Share2,
  Tag,
  Layers,
  AlertTriangle,
  ShieldCheck,
  User,
  ChevronRight,
  Flag,
  Heart,
  ChevronLeft,
  ExternalLink,
  Eye,
  EyeOff,
  X,
  Download,
  ClipboardList,
  LayoutGrid,
} from "lucide-vue-next";

const { params } = useRoute();
const { get } = useApi();
const product = ref({});
const similarProducts = ref([]);

async function getSalePost() {
  try {
    const response = await get(`/sale/posts/${params.slug}/`);
    if (response.data) {
      console.log(response.data);
      product.value = response.data;
    }
  } catch (error) {
    console.error("Error fetching sale post:", error);
  }
}

await getSalePost();

async function getSimilarProducts() {
  try {
    const response = await get(
      `/sale/posts/?category=${product.value?.category}`
    );
    if (response.data) {
      similarProducts.value = response.data.results;
      console.log(similarProducts.value);
    }
  } catch (error) {
    console.error("Error fetching similar products:", error);
  }
}
await getSimilarProducts();

// State variables
const currentImageIndex = ref(0);
const showPhone = ref(false);
const shareDialogOpen = ref(false);
const galleryRef = ref(null);
const touchStartX = ref(0);
const touchEndX = ref(0);
const shareUrl = ref(window.location.href);

// Format date
const formatDate = (dateString) => {
  const date = new Date(dateString);
  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "numeric",
  }).format(date);
};

// Mask phone number
const maskPhoneNumber = (phone) => {
  return "XXXXXXX" + phone?.slice(-3);
};

// Image navigation
const nextImage = () => {
  currentImageIndex.value =
    currentImageIndex.value === product.images.length - 1
      ? 0
      : currentImageIndex.value + 1;
};

const prevImage = () => {
  currentImageIndex.value =
    currentImageIndex.value === 0
      ? product.images.length - 1
      : currentImageIndex.value - 1;
};

const selectImage = (index) => {
  currentImageIndex.value = index;
};

// Touch handlers for swipe
const handleTouchStart = (e) => {
  touchStartX.value = e.touches[0].clientX;
};

const handleTouchMove = (e) => {
  touchEndX.value = e.touches[0].clientX;
};

const handleTouchEnd = () => {
  const touchDiff = touchStartX.value - touchEndX.value;

  // If swipe distance is significant enough (more than 50px)
  if (Math.abs(touchDiff) > 50) {
    if (touchDiff > 0) {
      // Swipe left, go to next image
      nextImage();
    } else {
      // Swipe right, go to previous image
      prevImage();
    }
  }
};

// Download image
const downloadImage = () => {
  // Create a download link for the current image
  const link = document.createElement("a");
  link.href = product.images[currentImageIndex.value];
  link.download = `product-image-${currentImageIndex.value + 1}.jpg`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

// Toggle phone visibility
const toggleShowPhone = () => {
  showPhone.value = !showPhone.value;
};

// Share functionality
const handleShare = () => {
  shareDialogOpen.value = true;
};

const closeShareDialog = () => {
  shareDialogOpen.value = false;
};

const copyToClipboard = () => {
  navigator.clipboard.writeText(shareUrl.value);
};

const shareViaMedia = (platform) => {
  let shareUrl = "";
  const currentUrl = encodeURIComponent(window.location.href);
  const title = encodeURIComponent(product.title);

  switch (platform) {
    case "facebook":
      shareUrl = `https://www.facebook.com/sharer/sharer.php?u=${currentUrl}`;
      break;
    case "twitter":
      shareUrl = `https://twitter.com/intent/tweet?text=${title}&url=${currentUrl}`;
      break;
    case "whatsapp":
      shareUrl = `https://api.whatsapp.com/send?text=${title} ${currentUrl}`;
      break;
    case "email":
      shareUrl = `mailto:?subject=${title}&body=${currentUrl}`;
      break;
  }

  if (shareUrl) {
    window.open(shareUrl, "_blank");
  }

  closeShareDialog();
};
</script>

<style scoped>
/* Additional custom styles can be added here if needed */
</style>
