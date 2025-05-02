<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 pt-3 flex-1 bg-gradient">
    <div class="max-w-3xl mx-auto relative z-10 sm:px-0">
      <!-- Professional Profile Card -->
      <div class="bg-white/90 backdrop-blur-sm rounded-xl shadow-sm border border-gray-200/50 mb-6 animate-fadeIn">
        <div class="p-4 sm:p-5">
          <!-- Mobile Profile Header (Mobile Only) -->
          <div class="flex sm:hidden items-center justify-between mb-4">
            <div>
              <h1 class="text-xl font-bold flex items-center gap-1.5">
                {{ user?.name }}
                <div class="relative inline-flex tooltip-container">
                  <UIcon
                    v-if="user?.kyc"
                    name="i-mdi-check-decagram"
                    class="w-4 h-4 text-blue-600 animate-pulse-subtle"
                  />
                  <div class="tooltip-content">Verified</div>
                </div>
              </h1>
              <!-- Move these elements under the name in mobile view -->
              <p class="text-sm font-medium text-slate-600 mb-0.5">
                {{ user?.profession }}
              </p>
              <p class="text-xs text-gray-500">@{{ user?.username }}</p>
            </div>

            <div class="flex gap-2">
              <button
                v-if="user?.id !== currentUser?.user?.id && currentUser"
                :class="[
                  'px-3 py-1 rounded text-xs font-medium flex items-center gap-1 transition-all duration-300',
                  isFollowing
                    ? 'border border-gray-200 hover:bg-gray-50 hover:shadow-sm text-gray-800'
                    : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 hover:shadow-md text-white',
                ]"
                :disabled="followLoading"
                @click="toggleFollow"
              >
                <div
                  v-if="followLoading"
                  class="h-3 w-3 border-2 border-t-transparent border-white rounded-full animate-spin"
                ></div>

                <template v-else-if="isFollowing">
                  <Check class="h-3 w-3 animate-scaleIn" />
                  Following
                </template>

                <template v-else>
                  <UserPlus class="h-3 w-3 animate-scaleIn" />
                  Follow
                </template>
              </button>
              <button
                v-if="!currentUser"
                class="p-1 border border-gray-200 rounded hover:bg-gray-50 hover:shadow-sm text-gray-800 transition-all duration-300"
                aria-label="Message"
              >
                <Mail class="h-3.5 w-3.5" />
              </button>
            </div>
          </div>

          <div class="flex flex-col sm:flex-row sm:items-start gap-6">
            <!-- Profile Picture and Mobile Stats -->
            <div class="flex flex-col items-center sm:items-start">
              <div class="relative group">
                <div
                  class="size-36 rounded-full border-2 border-white shadow-lg bg-white overflow-hidden group-hover:shadow-xl transition-all duration-300"
                >
                  <img
                    :src="
                      user?.image || '/static/frontend/images/placeholder.jpg'
                    "
                    :alt="user?.name"
                    class="w-full h-full object-cover transition-all duration-500 group-hover:scale-105"
                    loading="lazy"
                  />
                </div>
                <div class="absolute inset-0 rounded-full bg-gradient-to-tr from-blue-600/20 to-indigo-600/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
              </div>

              <!-- User Stats for Mobile -->
              <div class="flex w-full justify-center sm:hidden mt-4 space-x-6">
                <div class="text-center hover:scale-105 transition-transform">
                  <div class="text-md font-semibold">
                    {{ user?.post_count || 0 }}
                  </div>
                  <div class="text-sm text-gray-500">Posts</div>
                </div>
                <div class="text-center hover:scale-105 transition-transform">
                  <div class="text-md font-semibold">
                    {{ user?.followers_count || 0 }}
                  </div>
                  <div class="text-sm text-gray-500">Followers</div>
                </div>
                <div class="text-center hover:scale-105 transition-transform">
                  <div class="text-md font-semibold">
                    {{ user?.following_count || 0 }}
                  </div>
                  <div class="text-sm text-gray-500">Following</div>
                </div>
              </div>
            </div>

            <!-- User Info -->
            <div class="flex-1">
              <!-- Desktop Header (Hidden on Mobile) -->
              <div
                class="hidden sm:flex sm:flex-row sm:items-start sm:justify-between"
              >
                <div>
                  <div class="flex items-center flex-wrap gap-1.5">
                    <h1 class="text-xl font-bold">{{ user?.name }}</h1>
                    <span
                      v-if="user?.is_pro"
                      class="px-1.5 py-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-xs font-medium shadow-sm"
                    >
                      <div class="flex items-center gap-1">
                        <UIcon name="i-heroicons-shield-check" class="size-3" />
                        <span class="text-2xs">Pro</span>
                      </div>
                    </span>
                    <div class="relative inline-flex tooltip-container">
                      <UIcon
                        v-if="user?.kyc"
                        name="i-mdi-check-decagram"
                        class="w-4 h-4 text-blue-600 animate-pulse-subtle"
                        data-tooltip="Verified"
                      />
                      <div class="tooltip-content">Verified</div>
                    </div>
                  </div>
                  <p class="text-sm font-medium text-slate-600 mb-0.5">
                    {{ user?.profession }}
                  </p>
                  <p class="text-xs text-gray-500">@{{ user?.username }}</p>
                </div>

                <!-- Action buttons (Desktop) -->
                <div class="hidden sm:flex">
                  <button
                    v-if="user.id !== currentUser?.user?.id && currentUser"
                    :class="[
                      'px-3 py-1.5 rounded text-xs font-medium flex items-center gap-1.5 transition-all duration-300',
                      isFollowing
                        ? 'border border-gray-200 hover:bg-gray-50 hover:shadow-sm text-gray-800'
                        : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 hover:shadow-md text-white',
                    ]"
                    :disabled="followLoading"
                    @click="toggleFollow"
                  >
                    <div
                      v-if="followLoading"
                      class="h-3 w-3 border-2 border-t-transparent border-white rounded-full animate-spin"
                    ></div>
                    <template v-else-if="isFollowing">
                      <Check class="h-3 w-3 animate-scaleIn" />
                      Unfollow
                    </template>
                    <template v-else>
                      <UserPlus class="h-3 w-3 animate-scaleIn" />
                      Follow
                    </template>
                  </button>
                  <button
                    v-if="!currentUser"
                    class="ml-2 p-1.5 border border-gray-200 rounded hover:bg-gray-50 hover:shadow-sm text-gray-800 transition-all duration-300"
                    aria-label="Message"
                  >
                    <Mail class="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>

              <!-- User Stats (Desktop) -->
              <div
                class="hidden sm:flex items-center mt-3 mb-3 border-b border-gray-100 pb-3"
              >
                <div class="flex items-center gap-6 text-sm">
                  <div class="flex items-center hover:scale-105 transition-transform">
                    <span class="font-semibold">{{ user?.post_count || 0 }}</span>
                    <span class="text-gray-500 ml-1.5">Posts</span>
                  </div>
                  <div class="flex items-center hover:scale-105 transition-transform">
                    <span class="font-semibold">
                      {{ user?.followers_count || 0 }}</span>
                    <span class="text-gray-500 ml-1.5">Followers</span>
                  </div>
                  <div class="flex items-center hover:scale-105 transition-transform">
                    <span class="font-semibold">
                      {{ user?.following_count || 0 }}</span>
                    <span class="text-gray-500 ml-1.5">Following</span>
                  </div>
                </div>
              </div>

              <!-- Bio -->
              <div
                class="mt-3 sm:mt-0 border-t sm:border-t-0 pt-3 sm:pt-0 border-gray-100"
              >
                <p v-if="user?.about" class="text-sm text-gray-600 mb-3 leading-relaxed">
                  {{ user?.about }}
                </p>
              </div>

              <!-- Contact Info & Social Media -->
              <div
                class="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-2 text-sm"
              >
                <div
                  v-if="user?.city || user?.state"
                  class="flex items-center gap-1.5 group"
                >
                  <MapPin class="h-3.5 w-3.5 text-gray-500 group-hover:text-blue-600 transition-colors" />
                  <span class="text-gray-600 text-sm truncate group-hover:text-gray-900 transition-colors">
                    {{ [user?.city, user?.state].filter(Boolean).join(", ") }}
                  </span>
                </div>
                <div v-if="user?.company" class="flex items-center gap-1.5 group">
                  <Briefcase class="h-3.5 w-3.5 text-gray-500 group-hover:text-blue-600 transition-colors" />
                  <span class="text-gray-600 text-sm truncate group-hover:text-gray-900 transition-colors">{{
                    user?.company
                  }}</span>
                </div>
                <div class="flex items-center gap-1.5 group">
                  <Calendar class="h-3.5 w-3.5 text-gray-500 group-hover:text-blue-600 transition-colors" />
                  <span class="text-gray-600 text-sm group-hover:text-gray-900 transition-colors"
                    >Joined {{ formatTimeAgo(user?.date_joined) }}</span
                  >
                </div>
                <div
                  v-if="
                    user?.email &&
                    (currentUser?.user?.id === user?.id || user?.show_email)
                  "
                  class="flex items-center gap-1.5 group"
                >
                  <Mail class="h-3.5 w-3.5 text-gray-500 group-hover:text-blue-600 transition-colors" />
                  <span class="text-gray-600 text-sm truncate group-hover:text-gray-900 transition-colors">{{
                    user?.email
                  }}</span>
                </div>
                <div
                  v-if="
                    user?.phone &&
                    (currentUser?.user?.id === user?.id || user?.show_phone)
                  "
                  class="flex items-center gap-1.5 group"
                >
                  <Phone class="h-3.5 w-3.5 text-gray-500 group-hover:text-blue-600 transition-colors" />
                  <span class="text-gray-600 text-sm truncate group-hover:text-gray-900 transition-colors">{{
                    user?.phone
                  }}</span>
                </div>
              </div>

              <!-- Social Media Links -->
              <div class="mt-3 pt-3 border-t border-gray-100">
                <div
                  class="grid grid-cols-2 sm:flex sm:flex-wrap gap-2 sm:gap-3"
                >
                  <a
                    v-if="user?.website"
                    :href="user?.website"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-600 hover:text-blue-700 text-sm truncate transform transition-transform hover:scale-105 hover:shadow-sm p-1 rounded-md"
                  >
                    <LinkIcon class="h-3.5 w-3.5 flex-shrink-0" />
                    <span class="truncate">{{
                      user?.website?.replace(/^https?:\/\//, "")
                    }}</span>
                  </a>
                  <a
                    v-if="user?.facebook_url"
                    :href="user?.facebook_url"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-600 hover:text-blue-700 transform transition-transform hover:scale-105 hover:shadow-sm p-1 rounded-md"
                  >
                    <UIcon name="i-mdi-facebook" class="size-4 flex-shrink-0" />
                    <span class="text-xs">Facebook</span>
                  </a>
                  <a
                    v-if="user?.whatsapp"
                    :href="`https://wa.me/${user?.whatsapp}`"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-green-600 hover:text-green-700 transform transition-transform hover:scale-105 hover:shadow-sm p-1 rounded-md"
                  >
                    <UIcon name="i-mdi-whatsapp" class="size-4 flex-shrink-0" />
                    <span class="text-xs">WhatsApp</span>
                  </a>
                  <a
                    v-if="user?.linkedin_url"
                    :href="user?.linkedin_url"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-700 hover:text-blue-800 transform transition-transform hover:scale-105 hover:shadow-sm p-1 rounded-md"
                  >
                    <UIcon name="i-mdi-linkedin" class="size-4 flex-shrink-0" />
                    <span class="text-xs">LinkedIn</span>
                  </a>
                  <a
                    v-if="user?.twitter_url"
                    :href="user?.twitter_url"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-400 hover:text-blue-500 transform transition-transform hover:scale-105 hover:shadow-sm p-1 rounded-md"
                  >
                    <UIcon name="i-mdi-twitter" class="size-4 flex-shrink-0" />
                    <span class="text-xs">Twitter</span>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Tabs Section -->
      <div class="bg-white/90 backdrop-blur-sm rounded-xl shadow-lg border border-gray-200/50 overflow-hidden animate-fadeIn-delayed">
        <!-- Scrollable Tabs for Mobile -->
        <div class="overflow-x-auto scrollbar-hide">
          <div class="flex items-center border-b border-gray-200 min-w-max relative">
            <button
              v-for="tab in tabs"
              :key="tab.value"
              class="px-5 py-3.5 text-sm font-medium border-b-2 transition-all duration-300 whitespace-nowrap relative overflow-hidden"
              :class="[
                activeTab === tab.value 
                  ? 'text-blue-600 border-blue-600' 
                  : 'text-gray-500 border-transparent hover:text-gray-800 hover:border-gray-300'
              ]"
              @click="switchTab(tab.value)"
            >
              <span class="relative z-10">{{ tab.label }}</span>
              <div 
                v-if="activeTab === tab.value"
                class="absolute bottom-0 left-0 h-0.5 w-full bg-blue-600 animate-fadeIn"
              ></div>
            </button>
            <div class="tab-indicator"></div>
          </div>
        </div>

        <div class="py-4">
          <transition name="tab-transition" mode="out-in">
            <div v-if="activeTab === 'posts'" class="px-2 tab-content">
              <!-- Lazyloader component for profile posts -->
              <div v-if="isLoadingPosts" class="p-4">
                <div class="flex justify-center items-center mb-6">
                  <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
                </div>
                <!-- Skeleton loaders for posts -->
                <div v-for="i in 2" :key="i" class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4 animate-pulse-staggered">
                  <div class="flex items-center space-x-3 mb-4">
                    <div class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"></div>
                    <div class="flex-1 space-y-2">
                      <div class="h-4 bg-gray-200 rounded animate-pulse w-1/4"></div>
                      <div class="h-3 bg-gray-200 rounded animate-pulse w-1/5"></div>
                    </div>
                  </div>
                  <div class="space-y-2 mb-4">
                    <div class="h-4 bg-gray-200 rounded animate-pulse w-3/4"></div>
                    <div class="h-3 bg-gray-200 rounded animate-pulse w-full"></div>
                    <div class="h-3 bg-gray-200 rounded animate-pulse w-5/6"></div>
                  </div>
                  <div class="h-40 bg-gray-200 rounded animate-pulse mb-4"></div>
                  <div class="flex justify-between">
                    <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
                    <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
                    <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
                  </div>
                </div>
              </div>
              
              <!-- Display actual posts when loaded -->
              <BusinessNetworkPost
                v-if="!isLoadingPosts"
                :posts="posts.results"
                :id="currentUser?.user?.id"
                class="animate-fadeIn"
              />
            </div>

            <div v-else-if="activeTab === 'media'" class="tab-content">
              <!-- Lazyloader for media tab -->
              <div v-if="isLoadingMedia" class="p-4">
                <div class="flex justify-center items-center mb-6">
                  <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
                </div>
                <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 px-2">
                  <div v-for="i in 8" :key="i" class="aspect-square bg-gray-200 rounded animate-pulse"></div>
                </div>
              </div>
              
              <!-- Display actual media when loaded -->
              <div
                v-if="!isLoadingMedia"
                class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 px-2 animate-fadeIn"
              >
                <div
                  v-for="(media, index) in allMedia"
                  :key="index"
                  class="aspect-square bg-gray-100 rounded-lg overflow-hidden group cursor-pointer hover:shadow-md transition-all duration-300"
                >
                  <img
                    :src="media.thumbnail"
                    :alt="`Media ${index + 1}`"
                    class="w-full h-full object-cover group-hover:scale-105 transition-all duration-500"
                  />
                </div>
              </div>
            </div>

            <div v-else-if="activeTab === 'saved'" class="px-4 py-6 tab-content">
              <!-- Lazyloader for saved posts -->
              <div v-if="isLoadingSaved" class="p-4">
                <div class="flex justify-center items-center mb-6">
                  <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
                </div>
                <div v-for="i in 2" :key="i" class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4 animate-pulse-staggered">
                  <div class="flex items-center space-x-3 mb-4">
                    <div class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"></div>
                    <div class="flex-1 space-y-2">
                      <div class="h-4 bg-gray-200 rounded animate-pulse w-1/4"></div>
                      <div class="h-3 bg-gray-200 rounded animate-pulse w-1/5"></div>
                    </div>
                  </div>
                  <div class="space-y-2 mb-4">
                    <div class="h-4 bg-gray-200 rounded animate-pulse w-3/4"></div>
                    <div class="h-3 bg-gray-200 rounded animate-pulse w-full"></div>
                  </div>
                  <div class="h-40 bg-gray-200 rounded animate-pulse mb-4"></div>
                </div>
              </div>
              
              <div v-if="!isLoadingSaved" class="animate-fadeIn">
                <div v-if="savedPosts?.length === 0" class="text-center py-10">
                  <h3 class="text-base font-medium text-gray-900 mb-2">
                    No saved posts yet
                  </h3>
                  <p class="text-gray-500 text-sm">Posts you save will appear here</p>
                </div>
                <BusinessNetworkPost
                  :posts="savedPosts"
                  :id="currentUser?.user?.id"
                />
              </div>
            </div>
          </transition>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "adsy-business-network",
});

