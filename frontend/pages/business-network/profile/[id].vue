<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl pt-3 flex-1 bg-gradient">
    <!-- Skeleton loader for the entire profile page -->
    <template v-if="isLoading">
      <div class="max-w-3xl mx-auto relative z-10 sm:px-0">
        <!-- Skeleton for Profile Card -->
        <div
          class="bg-white/90 backdrop-blur-sm rounded-xl shadow-sm border border-gray-200/50 mb-6 animate-pulse"
        >
          <div class="p-4 sm:p-5">
            <!-- Using ProfileHeader component's skeleton UI -->
            <ProfileHeader :isLoading="true" />
          </div>
        </div>

        <!-- Skeleton for Tabs Section -->
        <div
          class="bg-white/90 backdrop-blur-sm rounded-xl shadow-sm border border-gray-200/50 overflow-hidden"
        >
          <!-- Tabs Skeleton -->
          <div class="border-b border-gray-200">
            <div class="flex items-center">
              <div class="h-10 w-20 bg-gray-200 rounded m-2"></div>
              <div class="h-10 w-20 bg-gray-200 rounded m-2"></div>
              <div class="h-10 w-20 bg-gray-200 rounded m-2"></div>
            </div>
          </div>

          <!-- Tab Content Skeleton -->
          <div class="py-4">
            <div class="px-2">
              <!-- Skeleton loaders for posts -->
              <div
                v-for="i in 2"
                :key="i"
                class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4"
              >
                <div class="flex items-center space-x-3 mb-4">
                  <div
                    class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"
                  ></div>
                  <div class="flex-1 space-y-2">
                    <div
                      class="h-4 bg-gray-200 rounded animate-pulse w-1/4"
                    ></div>
                    <div
                      class="h-3 bg-gray-200 rounded animate-pulse w-1/5"
                    ></div>
                  </div>
                </div>
                <div class="space-y-2 mb-4">
                  <div
                    class="h-4 bg-gray-200 rounded animate-pulse w-3/4"
                  ></div>
                  <div
                    class="h-3 bg-gray-200 rounded animate-pulse w-full"
                  ></div>
                  <div
                    class="h-3 bg-gray-200 rounded animate-pulse w-5/6"
                  ></div>
                </div>
                <div class="h-40 bg-gray-200 rounded animate-pulse mb-4"></div>
                <div class="flex justify-between">
                  <div
                    class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                  ></div>
                  <div
                    class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                  ></div>
                  <div
                    class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Actual profile content -->
    <div v-else class="mx-auto pb-8 animation-fade-in">
      <!-- Complete Profile Page Component -->
      <ProfilePage
        :user="user"
        :currentUser="currentUser"
        :isFollowing="isFollowing"
        :followLoading="followLoading"
        :showProfilePhotoMenu="showProfilePhotoMenu"
        :tabs="tabs"
        :activeTab="activeTab"
        :isLoadingPosts="isLoadingPosts"
        :loadingMorePosts="loadingMorePosts"
        :posts="posts"
        :isLoadingMedia="isLoadingMedia"
        :allMedia="allMedia"
        :isLoadingSaved="isLoadingSaved"
        :savedPosts="savedPosts"
        @open-qr-modal="openQrCodeModal"
        @toggle-follow="toggleFollow"
        @open-profile-photo-modal="openProfilePhotoModal"
        @toggle-profile-photo-menu="toggleProfilePhotoMenu"
        @open-followers-modal="openFollowersModal"
        @show-diamond-modal="showDiamondModal = true"
        @switch-tab="switchTab"
        @scroll-to-top="scrollToTop"
      />
    </div>

    <!-- Modals -->
    <BusinessNetworkDiamondPurchaseModal
      :modelValue="showDiamondModal"
      @close="showDiamondModal = false"
    />

    <!-- Profile Photo Modal -->
    <MediaViewer
      v-if="showMediaViewer"
      :activeMedia="profilePhotoMedia"
      :user="currentUser"
      :profileMode="true"
      :profileUser="user"
      @close-media="closeProfilePhotoModal"
    />

    <!-- Followers/Following Modal -->
    <FollowersModal
      :show="showFollowersModal"
      :userId="route.params.id"
      :initialTab="activeFollowersTab"
      :followersCount="user?.followers_count || 0"
      :followingCount="user?.following_count || 0"
      @close="showFollowersModal = false"
      @follow-changed="handleFollowStatusChange"
    />

    <!-- QR Code Modal -->
    <ProfileQrCodeModal
      :modelValue="showQrModal"
      :user="user"
      @update:modelValue="showQrModal = $event"
      @close="showQrModal = false"
    />
  </div>
