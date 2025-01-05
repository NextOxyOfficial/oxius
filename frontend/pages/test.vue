<template>
  <div class="min-h-screen bg-white flex items-center justify-center p-6">
    <div class="w-full max-w-sm">
      <!-- Glass Card Effect -->
      <div
        class="backdrop-blur-lg bg-white/70 rounded-xl p-6 shadow-lg border border-white/20"
      >
        <!-- Title -->
        <h2 class="text-lg font-semibold text-gray-800 mb-4">
          Confirm Transfer
        </h2>

        <!-- Transfer Details -->
        <div class="space-y-4 mb-6">
          <div class="flex justify-between items-center">
            <p class="text-gray-500 text-xs">Transfer amount</p>
            <p class="text-gray-900 text-lg font-semibold">₦10,456</p>
          </div>

          <div class="space-y-3">
            <!-- Recipient Field -->
            <div class="space-y-1">
              <label class="text-xs text-gray-500">Recipient:</label>
              <p class="text-sm text-gray-800 font-medium">John Smith</p>
            </div>

            <!-- Email Field -->
            <div class="space-y-1">
              <label class="text-xs text-gray-500">Email:</label>
              <p class="text-sm text-gray-800 font-medium">
                john.smith@example.com
              </p>
            </div>

            <!-- Name Field -->
            <!-- <div class="space-y-1">
              <label class="text-xs text-gray-500">Name:</label>
              <p class="text-sm text-gray-800 font-medium">John Smith</p>
            </div> -->

            <!-- Time Field -->
            <div class="flex items-center gap-2">
              <label class="text-xs text-gray-500">Time:</label>
              <span
                class="px-2 py-1 rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium"
              >
                Instant
              </span>
            </div>
          </div>
        </div>

        <!-- Final Amount -->
        <div
          class="flex justify-between items-center mb-6 pt-4 border-t border-gray-200"
        >
          <p class="text-xs text-gray-500">Final amount</p>
          <p class="text-gray-900 font-semibold">₦23,458.78</p>
        </div>

        <!-- Confirm Button -->
        <button
          @click="handleConfirm"
          :class="[
            'w-full py-2.5 rounded-lg text-sm font-medium transition-all duration-200',
            'bg-black text-white hover:bg-gray-800 active:scale-98',
            'focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2',
            'disabled:opacity-50 disabled:cursor-not-allowed',
          ]"
          :disabled="loading"
        >
          <div class="flex items-center justify-center gap-2">
            {{ loading ? "Processing..." : "Confirm Transfer" }}
          </div>
        </button>
      </div>

      <!-- Success Message -->
      <div
        v-if="showSuccess"
        class="mt-4 backdrop-blur-lg bg-white/70 rounded-lg p-3 border border-emerald-200/20 flex items-center gap-2 animate-fade-in"
      >
        <p class="text-emerald-600 text-sm">Transfer confirmed successfully!</p>
      </div>
    </div>
  </div>
</template>

<script setup>
const loading = ref(false);
const showSuccess = ref(false);

const handleConfirm = async () => {
  loading.value = true;
  // Simulate API call
  await new Promise((resolve) => setTimeout(resolve, 1500));
  loading.value = false;
  showSuccess.value = true;
};
</script>

<style>
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(5px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fade-in 0.2s ease-out;
}

.active\:scale-98:active {
  transform: scale(0.98);
}

/* Glass morphism effect */
.backdrop-blur-lg {
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}
</style>
