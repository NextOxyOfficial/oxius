<template>
  <div class="bg-gray-50/60 min-h-screen">
    <!-- Sale Search Bar -->
    <SaleSearchBar
      :initial-search-term="''"
      :is-searching="false"
      @search="handleSearch"
      @clear-location="handleClearLocation"
    />

    <div class="max-w-6xl mx-auto px-1 sm:py-4">
      <!-- Breadcrumb -->
      <nav class="flex items-center justify-between text-sm mb-3">
        <div class="flex items-center flex-1 min-w-0 text-gray-500">
          <NuxtLink to="/" class="hover:text-emerald-600">{{ t("home") }}</NuxtLink>
          <UIcon name="i-heroicons-chevron-right" class="h-3 w-3 mx-1.5 text-gray-400" />
          <NuxtLink to="/sale" class="hover:text-emerald-600">{{ t("sale_detail_marketplace") }}</NuxtLink>
          <template v-if="product?.category_details">
            <UIcon name="i-heroicons-chevron-right" class="h-3 w-3 mx-1.5 text-gray-400 hidden sm:inline" />
            <NuxtLink
              :to="`/sale?category=${product?.category}`"
              class="hover:text-emerald-600 hidden sm:inline"
            >{{ product?.category_details?.name }}</NuxtLink>
          </template>
          <UIcon name="i-heroicons-chevron-right" class="h-3 w-3 mx-1.5 text-gray-400" />
          <span class="text-gray-700 truncate max-w-[120px] sm:max-w-[260px]">{{ product?.title }}</span>
        </div>

        <!-- Action buttons for logged in users -->
        <div v-if="isAuthenticated" class="flex items-center gap-2 flex-shrink-0 ml-2">
          <NuxtLink
            to="/sale/my-posts"
            class="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-xs border border-emerald-500 text-emerald-600 rounded-lg hover:bg-emerald-50 transition-colors"
            @click="handleButtonClick('my_posts')"
          >
            <div v-if="loadingButtons.has('my_posts')" class="dotted-spinner emerald"></div>
            <List v-else class="h-3.5 w-3.5" />
            <span class="hidden sm:inline">{{ t("sale_tab_my_posts") }}</span>
          </NuxtLink>
          <NuxtLink
            to="/sale/my-posts?tab=post-sale"
            class="flex items-center gap-1 px-2 sm:px-3 py-1.5 text-xs bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors"
            @click="handleButtonClick('post_ad')"
          >
            <div v-if="loadingButtons.has('post_ad')" class="dotted-spinner white"></div>
            <UIcon v-else name="i-heroicons-plus-circle" class="h-3.5 w-3.5" />
            <span class="hidden sm:inline">{{ t("sale_detail_post_ad") }}</span>
          </NuxtLink>
        </div>
      </nav>

      <!-- Main Product Section -->
      <div class="grid grid-cols-1 lg:grid-cols-5 gap-3">
        <!-- Gallery -->
        <div class="lg:col-span-3">
          <div
            ref="galleryRef"
            class="relative aspect-[4/3] sm:aspect-video bg-gray-100 rounded-xl overflow-hidden border border-gray-200 group"
            @touchstart="handleTouchStart"
            @touchmove="handleTouchMove"
            @touchend="handleTouchEnd"
          >
            <div
              v-if="!product.images || product.images.length === 0 || !product.images[currentImageIndex]?.image"
              class="absolute inset-0 flex flex-col items-center justify-center text-gray-300"
            >
              <UIcon name="i-heroicons-photo" class="h-16 w-16 mb-2" />
              <p class="text-gray-400 text-sm font-medium">{{ t("sale_detail_no_photo") }}</p>
            </div>
            <img
              v-else
              :src="product.images[currentImageIndex]?.image"
              :alt="product.title"
              class="absolute inset-0 w-full h-full object-cover"
            />

            <template v-if="product?.images && product.images.length > 1">
              <button
                class="absolute left-3 top-1/2 -translate-y-1/2 rounded-full bg-white/90 hover:bg-white p-2 shadow-sm transition sm:opacity-0 sm:group-hover:opacity-100"
                @click="prevImage"
              >
                <ChevronLeft class="h-4 w-4 text-gray-800" />
              </button>
              <button
                class="absolute right-3 top-1/2 -translate-y-1/2 rounded-full bg-white/90 hover:bg-white p-2 shadow-sm transition sm:opacity-0 sm:group-hover:opacity-100"
                @click="nextImage"
              >
                <ChevronRight class="h-4 w-4 text-gray-800" />
              </button>
            </template>

            <div v-if="product.images && product.images.length" class="absolute bottom-3 right-3 flex items-center gap-2">
              <button
                class="bg-white/90 hover:bg-white text-gray-800 text-xs h-7 px-3 rounded-md transition flex items-center"
                @click="downloadImage"
              >
                <Download class="h-3 w-3 mr-1" />
                {{ t("sale_detail_download") }}
              </button>
              <span class="bg-black/55 text-white text-xs px-2.5 py-1 rounded-md">
                {{ currentImageIndex + 1 }}/{{ product.images?.length }}
              </span>
            </div>
          </div>

          <!-- Thumbnail Gallery -->
          <div
            v-if="product?.images && product.images.length > 1"
            class="flex mt-3 gap-2 overflow-x-auto pb-1 scrollbar-hide"
          >
            <button
              v-for="(image, index) in product?.images"
              :key="index"
              :class="[
                'relative w-16 h-16 flex-shrink-0 rounded-lg overflow-hidden border-2 transition',
                index === currentImageIndex ? 'border-emerald-600' : 'border-transparent hover:border-emerald-300',
              ]"
              @click="selectImage(index)"
            >
              <div v-if="!image.image" class="absolute inset-0 bg-gray-100 flex items-center justify-center">
                <UIcon name="i-heroicons-photo" class="h-6 w-6 text-gray-400" />
              </div>
              <img v-else :src="image.image" :alt="`${product.title} ${index + 1}`" class="absolute inset-0 w-full h-full object-cover" />
            </button>
          </div>
        </div>

        <!-- Product Info -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-xl border border-gray-200 p-4">
            <div class="flex justify-between items-start gap-2">
              <h1 class="text-lg sm:text-xl font-bold text-gray-900 leading-snug">
                {{ capitalizeTitle(product?.title) }}
              </h1>
              <button
                class="text-gray-400 hover:text-emerald-600 p-1 shrink-0 transition"
                :aria-label="t('sale_detail_share')"
                @click="handleShare"
              >
                <Share2 class="h-5 w-5" />
              </button>
            </div>

            <div class="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-gray-500">
              <span class="font-medium">{{ t("sale_detail_ad_id") }} {{ product?.id }}</span>
              <span class="flex items-center gap-1">
                <Calendar class="h-3 w-3" />{{ formatDate(product?.created_at) }}
              </span>
            </div>

            <div class="mt-3 flex items-center gap-2 flex-wrap">
              <span class="text-2xl font-bold text-emerald-600">
                {{ product?.price ? `৳${product.price.toLocaleString()}` : t("sale_detail_contact_price") }}
              </span>
              <span
                v-if="product?.negotiable"
                class="px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-700 text-[11px] font-semibold"
              >{{ t("sale_card_negotiable") }}</span>
              <span
                v-if="conditionLabel"
                class="px-2 py-0.5 rounded-md bg-gray-100 text-gray-700 text-[11px] font-semibold"
              >{{ conditionLabel }}</span>
            </div>

            <!-- Meta -->
            <div class="mt-4 grid grid-cols-2 gap-3">
              <div v-if="product?.category_details?.name" class="flex items-center gap-2.5">
                <div class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center shrink-0">
                  <Tag class="h-4 w-4 text-emerald-600" />
                </div>
                <div class="min-w-0">
                  <div class="text-[11px] text-gray-500">{{ t("sale_form_category") }}</div>
                  <div class="text-sm text-gray-800 truncate">{{ product.category_details?.name }}</div>
                </div>
              </div>

              <div v-if="product?.child_category_details?.name" class="flex items-center gap-2.5">
                <div class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center shrink-0">
                  <Layers class="h-4 w-4 text-emerald-600" />
                </div>
                <div class="min-w-0">
                  <div class="text-[11px] text-gray-500">{{ t("sale_form_subcategory") }}</div>
                  <div class="text-sm text-gray-800 truncate">{{ product?.child_category_details?.name }}</div>
                </div>
              </div>

              <div v-if="conditionLabel" class="flex items-center gap-2.5">
                <div class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center shrink-0">
                  <ShieldCheck class="h-4 w-4 text-emerald-600" />
                </div>
                <div class="min-w-0">
                  <div class="text-[11px] text-gray-500">{{ t("sale_form_condition") }}</div>
                  <div class="text-sm text-gray-800 truncate">{{ conditionLabel }}</div>
                </div>
              </div>

              <div class="flex items-center gap-2.5">
                <div class="h-8 w-8 rounded-full bg-emerald-50 flex items-center justify-center shrink-0">
                  <MapPin class="h-4 w-4 text-emerald-600" />
                </div>
                <div class="min-w-0">
                  <div class="text-[11px] text-gray-500">{{ t("location") }}</div>
                  <div class="text-sm text-gray-800 truncate">{{ locationDisplay }}</div>
                </div>
              </div>
            </div>

            <!-- Actions -->
            <div class="mt-4 flex gap-2">
              <button
                class="flex-1 text-sm py-2 rounded-lg border border-gray-200 flex items-center justify-center gap-1 hover:bg-gray-50 transition text-gray-600"
                @click="openReportDialog"
              >
                <Flag class="h-3.5 w-3.5" />
                {{ t("sale_detail_report") }}
              </button>
              <button
                class="flex-1 text-sm py-2 rounded-lg border border-gray-200 flex items-center justify-center gap-1 hover:bg-gray-50 transition text-gray-600"
                @click="handleShare"
              >
                <Share2 class="h-3.5 w-3.5" />
                {{ t("sale_detail_share") }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Ad slot #1 (leaderboard) -->
      <SaleAdSlot variant="leaderboard" class="mt-3" />

      <!-- Details + Seller Section -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-3 mt-3">
        <!-- Product Details -->
        <div class="lg:col-span-2 space-y-3">
          <div class="bg-white rounded-xl border border-gray-200 p-4">
            <h2 class="text-base font-bold text-gray-900 flex items-center gap-2 mb-3">
              <ClipboardList class="h-5 w-5 text-emerald-600" />
              {{ t("sale_detail_details") }}
            </h2>
            <div
              class="text-gray-600 whitespace-pre-line text-sm leading-relaxed prose-sm max-w-none"
              v-html="renderRichText(product?.description)"
            ></div>

            <template v-if="hasAddressInfo">
              <div class="my-4 border-t border-gray-100"></div>
              <h3 class="text-sm font-semibold text-gray-900 flex items-center gap-2 mb-2">
                <MapPin class="h-4 w-4 text-emerald-600" />
                {{ t("sale_detail_address") }}
              </h3>
              <p class="text-sm text-gray-700">{{ formattedAddress }}</p>
            </template>
          </div>

          <!-- Safety Tips -->
          <div class="bg-white rounded-xl border border-gray-200 p-4">
            <h2 class="text-base font-bold text-gray-900 flex items-center gap-2 mb-3">
              <ShieldCheck class="h-5 w-5 text-emerald-600" />
              {{ t("sale_detail_safety") }}
            </h2>
            <ul class="space-y-2.5 text-sm text-gray-600">
              <li v-for="tip in safetyTips" :key="tip" class="flex items-start gap-2.5">
                <span class="bg-emerald-50 rounded-full p-1 mt-0.5 shrink-0">
                  <AlertTriangle class="h-3 w-3 text-emerald-600" />
                </span>
                <span>{{ tip }}</span>
              </li>
            </ul>
          </div>
        </div>

        <!-- Seller Info -->
        <div class="lg:col-span-1">
          <div class="bg-white rounded-xl border border-gray-200 p-4 lg:sticky lg:top-4">
            <h2 class="text-base font-bold text-gray-900 flex items-center gap-2 mb-3">
              <User class="h-5 w-5 text-emerald-600" />
              {{ t("sale_detail_seller") }}
            </h2>
            <div class="flex items-center gap-3">
              <div class="size-14 rounded-full bg-gray-100 overflow-hidden border border-gray-200 shrink-0">
                <img
                  :src="product.user_details?.image || '/static/frontend/images/placeholder.jpg'"
                  :alt="`${product.user_details?.first_name} ${product.user_details?.last_name}`"
                  class="h-full w-full object-cover"
                />
              </div>
              <div class="min-w-0">
                <div class="flex items-center gap-1.5 flex-wrap">
                  <NuxtLink
                    :to="`/sale/user-profile/${product.user_details?.id}`"
                    class="font-semibold text-gray-900 hover:text-emerald-600 transition truncate"
                  >
                    {{ product.user_details?.first_name }} {{ product.user_details?.last_name }}
                  </NuxtLink>
                  <UIcon
                    v-if="product.user_details?.kyc"
                    name="mdi:check-decagram"
                    class="w-4 h-4 text-blue-600 shrink-0"
                    :title="t('sale_detail_verified')"
                  />
                  <span
                    v-if="product.user_details?.is_pro"
                    class="px-1.5 py-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-[10px] font-medium inline-flex items-center gap-1"
                  >
                    <UIcon name="i-heroicons-shield-check" class="size-3" />{{ t("pro") }}
                  </span>
                </div>
                <p v-if="product.user_details?.date_joined" class="text-xs text-gray-500 mt-0.5">
                  {{ t("sale_detail_member_since") }} {{ formatDate(product.user_details.date_joined) }}
                </p>
              </div>
            </div>

            <div class="mt-4 space-y-2.5 bg-gray-50 p-3 rounded-lg">
              <div class="flex justify-between text-sm">
                <span class="text-gray-500">{{ t("sale_detail_total_listings") }}</span>
                <span class="font-medium text-gray-800">{{ product.user_details?.sale_post_count || 0 }}</span>
              </div>
              <div v-if="product?.user_details?.phone" class="flex justify-between items-center text-sm">
                <span class="text-gray-500">{{ t("sale_detail_phone") }}</span>
                <div class="flex items-center gap-1.5">
                  <span class="font-medium text-gray-800">
                    {{ showPhone ? product?.user_details?.phone : maskPhoneNumber(product?.user_details?.phone) }}
                  </span>
                  <button class="text-emerald-600 hover:text-emerald-700" @click="toggleShowPhone">
                    <component :is="showPhone ? EyeOff : Eye" class="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>

            <!-- Chat with Seller -->
            <button
              v-if="user?.user?.id !== product.user_details?.id"
              class="w-full mt-3 flex items-center justify-center gap-2 text-white bg-emerald-600 hover:bg-emerald-700 transition text-sm font-semibold py-2.5 px-4 rounded-lg"
              @click="handleButtonClick('chat_seller'); startChatWithSeller();"
            >
              <div v-if="loadingButtons.has('chat_seller')" class="dotted-spinner white"></div>
              <template v-else>
                <UIcon name="i-heroicons-chat-bubble-left-right" class="h-4 w-4" />
                {{ t("sale_detail_chat_seller") }}
              </template>
            </button>

            <button
              class="w-full mt-2 text-sm border border-gray-200 rounded-lg py-2 flex items-center justify-center gap-2 hover:bg-gray-50 transition text-gray-800"
              @click="handleButtonClick('view_seller_profile'); navigateTo('/sale/user-profile/' + product.user_details?.id);"
            >
              <div v-if="loadingButtons.has('view_seller_profile')" class="dotted-spinner slate"></div>
              <User v-else class="h-4 w-4 text-emerald-600" />
              {{ t("sale_detail_view_profile") }}
            </button>
            <NuxtLink
              @click="handleButtonClick('view_more_listings'); navigateTo('/sale/user-profile/' + product.user_details?.id);"
              class="cursor-pointer mt-3 text-emerald-600 hover:text-emerald-700 text-sm flex items-center justify-center gap-1"
            >
              {{ t("sale_detail_view_more") }}
              <div v-if="loadingButtons.has('view_more_listings')" class="dotted-spinner emerald"></div>
              <ChevronRight v-else class="h-3 w-3" />
            </NuxtLink>
          </div>
        </div>
      </div>

      <!-- Ad slot #2 (billboard) -->
      <SaleAdSlot variant="billboard" class="mt-3" />

      <!-- Similar Listings (rail) -->
      <SaleTrendingRail
        v-if="filteredSimilar.length"
        :posts="filteredSimilar.slice(0, 12)"
        :title="t('sale_detail_similar')"
        icon="i-heroicons-sparkles"
        icon-color="text-emerald-600"
        class="mt-3"
      />

      <!-- Share Dialog -->
      <div
        v-if="shareDialogOpen"
        class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
        @click="closeShareDialog"
      >
        <div class="bg-white rounded-xl max-w-md w-full border border-gray-200" @click.stop>
          <div class="flex justify-between items-center p-4 border-b border-gray-100">
            <h3 class="font-semibold text-gray-900">{{ t("sale_detail_share_title") }}</h3>
            <button @click="closeShareDialog" class="text-gray-400 hover:text-gray-600 transition">
              <X class="h-5 w-5" />
            </button>
          </div>
          <div class="p-4">
            <div class="flex items-center gap-2">
              <div class="flex-1 overflow-hidden">
                <div class="flex items-center rounded-lg border border-gray-200 px-3 py-2 overflow-hidden">
                  <span class="text-sm text-gray-600 truncate">{{ shareUrl }}</span>
                </div>
              </div>
              <button
                class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-sm transition flex items-center gap-1"
                @click="copyToClipboard"
              >
                <UIcon name="i-heroicons-clipboard" class="w-4 h-4" />
                {{ t("sale_detail_copy") }}
              </button>
            </div>

            <div class="mt-4">
              <h4 class="text-sm font-medium mb-3 text-gray-800">{{ t("sale_detail_share_via") }}</h4>
              <div class="grid grid-cols-2 gap-3">
                <button
                  class="flex items-center justify-center py-2 px-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition text-gray-800"
                  @click="shareViaMedia('facebook')"
                >
                  <span class="w-5 h-5 bg-blue-600 text-white rounded flex items-center justify-center mr-2 text-sm">f</span>
                  Facebook
                </button>
                <button
                  class="flex items-center justify-center py-2 px-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition text-gray-800"
                  @click="shareViaMedia('twitter')"
                >
                  <span class="w-5 h-5 bg-sky-500 text-white rounded flex items-center justify-center mr-2 text-sm">t</span>
                  Twitter
                </button>
                <button
                  class="flex items-center justify-center py-2 px-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition text-gray-800"
                  @click="shareViaMedia('whatsapp')"
                >
                  <span class="w-5 h-5 bg-emerald-500 text-white rounded flex items-center justify-center mr-2 text-sm">w</span>
                  WhatsApp
                </button>
                <button
                  class="flex items-center justify-center py-2 px-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition text-gray-800"
                  @click="shareViaMedia('email')"
                >
                  <span class="w-5 h-5 bg-gray-700 text-white rounded flex items-center justify-center mr-2 text-sm">@</span>
                  Email
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <CommonUniversalReportDialog
        v-model="showReportDialog"
        :title="t('sale_detail_report')"
        :prompt="t('sale_detail_report_prompt')"
        :options="saleReportOptions"
        :on-submit="submitReport"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed, watch } from "vue";
