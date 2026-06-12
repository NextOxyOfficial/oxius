<template>
  <div class="min-h-screen bg-gray-50/60">
    <main class="max-w-7xl mx-auto px-2 sm:px-6 lg:px-8 pb-10">
      <!-- ===== FRONT PAGE: Lead story + Top stories ===== -->
      <section class="mt-2 mb-8">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <!-- Lead story -->
          <NuxtLink
            :to="`/adsy-news/${latestArticle.slug}/`"
            class="lg:col-span-2 group relative block rounded-xl overflow-hidden border border-gray-200 bg-black h-[300px] sm:h-[420px]"
          >
            <img
              :src="latestArticle.image"
              :alt="latestArticle.title"
              class="w-full h-full object-cover opacity-95 transition-transform duration-700 group-hover:scale-105"
            />
            <div
              class="absolute inset-0 bg-gradient-to-t from-black/85 via-black/40 to-transparent"
            ></div>
            <div class="absolute bottom-0 left-0 right-0 p-4 sm:p-6 text-white">
              <div class="flex items-center gap-3 mb-2">
                <span
                  class="bg-primary text-white text-[11px] font-bold px-2.5 py-1 rounded uppercase tracking-wide"
                  >{{ $t("news_latest_news") }}</span
                >
                <span class="text-xs text-white/80">{{
                  latestArticle.date
                }}</span>
              </div>
              <h2
                class="text-lg sm:text-2xl font-bold leading-snug line-clamp-3"
              >
                {{ latestArticle.title }}
              </h2>
              <div
                class="hidden sm:block mt-2 text-sm text-white/85 line-clamp-2"
                v-html="latestArticle.summary"
              ></div>
            </div>
          </NuxtLink>

          <!-- Top stories -->
          <div
            class="rounded-xl border border-gray-200 bg-white p-4 flex flex-col"
          >
            <h3
              class="flex items-center gap-2 text-base font-bold text-gray-900 mb-2"
            >
                {{ $t("news_top_stories") }}
            </h3>
            <div class="divide-y divide-gray-100 flex-1">
              <NuxtLink
                v-for="(article, idx) in topStories"
                :key="article.id"
                :to="`/adsy-news/${article.slug}/`"
                class="flex gap-3 py-3 first:pt-1 last:pb-0 group items-start"
              >
                <span class="text-lg font-bold text-primary w-5 shrink-0 leading-6"
                  >{{ idx + 1 }}</span
                >
                <div class="min-w-0 flex-1">
                  <h4
                    class="text-sm font-semibold text-gray-800 line-clamp-2 group-hover:text-primary transition-colors"
                  >
                    {{ article.title }}
                  </h4>
                  <span class="text-xs text-gray-500 mt-1 block">{{
                    article.date
                  }}</span>
                </div>
                <img
                  :src="article.image"
                  :alt="article.title"
                  class="w-16 h-14 rounded-lg object-cover shrink-0"
                />
              </NuxtLink>
            </div>
          </div>
        </div>
      </section>

      <!-- Ad -->
      <div class="mb-8">
        <SaleAdSlot variant="leaderboard" />
      </div>

      <!-- ===== Category-wise News ===== -->
      <section v-for="cat in categorySections" :key="cat.id" class="mb-8">
        <div class="flex items-center justify-between mb-4">
          <h2 class="flex items-center gap-2 text-lg font-bold text-gray-900">
            {{ cat.title }}
          </h2>
          <NuxtLink
            :to="`/adsy-news/categories/${cat.slug}/`"
            class="inline-flex items-center gap-1 text-sm font-semibold text-primary hover:text-primary-dark transition-colors"
          >
            {{ $t("news_see_all") }}
            <ChevronRightIcon class="h-4 w-4" />
          </NuxtLink>
        </div>
        <div class="grid gap-3 sm:gap-4 grid-cols-2 md:grid-cols-4">
          <NuxtLink
            v-for="post in cat.posts"
            :key="post.id"
            :to="`/adsy-news/${post.slug}/`"
            class="group block rounded-xl border border-gray-200 bg-white overflow-hidden hover:border-gray-300 transition-colors"
          >
            <div class="relative h-36">
              <img
                :src="post.image"
                :alt="post.title"
                class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
              />
            </div>
            <div class="p-3">
              <h3
                class="text-sm font-semibold text-gray-800 line-clamp-2 group-hover:text-primary transition-colors"
              >
                {{ post.title }}
              </h3>
              <div class="flex items-center gap-1.5 text-xs text-gray-500 mt-2">
                <UIcon name="i-heroicons-calendar-days" class="w-3.5 h-3.5" />
                <span>{{ post.date }}</span>
              </div>
            </div>
          </NuxtLink>
        </div>
      </section>

      <!-- Ad -->
      <div class="mb-8">
        <SaleAdSlot variant="leaderboard" />
      </div>

      <!-- ===== Trending News ===== -->
      <section class="mb-8">
        <div class="flex items-center justify-between mb-4">
          <h2 class="flex items-center gap-2 text-lg font-bold text-gray-900">
            {{ $t("news_trending") }}
          </h2>
          <div class="flex gap-2">
            <button
              @click="prevTrending"
              @mouseenter="pauseCarousel"
              class="w-8 h-8 rounded-full border border-gray-200 bg-white hover:bg-gray-50 flex items-center justify-center transition-colors"
            >
              <ChevronLeftIcon class="h-4 w-4 text-gray-700" />
            </button>
            <button
              @click="nextTrending"
              @mouseenter="pauseCarousel"
              class="w-8 h-8 rounded-full border border-gray-200 bg-white hover:bg-gray-50 flex items-center justify-center transition-colors"
            >
              <ChevronRightIcon class="h-4 w-4 text-gray-700" />
            </button>
          </div>
        </div>

        <div class="relative overflow-hidden">
          <div
            class="flex transition-transform duration-500 ease-in-out"
            :style="{
              transform: `translateX(-${
                (trendingIndex * 100) / trendingPerPage
              }%)`,
            }"
            @mouseenter="pauseCarousel"
            @mouseleave="resumeCarousel"
          >
            <div
              v-for="article in trendingArticles"
              :key="article.id"
              class="flex-shrink-0 mb-1 w-full sm:w-1/2 md:w-1/3 lg:w-1/4 px-2"
            >
              <NuxtLink
                :to="`/adsy-news/${article.slug}/`"
                class="group block h-full rounded-xl border border-gray-200 bg-white overflow-hidden hover:border-gray-300 transition-colors"
              >
                <div class="relative h-36">
                  <img
                    :src="article.image"
                    :alt="article.title"
                    class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <span
                    v-for="tag in article.tags"
                    :key="tag"
                    class="absolute top-2 left-2 bg-primary text-white text-[10px] font-semibold px-2 py-0.5 rounded"
                  >
                    {{ tag }}
                  </span>
                </div>
                <div class="p-3">
                  <h3
                    class="text-sm font-semibold mb-2 text-gray-800 line-clamp-2 group-hover:text-primary transition-colors"
                  >
                    {{ article.title }}
                  </h3>
                  <div
                    class="flex justify-between items-center text-xs text-gray-500"
                  >
                    <span>{{ article.date }}</span>
                    <span class="flex items-center gap-1">
                      <MessageSquareIcon class="h-3.5 w-3.5" />
                      {{ article.comments.length }}
                    </span>
                  </div>
                </div>
              </NuxtLink>
            </div>
          </div>
        </div>

        <div class="flex justify-center mt-4 gap-1.5">
          <button
            v-for="(_, i) in Math.ceil(
              trendingArticles.length / trendingPerPage
            )"
            :key="i"
            @click="trendingIndex = i"
            :class="[
              'h-1.5 rounded-full transition-all',
              trendingIndex === i
                ? 'w-5 bg-primary'
                : 'w-1.5 bg-gray-300 hover:bg-gray-400',
            ]"
          ></button>
        </div>
      </section>

      <!-- ===== All News + Sidebar ===== -->
      <section class="mb-8">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Main column -->
          <div class="lg:col-span-2 min-w-0">
            <div class="flex items-center justify-between mb-4">
              <h2
                class="flex items-center gap-2 text-lg font-bold text-gray-900"
              >
                    {{ $t("news_all") }}
              </h2>
          <div class="flex gap-2">
            <button
              v-for="layout in layouts"
              :key="layout.id"
              @click="currentLayout = layout.id"
              :class="[
                'p-1.5 rounded-md border transition-colors',
                currentLayout === layout.id
                  ? 'border-gray-300 bg-gray-100'
                  : 'border-gray-200 hover:bg-gray-50',
              ]"
            >
              <LayoutGridIcon
                v-if="layout.id === 'grid'"
                class="h-4 w-4 text-gray-700"
              />
              <LayoutListIcon v-else class="h-4 w-4 text-gray-700" />
            </button>
          </div>
        </div>

        <div
          :class="[
            currentLayout === 'grid'
              ? 'grid gap-3 sm:gap-4 grid-cols-1 sm:grid-cols-2 xl:grid-cols-3'
              : 'space-y-3',
          ]"
        >
          <article
            v-for="article in filteredArticles"
            :key="article.id"
            :class="[
              'rounded-xl border border-gray-200 bg-white overflow-hidden hover:border-gray-300 transition-colors',
              currentLayout === 'list' ? 'flex' : '',
            ]"
          >
            <NuxtLink
              :to="`/adsy-news/${article.slug}/`"
              :class="[
                'group relative block overflow-hidden',
                currentLayout === 'list' ? 'w-28 sm:w-44 shrink-0' : '',
              ]"
            >
              <div
                :class="[
                  currentLayout === 'list' ? 'h-full min-h-[6rem]' : 'h-40 sm:h-44',
                ]"
              >
                <img
                  :src="article.image"
                  :alt="article.title"
                  class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
              </div>
              <span
                v-for="tag in article.tags"
                :key="tag"
                class="absolute top-2 left-2 bg-primary text-white text-[10px] font-semibold px-2 py-0.5 rounded"
              >
                {{ tag }}
              </span>
            </NuxtLink>
            <div :class="['p-3', currentLayout === 'list' ? 'flex-1' : '']">
              <NuxtLink :to="`/adsy-news/${article.slug}/`">
                <h3
                  class="text-sm font-semibold text-gray-800 line-clamp-2 hover:text-primary transition-colors"
                >
                  {{ article.title }}
                </h3>
              </NuxtLink>
              <div class="flex items-center gap-1.5 text-xs text-gray-500 mt-2">
                <UIcon name="i-heroicons-calendar-days" class="w-3.5 h-3.5" />
                <span>{{ article.date }}</span>
              </div>
            </div>
          </article>
        </div>

        <!-- Load More -->
        <div v-if="hasMoreArticles" class="mt-6 text-center">
          <button
            @click="loadMoreArticles"
            class="px-6 py-2.5 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors font-semibold text-sm disabled:opacity-60"
            :disabled="isLoading || !hasMoreArticles"
          >
            <span v-if="isLoading">{{ $t("loading") }}</span>
            <span v-else>{{ $t("news_load_more") }}</span>
          </button>
        </div>
          </div>

          <!-- Sidebar -->
          <aside class="lg:col-span-1 space-y-5 lg:sticky lg:top-20 lg:self-start">
            <!-- Most Read -->
            <div
              v-if="mostReadArticles.length"
              class="rounded-xl border border-gray-200 bg-white p-4"
            >
              <h3
                class="flex items-center gap-2 text-base font-bold text-gray-900 mb-2"
              >
                    {{ $t("news_most_read") }}
              </h3>
              <div class="divide-y divide-gray-100">
                <NuxtLink
                  v-for="(a, idx) in mostReadArticles"
                  :key="a.id"
                  :to="`/adsy-news/${a.slug}/`"
                  class="flex gap-3 py-3 first:pt-1 last:pb-0 group items-start"
                >
                  <span
                    class="text-xl font-extrabold text-gray-300 w-6 shrink-0 leading-6"
                    >{{ idx + 1 }}</span
                  >
                  <div class="min-w-0">
                    <h4
                      class="text-sm font-semibold text-gray-800 line-clamp-2 group-hover:text-primary transition-colors"
                    >
                      {{ a.title }}
                    </h4>
                    <div
                      class="flex items-center gap-1 text-xs text-gray-500 mt-1"
                    >
                      <MessageSquareIcon class="h-3.5 w-3.5" />
                      {{ a.comments.length }}
                    </div>
                  </div>
                </NuxtLink>
              </div>
            </div>

            <!-- Trending Topics -->
            <div
              v-if="trendingTopics.length"
              class="rounded-xl border border-gray-200 bg-white p-4"
            >
              <h3
                class="flex items-center gap-2 text-base font-bold text-gray-900 mb-3"
              >
                    {{ $t("news_trending_topics") }}
              </h3>
              <div class="flex flex-wrap gap-2">
                <NuxtLink
                  v-for="(topic, index) in trendingTopics"
                  :key="index"
                  :to="`/adsy-news/categories/${topic.slug}/`"
                  class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-gray-200 bg-gray-50 text-gray-700 text-xs font-medium hover:border-gray-300 hover:text-primary transition-colors"
                >
                  <TrendingUpIcon class="h-3.5 w-3.5 text-primary" />
                  {{ topic.title }}
                </NuxtLink>
              </div>
            </div>

            <!-- Ad -->
            <SaleAdSlot variant="billboard" />
          </aside>
        </div>
      </section>

      <!-- ===== Tips and Suggestions ===== -->
      <section v-if="visibleTips.length" class="mb-8">
        <h2
          class="flex items-center gap-2 text-lg font-bold text-gray-900 mb-4"
        >
                    {{ $t("news_tips") }}
        </h2>
        <div class="grid gap-3 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
          <div
            v-for="(tip, index) in visibleTips"
            :key="index"
            class="rounded-xl border border-gray-200 bg-white p-4"
          >
            <h3 class="text-sm font-semibold mb-1 text-gray-900 line-clamp-2">
              {{ tip.title }}
            </h3>
            <p class="text-sm text-gray-600 line-clamp-3">
              {{ tip.description }}
            </p>
          </div>
        </div>
        <div
          v-if="visibleTips.length < tipsAndSuggestions.length"
          class="mt-4 text-center"
        >
          <button
            @click="loadMoreTips"
            class="px-6 py-2.5 rounded-lg border border-gray-200 bg-white text-gray-700 text-sm font-medium hover:bg-gray-50 transition-colors"
          >
            {{ $t("news_load_more") }}
          </button>
        </div>
      </section>

      <!-- Ad -->
      <div class="mb-8">
        <SaleAdSlot variant="leaderboard" />
      </div>

      <!-- ===== Newsletter ===== -->
      <section class="mb-2">
        <div class="rounded-xl bg-primary p-6 sm:p-8 text-white">
          <div
            class="flex flex-col md:flex-row items-center justify-between gap-5"
          >
            <div class="text-center md:text-left">
              <h2 class="text-lg sm:text-xl font-bold mb-1">
                {{ $t("news_stay_updated") }}
              </h2>
              <p class="text-white/85 text-sm max-w-md">
                {{ $t("news_newsletter_desc") }}
              </p>
            </div>
            <form
              @submit.prevent="subscribeNewsletter"
              class="w-full md:w-auto flex flex-col sm:flex-row gap-2"
            >
              <input
                type="email"
                v-model="newsletterEmail"
                :placeholder="$t('news_email_placeholder')"
                required
                class="px-4 py-2.5 rounded-lg text-gray-800 focus:outline-none focus:ring-2 focus:ring-white/60 w-full sm:w-64"
              />
              <button
                type="submit"
                class="px-6 py-2.5 bg-white text-primary font-semibold rounded-lg hover:bg-gray-100 transition-colors whitespace-nowrap"
              >
                {{ $t("news_subscribe") }}
              </button>
            </form>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "adsy-news",
});

