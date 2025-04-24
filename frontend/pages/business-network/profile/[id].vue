<template>
  <div class="mx-auto px-2 sm:px-6 lg:px-8 max-w-7xl mt-16 flex-1">
    <div class="max-w-3xl mx-auto relative z-10 sm:px-0">
      <!-- Professional Profile Card -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-4">
        <div class="p-4 sm:p-5">
          <!-- Mobile Profile Header (Mobile Only) -->
          <div class="flex sm:hidden items-center justify-between mb-4">
            <div>
              <h1 class="text-xl font-bold flex items-center gap-1.5">
                {{ user?.name }}
                <UIcon
                  v-if="user?.kyc"
                  name="i-mdi-check-decagram"
                  class="w-4 h-4 text-blue-600"
                />
              </h1>
              <!-- Move these elements under the name in mobile view -->
              <p class="text-sm font-medium text-slate-600 mb-0.5">{{ user?.profession }}</p>
              <p class="text-xs text-gray-500">@{{ user?.username }}</p>
            </div>
            <div class="flex gap-2">
              <button
                v-if="!isCurrentUserProfile"
                :class="[
                  'px-3 py-1 rounded text-xs font-medium flex items-center gap-1 transition-colors',
                  user?.isFollowing
                    ? 'border border-gray-200 hover:bg-gray-50 text-gray-700'
                    : 'bg-blue-600 hover:bg-blue-700 text-white',
                ]"
                :disabled="followLoading"
                @click="toggleFollow"
              >
                <div v-if="followLoading" class="h-3 w-3 border-2 border-t-transparent border-white rounded-full animate-spin"></div>
                <template v-else-if="user?.isFollowing">
                  <Check class="h-3 w-3" />
                  Following
                </template>
                <template v-else>
                  <UserPlus class="h-3 w-3" />
                  Follow
                </template>
              </button>
              <button
                v-if="!isCurrentUserProfile"
                class="p-1 border border-gray-200 rounded hover:bg-gray-50 text-gray-700 transition-colors"
                aria-label="Message"
              >
                <Mail class="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
          
          <div class="flex flex-col sm:flex-row sm:items-start gap-4">
            <!-- Profile Picture and Mobile Stats -->
            <div class="flex flex-col items-center sm:items-start">
              <div class="relative">
                <div class="size-32 sm:size-36 rounded-full border-2 border-white shadow-md bg-white overflow-hidden">
                  <img
                    :src="user?.image || '/static/frontend/images/placeholder.jpg'"
                    :alt="user?.name"
                    class="w-full h-full object-cover"
                    loading="lazy"
                  />
                </div>
              </div>
              
              <!-- User Stats for Mobile -->
              <div class="flex w-full justify-center sm:hidden mt-3 space-x-4">
                <div class="text-center">
                  <div class="text-md font-semibold">{{ user?.post_count || 0 }}</div>
                  <div class="text-sm text-gray-500">Posts</div>
                </div>
                <div class="text-center">
                  <div class="text-md font-semibold">{{ user?.followers_count || 0 }}</div>
                  <div class="text-sm text-gray-500">Followers</div>
                </div>
                <div class="text-center">
                  <div class="text-md font-semibold">{{ user?.following_count || 0 }}</div>
                  <div class="text-sm text-gray-500">Following</div>
                </div>
              </div>
            </div>
            
            <!-- User Info -->
            <div class="flex-1">
              <!-- Desktop Header (Hidden on Mobile) -->
              <div class="hidden sm:flex sm:flex-row sm:items-start sm:justify-between">
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
                    <UIcon
                      v-if="user?.kyc"
                      name="i-mdi-check-decagram"
                      class="w-4 h-4 text-blue-600"
                      data-tooltip="Verified"
                    />
                  </div>
                  <p class="text-sm font-medium text-slate-600 mb-0.5">{{ user?.profession }}</p>
                  <p class="text-xs text-gray-500">@{{ user?.username }}</p>
                </div>
                
                <!-- Action buttons (Desktop) -->
                <div class="hidden sm:flex">
                  <button
                    v-if="!isCurrentUserProfile"
                    :class="[
                      'px-3 py-1 rounded text-xs font-medium flex items-center gap-1 transition-colors',
                      user?.isFollowing
                        ? 'border border-gray-200 hover:bg-gray-50 text-gray-700'
                        : 'bg-blue-600 hover:bg-blue-700 text-white',
                    ]"
                    :disabled="followLoading"
                    @click="toggleFollow"
                  >
                    <div v-if="followLoading" class="h-3 w-3 border-2 border-t-transparent border-white rounded-full animate-spin"></div>
                    <template v-else-if="user?.isFollowing">
                      <Check class="h-3 w-3" />
                      Following
                    </template>
                    <template v-else>
                      <UserPlus class="h-3 w-3" />
                      Follow
                    </template>
                  </button>
                  <button
                    v-if="!isCurrentUserProfile"
                    class="ml-2 p-1 border border-gray-200 rounded hover:bg-gray-50 text-gray-700 transition-colors"
                    aria-label="Message"
                  >
                    <Mail class="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
              
              <!-- User Stats (Desktop) -->
              <div class="hidden sm:flex items-center mt-3 mb-3 border-b border-gray-100 pb-3">
                <div class="flex items-center gap-4 text-sm">
                  <div class="flex items-center">
                    <span class="font-semibold">{{ user?.post_count || 0 }}</span>
                    <span class="text-gray-500 ml-1">Posts</span>
                  </div>
                  <div class="flex items-center">
                    <span class="font-semibold">{{ user?.followers_count || 0 }}</span>
                    <span class="text-gray-500 ml-1">Followers</span>
                  </div>
                  <div class="flex items-center">
                    <span class="font-semibold">{{ user?.following_count || 0 }}</span>
                    <span class="text-gray-500 ml-1">Following</span>
                  </div>
                </div>
              </div>
              
              <!-- Bio -->
              <div class="mt-3 sm:mt-0 border-t sm:border-t-0 pt-3 sm:pt-0 border-gray-100">
                <p v-if="user?.about" class="text-sm text-gray-600 mb-3">{{ user?.about }}</p>
              </div>
              
              <!-- Contact Info & Social Media -->
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-2 text-sm">
                <div v-if="user?.city || user?.state" class="flex items-center gap-1.5">
                  <MapPin class="h-3.5 w-3.5 text-gray-500" />
                  <span class="text-gray-600 text-sm truncate">
                    {{ [user?.city, user?.state].filter(Boolean).join(', ') }}
                  </span>
                </div>
                <div v-if="user?.company" class="flex items-center gap-1.5">
                  <Briefcase class="h-3.5 w-3.5 text-gray-500" />
                  <span class="text-gray-600 text-sm truncate">{{ user?.company }}</span>
                </div>
                <div class="flex items-center gap-1.5">
                  <Calendar class="h-3.5 w-3.5 text-gray-500" />
                  <span class="text-gray-600 text-sm">Joined {{ formatTimeAgo(user?.date_joined) }}</span>
                </div>
                <div v-if="user?.email && (currentUser?.user?.id === user?.id || user?.show_email)" class="flex items-center gap-1.5">
                  <Mail class="h-3.5 w-3.5 text-gray-500" />
                  <span class="text-gray-600 text-sm truncate">{{ user?.email }}</span>
                </div>
                <div v-if="user?.phone && (currentUser?.user?.id === user?.id || user?.show_phone)" class="flex items-center gap-1.5">
                  <Phone class="h-3.5 w-3.5 text-gray-500" />
                  <span class="text-gray-600 text-sm truncate">{{ user?.phone }}</span>
                </div>
              </div>
              
              <!-- Social Media Links -->
              <div class="mt-3 pt-3 border-t border-gray-100">
                <div class="grid grid-cols-2 sm:flex sm:flex-wrap gap-2 sm:gap-3">
                  <a 
                    v-if="user?.website" 
                    :href="user?.website"
                    target="_blank" 
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-600 hover:text-blue-700 text-xs truncate"
                  >
                    <LinkIcon class="h-3.5 w-3.5 flex-shrink-0" />
                    <span class="truncate">{{ user?.website?.replace(/^https?:\/\//, "") }}</span>
                  </a>
                  <a 
                    v-if="user?.facebook_url" 
                    :href="user?.facebook_url"
                    target="_blank" 
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-600 hover:text-blue-700"
                  >
                    <UIcon name="i-mdi-facebook" class="size-4 flex-shrink-0" />
                    <span class="text-xs">Facebook</span>
                  </a>
                  <a 
                    v-if="user?.whatsapp" 
                    :href="`https://wa.me/${user?.whatsapp}`"
                    target="_blank" 
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-green-600 hover:text-green-700"
                  >
                    <UIcon name="i-mdi-whatsapp" class="size-4 flex-shrink-0" />
                    <span class="text-xs">WhatsApp</span>
                  </a>
                  <a 
                    v-if="user?.linkedin_url" 
                    :href="user?.linkedin_url"
                    target="_blank" 
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-700 hover:text-blue-800"
                  >
                    <UIcon name="i-mdi-linkedin" class="size-4 flex-shrink-0" />
                    <span class="text-xs">LinkedIn</span>
                  </a>
                  <a 
                    v-if="user?.twitter_url" 
                    :href="user?.twitter_url"
                    target="_blank" 
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-400 hover:text-blue-500"
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
      <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <!-- Scrollable Tabs for Mobile -->
        <div class="overflow-x-auto scrollbar-hide">
          <div class="flex items-center border-b border-gray-200 min-w-max">
            <button
              v-for="tab in tabs"
              :key="tab.value"
              class="px-4 py-3 text-sm font-medium border-b-2 transition-colors whitespace-nowrap"
              :class="activeTab === tab.value
                ? 'text-blue-600 border-blue-600'
                : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'"
              @click="activeTab = tab.value"
            >
              {{ tab.label }}
            </button>
          </div>
        </div>
        
        <div class="py-4">
          <div v-if="activeTab === 'posts'" class="px-2">
            <BusinessNetworkPost :posts="posts.results" :id="currentUser?.user?.id" />
          </div>

          <div v-else-if="activeTab === 'media'">
            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 px-2">
              <div
                v-for="(media, index) in allMedia"
                :key="index"
                class="aspect-square bg-gray-100 rounded overflow-hidden group cursor-pointer"
              >
                <img
                  :src="media.thumbnail"
                  :alt="`Media ${index + 1}`"
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />
              </div>
            </div>
          </div>

          <div v-else-if="activeTab === 'likes'" class="px-4 py-6">
            <div class="text-center">
              <h3 class="text-base font-medium text-gray-900">No liked posts yet</h3>
              <p class="text-sm text-gray-500 mt-1">Posts liked by this user will appear here.</p>
            </div>
          </div>

          <div v-else-if="activeTab === 'saved'" class="px-4 py-6">
            <div class="text-center">
              <h3 class="text-base font-medium text-gray-900">No saved posts yet</h3>
              <p class="text-sm text-gray-500 mt-1">Posts saved by this user will appear here.</p>
            </div>
          </div>
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
} from "lucide-vue-next";

import { useEventBus } from '@/composables/useEventBus'; 
const router = useRouter();
const route = useRoute();

const { user: currentUser } = useAuth();
const { get, post } = useApi();

const user = ref({});
const posts = ref([]);

const isCurrentUserProfile = computed(() => {
  return currentUser.value?.user?.id === route.params.id;
});

const followLoading = ref(false);

// Add social media properties to your fetchUser function
async function fetchUser() {
  try {
    const { data } = await get(`/user/${route.params.id}/`);
    user.value = {
      ...data,
      // Ensure these properties exist with defaults
      followers_count: data.followers_count || 0,
      following_count: data.following_count || 0,
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
    const  res  = await get(`/bn/user/${route.params.id}/posts/`);
    console.log(res,'user posts');
    posts.value = res.data;
  } catch (error) {
    console.error(error);
  }
}
await fetchUserPosts();

const refreshPosts = async () => {
  try {
    const response = await get(`/bn/posts/?author=${route.params.id}`);
    if (response && response.data) {
      posts.value = response.data; // Update the posts array
    }
  } catch (error) {
    console.error('Error refreshing posts:', error);
  }
};

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

const tabs = [
  { label: "Posts", value: "posts" },
  { label: "Media", value: "media" },
  { label: "Likes", value: "likes" },
  { label: "Saved", value: "saved" },
];

const toggleFollow = async () => {
  if (followLoading.value) return;
  followLoading.value = true;
  
  try {
    const wasFollowing = user.value.isFollowing;
    
    user.value.isFollowing = !user.value.isFollowing;
    user.value.followers_count = (user.value.followers_count || 0) + (user.value.isFollowing ? 1 : -1);
    
    const endpoint = `/bn/users/${route.params.id}/${wasFollowing ? 'unfollow' : 'follow'}/`;
    const { data } = await post(endpoint);
    
    if (!data) {
      user.value.isFollowing = wasFollowing;
      user.value.followers_count = (user.value.followers_count || 0) + (wasFollowing ? 1 : -1);
      console.error("Failed to update follow status");
    }
  } catch (error) {
    console.error("Error toggling follow:", error);
    user.value.isFollowing = !user.value.isFollowing;
    user.value.followers_count = (user.value.followers_count || 0) + (user.value.isFollowing ? 1 : -1);
  } finally {
    followLoading.value = false;
  }
};

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
  alert("Profile updated successfully");
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
      alert("Profile photo updated successfully");
      isEditPhotoOpen.value = false;
    }, 1000);
  }
};

