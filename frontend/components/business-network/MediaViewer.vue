<template>
  <Teleport to="body">
    <div
      v-if="activeMedia"
      class="fixed inset-0 z-[9999] bg-black/90 flex flex-col items-center justify-start p-4 overflow-auto"
      @click="$emit('close-media')"
    >
      <!-- Header toolbar -->
      <div class="w-full max-w-7xl flex justify-between items-center mb-4 px-2 py-2 bg-black/60 backdrop-blur-sm rounded-lg">
        <div class="text-white font-medium flex items-center">
          <span v-if="activePost && activePost.post_media.length > 1" class="mr-2 px-3 py-1 bg-white/10 rounded-full text-sm">
            {{ activeMediaIndex + 1 }} / {{ activePost.post_media.length }}
          </span>
          <span v-if="activePost?.title" class="truncate max-w-[200px] sm:max-w-[300px]">
            {{ activePost.title }}
          </span>
        </div>
        <button
          class="p-2 rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
          @click.stop="$emit('close-media')"
        >
          <X class="h-6 w-6" />
        </button>
      </div>

      <!-- Current active media (large view) -->
      <div
        class="relative max-w-4xl w-full mb-6 bg-white/5 backdrop-blur-sm rounded-lg overflow-hidden shadow-2xl"
        @click.stop
      >
        <div class="relative flex justify-center items-center py-4">
          <div v-if="activeMedia.type === 'image' || !activeMedia.type" class="relative">
            <img
              :src="activeMedia.image"
              alt="Media preview"
              class="max-h-[70vh] max-w-full object-contain"
            />
            <a
              :href="activeMedia.image"
              :download="`media-${activeMedia.id}`"
              class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
              @click.stop
            >
              <Download class="h-5 w-5" />
            </a>
          </div>
          <div v-else-if="activeMedia.type === 'video'" class="relative">
            <video
              :src="activeMedia.url || activeMedia.video"
              controls
              class="max-h-[70vh] max-w-full"
            ></video>
            <a
              :href="activeMedia.url || activeMedia.video"
              :download="`video-${activeMedia.id}`"
              class="absolute bottom-4 right-4 z-10 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors"
              @click.stop
            >
              <Download class="h-5 w-5" />
            </a>
          </div>
        </div>
      </div>

      <!-- Serial photo viewer grid -->
      <div v-if="activePost && activePost.post_media.length > 1" 
           class="w-full max-w-6xl grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 p-4 bg-white/5 backdrop-blur-sm rounded-lg"
           @click.stop>
        <div
          v-for="(media, index) in activePost.post_media"
          :key="media.id"
          class="relative group cursor-pointer overflow-hidden rounded-lg"
          :class="{'ring-2 ring-blue-500 shadow-lg': activeMediaIndex === index}"
          @click="$emit('navigate-media', index === activeMediaIndex ? null : 'select', index)"
        >
          <div class="aspect-square overflow-hidden">
            <img
              :src="media.image"
              :alt="`Media ${index + 1}`"
              class="h-full w-full object-cover transition-transform duration-200 group-hover:scale-105"
            />
          </div>
          
          <!-- Active indicator -->
          <div v-if="activeMediaIndex === index" 
               class="absolute inset-0 border-2 border-blue-500 rounded-lg"></div>
          
          <!-- Image number -->
          <div class="absolute top-2 right-2 px-2 py-1 bg-black/60 rounded text-white text-xs font-medium">
            {{ index + 1 }}
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
} from "lucide-vue-next";

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

defineEmits([
  "close-media",
  "navigate-media",
  "toggle-media-like",
  "open-media-likes-modal",
  "add-media-comment",
  "edit-media-comment",
  "delete-media-comment",
  "update:media-comment-text",
]);

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
</style>