import {
  Camera,
  Edit,
  MapPin,
  Briefcase,
  Calendar,
  LinkIcon,
  Grid,
  List,
  Settings,
  UserPlus,
  Check,
  BadgeCheck,
  Mail,
  Phone,
  Upload,
  Trash2,
  X,
  Home,
  Bell,
  User,
  BarChart2,
  Bookmark,
  Heart,
  MessageCircle,
  Share2,
  MoreHorizontal,
  Link2,
  Flag,
  Send,
  Download,
  ChevronLeft,
  ChevronRight,
  Loader2,
} from "lucide-vue-next";

const route = useRoute();

const { user: currentUser } = useAuth();
const { get, post, del } = useApi();

const user = ref({});
const posts = ref([]);
const toast = useToast();
const savedPosts = ref([]);
const allMedia = ref([]);

const followLoading = ref(false);
const isFollowing = ref(false);
const isLoadingPosts = ref(true); // Initialize as true
const isLoadingMedia = ref(true);
const isLoadingSaved = ref(true);

async function checkFollowing() {
  if (!currentUser.value) return;
  try {
    const { data } = await get(
      `/bn/check-follow-status/${currentUser.value?.user?.id}/${route.params.id}/`
    );
    console.log(data, "check-follow-status");
    isFollowing.value = data.is_following;
  } catch (error) {
    console.error(error);
  }
}
await checkFollowing();

