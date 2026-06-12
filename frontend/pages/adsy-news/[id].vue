<template>
  <div class="min-h-screen bg-gray-50/60">
    <UContainer class="py-5">
      <!-- Back link -->
      <NuxtLink
        to="/adsy-news/"
        class="mb-4 inline-flex items-center text-sm font-medium text-gray-600 hover:text-primary transition-colors"
      >
        <ArrowLeftIcon class="h-4 w-4 mr-1" />
        {{ $t("news_back") }}
      </NuxtLink>

      <div v-if="article" class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main article column -->
        <article class="lg:col-span-2 min-w-0">
          <!-- Hero -->
          <div
            class="relative rounded-xl overflow-hidden border border-gray-200 bg-black h-[260px] sm:h-[380px]"
          >
            <img
              :src="
                article.image
                  ? article.image
                  : '/static/frontend/images/placeholder.jpg'
              "
              :alt="article.title"
              class="w-full h-full object-cover opacity-95"
            />
            <div
              class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent"
            ></div>
            <div class="absolute bottom-0 left-0 right-0 p-4 sm:p-6 text-white">
              <div class="flex flex-wrap items-center gap-3 mb-2">
                <span
                  class="bg-primary text-white text-[11px] font-bold px-2.5 py-1 rounded uppercase tracking-wide"
                >
                  {{
                    article.categories && article.categories.length
                      ? article.categories[0].title
                      : $t("adsy_news")
                  }}
                </span>
                <span class="text-xs text-white/80">{{
                  formatDate(article.created_at)
                }}</span>
                <span class="text-xs text-white/80 flex items-center gap-1">
                  <ClockIcon class="h-3.5 w-3.5" />
                  {{ calculateReadTime(article.content) }}
                  {{ $t("news_min_read") }}
                </span>
              </div>
              <h1 class="text-lg sm:text-2xl font-bold leading-snug">
                {{ article.title }}
              </h1>
            </div>
          </div>

          <!-- Body card -->
          <div
            class="mt-4 bg-white rounded-xl border border-gray-200 p-4 sm:p-6"
          >
            <!-- Author + share -->
            <div
              class="flex items-center justify-between gap-3 pb-4 mb-5 border-b border-gray-100"
            >
              <div class="flex items-center gap-3 min-w-0">
                <img
                  :src="
                    article.author_details?.image ||
                    '/static/frontend/images/placeholder.jpg'
                  "
                  :alt="getAuthorName(article.author_details)"
                  class="h-11 w-11 rounded-full object-cover border border-gray-200"
                />
                <div class="min-w-0">
                  <p class="text-sm font-semibold text-gray-900 truncate">
                    {{ getAuthorName(article.author_details) }}
                  </p>
                  <p class="text-xs text-gray-500 capitalize">
                    {{
                      article.author_details?.profession ||
                      $t("news_contributor")
                    }}
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-2 shrink-0">
                <button
                  class="h-9 w-9 rounded-full bg-[#1DA1F2] text-white flex items-center justify-center hover:opacity-90 transition-opacity"
                  @click="shareArticle('twitter')"
                >
                  <TwitterIcon class="h-4 w-4" />
                </button>
                <button
                  class="h-9 w-9 rounded-full bg-[#1877F2] text-white flex items-center justify-center hover:opacity-90 transition-opacity"
                  @click="shareArticle('facebook')"
                >
                  <FacebookIcon class="h-4 w-4" />
                </button>
                <button
                  class="h-9 w-9 rounded-full bg-emerald-600 text-white flex items-center justify-center hover:opacity-90 transition-opacity"
                  @click="shareArticle('copy')"
                >
                  <LinkIcon class="h-4 w-4" />
                </button>
              </div>
            </div>

            <!-- Ad (after intro) -->
            <div class="mb-6">
              <SaleAdSlot variant="leaderboard" />
            </div>

            <!-- Content -->
            <div class="prose max-w-none" v-html="article.content"></div>

            <!-- Tags -->
            <div
              v-if="article.post_tags && article.post_tags.length > 0"
              class="flex flex-wrap gap-2 mt-6 pt-5 border-t border-gray-100"
            >
              <span
                v-for="(tag, index) in article.post_tags"
                :key="index"
                class="px-3 py-1 rounded-full bg-gray-50 border border-gray-200 text-gray-700 text-xs font-medium hover:border-gray-300 transition-colors"
              >
                #{{ tag.tag }}
              </span>
            </div>

            <!-- Ad (after content) -->
            <div class="mt-6">
              <SaleAdSlot variant="billboard" />
            </div>
          </div>

          <!-- Comments -->
          <div
            class="mt-4 bg-white rounded-xl border border-gray-200 p-4 sm:p-6"
          >
            <h2
              class="flex items-center gap-2 text-lg font-bold text-gray-900 mb-4"
            >
                            {{ $t("news_comments") }} ({{
                article.post_comments ? article.post_comments.length : 0
              }})
            </h2>

            <form @submit.prevent="addComment" class="mb-6">
              <textarea
                v-model="newComment.content"
                rows="3"
                :placeholder="$t('news_comment_placeholder')"
                required
                class="w-full px-4 py-2.5 border border-gray-200 rounded-lg focus:ring-1 focus:ring-primary focus:border-primary bg-white text-gray-800 text-sm"
              ></textarea>
              <div class="mt-3 flex justify-end">
                <button
                  type="submit"
                  :disabled="isSubmittingComment"
                  class="px-5 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors text-sm font-semibold disabled:opacity-60"
                >
                  <span v-if="isSubmittingComment">{{
                    $t("news_posting")
                  }}</span>
                  <span v-else>{{ $t("news_post_comment") }}</span>
                </button>
              </div>
            </form>

            <div class="space-y-4">
              <transition-group name="comment-list">
                <div
                  v-for="comment in article.post_comments"
                  :key="comment.id"
                  class="bg-gray-50 p-4 rounded-lg border border-gray-100"
                >
                  <div class="flex justify-between mb-1.5">
                    <h3 class="text-sm font-semibold text-gray-900">
                      {{
                        comment.author_details
                          ? getAuthorName(comment.author_details)
                          : "Anonymous"
                      }}
                    </h3>
                    <span class="text-xs text-gray-500">{{
                      formatDate(comment.created_at)
                    }}</span>
                  </div>
                  <p class="text-sm text-gray-700">{{ comment.content }}</p>
                </div>
              </transition-group>
              <div
                v-if="
                  !article.post_comments || article.post_comments.length === 0
                "
                class="text-center py-6 text-sm text-gray-500"
              >
                {{ $t("news_no_comments") }}
              </div>
            </div>
          </div>

          <!-- Related Articles -->
          <div v-if="relatedArticles.length > 0" class="mt-6">
            <h2
              class="flex items-center gap-2 text-lg font-bold text-gray-900 mb-4"
            >
                            {{ $t("news_related") }}
            </h2>
            <div class="grid gap-3 sm:gap-4 grid-cols-2 lg:grid-cols-3">
              <NuxtLink
                v-for="relatedArticle in relatedArticles.slice(0, 3)"
                :key="relatedArticle.id"
                :to="`/adsy-news/${relatedArticle.slug}/`"
                class="group block rounded-xl border border-gray-200 bg-white overflow-hidden hover:border-gray-300 transition-colors"
              >
                <div class="relative h-36 overflow-hidden">
                  <img
                    :src="
                      relatedArticle.image
                        ? relatedArticle.image
                        : '/static/frontend/images/placeholder.jpg'
                    "
                    :alt="relatedArticle.title"
                    class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                </div>
                <div class="p-3">
                  <h3
                    class="text-sm font-semibold text-gray-800 line-clamp-2 group-hover:text-primary transition-colors"
                  >
                    {{ relatedArticle.title }}
                  </h3>
                  <div
                    class="flex justify-between items-center text-xs text-gray-500 mt-2"
                  >
                    <span>{{ formatDate(relatedArticle.created_at) }}</span>
                    <span class="flex items-center gap-1">
                      <MessageSquareIcon class="h-3.5 w-3.5" />
                      {{
                        relatedArticle.post_comments
                          ? relatedArticle.post_comments.length
                          : 0
                      }}
                    </span>
                  </div>
                </div>
              </NuxtLink>
            </div>
          </div>
        </article>

        <!-- Sidebar -->
        <aside
          class="lg:col-span-1 space-y-5 lg:sticky lg:top-20 lg:self-start"
        >
          <!-- Ad -->
          <SaleAdSlot variant="billboard" />

          <!-- Tips -->
          <div
            v-if="visibleTips.length"
            class="rounded-xl border border-gray-200 bg-white p-4"
          >
            <h3
              class="flex items-center gap-2 text-base font-bold text-gray-900 mb-3"
            >
                            {{ $t("news_tips") }}
            </h3>
            <div class="divide-y divide-gray-100">
              <div
                v-for="(tip, index) in visibleTips.slice(0, 6)"
                :key="index"
                class="py-2.5 first:pt-0 last:pb-0"
              >
                <h4 class="text-sm font-semibold text-gray-800 line-clamp-2">
                  {{ tip.title }}
                </h4>
                <p class="text-xs text-gray-500 line-clamp-2 mt-0.5">
                  {{ tip.description }}
                </p>
              </div>
            </div>
          </div>

          <!-- Ad -->
          <SaleAdSlot variant="billboard" />
        </aside>
      </div>

      <!-- Loading state -->
      <div v-else class="py-12">
        <div class="animate-pulse space-y-6 max-w-3xl mx-auto">
          <div class="h-64 bg-gray-200 rounded-xl"></div>
          <div class="h-7 bg-gray-200 rounded-full w-3/4"></div>
          <div class="space-y-3">
            <div class="h-4 bg-gray-200 rounded-full"></div>
            <div class="h-4 bg-gray-200 rounded-full w-5/6"></div>
            <div class="h-4 bg-gray-200 rounded-full w-4/6"></div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "adsy-news",
});

