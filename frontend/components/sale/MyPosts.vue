<template>
  <div class="my-posts-container">
    <!-- Empty state with create button -->
    <div
      v-if="!posts.length && !isLoading"
      class="text-center p-12 bg-white/90 backdrop-blur-sm rounded-2xl shadow-sm border border-gray-100 overflow-hidden relative"
    >
      <div class="absolute inset-0 bg-gradient-to-br from-primary/5 to-indigo-50/30 z-0"></div>
      <div class="relative z-10 mb-10">
        <div class="flex justify-center">
          <div
            class="p-7 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-full inline-block shadow-inner overflow-hidden relative group"
          >
            <div class="absolute inset-0 bg-gradient-to-r from-primary/10 to-indigo-400/10 opacity-0 group-hover:opacity-100 transition-opacity duration-700"></div>
            <Icon
              name="heroicons:clipboard-document-list"
              class="h-16 w-16 text-primary drop-shadow-sm transform group-hover:scale-110 transition-transform duration-500"
            />
          </div>
        </div>
        <h3 class="text-2xl font-bold mt-8 text-gray-800">No posts yet</h3>
        <p class="text-gray-600 mt-4 max-w-md mx-auto leading-relaxed">
          Create your first post to start selling items in the marketplace!
        </p>
      </div>
      <button
        @click="$emit('create-post')"
        class="bg-gradient-to-r from-primary to-primary/90 text-white font-medium px-10 py-3.5 rounded-xl flex items-center gap-2 mx-auto shadow-sm hover:shadow-primary/20   transform hover:-translate-y-1"
      >
        <Icon name="heroicons:plus-circle" size="22px" />
        Create Post
      </button>
    </div>

    <!-- Loading state -->
    <div
      v-else-if="isLoading"
      class="p-8 bg-white/95 backdrop-blur-sm rounded-2xl shadow-sm border border-gray-100 overflow-hidden relative"
    >
      <div class="absolute inset-0 bg-gradient-to-tr from-blue-50/20 to-transparent"></div>
      <div
        class="flex justify-between items-center mb-8 pb-4 border-b border-gray-100 relative z-10"
      >        <div class="h-7 bg-gradient-to-r from-gray-200 to-gray-100 rounded-md w-36 animate-shimmer"></div>
        <div class="flex gap-4">
          <div class="h-10 w-36 bg-gradient-to-r from-gray-200 to-gray-100 rounded-lg animate-shimmer"></div>
          <div class="h-10 w-28 bg-gradient-to-r from-gray-200 to-gray-100 rounded-lg animate-shimmer"></div>
        </div>
      </div>
      <div v-for="i in 3" :key="i" class="mb-8 relative z-10">
        <div
          class="flex items-center gap-6 p-6 rounded-xl border border-gray-100/80 hover:border-gray-200  bg-white/50"
        >          <div class="w-28 h-28 bg-gradient-to-br from-gray-200 to-gray-100 rounded-xl animate-shimmer shadow-sm"></div>
          <div class="flex-1">
            <div class="h-6 bg-gradient-to-r from-gray-200 to-gray-100 rounded-md mb-4 w-3/4 animate-shimmer"></div>
            <div class="h-5 bg-gradient-to-r from-gray-200 to-gray-100 rounded-md mb-4 w-1/2 animate-shimmer"></div>
            <div class="h-5 bg-gradient-to-r from-gray-200 to-gray-100 rounded-md mb-4 w-2/3 animate-shimmer"></div>
            <div class="flex gap-3 mt-3">
              <div class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full w-24 animate-shimmer"></div>
              <div class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full w-20 animate-shimmer"></div>
            </div>
          </div>
          <div class="flex flex-col gap-4 items-end">
            <div class="flex gap-3">
              <div class="w-10 h-10 bg-gradient-to-r from-gray-200 to-gray-100 rounded-lg animate-shimmer"></div>
              <div class="w-10 h-10 bg-gradient-to-r from-gray-200 to-gray-100 rounded-lg animate-shimmer"></div>
            </div>
            <div class="w-28 h-10 bg-gradient-to-r from-gray-200 to-gray-100 rounded-lg animate-shimmer"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Post listing -->
    <div
      v-else
      class="bg-white/95 backdrop-blur-sm rounded-xl shadow-sm border border-gray-100 overflow-hidden"
    >      <!-- Header with Filters and controls -->
      <div
        class="flex flex-wrap justify-between items-center p-6 bg-gradient-to-r from-gray-50/80 via-white/60 to-white/80 border-b border-gray-100/70 backdrop-blur-sm"
      >
        <div class="flex items-center gap-4">
          <div
            class="flex items-center gap-1.5 bg-gradient-to-r from-gray-50 to-gray-100/70 px-4 py-1.5 rounded-full text-sm font-medium text-gray-600 shadow-sm"
          >
            <Icon name="heroicons:document-text" class="h-4 w-4 text-primary/70" />
            <span>{{ posts.length }}</span>
            <span>{{ posts.length === 1 ? "post" : "posts" }}</span>
          </div>
          <button
            @click="refreshPosts"
            class="p-2.5 text-gray-600 hover:text-primary bg-white/80 hover:bg-blue-50 rounded-full   shadow-sm hover:shadow border border-gray-100/70"
            title="Refresh posts"
          >
            <Icon
              name="heroicons:arrow-path"
              size="18px"
              :class="{ 'animate-spin': isRefreshing }"
            />
          </button>
        </div>

        <div class="flex items-center gap-4 mt-3 sm:mt-0">
          <div class="relative">
            <select
              v-model="statusFilter"
              class="border border-gray-200/80 rounded-lg py-2.5 text-sm font-medium pl-10 pr-10 text-gray-700 bg-white/90 shadow-sm hover:shadow focus:ring-2 focus:ring-primary/20 focus:border-primary appearance-none "
            >
              <option value="">All posts</option>
              <option value="pending">Pending review</option>
              <option value="active">Active</option>
              <option value="sold">Sold</option>
              <option value="expired">Expired</option>
            </select>
            <Icon
              name="heroicons:funnel"
              size="16px"
              class="absolute left-3 top-1/2 transform -translate-y-1/2 text-primary/70"
            />
            <Icon
              name="heroicons:chevron-down"
              size="16px"
              class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 pointer-events-none"
            />
          </div>

          <button
            @click="$emit('create-post')"
            class="bg-gradient-to-r from-primary to-primary/90 text-white font-medium text-sm px-4 py-2.5 rounded-lg flex items-center gap-2   shadow hover:shadow-primary/20 transform hover:-translate-y-0.5"
          >
            <Icon name="heroicons:plus-circle" size="18px" />
            New Post
          </button>
        </div>
      </div>      <!-- Post items -->
      <div class="divide-y divide-gray-50">
        <div
          v-for="post in filteredPosts"
          :key="post.id"
          class="p-"
        >
          <div class="flex gap-2 p-2">
            <!-- Post image -->
            <NuxtLink
              :to="`/sale/${post.slug}`"
              class="relative w-24 h-24 sm:w-32 sm:h-32 flex-shrink-0 rounded-xl overflow-hidden shadow-sm border border-gray-100/80 group-hover:shadow-sm   transform group-hover:scale-[1.03]"
            >
              <img
                v-if="post.main_image"
                :src="post.main_image"
                :alt="post.title"
                class="w-full h-full object-cover transform transition-transform duration-700 group-hover:scale-110"
              />
              <div
                v-else
                class="w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center"
              >
                <Icon name="heroicons:photo" class="h-12 w-12 text-gray-400" />
              </div>

              <!-- Status badge -->
              <div class="absolute top-2 left-2">
                <span
                  :class="{
                    'bg-gradient-to-r from-yellow-400 to-amber-500':
                      post.status === 'pending',
                    'bg-gradient-to-r from-green-500 to-emerald-600':
                      post.status === 'active',
                    'bg-gradient-to-r from-blue-500 to-indigo-600':
                      post.status === 'sold',
                    'bg-gradient-to-r from-red-500 to-rose-600':
                      post.status === 'expired',
                  }"
                  class="text-white text-xs font-medium px-2.5 py-1 rounded-md shadow-sm backdrop-blur-sm"
                >
                  {{ formatStatus(post.status) }}
                </span>
              </div>
            </NuxtLink>            
            <!-- Post details -->
            <div class="flex-1 min-w-0">
              <div class="flex justify-between items-start">
                <div>
                  <NuxtLink :to="`/sale/${post.slug}`">
                    <h3
                      class="text-xl font-semibold line-clamp-1 text-gray-800 hover:text-primary transition-colors group-hover:text-primary"
                    >
                      {{ post.title }}
                    </h3>
                  </NuxtLink>
                  <div
                    class="mt-3 flex items-center text-sm gap-3"
                  >
                    <div class="flex items-center gap-1.5 bg-gradient-to-r from-primary/5 to-primary/10 px-3 py-1.5 rounded-lg shadow-sm">
                      <Icon
                        name="heroicons:currency-bangladeshi"
                        class="h-5 w-5 text-primary"
                      />
                      <span class="font-bold text-gray-700">{{
                        post.price
                          ? `৳${post.price.toLocaleString()}`
                          : "Negotiable"
                      }}</span>
                    </div>
                    <div class="flex items-center gap-1.5 bg-gray-100/70 px-3 py-1.5 rounded-lg">
                      <Icon
                        name="heroicons:calendar"
                        class="h-4 w-4 text-gray-600"
                      />
                      <span class="text-gray-700">{{ formatDate(post.created_at) }}</span>
                    </div>
                  </div>
                  <div
                    class="mt-3 flex items-center text-sm text-gray-600 gap-1.5 bg-gray-50/80 px-3 py-1.5 rounded-lg inline-flex"
                  >
                    <Icon
                      name="heroicons:map-pin"
                      class="h-4 w-4 text-gray-600"
                    />
                    <span class="line-clamp-1"
                      >{{ post.area }}, {{ post.district }}</span
                    >
                  </div>
                  <div
                    class="mt-4 flex flex-block items-start text-xs text-gray-600 gap-3"
                  >
                    <span
                      class="flex items-start gap-1.5 bg-white px-3 py-1.5 rounded-full shadow-sm border border-gray-100/80 group-hover:bg-gray-50/80 group-hover:border-gray-200/80  "
                    >
                      <Icon name="heroicons:eye" class="h-3.5 w-3.5 text-gray-500" />
                      <span class="font-medium">{{ post.view_count }}</span> views
                    </span>
                    <span
                      v-if="post.condition"
                      class="flex items-center gap-1.5 bg-white px-3 py-1.5 rounded-full shadow-sm border border-gray-100/80 group-hover:bg-gray-50/80 group-hover:border-gray-200/80  "
                    >
                      <Icon name="heroicons:tag" class="h-3.5 w-3.5 text-gray-500" />
                      {{ post.condition }}
                    </span>
                  </div>
                </div>
              </div>
            </div>            <!-- Action buttons -->
            <div class="flex flex-col gap-4 items-end justify-between">
              <!-- Edit/Delete buttons -->
              <div class="flex gap-2.5">
                <button
                  @click="$emit('edit-post', post)"
                  class="p-2.5 text-gray-500 hover:text-primary hover:bg-blue-50 rounded-lg  duration-200 shadow-sm hover:shadow border border-gray-100 hover:border-blue-100"
                  title="Edit post"
                >
                  <Icon name="heroicons:pencil-square" size="20px" />
                </button>
                <button
                  @click="confirmDelete(post.id, post.title)"
                  class="p-2.5 text-gray-500 hover:text-red-500 hover:bg-red-50 rounded-lg  duration-200 shadow-sm hover:shadow border border-gray-100 hover:border-red-100"
                  title="Delete post"
                >
                  <Icon name="heroicons:trash" size="20px" />
                </button>
              </div>
              <!-- Mark as Sold button with states -->
              <button
                v-if="post.status !== 'sold' && post.status !== 'pending'"
                @click="markAsSold(post.id)"
                :disabled="markingSold === post.id"
                class="flex items-center gap-2.5 px-5 py-2.5 text-sm rounded-lg   shadow-sm"
                :class="[
                  markingSold === post.id
                    ? 'bg-gray-100 text-gray-500 cursor-not-allowed'
                    : 'bg-gradient-to-r from-blue-500/10 to-blue-600/10 text-blue-600 hover:from-blue-500/20 hover:to-blue-600/20 hover:shadow border border-blue-200/50',
                ]"
              >
                <Icon
                  :name="
                    markingSold === post.id
                      ? 'heroicons:clock'
                      : 'heroicons:tag'
                  "
                  size="18px"
                  class="flex-shrink-0"
                />
                {{ markingSold === post.id ? "Processing..." : "Mark as Sold" }}
              </button>

              <!-- Pending notice -->
              <div
                v-else-if="post.status === 'pending'"
                class="flex items-center gap-2.5 px-5 py-2.5 text-sm bg-gradient-to-r from-amber-50/80 to-amber-100/50 text-amber-600 rounded-lg shadow-sm border border-amber-200/30 backdrop-blur-sm"
              >
                <Icon
                  name="heroicons:clock"
                  size="18px"
                  class="flex-shrink-0"
                />
                Awaiting Approval
              </div>

              <!-- Sold status indicator -->
              <div
                v-else
                class="flex items-center gap-2.5 px-5 py-2.5 text-sm bg-gradient-to-r from-green-50/80 to-emerald-50/80 text-green-600 rounded-lg shadow-sm border border-green-200/30 backdrop-blur-sm"
              >
                <Icon
                  name="heroicons:check-circle"
                  size="18px"
                  class="flex-shrink-0"
                />
                Sold
              </div>
            </div>
          </div>
        </div>
      </div>      <!-- Empty filtered state -->
      <div
        v-if="posts.length > 0 && filteredPosts.length === 0"
        class="py-16 text-center bg-gradient-to-b from-white to-gray-50/80"
      >
        <div class="mb-5 relative">
          <div class="inline-block p-6 bg-gradient-to-br from-gray-50 to-white rounded-full shadow-inner relative overflow-hidden">
            <div class="absolute inset-0 bg-gradient-to-r from-gray-100/20 to-gray-200/30 opacity-50"></div>
            <Icon name="heroicons:face-frown" class="h-16 w-16 text-gray-400 relative z-10" />
          </div>
          <div class="absolute w-full h-8 top-full left-0 bg-gradient-to-b from-gray-200/20 to-transparent -mt-3 blur-xl rounded-full"></div>
        </div>
        <h3 class="text-gray-700 text-xl font-semibold">
          No matching posts found
        </h3>
        <p class="text-gray-500 mt-3 max-w-md mx-auto">
          There are no posts with the "<span class="font-medium text-gray-600">{{ statusFilter }}</span>" status.
        </p>
        <button
          @click="statusFilter = ''"
          class="mt-6 px-7 py-3 bg-gradient-to-r from-gray-100 to-white text-gray-700 rounded-xl   shadow-sm hover:shadow-sm border border-gray-200/50 transform hover:-translate-y-0.5"
        >
          <span class="flex items-center gap-2">
            <Icon name="heroicons:arrow-path" class="h-5 w-5" />
            Show all posts
          </span>
        </button>
      </div>

      <!-- Load more button -->
      <div
        v-if="hasMorePosts"
        class="p-8 border-t border-gray-100 bg-gradient-to-b from-white/80 to-gray-50/60 text-center backdrop-blur-sm"
      >
        <button
          @click="loadMorePosts"
          class="px-8 py-3 border border-gray-200/70 rounded-xl text-gray-700 bg-white hover:bg-gradient-to-r hover:from-primary/5 hover:to-indigo-50   shadow-sm hover:shadow-sm flex items-center gap-3 mx-auto transform hover:-translate-y-0.5"
          :disabled="isLoadingMore"
        >
          <span
            v-if="isLoadingMore"
            class="flex items-center gap-3 justify-center"
          >
            <span
              class="inline-block h-5 w-5 border-2 border-t-2 border-gray-300 border-t-primary rounded-full animate-spin"
            ></span>
            Loading more posts...
          </span>
          <span v-else class="flex items-center gap-3 justify-center">
            <Icon name="heroicons:arrow-down" size="20px" class="text-primary" />
            <span class="font-medium">Load more posts</span>
          </span>
        </button>
      </div>
    </div>    <!-- Delete confirmation modal -->
    <Teleport to="body">
      <div
        v-if="showDeleteModal"
        class="fixed inset-0 z-50 overflow-y-auto bg-black/50 backdrop-blur-md "
      >
        <div
          class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center"
        >
          <div
            class="inline-block align-bottom bg-white/95 backdrop-blur-sm rounded-2xl text-left overflow-hidden sm:my-8 sm:align-middle sm:max-w-lg sm:w-full border border-gray-100"
          >
            <div class="bg-gradient-to-b from-white to-gray-50/80 px-7 pt-7 pb-6">
              <div class="sm:flex sm:items-start">
                <div
                  class="mx-auto flex-shrink-0 flex items-center justify-center h-16 w-16 rounded-full bg-gradient-to-br from-red-50 to-red-100 sm:mx-0 sm:h-14 sm:w-14 shadow-inner overflow-hidden relative"
                >
                  <div class="absolute inset-0 bg-gradient-to-r from-red-500/5 to-red-600/10 opacity-70"></div>
                  <Icon
                    name="heroicons:exclamation-triangle"
                    class="h-8 w-8 text-red-500 drop-shadow-sm"
                  />
                </div>
                <div class="mt-3 text-center sm:mt-0 sm:ml-6 sm:text-left">
                  <h3 class="text-2xl leading-7 font-bold text-gray-800">
                    Delete Post
                  </h3>
                  <div class="mt-4">
                    <p class="text-gray-600 leading-relaxed">
                      Are you sure you want to delete "<span
                        class="font-semibold text-gray-800"
                        >{{ postToDeleteTitle }}</span
                      >"? This action cannot be undone.
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <div class="bg-gradient-to-b from-gray-50/70 to-gray-100/40 px-7 py-5 sm:flex sm:flex-row-reverse gap-4">
              <button
                type="button"
                class="w-full inline-flex justify-center rounded-xl border border-transparent shadow-sm px-6 py-3 bg-gradient-to-r from-red-500 to-red-600 text-base font-medium text-white hover:from-red-600 hover:to-red-700 focus:outline-none   transform hover:-translate-y-0.5 sm:ml-3 sm:w-auto"
                @click="deletePost"
              >
                <span class="flex items-center gap-2">
                  <Icon name="heroicons:trash" class="w-5 h-5" />
                  Delete Post
                </span>
              </button>
              <button
                type="button"
                class="mt-3 w-full inline-flex justify-center rounded-xl border border-gray-200 shadow-sm px-6 py-3 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none   transform hover:-translate-y-0.5 sm:mt-0 sm:w-auto"
                @click="showDeleteModal = false"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from "vue";

