<template>
  <div class="min-h-screen bg-gray-50">
    <main class="max-w-7xl mx-auto px-2 sm:px-6 lg:px-8 pb-4">
      <div class="mb-12">
        <div
          class="relative rounded-xl overflow-hidden shadow-xl sm:h-[430px] h-[400px] group"
        >
          <img
            :src="latestArticle.image"
            :alt="latestArticle.title"
            class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
          />
          <div
            class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent"
          ></div>
          <div
            class="absolute bottom-0 left-0 right-0 p-2 sm:p-4 md:p-10 text-white"
          >
            <div class="flex items-center mb-4">
              <span
                class="bg-primary text-white text-xs font-semibold px-3 py-1 rounded-full"
                >LATEST NEWS</span
              >
              <span class="ml-3 text-sm opacity-80">{{
                latestArticle.date
              }}</span>
            </div>
            <h2
              class="text-base sm:text-base md:text-base  font-semibold mb-4 leading-tight"
            >
              <NuxtLink
                :to="`/adsy-news/${latestArticle.slug}/`"
                class="hover:text-primary transition-colors duration-200 line-clamp-2"
              >
                {{ latestArticle.title }}
              </NuxtLink>
            </h2>
            <div
              class="text-sm sm:text-base opacity-90 mb-6 max-w-3xl line-clamp-2"
              v-html="latestArticle.summary"
            ></div>
            <div class="flex items-center">
              <img
                :src="latestArticle.authorImage"
                :alt="latestArticle.author"
                class="h-10 w-10 rounded-full mr-3 border-2 border-white"
              />
              <div>
                <p class="font-medium">
                  Posted by:
                  <span class="text-primary">{{ latestArticle.author }}</span>
                </p>
                <p class="text-sm opacity-80">
                  {{ latestArticle.authorTitle }}
                </p>
              </div>
              <UButton
                :to="`/adsy-news/${latestArticle.slug}/`"
                class="ml-auto bg-white text-gray-700 hover:bg-gray-100 px-5 py-2 rounded-full font-medium transition-colors duration-200 flex items-center"
              >
                Read
                <ArrowRightIcon class="h-4 w-4 ml-2" />
              </UButton>
            </div>
          </div>
        </div>
      </div>

      <!-- Trending News Carousel -->
      <div class="mb-12">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-base font-semibold text-gray-700">Trending News</h2>
          <div class="flex space-x-2">
            <button
              @click="prevTrending"
              @mouseenter="pauseCarousel"
              class="p-2 rounded-full bg-gray-100 hover:bg-gray-200 transition-colors"
            >
              <ChevronLeftIcon class="h-5 w-5 text-gray-700" />
            </button>
            <button
              @click="nextTrending"
              @mouseenter="pauseCarousel"
              class="p-2 rounded-full bg-gray-100 hover:bg-gray-200 transition-colors"
            >
              <ChevronRightIcon class="h-5 w-5 text-gray-700" />
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
              class="flex-shrink-0 mb-2 w-full sm:w-1/2 md:w-1/3 lg:w-1/4 px-3"
            >
              <div
                class="bg-white rounded-lg shadow-md overflow-hidden h-full hover:shadow-lg transition-shadow duration-300"
              >
                <div class="relative h-40">
                  <img
                    :src="article.image"
                    :alt="article.title"
                    class="w-full h-full object-cover"
                  />
                  <div class="absolute top-0 left-0 m-2">
                    <span
                      v-for="tag in article.tags"
                      :key="tag"
                      class="bg-primary/90 text-white text-xs font-semibold px-2 py-1 rounded"
                    >
                      {{ tag }}
                    </span>
                  </div>
                </div>
                <div class="p-4">
                  <NuxtLink :to="`/adsy-news/${article.slug}/`">
                    <h3
                      class="text-lg font-semibold mb-2 text-gray-700 hover:text-primary cursor-pointer line-clamp-2"
                    >
                      {{ article.title }}
                    </h3>
                  </NuxtLink>
                  <div
                    class="flex justify-between items-center text-sm text-gray-500"
                  >
                    <span>{{ article.date }}</span>
                    <span class="flex items-center">
                      <MessageSquareIcon class="h-4 w-4 mr-1" />
                      {{ article.comments.length }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-center mt-6 space-x-2">
          <button
            v-for="(_, i) in Math.ceil(
              trendingArticles.length / trendingPerPage
            )"
            :key="i"
            @click="trendingIndex = i"
            :class="[
              'w-2 h-2 rounded-full transition-colors',
              trendingIndex === i
                ? 'bg-primary'
                : 'bg-gray-300 hover:bg-gray-400',
            ]"
          ></button>
        </div>
      </div>

      <!-- Category Title -->
      <div class="flex justify-between items-center mb-8">
        <h2 class="text-base font-semibold text-gray-700">All News</h2>
        <div class="flex space-x-2">
          <button
            v-for="layout in layouts"
            :key="layout.id"
            @click="currentLayout = layout.id"
            :class="[
              'p-2 rounded-md transition-colors',
              currentLayout === layout.id ? 'bg-gray-200' : 'hover:bg-gray-100',
            ]"
          >
            <LayoutGridIcon
              v-if="layout.id === 'grid'"
              class="h-5 w-5 text-gray-700"
            />
            <LayoutListIcon v-else class="h-5 w-5 text-gray-700" />
          </button>
        </div>
      </div>

      <!-- Articles Grid/List -->
      <div>
        <div
          :class="[
            currentLayout === 'grid'
              ? 'grid gap-2 sm:gap-4 grid-cols-2 md:grid-cols-4'
              : 'space-y-8',
          ]"
        >
          <article
            v-for="article in filteredArticles.slice(0, 12)"
            :key="article.id"
            :class="[
              'bg-white rounded-xl overflow-hidden shadow-md hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1',
              currentLayout === 'list' ? 'flex flex-col md:flex-row' : '',
            ]"
          >
            <div :class="[currentLayout === 'list' ? 'md:w-1/3' : '']">
              <div
                class="relative overflow-hidden"
                :class="[currentLayout === 'list' ? 'h-full' : 'h-48 sm:h-56']"
              >
                <img
                  :src="article.image"
                  :alt="article.title"
                  class="w-full h-full object-cover transition-transform duration-500 hover:scale-110"
                />
                <div class="absolute top-0 left-0 m-3">
                  <span
                    v-for="tag in article.tags"
                    :key="tag"
                    class="bg-primary/90 text-white text-xs font-semibold px-2 py-1 rounded"
                  >
                    {{ tag }}
                  </span>
                </div>
              </div>
            </div>
            <div :class="[currentLayout === 'list' ? 'md:w-2/3 p-2' : 'p-2']">
              <NuxtLink :to="`/adsy-news/${article.slug}/`">
                <h3
                  class="font-semibold mb-2 text-gray-700 hover:text-primary cursor-pointer transition-colors duration-200 line-clamp-2"
                >
                  {{ article.title }}
                </h3>
              </NuxtLink>
              <div
                class="text-gray-600 mb-3 line-clamp-3"
                v-html="article.content.substring(0, 150) + '...'"
              ></div>
              <div class="flex justify-between items-center">
                <div class="flex items-center">
                  <img
                    :src="
                      article.authorImage ||
                      '/static/frontend/images/placeholder.jpg'
                    "
                    :alt="article.author"
                    class="h-8 w-8 rounded-full mr-2"
                  />
                  <span class="text-sm font-medium text-gray-700"
                    >Posted by:
                    <span class="text-primary">{{ article.author }}</span></span
                  >
                </div>
                <div class="flex items-center text-gray-500">
                  <MessageSquareIcon class="h-4 w-4 mr-1" />
                  <span class="text-sm">{{
                    article.post_comments ? article.post_comments.length : 0
                  }}</span>
                </div>
              </div>
            </div>
          </article>
        </div>

        <!-- Load More Button -->
        <div v-if="filteredArticles.length > 12" class="mt-12 text-center">
          <button
            @click="loadMoreArticles"
            class="px-6 py-3 bg-gray-200 text-gray-800 rounded-full hover:bg-gray-300 transition-colors duration-200 font-medium"
            :disabled="isLoading"
          >
            <span v-if="isLoading">Loading...</span>
            <span v-else>Load More Articles</span>
          </button>
        </div>
        <!-- Trending Topics Section -->
        <div class="mt-10 bg-gray-100 rounded-xl p-3 sm:p-8">
          <h2 class="text-base font-semibold text-gray-700 mb-4">
            Trending Topics
          </h2>
          <div class="flex flex-wrap gap-y-3 gap-x-1 sm:gap-3">
            <a
              v-for="(topic, index) in trendingTopics"
              :key="index"
              href="#"
              class="px-2 sm:px-4 py-2 bg-white rounded-full text-gray-800 shadow-sm hover:shadow-md transition-shadow duration-200 text-xs sm:text-sm font-medium flex items-center"
            >
              <TrendingUpIcon class="h-4 w-4 mr-2 text-primary" />
              {{ topic }}
            </a>
          </div>
        </div>

        <!-- Tips and Suggestions Section -->
        <div class="mt-10 bg-gray-100 rounded-xl p-3 sm:p-8">
          <h2 class="text-base font-semibold text-gray-700 mb-6">
            Tips and Suggestions
          </h2>
          <div
            class="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6"
          >
            <div
              v-for="(tip, index) in visibleTips"
              :key="index"
              class="bg-white rounded-lg shadow-md p-4 hover:shadow-lg transition-shadow duration-300 flex flex-col"
            >
              <h3
                class="text-sm font-semibold mb-2 text-gray-700 hover:text-primary cursor-pointer line-clamp-2"
              >
                {{ tip.title }}
              </h3>
              <p class="text-sm text-gray-500 line-clamp-3">
                {{ tip.description }}
              </p>
            </div>
          </div>
          <div
            v-if="visibleTips.length < tipsAndSuggestions.length"
            class="mt-6 text-center"
          >
            <button
              @click="loadMoreTips"
              class="px-6 py-3 bg-gray-200 text-gray-800 rounded-full hover:bg-gray-300 transition-colors duration-200 font-medium"
            >
              Load More
            </button>
          </div>
        </div>
      </div>

      <!-- Newsletter Section -->
      <div class="mt-16">
        <div class="bg-primary rounded-xl p-8 sm:p-10 relative overflow-hidden">
          <div class="absolute top-0 right-0 w-1/3 h-full opacity-10">
            <svg
              viewBox="0 0 100 100"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <circle cx="75" cy="25" r="20" fill="white" />
              <circle cx="25" cy="75" r="20" fill="white" />
              <circle cx="75" cy="75" r="20" fill="white" />
              <circle cx="25" cy="25" r="20" fill="white" />
            </svg>
          </div>
          <div
            class="relative z-10 flex flex-col md:flex-row items-center justify-between"
          >
            <div class="mb-6 md:mb-0 md:mr-8">
              <h2 class="text-base sm:text-base font-semibold text-white mb-2">
                Stay Updated
              </h2>
              <p class="text-white/80 max-w-md">
                Subscribe to our newsletter to receive the latest news and
                exclusive content straight to your inbox.
              </p>
            </div>
            <div class="w-full md:w-auto">
              <form
                @submit.prevent="subscribeNewsletter"
                class="flex flex-col sm:flex-row gap-3"
              >
                <input
                  type="email"
                  v-model="newsletterEmail"
                  placeholder="Your email address"
                  required
                  class="px-4 py-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-white/50 w-full sm:w-64"
                />
                <button
                  type="submit"
                  class="px-6 py-3 bg-white text-primary font-medium rounded-lg hover:bg-gray-100 transition-colors"
                >
                  Subscribe
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
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