const { get, post } = useApi();

import { ar } from "date-fns/locale";
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  MessageSquareIcon,
  ArrowRightIcon,
  LayoutGridIcon,
  LayoutListIcon,
  TrendingUpIcon,
  SearchIcon,
} from "lucide-vue-next";
import SaleAdSlot from "~/components/sale/SaleAdSlot.vue";

// Articles state
const articles = ref([]);
const forTrendingArticles = ref([]);
const totalPages = ref(0);
const isLoading = ref(false);
const hasMoreArticles = ref(false);
const currentPage = ref(1);
const allArticlesLoaded = ref(false);

// Layout options
const layouts = ref([
  { id: "grid", name: "Grid View" },
  { id: "list", name: "List View" },
]);
const currentLayout = ref("grid");

// Get articles from API
async function getArticles(page = 1, append = false) {
  try {
    isLoading.value = true;
    const res = await get(`/news/posts/?page=${page}`);

    if (res.data) {
      if (res.data.results) {
        // Handle paginated response
        if (page === 1) {
          forTrendingArticles.value = res.data.results;
        }
        if (append) {
          articles.value = [...articles.value, ...res.data.results];
        } else {
          articles.value = res.data.results;
        }

        // Check if there are more pages
        hasMoreArticles.value = !!res.data.next;
        // Update allArticlesLoaded state
        allArticlesLoaded.value = !hasMoreArticles.value;

        if (res.data.count) {
          totalPages.value = Math.ceil(res.data.count / 10); // Assuming 10 items per page
        }
      } else if (Array.isArray(res.data)) {
        // Handle non-paginated array response
        if (append) {
          articles.value = [...articles.value, ...res.data];
        } else {
          articles.value = res.data;
        }
        // If we get a direct array, assume all articles are loaded
        hasMoreArticles.value = false;
        allArticlesLoaded.value = true;
      }
    }
  } catch (error) {
    console.error("Error fetching articles:", error);
  } finally {
    isLoading.value = false;
  }
}

