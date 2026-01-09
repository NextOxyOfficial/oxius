<template>
  <PublicSection>
    <div class="bg-gradient-to-b from-rose-50 to-white min-h-screen">
      <div class="bg-gradient-to-b from-pink-600 to-pink-500 text-white">
        <UContainer class="py-4">
          <div class="flex items-center gap-2">
            <div
              class="w-9 h-9 rounded-xl bg-white/15 border border-white/20 flex items-center justify-center"
            >
              <UIcon name="i-heroicons-rectangle-stack" class="w-5 h-5" />
            </div>
            <div class="flex-1">
              <h1 class="text-xl font-bold tracking-tight">Food Zone</h1>
              <p class="text-xs text-pink-100">Delicious food near you</p>
            </div>
          </div>

          <div class="mt-3">
            <div
              class="h-11 bg-white rounded-full shadow-sm flex items-center px-4 gap-2"
            >
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="w-5 h-5 text-pink-500"
              />
              <input
                v-model="searchQuery"
                type="text"
                class="flex-1 outline-none border-none bg-transparent text-sm text-gray-800 placeholder:text-gray-400"
                placeholder="Search food items..."
              />
              <button
                v-if="searchQuery"
                type="button"
                class="p-1 rounded-full hover:bg-gray-100"
                @click="clearSearch"
              >
                <UIcon name="i-heroicons-x-mark" class="w-4 h-4 text-gray-400" />
              </button>
            </div>
          </div>
        </UContainer>
      </div>

      <CommonGeoSelector />

      <UContainer class="py-4">
        <div
          v-if="location"
          class="location-breadcrumb relative mb-4 overflow-hidden"
        >
          <div
            class="absolute inset-0 bg-gradient-to-r from-rose-50 to-pink-50 opacity-80 rounded-lg"
          ></div>
          <div class="absolute -left-3 top-1/2 -translate-y-1/2 text-pink-200">
            <UIcon name="i-heroicons-map-pin" class="w-16 h-16" />
          </div>
          <div
            class="relative z-10 flex items-center justify-between px-3 pl-12 rounded-lg border border-pink-100 py-3"
          >
            <div class="flex items-center flex-wrap gap-x-1.5 gap-y-1 text-sm">
              <span class="font-medium text-gray-800">{{ location?.country || 'Bangladesh' }}</span>
              <template v-if="location?.allOverBangladesh">
                <span class="text-xs bg-pink-100 text-pink-700 px-2 py-0.5 rounded-full">All over</span>
              </template>
              <template v-else>
                <span v-if="location?.state" class="text-gray-600">/ {{ location.state }}</span>
                <span v-if="location?.city" class="text-gray-600">/ {{ location.city }}</span>
                <span v-if="location?.upazila" class="text-gray-600">/ {{ location.upazila }}</span>
              </template>
            </div>
            <UButton
              icon="i-heroicons-pencil-square"
              size="xs"
              color="pink"
              variant="ghost"
              class="ml-2"
              @click="handleClearLocation"
            />
          </div>
        </div>

        <div v-if="loadError" class="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3">
          <div class="text-sm font-semibold text-red-700">Failed to load Food Zone</div>
          <div v-if="loadErrorMessage" class="text-xs text-red-600 mt-0.5">
            {{ loadErrorMessage }}
          </div>
          <div class="mt-3">
            <UButton color="red" variant="solid" size="sm" @click="refreshAll">
              Retry
            </UButton>
          </div>
        </div>


        <div v-if="isLoading" class="space-y-3">
          <div
            v-for="i in 6"
            :key="i"
            class="bg-white rounded-xl border border-gray-100 shadow-sm p-3 flex gap-3"
          >
            <div class="w-20 h-20 rounded-lg bg-gray-100"></div>
            <div class="flex-1 space-y-2">
              <div class="h-3 bg-gray-100 rounded w-2/3"></div>
              <div class="h-3 bg-gray-100 rounded w-1/2"></div>
              <div class="h-3 bg-gray-100 rounded w-1/3"></div>
            </div>
          </div>
        </div>

        <div v-else-if="!posts.length" class="py-16 text-center">
          <div
            class="w-20 h-20 mx-auto rounded-full bg-rose-100 flex items-center justify-center"
          >
            <UIcon
              name="i-heroicons-building-storefront"
              class="w-10 h-10 text-pink-600"
            />
          </div>
          <div class="mt-4 text-lg font-semibold text-gray-800">No food items found</div>
          <div class="mt-1 text-sm text-gray-500">
            <span v-if="searchQuery">Try a different search term</span>
            <span v-else>Check back later for delicious options</span>
          </div>
          <button
            v-if="searchQuery"
            type="button"
            class="mt-4 text-sm font-semibold text-pink-600 hover:text-pink-700"
            @click="clearSearch"
          >
            Clear Search
          </button>
        </div>

        <div v-else class="space-y-3">
          <NuxtLink
            v-for="p in posts"
            :key="p.id"
            :to="`/classified-categories/details/${p.slug || p.id}`"
            class="block bg-white rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow"
          >
            <div class="p-3 flex gap-3">
              <div class="relative w-20 h-20 rounded-lg overflow-hidden bg-rose-50 flex-shrink-0">
                <img
                  v-if="p?.medias?.length && p.medias[0]?.image"
                  :src="getImageUrl(p.medias[0].image)"
                  alt=""
                  class="w-full h-full object-cover"
                />
                <img
                  v-else-if="p?.category_details?.image"
                  :src="getImageUrl(p.category_details.image)"
                  alt=""
                  class="w-full h-full object-cover"
                />
                <div v-else class="w-full h-full flex items-center justify-center">
                  <UIcon name="i-heroicons-cake" class="w-8 h-8 text-pink-500" />
                </div>

                <div
                  v-if="p.negotiable"
                  class="absolute top-1 left-1 px-2 py-0.5 rounded bg-pink-600 text-white text-[10px] font-bold"
                >
                  Negotiable
                </div>
              </div>

              <div class="flex-1 min-w-0">
                <div
                  v-if="p?.user"
                  class="text-[11px] font-semibold text-pink-600 truncate"
                >
                  {{ `${p.user?.first_name || ''} ${p.user?.last_name || ''}`.trim() }}
                </div>
                <div class="text-sm font-semibold text-gray-900 mt-0.5 line-clamp-2">
                  {{ p.title }}
                </div>

                <div class="mt-1 text-xs text-gray-500 flex items-center gap-1">
                  <UIcon name="i-heroicons-map-pin" class="w-3 h-3" />
                  <span class="truncate">{{ [p.upazila, p.city].filter(Boolean).join(', ') }}</span>
                </div>

                <div class="mt-2 flex items-center justify-between">
                  <div class="text-sm font-bold text-pink-600">
                    <span v-if="p?.price && Number(p.price) > 0">৳{{ Number(p.price).toFixed(0) }}</span>
                    <span v-else class="text-xs font-medium text-gray-500">Contact for price</span>
                  </div>
                  <UIcon name="i-heroicons-chevron-right" class="w-5 h-5 text-gray-300" />
                </div>
              </div>
            </div>
          </NuxtLink>

          <div v-if="hasMore" class="pt-2 flex justify-center">
            <UButton
              :loading="isLoadingMore"
              color="pink"
              variant="solid"
              class="px-6"
              @click="loadMore"
            >
              Load more
            </UButton>
          </div>
        </div>
      </UContainer>
    </div>
  </PublicSection>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from "vue";