// Add social media properties to your fetchUser function
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
    console.log(user.value);
  } catch (error) {
    console.error(error);
  }
}
await fetchUser();

async function fetchUserPosts() {
  try {
    const res = await get(`/bn/user/${route.params.id}/posts/`);
    console.log(res, "user posts");
    posts.value = res.data;
  } catch (error) {
    console.error(error);
  } finally {
    isLoadingPosts.value = false;
  }
}
await fetchUserPosts();

async function fetchUserSavedPosts() {
  try {
    const res = await get(`/bn/posts/save/`);
    console.log(res.data, "saved posts");
    savedPosts.value = res.data;
  } catch (error) {
    console.error(error);
  } finally {
    isLoadingSaved.value = false;
  }
}

await fetchUserSavedPosts();

// Simulate loading media
onMounted(() => {
  setTimeout(() => {
    allMedia.value = Array(16).fill().map((_, i) => ({
      thumbnail: `https://picsum.photos/500/500?random=${i+1}`,
      url: `https://picsum.photos/1200/900?random=${i+1}`
    }));
    isLoadingMedia.value = false;
  }, 1500);
});

const viewMode = ref("list");
const activeTab = ref("posts");
const isEditProfileOpen = ref(false);
const isEditPhotoOpen = ref(false);
const isEditCoverOpen = ref(false);
const profileForm = ref({
  name: user.value.name,
  bio: user.value.bio,
  location: user.value.location,
  company: user.value.company,
  website: user.value.website,
  email: user.value.email,
  phone: user.value.phone,
});
const profilePhotoInputRef = ref(null);
const coverPhotoInputRef = ref(null);
const activeMedia = ref(null);
const activePost = ref(null);
const activeMediaIndex = ref(0);

