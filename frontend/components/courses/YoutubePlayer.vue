<template>
  <div class="youtube-player-container">
    <div v-if="!isPlaying" class="preview-container" @click="playVideo">
      <img :src="thumbnailUrl" alt="Video Thumbnail" class="thumbnail">
      <div class="play-button">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-white opacity-90" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd" />
        </svg>
      </div>
    </div>
    <iframe 
      v-else
      :src="`https://www.youtube.com/embed/${videoId}?autoplay=1`" 
      frameborder="0" 
      allowfullscreen
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      class="youtube-iframe"
    ></iframe>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  videoId: {
    type: String,
    required: true
  },
  video: {
    type: Object,
    default: () => ({})
  }
});

const isPlaying = ref(false);

// Get YouTube thumbnail URL from video ID
const thumbnailUrl = computed(() => {
  return `https://img.youtube.com/vi/${props.videoId}/mqdefault.jpg`;
});

function playVideo() {
  isPlaying.value = true;
}
</script>

<style scoped>
.youtube-player-container {
  width: 100%;
  height: 100%;
  position: relative;
}

.preview-container {
  position: relative;
  width: 100%;
  height: 100%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.thumbnail {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.play-button {
  position: absolute;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s ease-in-out;
}

.preview-container:hover .play-button {
  transform: scale(1.1);
}

.youtube-iframe {
  width: 100%;
  height: 100%;
  border: none;
}
</style>
