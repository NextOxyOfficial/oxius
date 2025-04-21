<template>
  <div class="min-h-screen bg-gray-50">
    <main class="max-w-7xl mx-auto px-2 sm:px-6 lg:px-8 pb-4">
      <div class="mb-12">
        <div
          class="relative rounded-xl overflow-hidden shadow-xl h-[500px] group"
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
            class="absolute bottom-0 left-0 right-0 p-6 sm:p-8 md:p-10 text-white"
          >
            <div class="flex items-center mb-4">
              <span
                class="bg-primary text-white text-xs font-bold px-3 py-1 rounded-full"
                >LATEST NEWS</span
              >
              <span class="ml-3 text-sm opacity-80">{{
                latestArticle.date
              }}</span>
              <span class="ml-3 text-sm opacity-80 flex items-center">
                <ClockIcon class="h-4 w-4 mr-1" />
                {{ latestArticle.readTime }} min read
              </span>
            </div>
            <h2
              class="text-2xl sm:text-3xl md:text-4xl font-bold mb-4 leading-tight"
            >
              <NuxtLink
                :to="`/adsy-news/${latestArticle.slug}/`"
                class="hover:text-primary transition-colors duration-200"
              >
                {{ latestArticle.title }}
              </NuxtLink>
            </h2>
            <p class="text-sm sm:text-base opacity-90 mb-6 max-w-3xl">
              {{ latestArticle.summary }}
            </p>
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
              <button
                @click="readArticle(latestArticle)"
                class="ml-auto bg-white text-gray-900 hover:bg-gray-100 px-5 py-2 rounded-full font-medium transition-colors duration-200 flex items-center"
              >
                Read
                <ArrowRightIcon class="h-4 w-4 ml-2" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Trending News Carousel -->
      <div class="mb-12">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold text-gray-900">Trending News</h2>
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
                      class="bg-primary/90 text-white text-xs font-bold px-2 py-1 rounded"
                    >
                      All News
                    </span>
                  </div>
                  <div class="absolute top-0 right-0 m-2">
                    <span
                      class="bg-black/70 text-white text-xs px-2 py-1 rounded-full flex items-center"
                    >
                      <TrendingUpIcon class="h-3 w-3 mr-1" />
                      Trending
                    </span>
                  </div>
                </div>
                <div class="p-4">
                  <NuxtLink :to="`/adsy-news/${article.slug}/`">
                    <h3
                      class="text-lg font-bold mb-2 text-gray-900 hover:text-primary cursor-pointer line-clamp-2"
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
      <div
        v-if="!selectedArticle"
        class="flex justify-between items-center mb-8"
      >
        <h2 class="text-2xl font-bold text-gray-900">All News</h2>
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
      <div v-if="!selectedArticle">
        <div
          :class="[
            currentLayout === 'grid'
              ? 'grid gap-8 md:grid-cols-2 lg:grid-cols-3'
              : 'space-y-8',
          ]"
        >
          <article
            v-for="article in filteredArticles"
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
                    class="bg-primary/90 text-white text-xs font-bold px-2 py-1 rounded"
                  >
                    All News
                  </span>
                </div>
              </div>
            </div>
            <div :class="[currentLayout === 'list' ? 'md:w-2/3 p-6' : 'p-6']">
              <div class="flex items-center text-sm text-gray-500 mb-2">
                <CalendarIcon class="h-4 w-4 mr-1" />
                <span>{{ article.date }}</span>
                <span class="mx-2">•</span>
                <ClockIcon class="h-4 w-4 mr-1" />
                <span>{{ article.readTime }} min read</span>
              </div>
              <NuxtLink :to="`/adsy-news/${article.slug}/`">
                <h3
                  class="text-xl font-bold mb-2 text-gray-900 hover:text-primary cursor-pointer transition-colors duration-200"
                >
                  {{ article.title }}
                </h3>
              </NuxtLink>
              <p class="text-gray-600 mb-4 line-clamp-2">
                {{ article.summary }}
              </p>
              <div class="flex justify-between items-center">
                <div class="flex items-center">
                  <img
                    :src="article.authorImage"
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
                  <span class="text-sm">{{ article.comments.length }}</span>
                </div>
              </div>
            </div>
          </article>
        </div>

        <!-- Load More Button -->
        <div class="mt-12 text-center">
          <button
            @click="loadMoreArticles"
            class="px-6 py-3 bg-gray-200 text-gray-800 rounded-full hover:bg-gray-300 transition-colors duration-200 font-medium"
          >
            Load More Articles
          </button>
        </div>
      </div>

      <!-- Article Detail View -->

      <!-- Trending Topics Section -->
      <div class="mt-16 bg-gray-100 rounded-xl p-3 sm:p-8">
        <h2 class="text-2xl font-bold text-gray-900 mb-6">Trending Topics</h2>
        <div class="flex flex-wrap gap-y-3 gap-x-1 sm:gap-3">
          <a
            v-for="(topic, index) in trendingTopics"
            :key="index"
            href="#"
            class="px-1 sm:px-4 py-2 bg-white rounded-full text-gray-800 shadow-sm hover:shadow-md transition-shadow duration-200 text-xs sm:text-sm font-medium flex items-center"
          >
            <TrendingUpIcon class="h-4 w-4 mr-2 text-primary" />
            {{ topic }}
          </a>
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
              <h2 class="text-2xl sm:text-3xl font-bold text-white mb-2">
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

