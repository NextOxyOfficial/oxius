<template>
  <div class="my-posts-container">
    <!-- Empty state with create button -->
    <div v-if="!posts.length && !isLoading" class="text-center py-10">
      <div class="mb-6">
        <div class="flex justify-center">
          <div class="p-4 bg-gray-100 rounded-full inline-block">
            <Icon name="heroicons:clipboard-document-list" class="h-10 w-10 text-gray-500" />
          </div>
        </div>
        <h3 class="text-lg font-semibold mt-4">No posts yet</h3>
        <p class="text-gray-600 mt-1">Create your first post to start selling!</p>
      </div>
      <button
        @click="$emit('create-post')"
        class="bg-primary hover:bg-primary/90 text-white font-medium px-5 py-2 rounded-md flex items-center gap-2 mx-auto"
      >
        <Icon name="heroicons:plus-circle" size="18px" />
        Create Post
      </button>
    </div>

    <!-- Loading state -->
    <div v-else-if="isLoading" class="p-6">
      <div v-for="i in 3" :key="i" class="mb-4 animate-pulse">
        <div class="flex items-center gap-4">
          <div class="w-16 h-16 bg-gray-200 rounded"></div>
          <div class="flex-1">
            <div class="h-5 bg-gray-200 rounded mb-2 w-3/4"></div>
            <div class="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
          <div class="flex gap-2">
            <div class="w-8 h-8 bg-gray-200 rounded"></div>
            <div class="w-8 h-8 bg-gray-200 rounded"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Post listing -->
    <div v-else>
      <!-- Filters and controls -->
      <div class="flex justify-between mb-4">
        <div class="flex items-center">
          <select
            v-model="statusFilter"
            class="border border-gray-300 rounded-md py-1 px-2 text-sm"
          >
            <option value="">All posts</option>
            <option value="pending">Pending review</option>
            <option value="active">Active</option>
            <option value="sold">Sold</option>
            <option value="expired">Expired</option>
          </select>
        </div>
        <button
          @click="$emit('create-post')"
          class="bg-primary hover:bg-primary/90 text-white text-sm px-3 py-1 rounded-md flex items-center gap-1"
        >
          <Icon name="heroicons:plus-circle" size="16px" />
          New Post
        </button>
      </div>

      <!-- Post items -->
      <div class="divide-y divide-gray-200">
        <div v-for="post in filteredPosts" :key="post.id" class="py-4 flex gap-4">
          <!-- Post image -->
          <NuxtLink :to="`/sale/${post.slug}`" class="relative w-16 h-16 sm:w-20 sm:h-20 flex-shrink-0">
            <img
              v-if="post.main_image"
              :src="post.main_image"
              :alt="post.title"
              class="w-full h-full object-cover rounded-md"
            />
            <div v-else class="w-full h-full bg-gray-200 rounded-md flex items-center justify-center">
              <Icon name="heroicons:photo" class="h-8 w-8 text-gray-400" />
            </div>
            
            <!-- Status badge -->
            <div class="absolute top-0 left-0">
              <span
                :class="{
                  'bg-yellow-500': post.status === 'pending',
                  'bg-green-500': post.status === 'active',
                  'bg-blue-500': post.status === 'sold',
                  'bg-red-500': post.status === 'expired'
                }"
                class="text-white text-xs px-2 py-0.5 rounded-sm"
              >
                {{ formatStatus(post.status) }}
              </span>
            </div>
          </NuxtLink>

          <!-- Post details -->
          <div class="flex-1 min-w-0">
            <NuxtLink :to="`/sale/${post.slug}`">
              <h3 class="text-base font-medium line-clamp-1">{{ post.title }}</h3>
            </NuxtLink>
            <div class="mt-1 flex items-center text-sm text-gray-500">
              <Icon name="heroicons:currency-bangladeshi" class="h-4 w-4 mr-1" />
              <span>{{ post.price ? `৳${post.price.toLocaleString()}` : 'Negotiable' }}</span>
              <span class="mx-2">•</span>
              <span>{{ formatDate(post.created_at) }}</span>
            </div>
            <div class="mt-1 flex items-center text-sm text-gray-500">
              <Icon name="heroicons:map-pin" class="h-4 w-4 mr-1" />
              <span class="line-clamp-1">{{ post.area }}, {{ post.district }}</span>
            </div>
          </div>

          <!-- Action buttons -->
          <div class="flex flex-col gap-2 items-end">
            <div class="flex gap-2">
              <button
                @click="$emit('edit-post', post)"
                class="p-1.5 text-gray-600 hover:text-primary hover:bg-gray-100 rounded-full transition-colors"
                title="Edit post"
              >
                <Icon name="heroicons:pencil-square" size="18px" />
              </button>
              <button
                v-if="post.status !== 'sold'"
                @click="markAsSold(post.id)"
                class="p-1.5 text-gray-600 hover:text-blue-500 hover:bg-gray-100 rounded-full transition-colors"
                title="Mark as sold"
              >
                <Icon name="heroicons:tag" size="18px" />
              </button>
              <button
                @click="confirmDelete(post.id, post.title)"
                class="p-1.5 text-gray-600 hover:text-red-500 hover:bg-gray-100 rounded-full transition-colors"
                title="Delete post"
              >
                <Icon name="heroicons:trash" size="18px" />
              </button>
            </div>
            <div class="text-xs text-gray-500">
              {{ post.view_count }} views
            </div>
          </div>
        </div>
      </div>

      <!-- Load more button -->
      <div v-if="hasMorePosts" class="mt-6 text-center">
        <button
          @click="loadMorePosts"
          class="px-4 py-2 border border-gray-300 rounded-md text-gray-600 hover:bg-gray-50"
          :disabled="isLoadingMore"
        >
          <span v-if="isLoadingMore">Loading...</span>
          <span v-else>Load more</span>
        </button>
      </div>
    </div>

    <!-- Delete confirmation modal -->
    <div v-if="showDeleteModal" class="fixed inset-0 z-50 overflow-y-auto">
      <div
        class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center"
      >
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>

        <div
          class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div
                class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10"
              >
                <Icon name="heroicons:exclamation-triangle" class="h-6 w-6 text-red-600" />
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <h3 class="text-lg leading-6 font-medium text-gray-900">
                  Delete Post
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">
                    Are you sure you want to delete "{{ postToDeleteTitle }}"? This action cannot be undone.
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

