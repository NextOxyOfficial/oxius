<template>
  <Teleport to="body">
    <div
      v-if="activeMedia"
      class="fixed inset-0 z-[9999] mt-14 bg-white flex flex-col items-center justify-start overflow-auto scrollbar-custom"
      @touchstart="handleTouchStart"
      @touchend="handleTouchEnd"
    >
      <!-- Fixed header with X button that stays visible while scrolling -->
      <div class="sticky top-0 left-0 w-full z-[10000] bg-white shadow-sm flex justify-between items-center px-4 py-3">
        <div class="text-black font-medium flex items-center">
          <span v-if="activePost && activePost.post_media.length > 1" class="mr-2 px-3 py-1 bg-gray-100 rounded-full text-sm">
            {{ activeMediaIndex + 1 }} / {{ activePost.post_media.length }}
          </span>
          <span v-if="activePost?.title" class="truncate max-w-[200px] sm:max-w-[300px]">
            {{ activePost.title }}
          </span>
        </div>
        
        <!-- X button that's always visible -->
        <button
          class="p-3 bg-white rounded-full shadow-sm transition-colors hover:bg-gray-100 border-2 border-gray-300"
          @click.stop="$emit('close-media')"
          aria-label="Close viewer"
        >
          <X class="h-6 w-6 text-black" />
        </button>
      </div>

      <!-- Serial Photos Container - Displays all photos in a vertical layout -->
      <div class="w-full max-w-4xl flex flex-col items-center py-4" @click.stop>
        <!-- Loop through all photos if we have more than one -->
        <template v-if="activePost && activePost.post_media.length > 1">
          <div 
            v-for="(media, index) in activePost.post_media" 
            :key="media.id"
            :id="`media-item-${index}`"
            class="w-full mb-8 bg-white rounded-lg overflow-hidden shadow-sm"
          >
            <div class="relative flex justify-center items-center p-2">
              <!-- Display image -->
              <div v-if="media.type === 'image' || !media.type" class="relative">
                <img
                  :src="media.image"
                  alt="Media preview"
                  class="max-h-[85vh] max-w-full object-contain"
                  loading="lazy"
                />
                
                <!-- Media counter indicator -->
                <div class="absolute top-4 left-4 px-3 py-1 bg-black/50 rounded-full text-white text-sm">
                  {{ index + 1 }} / {{ activePost.post_media.length }}
                </div>
                  <!-- Three-dot menu dropdown -->
                <div 
                  v-if="isCurrentUserPostOwner"
                  class="absolute top-4 right-4 z-10"
                >
                  <button 
                    @click.stop="showMediaMenuForItem(index)"
                    class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors"
                  >
                    <MoreVertical class="h-5 w-5 text-gray-700" />
                  </button>
                  
                  <!-- Dropdown menu -->
                  <div 
                    v-if="activeMenuIndex === index && showMediaMenu" 
                    class="absolute right-0 mt-2 w-48 rounded-md shadow-sm bg-white dark:bg-slate-800 ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 dark:divide-gray-700 z-50"
                    @click.stop
                  >
                    <div class="py-1">
                      <a 
                        :href="media.image" 
                        :download="`media-${media.id}`"
                        class="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
                        @click.stop="showMediaMenu = false"
                      >
                        <Download class="h-4 w-4 mr-2" />
                        <span>Download photo</span>
                      </a>
                      <button 
                        class="flex w-full items-center px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700"
                        @click.stop="confirmDeleteMedia(media)"
                      >
                        <Trash2 class="h-4 w-4 mr-2" />
                        <span>Delete photo</span>
                      </button>
                    </div>
                  </div>
                </div>
                
                <!-- Download button (visible to all users) -->
                <div 
                  v-if="!isCurrentUserPostOwner" 
                  class="absolute top-4 right-4 z-10"
                >
                  <a 
                    :href="media.image" 
                    :download="`media-${media.id}`"
                    class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors inline-flex"
                    title="Download photo"
                  >
                    <Download class="h-5 w-5 text-gray-700" />
                  </a>
                </div>
              </div>
              
              <!-- Display video if it's a video type -->
              <div v-else-if="media.type === 'video'" class="relative">
                <video
                  :src="media.url || media.video"
                  controls
                  class="max-h-[85vh] max-w-full"
                ></video>
                
                <!-- Media counter indicator -->
                <div class="absolute top-4 left-4 px-3 py-1 bg-black/50 rounded-full text-white text-sm">
                  {{ index + 1 }} / {{ activePost.post_media.length }}
                </div>
                  <!-- Three-dot menu dropdown for video -->
                <div 
                  v-if="isCurrentUserPostOwner"
                  class="absolute top-4 right-4 z-10"
                >
                  <button 
                    @click.stop="showMediaMenuForItem(index)"
                    class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors"
                  >
                    <MoreVertical class="h-5 w-5 text-gray-700" />
                  </button>
                  
                  <!-- Dropdown menu -->
                  <div 
                    v-if="activeMenuIndex === index && showMediaMenu" 
                    class="absolute right-0 mt-2 w-48 rounded-md shadow-sm bg-white dark:bg-slate-800 ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 dark:divide-gray-700 z-50"
                    @click.stop
                  >
                    <div class="py-1">
                      <a 
                        :href="media.url || media.video" 
                        :download="`video-${media.id}`"
                        class="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
                        @click.stop="showMediaMenu = false"
                      >
                        <Download class="h-4 w-4 mr-2" />
                        <span>Download video</span>
                      </a>
                      <button 
                        class="flex w-full items-center px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700"
                        @click.stop="confirmDeleteMedia(media)"
                      >
                        <Trash2 class="h-4 w-4 mr-2" />
                        <span>Delete video</span>
                      </button>
                    </div>
                  </div>
                </div>
                
                <!-- Download button for video (visible to all users) -->
                <div 
                  v-if="!isCurrentUserPostOwner" 
                  class="absolute top-4 right-4 z-10"
                >
                  <a 
                    :href="media.url || media.video" 
                    :download="`video-${media.id}`"
                    class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors inline-flex"
                    title="Download video"
                  >
                    <Download class="h-5 w-5 text-gray-700" />
                  </a>
                </div>
              </div>
            </div>
          </div>
        </template>
        
        <!-- Single photo view if there's only one photo -->
        <div 
          v-else 
          class="w-full mb-8 bg-white rounded-lg overflow-hidden shadow-sm"
        >
          <div class="relative flex justify-center items-center py-6 px-6">
            <div v-if="activeMedia.type === 'image' || !activeMedia.type" class="relative">
              <img
                :src="activeMedia.image"
                alt="Media preview"
                class="max-h-[85vh] max-w-full object-contain"
              />
                <!-- Three-dot menu dropdown (only visible to post owner) -->
              <div 
                v-if="isCurrentUserPostOwner"
                class="absolute top-4 right-4 z-10"
              >
                <button 
                  @click.stop="showMediaMenu = !showMediaMenu"
                  class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors"
                >
                  <MoreVertical class="h-5 w-5 text-gray-700" />
                </button>
                
                <!-- Dropdown menu -->
                <div 
                  v-if="showMediaMenu" 
                  class="absolute right-0 mt-2 w-48 rounded-md shadow-sm bg-white dark:bg-slate-800 ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 dark:divide-gray-700 z-50"
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
                      @click.stop="confirmDeleteMedia(activeMedia)"
                    >
                      <Trash2 class="h-4 w-4 mr-2" />
                      <span>Delete photo</span>
                    </button>
                  </div>
                </div>
              </div>
              
              <!-- Download button (visible to all users) -->
              <div 
                v-if="!isCurrentUserPostOwner" 
                class="absolute top-4 right-4 z-10"
              >
                <a 
                  :href="activeMedia.image" 
                  :download="`media-${activeMedia.id}`"
                  class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors inline-flex"
                  title="Download photo"
                >
                  <Download class="h-5 w-5 text-gray-700" />
                </a>
              </div>
            </div>
            
            <div v-else-if="activeMedia.type === 'video'" class="relative">
              <video
                :src="activeMedia.url || activeMedia.video"
                controls
                class="max-h-[85vh] max-w-full"
              ></video>
                <!-- Three-dot menu dropdown for video (only visible to post owner) -->
              <div 
                v-if="isCurrentUserPostOwner"
                class="absolute top-4 right-4 z-10"
              >
                <button 
                  @click.stop="showMediaMenu = !showMediaMenu"
                  class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors"
                >
                  <MoreVertical class="h-5 w-5 text-gray-700" />
                </button>
                
                <!-- Dropdown menu -->
                <div 
                  v-if="showMediaMenu" 
                  class="absolute right-0 mt-2 w-48 rounded-md shadow-sm bg-white dark:bg-slate-800 ring-1 ring-black ring-opacity-5 divide-y divide-gray-100 dark:divide-gray-700 z-50"
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
                      @click.stop="confirmDeleteMedia(activeMedia)"
                    >
                      <Trash2 class="h-4 w-4 mr-2" />
                      <span>Delete video</span>
                    </button>
                  </div>
                </div>
              </div>
              
              <!-- Download button for video (visible to all users) -->
              <div 
                v-if="!isCurrentUserPostOwner" 
                class="absolute top-4 right-4 z-10"
              >
                <a 
                  :href="activeMedia.url || activeMedia.video" 
                  :download="`video-${activeMedia.id}`"
                  class="p-2 rounded-full bg-gray-200 hover:bg-gray-300 transition-colors inline-flex"
                  title="Download video"
                >
                  <Download class="h-5 w-5 text-gray-700" />
                </a>
              </div>
            </div>
          </div>
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
        class="bg-white dark:bg-slate-800 rounded-lg shadow-sm max-w-md w-full p-6 m-4"
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
import { onMounted, onUnmounted, ref, watch, nextTick, computed } from 'vue';

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