const { get } = useApi();

import {
  ChevronLeftIcon,
  ChevronRightIcon,
  CalendarIcon,
  ClockIcon,
  MessageSquareIcon,
  ArrowRightIcon,
  LayoutGridIcon,
  LayoutListIcon,
  TrendingUpIcon,
} from "lucide-vue-next";

// Navigation state
const mobileMenuOpen = ref(false);
const articles = ref([]);

async function getArticles() {
  try {
    const res = await get("/news/posts/");
    console.log("API response:", res.data); // Debug log to see what we're getting
    if (res.data && res.data.results) {
      articles.value = res.data.results;
      console.log("Articles loaded:", articles.value.length);
    } else if (res.data) {
      // If the API doesn't return a paginated response with 'results'
      articles.value = Array.isArray(res.data) ? res.data : [res.data];
      console.log(
        "Alternative format - Articles loaded:",
        articles.value.length
      );
    }
  } catch (error) {
    console.error("Error fetching articles:", error);
  }
}
await getArticles();

// Search state
const searchQuery = ref("");
const searchResults = ref([]);

// Perform search when query changes
const performSearch = () => {
  // Always show results as user types, even with just 1 character
  if (!searchQuery.value) {
    searchResults.value = [];
    return;
  }

  // Filter articles based on search query
  const query = searchQuery.value.toLowerCase();

  searchResults.value = articles.value.filter((article) => {
    return article.title.toLowerCase().includes(query);
  });
};

// Clear search
const clearSearch = () => {
  searchQuery.value = "";
  searchResults.value = [];
};

// Newsletter
const newsletterEmail = ref("");
const subscribeNewsletter = () => {
  // Simulate subscription
  alert(`Thank you for subscribing with ${newsletterEmail.value}!`);
  newsletterEmail.value = "";
};

// Categories
const categories = ref([
  { id: "all", name: "All News" },
  { id: "world", name: "World" },
  { id: "politics", name: "Politics" },
  { id: "business", name: "Business" },
  { id: "technology", name: "Technology" },
  { id: "science", name: "Science" },
  { id: "health", name: "Health" },
  { id: "sports", name: "Sports" },
  { id: "entertainment", name: "Entertainment" },
]);

const activeCategory = ref("all");
const setActiveCategory = (categoryId) => {
  activeCategory.value = categoryId;
  selectedArticle.value = null;
  mobileMenuOpen.value = false;
};

const getCategoryName = (categoryId) => {
  const category = categories.value.find((c) => c.id === categoryId);
  return category ? category.name : "Uncategorized";
};

// Layout options
const layouts = ref([
  { id: "grid", name: "Grid View" },
  { id: "list", name: "List View" },
]);
const currentLayout = ref("grid");

// Breaking news ticker
const breakingNews = ref([
  "Global Summit on Climate Change Reaches Historic Agreement",
  "New Technology Breakthrough Could Revolutionize Renewable Energy",
  "Major Economic Reform Bill Passes in Senate",
  "Scientists Discover Potential Cure for Rare Disease",
]);
const currentTickerIndex = ref(0);