// Load initial articles
await getArticles();

// Load more articles
async function loadMoreArticles() {
  if (isLoading.value || !hasMoreArticles.value) return;

  currentPage.value++;
  await getArticles(currentPage.value, true);
}

// Newsletter subscription
const newsletterEmail = ref("");
const subscribeNewsletter = async () => {
  if (!newsletterEmail.value) return;

  try {
    // This would typically connect to your newsletter subscription API
    // await post("/newsletter/subscribe/", { email: newsletterEmail.value });
    alert(`Thank you for subscribing with ${newsletterEmail.value}!`);
    newsletterEmail.value = "";
  } catch (error) {
    console.error("Error subscribing to newsletter:", error);
  }
};

// Chat opening logic
const openChat = () => {
  alert("Chat option opened!"); // Replace with actual chat opening logic
};

// Trending News Carousel
const trendingIndex = ref(0);
const trendingPerPage = computed(() => {
  if (typeof window === "undefined") return 4; // Server-side rendering default

  if (window.innerWidth < 640) return 1;
  if (window.innerWidth < 768) return 2;
  if (window.innerWidth < 1024) return 3;
  return 4;
});

const nextTrending = () => {
  const maxIndex =
    Math.ceil(trendingArticles.value.length / trendingPerPage.value) - 1;
  trendingIndex.value =
    trendingIndex.value >= maxIndex ? 0 : trendingIndex.value + 1;
};

