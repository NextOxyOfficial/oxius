<template>
    <div
      class="fixed inset-0 z-[9999] bg-black/80 flex items-center justify-center p-4"
      @click="$emit('close')"
    >
      <div
        class="relative max-w-3xl w-full max-h-[80vh] bg-white rounded-lg overflow-hidden flex flex-col"
        @click.stop
      >
        <button
          class="absolute right-2 top-2 z-10 p-1 rounded-full bg-black/50 text-white"
          @click="$emit('close')"
        >
          <XIcon class="h-6 w-6" />
        </button>
  
        <div class="flex-1 overflow-hidden relative">
          <div v-if="currentMedia.type === 'image'" class="relative h-[45vh] w-full">
            <img
              :src="currentMedia.url"
              alt="Media preview"
              class="object-contain h-full w-full"
            />
            <a
              :href="currentMedia.url"
              download
              class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
              @click.stop
            >
              <DownloadIcon class="h-5 w-5" />
            </a>
          </div>
          <div v-else class="relative">
            <video :src="currentMedia.url" controls class="w-full h-auto max-h-[45vh]"></video>
            <a
              :href="currentMedia.url"
              download
              class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
              @click.stop
            >
              <DownloadIcon class="h-5 w-5" />
            </a>
          </div>
  
          <!-- Media navigation -->
          <div v-if="media.length > 1">
            <button
              class="absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 rounded-full p-2 text-white touch-manipulation transition-all hover:scale-110"
              @click.stop="navigatePrevious"
            >
              <ChevronLeftIcon class="h-5 w-5" />
            </button>
            <button
              class="absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 rounded-full p-2 text-white touch-manipulation transition-all hover:scale-110"
              @click.stop="navigateNext"
            >
              <ChevronRightIcon class="h-5 w-5" />
            </button>
            <div class="absolute bottom-2 left-1/2 -translate-x-1/2 bg-black/50 backdrop-blur-sm rounded-full px-3 py-1 text-white text-xs">
              {{ currentIndex + 1 }} / {{ media.length }}
            </div>
          </div>
        </div>
  
        <div class="p-4 border-t border-gray-200">
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center space-x-4">
              <div class="flex items-center space-x-1">
                <button
                  class="p-1 rounded-full hover:bg-gray-100 transition-colors"
                  @click.stop="toggleLike"
                >
                  <HeartIcon
                    :class="['h-4 w-4', isLiked ? 'text-red-500 fill-red-500' : 'text-gray-500']"
                  />
                </button>
                <button
                  class="text-xs text-gray-600 hover:underline"
                  @click.stop="showLikes = true"
                >
                  {{ likeCount }} likes
                </button>
              </div>
              <div class="flex items-center space-x-1">
                <MessageCircleIcon class="h-4 w-4 text-gray-500" />
                <span class="text-xs text-gray-600">
                  {{ comments.length }} comments
                </span>
              </div>
            </div>
          </div>
  
          <!-- Comments -->
          <div v-if="comments.length > 0" class="max-h-[20vh] overflow-y-auto mb-3">
            <h4 class="text-xs font-medium text-gray-500 mb-2">Comments</h4>
            <div class="space-y-2">
              <div
                v-for="comment in comments"
                :key="comment.id"
                class="flex items-start space-x-2"
              >
                <img
                  :src="comment.user.avatar"
                  :alt="comment.user.fullName"
                  class="w-6 h-6 rounded-full mt-0.5"
                />
                <div class="flex-1">
                  <div class="bg-gray-50 rounded-lg p-2">
                    <router-link
                      :to="`/profile/${comment.user.id}`"
                      class="text-xs font-medium hover:underline"
                    >
                      {{ comment.user.fullName }}
                    </router-link>
                    <p class="text-xs">{{ comment.text }}</p>
                  </div>
                  <span class="text-[10px] text-gray-500">{{ formatTimeAgo(comment.timestamp) }}</span>
                </div>
              </div>
            </div>
          </div>
  
          <!-- Add comment -->
          <div class="flex items-center gap-2">
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
                @click.stop="addComment"
              >
                <SendIcon class="h-3 w-3" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref, computed } from 'vue';
  import { 
    X as XIcon,
    ChevronLeft as ChevronLeftIcon,
    ChevronRight as ChevronRightIcon,
    Download as DownloadIcon,
    Heart as HeartIcon,
    MessageCircle as MessageCircleIcon,
    Send as SendIcon
  } from 'lucide-vue-next';
  
  const props = defineProps({
    media: {
      type: Array,
      required: true
    },
    currentIndex: {
      type: Number,
      default: 0
    },
    postId: {
      type: [String, Number],
      required: true
    }
  });
  
  const emit = defineEmits(['close', 'update:media']);
  
  // Local state
  const index = ref(props.currentIndex);
  const commentText = ref('');
  const showLikes = ref(false);
  
  // Computed properties
  const currentMedia = computed(() => props.media[index.value]);
  const isLiked = computed(() => currentMedia.value.likedBy?.some(user => user.id === 'current-user') || false);
  const likeCount = computed(() => currentMedia.value.likeCount || 0);
  const comments = computed(() => currentMedia.value.comments || []);
  
  // Methods
  const navigatePrevious = () => {
    index.value = (index.value - 1 + props.media.length) % props.media.length;
  };
  
  const navigateNext = () => {
    index.value = (index.value + 1) % props.media.length;
  };
  
  const toggleLike = () => {
    const updatedMedia = [...props.media];
    const mediaToUpdate = {...updatedMedia[index.value]};
    
    if (isLiked.value) {
      mediaToUpdate.likeCount = Math.max(0, mediaToUpdate.likeCount - 1);
      mediaToUpdate.likedBy = mediaToUpdate.likedBy.filter(user => user.id !== 'current-user');
    } else {
      mediaToUpdate.likeCount = (mediaToUpdate.likeCount || 0) + 1;
      mediaToUpdate.likedBy = [
        { id: 'current-user', fullName: 'You', avatar: '/images/placeholder.jpg' },
        ...(mediaToUpdate.likedBy || [])
      ];
    }
    
    updatedMedia[index.value] = mediaToUpdate;
    emit('update:media', updatedMedia);
  };
  
  const addComment = () => {
    if (!commentText.value.trim()) return;
    
    const updatedMedia = [...props.media];
    const mediaToUpdate = {...updatedMedia[index.value]};
    
    const newComment = {
      id: `media-comment-${Date.now()}`,
      user: {
        id: 'current-user',
        fullName: 'You',
        avatar: '/images/placeholder.jpg'
      },
      text: commentText.value,
      timestamp: new Date().toISOString()
    };
    
    mediaToUpdate.comments = [
      ...(mediaToUpdate.comments || []),
      newComment
    ];
    
    updatedMedia[index.value] = mediaToUpdate;
    emit('update:media', updatedMedia);
    
    commentText.value = '';
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
  </script>