useHead({
  title: "Food Zone - AdsyClub",
});

const { get, staticURL } = useApi();
const { location, clearLocation } = useLocation();

const posts = ref([]);

const searchQuery = ref("");

const currentPage = ref(1);
const hasMore = ref(false);

const isLoading = ref(true);
const isLoadingMore = ref(false);

const loadError = ref(false);
const loadErrorMessage = ref("");

const getImageUrl = (url) => {
  if (!url) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  if (url.startsWith("/")) return staticURL + url;
  return staticURL + "/" + url;
};

const normalizeArrayOrResults = (data) => {
  if (!data) return { results: [], next: null };
  if (Array.isArray(data)) return { results: data, next: null };
  if (data.results) return { results: data.results, next: data.next || null };
  return { results: [], next: null };
};

const buildPostParams = (page) => {
  const params = {
    page,
    page_size: 20,
  };

  if (searchQuery.value && searchQuery.value.trim()) {
    params.search = searchQuery.value.trim();
  }

  const loc = location.value;
  if (loc?.country) {
    params.country = loc.country;
  }

  if (loc && !loc.allOverBangladesh) {
    if (loc.state) params.state = loc.state;
    if (loc.city) params.city = loc.city;
    if (loc.upazila) params.upazila = loc.upazila;
  }

  return params;
};

const fetchPosts = async (opts = {}) => {
  const reset = opts.reset !== undefined ? opts.reset : true;
  const page = reset ? 1 : currentPage.value;

  if (reset) {
    isLoading.value = true;
  } else {
    isLoadingMore.value = true;
  }

  const res = await get("/food-zone/posts/", { params: buildPostParams(page) });
  if (res.error) {
    loadError.value = true;
    loadErrorMessage.value = res.error?.message || "Please try again.";
    if (reset) {
      posts.value = [];
      currentPage.value = 1;
      hasMore.value = false;
    }
    isLoading.value = false;
    isLoadingMore.value = false;
    return;
  }
  const { results, next } = normalizeArrayOrResults(res.data);

  if (reset) {
    posts.value = results;
    currentPage.value = 1;
  } else {
    posts.value = [...posts.value, ...results];
  }

  hasMore.value = !!next;

  isLoading.value = false;
  isLoadingMore.value = false;
};

const refreshAll = async () => {
  loadError.value = false;
  loadErrorMessage.value = "";
  await fetchPosts({ reset: true });
};

const clearSearch = async () => {
  searchQuery.value = "";
  await fetchPosts({ reset: true });
};

const loadMore = async () => {
  if (!hasMore.value || isLoadingMore.value) return;
  currentPage.value = currentPage.value + 1;
  await fetchPosts({ reset: false });
};

const handleClearLocation = () => {
  clearLocation();
  window.location.reload();
};

let searchTimer = null;
watch(
  () => searchQuery.value,
  () => {
    if (searchTimer) clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      fetchPosts({ reset: true });
    }, 450);
  }
);

const handleScroll = () => {
  if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
  const nearBottom =
    window.innerHeight + window.scrollY >=
    document.documentElement.scrollHeight - 400;
  if (nearBottom) {
    loadMore();
  }
};

watch(
  () => location.value,
  () => {
    fetchPosts({ reset: true });
  },
  { deep: true }
);

onMounted(() => {
  refreshAll();
  window.addEventListener("scroll", handleScroll);
});

onBeforeUnmount(() => {
  if (searchTimer) clearTimeout(searchTimer);
  window.removeEventListener("scroll", handleScroll);
});
</script>

<style scoped>
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