const { get, post, del, patch } = useApi();
const { user } = useAuth();
const { showNotification } = useNotifications();

const emit = defineEmits(["create-post", "edit-post", "delete-post"]);

// State
const posts = ref([]);
const isLoading = ref(true);
const isLoadingMore = ref(false);
const isRefreshing = ref(false);
const statusFilter = ref("");
const currentPage = ref(1);
const hasMorePosts = ref(false);
const pagination = ref(null);
const markingSold = ref(null); // Track which post is being marked as sold

// Delete confirmation state
const showDeleteModal = ref(false);
const postToDeleteId = ref(null);
const postToDeleteTitle = ref("");

// Filter posts based on status
const filteredPosts = computed(() => {
  if (!statusFilter.value) {
    return posts.value;
  }
  return posts.value.filter((post) => post.status === statusFilter.value);
});

// Format status for display
const formatStatus = (status) => {
  switch (status) {
    case "pending":
      return "Pending";
    case "active":
      return "Active";
    case "sold":
      return "Sold";
    case "expired":
      return "Expired";
    default:
      return status;
  }
};

// Format date for display
const formatDate = (dateString) => {
  if (!dateString) return "";

  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays <= 1) {
    return "Today";
  } else if (diffDays <= 2) {
    return "Yesterday";
  } else if (diffDays <= 7) {
    return `${diffDays} days ago`;
  } else {
    return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  }
};

