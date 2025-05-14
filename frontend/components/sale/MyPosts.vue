<template>
  <div class="my-posts-container">
    <!-- Empty state with create button -->
    <div v-if="!posts.length && !isLoading" class="text-center py-12 bg-white rounded-lg shadow">
      <div class="mb-6">
        <div class="flex justify-center">
          <div class="p-6 bg-blue-50 rounded-full inline-block">
            <Icon
              name="heroicons:clipboard-document-list"
              class="h-12 w-12 text-blue-500"
            />
          </div>
        </div>
        <h3 class="text-xl font-semibold mt-5">No posts yet</h3>
        <p class="text-gray-600 mt-2 max-w-sm mx-auto">
          Create your first post to start selling items in the marketplace!
        </p>
      </div>
      <button
        @click="$emit('create-post')"
        class="bg-primary hover:bg-primary/90 text-white font-medium px-6 py-2.5 rounded-md flex items-center gap-2 mx-auto shadow-sm hover:shadow transition-all"
      >
        <Icon name="heroicons:plus-circle" size="18px" />
        Create Post
      </button>
    </div>

    <!-- Loading state -->
    <div v-else-if="isLoading" class="p-6 bg-white rounded-lg shadow">
      <div class="flex justify-between items-center mb-6 pb-4 border-b border-gray-100">
        <div class="h-6 bg-gray-200 rounded w-32 animate-pulse"></div>
        <div class="flex gap-3">
          <div class="h-8 w-32 bg-gray-200 rounded animate-pulse"></div>
          <div class="h-8 w-24 bg-gray-200 rounded animate-pulse"></div>
        </div>
      </div>
      <div v-for="i in 3" :key="i" class="mb-6 animate-pulse">
        <div class="flex items-center gap-4">
          <div class="w-24 h-24 bg-gray-200 rounded-md"></div>
          <div class="flex-1">
            <div class="h-5 bg-gray-200 rounded mb-3 w-3/4"></div>
            <div class="h-4 bg-gray-200 rounded mb-2 w-1/2"></div>
            <div class="h-4 bg-gray-200 rounded mb-2 w-2/3"></div>
            <div class="h-3 bg-gray-200 rounded w-1/3"></div>
          </div>
          <div class="flex flex-col gap-3 items-end">
            <div class="flex gap-2">
              <div class="w-8 h-8 bg-gray-200 rounded-full"></div>
              <div class="w-8 h-8 bg-gray-200 rounded-full"></div>
            </div>
            <div class="w-24 h-8 bg-gray-200 rounded-md"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Post listing -->
    <div v-else class="bg-white rounded-lg shadow">
      <!-- Header with Filters and controls -->
      <div class="flex flex-wrap justify-between items-center p-4 border-b border-gray-100">
        <div class="flex items-center gap-3">
          <h2 class="text-lg font-medium text-gray-800">My Posts</h2>
          <button 
            @click="refreshPosts" 
            class="p-1.5 text-gray-500 hover:text-primary hover:bg-gray-100 rounded-full transition-colors"
            title="Refresh posts"
          >
            <Icon 
              name="heroicons:arrow-path" 
              size="16px"
              :class="{ 'animate-spin': isRefreshing }"
            />
          </button>
        </div>
        
        <div class="flex items-center gap-3 mt-2 sm:mt-0">
          <div class="relative">
            <select
              v-model="statusFilter"
              class="border border-gray-300 rounded-md py-1.5 pl-8 pr-8 text-sm bg-white shadow-sm focus:ring-2 focus:ring-primary/20 focus:border-primary appearance-none"
            >
              <option value="">All posts</option>
              <option value="pending">Pending review</option>
              <option value="active">Active</option>
              <option value="sold">Sold</option>
              <option value="expired">Expired</option>
            </select>
            <Icon 
              name="heroicons:funnel" 
              size="14px" 
              class="absolute left-2.5 top-1/2 transform -translate-y-1/2 text-gray-500"
            />
            <Icon 
              name="heroicons:chevron-down" 
              size="14px" 
              class="absolute right-2.5 top-1/2 transform -translate-y-1/2 text-gray-500 pointer-events-none"
            />
          </div>
          
          <button
            @click="$emit('create-post')"
            class="bg-primary hover:bg-primary/90 text-white text-sm px-4 py-1.5 rounded-md flex items-center gap-1.5 transition-all shadow-sm hover:shadow"
          >
            <Icon name="heroicons:plus-circle" size="16px" />
            New Post
          </button>
        </div>
      </div>

      <!-- Post items -->
      <div class="divide-y divide-gray-100">
        <div
          v-for="post in filteredPosts"
          :key="post.id"
          class="p-4 hover:bg-gray-50 transition-colors"
        >
          <div class="flex gap-4">
            <!-- Post image -->
            <NuxtLink
              :to="`/sale/${post.slug}`"
              class="relative w-20 h-20 sm:w-24 sm:h-24 flex-shrink-0 rounded-md overflow-hidden shadow-sm border border-gray-200"
            >
              <img
                v-if="post.main_image"
                :src="post.main_image"
                :alt="post.title"
                class="w-full h-full object-cover"
              />
              <div
                v-else
                class="w-full h-full bg-gray-200 flex items-center justify-center"
              >
                <Icon name="heroicons:photo" class="h-8 w-8 text-gray-400" />
              </div>

              <!-- Status badge -->
              <div class="absolute top-1 left-1">
                <span
                  :class="{
                    'bg-yellow-500': post.status === 'pending',
                    'bg-green-500': post.status === 'active',
                    'bg-blue-500': post.status === 'sold',
                    'bg-red-500': post.status === 'expired',
                  }"
                  class="text-white text-xs px-2 py-0.5 rounded-sm shadow-sm"
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
                    <h3 class="text-base font-medium line-clamp-1 text-gray-800 hover:text-primary transition-colors">
                      {{ post.title }}
                    </h3>
                  </NuxtLink>
                  <div class="mt-1 flex items-center text-sm text-gray-500 gap-1">
                    <Icon
                      name="heroicons:currency-bangladeshi"
                      class="h-4 w-4"
                    />
                    <span class="font-medium">{{
                      post.price ? `৳${post.price.toLocaleString()}` : "Negotiable"
                    }}</span>
                    <span class="mx-2">•</span>
                    <span>{{ formatDate(post.created_at) }}</span>
                  </div>
                  <div class="mt-1 flex items-center text-sm text-gray-500 gap-1">
                    <Icon name="heroicons:map-pin" class="h-4 w-4" />
                    <span class="line-clamp-1"
                      >{{ post.area }}, {{ post.district }}</span
                    >
                  </div>
                  <div class="mt-2 flex items-center text-xs text-gray-400 gap-3">
                    <span class="flex items-center gap-1">
                      <Icon name="heroicons:eye" class="h-3.5 w-3.5" />
                      {{ post.view_count }} views
                    </span>
                    <span v-if="post.condition" class="flex items-center gap-1">
                      <Icon name="heroicons:tag" class="h-3.5 w-3.5" />
                      {{ post.condition }}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Action buttons -->
            <div class="flex flex-col gap-3 items-end justify-between">
              <!-- Edit/Delete buttons -->
              <div class="flex gap-2">
                <button
                  @click="$emit('edit-post', post)"
                  class="p-1.5 text-gray-600 hover:text-primary hover:bg-gray-100 rounded-full transition-colors"
                  title="Edit post"
                >
                  <Icon name="heroicons:pencil-square" size="18px" />
                </button>
                <button
                  @click="confirmDelete(post.id, post.title)"
                  class="p-1.5 text-gray-600 hover:text-red-500 hover:bg-gray-100 rounded-full transition-colors"
                  title="Delete post"
                >
                  <Icon name="heroicons:trash" size="18px" />
                </button>
              </div>
              
              <!-- Mark as Sold button with states -->
              <button
                v-if="post.status !== 'sold'"
                @click="markAsSold(post.id)"
                :disabled="markingSold === post.id"
                class="flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-md transition-all shadow-sm"
                :class="[
                  markingSold === post.id 
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed' 
                    : 'bg-blue-50 text-blue-600 hover:bg-blue-100 hover:shadow'
                ]"
              >
                <Icon 
                  :name="markingSold === post.id ? 'heroicons:clock' : 'heroicons:tag'" 
                  size="16px" 
                  class="flex-shrink-0" 
                />
                {{ markingSold === post.id ? 'Processing...' : 'Mark as Sold' }}
              </button>
              
              <!-- Sold status indicator -->
              <div 
                v-else
                class="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-green-50 text-green-600 rounded-md shadow-sm"
              >
                <Icon name="heroicons:check-circle" size="16px" class="flex-shrink-0" />
                Sold
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty filtered state -->
      <div v-if="posts.length > 0 && filteredPosts.length === 0" class="py-8 text-center">
        <div class="mb-3">
          <Icon name="heroicons:face-frown" class="h-12 w-12 text-gray-300 mx-auto" />
        </div>
        <h3 class="text-gray-600 font-medium">No matching posts found</h3>
        <p class="text-gray-500 mt-1">There are no posts with the "{{ statusFilter }}" status.</p>
        <button 
          @click="statusFilter = ''" 
          class="mt-4 px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-700 text-sm rounded-md transition-colors"
        >
          Show all posts
        </button>
      </div>

      <!-- Load more button -->
      <div v-if="hasMorePosts" class="p-4 border-t border-gray-100 text-center">
        <button
          @click="loadMorePosts"
          class="px-5 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors shadow-sm"
          :disabled="isLoadingMore"
        >
          <span v-if="isLoadingMore" class="flex items-center gap-2 justify-center">
            <span class="inline-block h-4 w-4 border-2 border-t-2 border-gray-300 border-t-primary rounded-full animate-spin"></span>
            Loading more posts...
          </span>
          <span v-else class="flex items-center gap-2 justify-center">
            <Icon name="heroicons:arrow-down" size="16px" />
            Load more posts
          </span>
        </button>
      </div>
    </div>

    <!-- Delete confirmation modal -->
    <div v-if="showDeleteModal" class="fixed inset-0 z-50 overflow-y-auto">
      <div
        class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
        ></div>

        <div
          class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div
                class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10"
              >
                <Icon
                  name="heroicons:exclamation-triangle"
                  class="h-6 w-6 text-red-600"
                />
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <h3 class="text-lg leading-6 font-medium text-gray-900">
                  Delete Post
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">
                    Are you sure you want to delete "{{ postToDeleteTitle }}"?
                    This action cannot be undone.
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none sm:ml-3 sm:w-auto sm:text-sm"
              @click="deletePost"
            >
              Delete
            </button>
            <button
              type="button"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
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

const { get, post, del } = useApi();
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
    const response = await get(`/sale/posts/`, {}, {
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
    const response = await get(`/sale/posts/`, {}, {
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
    const response = await post(`/sale/posts/${postId}/mark_as_sold/`, {}, {
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      }
    });

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
      });
    }
  } catch (error) {
    console.error("Error marking post as sold:", error);
    
    // Show appropriate error message based on the error
    let errorMessage = "Failed to mark post as sold. Please try again later.";
    
    if (error.response) {
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
    await del(`/sale/posts/${postToDeleteId.value}/`);

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

/* Add a subtle hover effect for post items */
.my-posts-container {
  max-width: 3xl;
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
</style>
