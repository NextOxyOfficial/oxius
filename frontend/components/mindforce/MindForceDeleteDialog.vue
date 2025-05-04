<template>
  <Transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="opacity-0 scale-95"
    enter-to-class="opacity-100 scale-100"
    leave-active-class="transition duration-150 ease-in"
    leave-from-class="opacity-100 scale-100"
    leave-to-class="opacity-0 scale-95"
  >
    <div
      v-if="modelValue"
      class="fixed inset-0 z-[60] flex items-center justify-center"
    >
      <div
        class="absolute inset-0 bg-black/50 backdrop-blur-sm"
        @click="$emit('update:modelValue', false)"
      ></div>
      <div
        class="relative bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-6"
      >
        <div class="flex items-center mb-4 text-red-500">
          <AlertTriangle class="h-6 w-6 mr-2" />
          <h3 class="text-lg font-semibold">Are you sure?</h3>
        </div>
        <p class="mt-2 text-gray-600">
          This action cannot be undone. This will permanently delete your
          problem and all associated advices.
        </p>
        <div class="flex justify-end gap-3 mt-8">
          <button
            @click="$emit('update:modelValue', false)"
            class="inline-flex items-center justify-center rounded-lg text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-gray-200 bg-white text-gray-700 hover:bg-gray-100 h-10 px-4 py-2"
          >
            Cancel
          </button>
          <button
            @click="$emit('confirm')"
            class="inline-flex items-center justify-center rounded-lg text-md font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-red-600 text-white hover:bg-red-700 h-10 px-4 py-2 shadow-md hover:shadow-sm"
          >
            <AlertTriangle class="h-4 w-4 mr-2" />
            Delete
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { AlertTriangle } from "lucide-vue-next";

defineProps({
  modelValue: {
    type: Boolean,
    required: true
  }
});

defineEmits(['update:modelValue', 'confirm']);
</script>