const tabs =
  currentUser.value?.user?.id && currentUser.value?.user?.id === route.params.id
    ? [
        { label: "Posts", value: "posts" },
        // { label: "Media", value: "media" },
        { label: "Saved", value: "saved" },
      ]
    : [
        { label: "Posts", value: "posts" },
        // { label: "Media", value: "media" },
        // { label: "Saved", value: "saved" },
      ];

const toggleFollow = async () => {
  if (followLoading.value) return;
  followLoading.value = true;
  isFollowing.value = !isFollowing.value;
  if (isFollowing.value) {
    try {
      const { data } = await post(`/bn/users/${route.params.id}/follow/`);

      if (data) {
        // Update followers count accordingly
        user.value.followers_count = (user.value.followers_count || 0) + 1;

        toast.add({
          title: "Followed",
          description: "You have successfully followed this user.",
          icon: "i-heroicons-check-circle",
          color: "green",
        });
      }
    } catch (error) {
      console.error("Error toggling follow:", error);
      isFollowing.value = !isFollowing.value; // Revert state on error
    } finally {
      followLoading.value = false;
    }
  } else {
    try {
      const res = await del(`/bn/users/${route.params.id}/unfollow/`);
      if (res.data === undefined) {
        // Update followers count accordingly
        user.value.followers_count = Math.max(0, (user.value.followers_count || 0) - 1);
        
        toast.add({
          title: "Unfollowed",
          description: "You have successfully unfollowed this user.",
          icon: "i-heroicons-information-circle",
          color: "gray",
        });
      }
    } catch (error) {
      console.error("Error toggling follow:", error);
      isFollowing.value = !isFollowing.value; // Revert state on error
    } finally {
      followLoading.value = false;
    }
  }
};

