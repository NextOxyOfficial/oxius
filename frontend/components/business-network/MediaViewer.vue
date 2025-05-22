<template>
  <Teleport to="body">
    <div
      v-if="activeMedia"
      class="fixed inset-0 z-[9999] bg-black/95 flex flex-col items-center justify-start p-4 overflow-auto"
      @click="$emit('close-media')"
      @touchstart="handleTouchStart"
      @touchend="handleTouchEnd"
    >
      <!-- X button to close the viewer (with white background for visibility) -->
      <button
        class="absolute top-4 right-4 z-[10000] p-3 bg-white rounded-full shadow-lg transition-colors hover:bg-gray-100"
        @click.stop="$emit('close-media')"
        aria-label="Close viewer"
      >
        <X class="h-6 w-6 text-black" />
      </button>

      <!-- Header toolbar -->
      <div class="w-full max-w-7xl flex justify-between items-center mb-4 px-4 py-3 mt-12">
        <div class="text-white font-medium flex items-center">
          <span v-if="activePost && activePost.post_media.length > 1" class="mr-2 px-3 py-1 bg-white/10 rounded-full text-sm">
            {{ activeMediaIndex + 1 }} / {{ activePost.post_media.length }}
          </span>
          <span v-if="activePost?.title" class="truncate max-w-[200px] sm:max-w-[300px]">
            {{ activePost.title }}
          </span>
        </div>
      </div>

      <!-- Single-photo serial view with white background -->
      <div class="w-full max-w-4xl flex flex-col items-center" @click.stop>
        <!-- Current active media -->
        <div class="relative w-full mb-4 bg-white rounded-lg overflow-hidden shadow-2xl">
          <div class="relative flex justify-center items-center py-6 px-6">
            <div v-if="activeMedia.type === 'image' || !activeMedia.type" class="relative">
              <img
                :src="activeMedia.image"
                alt="Media preview"
                class="max-h-[70vh] max-w-full object-contain"
              />
              <!-- Three-dot menu dropdown -->
              <div class="absolute top-4 right-4 z-10">
                <button 
                  @click.stop="showMediaMenu = !showMediaMenu"
                  class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors"
                >
                  <MoreVertical class="h-5 w-5 text-gray-700" />
                </button>
                
                <!-- Dropdown menu -->
                <div 
                  v-if="showMediaMenu" 
                  class="absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white dark:bg-slate-800 ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 dark:divide-gray-700 z-50"
                  @click.stop
                >
                  <div class="py-1">
                    <a 
                      :href="activeMedia.image" 
                      :download="`media-${activeMedia.id}`"
                      class="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
                      @click.stop="showMediaMenu = false"
                    >
                      <Download class="h-4 w-4 mr-2" />
                      <span>Download photo</span>
                    </a>
                    <button 
                      class="flex w-full items-center px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700"
                      @click.stop="confirmDeleteMedia"
                    >
                      <Trash2 class="h-4 w-4 mr-2" />
                      <span>Delete photo</span>
                    </button>
                  </div>
                </div>
              </div>
              
              <!-- Delete confirmation modal -->
              <div 
                v-if="showDeleteConfirm" 
                class="fixed inset-0 bg-black/80 flex items-center justify-center z-[10001]"
                @click.stop="showDeleteConfirm = false"
              >
                <div 
                  class="bg-white dark:bg-slate-800 rounded-lg shadow-xl max-w-md w-full p-6 m-4"
                  @click.stop
                >
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Delete photo?</h3>
                  <p class="text-gray-600 dark:text-gray-300 mb-5">
                    Are you sure you want to delete this photo? This action cannot be undone.
                  </p>
                  <div class="flex justify-end space-x-3">
                    <button 
                      class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 rounded-md hover:bg-gray-200 dark:hover:bg-gray-600"
                      @click.stop="showDeleteConfirm = false"
                    >
                      Cancel
                    </button>
                    <button 
                      class="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700"
                      @click.stop="deleteMedia"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <div v-else-if="activeMedia.type === 'video'" class="relative">
              <video
                :src="activeMedia.url || activeMedia.video"
                controls
                class="max-h-[70vh] max-w-full"
              ></video>
              <!-- Three-dot menu dropdown for video -->
              <div class="absolute top-4 right-4 z-10">
                <button 
                  @click.stop="showMediaMenu = !showMediaMenu"
                  class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors"
                >
                  <MoreVertical class="h-5 w-5 text-gray-700" />
                </button>
                
                <!-- Dropdown menu -->
                <div 
                  v-if="showMediaMenu" 
                  class="absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white dark:bg-slate-800 ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 dark:divide-gray-700 z-50"
                  @click.stop
                >
                  <div class="py-1">
                    <a 
                      :href="activeMedia.url || activeMedia.video" 
                      :download="`video-${activeMedia.id}`"
                      class="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
                      @click.stop="showMediaMenu = false"
                    >
                      <Download class="h-4 w-4 mr-2" />
                      <span>Download video</span>
                    </a>
                    <button 
                      class="flex w-full items-center px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700"
                      @click.stop="confirmDeleteMedia"
                    >
                      <Trash2 class="h-4 w-4 mr-2" />
                      <span>Delete video</span>
                    </button>
                  </div>
                </div>
              </div>
              
              <!-- Delete confirmation modal is shared with image type -->
            </div>
          </div>
        </div>
        
        <!-- Navigation controls at the bottom -->
        <div v-if="activePost && activePost.post_media.length > 1" class="flex justify-between w-full max-w-4xl mb-6">
          <button
            @click.stop="$emit('navigate-media', 'prev')"
            class="flex items-center gap-2 px-4 py-2 bg-white rounded-lg shadow text-gray-700 hover:bg-gray-100 transition-colors"
          >
            <ChevronLeft class="h-5 w-5" />
            <span>Previous</span>
          </button>
          
          <div class="flex items-center">
            <span class="px-3 py-1 bg-white rounded-full text-sm font-medium text-gray-700">
              {{ activeMediaIndex + 1 }} / {{ activePost.post_media.length }}
            </span>
          </div>
          
          <button
            @click.stop="$emit('navigate-media', 'next')"
            class="flex items-center gap-2 px-4 py-2 bg-white rounded-lg shadow text-gray-700 hover:bg-gray-100 transition-colors"
          >
            <span>Next</span>
            <ChevronRight class="h-5 w-5" />
          </button>
        </div>
        
        <!-- Image thumbnails in a single row -->
        <div 
          v-if="activePost && activePost.post_media.length > 1"
          class="w-full max-w-4xl overflow-x-auto scrollbar-hide py-4 px-2 bg-white/10 rounded-lg"
        >
          <div class="flex gap-3 min-w-max">
            <div
              v-for="(media, index) in activePost.post_media"
              :key="media.id"
              class="relative flex-shrink-0 w-16 h-16 cursor-pointer rounded-lg overflow-hidden transition-all duration-200"
              :class="activeMediaIndex === index ? 'ring-3 ring-blue-600 scale-110 z-10' : 'ring-1 ring-gray-300 hover:ring-blue-400'"
              @click.stop="$emit('navigate-media', 'select', index)"
            >
              <img
                :src="media.image"
                :alt="`Media ${index + 1}`"
                class="h-full w-full object-cover"
              />
              <div class="absolute inset-0 flex items-center justify-center bg-black/40" 
                   :class="{'opacity-0': activeMediaIndex === index}">
                <span class="text-white font-medium">{{ index + 1 }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import {
  X,
  ChevronLeft,
  ChevronRight,
  Heart,
  MessageCircle,
  Send,
  Download,
  MoreVertical,
  Trash2,
} from "lucide-vue-next";
import { onMounted, onUnmounted, ref } from 'vue';

// Get toast utility
const toast = useToast();

const props = defineProps({
  activeMedia: {
    type: Object,
    default: null,
  },
  activePost: {
    type: Object,
    default: null,
  },
  activeMediaIndex: {
    type: Number,
    default: 0,
  },
  mediaCommentText: {
    type: String,
    default: "",
  },
  user: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits([
  "close-media",
  "navigate-media",
  "toggle-media-like",
  "open-media-likes-modal",
  "add-media-comment",
  "edit-media-comment",
  "delete-media-comment",
  "update:media-comment-text",
]);

// Add keyboard navigation
const handleKeyDown = (event) => {
  if (!props.activeMedia) return;
  
  if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
    emit('navigate-media', 'next');
  } else if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
    emit('navigate-media', 'prev');
  } else if (event.key === 'Escape') {
    emit('close-media');
  }
};

// Register and clean up event listeners
onMounted(() => {
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {  
  window.removeEventListener('keydown', handleKeyDown);
});

// Touch gesture handlers
const touchStartX = ref(0);
const touchStartY = ref(0);

// Media menu state
const showMediaMenu = ref(false);
const showDeleteConfirm = ref(false);

const handleTouchStart = (event) => {
  touchStartX.value = event.touches[0].clientX;
  touchStartY.value = event.touches[0].clientY;
};

const handleTouchEnd = (event) => {
  if (!props.activePost || props.activePost.post_media.length <= 1) return;
  
  const touchEndX = event.changedTouches[0].clientX;
  const touchEndY = event.changedTouches[0].clientY;
  
  const diffX = touchEndX - touchStartX.value;
  const diffY = touchEndY - touchStartY.value;
  
  // Check if the swipe was more horizontal than vertical and if it was significant enough
  if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 50) {
    event.stopPropagation(); // Prevent closing the modal
    
    // Left swipe (next image)
    if (diffX < 0) {
      emit('navigate-media', 'next');
    } 
    // Right swipe (previous image)
    else {
      emit('navigate-media', 'prev');
    }
  }
};

// Media menu functions
const confirmDeleteMedia = () => {
  // Check if this is the user's own post before allowing deletion
  if (!user.value || (activePost.value && activePost.value.author !== user.value.user?.id)) {
    toast.add({
      title: "You can only delete your own photos",
      color: "red",
    });
    showMediaMenu.value = false;
    return;
  }
  
  showMediaMenu.value = false;
  showDeleteConfirm.value = true;
};

const deleteMedia = () => {
  // Here you would implement the actual delete functionality
  // For now, we'll just close the modal and emit an event that the parent can handle
  showDeleteConfirm.value = false;
  emit('delete-media-comment', props.activeMedia);
  emit('close-media'); // Close the viewer after delete
  
  // Show a toast notification
  toast.add({
    title: "Photo deleted successfully",
    color: "green",
  });
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
</script>

<style scoped>
/* Add smooth transitions for hover effects */
.transition-transform {
  transition: transform 0.3s ease-out;
}

/* Optional zoom effect on hover */
.group:hover img {
  transform: scale(1.05);
}

/* Smoothly highlight the active image */
.ring-blue-500 {
  transition: all 0.2s ease-out;
}

/* Hide scrollbar but maintain functionality */
.scrollbar-hide {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}
.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Opera */
}

/* Slide animations for images */
@keyframes fadeInSlideUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.fade-slide-enter-active {
  animation: fadeInSlideUp 0.3s ease-out;
}
</style>
