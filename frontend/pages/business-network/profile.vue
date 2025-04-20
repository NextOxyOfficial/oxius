<template>
    <div class="min-h-screen bg-gray-50">
     
  
      <!-- Profile Header -->
      <div class="max-w-3xl mx-auto px-4 relative z-10 mt-4 sm:mt-6">
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div class="flex flex-col md:flex-row gap-6">
            <!-- Profile Picture -->
            <div class="relative">
              <div class="relative h-32 w-32 rounded-full border-4 border-white overflow-hidden bg-gray-100 shadow-md">
                <img :src="user.avatar || '/placeholder.svg'" :alt="user.name" class="h-full w-full object-cover" />
                <div v-if="user.verified" class="absolute bottom-0 right-0 bg-blue-500 text-white rounded-full p-1 border-2 border-white">
                  <BadgeCheckIcon class="h-4 w-4" />
                </div>
              </div>
              <button v-if="isCurrentUser" class="absolute bottom-0 right-0 bg-blue-500 text-white p-2 rounded-full shadow-md hover:bg-blue-600 transition-colors">
                <CameraIcon class="h-4 w-4" />
              </button>
            </div>
  
            <!-- Profile Info -->
            <div class="flex-1">
              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                  <h1 class="text-2xl font-bold flex items-center gap-1">
                    {{ user.name }}
                    <BadgeCheckIcon v-if="user.verified" class="h-5 w-5 text-blue-500" />
                  </h1>
                  <p class="text-gray-500">@{{ user.username }}</p>
                </div>
                <div class="flex gap-2">
                  <button v-if="isCurrentUser" class="border border-gray-200 px-3 py-1.5 rounded-md text-sm flex items-center gap-1 hover:bg-gray-50">
                    <EditIcon class="h-4 w-4" />
                    Edit Profile
                  </button>
                  <button v-else :class="[
                    'px-3 py-1.5 rounded-md text-sm flex items-center gap-1',
                    isFollowing ? 'border border-gray-200 text-gray-700' : 'bg-blue-500 text-white'
                  ]" @click="toggleFollow">
                    <component :is="isFollowing ? CheckIcon : UserPlusIcon" class="h-4 w-4" />
                    {{ isFollowing ? 'Following' : 'Follow' }}
                  </button>
                </div>
              </div>
  
              <!-- Bio -->
              <p class="mt-4 text-gray-700">{{ user.bio }}</p>
  
              <!-- Additional Info -->
              <div class="mt-4 flex flex-wrap gap-x-6 gap-y-2 text-sm text-gray-500">
                <div v-if="user.location" class="flex items-center gap-1">
                  <MapPinIcon class="h-4 w-4" />
                  <span>{{ user.location }}</span>
                </div>
                <div v-if="user.company" class="flex items-center gap-1">
                  <BriefcaseIcon class="h-4 w-4" />
                  <span>{{ user.company }}</span>
                </div>
                <div class="flex items-center gap-1">
                  <CalendarIcon class="h-4 w-4" />
                  <span>Joined {{ user.joinedDate }}</span>
                </div>
                <div v-if="user.website" class="flex items-center gap-1">
                  <LinkIcon class="h-4 w-4" />
                  <a
                    :href="user.website"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-blue-500 hover:underline"
                  >
                    {{ user.website.replace(/^https?:\/\//, "") }}
                  </a>
                </div>
              </div>
  
              <!-- Followers/Following -->
              <div class="mt-4 flex gap-4 text-sm">
                <div class="flex items-center gap-0.5">
                  <span class="font-semibold">{{ user.followers.toLocaleString() }} </span>
                  <span class="text-gray-500">Followers</span>
                </div>
                <div class="flex items-center gap-0.5">
                  <span class="font-semibold">{{ user.following.toLocaleString() }} </span>
                  <span class="text-gray-500">Following</span>
                </div>
              </div>
            </div>
          </div>
        </div>
  
        <!-- Tabs and Content -->
        <div class="mt-6">
          <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
            <div class="flex border-b border-gray-200">
              <button 
                v-for="tab in tabs" 
                :key="tab.value"
                :class="[
                  'px-4 py-3 text-sm font-medium transition-colors',
                  activeTab === tab.value 
                    ? 'text-blue-500 border-b-2 border-blue-500' 
                    : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
                ]"
                @click="activeTab = tab.value"
              >
                {{ tab.label }}
              </button>
              
              <div class="ml-auto flex items-center px-2">
                <button 
                  :class="[
                    'p-1.5 rounded',
                    viewMode === 'list' ? 'bg-gray-100' : ''
                  ]"
                  @click="viewMode = 'list'"
                >
                  <ListIcon class="h-4 w-4" />
                </button>
                <button 
                  :class="[
                    'p-1.5 rounded',
                    viewMode === 'grid' ? 'bg-gray-100' : ''
                  ]"
                  @click="viewMode = 'grid'"
                >
                  <GridIcon class="h-4 w-4" />
                </button>
              </div>
            </div>
            
            <div class="p-4">
              <!-- Posts Tab -->
              <div v-if="activeTab === 'posts'" class="animate-fade-in">
                <div v-if="viewMode === 'list'" class="space-y-4">
                  <div v-for="post in posts" :key="post.id">
                    <BusinessNetworkPostCard :post="post" />
                  </div>
                </div>
                <div v-else class="grid grid-cols-2 md:grid-cols-3 gap-4">
                  <div
                    v-for="post in posts"
                    :key="post.id"
                    class="bg-white rounded-lg border border-gray-200 overflow-hidden hover:shadow-md transition-shadow"
                  >
                    <div class="p-3">
                      <h3 class="font-medium text-sm line-clamp-2">{{ post.title }}</h3>
                      <p class="text-xs text-gray-500 mt-1">{{ formatDate(post.timestamp) }}</p>
                    </div>
                    <div v-if="post.media.length > 0" class="relative aspect-video bg-gray-100">
                      <img
                        :src="post.media[0].thumbnail"
                        :alt="post.title"
                        class="w-full h-full object-cover"
                      />
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Media Tab -->
              <div v-else-if="activeTab === 'media'" class="animate-fade-in">
                <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
                  <div 
                    v-for="(media, index) in allMedia" 
                    :key="index" 
                    class="relative aspect-square bg-gray-100 rounded-lg overflow-hidden group"
                  >
                    <img
                      :src="media.thumbnail"
                      :alt="`Media ${index + 1}`"
                      class="h-full w-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                  </div>
                </div>
              </div>
              
              <!-- Likes Tab -->
              <div v-else-if="activeTab === 'likes'" class="animate-fade-in">
                <div class="text-center py-12">
                  <h3 class="text-lg font-medium text-gray-900">No liked posts yet</h3>
                  <p class="text-gray-500 mt-1">Posts you like will appear here.</p>
                </div>
              </div>
              
              <!-- Saved Tab -->
              <div v-else-if="activeTab === 'saved'" class="animate-fade-in">
                <div class="text-center py-12">
                  <h3 class="text-lg font-medium text-gray-900">No saved posts yet</h3>
                  <p class="text-gray-500 mt-1">Posts you save will appear here.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script setup>

  