const prevTrending = () => {
  const maxIndex =
    Math.ceil(trendingArticles.value.length / trendingPerPage.value) - 1;
  trendingIndex.value =
    trendingIndex.value <= 0 ? maxIndex : trendingIndex.value - 1;
};

const carouselInterval = ref(null);
const isPaused = ref(false);

const startCarousel = () => {
  stopCarousel(); // Clear any existing interval
  carouselInterval.value = setInterval(() => {
    if (!isPaused.value) {
      nextTrending();
    }
  }, 4000);
};

const stopCarousel = () => {
  if (carouselInterval.value) {
    clearInterval(carouselInterval.value);
    carouselInterval.value = null;
  }
};

const pauseCarousel = () => {
  isPaused.value = true;
};

const resumeCarousel = () => {
  isPaused.value = false;
};

// Trending Topics (ideally these would come from an API based on popular tags)
const trendingTopics = ref([]);

async function getTrendingTopics() {
  try {
    // Get all tags from the API
    const res = await get("/news/categories/");
    if (res.data && Array.isArray(res.data.results)) {
      // Extract unique tags and take the first 7 (or fewer if there aren't 7)
      const uniqueTags = [
        ...new Set(
          res.data.results.map((category) => ({
            title: category.title,
            slug: category.slug,
          }))
        ),
      ];
      trendingTopics.value = uniqueTags.slice(0, 7);
    }
  } catch (error) {
    console.error("Error fetching trending topics:", error);
    // Fallback to default trending topics if API call fails
    trendingTopics.value = [
      "Climate Change",
      "Artificial Intelligence",
      "Global Economy",
      "Healthcare Innovation",
      "Technology",
      "Business",
      "Science",
    ];
  }
}

