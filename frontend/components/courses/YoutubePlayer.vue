<template>  <div class="youtube-player-container">
    <div v-if="!isPlaying" class="preview-container" @click="playVideo" @contextmenu.prevent="showAuthModal">
      <img :src="thumbnailUrl" alt="Video Thumbnail" class="thumbnail" />

      <!-- Video duration badge -->
      <div class="duration-badge">{{ video.duration }}</div>

      <!-- Enhanced play button with glowing effect -->
      <div class="play-button-wrapper">
        <div class="play-button">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-12 w-12 text-white"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
              clip-rule="evenodd"
            />
          </svg>
        </div>

        <!-- Video title overlay -->
        <div class="video-info-overlay">
          <h4 class="video-title">{{ video.title }}</h4>
        </div>
      </div>
    </div>
      <iframe
      v-else
      :src="`https://www.youtube.com/embed/${videoId}?autoplay=1&rel=0&enablejsapi=1`"
      frameborder="0"
      allowfullscreen
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      class="youtube-iframe"
      @load="onIframeLoad"
    ></iframe>    
    
    <!-- Using SimpleAccessModal for non-authenticated users -->
    <SimpleAccessModal
      :show="showLoginModal"
      @close="handleModalClose"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from "vue";
import { useAuth } from "~/composables/useAuth";
// Import our simplified modal component
import SimpleAccessModal from "~/components/common/SimpleAccessModal.vue";

const props = defineProps({
  videoId: {
    type: String,
    required: true,
  },
  video: {
    type: Object,
    default: () => ({}),
  },
  sessionManager: {
    type: Object,
    default: null,
  }
});

const emit = defineEmits(['video-start', 'video-pause', 'video-resume', 'video-stop', 'login-required', 'subscription-required']);

const { isAuthenticated } = useAuth()
const isPlaying = ref(false);
const showLocalAccessModal = ref(false);
const showLoginModal = ref(false);

// Get YouTube thumbnail URL from video ID - use maxresdefault for higher quality when available
const thumbnailUrl = computed(() => {
  return `https://img.youtube.com/vi/${props.videoId}/mqdefault.jpg`;
});

// Debug function to manually show the modal
function showAuthModal() {
  console.log('Manually showing access modal');
  showLocalAccessModal.value = true;
  return false;
}

async function playVideo() {
  try {
  // First check if user is authenticated directly
    if (!isAuthenticated.value) {
      console.log('User not authenticated, showing login modal');
      showLoginModal.value = true;
      
      // Sync with session manager state if needed
      if (props.sessionManager) {
        props.sessionManager.requiresLogin.value = true;
        props.sessionManager.showAccessModal.value = true;
      }
      emit('video-start', false, 'Login required');
      return;
    }

    // Check access through session manager if available and user is authenticated
    if (props.sessionManager && !props.sessionManager.checkVideoAccess()) {
      emit('video-start', false, 'Access restricted');
      return;
    }

    // Check session status before playing video
    if (props.sessionManager && !props.sessionManager.isSessionActive.value) {
      throw new Error('Session not active. Please refresh the page.');
    }    // For non-pro users, check time limit
    if (props.sessionManager && props.sessionManager.hasTimeLimit.value && props.sessionManager.timeRemaining.value <= 0) {
      showLocalAccessModal.value = true;
      // Sync with session manager state
      if (props.sessionManager) {
        props.sessionManager.requiresSubscription.value = true;
        props.sessionManager.showAccessModal.value = true;
      }
      emit('video-start', false, 'Time limit exceeded');
      return;
    }

    isPlaying.value = true;
    emit('video-start', true);
    
    // Start video tracking if session manager is available
    if (props.sessionManager && props.video.id) {
      props.sessionManager.startVideoTracking(props.video.id);
    }
  } catch (error) {
    console.error('Failed to start video:', error);
    emit('video-start', false, error.message);
  }
}

function pauseVideo() {
  emit('video-pause');
  if (props.sessionManager && props.video.id) {
    props.sessionManager.pauseVideoTracking();
  }
}