</template>

<script setup>
definePageMeta({
  layout: "adsy-business-network",
});

import BusinessNetworkDiamondPurchaseModal from "~/components/business-network/DiamondPurchaseModal.vue";
import MediaViewer from "~/components/business-network/MediaViewer.vue";
import FollowersModal from "~/components/business-network/FollowersModal.vue";
import ProfilePage from "~/components/business-network/profile/ProfilePage.vue";
import ProfileHeader from "~/components/business-network/profile/sections/ProfileHeader.vue";
import ProfileQrCodeModal from "~/components/business-network/profile/ProfileQrCodeModal.vue";
import { useApi } from "~/composables/useApi";

const route = useRoute();
const router = useRouter();
const toast = useToast();
const { get, post, del } = useApi(); // Initialize API functions

const { user: currentUser } = useAuth();

// QR code related variables
const showQrModal = ref(false);

// Event bus
const eventBus = useEventBus();

// Always start with loading state to show skeleton immediately
const isLoading = ref(true);
const isLoadingPosts = ref(true);
const isLoadingMedia = ref(true);
const isLoadingSaved = ref(true);
const loadingMorePosts = ref(false);
const hasMorePosts = ref(true);
const currentPage = ref(1);
const postsPerPage = ref(10);
const loadedPostIds = ref(new Set()); // Track loaded post IDs to prevent duplicates

// Initialize other reactive state
const user = ref({});
const posts = ref({});
const savedPosts = ref([]);
const allMedia = ref([]);
const followLoading = ref(false);
const isFollowing = ref(false);
const showDiamondModal = ref(false);
const showFollowersModal = ref(false);
const activeFollowersTab = ref("followers");
const showProfilePhotoMenu = ref(false);
const showProfilePhotoModal = ref(false);

// Profile photo for MediaViewer
const profilePhotoMedia = ref(null);
const showMediaViewer = ref(false);

// Toggle profile photo menu
const cameraButtonRef = ref(null);

const toggleProfilePhotoMenu = (event) => {
  // Toggle the menu state
  showProfilePhotoMenu.value = !showProfilePhotoMenu.value;

  // Add click event listener to handle clicks outside the menu
  if (showProfilePhotoMenu.value) {
    // Use nextTick to ensure the DOM is updated before adding the event listener
    nextTick(() => {
      document.addEventListener("click", closeMenuOnClickOutside);
    });
  } else {
    document.removeEventListener("click", closeMenuOnClickOutside);
  }

  // Stop event propagation to prevent immediate closing
  if (event) {
    event.stopPropagation();
  }
};

// Close menu when clicking outside
const closeMenuOnClickOutside = (event) => {
  // Check if the click was outside both the menu and the button
  const menuElement = document.querySelector(".profile-photo-menu");
  const buttonElement = cameraButtonRef.value?.$el || cameraButtonRef.value;

  if (
    menuElement &&
    !menuElement.contains(event.target) &&
    buttonElement &&
    !buttonElement.contains(event.target)
  ) {
    showProfilePhotoMenu.value = false;
    document.removeEventListener("click", closeMenuOnClickOutside);
  }
};

