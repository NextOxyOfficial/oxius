<template>
  <div class="saved-tab">
    <!-- Lazyloader for saved posts -->
    <div v-if="isLoadingSaved" class="p-4">
      <div class="flex justify-center items-center mb-6">
        <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
      </div>
      <div
        v-for="i in 2"
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
        </div>
        <div class="h-40 bg-gray-200 rounded animate-pulse mb-4"></div>
      </div>
    </div>

    <div v-if="!isLoadingSaved" class="animate-fadeIn">
      <div v-if="savedPosts?.length === 0" class="text-center py-10">
        <div class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4 mx-auto">
          <BookmarkIcon class="h-8 w-8 text-gray-600" />
        </div>
        <h3 class="text-base font-medium text-gray-800 mb-2">
          No saved posts yet
        </h3>
        <p class="text-gray-600 text-sm">
          Posts you save will appear here
        </p>
      </div>
      <BusinessNetworkPost
        v-if="savedPosts?.length > 0"
        :posts="savedPosts"
        :id="currentUser?.user?.id"
      />
    </div>
  </div>
</template>

<script setup>
import { Loader2, BookmarkIcon } from 'lucide-vue-next';

defineProps({
  isLoadingSaved: {
    type: Boolean,
    default: false
  },
  savedPosts: {
    type: Array,
    default: () => []
  },
  currentUser: {
    type: Object,
    default: null
  }
});
</script>
