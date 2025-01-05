<template>
  <div class="min-h-screen bg-white flex items-center justify-center p-6">
    <div class="w-full max-w-sm">
      <!-- Glass Card Effect -->
      <div
        class="backdrop-blur-lg bg-white/70 rounded-xl p-6 shadow-lg border border-white/20"
      >
        <!-- Title and Success Icon -->
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-semibold text-gray-800">
            Transfer Completed
          </h2>
          <UIcon name="i-rivet-icons-check-circle-breakout" class="h-5 w-5" />
        </div>

        <!-- Transfer Details -->
        <div class="space-y-4 mb-6">
          <div class="flex justify-between items-center">
            <p class="text-gray-500 text-xs">Transferred amount</p>
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
                Completed
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

        <!-- Action Buttons -->
        <div class="flex gap-3">
          <button
            @click="handleViewDetails"
            class="flex-1 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 bg-gray-100 text-gray-800 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-gray-300"
          >
            View Details
          </button>
          <button
            @click="handleNewTransfer"
            class="flex-1 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 bg-black text-white hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2"
          >
            New Transfer
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const handleViewDetails = () => {
  // Implement view details logic
  console.log("View transfer details");
};

const handleNewTransfer = () => {
  // Implement new transfer logic
  console.log("Start new transfer");
};
</script>

<style scoped>
/* Glass morphism effect */
.backdrop-blur-lg {
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}
</style>