function resumeVideo() {
  emit('video-resume');
  if (props.sessionManager && props.video.id) {
    props.sessionManager.resumeVideoTracking();
  }
}

function stopVideo() {
  isPlaying.value = false;
  emit('video-stop');
  if (props.sessionManager && props.video.id) {
    props.sessionManager.stopVideoTracking();
  }
}

// Listen for window messages from YouTube iframe API
function handleMessage(event) {
  if (event.origin !== 'https://www.youtube.com') return;
  
  try {
    const data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
    
    if (data.event === 'video-progress') {
      // YouTube iframe is playing
      if (data.info?.playerState === 1) { // Playing
        resumeVideo();
      } else if (data.info?.playerState === 2) { // Paused
        pauseVideo();
      } else if (data.info?.playerState === 0) { // Ended
        stopVideo();
      }
    }
  } catch (error) {
    // Ignore parsing errors
  }
}

function onIframeLoad() {
  // Additional iframe load handling if needed
}

// Modal event handlers
const handleModalClose = () => {
  showLocalAccessModal.value = false;
  showLoginModal.value = false;
  if (props.sessionManager) {
    props.sessionManager.closeAccessModal();
  }
}

const handleLogin = () => {
  showLocalAccessModal.value = false;
  showLoginModal.value = false;
  emit('login-required');
}

const handleSubscribe = () => {
  showLocalAccessModal.value = false;
  showLoginModal.value = false;
  emit('subscription-required');
}

// Watch for authentication status changes
watch(() => isAuthenticated.value, (newValue) => {
  console.log('Authentication status changed:', newValue);
  // If user logs out while the video is playing, show login required modal
  if (!newValue && isPlaying.value) {
    isPlaying.value = false;
    showLoginModal.value = true;
  }
});

onMounted(() => {
  window.addEventListener('message', handleMessage);
  console.log('YoutubePlayer mounted, isAuthenticated:', isAuthenticated.value);
});

onUnmounted(() => {
  window.removeEventListener('message', handleMessage);
  // Ensure video tracking is stopped when component unmounts
  if (props.sessionManager && props.video.id) {
    props.sessionManager.stopVideoTracking();
  }
});
</script>

<style scoped>
.youtube-player-container {
  width: 100%;
  height: 100%;
  position: relative;
  border-radius: 0.5rem;
  overflow: hidden;
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
  background-color: #000;
}

.thumbnail {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.preview-container:hover .thumbnail {
  transform: scale(1.05);
  opacity: 0.8;
}

.play-button-wrapper {
  position: absolute;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    to top,
    rgba(0, 0, 0, 0.7) 0%,
    rgba(0, 0, 0, 0) 60%
  );
}

.play-button {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.5);
  box-shadow: 0 0 30px rgba(255, 255, 255, 0.2);
  z-index: 2;
}

.preview-container:hover .play-button {
  transform: scale(1.15);
  background: rgba(229, 62, 62, 0.9);
  box-shadow: 0 0 40px rgba(229, 62, 62, 0.4);
}

.youtube-iframe {
  width: 100%;
  height: 100%;
  border: none;
}

.duration-badge {
  position: absolute;
  bottom: 10px;
  right: 10px;
  background-color: rgba(0, 0, 0, 0.8);
  color: white;
  font-size: 0.7rem;
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 500;
  z-index: 2;
}

.video-info-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  padding: 30px 15px 15px 15px;
  background: linear-gradient(
    to top,
    rgba(0, 0, 0, 0.8) 0%,
    rgba(0, 0, 0, 0) 100%
  );
  opacity: 0;
  transform: translateY(20px);
  transition: all 0.3s ease;
}

.preview-container:hover .video-info-overlay {
  opacity: 1;
  transform: translateY(0);
}

.video-title {
  color: white;
  font-size: 0.9rem;
  font-weight: 600;
  text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.8);
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  display: flex;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  box-orient: vertical;
}
</style>
