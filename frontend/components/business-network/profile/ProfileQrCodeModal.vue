<template>
  <div class="qr-code-modal">
    <UModal
      v-model="isOpen"
      :ui="{
        width: 'sm:max-w-md',
        container: 'flex flex-col h-auto mt-16',
        base: 'relative flex flex-col h-auto',
        rounded: 'rounded-xl',
        overlay: { base: 'bg-black/50 backdrop-blur-sm' },
        padding: 'p-0',
        ring: '',
        transition: {
          enterFrom: 'opacity-0 scale-95',
          enterTo: 'opacity-100 scale-100',
          leaveFrom: 'opacity-100 scale-100',
          leaveTo: 'opacity-0 scale-95',
        },
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
        <!-- QR Code Container with updated styling -->
        <div class="bg-white rounded-t-xl pt-4 px-6 text-center">
          <h3 class="text-xl font-semibold text-gray-900 mb-1">
            {{
              props.user?.first_name ||
              props.user?.name ||
              props.user?.full_name ||
              props.user?.username ||
              "User"
            }}'s ABN Profile QR Code
          </h3>
          <p class="text-gray-600 text-sm mb-5">
            Scan this QR code to view profile
          </p>

          <!-- QR Code with enhanced styling -->
          <div
            class="inline-flex items-center justify-center p-4 bg-white rounded-xl shadow-sm mb-4 border border-gray-100"
          >
            <div v-if="qrCodeUrl" class="overflow-hidden rounded-lg relative">
              <img :src="qrCodeUrl" alt="Profile QR Code" class="w-60 h-60" />
              <!-- Center logo overlay -->
              <div
                class="absolute inset-0 flex items-center justify-center pointer-events-none"
              >
                <div class="bg-blue-100 rounded-full p-2 border-4 border-white">
                  <div
                    class="bg-blue-500 rounded-full w-8 h-8 flex items-center justify-center"
                  >
                    <UserIcon class="h-5 w-5 text-white" />
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="w-60 h-60 flex items-center justify-center">
              <Loader2 class="h-8 w-8 text-blue-500 animate-spin" />
            </div>
          </div>
          <!-- Business Network branding with improved design -->
          <div class="flex items-center justify-center mb-4">
            <div
              class="flex items-center gap-1.5 text-xs text-gray-600 bg-gray-100 px-3 py-1.5 rounded-full shadow-sm"
            >
              <UIcon
                name="i-heroicons-globe-alt"
                class="w-4 h-4 text-blue-500"
                aria-hidden="true"
              />
              <span class="font-medium">AdsyClub</span>
              <span>Business Network</span>
            </div>
          </div>
        </div>

        <!-- Customization section -->
        <div class="px-4 py-2 bg-gray-50 border-t border-gray-100">
          <h4 class="text-sm font-medium text-gray-700 mb-3">
            Customize QR Code
          </h4>

          <div class="flex items-center justify-between mb-4">
            <!-- QR Color options -->
            <div>
              <label class="text-xs text-gray-500 block mb-2">QR Color</label>
              <div class="flex gap-1">
                <button
                  v-for="color in qrColorOptions"
                  :key="color.value"
                  @click="selectedQrColor = color.value"
                  :class="[
                    'w-6 h-6 rounded-full border transition-all',
                    selectedQrColor === color.value
                      ? 'ring-2 ring-offset-1 ring-blue-500'
                      : 'ring-0',
                  ]"
                  :style="{ backgroundColor: color.hex }"
                ></button>
              </div>
            </div>

            <!-- Format options -->
            <div>
              <label class="text-xs text-gray-500 block mb-2">Format</label>
              <div class="flex gap-1">
                <button
                  v-for="format in formatOptions"
                  :key="format"
                  @click="selectedFormat = format"
                  :class="[
                    'px-3 py-1 text-xs rounded border transition-all',
                    selectedFormat === format
                      ? 'bg-blue-100 text-blue-700 border-blue-300'
                      : 'bg-white text-gray-700 border-gray-200',
                  ]"
                >
                  {{ format }}
                </button>
              </div>
            </div>
          </div>
        </div>
        <!-- Action buttons with enhanced design -->
        <div class="p-4 bg-white rounded-b-xl border-t border-gray-100">
          <div class="flex flex-wrap gap-3 justify-center">
            <!-- Download button -->
            <button
              @click="downloadQrCode"
              class="flex items-center gap-2 px-5 py-2 bg-blue-50 hover:bg-blue-100 text-blue-600 rounded-full transition-all text-sm font-medium"
              :disabled="!qrCodeUrl"
            >
              <DownloadIcon class="h-4 w-4" />
              <span>Download</span>
            </button>

            <!-- Share button -->
            <button
              @click="shareProfile"
              class="flex items-center gap-2 px-5 py-2 bg-indigo-50 hover:bg-indigo-100 text-indigo-600 rounded-full transition-all text-sm font-medium"
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
import { ref, watch, computed } from "vue";
import {
  Loader2,
  Share as ShareIcon,
  Download as DownloadIcon,
  User as UserIcon,
  CircleUser as CircleUserIcon,
} from "lucide-vue-next";

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false,
  },
  user: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(["update:modelValue", "close"]);

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit("update:modelValue", value),
});

