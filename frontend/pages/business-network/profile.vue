<template>
    <div class="min-h-screen bg-gray-50 mt-14">
      <div class="max-w-3xl mx-auto px-2 sm:px-2 lg:px-4 relative z-10 pt-3">
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-3 sm:p-6">
          <div class="flex flex-col md:flex-row sm:gap-6">
            <div class="relative flex gap-4">
              <div class="flex relative">
                <div class="relative h-32 w-32 rounded-full border-4 border-white overflow-hidden bg-gray-100 shadow-md">
                <img :src="user.avatar" :alt="user.name" class="w-full h-full object-cover" />
                <div v-if="user.verified" class="absolute bottom-0 right-0 bg-blue-500 text-white rounded-full p-1 border-2 border-white">
                  <BadgeCheck class="h-4 w-4" />
                </div>
              </div>
              <button 
                v-if="user.isCurrentUser" 
                class="absolute bottom-0 right-0 bg-blue-600 text-white p-2 rounded-full shadow-md hover:bg-blue-700 transition-colors"
                @click="isEditPhotoOpen = true"
              >
                <Camera class="h-4 w-4" />
              </button>
              </div>

              <div class="flex sm:hidden flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                  <h1 class="text-2xl font-bold flex items-center gap-1">
                    {{ user.name }}
                    <BadgeCheck v-if="user.verified" class="h-5 w-5 text-blue-500" />
                  </h1>
                  <UBadge class="bg-gray-100 text-slate-500">Writer</UBadge>
                  <p class="text-gray-500">@{{ user.username }}</p>
                </div>
                <div class="flex gap-2">
                  <template v-if="user.isCurrentUser">
                    <button 
                      class="px-3 py-1.5 border border-gray-200 rounded-md text-sm flex items-center gap-1 hover:bg-gray-50"
                      @click="isEditProfileOpen = true"
                    >
                      <Edit class="h-4 w-4" />
              
                    </button>
                    <button class="p-2 border border-gray-200 rounded-md hover:bg-gray-50">
                      <Settings class="h-4 w-4" />
                    </button>
                  </template>
                  <template v-else>
                    <button
                      :class="[
                        'px-3 py-1.5 rounded-md text-sm flex items-center gap-1',
                        user.isFollowing ? 'border border-gray-200 hover:bg-gray-50' : 'bg-blue-600 text-white hover:bg-blue-700'
                      ]"
                      @click="toggleFollow"
                    >
                      <template v-if="user.isFollowing">
                        <Check class="h-4 w-4" />
                        Following
                      </template>
                      <template v-else>
                        <UserPlus class="h-4 w-4" />
                        Follow
                      </template>
                    </button>
                    <button class="p-2 border border-gray-200 rounded-md hover:bg-gray-50">
                      <Mail class="h-4 w-4" />
                    </button>
                  </template>
                </div>
              </div>
            </div>
  
            <div class="flex-1">
              <div class="hidden sm:flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                  <h1 class="text-2xl font-bold flex items-center gap-1">
                    {{ user.name }}
                    <BadgeCheck v-if="user.verified" class="h-5 w-5 text-blue-500" />
                  </h1>
                  <p class="text-gray-500">@{{ user.username }}</p>
                </div>
                <div class="flex gap-2">
                  <template v-if="user.isCurrentUser">
                    <button 
                      class="px-3 py-1.5 border border-gray-200 rounded-md text-sm flex items-center gap-1 hover:bg-gray-50"
                      @click="isEditProfileOpen = true"
                    >
                      <Edit class="h-4 w-4" />
                      Edit Profile
                    </button>
                    <button class="p-2 border border-gray-200 rounded-md hover:bg-gray-50">
                      <Settings class="h-4 w-4" />
                    </button>
                  </template>
                  <template v-else>
                    <button
                      :class="[
                        'px-3 py-1.5 rounded-md text-sm flex items-center gap-1',
                        user.isFollowing ? 'border border-gray-200 hover:bg-gray-50' : 'bg-blue-600 text-white hover:bg-blue-700'
                      ]"
                      @click="toggleFollow"
                    >
                      <template v-if="user.isFollowing">
                        <Check class="h-4 w-4" />
                        Following
                      </template>
                      <template v-else>
                        <UserPlus class="h-4 w-4" />
                        Follow
                      </template>
                    </button>
                    <button class="p-2 border border-gray-200 rounded-md hover:bg-gray-50">
                      <Mail class="h-4 w-4" />
                    </button>
                  </template>
                </div>
              </div>
  
              <p class="mt-4 text-gray-700">{{ user.bio }}</p>
  
              <div class="mt-4 flex flex-wrap gap-x-6 gap-y-2 text-sm text-gray-500">
                <div v-if="user.location" class="flex items-center gap-1">
                  <MapPin class="h-4 w-4" />
                  <span>{{ user.location }}</span>
                </div>
                <div v-if="user.company" class="flex items-center gap-1">
                  <Briefcase class="h-4 w-4" />
                  <span>{{ user.company }}</span>
                </div>
                <div class="flex items-center gap-1">
                  <Calendar class="h-4 w-4" />
                  <span>Joined {{ user.joinedDate }}</span>
                </div>
                <div v-if="user.website" class="flex items-center gap-1">
                  <LinkIcon class="h-4 w-4" />
                  <a
                    :href="user.website"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-blue-600 hover:underline"
                  >
                    {{ user.website.replace(/^https?:\/\//, "") }}
                  </a>
                </div>
                <div v-if="user.email && user.isCurrentUser" class="flex items-center gap-1">
                  <Mail class="h-4 w-4" />
                  <span>{{ user.email }}</span>
                </div>
                <div v-if="user.phone && user.isCurrentUser" class="flex items-center gap-1">
                  <Phone class="h-4 w-4" />
                  <span>{{ user.phone }}</span>
                </div>
              </div>
  
              <div class="mt-4 flex gap-4 text-sm">
                <div>
                  <span class="font-semibold">{{ user.followers.toLocaleString() }}</span>
                  <span class="text-gray-500"> Followers</span>
                </div>
                <div>
                  <span class="font-semibold">{{ user.following.toLocaleString() }}</span>
                  <span class="text-gray-500"> Following</span>
                </div>
              </div>
            </div>
          </div>
        </div>
  
        <div class="mt-6">
          <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
            <div class="flex items-center justify-between p-4 border-b border-gray-200">
              <div class="flex">
                <button
                  v-for="tab in tabs"
                  :key="tab.value"
                  class="px-4 py-2 text-sm font-medium"
                  :class="activeTab === tab.value ? 'text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:text-gray-700'"
                  @click="activeTab = tab.value"
                >
                  {{ tab.label }}
                </button>
              </div>
            </div>
  
            <div class="py-4">
              <div v-if="activeTab === 'posts'">
                <BusinessNetworkPost/>
              </div>
  
             
              <div v-else-if="activeTab === 'media'">
                <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
                  <div
                    v-for="(media, index) in allMedia"
                    :key="index"
                    class="relative aspect-square bg-gray-100 rounded-lg overflow-hidden group"
                  >
                    <img
                      :src="media.thumbnail"
                      :alt="`Media ${index + 1}`"
                      class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                  </div>
                </div>
              </div>
  
             
              <div v-else-if="activeTab === 'likes'">
                <div class="text-center py-12">
                  <h3 class="text-lg font-medium text-gray-900">No liked posts yet</h3>
                  <p class="text-gray-500 mt-1">Posts you like will appear here.</p>
                </div>
              </div>
  
              
              <div v-else-if="activeTab === 'saved'">
                <div class="text-center py-12">
                  <h3 class="text-lg font-medium text-gray-900">No saved posts yet</h3>
                  <p class="text-gray-500 mt-1">Posts you save will appear here.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
  
      
  
      <Teleport to="body">
        <div v-if="isEditProfileOpen" class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4" @click="isEditProfileOpen = false">
          <div class="bg-white rounded-lg max-w-lg w-full max-h-[90vh] overflow-hidden" @click.stop>
            <div class="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="font-semibold">Edit Profile</h3>
              <button @click="isEditProfileOpen = false">
                <X class="h-5 w-5" />
              </button>
            </div>
            <div class="p-4 overflow-y-auto max-h-[calc(90vh-130px)]">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                  <input
                    type="text"
                    v-model="profileForm.name"
                    class="w-full p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Bio</label>
                  <textarea
                    v-model="profileForm.bio"
                    rows="3"
                    class="w-full p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                  ></textarea>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Location</label>
                  <input
                    type="text"
                    v-model="profileForm.location"
                    class="w-full p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Company</label>
                  <input
                    type="text"
                    v-model="profileForm.company"
                    class="w-full p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Website</label>
                  <input
                    type="text"
                    v-model="profileForm.website"
                    class="w-full p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                  <input
                    type="email"
                    v-model="profileForm.email"
                    class="w-full p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                  <input
                    type="text"
                    v-model="profileForm.phone"
                    class="w-full p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-600"
                  />
                </div>
              </div>
            </div>
            <div class="p-4 border-t border-gray-200 flex justify-end gap-2">
              <button 
                class="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
                @click="isEditProfileOpen = false"
              >
                Cancel
              </button>
              <button 
                class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                @click="updateProfile"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      </Teleport>
  
      <Teleport to="body">
        <div v-if="isEditPhotoOpen" class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4" @click="isEditPhotoOpen = false">
          <div class="bg-white rounded-lg max-w-md w-full" @click.stop>
            <div class="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="font-semibold">Update Profile Picture</h3>
              <button @click="isEditPhotoOpen = false">
                <X class="h-5 w-5" />
              </button>
            </div>
            <div class="p-4">
              <div class="relative h-40 w-40 mx-auto rounded-full overflow-hidden bg-gray-100 mb-4">
                <img
                  :src="user.avatar"
                  alt="Current profile picture"
                  class="w-full h-full object-cover"
                />
              </div>
              <div class="flex flex-col gap-2">
                <button 
                  class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center justify-center gap-2"
                  @click="triggerProfilePhotoInput"
                >
                  <Upload class="h-4 w-4" />
                  Upload New Photo
                </button>
                <button class="w-full px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50 flex items-center justify-center gap-2">
                  <Trash2 class="h-4 w-4 text-red-500" />
                  Remove Photo
                </button>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
  
      <Teleport to="body">
        <div v-if="isEditCoverOpen" class="fixed inset-0 z-[9999] bg-black/50 flex items-center justify-center p-4" @click="isEditCoverOpen = false">
          <div class="bg-white rounded-lg max-w-md w-full" @click.stop>
            <div class="p-4 border-b border-gray-200 flex items-center justify-between">
              <h3 class="font-semibold">Update Cover Photo</h3>
              <button @click="isEditCoverOpen = false">
                <X class="h-5 w-5" />
              </button>
            </div>
            <div class="p-4">
              <div class="relative aspect-[3/1] w-full bg-gray-100 rounded-md overflow-hidden mb-4">
                <img
                  :src="user.coverPhoto"
                  alt="Current cover photo"
                  class="w-full h-full object-cover"
                />
              </div>
              <div class="flex flex-col gap-2">
                <button 
                  class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center justify-center gap-2"
                  @click="triggerCoverPhotoInput"
                >
                  <Upload class="h-4 w-4" />
                  Upload New Cover Photo
                </button>
                <button class="w-full px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50 flex items-center justify-center gap-2">
                  <Trash2 class="h-4 w-4 text-red-500" />
                  Remove Cover Photo
                </button>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
  
      <Teleport to="body">
        <div v-if="activeMedia" class="fixed inset-0 z-[9999] bg-black/80 flex items-center justify-center p-4" @click="activeMedia = null">
          <div class="relative max-w-3xl w-full max-h-[80vh] bg-white rounded-lg overflow-hidden flex flex-col" @click.stop>
            <button class="absolute right-2 top-2 z-10 p-1 rounded-full bg-black/50 text-white" @click="activeMedia = null">
              <X class="h-6 w-6" />
            </button>
  
            <div class="flex-1 overflow-hidden relative">
              <div v-if="activeMedia.type === 'image'" class="relative h-[45vh] w-full">
                <img :src="activeMedia.url" alt="Media preview" class="w-full h-full object-contain" />
                <a
                  :href="activeMedia.url"
                  :download="`media-${activeMedia.id}`"
                  class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
                  @click.stop
                >
                  <Download class="h-5 w-5" />
                </a>
              </div>
              <div v-else class="relative">
                <video :src="activeMedia.url" controls class="w-full h-auto max-h-[45vh]"></video>
                <a
                  :href="activeMedia.url"
                  :download="`video-${activeMedia.id}`"
                  class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
                  @click.stop
                >
                  <Download class="h-5 w-5" />
                </a>
              </div>
  
              <div v-if="activePost && activePost.media.length > 1">
                <button
                  class="absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 rounded-full p-2 text-white touch-manipulation transition-all hover:scale-110"
                  @click.stop="navigateMedia('prev')"
                >
                  <ChevronLeft class="h-5 w-5" />
                </button>
                <button
                  class="absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 rounded-full p-2 text-white touch-manipulation transition-all hover:scale-110"
                  @click.stop="navigateMedia('next')"
                >
                  <ChevronRight class="h-5 w-5" />
                </button>
                <div class="absolute bottom-2 left-1/2 -translate-x-1/2 bg-black/50 backdrop-blur-sm rounded-full px-3 py-1 text-white text-xs">
                  {{ activeMediaIndex + 1 }} / {{ activePost.media.length }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </Teleport>
  
      <input
        type="file"
        ref="profilePhotoInputRef"
        class="hidden"
        accept="image/*"
        @change="handleProfilePhotoChange"
      />
      <input
        type="file"
        ref="coverPhotoInputRef"
        class="hidden"
        accept="image/*"
        @change="handleCoverPhotoChange"
      />
    </div>
  </template>
  
  <script setup>
definePageMeta({
    layout: 'adsy-business-network',
  });
  import { 
    Camera, Edit, MapPin, Briefcase, Calendar, LinkIcon, Grid, List, 
    Settings, UserPlus, Check, BadgeCheck, Mail, Phone, Upload, Trash2, X,
    Home, Bell, User, BarChart2, Bookmark, Heart, MessageCircle, Share2,
    MoreHorizontal, Link2, Flag, Send, Download, ChevronLeft, ChevronRight
  } from 'lucide-vue-next';
  
  // Sample user data
  const userData = {
    id: "user-current",
    name: "Alex Morgan",
    username: "alexmorgan",
    avatar: "/static/frontend/images/placeholder.jpg?height=150&width=150",
    coverPhoto: "/static/frontend/images/placeholder.jpg?height=400&width=1200",
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
  };
  
  // State
  const user = ref(userData);
  const viewMode = ref('list');
  const activeTab = ref('posts');
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
  
  // Tabs
  const tabs = [
    { label: 'Posts', value: 'posts' },
    { label: 'Media', value: 'media' },
    { label: 'Likes', value: 'likes' },
    { label: 'Saved', value: 'saved' },
  ];
  
  // Sample posts data
  const generatePosts = (count) => {
    return Array.from({ length: count }, (_, i) => ({
      id: i + 1,
      title: `Business Strategy Update ${i + 1}: ${["Market Analysis", "Quarterly Report", "Team Building", "Product Launch", "Industry Trends"][i % 5]}`,
      author: {
        id: user.value.id,
        fullName: user.value.name,
        avatar: user.value.avatar,
        verified: user.value.verified,
      },
      timestamp: new Date(Date.now() - i * 3600000).toISOString(),
      content: [
        "Our latest market analysis shows significant growth opportunities in the APAC region. The consumer behavior data indicates a shift towards sustainable products, with a 27% increase in eco-friendly purchases over the last quarter.",
        "The Q3 financial results exceeded expectations with a 15% revenue increase year-over-year. Our cost-cutting initiatives have resulted in a 7% reduction in operational expenses, improving our overall profit margins.",
        "I'm excited to share that our team building workshop last week was a tremendous success. The cross-departmental collaboration exercises resulted in three innovative product ideas that we're now exploring further.",
        "We're thrilled to announce that our new product line will launch on November 15th. The marketing campaign will begin next week, focusing on digital channels and influencer partnerships.",
        "The latest industry report highlights a shift towards AI-powered solutions in our sector. Our R&D team has prepared a comprehensive analysis of how we can leverage these technologies to enhance our product offerings.",
      ][i % 5],
      likeCount: Math.floor(Math.random() * 50) + 5,
      likedBy: [],
      comments: Array.from({ length: Math.floor(Math.random() * 5) }, (_, j) => ({
        id: `comment-${i}-${j}`,
        user: {
          id: `user-${j}`,
          fullName: ["Emma Johnson", "Liam Smith", "Olivia Williams", "Noah Brown", "Ava Jones"][j % 5],
          avatar: `/images/placeholder.jpg?height=40&width=40`,
        },
        text: [
          "Great insight! Thanks for sharing.",
          "I completely agree with your analysis.",
          "This is exactly what our team needed to hear.",
          "Looking forward to discussing this further in our next meeting.",
          "Could you elaborate more on the second point?",
        ][j % 5],
        timestamp: new Date(Date.now() - Math.floor(Math.random() * 86400000 * 7)).toISOString(),
      })),
      media: Array.from({ length: Math.floor(Math.random() * 5) }, (_, j) => ({
        id: `${i}-${j}`,
        type: "image",
        url: `/images/placeholder.jpg?height=300&width=400`,
        thumbnail: `/images/placeholder.jpg?height=150&width=200`,
        likeCount: Math.floor(Math.random() * 20),
        isLiked: false,
      })),
      categories: [
        ["Marketing", "Strategy"][Math.floor(Math.random() * 2)],
        ["Leadership", "Technology", "Operations"][Math.floor(Math.random() * 3)],
      ],
      isLiked: false,
      isSaved: false,
      showDropdown: false,
      showFullDescription: false,
      commentText: '',
    }));
  };
  
  const posts = ref(generatePosts(6));
  
  // Computed
  const allMedia = computed(() => {
    return posts.value.flatMap(post => post.media);
  });
  
  // Methods
  const toggleFollow = () => {
    user.value.isFollowing = !user.value.isFollowing;
    user.value.followers += user.value.isFollowing ? 1 : -1;
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
    alert('Profile updated successfully');
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
      // In a real app, you would upload the file to a server
      // For now, we'll just simulate a successful upload
      setTimeout(() => {
        alert('Profile photo updated successfully');
        isEditPhotoOpen.value = false;
      }, 1000);
    }
  };
  
  const handleCoverPhotoChange = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      // In a real app, you would upload the file to a server
      // For now, we'll just simulate a successful upload
      setTimeout(() => {
        alert('Cover photo updated successfully');
        isEditCoverOpen.value = false;
      }, 1000);
    }
  };
  
  // Format time ago
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
  
  // Toggle like
  const toggleLike = (post) => {
    post.isLiked = !post.isLiked;
    post.likeCount += post.isLiked ? 1 : -1;
  };
  
  // Toggle save
  const toggleSave = (post) => {
    post.isSaved = !post.isSaved;
    post.showDropdown = false;
  };
  
  // Toggle dropdown
  const toggleDropdown = (post) => {
    // Close all other dropdowns first
    posts.value.forEach(p => {
      if (p.id !== post.id) p.showDropdown = false;
    });
    
    post.showDropdown = !post.showDropdown;
  };
  
  // Toggle description
  const toggleDescription = (post) => {
    post.showFullDescription = !post.showFullDescription;
  };
  
  // Copy link
  const copyLink = (post) => {
    const postUrl = `${window.location.origin}/post/${post.id}`;
    navigator.clipboard.writeText(postUrl);
    alert('Link copied to clipboard');
    post.showDropdown = false;
  };
  
  // Share post
  const sharePost = (post) => {
    const postUrl = `${window.location.origin}/post/${post.id}`;
    
    if (navigator.share && navigator.canShare) {
      navigator.share({
        title: post.title,
        text: post.content.substring(0, 100) + (post.content.length > 100 ? "..." : ""),
        url: postUrl,
      }).catch(error => console.error("Error sharing:", error));
    } else {
      alert(`Share URL: ${postUrl}`);
    }
  };
  
  // Add comment
  const addComment = (post) => {
    if (!post.commentText.trim()) return;
    
    const newComment = {
      id: `comment-${Date.now()}`,
      user: {
        id: 'current-user',
        fullName: 'You',
        avatar: '/images/placeholder.jpg?height=40&width=40'
      },
      text: post.commentText,
      timestamp: new Date().toISOString()
    };
    
    post.comments.unshift(newComment);
    post.commentText = '';
  };
  
  // Open media
  const openMedia = (post, index) => {
    activePost.value = post;
    activeMediaIndex.value = index;
    activeMedia.value = post.media[index];
  };
  
  // Navigate media
  const navigateMedia = (direction) => {
    if (!activePost.value || !activeMedia.value) return;
    
    const currentIndex = activeMediaIndex.value;
    const totalMedia = activePost.value.media.length;
    
    if (direction === 'prev') {
      activeMediaIndex.value = (currentIndex - 1 + totalMedia) % totalMedia;
    } else {
      activeMediaIndex.value = (currentIndex + 1) % totalMedia;
    }
    
    activeMedia.value = activePost.value.media[activeMediaIndex.value];
  };
  </script>
  
  <style scoped>
  .border-l-3 {
    border-left-width: 3px;
  }
  </style>