<template>
  <div class="w-full">
    <div class="preloader">
      <div class="spinner">
        <div class="spinner-ring"></div>
        <div class="spinner-ring"></div>
        <div class="spinner-ring"></div>
        <div class="icon-wrapper">
          <span class="font-bold text-3xl p-1">A</span>
        </div>
      </div>
    </div>
    <p class="text-sm text-gray-500 text-center">{{ text }}</p>
  </div>
</template>

<script setup>
defineProps({
  text: {
    type: String,
  },
});
</script>

<style scoped>
.preloader {
  display: flex;
  align-items: center;
  justify-content: center;
}

.spinner {
  position: relative;
  width: 64px;
  height: 64px;
}

.spinner-ring {
  position: absolute;
  width: 100%;
  height: 100%;
  border: 4px solid transparent;
  border-radius: 50%;
  border-top-color: #3b82f6;
}

.spinner-ring:nth-child(1) {
  animation: spin-clockwise 1s linear infinite;
}

.spinner-ring:nth-child(2) {
  border-width: 2px;
  animation: spin-counter 1s linear infinite;
  scale: 0.8;
}

.spinner-ring:nth-child(3) {
  border-style: dotted;
  animation: spin-clockwise 2s linear infinite;
  scale: 0.6;
}

.icon-wrapper {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.icon {
  width: 24px;
  height: 24px;
  color: #3b82f6;
}

@keyframes spin-clockwise {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@keyframes spin-counter {
  from {
    transform: rotate(360deg);
  }
  to {
    transform: rotate(0deg);
  }
}
</style>
