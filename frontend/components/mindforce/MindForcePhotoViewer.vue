<template>
  <Transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="opacity-0"
    enter-to-class="opacity-100"
    leave-active-class="transition duration-150 ease-in"
    leave-from-class="opacity-100"
    leave-to-class="opacity-0"
  >
    <div
      v-if="modelValue && photos?.length"
      class="fixed inset-0 z-[70] flex items-center justify-center bg-black/90"
    >
      <button
        @click="$emit('update:modelValue', false)"
        class="absolute top-4 right-4 p-1.5 rounded-full text-white hover:bg-white/10 transition-colors"
        aria-label="Close"
      >
        <X class="h-6 w-6" />
      </button>

      <div class="relative w-full max-w-4xl px-4">
        <img
          :src="photos[currentPhotoIndex]?.image"
          alt="Problem photo"
          class="mx-auto max-h-[80vh] max-w-full object-contain"
        />

        <div
          class="absolute top-1/2 left-0 right-0 flex justify-between transform -translate-y-1/2 px-2"
        >
          <button
            v-if="photos.length > 1"
            @click="prevPhoto"
            class="p-2 rounded-full bg-black/30 text-white hover:bg-black/50 transition-colors"
            aria-label="Previous photo"
          >
            <ChevronLeft class="h-6 w-6" />
          </button>
          <div class="flex-1"></div>
          <button
            v-if="photos.length > 1"
            @click="nextPhoto"
            class="p-2 rounded-full bg-black/30 text-white hover:bg-black/50 transition-colors"
            aria-label="Next photo"
          >
            <ChevronRight class="h-6 w-6" />
          </button>
        </div>

        <div
          class="absolute bottom-4 left-0 right-0 flex justify-center gap-2"
        >
          <button
            v-for="(_, i) in photos"
            :key="i"
            @click="$emit('update:currentIndex', i)"
            :class="[
              'w-2 h-2 rounded-full transition-all',
              currentPhotoIndex === i
                ? 'bg-white scale-125'
                : 'bg-white/50 hover:bg-white/70',
            ]"
            :aria-label="`View photo ${i + 1}`"
          ></button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { X, ChevronLeft, ChevronRight } from "lucide-vue-next";

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  photos: {
    type: Array,
    default: () => []
  },
  currentPhotoIndex: {
    type: Number,
    default: 0
  }
});

const emit = defineEmits(['update:modelValue', 'update:currentIndex']);

const nextPhoto = () => {
  if (props.photos.length <= 1) return;
  const newIndex = (props.currentPhotoIndex + 1) % props.photos.length;
  emit('update:currentIndex', newIndex);
};

const prevPhoto = () => {
  if (props.photos.length <= 1) return;
  const newIndex = (props.currentPhotoIndex - 1 + props.photos.length) % props.photos.length;
  emit('update:currentIndex', newIndex);
};
</script>