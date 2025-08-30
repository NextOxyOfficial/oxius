<template>
  <div class="space-y-6">
    <div class="text-center py-16">
      <div class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <ShoppingCart class="h-8 w-8 text-blue-600" />
      </div>
      <h3 class="text-lg font-semibold text-gray-900 mb-2">No Orders Yet</h3>
      <p class="text-gray-600 mb-4">
        You haven't placed any orders yet. Browse gigs to get started!
      </p>
      <button
        @click="$emit('switchTab', 'all-gigs')"
        class="inline-flex items-center px-4 py-2 rounded-lg bg-blue-100 text-blue-700 hover:bg-blue-200 transition-colors"
      >
        Browse Gigs
      </button>
    </div>
  </div>
</template>

<script setup>
import { ShoppingCart } from 'lucide-vue-next';

// Emit events to parent component
defineEmits(['switchTab']);
</script>
