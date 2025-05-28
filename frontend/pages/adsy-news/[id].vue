<template>
  <UContainer>
    <NuxtLink
      to="/adsy-news/"
      class="mb-6 flex items-center text-gray-800 hover:text-primary transition-colors"
    >
      <ArrowLeftIcon class="h-5 w-5 mr-1" />
      Back to all news
    </NuxtLink>

    <article
      v-if="article"
      class="bg-white rounded-xl shadow-sm overflow-hidden"
    >
      <div class="relative h-[350px]">
        <img
          :src="
            article.image
              ? article.image
              : '/static/frontend/images/placeholder.jpg'
          "
          :alt="article.title"
          class="w-full h-full object-cover"
        />
        <div
          class="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"
        ></div>
        <div class="absolute bottom-0 left-0 right-0 p-2 sm:p-6 text-white">
          <div class="flex items-center mb-4">
            <span
              class="bg-primary text-white text-xs font-semibold px-3 py-1 rounded-full"
            >
              All News
            </span>
            <span class="ml-3 text-sm opacity-80">{{
              formatDate(article.created_at)
            }}</span>
            <span class="ml-3 text-sm opacity-80 flex items-center">
              <ClockIcon class="h-4 w-4 mr-1" />
              {{ calculateReadTime(article.content) }} min read
            </span>
          </div>
          <h1 class="text-xl sm:text-2xl font-semibold mb-4 leading-tight">
            {{ article.title }}
          </h1>
        </div>
      </div>

      <div class="p-2 sm:p-6">
        <div class="flex mb-8 border-b border-gray-200 w-full pb-2">
          <img
            :src="
              article.author_details?.image ||
              '/static/frontend/images/placeholder.jpg'
            "
            :alt="getAuthorName(article.author_details)"
            class="h-12 w-12 rounded-full mr-4 border-2 border-primary"
          />
          <div class="w-full">
            <div class="flex items-center justify-between">
              <span class="font-medium text-gray-800">
                Posted by:
                <span class="text-primary">{{
                  getAuthorName(article.author_details)
                }}</span>
              </span>
              <div class="items-center flex space-x-3">
                <button
                  class="p-2 bg-blue-500 text-white rounded-full hover:bg-blue-600 transition-colors"
                  @click="shareArticle('twitter')"
                >
                  <TwitterIcon class="h-4 w-4" />
                </button>
                <button
                  class="p-2 bg-blue-700 text-white rounded-full hover:bg-blue-800 transition-colors"
                  @click="shareArticle('facebook')"
                >
                  <FacebookIcon class="h-4 w-4" />
                </button>
                <button
                  class="p-2 bg-green-600 text-white rounded-full hover:bg-green-700 transition-colors"
                  @click="shareArticle('copy')"
                >
                  <LinkIcon class="h-4 w-4" />
                </button>
              </div>
            </div>
            <span class="text-sm text-gray-600 capitalize">
              {{ article.author_details?.profession || "Contributor" }}
            </span>
          </div>
        </div>

        <div class="prose max-w-none mb-10" v-html="article.content"></div>

        <div
          v-if="article.post_tags && article.post_tags.length > 0"
          class="flex flex-wrap gap-2 mb-10"
        >
          <span
            v-for="(tag, index) in article.post_tags"
            :key="index"
            class="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer transition-colors"
          >
            #{{ tag.tag }}
          </span>
        </div>

        <!-- Comments Section -->
        <div class="border-t border-gray-200 pt-8">
          <h2 class="text-xl font-semibold mb-6 text-gray-800">
            Comments ({{
              article.post_comments ? article.post_comments.length : 0
            }})
          </h2>

          <form @submit.prevent="addComment" class="mb-8">
            <div class="space-y-4">
              <div class="flex-1">
                <textarea
                  v-model="newComment.content"
                  rows="3"
                  placeholder="Write a comment..."
                  required
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary bg-white text-gray-800"
                ></textarea>
                <div class="mt-3 flex justify-end">
                  <button
                    type="submit"
                    class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-colors"
                    :disabled="isSubmittingComment"
                  >
                    <span v-if="isSubmittingComment">Posting...</span>
                    <span v-else>Post Comment</span>
                  </button>
                </div>
              </div>
            </div>
          </form>

          <div class="space-y-6">
            <transition-group name="comment-list">
              <div
                v-for="comment in article.post_comments"
                :key="comment.id"
                class="bg-gray-50 p-4 rounded-lg border border-gray-200"
              >
                <div class="flex items-start space-x-4">
                  <div class="flex-1">
                    <div class="flex justify-between mb-2">
                      <h3 class="font-semibold text-gray-800">
                        {{
                          comment.author_details
                            ? getAuthorName(comment.author_details)
                            : "Anonymous"
                        }}
                      </h3>
                      <span class="text-sm text-gray-600">{{
                        formatDate(comment.created_at)
                      }}</span>
                    </div>
                    <p class="text-gray-800">{{ comment.content }}</p>
                  </div>
                </div>
              </div>
            </transition-group>
            <div
              v-if="
                !article.post_comments || article.post_comments.length === 0
              "
              class="text-center py-8 text-gray-600"
            >
              No comments yet. Be the first to comment!
            </div>
          </div>
        </div>

        <!-- Related Articles -->
        <div
          v-if="relatedArticles.length > 0"
          class="mt-12 border-t border-gray-200 pt-8"
        >
          <h2 class="text-xl font-semibold mb-6 text-gray-800">
            Related Articles
          </h2>
          <div class="grid gap-2 sm:gap-4 grid-cols-2 lg:grid-cols-4">
            <div
              v-for="relatedArticle in relatedArticles.slice(0, 4)"
              :key="relatedArticle.id"
              class="bg-gray-50 rounded-lg overflow-hidden shadow-sm hover:shadow-sm transition-all duration-300"
            >
              <div class="relative h-40 overflow-hidden">
                <img
                  :src="
                    relatedArticle.image
                      ? relatedArticle.image
                      : '/static/frontend/images/placeholder.jpg'
                  "
                  :alt="relatedArticle.title"
                  class="w-full h-full object-cover transition-transform duration-500 hover:scale-110"
                />
              </div>
              <div class="p-4">
                <NuxtLink :to="`/adsy-news/${relatedArticle.slug}/`">
                  <h3
                    class="font-semibold text-lg mb-2 hover:text-primary transition-colors line-clamp-2"
                  >
                    {{ relatedArticle.title }}
                  </h3>
                </NuxtLink>
                <div
                  v-html="relatedArticle.content.substring(0, 100) + `...`"
                  class="text-sm text-gray-600 mb-4 line-clamp-2"
                ></div>

                <div class="flex justify-between text-sm">
                  <span class="text-gray-600">{{
                    formatDate(relatedArticle.created_at)
                  }}</span>
                  <span class="text-gray-600 flex items-center">
                    <MessageSquareIcon class="h-3 w-3 mr-1" />
                    {{
                      relatedArticle.post_comments
                        ? relatedArticle.post_comments.length
                        : 0
                    }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tips and Suggestions Section -->
        <div class="mt-12 bg-gray-100 rounded-xl p-3 sm:p-8">
          <h2 class="text-xl font-semibold text-gray-800 mb-6">
            Tips and Suggestions
          </h2>
          <div
            class="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6"
          >
            <div
              v-for="(tip, index) in visibleTips"
              :key="index"
              class="bg-white rounded-lg shadow-sm p-4 hover:shadow-sm transition-shadow duration-300 flex flex-col"
            >
              <h3
                class="text-sm font-semibold mb-2 text-gray-800 hover:text-primary cursor-pointer line-clamp-2"
              >
                {{ tip.title }}
              </h3>
              <p class="text-sm text-gray-600 line-clamp-3">
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
    </article>

    <!-- Loading state -->
    <div v-else class="py-12 text-center">
      <div class="animate-pulse space-y-8">
        <div class="h-64 bg-gray-200 rounded-xl"></div>
        <div class="h-8 bg-gray-200 rounded-full w-3/4 mx-auto"></div>
        <div class="space-y-3">
          <div class="h-4 bg-gray-200 rounded-full"></div>
          <div class="h-4 bg-gray-200 rounded-full w-5/6"></div>
          <div class="h-4 bg-gray-200 rounded-full w-4/6"></div>
        </div>
      </div>
    </div>
  </UContainer>
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
      console.log(article.value);
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