// Media menu states
const showMediaMenu = ref(false);
const showDeleteConfirm = ref(false);
const activeMenuIndex = ref(null);
const mediaToDelete = ref(null);

// Computed property to check if current user is the post owner
const isCurrentUserPostOwner = computed(() => {
  if (!props.user || !props.activePost?.author) {
    return false;
  }
  return props.user.user?.id === props.activePost.author;
});

// Show media menu for a specific item
const showMediaMenuForItem = (index) => {
  if (activeMenuIndex.value === index && showMediaMenu.value) {
    showMediaMenu.value = false;
  } else {
    activeMenuIndex.value = index;
    showMediaMenu.value = true;
  }
};

// Scroll to the active media when opening the viewer
watch(() => props.activeMedia, (newVal) => {
  if (newVal && props.activePost && props.activePost.post_media.length > 1) {
    // Use nextTick to ensure DOM is updated
    nextTick(() => {
      const element = document.getElementById(`media-item-${props.activeMediaIndex}`);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  }
});

// Add keyboard navigation for close
const handleKeyDown = (event) => {
  if (!props.activeMedia) return;
  
  if (event.key === 'Escape') {
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

const handleTouchStart = (event) => {
  touchStartX.value = event.touches[0].clientX;
  touchStartY.value = event.touches[0].clientY;
};

const handleTouchEnd = (event) => {
  const touchEndX = event.changedTouches[0].clientX;
  const touchEndY = event.changedTouches[0].clientY;
  
  const diffX = touchEndX - touchStartX.value;
  const diffY = touchEndY - touchStartY.value;
  
  // If horizontal swipe is much stronger than vertical, handle as a close gesture
  if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 100) {
    // Right swipe to close (mimics common mobile pattern)
    if (diffX > 0) {
      emit('close-media');
    }
  }
};

// Media menu functions
const confirmDeleteMedia = (media) => {
  // Check if this is the user's own post before allowing deletion
  if (!isCurrentUserPostOwner.value) {
    toast.add({
      title: "You can only delete your own photos",
      color: "red",
    });
    showMediaMenu.value = false;
    return;
  }
  
  mediaToDelete.value = media;
  showMediaMenu.value = false;
  showDeleteConfirm.value = true;
};

const deleteMedia = () => {
  // Here you would implement the actual delete functionality
  showDeleteConfirm.value = false;
  emit('delete-media-comment', mediaToDelete.value || props.activeMedia);
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

/* Hide scrollbar but maintain functionality */
.scrollbar-hide {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE and Edge */
}
.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Chrome, Safari, Opera */
}

/* Custom scrollbar for vertical serial view */
.scrollbar-custom::-webkit-scrollbar {
  width: 8px;
}

.scrollbar-custom::-webkit-scrollbar-track {
  background: #f1f1f1;
}

.scrollbar-custom::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 4px;
}

.scrollbar-custom::-webkit-scrollbar-thumb:hover {
  background: #555;
}

/* Smooth fade-in animation for images */
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.fade-in {
  animation: fadeIn 0.4s ease-in-out;
}
</style>