// Fetch user's posts
const fetchPosts = async (page = 1) => {
  if (page === 1) {
    isLoading.value = true;
  } else {
    isLoadingMore.value = true;
  }

  try {
    // Use my_posts action to get only the current user's posts
    const response = await get(
      `/sale/posts/my_posts/`,
      {},
      {
        headers: {
          "Cache-Control": "no-cache",
          Pragma: "no-cache",
        },
      }
    );

    if (response.data) {
      if ("results" in response.data) {
        // Paginated response
        pagination.value = {
          count: response.data.count,
          next: response.data.next,
          previous: response.data.previous,
        };

        if (page === 1) {
          posts.value = response.data.results;
        } else {
          posts.value = [...posts.value, ...response.data.results];
        }

        hasMorePosts.value = !!response.data.next;
      } else if (Array.isArray(response.data)) {
        // Non-paginated response
        posts.value = response.data;
        hasMorePosts.value = false;
      }
    }
  } catch (error) {
    console.error("Error fetching posts:", error);
    showNotification({
      title: "Error",
      message: "Failed to load your posts. Please try again later.",
      type: "error",
    });
  } finally {
    isLoading.value = false;
    isLoadingMore.value = false;
  }
};

// Refresh posts
const refreshPosts = async () => {
  isRefreshing.value = true;
  currentPage.value = 1;

  try {
    // Use my_posts action to get only the current user's posts
    const response = await get(
      `/sale/posts/my_posts/`,
      {},
      {
        headers: {
          "Cache-Control": "no-cache",
          Pragma: "no-cache",
        },
      }
    );

    if (response.data) {
      if ("results" in response.data) {
        // Paginated response
        pagination.value = {
          count: response.data.count,
          next: response.data.next,
          previous: response.data.previous,
        };

        posts.value = response.data.results;
        hasMorePosts.value = !!response.data.next;
      } else if (Array.isArray(response.data)) {
        // Non-paginated response
        posts.value = response.data;
        hasMorePosts.value = false;
      }

      // Show success message only if we actually got some posts
      if (posts.value.length > 0) {
        showNotification({
          title: "Updated",
          message: "Your posts have been refreshed.",
          type: "success",
        });
      }
    }
  } catch (error) {
    console.error("Error refreshing posts:", error);
    showNotification({
      title: "Error",
      message: "Failed to refresh your posts. Please try again later.",
      type: "error",
    });
  } finally {
    isRefreshing.value = false;
  }
};

