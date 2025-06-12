<template>  <PublicSection>
    <div class="bg-white rounded-xl shadow-sm max-w-3xl mx-auto overflow-hidden border border-gray-100">
      <div class="mx-auto max-w-7xl">        
        <!-- Enhanced Header -->
        <div class="text-center mb-10">
          <h1
            class="text-2xl font-semibold mb-2 bg-gradient-to-r from-emerald-500 to-green-600 bg-clip-text text-transparent"
          >
            Manage Your Sale Posts
          </h1>
          <p class="text-lg text-gray-600 max-w-lg mx-auto mb-4">
            View, edit, and manage all your sale listings in one place
          </p>
          <UButton
            @click="navigateToMarketplace"
            color="emerald"
            variant="outline"
            size="sm"
          >
            <template #leading>
              <UIcon name="i-heroicons-shopping-bag" />
            </template>
            Go to Marketplace          
        </UButton>
        </div>          <!-- Quick Stats -->
        <div v-if="activeTab === 'my-posts'" class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div class="bg-white rounded-lg p-4 border border-gray-100">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <UIcon name="i-heroicons-document-text" class="h-6 w-6 text-blue-600" />
              </div>
              <div class="ml-3">
                <p class="text-sm font-medium text-gray-900">Total Posts</p>
                <p class="text-lg font-semibold text-blue-600">{{ stats.total || 0 }}</p>
              </div>
            </div>
          </div>
          
          <div class="bg-white rounded-lg p-4 border border-gray-100">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <UIcon name="i-heroicons-eye" class="h-6 w-6 text-green-600" />
              </div>
              <div class="ml-3">
                <p class="text-sm font-medium text-gray-900">Active</p>
                <p class="text-lg font-semibold text-green-600">{{ stats.active || 0 }}</p>
              </div>
            </div>
          </div>
          
          <div class="bg-white rounded-lg p-4 border border-gray-100">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <UIcon name="i-heroicons-check-circle" class="h-6 w-6 text-emerald-600" />
              </div>
              <div class="ml-3">
                <p class="text-sm font-medium text-gray-900">Sold</p>
                <p class="text-lg font-semibold text-emerald-600">{{ stats.sold || 0 }}</p>
              </div>
            </div>
          </div>
          
          <div class="bg-white rounded-lg p-4 border border-gray-100">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <UIcon name="i-heroicons-clock" class="h-6 w-6 text-amber-600" />
              </div>
              <div class="ml-3">
                <p class="text-sm font-medium text-gray-900">Pending</p>
                <p class="text-lg font-semibold text-amber-600">{{ stats.pending || 0 }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Tabs Navigation -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
          <div class="border-b border-gray-200">
            <nav class="flex space-x-8" aria-label="Tabs">
              <button
                v-for="tab in tabs"
                :key="tab.id"
                @click="activeTab = tab.id"
                :class="[
                  activeTab === tab.id
                    ? 'border-emerald-500 text-emerald-600 bg-emerald-50'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
                  'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-all duration-200 rounded-t-lg'
                ]"
              >
                <div class="flex items-center gap-2">
                  <UIcon :name="tab.icon" class="w-4 h-4" />
                  {{ tab.name }}
                  <span
                    v-if="tab.id === 'my-posts' && myPostsCount > 0"
                    class="bg-emerald-100 text-emerald-800 text-xs font-medium px-2 py-0.5 rounded-full"
                  >
                    {{ myPostsCount }}
                  </span>
                </div>
              </button>
            </nav>
          </div>

          <!-- Tab Content -->
          <div>              
            <!-- My Posts Tab -->
            <div v-if="activeTab === 'my-posts'">
              <MyPosts
                @create-post="activeTab = 'post-sale'"
                @edit-post="handleEditPost"
                @delete-post="handleDeletePost"
                @posts-updated="updatePostsCount"
              />
            </div>            
            <!-- Post Sale Tab -->
            <div v-if="activeTab === 'post-sale'">
              <!-- Embed the Post Sale Form -->
              <SalePostForm @post-created="handlePostCreated" />
            </div>          </div>
        </div>
      </div>
    </div>
  </PublicSection>
</template>

<script setup>
import MyPosts from "~/components/sale/MyPosts.vue";
import SalePostForm from "~/components/sale/SalePostForm.vue";

// Middleware
definePageMeta({
  middleware: "auth",
});

// State
const activeTab = ref('my-posts');
const refreshing = ref(false);
const myPostsCount = ref(0);
const stats = ref({
  total: 0,
  active: 0,
  sold: 0,
  pending: 0
});

// Tabs configuration
const tabs = [
  {
    id: 'my-posts',
    name: 'My Posts',
    icon: 'i-heroicons-document-text'
  },
  {
    id: 'post-sale',
    name: 'Post a Sale',
    icon: 'i-heroicons-plus-circle'
  }
];

// Check URL params for initial tab
const route = useRoute();
if (route.query.tab) {
  const tabExists = tabs.find(tab => tab.id === route.query.tab);
  if (tabExists) {
    activeTab.value = route.query.tab;
  }
}

// Methods
const refreshPosts = async () => {
  refreshing.value = true;
  // Trigger refresh in MyPosts component
  await nextTick();
  setTimeout(() => {
    refreshing.value = false;
  }, 1000);
};

const handleEditPost = (post) => {
  // Navigate to edit page
  navigateTo(`/sale/edit/${post.slug}`);
};

const handleDeletePost = (postId) => {
  console.log("Delete post with ID:", postId);
  // Refresh stats after deletion
  updatePostsCount();
};

const handlePostCreated = (post) => {
  console.log("Post created:", post);
  // Switch to my posts tab and refresh
  activeTab.value = 'my-posts';
  updatePostsCount();
  
  // Show success message
  const toast = useToast();
  toast.add({
    title: "Success!",
    description: "Your listing has been posted successfully.",
    color: "green",
  });
};

const updatePostsCount = (postsData) => {
  if (postsData) {
    myPostsCount.value = postsData.length;
    
    // Calculate stats
    stats.value = {
      total: postsData.length,
      active: postsData.filter(p => p.status === 'active').length,
      sold: postsData.filter(p => p.status === 'sold').length,
      pending: postsData.filter(p => p.status === 'pending').length,
    };
  }
};

const navigateToMarketplace = () => {
  navigateTo('/sale');
};

// Watch active tab and update URL
watch(activeTab, (newTab) => {
  const router = useRouter();
  router.push({ query: { tab: newTab } });
});

// SEO
useHead({
  title: "My Sale Posts - Manage Your Listings",
  meta: [
    {
      name: "description",
      content: "Manage your sale listings, post new items, and track your selling activity.",
    },
  ],
});
</script>

<style scoped>
/* Custom tab styles */
.tab-active {
  background: linear-gradient(to right, #10b981, #059669);
}

/* Animation for tab switching */
.tab-content {
  animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
