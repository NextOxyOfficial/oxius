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
      @click="$emit('update:modelValue', false)"
    >
      <!-- Enhanced close button - larger and more visible -->
      <button
        @click.stop="$emit('update:modelValue', false)"
        class="absolute top-4 right-4 p-2 rounded-full bg-white/20 backdrop-blur-sm text-white hover:bg-white/30 transition-colors shadow-lg z-50"
        aria-label="Close"
      >
        <X class="h-6 w-6" />
      </button>

      <!-- Close instruction text -->
      <div class="absolute top-6 left-1/2 transform -translate-x-1/2 bg-black/40 backdrop-blur-sm px-3 py-1 rounded-full">
        <p class="text-white/80 text-sm">Click anywhere to close</p>
      </div>

      <div class="relative w-full max-w-4xl px-4" @click.stop>
        <img
          :src="getPhotoUrl(photos[currentPhotoIndex])"
          alt="Photo"
          class="mx-auto max-h-[80vh] max-w-full object-contain rounded-lg shadow-2xl"
          @error="handleImageError"
        />

        <div
          class="absolute top-1/2 left-0 right-0 flex justify-between transform -translate-y-1/2 px-2"
        >
          <button
            v-if="photos.length > 1"
            @click.stop="prevPhoto"
            class="p-2 rounded-full bg-black/30 text-white hover:bg-black/50 transition-colors"
            aria-label="Previous photo"
          >
            <ChevronLeft class="h-6 w-6" />
          </button>
          <div class="flex-1"></div>
          <button
            v-if="photos.length > 1"
            @click.stop="nextPhoto"
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
            @click.stop="$emit('update:currentIndex', i)"
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
import { ref } from "vue";

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

// Track image load errors
const imageError = ref(false);

const getPhotoUrl = (photo) => {
  if (!photo) return '/placeholder.svg';
  
  // Reset error state when trying to get a new URL
  imageError.value = false;
  
  try {
    // Handle string URLs directly
    if (typeof photo === 'string') return photo;
    
    // Handle objects with standard image properties
    if (photo.image) return photo.image;
    if (photo.preview) return photo.preview;
    if (photo.url) return photo.url;
    if (photo.src) return photo.src;
    
    // Handle other potential object structures
    for (const key of Object.keys(photo)) {
      const value = photo[key];
      if (typeof value === 'string' && 
          (value.startsWith('http') || 
           value.startsWith('/') || 
           value.startsWith('data:'))) {
        return value;
      }
    }
    
    // If all else fails, return placeholder
    return '/placeholder.svg';
  } catch (err) {
    console.error('Error processing photo URL:', err);
    return '/placeholder.svg';
  }
};

const handleImageError = () => {
  imageError.value = true;
  console.warn('Image failed to load:', props.photos[props.currentPhotoIndex]);
};

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

<style scoped>
/* Add some animation for a smoother experience */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

img {
  animation: fadeIn 0.3s ease-out;
}
</style>