// Call trending topics function
getTrendingTopics();

// Tips and Suggestions data
const tipsAndSuggestions = ref([]);

async function getTipsAndSuggestions() {
  try {
    const res = await get("/news/tips-suggestions/");
    if (res.data) {
      tipsAndSuggestions.value = res.data.results;
    }
  } catch (error) {
    console.error("Error fetching tips and suggestions:", error);
  }
}
await getTipsAndSuggestions();
// State for visible tips and load more functionality
const visibleTips = ref([]);
const tipsPerPage = ref(6);

const loadMoreTips = () => {
  const nextItems = tipsAndSuggestions.value.slice(
    visibleTips.value.length,
    visibleTips.value.length + tipsPerPage.value
  );
  visibleTips.value = [...visibleTips.value, ...nextItems];
};

// Initialize visible tips
onMounted(() => {
  loadMoreTips();
});

// Helper functions for article display
const formatArticleForDisplay = (article) => {
  if (!article) return null;

  return {
    id: article.id || "",
    slug: article.slug || "",
    title: article.title || "Untitled Article",
    content: article.content || "",
    image: article.image
      ? article.image
      : "/static/frontend/images/placeholder.jpg",
    date: article.created_at
      ? new Date(article.created_at).toLocaleDateString("en-US", {
          year: "numeric",
          month: "long",
          day: "numeric",
        })
      : "Unknown date",
    readTime: article.content ? Math.ceil(article.content.length / 1000) : 1,
    author: article.author_details?.name || "Unknown Author",
    authorTitle: article.author_details?.profession || "",
    authorImage:
      article.author_details?.image ||
      "/static/frontend/images/placeholder.jpg",
    comments: article.post_comments || [],
    summary: article.content
      ? article.content.substring(0, 150) + "..."
      : "No content available",
    tags: article.tags || [],
  };
};