import SaleSearchBar from "~/components/sale/SaleSearchBar.vue";
import SaleTrendingRail from "~/components/sale/SaleTrendingRail.vue";
import SaleAdSlot from "~/components/sale/SaleAdSlot.vue";
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
  List,
} from "lucide-vue-next";

const { renderRichText } = useRichText();
const { t } = useI18n();

// Import toast functionality for notifications
const toast = useToast();

// Import authentication composable
const { user, isAuthenticated } = useAuth();
const { chatIconPath } = useStaticAssets();

const { params } = useRoute();
const { get, post } = useApi();
const product = ref({});
const similarProducts = ref([]);

async function getSalePost() {
  try {
    const response = await get(`/sale/posts/${params.slug}/`);
    if (response.data) {
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
    }
  } catch (error) {
    console.error("Error fetching similar products:", error);
  }
}
await getSimilarProducts();

// Similar products excluding the current one
const filteredSimilar = computed(() =>
  (similarProducts.value || []).filter((p) => p.slug !== params.slug)
);

// State variables
const currentImageIndex = ref(0);
const showPhone = ref(false);
const shareDialogOpen = ref(false);
const showReportDialog = ref(false);
const galleryRef = ref(null);
const touchStartX = ref(0);
const touchEndX = ref(0);
const shareUrl = ref("");