// Open profile photo modal
const openProfilePhotoModal = (event) => {
  if (event) {
    event.stopPropagation(); // Prevent the click from closing the menu
  }

  // Create a media object for the profile photo
  profilePhotoMedia.value = {
    image: user.value?.image || "/static/frontend/images/placeholder.jpg",
    type: "image",
    id: user.value?.id || "profile",
  };

  showMediaViewer.value = true;
  showProfilePhotoMenu.value = false; // Close the menu

  // Remove document click listener
  document.removeEventListener("click", closeMenuOnClickOutside);
};

// Close profile photo modal
const closeProfilePhotoModal = () => {
  showMediaViewer.value = false;
};

// Define data loading functions
async function checkFollowing() {
  if (!currentUser.value) return;
  try {
    const { data } = await get(
      `/bn/check-follow-status/${currentUser.value?.user?.id}/${route.params.id}/`
    );
    isFollowing.value = data.is_following;
  } catch (error) {
    console.error(error);
  }
}

async function fetchUser() {
  try {
    const { data } = await get(`/user/${route.params.id}/`);
    user.value = {
      ...data,
      // Standardize the follower/following count properties
      followers_count: data.followers_count || data.follower_count || 0,
      following_count: data.following_count || data.follow_count || 0,
      post_count: data.post_count || 0,
      // Social media fields
      facebook_url: data.facebook_url || null,
      whatsapp: data.whatsapp || null,
      linkedin_url: data.linkedin_url || null,
      twitter_url: data.twitter_url || null,
      // Other properties are preserved
    };
  } catch (error) {
    console.error(error);
  } finally {
    // Add a minimum loading time for better UX
    setTimeout(() => {
      isLoading.value = false;
    }, 800);
  }
}

async function fetchUserPosts(loadMore = false) {
  try {
    if (loadMore) {
      loadingMorePosts.value = true;
    } else {
      isLoadingPosts.value = true;
      currentPage.value = 1;
      loadedPostIds.value.clear(); // Clear tracked IDs on initial load
    }

    // Build params for pagination
    const params = {
      page: currentPage.value,
      page_size: postsPerPage.value,
    };

    const res = await get(`/bn/user/${route.params.id}/posts/`, { params });

    if (loadMore) {
      // Append new posts to existing ones
      if (
        posts.value?.results &&
        Array.isArray(posts.value.results) &&
        res.data?.results &&
        Array.isArray(res.data.results)
      ) {
        // Filter out any duplicates based on post ID
        const newPosts = res.data.results.filter(
          (post) => !loadedPostIds.value.has(post.id)
        );

        // Add new post IDs to our tracking Set
        newPosts.forEach((post) => loadedPostIds.value.add(post.id));

        // Update posts with combined unique results
        posts.value = {
          ...res.data,
          results: [...posts.value.results, ...newPosts],
        };

        // If we filtered out all posts as duplicates, show end of feed
        if (newPosts.length === 0 && res.data.results.length > 0) {
          hasMorePosts.value = false;
        }
      } else {
        // Initial set of posts when loading more
        if (res.data?.results) {
          res.data.results.forEach((post) => loadedPostIds.value.add(post.id));
        }
        posts.value = res.data;
      }
    } else {
      // Initial load - replace existing posts
      if (res.data?.results) {
        // Clear tracking and add all new posts
        loadedPostIds.value.clear();
        res.data.results.forEach((post) => loadedPostIds.value.add(post.id));
      }
      posts.value = res.data;
    }

    // Check if we have more posts to load
    hasMorePosts.value = !!res.data.next;

    // If we didn't get any posts in a load more request, we're at the end
    if (loadMore && (!res.data.results || res.data.results.length === 0)) {
      hasMorePosts.value = false;
    }
  } catch (error) {
    console.error("Error fetching user posts:", error);

    toast.add({
      title: "Error",
      description: "Failed to load posts",
      color: "red",
      timeout: 3000,
    });
  } finally {
    isLoadingPosts.value = false;
    loadingMorePosts.value = false;
  }
}