// Latest article (most recent by date)
const latestArticle = computed(() => {
  if (articles.value.length === 0) {
    return {
      id: "",
      title: "No articles available",
      content: "",
      image: "/static/frontend/images/placeholder.jpg",
      date: new Date().toLocaleDateString(),
      readTime: 1,
      author: "System",
      authorImage: "/static/frontend/images/placeholder.jpg",
      summary: "No articles available at this moment.",
      comments: [],
      tags: [],
    };
  }

  // Sort by created_at date and return the most recent as formatted display object
  const latest = [...articles.value].sort((a, b) => {
    return new Date(b.created_at) - new Date(a.created_at);
  })[0];

  return formatArticleForDisplay(latest);
});

// Top stories beside the lead (next most-recent after the latest)
const topStories = computed(() => {
  if (articles.value.length === 0) return [];
  return [...articles.value]
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    .slice(1, 5)
    .map((article) => formatArticleForDisplay(article));
});

// Filter articles based on active category and include all articles
const filteredArticles = computed(() => {
  if (articles.value.length === 0) return [];

  // Use all articles, don't exclude any
  return articles.value.map((article) => formatArticleForDisplay(article));
});

// Trending articles (based on comment count)
const trendingArticles = computed(() => {
  // Sort articles by comment count (or can be replaced with other engagement metrics if available)
  return [...forTrendingArticles.value]
    .sort((a, b) => {
      const aComments = a.post_comments ? a.post_comments.length : 0;
      const bComments = b.post_comments ? b.post_comments.length : 0;
      return bComments - aComments;
    })
    .slice(0, 8) // Take the top 8 articles
    .map((article) => formatArticleForDisplay(article));
});