const saleReportOptions = computed(() => [
  { label: t("sale_report_spam"), value: "spam" },
  { label: t("sale_report_inappropriate"), value: "inappropriate" },
  { label: t("sale_report_duplicate"), value: "duplicate" },
  { label: t("sale_report_fraud"), value: "fraud" },
  { label: t("sale_report_other"), value: "other" },
]);

// Condition value -> localized label
const CONDITION_KEYS = {
  "brand-new": "sale_cond_brand_new",
  brandnew: "sale_cond_brand_new",
  new: "sale_cond_new",
  "like-new": "sale_cond_like_new",
  likenew: "sale_cond_like_new",
  used: "sale_cond_used",
  good: "sale_cond_good",
  fair: "sale_cond_fair",
  "for-parts": "sale_cond_for_parts",
  refurbished: "sale_cond_refurbished",
};
const conditionLabel = computed(() => {
  const c = (product.value?.condition || "").toString().toLowerCase().replace(/\s+/g, "-");
  if (!c) return "";
  const key = CONDITION_KEYS[c] || CONDITION_KEYS[c.replace(/-/g, "")];
  return key ? t(key) : product.value.condition;
});

// Localized safety tips
const safetyTips = computed(() => [
  t("sale_detail_tip_meet"),
  t("sale_detail_tip_advance"),
  t("sale_detail_tip_inspect"),
  t("sale_detail_tip_deal"),
]);