// Articles state
const articles = ref([]);
const totalPages = ref(0);
const isLoading = ref(false);
const hasMoreArticles = ref(true);
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
        ...new Set(res.data.results.map((category) => category.title)),
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
  console.log("Latest article:", articles.value);
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

// Filter articles based on active category and include all articles
const filteredArticles = computed(() => {
  if (articles.value.length === 0) return [];

  // Use all articles, don't exclude any
  return articles.value.map((article) => formatArticleForDisplay(article));
});

// Trending articles (based on comment count)
const trendingArticles = computed(() => {
  // Sort articles by comment count (or can be replaced with other engagement metrics if available)
  return [...articles.value]
    .sort((a, b) => {
      const aComments = a.post_comments ? a.post_comments.length : 0;
      const bComments = b.post_comments ? b.post_comments.length : 0;
      return bComments - aComments;
    })
    .slice(0, 8) // Take the top 8 articles
    .map((article) => formatArticleForDisplay(article));
});

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

.bg-primary {
  background-color: var(--color-primary);
}

.text-primary {
  color: var(--color-primary);
}

.hover\:text-primary:hover {
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
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Ensure fixed height for article cards */
article {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
}

article h3 {
  min-height: 3rem; /* Adjust based on expected title height */
}

article p {
  min-height: 4rem; /* Adjust based on expected description height */
}
</style>