const qrCodeUrl = ref(null);
const selectedQrColor = ref("blue");
const selectedFormat = ref("PNG");

// QR Color options
const qrColorOptions = [
  { value: "blue", hex: "#4285F4" },
  { value: "black", hex: "#000000" },
  { value: "red", hex: "#EA4335" },
  { value: "green", hex: "#34A853" },
  { value: "orange", hex: "#FBBC05" },
];

// Format options
const formatOptions = ["PNG", "SVG"];

// Watch for changes in customization options
watch([selectedQrColor, selectedFormat], () => {
  if (props.user?.username) {
    generateQrCode();
  }
});

// Generate QR code when modal opens
watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal && props.user?.username) {
      generateQrCode();
    }
  },
  { immediate: true }
);

// Format username for display
const formatUsername = (username) => {
  if (!username) return "";
  return username.startsWith("@") ? username : `@${username}`;
};

// Generate QR code for the profile with color customization
const generateQrCode = async () => {
  try {
    const profileUrl = `${window.location.origin}/business-network/profile/${props.user?.id}`;

    // Get the hex color from the selected color option (default to blue)
    const colorOption =
      qrColorOptions.find((c) => c.value === selectedQrColor.value) ||
      qrColorOptions[0];
    const colorHex = colorOption.hex.replace("#", "");

    // Build API URL with options
    let qrCodeApiUrl = `https://api.qrserver.com/v1/create-qr-code/`;
    qrCodeApiUrl += `?data=${encodeURIComponent(profileUrl)}`;
    qrCodeApiUrl += `&size=240x240`;
    qrCodeApiUrl += `&margin=10`;
    qrCodeApiUrl += `&color=${colorHex}`;

    // Add format if SVG
    if (selectedFormat.value === "SVG") {
      qrCodeApiUrl += `&format=svg`;
    }

    qrCodeUrl.value = qrCodeApiUrl;
  } catch (error) {
    console.error("Error generating QR code:", error);
    qrCodeUrl.value = null;
  }
};

// Download QR code
const downloadQrCode = async () => {
  if (!qrCodeUrl.value) return;

  // Add subtle feedback animation
  const downloadButton = document.activeElement;
  if (downloadButton) {
    downloadButton.classList.add("scale-95");
    setTimeout(() => {
      downloadButton.classList.remove("scale-95");
    }, 150);
  }

  try {
    // Fetch the QR code image as blob to handle CORS
    const response = await fetch(qrCodeUrl.value);
    if (!response.ok) {
      throw new Error("Failed to fetch QR code");
    }

    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);

    // Create download link
    const link = document.createElement("a");
    link.href = url;
    // Create filename based on the user's name or username
    const userName =
      props.user?.first_name ||
      props.user?.name ||
      props.user?.full_name ||
      props.user?.username ||
      "profile";
    const sanitizedName = userName
      .replace(/[^a-zA-Z0-9-_]/g, "-")
      .toLowerCase();
    const extension = selectedFormat.value.toLowerCase();
    link.download = `${sanitizedName}-qr-code.${extension}`;

    // Trigger download
    document.body.appendChild(link);
    link.click();

    // Cleanup
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  } catch (error) {
    console.error("Error downloading QR code:", error); // Fallback: try the old method
    const link = document.createElement("a");
    link.href = qrCodeUrl.value;
    const userName =
      props.user?.first_name ||
      props.user?.name ||
      props.user?.full_name ||
      props.user?.username ||
      "profile";
    const sanitizedName = userName
      .replace(/[^a-zA-Z0-9-_]/g, "-")
      .toLowerCase();
    const extension = selectedFormat.value.toLowerCase();
    link.download = `${sanitizedName}-qr-code.${extension}`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
};

// Share profile
const shareProfile = async () => {
  try {
    // Add subtle feedback animation
    const shareButton = document.activeElement;
    if (shareButton) {
      shareButton.classList.add("scale-95");
      setTimeout(() => {
        shareButton.classList.remove("scale-95");
      }, 150);
    }
    const profileUrl = `${window.location.origin}/business-network/profile/${props.user?.id}`;
    const shareData = {
      title: `${
        props.user?.first_name || props.user?.name || props.user?.username
      }'s Profile`,
      text: `Check out ${
        props.user?.first_name || props.user?.name || props.user?.username
      }'s profile on our platform!`,
      url: profileUrl,
    };

    if (navigator.share) {
      await navigator.share(shareData);
    } else {
      // Fallback: copy to clipboard
      await navigator.clipboard.writeText(profileUrl);
      alert("Profile URL copied to clipboard!");
    }
  } catch (error) {
    console.error("Error sharing:", error);
  }
};

// Close modal
const closeModal = () => {
  isOpen.value = false;
  emit("close");
};
</script>