const startTicker = () => {
  setInterval(() => {
    currentTickerIndex.value =
      (currentTickerIndex.value + 1) % breakingNews.value.length;
  }, 5000);
};

// Current date
const currentDate = computed(() => {
  return new Date().toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
});

// Weather data (simulated)
const weather = reactive({
  temp: 24,
  condition: "Partly Cloudy",
  icon: "cloud",
});

// Format article for display
const formatArticleForDisplay = (article) => {
  if (!article) return null;

  return {
    id: article.id || "",
    slug: article.slug || "",
    title: article.title || "Untitled Article",
    content: article.content || "",
    image:
      article.post_media &&
      article.post_media.length > 0 &&
      article.post_media[0].image
        ? article.post_media[0].image
        : "/static/frontend/images/placeholder.jpg",
    date: article.created_at
      ? new Date(article.created_at).toLocaleDateString("en-US", {
          year: "numeric",
          month: "long",
          day: "numeric",
        })
      : "Unknown date",
    readTime: article.content ? Math.ceil(article.content.length / 1000) : 1,
    author: article.author_details
      ? `${article.author_details.first_name || ""} ${
          article.author_details.last_name || ""
        }`.trim() || article.author_details.username
      : "Anonymous",
    authorTitle: article.author_details?.user_type || "",
    authorImage:
      article.author_details?.image ||
      "/static/frontend/images/placeholder.jpg",
    comments: article.post_comments || [],
    summary: article.content
      ? article.content.substring(0, 150) + "..."
      : "No content available",
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
      categoryId: "all",
    };
  }

  // Sort by created_at date and return the most recent as formatted display object
  const latest = [...articles.value].sort((a, b) => {
    return new Date(b.created_at) - new Date(a.created_at);
  })[0];

  return formatArticleForDisplay(latest);
});

// Filter articles based on active category and exclude latest article
const filteredArticles = computed(() => {
  if (articles.value.length === 0) return [];

  // Get the latest article to exclude it
  const latest = latestArticle.value;

  // Filter and format remaining articles - only exclude the latest
  let filtered = articles.value
    .filter((article) => latest && article.id !== latest.id)
    .map((article) => formatArticleForDisplay(article));

  return filtered;
});

// Trending articles (based on engagement)
const trendingArticles = computed(() => {
  // For now, just use all articles and format them
  return articles.value.map((article) => formatArticleForDisplay(article));
});

const trendingIndex = ref(0);
const trendingPerPage = computed(() => {
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

// Trending Topics
const trendingTopics = ref([
  "Climate Change",
  "Artificial Intelligence",
  "Global Economy",
  "Space Exploration",
  "Renewable Energy",
  "Healthcare Innovation",
  "Cybersecurity",
]);

// Related articles (for article detail view)
const relatedArticles = computed(() => {
  if (!selectedArticle.value) return [];

  return articles.value
    .filter(
      (article) =>
        article.id !== selectedArticle.value.id &&
        article.categoryId === selectedArticle.value.categoryId
    )
    .slice(0, 3);
});

// Article view state
const selectedArticle = ref(null);

const selectArticle = (article) => {
  selectedArticle.value = article;
  window.scrollTo(0, 0);
  // Clear search when selecting an article
  searchQuery.value = "";
  searchResults.value = [];
};

const readArticle = (article) => {
  selectArticle(article);
};

// Load more articles (simulated)
const loadMoreArticles = () => {
  // In a real app, this would fetch more articles from an API
  alert(
    "In a real application, this would load more articles from the server."
  );
};

// New comment form data
const newComment = reactive({
  text: "",
});

// Function to add a new comment
const addComment = () => {
  if (newComment.text) {
    selectedArticle.value.comments.unshift({
      name: "Guest User",
      text: newComment.text,
      date: new Date().toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      }),
      userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
    });

    // Reset form
    newComment.text = "";
  }
};

// Initialize on mount
onMounted(() => {
  // Start breaking news ticker
  startTicker();

  // Set up window resize listener for responsive carousel
  window.addEventListener("resize", () => {
    // Reset carousel index when screen size changes to avoid empty slides
    trendingIndex.value = 0;
  });

  startCarousel();
});

onUnmounted(() => {
  stopCarousel();
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
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
