<template>
  <div class="w-full max-w-md mx-auto p-4">
    <h1 class="text-2xl font-bold text-center mb-6">QR Code Scanner</h1>

    <div class="space-y-2">
      <label for="qr-input" class="text-sm font-medium"> Input Field </label>
      <div class="relative">
        <input
          id="qr-input"
          v-model="inputValue"
          type="text"
          placeholder="Enter text or scan QR code"
          class="w-full px-4 py-2 border rounded-md pr-10 focus:outline-none focus:ring-2 focus:ring-primary"
        />
        <button
          type="button"
          class="absolute right-0 top-0 h-full px-3 text-gray-500 hover:text-gray-700"
          @click="startScanning"
          aria-label="Scan QR code"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="lucide lucide-scan"
          >
            <path d="M3 7V5a2 2 0 0 1 2-2h2"></path>
            <path d="M17 3h2a2 2 0 0 1 2 2v2"></path>
            <path d="M21 17v2a2 2 0 0 1-2 2h-2"></path>
            <path d="M7 21H5a2 2 0 0 1-2-2v-2"></path>
            <line x1="7" y1="12" x2="17" y2="12"></line>
          </svg>
        </button>
      </div>
    </div>

    <!-- QR Scanner Modal -->
    <Teleport to="body">
      <div
        v-if="isScanning"
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      >
        <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-4">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-medium">Scan QR Code</h3>
            <button
              @click="stopScanning"
              class="text-gray-500 hover:text-gray-700"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="lucide lucide-x"
              >
                <path d="M18 6 6 18"></path>
                <path d="m6 6 12 12"></path>
              </svg>
            </button>
          </div>

          <p class="text-center mb-3 text-sm">
            Point your camera at the other person's QR code
          </p>

          <div class="w-full h-64 overflow-hidden rounded-md relative">
            <client-only>
              <qrcode-stream
                v-if="isScanning && !error"
                @decode="onDecode"
                @init="onInit"
                :camera="camera"
                :track="track"
              ></qrcode-stream>
            </client-only>

            <!-- Scanning overlay -->
            <div v-if="!error" class="absolute inset-0 pointer-events-none">
              <div class="w-full h-full flex items-center justify-center">
                <div
                  class="border-2 border-primary w-64 h-64 max-w-full max-h-full"
                ></div>
              </div>
            </div>

            <!-- Camera permission error message -->
            <div
              v-if="error"
              class="absolute inset-0 bg-white bg-opacity-90 flex flex-col items-center justify-center p-4"
            >
              <p class="text-red-500 mb-2">{{ error }}</p>
              <button
                @click="retryScanning"
                class="px-4 py-2 bg-primary text-white rounded-md"
              >
                Try Again
              </button>
            </div>
          </div>

          <div class="mt-4 text-center text-sm text-gray-500">
            Align the QR code within the frame to scan
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script>
import { QrcodeStream } from "vue-qrcode-reader";

export default defineComponent({
  name: "QRCodeScanner",
  components: {
    QrcodeStream,
    ClientOnly: {
      render(h) {
        return this.$slots.default;
      },
      mounted() {
        this.$forceUpdate();
      },
    },
  },
  setup() {
    const inputValue = ref("");
    const isScanning = ref(false);
    const error = ref("");
    const camera = ref("auto");
    const track = ref({
      constraints: {
        facingMode: { ideal: "environment" },
        width: { min: 360, ideal: 640, max: 1920 },
        height: { min: 240, ideal: 480, max: 1080 },
      },
    });

    const startScanning = () => {
      error.value = "";
      isScanning.value = true;
    };

    const stopScanning = () => {
      isScanning.value = false;
    };

    const retryScanning = () => {
      error.value = "";
      // Small delay to ensure camera is properly reset
      setTimeout(() => {
        startScanning();
      }, 100);
    };

    const onDecode = (result) => {
      inputValue.value = result;
      stopScanning();
    };

    const onInit = async (promise) => {
      try {
        await promise;
      } catch (err) {
        console.error("QR Scanner error:", err);

        if (err.name === "NotAllowedError") {
          error.value =
            "Camera access denied. Please allow camera access to scan QR codes.";
        } else if (err.name === "NotFoundError") {
          error.value = "No camera found. Please use a device with a camera.";
        } else if (err.name === "NotSupportedError") {
          error.value =
            "Your browser doesn't support camera access for QR scanning.";
        } else if (err.name === "NotReadableError") {
          error.value = "Camera is already in use by another application.";
        } else {
          error.value =
            "Error accessing camera: " + (err.message || "Unknown error");
        }
      }
    };

    // Clean up camera resources when component is destroyed
    onBeforeUnmount(() => {
      stopScanning();
    });

    return {
      inputValue,
      isScanning,
      error,
      camera,
      track,
      startScanning,
      stopScanning,
      retryScanning,
      onDecode,
      onInit,
    };
  },
});
</script>

<style scoped>
.border-primary {
  border-color: #4f46e5;
}

.bg-primary {
  background-color: #4f46e5;
}
</style>