// Load more posts
function loadMorePosts() {
  if (!hasMorePosts.value || loadingMorePosts.value || isLoadingPosts.value)
    return;

  currentPage.value++;
  fetchUserPosts(true);
}

// Setup scroll detection for infinite scroll
function setupInfiniteScroll() {
  // Create a global flag to track if we've reached the end of feed
  // Using a ref ensures this state persists properly
  const endOfFeedReached = ref(false);

  const handleScroll = () => {
    if (activeTab.value !== "posts") return;
    if (endOfFeedReached.value) {
      // If we already know we're at the end, don't do anything
      return;
    }

    // Check if we're at or near the bottom of the page
    if (
      window.innerHeight + window.scrollY >=
      document.body.offsetHeight - 200
    ) {
      // Stop further API calls if we're already at the end (no more posts OR we've already seen the "all caught up" message)
      if (!hasMorePosts.value) {
        endOfFeedReached.value = true;
        return;
      }

      // Otherwise, try loading more posts if not currently loading
      if (!loadingMorePosts.value && !isLoadingPosts.value) {
        loadMorePosts();
      }
    }
  };

  window.addEventListener("scroll", handleScroll);

  // Remove event listener on component unmount
  onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
  });
}

async function fetchUserSavedPosts() {
  try {
    const res = await get(`/bn/posts/save/`);
    savedPosts.value = res.data;
  } catch (error) {
    console.error(error);
  } finally {
    isLoadingSaved.value = false;
  }
}

// Load data when component is created
function loadAllData() {
  // Start with loading states set to true
  isLoading.value = true;
  isLoadingPosts.value = true;
  isLoadingMedia.value = true;
  isLoadingSaved.value = true;
  loadingMorePosts.value = false;
  hasMorePosts.value = true;
  currentPage.value = 1;

  // Fetch all data in parallel
  Promise.all([
    fetchUser(),
    fetchUserPosts(),
    currentUser.value ? fetchUserSavedPosts() : Promise.resolve(),
    currentUser.value && route.params.id ? checkFollowing() : Promise.resolve(),
  ]);

  // Simulate loading media items
  setTimeout(() => {
    allMedia.value = Array(16)
      .fill()
      .map((_, i) => ({
        thumbnail: `https://picsum.photos/500/500?random=${i + 1}`,
        url: `https://picsum.photos/1200/900?random=${i + 1}`,
      }));
    isLoadingMedia.value = false;
  }, 1500);
}

// Existing view mode and tab states
const viewMode = ref("list");
const activeTab = ref("posts");
const isEditProfileOpen = ref(false);
const isEditPhotoOpen = ref(false);
const isEditCoverOpen = ref(false);

const tabs = computed(() =>
  currentUser.value?.user?.id && currentUser.value?.user?.id === route.params.id
    ? [
        { label: "Posts", value: "posts" },
        // { label: "Media", value: "media" },
        { label: "Saved", value: "saved" },
      ]
    : [
        { label: "Posts", value: "posts" },
        // { label: "Media", value: "media" },
      ]
);

// Open QR code modal
const openQrCodeModal = () => {
  showQrModal.value = true;
};

// Toggle follow action
const toggleFollow = async () => {
  if (followLoading.value) return;

  followLoading.value = true;
  const wasFollowing = isFollowing.value;

  // Optimistic UI update
  isFollowing.value = !wasFollowing;

  try {
    if (!wasFollowing) {
      // Follow user
      const { data } = await post(`/bn/users/${route.params.id}/follow/`);

      if (data) {
        // Update followers count accordingly
        user.value.followers_count = (user.value.followers_count || 0) + 1;
      }
    } else {
      // Unfollow user
      const res = await del(`/bn/users/${route.params.id}/unfollow/`);

      if (res.data === undefined) {
        // Update followers count accordingly
        user.value.followers_count = Math.max(
          0,
          (user.value.followers_count || 0) - 1
        );
      }
    }
  } catch (error) {
    console.error("Error toggling follow:", error);
    // Revert state on error
    isFollowing.value = wasFollowing;
  } finally {
    followLoading.value = false;
  }
};