const { get, post } = useApi();
const route = useRoute();
const toast = useToast();
const { user } = useAuth();

const article = ref(null);
const relatedArticles = ref([]);
const isSubmittingComment = ref(false);

// New comment form data
const newComment = ref({
  content: "",
});

async function getArticle() {
  try {
    // Use the slug parameter from the route
    const res = await get(`/news/posts/${route.params.id}/`);
    if (res && res.data) {
      article.value = res.data;
      // After getting the article, fetch related articles

      await getRelatedArticles();
    }
  } catch (error) {
    console.error("Error fetching article:", error);
  }
}

async function getRelatedArticles() {
  try {
    if (
      !article.value ||
      !article.value.post_tags ||
      article.value.post_tags.length === 0
    ) {
      // If no tags, just get the latest articles
      const res = await get("/news/posts/?limit=3");
      if (res.data && res.data.results) {
        // Filter out the current article
        relatedArticles.value = res.data.results
          .filter((a) => a.id !== article.value.id)
          .slice(0, 3);
      }
      return;
    }

    // Get articles with similar tags
    const tags = article.value.post_tags.map((tag) => tag.tag).join(",");
    // Here we would ideally have an endpoint that returns related articles by tag
    // But for now, we'll just get all articles and filter on the client side
    const res = await get(`/news/posts/?limit=10`);

    if (res.data && res.data.results) {
      // Filter out the current article
      const filtered = res.data.results.filter(
        (a) => a.id !== article.value.id
      );

      // Sort by relevance (number of matching tags)
      const withRelevance = filtered.map((a) => {
        const articleTags = a.post_tags ? a.post_tags.map((t) => t.tag) : [];
        const matchingTags = article.value.post_tags.filter((t) =>
          articleTags.includes(t.tag)
        ).length;

        return {
          ...a,
          relevance: matchingTags,
        };
      });

      // Sort by relevance (higher first) and take top 3
      relatedArticles.value = withRelevance
        .sort((a, b) => b.relevance - a.relevance)
        .slice(0, 3);
    }
  } catch (error) {
    console.error("Error fetching related articles:", error);
  }
}

