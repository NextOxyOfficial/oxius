<template>
  <div
    v-if="!isLoading && !posts.length"
    class="hidden"
  ></div>

  <div
    v-else
    class="my-3"
  >
    <div
      class="rounded-2xl border border-pink-200/50 bg-gradient-to-b from-pink-50 to-white overflow-hidden"
    >
      <div class="px-4 py-3 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div
            class="w-10 h-10 rounded-2xl bg-gradient-to-br from-pink-600 to-pink-500 flex items-center justify-center shadow-sm"
          >
            <UIcon name="i-heroicons-rectangle-stack" class="w-5 h-5 text-white" />
          </div>
          <div>
            <div class="text-sm font-bold text-pink-700">Food Zone</div>
            <div class="text-xs text-gray-500">Delicious food near you</div>
          </div>
        </div>

        <NuxtLink
          to="/food-zone"
          class="px-3 py-1.5 rounded-full bg-pink-600 text-white text-xs font-bold hover:bg-pink-700 transition-colors"
        >
          See All
        </NuxtLink>
      </div>

      <div class="px-2 pb-1">

        <div v-if="isLoading" class="flex gap-3 overflow-x-auto scrollbar-hide py-1 cursor-grab active:cursor-grabbing">
          <div
            v-for="i in 6"
            :key="i"
            class="w-40 shrink-0 rounded-xl bg-white border border-gray-100 shadow-sm overflow-hidden"
          >
            <div class="h-24 bg-gray-100"></div>
            <div class="p-2 space-y-2">
              <div class="h-3 bg-gray-100 rounded w-4/5"></div>
              <div class="h-3 bg-gray-100 rounded w-2/3"></div>
            </div>
          </div>
        </div>

        <div
          v-else
          ref="scrollContainer"
          class="flex gap-3 overflow-x-auto scrollbar-hide py-1 cursor-grab active:cursor-grabbing select-none"
          @mousedown="startDrag"
          @mousemove="onDrag"
          @mouseup="stopDrag"
          @mouseleave="stopDrag"
        >
          <NuxtLink
            v-for="p in posts"
            :key="p.id"
            :to="`/classified-categories/details/${p.slug || p.id}`"
            class="w-40 shrink-0 rounded-xl bg-white border border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden"
          >
            <div class="relative h-24 bg-pink-50">
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

            <div class="p-2">
              <div class="text-xs font-semibold text-gray-900 line-clamp-2">
                {{ p.title }}
              </div>
              <div class="mt-1 flex items-center justify-between">
                <div class="text-xs font-bold text-pink-600">
                  <span v-if="p?.price && Number(p.price) > 0">৳{{ Number(p.price).toFixed(0) }}</span>
                  <span v-else class="text-[10px] font-medium text-gray-500">Contact</span>
                </div>
                <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 text-gray-300" />
              </div>
            </div>
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";

const scrollContainer = ref(null);
let isDragging = false;
let startX = 0;
let scrollLeft = 0;

const startDrag = (e) => {
  if (!scrollContainer.value) return;
  isDragging = true;
  startX = e.pageX - scrollContainer.value.offsetLeft;
  scrollLeft = scrollContainer.value.scrollLeft;
};

const onDrag = (e) => {
  if (!isDragging || !scrollContainer.value) return;
  e.preventDefault();
  const x = e.pageX - scrollContainer.value.offsetLeft;
  const walk = (x - startX) * 1.5;
  scrollContainer.value.scrollLeft = scrollLeft - walk;
};

const stopDrag = () => {
  isDragging = false;
};

const { get, staticURL } = useApi();

const posts = ref([]);
const isLoading = ref(true);

const getImageUrl = (url) => {
  if (!url) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  if (url.startsWith("/")) return staticURL + url;
  return staticURL + "/" + url;
};

const fetchFoodZonePreview = async () => {
  isLoading.value = true;

  const postsRes = await get("/food-zone/posts/", {
    params: {
      page: 1,
      page_size: 10,
    },
  });

  const d = postsRes.data;
  if (d?.results && Array.isArray(d.results)) {
    posts.value = d.results;
  } else if (Array.isArray(d)) {
    posts.value = d;
  } else {
    posts.value = [];
  }

  isLoading.value = false;
};

onMounted(fetchFoodZonePreview);
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