const handleCoverPhotoChange = (e) => {
  const file = e.target.files?.[0];
  if (file) {
    setTimeout(() => {
      alert("Cover photo updated successfully");
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

const toggleLike = (post) => {
  post.isLiked = !post.isLiked;
  post.likeCount += post.isLiked ? 1 : -1;
};

const toggleSave = (post) => {
  post.isSaved = !post.isSaved;
  post.showDropdown = false;
};

const toggleDropdown = (post) => {
  posts.value.forEach((p) => {
    if (p.id !== post.id) p.showDropdown = false;
  });

  post.showDropdown = !post.showDropdown;
};

const toggleDescription = (post) => {
  post.showFullDescription = !post.showFullDescription;
};

const copyLink = (post) => {
  const postUrl = `${window.location.origin}/post/${post.id}`;
  navigator.clipboard.writeText(postUrl);
  alert("Link copied to clipboard");
  post.showDropdown = false;
};

const sharePost = (post) => {
  const postUrl = `${window.location.origin}/post/${post.id}`;

  if (navigator.share && navigator.canShare) {
    navigator
      .share({
        title: post.title,
        text:
          post.content.substring(0, 100) +
          (post.content.length > 100 ? "..." : ""),
        url: postUrl,
      })
      .catch((error) => console.error("Error sharing:", error));
  } else {
    alert(`Share URL: ${postUrl}`);
  }
};

const addComment = (post) => {
  if (!post.commentText.trim()) return;

  const newComment = {
    id: `comment-${Date.now()}`,
    user: {
      id: "current-user",
      fullName: "You",
      avatar: "/images/placeholder.jpg?height=40&width=40",
    },
    text: post.commentText,
    timestamp: new Date().toISOString(),
  };

  post.comments.unshift(newComment);
  post.commentText = "";
};

const openMedia = (post, index) => {
  activePost.value = post;
  activeMediaIndex.value = index;
  activeMedia.value = post.media[index];
};

const navigateMedia = (direction) => {
  if (!activePost.value || !activeMedia.value) return;

  const currentIndex = activeMediaIndex.value;
  const totalMedia = activePost.value.media.length;

  if (direction === "prev") {
    activeMediaIndex.value = (currentIndex - 1 + totalMedia) % totalMedia;
  } else {
    activeMediaIndex.value = (currentIndex + 1) % totalMedia;
  }

  activeMedia.value = activePost.value.media[activeMediaIndex.value];
};

// Add handler for new posts
const handleNewPost = (newPost) => {
  // Only add to this profile's posts if the author is the profile owner
  if (newPost.author?.id === route.params.id) {
    posts.value.results = [newPost, ...posts.value.results];
  }
};

// Add event listeners
onMounted(() => {
  const eventBus = useEventBus();
  
  eventBus.on('post-created', (newPost) => {
    // Only update if this is the author's profile
    if (newPost.author?.id === route.params.id) {
      // Add the new post to the beginning of the array
      if (posts.value?.results && Array.isArray(posts.value.results)) {
        posts.value.results.unshift(newPost);
      }
      
      // Scroll to the new post after it renders
      nextTick(() => {
        setTimeout(() => {
          const newPostElement = document.getElementById(`post-${newPost.id}`);
          if (newPostElement) {
            newPostElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
            // Add highlight animation
            newPostElement.classList.add('highlight-new-post');
          }
        }, 500);
      });
    }
  });
  
  // Clean up event listener
  onUnmounted(() => {
    eventBus.off('post-created');
  });
});

</script>

<style scoped>
.border-l-3 {
  border-left-width: 3px;
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

[data-tooltip]:hover::after {
  content: attr(data-tooltip);
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  background-color: #333;
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  z-index: 10;
  white-space: nowrap;
  margin-top: 0.25rem;
  animation: fadeIn 0.2s ease-out forwards;
}

@keyframes highlightPost {
  0% { box-shadow: 0 0 0 rgba(59, 130, 246, 0); transform: scale(1); }
  50% { box-shadow: 0 0 20px rgba(59, 130, 246, 0.6); transform: scale(1.02); }
  100% { box-shadow: 0 0 5px rgba(59, 130, 246, 0.3); transform: scale(1); }
}

.highlight-new-post {
  animation: highlightPost 1.5s ease-out;
}
</style>