async function addComment() {
  if (!user.value) {
    toast.add({
      description: "You must be logged in to comment.",
      color: "red",
    });
    return;
  }

  if (!newComment.value.content.trim()) return;

  isSubmittingComment.value = true;

  try {
    const response = await post(`/news/posts/${article.value.id}/comments/`, {
      post: article.value.id,
      content: newComment.value.content,
    });

    if (response && response.data) {
      // Add the new comment to the article's comments
      if (!article.value.post_comments) {
        article.value.post_comments = [];
      }

      // Add author details from the returned comment
      article.value.post_comments.unshift(response.data);

      // Clear the comment form
      newComment.value.content = "";

      toast.add({
        description: "Comment posted!",
        color: "green",
      });
    }
  } catch (error) {
    console.error("Error posting comment:", error);
    toast.add({
      title: "Failed to post comment. Please try again.",
      color: "red",
    });
  } finally {
    isSubmittingComment.value = false;
  }
}

// Share functionality
function shareArticle(platform) {
  const url = window.location.href;
  const title = article.value ? article.value.title : "Interesting article";

  switch (platform) {
    case "twitter":
      window.open(
        `https://twitter.com/intent/tweet?url=${encodeURIComponent(
          url
        )}&text=${encodeURIComponent(title)}`,
        "_blank"
      );
      break;
    case "facebook":
      window.open(
        `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
          url
        )}`,
        "_blank"
      );
      break;
    case "copy":
      navigator.clipboard
        .writeText(url)
        .then(() => {
          toast.add({
            title: "Link copied to clipboard!",
            color: "green",
          });
        })
        .catch((err) => {
          console.error("Failed to copy: ", err);
          toast.add({
            title: "Failed to copy link",
            color: "red",
          });
        });
      break;
  }
}