// Load more posts
const loadMorePosts = () => {
  if (hasMorePosts.value) {
    currentPage.value++;
    fetchPosts(currentPage.value);
  }
};

// Mark a post as sold
const markAsSold = async (postId) => {
  // Set loading state for this specific post
  markingSold.value = postId;

  try {
    // Find the post object by ID to get its slug
    const postToUpdate = posts.value.find((p) => p.id === postId);
    if (!postToUpdate || !postToUpdate.slug) {
      throw new Error("Could not find post with that ID or post has no slug");
    }

    // Use the custom action endpoint specifically designed for marking posts as sold
    const response = await post(
      `/sale/posts/${postToUpdate.slug}/mark_as_sold/`,
      {}
    );

    if (response && response.data) {
      // Update post in the local state
      const postIndex = posts.value.findIndex((p) => p.id === postId);
      if (postIndex !== -1) {
        posts.value[postIndex] = {
          ...posts.value[postIndex],
          status: "sold",
        };
      }

      showNotification({
        title: "Success!",
        message: "Your post has been marked as sold.",
        type: "success",
      });
    }
  } catch (error) {
    console.error("Error marking post as sold:", error);

    // Show appropriate error message based on the error
    let errorMessage = "Failed to mark post as sold. Please try again later.";

    // Check for client-side errors first
    if (error.message && error.message.includes("Could not find post")) {
      errorMessage =
        "Could not identify the post. Please refresh and try again.";
    } else if (error.response) {
      // The request was made and the server responded with a non-2xx status
      if (error.response.status === 403) {
        errorMessage = "You don't have permission to mark this post as sold.";
      } else if (error.response.status === 404) {
        errorMessage = "This post no longer exists.";
      } else if (error.response.data && error.response.data.detail) {
        errorMessage = error.response.data.detail;
      }
    } else if (error.request) {
      // The request was made but no response was received
      errorMessage = "Network error. Please check your internet connection.";
    }

    showNotification({
      title: "Error",
      message: errorMessage,
      type: "error",
    });
  } finally {
    // Clear loading state
    markingSold.value = null;
  }
};

