<template>
  <UContainer>
    <NuxtLink
      to="/adsy-news/"
      class="mb-6 flex items-center text-gray-700 hover:text-primary transition-colors"
    >
      <ArrowLeftIcon class="h-5 w-5 mr-1" />
      Back to all news
    </NuxtLink>

    <article
      v-if="article"
      class="bg-white rounded-xl shadow-lg overflow-hidden"
    >
      <div class="relative h-[400px]">
        <img
          :src="
            article.post_media && article.post_media.length > 0
              ? article.post_media[0].image
              : '/static/frontend/images/placeholder.jpg'
          "
          :alt="article.title"
          class="w-full h-full object-cover"
        />
        <div
          class="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"
        ></div>
        <div class="absolute bottom-0 left-0 right-0 p-6 sm:p-8 text-white">
          <div class="flex items-center mb-4">
            <span
              class="bg-primary text-white text-xs font-bold px-3 py-1 rounded-full"
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
          <h1 class="text-3xl sm:text-4xl font-bold mb-4 leading-tight">
            {{ article.title }}
          </h1>
        </div>
      </div>

      <div class="p-6 sm:p-8">
        <div class="flex items-center mb-8 border-b border-gray-200 pb-6">
          <img
            :src="
              article.author_details?.image ||
              '/static/frontend/images/placeholder.jpg'
            "
            :alt="
              article.author_details
                ? getAuthorName(article.author_details)
                : 'Anonymous'
            "
            class="h-12 w-12 rounded-full mr-4 border-2 border-primary"
          />
          <div>
            <p class="font-medium text-gray-900">
              Posted by:
              <span class="text-primary">{{
                article.author_details
                  ? getAuthorName(article.author_details)
                  : "Anonymous"
              }}</span>
            </p>
            <p class="text-sm text-gray-500">
              {{ article.author_details?.user_type || "" }}
            </p>
          </div>
          <div class="ml-auto flex space-x-3">
            <button
              class="p-2 bg-blue-500 text-white rounded-full hover:bg-blue-600 transition-colors"
            >
              <TwitterIcon class="h-4 w-4" />
            </button>
            <button
              class="p-2 bg-blue-700 text-white rounded-full hover:bg-blue-800 transition-colors"
            >
              <FacebookIcon class="h-4 w-4" />
            </button>
            <button
              class="p-2 bg-green-600 text-white rounded-full hover:bg-green-700 transition-colors"
            >
              <LinkIcon class="h-4 w-4" />
            </button>
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
            class="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm hover:bg-gray-200 cursor-pointer transition-colors"
          >
            #{{ tag.tag }}
          </span>
        </div>

        <!-- Comments Section -->
        <div class="border-t border-gray-200 pt-8">
          <h2 class="text-2xl font-bold mb-6 text-gray-900">
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
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary bg-white text-gray-900"
                ></textarea>
                <div class="mt-3 flex justify-end">
                  <button
                    type="submit"
                    class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-colors"
                  >
                    Post Comment
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
                      <h3 class="font-bold text-gray-900">
                        {{
                          comment.author_details
                            ? getAuthorName(comment.author_details)
                            : "Anonymous"
                        }}
                      </h3>
                      <span class="text-sm text-gray-500">{{
                        formatDate(comment.created_at)
                      }}</span>
                    </div>
                    <p class="text-gray-700">{{ comment.content }}</p>
                  </div>
                </div>
              </div>
            </transition-group>
            <div
              v-if="
                !article.post_comments || article.post_comments.length === 0
              "
              class="text-center py-8 text-gray-500"
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
          <h2 class="text-2xl font-bold mb-6 text-gray-900">
            Related Articles
          </h2>
          <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <div
              v-for="relatedArticle in relatedArticles"
              :key="relatedArticle.id"
              class="bg-gray-50 rounded-lg overflow-hidden shadow-md hover:shadow-lg transition-all duration-300"
            >
              <div class="relative h-40 overflow-hidden">
                <img
                  :src="
                    relatedArticle.post_media &&
                    relatedArticle.post_media.length > 0
                      ? relatedArticle.post_media[0].image
                      : '/static/frontend/images/placeholder.jpg'
                  "
                  :alt="relatedArticle.title"
                  class="w-full h-full object-cover transition-transform duration-500 hover:scale-110"
                />
              </div>
              <div class="p-4">
                <NuxtLink :to="`/adsy-news/${relatedArticle.slug}/`">
                  <h3
                    class="text-lg font-bold mb-2 text-gray-900 hover:text-primary cursor-pointer transition-colors"
                  >
                    {{ relatedArticle.title }}
                  </h3>
                </NuxtLink>
                <div
                  class="flex items-center justify-between text-sm text-gray-500"
                >
                  <div class="flex items-center">
                    <CalendarIcon class="h-4 w-4 mr-1" />
                    <span>{{ formatDate(relatedArticle.created_at) }}</span>
                  </div>
                  <span
                    >Posted by:
                    <span class="text-primary">{{
                      relatedArticle.author_details
                        ? getAuthorName(relatedArticle.author_details)
                        : "Anonymous"
                    }}</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </article>
  </UContainer>
</template>
<script setup>
definePageMeta({
  layout: "adsy-news",
});
const { get } = useApi();
const route = useRoute();

const article = ref(null);
const relatedArticles = ref([]);

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
    // Fetch all articles to find related ones
    const res = await get("/news/posts/");
    if (res.data && res.data.results) {
      // Filter out the current article
      relatedArticles.value = res.data.results
        .filter((a) => a.id !== article.value.id)
        .slice(0, 3); // Limit to 3 related articles
    }
  } catch (error) {
    console.error("Error fetching related articles:", error);
  }
}

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
  // Estimate read time based on content length (1 min per 1000 chars)
  return Math.max(1, Math.ceil(content.length / 1000));
}

function getAuthorName(authorDetails) {
  if (!authorDetails) return "Anonymous";

  if (authorDetails.name) return authorDetails.name;

  const firstName = authorDetails.first_name || "";
  const lastName = authorDetails.last_name || "";

  if (firstName || lastName) {
    return `${firstName} ${lastName}`.trim();
  }

  return authorDetails.username || "Anonymous";
}

import {
  ArrowLeftIcon,
  CalendarIcon,
  ClockIcon,
  TwitterIcon,
  FacebookIcon,
  LinkIcon,
} from "lucide-vue-next";

// New comment form data
const newComment = reactive({
  content: "",
});

// Function to add a new comment
const addComment = async () => {
  if (newComment.content && article.value) {
    try {
      // Add code here to send the comment to the API
      // Currently just showing a message since implementing this requires the post comment API
      alert(
        "Comment functionality would be implemented here with a POST to the API"
      );

      // Reset form
      newComment.content = "";
    } catch (error) {
      console.error("Error posting comment:", error);
    }
  }
};
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
