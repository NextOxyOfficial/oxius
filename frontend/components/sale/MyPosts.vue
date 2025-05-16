<template>
  <div class="my-posts-container">
    <!-- Empty state with create button -->
    <div v-if="!posts.length && !isLoading" class="text-center p-10 bg-white rounded-xl shadow-sm border border-gray-100">
      <div class="mb-8">
        <div class="flex justify-center">
          <div class="p-6 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-full inline-block shadow-inner">
            <Icon
              name="heroicons:clipboard-document-list"
              class="h-14 w-14 text-primary"
            />
          </div>
        </div>
        <h3 class="text-2xl font-semibold mt-6 text-gray-800">No posts yet</h3>
        <p class="text-gray-600 mt-3 max-w-sm mx-auto">
          Create your first post to start selling items in the marketplace!
        </p>
      </div>
      <button
        @click="$emit('create-post')"
        class="bg-gradient-to-r from-primary to-primary/90 text-white font-medium px-8 py-3 rounded-lg flex items-center gap-2 mx-auto shadow-sm hover:shadow-sm transition-all duration-200 transform hover:-translate-y-0.5"
      >
        <Icon name="heroicons:plus-circle" size="20px" />
        Create Post
      </button>
    </div>

    <!-- Loading state -->
    <div v-else-if="isLoading" class="p-8 bg-white rounded-xl shadow-sm border border-gray-50">
      <div class="flex justify-between items-center mb-8 pb-4 border-b border-gray-100">
        <div class="h-7 bg-gray-200 rounded-md w-36 animate-pulse"></div>
        <div class="flex gap-4">
          <div class="h-10 w-36 bg-gray-200 rounded-lg animate-pulse"></div>
          <div class="h-10 w-28 bg-gray-200 rounded-lg animate-pulse"></div>
        </div>
      </div>
      <div v-for="i in 3" :key="i" class="mb-8 animate-pulse">
        <div class="flex items-center gap-6 p-4 rounded-xl border border-gray-100 hover:border-gray-200 transition-all">
          <div class="w-28 h-28 bg-gray-200 rounded-lg"></div>
          <div class="flex-1">
            <div class="h-6 bg-gray-200 rounded-md mb-4 w-3/4"></div>
            <div class="h-5 bg-gray-200 rounded-md mb-3 w-1/2"></div>
            <div class="h-5 bg-gray-200 rounded-md mb-3 w-2/3"></div>
            <div class="h-4 bg-gray-200 rounded-md w-1/3"></div>
          </div>
          <div class="flex flex-col gap-4 items-end">
            <div class="flex gap-3">
              <div class="w-10 h-10 bg-gray-200 rounded-lg"></div>
              <div class="w-10 h-10 bg-gray-200 rounded-lg"></div>
            </div>
            <div class="w-28 h-10 bg-gray-200 rounded-lg"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Post listing -->
    <div v-else class="bg-white rounded-xl shadow-sm border border-gray-50 overflow-hidden">
      <!-- Header with Filters and controls -->
      <div class="flex flex-wrap justify-between items-center p-6 bg-gradient-to-r from-gray-50 to-white border-b border-gray-100">
        <div class="flex items-center gap-4">
          <h2 class="text-xl font-semibold text-gray-800">My Posts</h2>
          <div class="flex items-center gap-1 bg-gray-100 px-3 py-1 rounded-full text-sm text-gray-600">
            <span>{{ posts.length }}</span>
            <span>{{ posts.length === 1 ? 'post' : 'posts' }}</span>
          </div>
          <button 
            @click="refreshPosts" 
            class="p-2 text-gray-500 hover:text-primary hover:bg-blue-50 rounded-full transition-all duration-200"
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
              class="border border-gray-200 rounded-lg py-2.5 pl-10 pr-10 text-gray-700 bg-white shadow-sm focus:ring-2 focus:ring-primary/20 focus:border-primary appearance-none transition-colors"
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
              class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
            />
            <Icon 
              name="heroicons:chevron-down" 
              size="16px" 
              class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 pointer-events-none"
            />
          </div>
          
          <button
            @click="$emit('create-post')"
            class="bg-primary hover:bg-primary/90 text-white font-medium px-5 py-2.5 rounded-lg flex items-center gap-2 transition-all duration-200 shadow hover:shadow-sm"
          >
            <Icon name="heroicons:plus-circle" size="18px" />
            New Post
          </button>
        </div>
      </div>

      <!-- Post items -->
      <div class="divide-y divide-gray-50">
        <div
          v-for="post in filteredPosts"
          :key="post.id"
          class="p-5 hover:bg-gray-50 transition-all duration-200 group"
        >
          <div class="flex gap-5">
            <!-- Post image -->
            <NuxtLink
              :to="`/sale/${post.slug}`"
              class="relative w-24 h-24 sm:w-28 sm:h-28 flex-shrink-0 rounded-xl overflow-hidden shadow-sm border border-gray-100 "
            >
              <img
                v-if="post.main_image"
                :src="post.main_image"
                :alt="post.title"
                class="w-full h-full object-cover transform "
              />
              <div
                v-else
                class="w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center"
              >
                <Icon name="heroicons:photo" class="h-10 w-10 text-gray-400" />
              </div>

              <!-- Status badge -->
              <div class="absolute top-2 left-2">
                <span
                  :class="{
                    'bg-gradient-to-r from-yellow-400 to-amber-500': post.status === 'pending',
                    'bg-gradient-to-r from-green-500 to-emerald-600': post.status === 'active',
                    'bg-gradient-to-r from-blue-500 to-indigo-600': post.status === 'sold',
                    'bg-gradient-to-r from-red-500 to-rose-600': post.status === 'expired',
                  }"
                  class="text-white text-xs font-medium px-2.5 py-1 rounded shadow-sm"
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
                    <h3 class="text-lg font-medium line-clamp-1 text-gray-800 hover:text-primary transition-colors group-hover:text-primary">
                      {{ post.title }}
                    </h3>
                  </NuxtLink>
                  <div class="mt-2 flex items-center text-sm text-gray-600 gap-2">
                    <div class="flex items-center gap-1">
                      <Icon
                        name="heroicons:currency-bangladeshi"
                        class="h-4.5 w-4.5 text-primary/80"
                      />
                      <span class="font-medium">{{
                        post.price ? `৳${post.price.toLocaleString()}` : "Negotiable"
                      }}</span>
                    </div>
                    <span class="mx-1 text-gray-300">•</span>
                    <div class="flex items-center gap-1">
                      <Icon name="heroicons:calendar" class="h-4 w-4 text-gray-500" />
                      <span>{{ formatDate(post.created_at) }}</span>
                    </div>
                  </div>
                  <div class="mt-2 flex items-center text-sm text-gray-600 gap-1.5">
                    <Icon name="heroicons:map-pin" class="h-4 w-4 text-gray-500" />
                    <span class="line-clamp-1">{{ post.area }}, {{ post.district }}</span>
                  </div>
                  <div class="mt-3 flex items-center text-xs text-gray-500 gap-4">
                    <span class="flex items-center gap-1.5 bg-gray-50 px-2.5 py-1 rounded-full group-hover:bg-gray-100 transition-colors">
                      <Icon name="heroicons:eye" class="h-3.5 w-3.5" />
                      {{ post.view_count }} views
                    </span>
                    <span v-if="post.condition" class="flex items-center gap-1.5 bg-gray-50 px-2.5 py-1 rounded-full group-hover:bg-gray-100 transition-colors">
                      <Icon name="heroicons:tag" class="h-3.5 w-3.5" />
                      {{ post.condition }}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Action buttons -->
            <div class="flex flex-col gap-4 items-end justify-between">
              <!-- Edit/Delete buttons -->
              <div class="flex gap-2">
                <button
                  @click="$emit('edit-post', post)"
                  class="p-2 text-gray-600 hover:text-primary hover:bg-blue-50 rounded-lg transition-colors"
                  title="Edit post"
                >
                  <Icon name="heroicons:pencil-square" size="20px" />
                </button>
                <button
                  @click="confirmDelete(post.id, post.title)"
                  class="p-2 text-gray-600 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
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
                class="flex items-center gap-2 px-4 py-2 text-sm rounded-lg transition-all duration-200"
                :class="[
                  markingSold === post.id 
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed' 
                    : 'bg-blue-50 text-blue-600 hover:bg-blue-100 hover:shadow'
                ]"
              >
                <Icon 
                  :name="markingSold === post.id ? 'heroicons:clock' : 'heroicons:tag'" 
                  size="18px" 
                  class="flex-shrink-0" 
                />
                {{ markingSold === post.id ? 'Processing...' : 'Mark as Sold' }}
              </button>
              
              <!-- Pending notice -->
              <div 
                v-else-if="post.status === 'pending'"
                class="flex items-center gap-2 px-4 py-2 text-sm bg-amber-50 text-amber-600 rounded-lg opacity-75"
              >
                <Icon name="heroicons:clock" size="18px" class="flex-shrink-0" />
                Awaiting Approval
              </div>
              
              <!-- Sold status indicator -->
              <div 
                v-else
                class="flex items-center gap-2 px-4 py-2 text-sm bg-gradient-to-r from-green-50 to-emerald-50 text-green-600 rounded-lg shadow-sm"
              >
                <Icon name="heroicons:check-circle" size="18px" class="flex-shrink-0" />
                Sold
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty filtered state -->
      <div v-if="posts.length > 0 && filteredPosts.length === 0" class="py-12 text-center">
        <div class="mb-4">
          <div class="inline-block p-4 bg-gray-50 rounded-full">
            <Icon name="heroicons:face-frown" class="h-12 w-12 text-gray-400" />
          </div>
        </div>
        <h3 class="text-gray-700 text-lg font-medium">No matching posts found</h3>
        <p class="text-gray-500 mt-2">There are no posts with the "{{ statusFilter }}" status.</p>
        <button 
          @click="statusFilter = ''" 
          class="mt-5 px-6 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg transition-all duration-200 shadow-sm hover:shadow"
        >
          Show all posts
        </button>
      </div>

      <!-- Load more button -->
      <div v-if="hasMorePosts" class="p-6 border-t border-gray-100 bg-gray-50 text-center">
        <button
          @click="loadMorePosts"
          class="px-6 py-2.5 border border-gray-300 rounded-lg text-gray-700 hover:bg-white transition-all duration-200 shadow-sm hover:shadow flex items-center gap-2 mx-auto"
          :disabled="isLoadingMore"
        >
          <span v-if="isLoadingMore" class="flex items-center gap-2 justify-center">
            <span class="inline-block h-4 w-4 border-2 border-t-2 border-gray-300 border-t-primary rounded-full animate-spin"></span>
            Loading more posts...
          </span>
          <span v-else class="flex items-center gap-2 justify-center">
            <Icon name="heroicons:arrow-down" size="18px" />
            Load more posts
          </span>
        </button>
      </div>
    </div>

    <!-- Delete confirmation modal -->
    <div v-if="showDeleteModal" class="fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-60 backdrop-blur-sm transition-all">
      <div
        class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center"
      >
        <div
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white px-6 pt-6 pb-5">
            <div class="sm:flex sm:items-start">
              <div
                class="mx-auto flex-shrink-0 flex items-center justify-center h-14 w-14 rounded-full bg-red-100 sm:mx-0 sm:h-12 sm:w-12"
              >
                <Icon
                  name="heroicons:exclamation-triangle"
                  class="h-7 w-7 text-red-600"
                />
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-5 sm:text-left">
                <h3 class="text-xl leading-6 font-semibold text-gray-900">
                  Delete Post
                </h3>
                <div class="mt-3">
                  <p class="text-gray-600">
                    Are you sure you want to delete "<span class="font-medium">{{ postToDeleteTitle }}</span>"?
                    This action cannot be undone.
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-6 py-4 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              class="w-full inline-flex justify-center rounded-lg border border-transparent shadow-sm px-5 py-2.5 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none transition-colors sm:ml-3 sm:w-auto"
              @click="deletePost"
            >
              Delete
            </button>
            <button
              type="button"
              class="mt-3 w-full inline-flex justify-center rounded-lg border border-gray-300 shadow-sm px-5 py-2.5 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none transition-colors sm:mt-0 sm:ml-3 sm:w-auto"
              @click="showDeleteModal = false"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
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
    const response = await get(`/sale/posts/my_posts/`, {}, {
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      }
    });

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
    const response = await get(`/sale/posts/my_posts/`, {}, {
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      }
    });

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
    const postToUpdate = posts.value.find(p => p.id === postId);
    if (!postToUpdate || !postToUpdate.slug) {
      throw new Error("Could not find post with that ID or post has no slug");
    }
    
    // Use the custom action endpoint specifically designed for marking posts as sold
    const response = await post(`/sale/posts/${postToUpdate.slug}/mark_as_sold/`, {});

    if (response && response.data) {
      // Update post in the local state
      const postIndex = posts.value.findIndex((p) => p.id === postId);
      if (postIndex !== -1) {
        posts.value[postIndex] = {
          ...posts.value[postIndex],
          status: "sold"
        };
      }

      showNotification({
        title: "Success!",
        message: "Your post has been marked as sold.",
        type: "success",
      });    }
  } catch (error) {
    console.error("Error marking post as sold:", error);
    
    // Show appropriate error message based on the error
    let errorMessage = "Failed to mark post as sold. Please try again later.";
    
    // Check for client-side errors first
    if (error.message && error.message.includes("Could not find post")) {
      errorMessage = "Could not identify the post. Please refresh and try again.";
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
    const postToDelete = posts.value.find(p => p.id === postToDeleteId.value);
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

/* Add premium transition effects */
.transition-all {
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
}

/* Fix for the stagger animation on hover */
.group:hover .group-hover\:scale-105 {
  transform: scale(1.05);
}
</style>