// Animation when switching tabs
const switchTab = (tabValue) => {
  if (activeTab.value === tabValue) return;
  
  // Apply animation class and change tab
  activeTab.value = tabValue;
};

// Remaining functions
const updateProfile = () => {
  user.value = {
    ...user.value,
    name: profileForm.value.name,
    bio: profileForm.value.bio,
    location: profileForm.value.location,
    company: profileForm.value.company,
    website: profileForm.value.website,
    email: profileForm.value.email,
    phone: profileForm.value.phone,
  };
  isEditProfileOpen.value = false;
  toast.add({
    title: "Profile Updated",
    description: "Your profile has been updated successfully.",
    icon: "i-heroicons-check-circle",
    color: "green",
  });
};

const triggerProfilePhotoInput = () => {
  profilePhotoInputRef.value?.click();
};

const triggerCoverPhotoInput = () => {
  coverPhotoInputRef.value?.click();
};

const handleProfilePhotoChange = (e) => {
  const file = e.target.files?.[0];
  if (file) {
    setTimeout(() => {
      toast.add({
        title: "Photo Updated",
        description: "Your profile photo has been updated successfully.",
        icon: "i-heroicons-check-circle",
        color: "green",
      });
      isEditPhotoOpen.value = false;
    }, 1000);
  }
};