// Most read (ranked by comment count) — powers the sidebar
const mostReadArticles = computed(() => {
  return [...forTrendingArticles.value]
    .sort((a, b) => {
      const aC = a.post_comments ? a.post_comments.length : 0;
      const bC = b.post_comments ? b.post_comments.length : 0;
      return bC - aC;
    })
    .slice(0, 5)
    .map((article) => formatArticleForDisplay(article));
});

// Category-wise news blocks (newspaper-style sections, real data per category)
const categorySections = ref([]);
async function getCategorySections() {
  try {
    const catRes = await get("/news/categories/");
    const cats = (catRes.data?.results || []).slice(0, 4);
    const sections = await Promise.all(
      cats.map(async (cat) => {
        try {
          const res = await get(`/news/categories/${cat.slug}/posts/?page=1`);
          const posts = (res.data?.results || [])
            .slice(0, 4)
            .map((a) => formatArticleForDisplay(a));
          return { id: cat.id, title: cat.title, slug: cat.slug, posts };
        } catch (e) {
          return { id: cat.id, title: cat.title, slug: cat.slug, posts: [] };
        }
      })
    );
    categorySections.value = sections.filter((s) => s.posts.length > 0);
  } catch (e) {
    console.error("Error fetching category sections:", e);
  }
}
getCategorySections();

// Helper functions
const getAuthorName = (authorDetails) => {
  if (!authorDetails) return "Anonymous";

  const firstName = authorDetails.first_name || "";
  const lastName = authorDetails.last_name || "";

  const fullName = `${firstName} ${lastName}`.trim();
  return fullName || "Anonymous";
};

// Initialize on mount
onMounted(() => {
  // Set up window resize listener for responsive carousel
  window.addEventListener("resize", () => {
    // Reset carousel index when screen size changes to avoid empty slides
    trendingIndex.value = 0;
  });

  startCarousel();
});

onUnmounted(() => {
  stopCarousel();
  window.removeEventListener("resize", () => {});
});
</script>

<style>
:root {
  --color-primary: #e53e3e;
  --color-primary-dark: #c53030;
}

.clamp-2 {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.bg-primary {
  background-color: var(--color-primary);
}

.text-primary {
  color: var(--color-primary);
}

.hover\:text-primary:hover {
  color: var(--color-primary);
}

.group:hover .group-hover\:text-primary {
  color: var(--color-primary);
}

.hover\:text-primary-dark:hover {
  color: var(--color-primary-dark);
}

.hover\:bg-primary-dark:hover {
  background-color: var(--color-primary-dark);
}

.focus\:ring-primary:focus {
  --tw-ring-color: var(--color-primary);
}

.focus\:border-primary:focus {
  border-color: var(--color-primary);
}

.border-primary {
  border-color: var(--color-primary);
}

/* Ticker animation */
.ticker-container {
  animation: ticker 20s linear infinite;
}

.ticker-item {
  margin-right: 50px;
}

@keyframes ticker {
  0% {
    transform: translateX(100%);
  }
  100% {
    transform: translateX(-100%);
  }
}

/* Transition effects */
.comment-list-enter-active,
.comment-list-leave-active {
  transition: all 0.5s ease;
}
.comment-list-enter-from,
.comment-list-leave-to {
  opacity: 0;
  transform: translateY(30px);
}

/* Line clamp for article summaries */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