// Open the followers/following modal
const openFollowersModal = (tab) => {
  activeFollowersTab.value = tab;
  showFollowersModal.value = true;
};

// Handle follow status change from the modal
const handleFollowStatusChange = ({ userId, isFollowing: newFollowStatus }) => {
  // If the user changed is the profile user, update their followers count
  if (userId === route.params.id) {
    if (newFollowStatus) {
      // User was followed
      user.value.followers_count = (user.value.followers_count || 0) + 1;
      isFollowing.value = true;
    } else {
      // User was unfollowed
      user.value.followers_count = Math.max(
        0,
        (user.value.followers_count || 0) - 1
      );
      isFollowing.value = false;
    }
  }
};

// Animation when switching tabs
const switchTab = (tabValue) => {
  if (activeTab.value === tabValue) return;

  // Apply animation class and change tab
  activeTab.value = tabValue;
};

// Format time ago function
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${Math.abs(diffInSeconds)} ${
      diffInSeconds === 1 ? "second" : "seconds"
    } ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${Math.abs(diffInMinutes)} ${
      diffInMinutes === 1 ? "minute" : "minutes"
    } ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${Math.abs(diffInHours)} ${
      diffInHours === 1 ? "hour" : "hours"
    } ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${Math.abs(diffInDays)} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${Math.abs(diffInMonths)} ${
    diffInMonths === 1 ? "month" : "months"
  } ago`;
};

// Watch for route changes
watch(
  () => route.params.id,
  (newId, oldId) => {
    if (newId !== oldId) {
      // Always reset loading states when route changes
      isLoading.value = true;
      isLoadingPosts.value = true;
      isLoadingMedia.value = true;
      isLoadingSaved.value = true;

      // Load fresh data
      loadAllData();
    }
  },
  { immediate: false }
);

// Lifecycle hooks
onMounted(() => {
  // Register event listeners
  eventBus.on("post-created", (newPost) => {
    // Only update if this is the author's profile
    if (newPost.author?.id === route.params.id) {
      // Add the new post to the beginning of the array
      if (posts.value?.results && Array.isArray(posts.value.results)) {
        posts.value.results.unshift(newPost);
      }

      // Update post count
      user.value.post_count = (user.value.post_count || 0) + 1;
    }
  });

  // Load data on mount (with skeleton already showing)
  loadAllData();

  // Setup infinite scroll
  setupInfiniteScroll();

  // Clean up event listener on unmount
  onUnmounted(() => {
    eventBus.off("post-created");
    eventBus.off("start-loading-profile");
  });
});

// Scroll to top function
const scrollToTop = () => {
  window.scrollTo({
    top: 0,
    behavior: "smooth",
  });
};
</script>

<style scoped>
/* Enhanced background and styling */
.bg-gradient {
  background: linear-gradient(
    135deg,
    rgba(241, 245, 249, 0.8),
    rgba(248, 250, 252, 0.8),
    rgba(241, 245, 249, 0.8)
  );
  background-size: 200% 200%;
  animation: gradientBackground 15s ease infinite;
}

@keyframes gradientBackground {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

/* Tab transitions */
.tab-transition-enter-active,
.tab-transition-leave-active {
  transition: opacity 0.4s, transform 0.4s;
}

.tab-transition-enter-from,
.tab-transition-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* Animation for skeleton loading */
@keyframes pulse {
  0%,
  100% {
    opacity: 0.6;
  }
  50% {
    opacity: 1;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Fade in animation */
.animation-fade-in {
  animation: fadeIn 0.5s ease-out;
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