definePageMeta({
  layout: "businessnetwork",
});

  import { 
    Camera as CameraIcon,
    BadgeCheck as BadgeCheckIcon,
    Edit as EditIcon,
    Check as CheckIcon,
    UserPlus as UserPlusIcon,
    MapPin as MapPinIcon,
    Briefcase as BriefcaseIcon,
    Calendar as CalendarIcon,
    Link as LinkIcon,
    List as ListIcon,
    Grid as GridIcon
  } from 'lucide-vue-next';

  
  // Sample user data
  const user = ref({
    id: "user-current",
    name: "Alex Morgan",
    username: "alexmorgan",
    avatar: "/placeholder.svg?height=150&width=150",
    coverPhoto: "/placeholder.svg?height=400&width=1200",
    bio: "Director of Marketing | Helping businesses grow through strategic digital marketing | Speaker | Writer | Coffee enthusiast",
    location: "San Francisco, CA",
    company: "TechGrowth Partners",
    joinedDate: "January 2020",
    website: "https://alexmorgan.com",
    email: "alex.morgan@example.com",
    phone: "+1 (555) 123-4567",
    followers: 1248,
    following: 365,
    isFollowing: false,
    isCurrentUser: true,
    verified: true,
  });
  
  // State
  const isCurrentUser = computed(() => user.value.isCurrentUser);
  const isFollowing = ref(false);
  const activeTab = ref('posts');
  const viewMode = ref('list');
  const posts = ref([]);
  const loading = ref(false);
  
  // Tabs
  const tabs = [
    { label: 'Posts', value: 'posts' },
    { label: 'Media', value: 'media' },
    { label: 'Likes', value: 'likes' },
    { label: 'Saved', value: 'saved' },
  ];
  
  // Get all media from posts
  const allMedia = computed(() => {
    return posts.value.flatMap(post => post.media);
  });
  
  // Methods
  const toggleFollow = () => {
    isFollowing.value = !isFollowing.value;
    user.value.followers += isFollowing.value ? 1 : -1;
  };
  
  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };
  
  // Load user posts
  const loadPosts = async () => {
    loading.value = true;
    
    try {
      const { getPosts } = usePost();
      posts.value = await getPosts({ limit: 6 });
    } catch (error) {
      console.error('Error loading posts:', error);
    } finally {
      loading.value = false;
    }
  };
  
  // Lifecycle hooks
  onMounted(() => {
    loadPosts();
  });
  </script>
  
  <style scoped>
  .animate-fade-in {
    animation: fadeIn 0.3s ease-out forwards;
  }
  
  @keyframes fadeIn {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }
  </style>