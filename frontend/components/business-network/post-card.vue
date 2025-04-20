<template>
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-all duration-300">
      <div class="p-3">
        <!-- Post Header -->
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center space-x-3">
            <div class="relative">
              <img 
                :src="post.author.avatar" 
                :alt="post.author.fullName" 
                class="w-8 h-8 rounded-full"
              />
              <div 
                v-if="post.author.verified" 
                class="absolute -right-0.5 -bottom-0.5 bg-blue-500 text-white rounded-full p-0.5"
              >
                <CheckIcon class="h-2.5 w-2.5" />
              </div>
            </div>
            <div>
              <NuxtLink 
                :to="`/profile/${post.author.id}`" 
                class="font-medium text-gray-900 text-sm hover:underline flex items-center gap-1"
              >
                {{ post.author.fullName }}
                <div v-if="post.author.verified" class="text-blue-500">
                  <CheckIcon class="h-3.5 w-3.5" />
                </div>
              </NuxtLink>
              <p class="text-xs text-gray-500">{{ formatTimeAgo(post.timestamp) }}</p>
            </div>
          </div>
  
          <div class="flex items-center gap-2">
            <button
              :class="[
                'text-xs h-7 rounded-full px-3 flex items-center gap-1',
                isFollowing ? 'border border-gray-200 text-gray-700' : 'bg-blue-500 text-white'
              ]"
              @click="toggleFollow"
            >
              <component :is="isFollowing ? CheckIcon : UserPlusIcon" class="h-3 w-3" />
              {{ isFollowing ? 'Following' : 'Follow' }}
            </button>
  
            <div class="relative">
              <button 
                class="h-8 w-8 rounded-full hover:bg-gray-100 flex items-center justify-center"
                @click="showMenu = !showMenu"
              >
                <MoreHorizontalIcon class="h-4 w-4" />
              </button>
  
              <!-- Dropdown Menu -->
              <div 
                v-if="showMenu" 
                class="absolute right-0 mt-1 w-56 bg-white rounded-lg shadow-lg border border-gray-200 z-10"
              >
                <div class="py-1">
                  <button
                    class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    @click="toggleSave"
                  >
                    <BookmarkIcon
                      :class="['h-4 w-4 mr-2', post.isSaved ? 'text-blue-500 fill-blue-500' : '']"
                    />
                    {{ post.isSaved ? 'Unsave post' : 'Save post' }}
                  </button>
                  <button
                    class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    @click="copyLink"
                  >
                    <Link2Icon class="h-4 w-4 mr-2" />
                    Copy link
                  </button>
                  <hr class="my-1 border-gray-200" />
                  <button 
                    class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                    @click="reportPost"
                  >
                    <FlagIcon class="h-4 w-4 mr-2" />
                    Report post
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
  
        <!-- Post Title -->
        <NuxtLink 
          :to="`/post/${post.id}`" 
          class="block text-base font-semibold mb-1 hover:text-blue-500 transition-colors"
        >
          {{ post.title }}
        </NuxtLink>
  
        <!-- Categories -->
        <div v-if="post.categories && post.categories.length > 0" class="flex flex-wrap gap-1 mb-2">
          <span 
            v-for="category in post.categories" 
            :key="category" 
            class="text-[10px] bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full"
          >
            {{ category }}
          </span>
        </div>
  
        <!-- Post Content -->
        <div class="mb-2">
          <p 
            :class="['text-sm text-gray-700', !showFullContent && 'line-clamp-4']"
          >
            {{ post.content }}
          </p>
          <button 
            v-if="post.content.length > 280" 
            class="text-xs text-blue-500 font-medium mt-1"
            @click="showFullContent = !showFullContent"
          >
            {{ showFullContent ? 'Read less' : 'Read more' }}
          </button>
        </div>
  
        <!-- Media Gallery -->
        <div v-if="post.media.length > 0" class="mb-3">
          <div class="grid grid-cols-4 gap-1">
            <div
              v-for="(media, index) in post.media.slice(0, 8)"
              :key="media.id"
              class="relative aspect-square cursor-pointer overflow-hidden rounded-md bg-gray-100 transition-transform hover:scale-[1.02]"
              @click="openMedia(index)"
            >
              <img
                :src="media.thumbnail"
                :alt="`Media ${index + 1}`"
                class="h-full w-full object-cover"
              />
              <div v-if="media.type === 'video'" class="absolute inset-0 flex items-center justify-center">
                <div class="h-4 w-4 rounded-full bg-black/50 flex items-center justify-center">
                  <div class="h-0 w-0 border-y-2 border-y-transparent border-l-3 border-l-white ml-0.5"></div>
                </div>
              </div>
              <div v-if="index === 7 && post.media.length > 8" class="absolute inset-0 bg-black/50 flex items-center justify-center">
                <span class="text-white font-medium text-xs">+{{ post.media.length - 8 }}</span>
              </div>
            </div>
          </div>
        </div>
  
        <!-- Post Actions -->
        <div class="flex items-center justify-between pt-2 border-t border-gray-100 mb-3">
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-1">
              <button 
                class="p-1 rounded-full hover:bg-gray-100 transition-colors" 
                @click="toggleLike"
              >
                <HeartIcon 
                  :class="['h-4 w-4', post.isLiked ? 'text-red-500 fill-red-500' : 'text-gray-500']" 
                />
              </button>
              <button 
                class="text-xs text-gray-600 hover:underline" 
                @click="showLikes = true"
              >
                {{ post.likeCount }} likes
              </button>
            </div>
            <button 
              class="flex items-center space-x-1" 
              @click="showComments = true"
            >
              <MessageCircleIcon class="h-4 w-4 text-gray-500" />
              <span class="text-xs text-gray-600">{{ post.comments.length }} comments</span>
            </button>
            <button 
              class="flex items-center space-x-1" 
              @click="sharePost"
            >
              <Share2Icon class="h-4 w-4 text-gray-500" />
              <span class="text-xs text-gray-600">Share</span>
            </button>
            <button 
              class="flex items-center space-x-1" 
              @click="toggleSave"
            >
              <BookmarkIcon 
                :class="['h-4 w-4', post.isSaved ? 'text-blue-500 fill-blue-500' : 'text-gray-500']" 
              />
              <span class="text-xs text-gray-600">Save</span>
            </button>
          </div>
        </div>
  
        <!-- Comments Preview -->
        <div v-if="post.comments.length > 0" class="space-y-2">
          <div 
            v-for="comment in post.comments.slice(0, 2)" 
            :key="comment.id" 
            class="flex items-start space-x-2"
          >
            <img
              :src="comment.user.avatar"
              :alt="comment.user.fullName"
              class="w-5 h-5 rounded-full mt-0.5"
            />
            <div class="flex-1">
              <div class="bg-gray-50 rounded-lg p-2">
                <NuxtLink 
                  :to="`/profile/${comment.user.id}`" 
                  class="text-xs font-medium hover:underline"
                >
                  {{ comment.user.fullName }}
                </NuxtLink>
                <p class="text-xs">{{ comment.text }}</p>
              </div>
              <span class="text-[10px] text-gray-500 mt-1 inline-block">
                {{ formatTimeAgo(comment.timestamp) }}
              </span>
            </div>
          </div>
  
          <button 
            v-if="post.comments.length > 2" 
            class="text-xs text-blue-500 font-medium mt-1"
            @click="showComments = true"
          >
            See all {{ post.comments.length }} comments
          </button>
        </div>
  
        <!-- Add Comment Input -->
        <div class="flex items-center gap-2 mt-3 pt-2 border-t border-gray-100">
          <img src="/images/placeholder.jpg" alt="Your avatar" class="w-6 h-6 rounded-full" />
          <div class="flex-1 relative">
            <input
              type="text"
              placeholder="Add a comment..."
              v-model="commentText"
              class="w-full text-xs py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-500"
              @keyup.enter="addComment"
            />
            <button
              v-if="commentText"
              class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-500"
              @click="addComment"
            >
              <SendIcon class="h-3 w-3" />
            </button>
          </div>
        </div>
      </div>
  
      <!-- Modals -->
      <BusinessNetworkLikesModal 
        v-if="showLikes" 
        :post="post" 
        @close="showLikes = false" 
      />
      
      <BusinessNetworkCommentsModal 
        v-if="showComments" 
        :post="post" 
        @close="showComments = false" 
        @add-comment="addComment"
      />
      
      <BusinessNetworkShareModal 
        v-if="showShare" 
        :post="post" 
        @close="showShare = false" 
      />
    </div>
  </template>
  
  <script setup>
  
  import { 
    Heart as HeartIcon,
    MessageCircle as MessageCircleIcon,
    Share2 as Share2Icon,
    Bookmark as BookmarkIcon,
    Check as CheckIcon,
    UserPlus as UserPlusIcon,
    MoreHorizontal as MoreHorizontalIcon,
    Link2 as Link2Icon,
    Flag as FlagIcon,
    Send as SendIcon
  } from 'lucide-vue-next';
  

  
  const props = defineProps({
    post: {
      type: Object,
      required: true
    }
  });
  
  const emit = defineEmits(['update:post']);
  
  // Local state
  const showFullContent = ref(false);
  const isFollowing = ref(false);
  const showMenu = ref(false);
  const showLikes = ref(false);
  const showComments = ref(false);
  const showShare = ref(false);
  const commentText = ref('');
  
  // Get modal state from parent
  const { openMediaViewer } = inject('modalState');
  
  // Methods
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
  
  const toggleLike = () => {
    const updatedPost = { ...props.post };
    updatedPost.isLiked = !updatedPost.isLiked;
    
    if (updatedPost.isLiked) {
      updatedPost.likeCount++;
      updatedPost.likedBy = [
        { id: 'current-user', fullName: 'You', avatar: '/images/placeholder.jpg' },
        ...updatedPost.likedBy
      ];
    } else {
      updatedPost.likeCount = Math.max(0, updatedPost.likeCount - 1);
      updatedPost.likedBy = updatedPost.likedBy.filter(user => user.id !== 'current-user');
    }
    
    emit('update:post', updatedPost);
  };
  
  const toggleSave = () => {
    const updatedPost = { ...props.post };
    updatedPost.isSaved = !updatedPost.isSaved;
    emit('update:post', updatedPost);
    showMenu.value = false;
  };
  
  const toggleFollow = () => {
    isFollowing.value = !isFollowing.value;
  };
  
  const openMedia = (index) => {
    openMediaViewer({
      postId: props.post.id,
      media: props.post.media,
      currentIndex: index
    });
  };
  
  const sharePost = () => {
    showShare.value = true;
  };
  
  const copyLink = () => {
    const postUrl = `${window.location.origin}/post/${props.post.id}`;
    navigator.clipboard.writeText(postUrl);
    // Show toast notification
    alert('Link copied to clipboard');
    showMenu.value = false;
  };
  
  const reportPost = () => {
    // In a real app, this would open a report dialog
    alert('Post reported');
    showMenu.value = false;
  };
  
  const addComment = () => {
    if (!commentText.value.trim()) return;
    
    const updatedPost = { ...props.post };
    const newComment = {
      id: `comment-${Date.now()}`,
      user: {
        id: 'current-user',
        fullName: 'You',
        avatar: '/images/placeholder.jpg'
      },
      text: commentText.value,
      timestamp: new Date().toISOString()
    };
    
    updatedPost.comments = [newComment, ...updatedPost.comments];
    emit('update:post', updatedPost);
    commentText.value = '';
  };
  
  // Close menu when clicking outside
  const handleClickOutside = (event) => {
    if (showMenu.value && !event.target.closest('.post-menu')) {
      showMenu.value = false;
    }
  };
  
  // Add event listener when component is mounted
  onMounted(() => {
    document.addEventListener('click', handleClickOutside);
  });
  
  // Remove event listener when component is unmounted
  onUnmounted(() => {
    document.removeEventListener('click', handleClickOutside);
  });
  </script>
  
  <style scoped>
  .border-l-3 {
    border-left-width: 3px;
  }
  </style>