const handleCoverPhotoChange = (e) => {
  const file = e.target.files?.[0];
  if (file) {
    setTimeout(() => {
      toast.add({
        title: "Cover Updated",
        description: "Your cover photo has been updated successfully.",
        icon: "i-heroicons-check-circle",
        color: "green",
      });
      isEditCoverOpen.value = false;
    }, 1000);
  }
};

const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${diffInSeconds} ${diffInSeconds === 1 ? "second" : "seconds"} ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} ${diffInMinutes === 1 ? "minute" : "minutes"} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} ${diffInHours === 1 ? "hour" : "hours"} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${diffInMonths} ${diffInMonths === 1 ? "month" : "months"} ago`;
};

// Add event listeners
onMounted(() => {
  const eventBus = useEventBus();

  eventBus.on("post-created", (newPost) => {
    // Only update if this is the author's profile
    if (newPost.author?.id === route.params.id) {
      // Add the new post to the beginning of the array
      if (posts.value?.results && Array.isArray(posts.value.results)) {
        posts.value.results.unshift(newPost);
      }

      // Update post count
      user.value.post_count = (user.value.post_count || 0) + 1;

      // Scroll to the new post after it renders
      nextTick(() => {
        setTimeout(() => {
          const newPostElement = document.getElementById(`post-${newPost.id}`);
          if (newPostElement) {
            newPostElement.scrollIntoView({
              behavior: "smooth",
              block: "center",
            });
            // Add highlight animation
            newPostElement.classList.add("highlight-new-post");
          }
        }, 500);
      });
    }
  });

  // Clean up event listener
  onUnmounted(() => {
    eventBus.off("post-created");
  });
});
</script>

<style scoped>
/* Enhanced background and styling */
.bg-gradient {
  background: linear-gradient(135deg, rgba(241, 245, 249, 0.8), rgba(248, 250, 252, 0.8), rgba(241, 245, 249, 0.8));
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

/* Enhanced tooltip styling */
.tooltip-container {
  position: relative;
}

.tooltip-content {
  position: absolute;
  top: calc(100% + 5px);
  left: 50%;
  transform: translateX(-50%);
  background-color: #333;
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  z-index: 10;
  white-space: nowrap;
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.2s ease-out, visibility 0.2s ease-out;
  pointer-events: none;
  width: max-content;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 10%), 0 2px 4px -1px rgb(0 0 0 / 6%);
}

.tooltip-container:hover .tooltip-content {
  opacity: 1;
  visibility: visible;
}

/* Tab transitions */
.tab-transition-enter-active,
.tab-transition-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}
.tab-transition-enter-from,
.tab-transition-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

.tab-content {
  min-height: 300px;
}

/* Animations */
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

@keyframes scaleIn {
  from {
    transform: scale(0);
  }
  to {
    transform: scale(1);
  }
}

@keyframes highlightPost {
  0% {
    box-shadow: 0 0 0 rgba(59, 130, 246, 0);
    transform: scale(1);
  }
  50% {
    box-shadow: 0 0 20px rgba(59, 130, 246, 0.6);
    transform: scale(1.02);
  }
  100% {
    box-shadow: 0 0 5px rgba(59, 130, 246, 0.3);
    transform: scale(1);
  }
}

@keyframes pulse-subtle {
  0% {
    opacity: 0.9;
  }
  50% {
    opacity: 1;
  }
  100% {
    opacity: 0.9;
  }
}

.animate-fadeIn {
  animation: fadeIn 0.5s ease forwards;
}

.animate-fadeIn-delayed {
  animation: fadeIn 0.5s 0.2s ease forwards;
  opacity: 0;
}

.animate-scaleIn {
  animation: scaleIn 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s infinite;
}

.animate-pulse-staggered:nth-child(2) {
  animation-delay: 0.2s;
}

.highlight-new-post {
  animation: highlightPost 1.5s ease-out;
}

/* Hide scrollbar but allow scrolling */
.scrollbar-hide {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* Internet Explorer 10+ */
}

.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Safari and Chrome */
}
</style>
