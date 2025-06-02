<template>
  <div class="posts-tab animate-fadeIn">
    <!-- Posts skeleton loader -->
    <div v-if="isLoadingPosts">
      <div 
        v-for="i in 3" 
        :key="i"
        class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4 animate-pulse-staggered"
      >
        <div class="flex items-center space-x-3 mb-4">
          <div class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"></div>
          <div class="flex-1 space-y-2">
            <div class="h-4 bg-gray-200 rounded animate-pulse w-1/4"></div>
            <div class="h-3 bg-gray-200 rounded animate-pulse w-1/5"></div>
          </div>
        </div>
        <div class="space-y-2 mb-4">
          <div class="h-4 bg-gray-200 rounded animate-pulse w-3/4"></div>
          <div class="h-3 bg-gray-200 rounded animate-pulse w-full"></div>
          <div class="h-3 bg-gray-200 rounded animate-pulse w-5/6"></div>
        </div>
        <div class="h-40 bg-gray-200 rounded animate-pulse mb-4"></div>
        <div class="flex justify-between">
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
          <div class="h-8 bg-gray-200 rounded animate-pulse w-1/4"></div>
        </div>
      </div>
    </div>

    <!-- Load more posts indicator -->
    <div v-if="loadingMorePosts && !isLoadingPosts" class="pb-6">
      <div class="flex justify-center items-center py-4">
        <Loader2 class="h-8 w-8 text-blue-600 animate-spin" />
      </div>
    </div>

    <!-- Display actual posts when loaded -->
    <BusinessNetworkPost
      v-if="!isLoadingPosts"
      :posts="posts.results"
      :id="currentUser?.user?.id"
    />

    <!-- No posts indicator -->
    <div
      v-if="!isLoadingPosts && posts?.results?.length === 0"
      class="flex flex-col items-center justify-center py-8 text-center"
    >
      <div class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4">
        <ChevronUp class="h-8 w-8 text-gray-600" />
      </div>
      <h3 class="text-lg font-medium text-gray-800 mb-1">No posts yet</h3>
      <p class="text-gray-600 mb-4 max-w-md">
        This profile hasn't posted anything yet
      </p>
    </div>

    <!-- End of feed indicator -->
    <div
      class="end-of-feed-indicator bg-white rounded-xl border border-gray-200/50 overflow-hidden mt-8 mb-4"
      v-if="!isLoadingPosts && posts?.results?.length > 0"
    >
      <div class="flex flex-col items-center justify-center py-8 text-center">
        <div class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4">
          <Check class="h-8 w-8 text-blue-600" />
        </div>
        <h3 class="text-lg font-medium text-gray-800 mb-1">
          You're all caught up!
        </h3>
        <p class="text-gray-600 mb-8 max-w-md">
          You've reached the end of the feed
        </p>
        <button
          @click="$emit('scroll-to-top')"
          class="flex items-center gap-2 px-4 py-2 text-sm bg-blue-50 text-blue-600 rounded-full hover:bg-blue-100 transition-colors"
        >
          <ChevronUp class="h-4 w-4" />
          <span>Back to top</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Loader2, Check, ChevronUp } from 'lucide-vue-next';

defineProps({
  isLoadingPosts: {
    type: Boolean,
    default: false
  },
  loadingMorePosts: {
    type: Boolean,
    default: false
  },
  posts: {
    type: Object,
    default: () => ({
      results: []
    })
  },
  currentUser: {
    type: Object,
    default: null
  }
});

defineEmits(['scroll-to-top']);
</script>
