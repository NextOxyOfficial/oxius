<template>
  <div>
    <h3
      class="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between"
    >
      <div class="flex items-center">
        <Newspaper class="h-3.5 w-3.5 mr-1.5" />
        <span>Adsy News</span>
      </div>
      <a
        href="/adsy-news"
        class="text-blue-700 text-xs normal-case font-medium hover:underline flex items-center"
        @click.prevent="$emit('navigation', '/adsy-news')"
      >
        <span>See All</span>
        <ChevronRight class="h-3 w-3 ml-0.5" />
      </a>
    </h3>
    <div class="px-3 relative">
      <div
        v-if="isLoading"
        class="flex justify-center items-center h-40 bg-gray-50 rounded-lg"
      >
        <div
          class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"
        ></div>
      </div>

      <div
        v-else
        class="overflow-hidden rounded-lg border border-gray-200 shadow-sm"
      >
        <div
          class="transition-transform duration-300 ease-in-out flex"
          :style="{
            transform: `translateX(-${currentNewsIndex * 100}%)`,
          }"
          @mouseenter="pauseCarousel"
          @mouseleave="resumeCarousel"
        >
          <a
            v-for="(news, index) in newsItems"
            :key="index"
            :href="`/adsy-news/${news.slug}/`"
            class="w-full flex-shrink-0"
            @click.prevent="$emit('navigation', `/adsy-news/${news.slug}/`)"
          >
            <div class="aspect-[16/9] w-full bg-gray-100 relative">
              <img
                :src="
                  news.image
                    ? news.image
                    : '/static/frontend/images/placeholder.jpg'
                "
                :alt="news.title"
                class="w-full h-full object-cover"
              />
              <div
                class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent p-3"
              >
                <div class="flex items-center mb-1">
                  <span
                    class="text-xs font-medium text-white bg-blue-600 px-2 py-0.5 rounded-sm"
                    >News</span
                  >
                  <span
                    class="text-xs text-white/80 ml-2 flex items-center"
                  >
                    <Clock class="h-3 w-3 mr-1" />
                    {{ formatDate(news.created_at) }}
                  </span>
                </div>
                <h4 class="text-sm font-medium text-white line-clamp-2">
                  {{ news.title }}
                </h4>
              </div>
            </div>
          </a>
        </div>
      </div>
      <!-- News Controls -->
      <div class="flex justify-between items-center mt-2">
        <div class="flex space-x-1">
          <button
            v-for="(_, index) in newsItems"
            :key="index"
            @click="currentNewsIndex = index"
            :class="[
              'h-1.5 rounded-full transition-all',
              currentNewsIndex === index
                ? 'w-4 bg-blue-600'
                : 'w-1.5 bg-gray-300',
            ]"
          ></button>
        </div>
        <div class="flex space-x-1">
          <button
            class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
            @click="prevNews"
          >
            <ChevronLeft class="h-3 w-3" />
          </button>
          <button
            class="h-6 w-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-gray-200"
            @click="nextNews"
          >
            <ChevronRight class="h-3 w-3" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Newspaper, ChevronLeft, ChevronRight, Clock, ChevronRight as ChevronRightIcon } from "lucide-vue-next";

const emit = defineEmits(['navigation']);

const props = defineProps({
  newsItems: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  }
});

const currentNewsIndex = ref(0);
let newsInterval = null;

// Function to move to next news item
const nextNews = () => {
  if (props.newsItems.length === 0) return;
  currentNewsIndex.value =
    (currentNewsIndex.value + 1) % props.newsItems.length;
};

// Function to move to previous news item
const prevNews = () => {
  if (props.newsItems.length === 0) return;
  currentNewsIndex.value =
    (currentNewsIndex.value - 1 + props.newsItems.length) %
    props.newsItems.length;
};

// Pause carousel on hover
const pauseCarousel = () => {
  if (newsInterval) {
    clearInterval(newsInterval);
  }
};

// Resume carousel when not hovering
const resumeCarousel = () => {
  pauseCarousel(); // Clear any existing interval first
  newsInterval = setInterval(() => {
    nextNews();
  }, 7000);
};

// Format date for news items
const formatDate = (dateString) => {
  if (!dateString) return "";
  const options = { year: "numeric", month: "short", day: "numeric" };
  return new Date(dateString).toLocaleDateString(undefined, options);
};

// Start the carousel when component mounts
onMounted(() => {
  resumeCarousel();
});

// Clean up intervals when component unmounts
onUnmounted(() => {
  if (newsInterval) clearInterval(newsInterval);
});
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-clamp: 2; /* Standard property for compatibility */
}
</style>