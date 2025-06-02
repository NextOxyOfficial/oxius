<template>
  <div class="qr-code-modal">
    <UModal
      v-model="isOpen"
      :ui="{ 
        width: 'sm:max-w-md',
        container: 'flex flex-col h-full sm:h-auto',
        base: 'relative flex flex-col h-full sm:h-auto', 
        rounded: 'rounded-xl',
        overlay: { base: 'bg-black/50 backdrop-blur-sm' },
        padding: 'p-0',
        ring: ''
      }"
    >
      <div class="relative">
        <!-- Close button with improved position and style -->
        <button 
          type="button" 
          class="absolute right-2 top-2 z-50 p-2 text-gray-400 hover:text-gray-500 bg-white/80 hover:bg-white rounded-full transition-colors focus:outline-none" 
          @click="closeModal"
        >
          <span class="sr-only">Close</span>
          <UIcon name="i-heroicons-x-mark" class="h-5 w-5" />
        </button>

        <!-- QR Code Container with gradient background and styling -->
        <div class="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-t-xl pt-8 pb-6 px-6 text-center">
          <h3 class="text-xl font-semibold text-gray-900 mb-2">
            {{ user?.name }}'s Profile QR
          </h3>
          <p class="text-gray-600 text-sm mb-4">
            Scan this code to view this profile
          </p>

          <!-- QR Code with enhanced styling -->
          <div class="inline-flex items-center justify-center p-2 bg-white rounded-xl shadow-sm mb-3 border border-gray-100">
            <div v-if="qrCodeUrl" class="overflow-hidden rounded-lg">
              <img 
                :src="qrCodeUrl" 
                alt="Profile QR Code" 
                class="w-52 h-52"
              />
            </div>
            <div v-else class="w-52 h-52 flex items-center justify-center">
              <Loader2 class="h-8 w-8 text-blue-500 animate-spin" />
            </div>
          </div>

          <!-- Username display -->
          <p class="text-blue-600 font-medium">
            {{ formatUsername(user?.username) }}
          </p>
        </div>

        <!-- Action buttons -->
        <div class="p-4 bg-white rounded-b-xl border-t border-gray-100">
          <div class="flex justify-center gap-3">
            <!-- Download button -->
            <button
              @click="downloadQrCode"
              class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors flex items-center gap-2"
              :disabled="!qrCodeUrl"
            >
              <DownloadIcon class="h-4 w-4" />
              <span>Download</span>
            </button>
            
            <!-- Share button -->
            <button
              @click="shareProfile"
              class="px-4 py-2 bg-blue-600 rounded-lg text-white hover:bg-blue-700 transition-colors flex items-center gap-2"
            >
              <ShareIcon class="h-4 w-4" />
              <span>Share</span>
            </button>
          </div>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue';
import { Loader2, Share as ShareIcon, Download as DownloadIcon } from 'lucide-vue-next';

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  user: {
    type: Object,
    default: () => ({})
  }
});

const emit = defineEmits(['update:modelValue', 'close']);

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
});

const qrCodeUrl = ref(null);

// Generate QR code when modal opens
watch(() => props.modelValue, (newVal) => {
  if (newVal && props.user?.username) {
    generateQrCode();
  }
}, { immediate: true });

// Format username for display
const formatUsername = (username) => {
  if (!username) return '';
  return username.startsWith('@') ? username : `@${username}`;
};

// Generate QR code for the profile
const generateQrCode = async () => {
  try {
    const profileUrl = `${window.location.origin}/business-network/profile/${props.user?.id}`;
    const qrCodeApiUrl = `https://api.qrserver.com/v1/create-qr-code/?data=${encodeURIComponent(profileUrl)}&size=200x200&margin=10`;
    qrCodeUrl.value = qrCodeApiUrl;
  } catch (error) {
    console.error("Error generating QR code:", error);
    qrCodeUrl.value = null;
  }
};

// Download QR code
const downloadQrCode = () => {
  if (!qrCodeUrl.value) return;
  
  const link = document.createElement('a');
  link.href = qrCodeUrl.value;
  link.download = `${props.user?.name || 'profile'}-qr-code.png`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

// Share profile
const shareProfile = async () => {
  try {
    const profileUrl = `${window.location.origin}/business-network/profile/${props.user?.id}`;
    const shareData = {
      title: `${props.user?.name}'s Profile`,
      text: `Check out ${props.user?.name}'s profile on our platform!`,
      url: profileUrl
    };

    if (navigator.share) {
      await navigator.share(shareData);
    } else {
      // Fallback: copy to clipboard
      await navigator.clipboard.writeText(profileUrl);
      alert('Profile URL copied to clipboard!');
    }
  } catch (error) {
    console.error("Error sharing:", error);
  }
};

// Close modal
const closeModal = () => {
  isOpen.value = false;
  emit('close');
};
</script>