const { get, post, deleteReq } = useApi();
const { user } = useAuth();
const { showNotification } = useNotifications();

const emit = defineEmits(['create-post', 'edit-post', 'delete-post']);

// State
const posts = ref([]);
const isLoading = ref(true);
const isLoadingMore = ref(false);
const statusFilter = ref("");
const currentPage = ref(1);
const hasMorePosts = ref(false);
const pagination = ref(null);

// Delete confirmation state
const showDeleteModal = ref(false);
const postToDeleteId = ref(null);
const postToDeleteTitle = ref("");

// Filter posts based on status
const filteredPosts = computed(() => {
  if (!statusFilter.value) {
    return posts.value;
  }
  return posts.value.filter(post => post.status === statusFilter.value);
});

// Format status for display
const formatStatus = (status) => {
  switch(status) {
    case 'pending': return 'Pending';
    case 'active': return 'Active';
    case 'sold': return 'Sold';
    case 'expired': return 'Expired';
    default: return status;
  }
};

// Format date for display
const formatDate = (dateString) => {
  if (!dateString) return '';
  
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays <= 1) {
    return 'Today';
  } else if (diffDays <= 2) {
    return 'Yesterday';
  } else if (diffDays <= 7) {
    return `${diffDays} days ago`;
  } else {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
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
    const response = await get(`/sale/posts/my_posts/?page=${page}`);
    
    if (response.data) {
      if ('results' in response.data) {
        // Paginated response
        pagination.value = {
          count: response.data.count,
          next: response.data.next,
          previous: response.data.previous
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
      type: "error"
    });
  } finally {
    isLoading.value = false;
    isLoadingMore.value = false;
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
  try {
    const response = await post(`/sale/posts/${postId}/mark_as_sold/`);
    
    if (response.data) {
      // Update post in the local state
      const postIndex = posts.value.findIndex(p => p.id === postId);
      if (postIndex !== -1) {
        posts.value[postIndex].status = 'sold';
      }
      
      showNotification({
        title: "Success",
        message: "Post has been marked as sold!",
        type: "success"
      });
    }
  } catch (error) {
    console.error("Error marking post as sold:", error);
    showNotification({
      title: "Error",
      message: "Failed to mark post as sold. Please try again later.",
      type: "error"
    });
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
    await deleteReq(`/sale/posts/${postToDeleteId.value}/`);
    
    // Remove post from local state
    posts.value = posts.value.filter(p => p.id !== postToDeleteId.value);
    
    // Emit event
    emit('delete-post', postToDeleteId.value);
    
    showNotification({
      title: "Success",
      message: "Post deleted successfully!",
      type: "success"
    });
  } catch (error) {
    console.error("Error deleting post:", error);
    showNotification({
      title: "Error",
      message: "Failed to delete post. Please try again later.",
      type: "error"
    });
  } finally {
    showDeleteModal.value = false;
    postToDeleteId.value = null;
    postToDeleteTitle.value = "";
  }
};

// Watch for user change to reload posts
watch(() => user.value?.id, (newId) => {
  if (newId) {
    fetchPosts();
  }
});

// Load posts on component mount
onMounted(() => {
  if (user.value?.id) {
    fetchPosts();
  }
});
</script>

<style scoped>
.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}
</style>
