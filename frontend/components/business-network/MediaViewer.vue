<template>
  <Teleport to="body">
    <div
      v-if="activeMedia"
      class="fixed inset-0 z-[9999] bg-black/80 flex items-center justify-center p-4"
      @click="$emit('close-media')"
    >
      <div
        class="relative max-w-3xl w-full max-h-[80vh] bg-white rounded-lg overflow-hidden flex flex-col"
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
            class="absolute left-2 top-1/2 -translate-y-1/2 bg-black/60 hover:bg-black/75 rounded-full p-2.5 text-white touch-manipulation transition-all duration-200 hover:scale-110 shadow-lg backdrop-blur-sm"
            @click.stop="$emit('navigate-media', 'prev')"
          >
            <ChevronLeft class="h-5 w-5" />
          </button>
          <button
            class="absolute right-2 top-1/2 -translate-y-1/2 bg-black/60 hover:bg-black/75 rounded-full p-2.5 text-white touch-manipulation transition-all duration-200 hover:scale-110 shadow-lg backdrop-blur-sm"
            @click.stop="$emit('navigate-media', 'next')"
          >
            <ChevronRight class="h-5 w-5" />
          </button>
          <div
            class="absolute bottom-2 left-1/2 -translate-x-1/2 bg-black/60 backdrop-blur-sm rounded-full px-4 py-1.5 text-white text-sm font-medium shadow-lg"
          >
            {{ activeMediaIndex + 1 }} / {{ activePost.post_media.length }}
          </div>
        </div>

        <div class="p-4 border-t border-gray-200 bg-gray-50">
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center space-x-6">
              <div class="flex items-center space-x-1.5 group">
                <button
                  class="p-1.5 rounded-full hover:bg-rose-50 transition-all duration-200 transform hover:scale-105"
                  @click.stop="$emit('toggle-media-like')"
                >
                  <Heart
                    :class="[
                      'h-5 w-5 transition-colors duration-300',
                      activeMedia.media_likes?.find(
                        (like) => like.user === user?.user?.id
                      )
                        ? 'text-red-500 fill-red-500 animate-heartbeat'
                        : 'text-rose-400 group-hover:text-red-500',
                    ]"
                  />
                </button>
                <button
                  class="text-md text-gray-600 hover:underline"
                  @click.stop="$emit('open-media-likes-modal')"
                >
                  {{ activeMedia.media_likes?.length || 0 }} likes
                </button>
              </div>
              <div class="flex items-center space-x-1">
                <MessageCircle class="h-4 w-4 text-gray-500" />
                <span class="text-md text-gray-600">
                  {{ activeMedia.media_comments?.length || 0 }} comments
                </span>
              </div>
            </div>
          </div>

          <!-- Media comments -->
          <div
            v-if="
              activeMedia.media_comments &&
              activeMedia.media_comments.length > 0
            "
            class="max-h-[20vh] overflow-y-auto mb-3"
          >
            <h4 class="text-md font-medium text-gray-500 mb-2">Comments</h4>
            <div class="space-y-2">
              <div
                v-for="comment in activeMedia.media_comments"
                :key="comment.id"
                class="flex items-start space-x-2"
              >
                <div class="flex items-start space-x-2">
                  <NuxtLink
                    :to="`/business-network/profile/${comment.author_details.id}`"
                  >
                    <img
                      v-if="comment.author_details.image"
                      :src="comment.author_details.image"
                      alt="User"
                      class="w-6 h-6 rounded-full cursor-pointer"
                    />
                    <img
                      v-else
                      src="/static/frontend/avatar.png"
                      alt="User"
                      class="w-6 h-6 rounded-full cursor-pointer"
                    />
                  </NuxtLink>
                  <div class="flex-1">
                    <div class="bg-gray-50 rounded-lg p-2">
                      <div class="flex items-center justify-between">
                        <div class="flex items-center gap-1.5">
                          <NuxtLink
                            :to="`/business-network/profile/${comment.author_details.id}`"
                            class="text-sm font-medium hover:underline"
                          >
                            {{ comment.author_details.name }}
                          </NuxtLink>
                          <!-- Verified Badge -->
                          <div
                            v-if="comment.author_details.kyc"
                            class="text-blue-500 flex items-center"
                          >
                            <UIcon
                              name="i-mdi-check-decagram"
                              class="w-3 h-3"
                            />
                          </div>
                        </div>
                      </div>
                      <p class="text-sm mt-1">{{ comment.content }}</p>
                    </div>
                    <div class="flex items-center mt-1 space-x-3">
                      <span class="text-sm text-gray-500">{{
                        formatTimeAgo(comment.created_at)
                      }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Add comment input for media -->
          <div v-if="user" class="flex items-center gap-2">
            <img
              :src="user?.user?.image"
              alt="Your avatar"
              class="w-6 h-6 rounded-full"
            />
            <div class="flex-1 relative">
              <input
                type="text"
                placeholder="Add a comment..."
                class="w-full text-sm py-1.5 px-3 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:ring-1 focus:ring-blue-600"
                :value="mediaCommentText"
                @input="$emit('update:media-comment-text', $event.target.value)"
                @click.stop
              />
              <button
                v-if="mediaCommentText"
                class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-600"
                @click.stop="$emit('add-media-comment')"
              >
                <Send class="h-3 w-3" />
              </button>
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
  if (!dateString) return "";

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