// Load the article data
await getArticle();

// Helper functions
function formatDate(dateString) {
  if (!dateString) return "";
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

function calculateReadTime(content) {
  if (!content) return 1;
  // Estimate read time based on content length (average reading speed: 200 words per minute)
  // Assuming 5 characters per word on average
  return Math.max(1, Math.ceil(content.length / (5 * 200)));
}

function getAuthorName(authorDetails) {
  if (!authorDetails) return "Anonymous";

  const firstName = authorDetails.first_name || "";
  const lastName = authorDetails.last_name || "";

  const fullName = `${firstName} ${lastName}`.trim();
  return fullName || "Anonymous";
}

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

import {
  ArrowLeftIcon,
  CalendarIcon,
  ClockIcon,
  TwitterIcon,
  FacebookIcon,
  LinkIcon,
  MessageSquareIcon,
  SearchIcon,
} from "lucide-vue-next";
import SaleAdSlot from "~/components/sale/SaleAdSlot.vue";
</script>

<style scoped>
.prose {
  max-width: 100% !important;
  color: #374151;
}

.prose h1,
.prose h2,
.prose h3,
.prose h4,
.prose h5,
.prose h6 {
  color: #111827;
  font-weight: 600;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
}

.prose p {
  margin-bottom: 1.25em;
  line-height: 1.7;
}

.prose img {
  border-radius: 0.5rem;
  margin: 1.5rem 0;
}

.prose a {
  color: var(--color-primary);
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 2px;
}

.prose a:hover {
  text-decoration-thickness: 2px;
}

.prose blockquote {
  border-left-width: 4px;
  border-left-color: var(--color-primary);
  padding-left: 1rem;
  font-style: italic;
  color: #6b7280;
}

.prose ul,
.prose ol {
  padding-left: 1.5rem;
}

.prose li {
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Comment animation */
.comment-list-enter-active,
.comment-list-leave-active {
  transition: all 0.5s ease;
}

.comment-list-enter-from,
.comment-list-leave-to {
  opacity: 0;
  transform: translateY(30px);
}
</style>