// Confirm delete action
const confirmDelete = (id, title) => {
  postToDeleteId.value = id;
  postToDeleteTitle.value = title;
  showDeleteModal.value = true;
};

// Delete post
const deletePost = async () => {
  if (!postToDeleteId.value) return;

  try {
    // Find the post by ID to get its slug
    const postToDelete = posts.value.find((p) => p.id === postToDeleteId.value);
    if (!postToDelete || !postToDelete.slug) {
      throw new Error("Could not find post with that ID or post has no slug");
    }

    // Use the slug instead of ID for the API call
    await del(`/sale/posts/${postToDelete.slug}/`);

    // Remove post from local state
    posts.value = posts.value.filter((p) => p.id !== postToDeleteId.value);

    // Emit event
    emit("delete-post", postToDeleteId.value);

    showNotification({
      title: "Success",
      message: "Post deleted successfully!",
      type: "success",
    });
  } catch (error) {
    console.error("Error deleting post:", error);
    showNotification({
      title: "Error",
      message: "Failed to delete post. Please try again later.",
      type: "error",
    });
  } finally {
    showDeleteModal.value = false;
    postToDeleteId.value = null;
    postToDeleteTitle.value = "";
  }
};

// Watch for user change to reload posts
watch(
  () => user.value?.id,
  (newId) => {
    if (newId) {
      fetchPosts();
    }
  }
);

