<template>  <Teleport to="body">
    <div
      v-if="activeMedia"
      class="fixed inset-0 z-[9999] bg-black/95 flex flex-col items-center justify-start overflow-auto scrollbar-custom"
      @touchstart="handleTouchStart"
      @touchend="handleTouchEnd"
      @click="$emit('close-media')"
    >      <!-- Fixed header with X button that stays visible while scrolling -->      <div class="sticky top-14 left-0 w-full z-[10000] bg-gray-900/70 backdrop-blur-md shadow-lg flex justify-between items-center px-4 py-3">
        <div class="text-white font-medium flex items-center">
          <span v-if="activePost && activePost.post_media.length > 1" class="mr-2 px-3 py-1 bg-gray-800/80 rounded-full text-sm">
            {{ activeMediaIndex + 1 }} / {{ activePost.post_media.length }}
          </span>
          <span v-if="activePost?.title" class="truncate max-w-[200px] sm:max-w-[300px]">
            {{ activePost.title }}
          </span>
          <span v-if="profileMode && profileUser?.name" class="truncate max-w-[200px] sm:max-w-[300px]">
            {{ profileUser.name }}'s Profile Photo
          </span>
          <span v-else-if="profileMode" class="truncate max-w-[200px] sm:max-w-[300px]">
            Profile Photo
          </span>
        </div>
        
        <!-- X button that's always visible -->
        <button
          class="p-2.5 bg-gray-800/80 hover:bg-gray-700 rounded-full shadow-lg transition-all duration-200 border border-gray-700 scale-in"
          @click.stop="$emit('close-media')"
          aria-label="Close viewer"
        >
          <X class="h-5 w-5 text-white" />
        </button>
      </div>      <!-- Serial Photos Container - Displays all photos in a vertical layout -->      <div class="w-full max-w-5xl flex flex-col items-center py-14" @click.stop>
        <!-- Profile Photo Mode -->
        <div 
          v-if="profileMode && activeMedia"          class="w-full md:w-4/5 lg:w-3/4 mb-8 bg-gray-900/70 rounded-xl overflow-hidden shadow-xl border border-gray-800"
        >
          <div class="relative flex justify-center items-center py-10 px-10">
            <div class="relative fade-in">
              <!-- Profile photo with special styling -->
              <div class="relative mx-auto">                <!-- Decorative gradient border for profile photo -->
                <div class="absolute inset-0 rounded-full bg-gradient-to-r from-blue-300 to-indigo-400 p-1 -m-1 blur-sm opacity-80"></div>
                
                <img
                  :src="activeMedia.image || activeMedia.url"
                  :alt="profileUser?.name ? `${profileUser.name}'s profile photo` : 'Profile photo'"
                  class="relative max-h-[85vh] max-w-full object-contain rounded-lg shadow-lg"
                  style="max-width: 80vw;"
                />
                
                <!-- Download button (visible to all users) -->
                <div class="absolute top-4 right-4 z-10">
                  <a 
                    :href="activeMedia.image || activeMedia.url" 
                    :download="`profile-photo`"
                    class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md inline-flex scale-in"
                    title="Download photo"
                  >
                    <Download class="h-4.5 w-4.5 text-blue-500" />
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
          <!-- Loop through all photos if we have more than one and not in profile mode -->
        <template v-if="!profileMode && activePost && activePost.post_media.length > 1">
          <div 
            v-for="(media, index) in activePost.post_media" 
            :key="media.id"
            :id="`media-item-${index}`"
            class="w-full sm:w-3/4 mb-5 bg-gray-900/70 rounded-xl overflow-hidden shadow-xl transform transition-all duration-300 hover:shadow-2xl border border-gray-800"
          >            <div class="relative flex justify-center items-center p-1">
              <!-- Display image -->              
              <div v-if="media.type === 'image' || !media.type" class="relative fade-in">
                <img
                  :src="media.image"
                  alt="Media preview"
                  class="max-h-[85vh] max-w-full object-contain rounded-md"
                  loading="lazy"
                />
                
                <!-- Media counter indicator -->
                <div class="absolute top-4 left-4 px-3 py-1.5 bg-black/70 backdrop-blur-md rounded-full text-white text-xs font-medium shadow-md flex items-center space-x-1.5">
                  <span class="w-2 h-2 rounded-full bg-blue-500"></span>
                  <span>{{ index + 1 }} / {{ activePost.post_media.length }}</span>
                </div>                  
                <!-- Three-dot menu dropdown -->
                <div 
                  v-if="isCurrentUserPostOwner"
                  class="absolute top-4 right-4 z-10"
                >
                  <button 
                    @click.stop="showMediaMenuForItem(index)"
                    class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md scale-in"
                  >
                    <MoreVertical class="h-4.5 w-4.5 text-white" />
                  </button>
                  
                  <!-- Dropdown menu -->
                  <div 
                    v-if="activeMenuIndex === index && showMediaMenu" 
                    class="absolute right-0 mt-2 w-56 rounded-xl shadow-xl bg-gray-900/95 ring-1 ring-gray-700 divide-y divide-gray-800 z-50 overflow-hidden transition-all duration-200 slide-in"
                    @click.stop
                  >
                    <div class="py-1">
                      <a 
                        :href="media.image" 
                        :download="`media-${media.id}`"
                        class="flex items-center px-4 py-3 text-sm text-gray-200 hover:bg-gray-800 transition-colors"
                        @click.stop="showMediaMenu = false"
                      >
                        <Download class="h-4 w-4 mr-3 text-blue-500" />
                        <span>Download photo</span>
                      </a>
                      <button 
                        class="flex w-full items-center px-4 py-3 text-sm text-red-400 hover:bg-gray-800 transition-colors"
                        @click.stop="confirmDeleteMedia(media)"
                      >
                        <Trash2 class="h-4 w-4 mr-3" />
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
                    class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md inline-flex scale-in"
                    title="Download photo"
                  >
                    <Download class="h-4.5 w-4.5 text-blue-500" />
                  </a>
                </div>
              </div>
                <!-- Display video if it's a video type -->
              <div v-else-if="media.type === 'video'" class="relative fade-in">
                <video
                  :src="media.url || media.video"
                  controls
                  class="max-h-[85vh] max-w-full rounded-md"
                ></video>
                
                <!-- Media counter indicator -->
                <div class="absolute top-4 left-4 px-3 py-1.5 bg-black/70 backdrop-blur-md rounded-full text-white text-xs font-medium shadow-md flex items-center space-x-1.5">
                  <span class="w-2 h-2 rounded-full bg-blue-500"></span>
                  <span>{{ index + 1 }} / {{ activePost.post_media.length }}</span>
                </div>
                  <!-- Three-dot menu dropdown for video -->
                <div 
                  v-if="isCurrentUserPostOwner"
                  class="absolute top-4 right-4 z-10"
                >
                  <button 
                    @click.stop="showMediaMenuForItem(index)"
                    class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md scale-in"
                  >
                    <MoreVertical class="h-4.5 w-4.5 text-white" />
                  </button>
                  
                  <!-- Dropdown menu -->
                  <div 
                    v-if="activeMenuIndex === index && showMediaMenu" 
                    class="absolute right-0 mt-2 w-56 rounded-xl shadow-xl bg-gray-900/95 ring-1 ring-gray-700 divide-y divide-gray-800 z-50 overflow-hidden transition-all duration-200 slide-in"
                    @click.stop
                  >
                    <div class="py-1">
                      <a 
                        :href="media.url || media.video" 
                        :download="`video-${media.id}`"
                        class="flex items-center px-4 py-3 text-sm text-gray-200 hover:bg-gray-800 transition-colors"
                        @click.stop="showMediaMenu = false"
                      >
                        <Download class="h-4 w-4 mr-3 text-blue-500" />
                        <span>Download video</span>
                      </a>
                      <button 
                        class="flex w-full items-center px-4 py-3 text-sm text-red-400 hover:bg-gray-800 transition-colors"
                        @click.stop="confirmDeleteMedia(media)"
                      >
                        <Trash2 class="h-4 w-4 mr-3" />
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
                    class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md inline-flex scale-in"
                    title="Download video"
                  >
                    <Download class="h-4.5 w-4.5 text-blue-500" />
                  </a>
                </div>
              </div>
            </div>
          </div>        </template>
          <!-- Single photo view if there's only one photo and not in profile mode -->
        <div 
          v-else-if="!profileMode"
          class="w-full md:w-4/5 lg:w-3/4 mb-8 bg-gray-900/70 rounded-xl overflow-hidden shadow-xl border border-gray-800"
        >
          <div class="relative flex justify-center items-center py-6 px-6">
            <div v-if="activeMedia.type === 'image' || !activeMedia.type" class="relative fade-in">
              <img
                :src="activeMedia.image"
                alt="Media preview"
                class="max-h-[85vh] max-w-full object-contain rounded-md"
              />                <!-- Three-dot menu dropdown (only visible to post owner) -->
              <div 
                v-if="isCurrentUserPostOwner"
                class="absolute top-4 right-4 z-10"
              >
                <button 
                  @click.stop="showMediaMenu = !showMediaMenu"
                  class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md scale-in"
                >
                  <MoreVertical class="h-4.5 w-4.5 text-white" />
                </button>
                
                <!-- Dropdown menu -->
                <div 
                  v-if="showMediaMenu" 
                  class="absolute right-0 mt-2 w-56 rounded-xl shadow-xl bg-gray-900/95 ring-1 ring-gray-700 divide-y divide-gray-800 z-50 overflow-hidden transition-all duration-200 slide-in"
                  @click.stop
                >
                  <div class="py-1">
                    <a 
                      :href="activeMedia.image" 
                      :download="`media-${activeMedia.id}`"
                      class="flex items-center px-4 py-3 text-sm text-gray-200 hover:bg-gray-800 transition-colors"
                      @click.stop="showMediaMenu = false"
                    >
                      <Download class="h-4 w-4 mr-3 text-blue-500" />
                      <span>Download photo</span>
                    </a>
                    <button 
                      class="flex w-full items-center px-4 py-3 text-sm text-red-400 hover:bg-gray-800 transition-colors"
                      @click.stop="confirmDeleteMedia(activeMedia)"
                    >
                      <Trash2 class="h-4 w-4 mr-3" />
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
                  class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md inline-flex scale-in"
                  title="Download photo"
                >
                  <Download class="h-4.5 w-4.5 text-blue-500" />
                </a>
              </div>
            </div>
              <div v-else-if="activeMedia.type === 'video'" class="relative fade-in">
              <video
                :src="activeMedia.url || activeMedia.video"
                controls
                class="max-h-[85vh] max-w-full rounded-md"
              ></video>
                <!-- Three-dot menu dropdown for video (only visible to post owner) -->
              <div 
                v-if="isCurrentUserPostOwner"
                class="absolute top-4 right-4 z-10"
              >
                <button 
                  @click.stop="showMediaMenu = !showMediaMenu"
                  class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md scale-in"
                >
                  <MoreVertical class="h-4.5 w-4.5 text-white" />
                </button>
                
                <!-- Dropdown menu -->
                <div 
                  v-if="showMediaMenu" 
                  class="absolute right-0 mt-2 w-56 rounded-xl shadow-xl bg-gray-900/95 ring-1 ring-gray-700 divide-y divide-gray-800 z-50 overflow-hidden transition-all duration-200 slide-in"
                  @click.stop
                >
                  <div class="py-1">
                    <a 
                      :href="activeMedia.url || activeMedia.video" 
                      :download="`video-${activeMedia.id}`"
                      class="flex items-center px-4 py-3 text-sm text-gray-200 hover:bg-gray-800 transition-colors"
                      @click.stop="showMediaMenu = false"
                    >
                      <Download class="h-4 w-4 mr-3 text-blue-500" />
                      <span>Download video</span>
                    </a>
                    <button 
                      class="flex w-full items-center px-4 py-3 text-sm text-red-400 hover:bg-gray-800 transition-colors"
                      @click.stop="confirmDeleteMedia(activeMedia)"
                    >
                      <Trash2 class="h-4 w-4 mr-3" />
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
                  class="p-2.5 rounded-full bg-black/70 hover:bg-black/90 transition-all duration-200 shadow-md inline-flex scale-in"
                  title="Download video"
                >
                  <Download class="h-4.5 w-4.5 text-blue-500" />
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
      class="fixed inset-0 bg-black/90 backdrop-blur-sm flex items-center justify-center z-[10001]"
      @click.stop="showDeleteConfirm = false"
    >
      <div 
        class="bg-gray-900 rounded-xl shadow-2xl max-w-md w-full p-6 m-4 border border-gray-800 scale-in"
        @click.stop
      >
        <h3 class="text-lg font-medium text-white mb-4 flex items-center">
          <Trash2 class="h-5 w-5 text-red-400 mr-2" /> 
          Delete photo?
        </h3>
        <p class="text-gray-300 mb-5">
          Are you sure you want to delete this photo? This action cannot be undone.
        </p>
        <div class="flex justify-end space-x-3">
          <button 
            class="px-4 py-2.5 text-sm font-medium text-gray-300 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors"
            @click.stop="showDeleteConfirm = false"
          >
            Cancel
          </button>
          <button 
            class="px-4 py-2.5 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors"
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
  // New prop for profile photo mode
  profileMode: {
    type: Boolean,
    default: false
  },
  // Profile user object for displaying name in header
  profileUser: {
    type: Object,
    default: null
  }
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
  width: 6px; /* Slightly thinner scrollbar */
}

.scrollbar-custom::-webkit-scrollbar-track {
  background: rgba(241, 241, 241, 0.1); /* Subtle transparent track */
}

.scrollbar-custom::-webkit-scrollbar-thumb {
  background: rgba(136, 136, 136, 0.6); /* Semi-transparent thumb */
  border-radius: 10px; /* More rounded corners */
}

.scrollbar-custom::-webkit-scrollbar-thumb:hover {
  background: rgba(85, 85, 85, 0.8); /* Darker on hover but still semi-transparent */
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

/* Add slide-in animation for menu */
@keyframes slideIn {
  from {
    transform: translateY(-10px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.slide-in {
  animation: slideIn 0.2s ease-out;
}

/* Add scale animation for buttons */
@keyframes scaleIn {
  from {
    transform: scale(0.95);
  }
  to {
    transform: scale(1);
  }
}

.scale-in {
  animation: scaleIn 0.15s ease-out;
}
</style>
