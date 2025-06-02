<template>
  <div class="media-tab">
    <!-- Lazyloader for media tab -->
    <div v-if="isLoadingMedia" class="p-4">
      <div class="flex justify-center items-center mb-6">
        <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
      </div>
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 px-2">
        <div
          v-for="i in 8"
          :key="i"
          class="aspect-square bg-gray-200 rounded animate-pulse"
        ></div>
      </div>
    </div>

    <!-- Display actual media when loaded -->
    <div
      v-if="!isLoadingMedia"
      class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 px-2 animate-fadeIn"
    >
      <div
        v-for="(media, index) in allMedia"
        :key="index"
        class="aspect-square bg-gray-100 rounded-lg overflow-hidden group cursor-pointer hover:shadow-sm transition-all duration-300"
      >
        <img
          :src="media.thumbnail"
          :alt="`Media ${index + 1}`"
          class="w-full h-full object-cover group-hover:scale-105 transition-all duration-500"
        />
      </div>
    </div>
    
    <!-- No media indicator -->
    <div
      v-if="!isLoadingMedia && allMedia.length === 0"
      class="flex flex-col items-center justify-center py-8 text-center"
    >
      <div class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4">
        <ImageIcon class="h-8 w-8 text-gray-600" />
      </div>
      <h3 class="text-lg font-medium text-gray-800 mb-1">No media yet</h3>
      <p class="text-gray-600 mb-4 max-w-md">
        This profile hasn't posted any media yet
      </p>
    </div>
  </div>
</template>

<script setup>
import { Loader2 } from 'lucide-vue-next';
import { ImageIcon } from 'lucide-vue-next';

defineProps({
  isLoadingMedia: {
    type: Boolean,
    default: false
  },
  allMedia: {
    type: Array,
    default: () => []
  }
});
</script>