// Loading state for buttons
const loadingButtons = ref(new Set());

// Handle button clicks with loading states
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
};

// Watch route changes to clear loading states
watch(
  () => useRoute().fullPath,
  () => {
    loadingButtons.value.clear();
  }
);

// Format date
const formatDate = (dateString) => {
  if (!dateString) return "N/A";
  try {
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return "N/A";
    return new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    }).format(date);
  } catch (e) {
    return "N/A";
  }
};

// Mask phone number
const maskPhoneNumber = (phone) => {
  if (!phone) return t("sale_detail_not_provided");
  return "XXXXXXX" + phone?.slice(-3);
};

// Computed property to check if address info exists
const hasAddressInfo = computed(() => {
  const p = product.value;
  return (
    (p?.detailed_address && p.detailed_address.trim() !== "") ||
    (p?.division && p?.district) ||
    p?.area
  );
});

// Computed property for formatted address
const formattedAddress = computed(() => {
  const p = product.value;

  if (p?.detailed_address && p.detailed_address.trim() !== "") {
    return p.detailed_address;
  }

  const parts = [];
  if (p?.area) parts.push(p.area);
  if (p?.district) parts.push(p.district);
  if (p?.division) parts.push(p.division);

  if (parts.length > 0) {
    return parts.join(", ");
  }

  return t("sale_detail_location_unspecified");
});

