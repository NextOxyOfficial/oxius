<template>
  <Teleport to="body">
    <div
      v-if="activeMedia"
      class="fixed inset-0 z-[9999] bg-black/80 flex items-center justify-center p-4"
      @click="$emit('close-media')"
    >
      <div
        class="relative max-w-3xl w-full max-h-[75vh] bg-white rounded-lg overflow-hidden flex flex-col"
        @click.stop
      >
        <button
          class="absolute right-2 top-2 z-10 p-1 rounded-full bg-black/50 text-white"
          @click="$emit('close-media')"
        >
          <X class="h-6 w-6" />
        </button>

        <div class="flex-1 overflow-hidden relative">
          <div
            v-if="activeMedia.type === 'image' || !activeMedia.type"
            class="relative h-[45vh] w-full"
          >
            <img
              :src="activeMedia.image"
              alt="Media preview"
              class="w-full h-full object-contain"
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
              class="w-full h-auto max-h-[45vh]"
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

        <!-- Media navigation -->
        <div v-if="activePost && activePost.post_media.length > 1">
          <button
            class="absolute left-2 top-1/2 -translate-y-1/2 bg-black/60 hover:bg-black/75 rounded-full p-2.5 text-white touch-manipulation transition-all duration-200 hover:scale-110 shadow-sm backdrop-blur-sm"
            @click.stop="$emit('navigate-media', 'prev')"
          >
            <ChevronLeft class="h-5 w-5" />
          </button>
          <button
            class="absolute right-2 top-1/2 -translate-y-1/2 bg-black/60 hover:bg-black/75 rounded-full p-2.5 text-white touch-manipulation transition-all duration-200 hover:scale-110 shadow-sm backdrop-blur-sm"
            @click.stop="$emit('navigate-media', 'next')"
          >
            <ChevronRight class="h-5 w-5" />
          </button>
          <div
            class="absolute bottom-2 left-1/2 -translate-x-1/2 bg-black/60 backdrop-blur-sm rounded-full px-4 py-1.5 text-white text-sm font-medium shadow-sm"
          >
            {{ activeMediaIndex + 1 }} / {{ activePost.post_media.length }}
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
