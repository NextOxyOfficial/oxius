<template>
  <!-- Social Media Links -->
  <div class="mt-3 pt-3 border-t border-gray-100">
    <div class="grid grid-cols-2 sm:flex sm:flex-wrap gap-3">
      <!-- Website -->
      <a
        v-if="user?.website"
        :href="formatUrl(user?.website)"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-1.5 text-blue-600 hover:text-blue-700 text-sm font-medium truncate transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-blue-50/80 to-blue-50/30 hover:from-blue-50 hover:to-blue-100/50 border border-blue-100/50"
      >
        <LinkIcon class="h-4 w-4 flex-shrink-0" />
        <span class="truncate">{{ formatLinkDisplay(user?.website) }}</span>
      </a>

      <!-- Facebook -->
      <a
        v-if="user?.face_link"
        :href="formatUrl(user.face_link)"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-1.5 text-blue-600 hover:text-blue-700 transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-blue-50/80 to-blue-50/30 hover:from-blue-50 hover:to-blue-100/50 border border-blue-100/50"
      >
        <UIcon name="i-mdi-facebook" class="size-4 flex-shrink-0" />
        <span class="text-sm font-medium">Facebook</span>
      </a>

      <!-- Instagram -->
      <a
        v-if="user?.instagram_link"
        :href="formatUrl(user.instagram_link)"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-1.5 text-pink-600 hover:text-pink-700 transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-pink-50/80 to-pink-50/30 hover:from-pink-50 hover:to-pink-100/50 border border-pink-100/50"
      >
        <UIcon name="i-mdi-instagram" class="size-4 flex-shrink-0" />
        <span class="text-sm font-medium">Instagram</span>
      </a>

      <!-- WhatsApp -->
      <a
        v-if="user?.whatsapp_link"
        :href="`https://wa.me/${user.whatsapp_link.replace(/[^0-9]/g, '')}`"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-1.5 text-green-600 hover:text-green-700 transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-green-50/80 to-green-50/30 hover:from-green-50 hover:to-green-100/50 border border-green-100/50"
      >
        <UIcon name="i-mdi-whatsapp" class="size-4 flex-shrink-0" />
        <span class="text-sm font-medium">WhatsApp</span>
      </a>

      <!-- Gmail/Email -->
      <a
        v-if="user?.gmail_link"
        :href="`mailto:${user.gmail_link}`"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-1.5 text-red-500 hover:text-red-600 transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-red-50/80 to-red-50/30 hover:from-red-50 hover:to-red-100/50 border border-red-100/50"
      >
        <UIcon name="i-mdi-gmail" class="size-4 flex-shrink-0" />
        <span class="text-sm font-medium">Email</span>
      </a>
    </div>
  </div>
</template>

<script setup>
import { Link as LinkIcon } from "lucide-vue-next";

const props = defineProps({
  user: {
    type: Object,
    required: true
  }
});

// Format URL to ensure it has http/https
const formatUrl = (url) => {
  if (!url) return '#';
  return url.startsWith('http') ? url : 'https://' + url;
};

// Format display text for links
const formatLinkDisplay = (url) => {
  if (!url) return '';
  // Remove http/https and trailing slashes for display
  return url.replace(/^(https?:\/\/)?(www\.)?/, '').replace(/\/$/, '');
};
</script>