// Load posts on component mount
onMounted(() => {
  if (user.value?.user.id) {
    fetchPosts();
  }
});
</script>

<style>
/* Pulse animation with enhanced timing and smoothness */
.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

/* New shimmer effect animation */
.animate-shimmer {
  background-size: 200% 100%;
  animation: shimmer 1.5s linear infinite;
  background-image: linear-gradient(90deg, rgba(255,255,255,0) 0%, rgba(255,255,255,0.6) 50%, rgba(255,255,255,0) 100%);
}

@keyframes shimmer {
  to {
    background-position: 200% 0;
  }
}

/* Skeleton pulse animation for loading states */
.skeleton-pulse {
  position: relative;
  overflow: hidden;
}

.skeleton-pulse::after {
  content: "";
  position: absolute;
  top: 0;
  right: -100%;
  bottom: 0;
  left: 0;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.4), transparent);
  animation: skeleton-pulse 1.8s infinite;
}

@keyframes skeleton-pulse {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.my-posts-container {
  max-width: 4xl;
  margin-left: auto;
  margin-right: auto;
}

/* Loading spinner animation */
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
.animate-spin {
  animation: spin 1s linear infinite;
}


/* Hover scale effect */
.group:hover .group-hover\:scale-105 {
  transform: scale(1.05);
}

/* Glass morphism effect */
.backdrop-blur-sm {
  backdrop-filter: blur(8px);
}

/* Rich gradient backgrounds */
.bg-gradient-card {
  background-image: linear-gradient(135deg, #ffffff 0%, #f9fafb 100%);
}

/* Card hover effects */
.card-hover {
  transition: all 0.3s ease;
}
.card-hover:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px -6px rgba(0, 0, 0, 0.1);
}
</style>
