<template>
  <div>
    <video ref="videoElement" width="100%" height="100%"></video>
    <div v-if="qrCode" class="qr-result">
      <p>Scanned QR Code: {{ qrCode }}</p>
    </div>
  </div>
</template>

<script setup>
const emit = defineEmits(["scanned"]);
import QrScanner from "qr-scanner";

const qrCode = ref(null);
const videoElement = ref(null);
let qrScanner;

onMounted(() => {
  if (videoElement.value) {
    qrScanner = new QrScanner(videoElement.value, (result) => {
      qrCode.value = result; // Store the scanned QR code
      emit("scanned", result);
    });
    qrScanner.start();
  }
});

onBeforeUnmount(() => {
  if (qrScanner) {
    qrScanner.stop(); // Stop the scanner when the component is unmounted
  }
});
</script>

<style scoped>
.qr-result {
  margin-top: 20px;
  font-size: 1.2em;
  color: #333;
}
</style>
