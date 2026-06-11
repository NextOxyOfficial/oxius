<template>
  <div
    :class="[
      'relative w-full rounded-xl overflow-hidden bg-gray-50 border border-dashed border-gray-200',
      heightClass,
    ]"
  >
    <span
      class="absolute top-1.5 right-2 z-10 text-[9px] font-semibold tracking-wider uppercase text-gray-400"
    >বিজ্ঞাপন</span>

    <!-- Real banner when provided -->
    <a
      v-if="image"
      :href="link || '#'"
      :target="link ? '_blank' : '_self'"
      rel="noopener sponsored"
      class="block w-full h-full"
    >
      <img :src="image" :alt="alt" class="w-full h-full object-cover" />
    </a>

    <!-- Reserved placeholder -->
    <div v-else class="absolute inset-0 flex flex-col items-center justify-center text-gray-300 select-none">
      <UIcon name="i-heroicons-megaphone" class="h-6 w-6 mb-1" />
      <span class="text-[11px] font-medium text-gray-400">এখানে আপনার বিজ্ঞাপন দিন</span>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";

const props = defineProps({
  // 'leaderboard' = short wide strip, 'billboard' = taller block
  variant: { type: String, default: "leaderboard" },
  image: { type: String, default: "" },
  link: { type: String, default: "" },
  alt: { type: String, default: "বিজ্ঞাপন" },
});

const heightClass = computed(() =>
  props.variant === "billboard" ? "h-28 sm:h-36" : "h-20 sm:h-24"
);
</script>