// Computed property for location display in the grid
const locationDisplay = computed(() => {
  const p = product.value;

  const parts = [];
  if (p?.division) parts.push(p.division);
  if (p?.district) parts.push(p.district);
  if (p?.area) parts.push(p.area);

  if (parts.length > 0) {
    return parts.join(", ");
  }

  return t("all_over_bangladesh");
});

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

  if (Math.abs(touchDiff) > 50) {
    if (touchDiff > 0) {
      nextImage();
    } else {
      prevImage();
    }
  }
};

// Download image
const downloadImage = () => {
  const currentImage = product.value?.images?.[currentImageIndex.value];
  const imageUrl = currentImage?.image;

  if (!imageUrl) {
    console.error("No image URL found for download");
    return;
  }

  const link = document.createElement("a");
  link.href = imageUrl;
  link.download = `product-image-${currentImageIndex.value + 1}.jpg`;
  link.setAttribute("target", "_blank");
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

// Toggle phone visibility
const toggleShowPhone = () => {
  showPhone.value = !showPhone.value;
};

// Chat with seller functionality
const startChatWithSeller = async () => {
  try {
    if (!isAuthenticated.value) {
      await navigateTo("/auth/login");
      return;
    }

    if (!product.value?.user_details?.id) {
      toast.add({
        title: t("sale_detail_error"),
        description: t("sale_detail_seller_unavailable"),
        color: "red",
        timeout: 3000,
      });
      return;
    }

    await navigateTo(`/inbox?chat_with=${product.value.user_details.id}`);

    toast.add({
      title: t("sale_detail_chat_started"),
      description: `${product.value.user_details.first_name} ${product.value.user_details.last_name}`,
      color: "green",
      timeout: 2000,
    });
  } catch (error) {
    console.error("Error starting chat:", error);
    toast.add({
      title: t("sale_detail_error"),
      description: t("sale_detail_chat_failed"),
      color: "red",
      timeout: 3000,
    });
  } finally {
    loadingButtons.value.delete("chat_seller");
  }
};

// Share functionality
const handleShare = () => {
  shareDialogOpen.value = true;
  const productionDomain = "https://adsyclub.com";
  const pathname = window.location.pathname;
  shareUrl.value = productionDomain + pathname;
};

const closeShareDialog = () => {
  shareDialogOpen.value = false;
};

const copyToClipboard = () => {
  navigator.clipboard.writeText(shareUrl.value);
  toast.add({
    title: t("sale_detail_link_copied"),
    description: t("sale_detail_link_copied_desc"),
    color: "green",
    icon: "i-heroicons-check-circle",
  });
};

const shareViaMedia = (platform) => {
  let platformShareUrl = "";
  const currentUrl = encodeURIComponent(shareUrl.value);
  const title = encodeURIComponent(product.value?.title);
  switch (platform) {
    case "facebook":
      platformShareUrl = `https://www.facebook.com/sharer/sharer.php?u=${currentUrl}`;
      break;
    case "twitter":
      platformShareUrl = `https://twitter.com/intent/tweet?text=${title}&url=${currentUrl}`;
      break;
    case "whatsapp":
      platformShareUrl = `https://api.whatsapp.com/send?text=${title} ${currentUrl}`;
      break;
    case "email":
      platformShareUrl = `mailto:?subject=${title}&body=${currentUrl}`;
      break;
  }

  if (platformShareUrl) {
    window.open(platformShareUrl, "_blank");
  }

  closeShareDialog();
};

// Report functionality
const openReportDialog = () => {
  showReportDialog.value = true;
};

const submitReport = async ({ reason, details }) => {
  const response = await post(`/sale/posts/${params.slug}/report/`, {
    reason,
    details,
  });
  return !response.error;
};

// Function to capitalize first letter of title
const capitalizeTitle = (title) => {
  if (!title) return "";
  return title.charAt(0).toUpperCase() + title.slice(1);
};

// Search handlers for the search bar
const handleSearch = (searchTerm) => {
  navigateTo(`/sale?search=${encodeURIComponent(searchTerm)}`);
};

const handleClearLocation = () => {
  window.location.reload();
};
</script>

<style scoped>
/* Hide scrollbar but maintain functionality */
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

.dotted-spinner.emerald {
  border-color: #059669;
}

.dotted-spinner.slate {
  border-color: #64748b;
}

.dotted-spinner.blue {
  border-color: #3b82f6;
}

.dotted-spinner.white {
  border-color: #ffffff;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
