<template>
  <!-- Contact Info -->
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-2 text-sm">
    <!-- Location info -->
    <div
      v-if="user?.city || user?.state"
      class="flex items-center gap-1.5 group"
    >
      <div
        class="p-1 rounded-md text-blue-500 group-hover:bg-blue-50 transition-colors"
      >
        <MapPin class="h-3.5 w-3.5" />
      </div>
      <span
        class="text-gray-600 text-sm font-medium truncate group-hover:text-gray-800 transition-colors"
      >
        {{ formatLocation(user) }}
      </span>
    </div>

    <!-- Company info -->
    <div
      v-if="user?.company"
      class="flex items-center gap-1.5 group"
    >
      <div
        class="p-1 rounded-md text-purple-500 group-hover:bg-purple-50 transition-colors"
      >
        <Briefcase class="h-3.5 w-3.5" />
      </div>
      <span
        class="text-gray-600 text-sm font-medium truncate group-hover:text-gray-800 transition-colors"
      >
        {{ user?.company }}
      </span>
    </div>

    <!-- Joined date -->
    <div class="flex items-center gap-1.5 group">
      <div
        class="p-1 rounded-md text-emerald-500 group-hover:bg-emerald-50 transition-colors"
      >
        <Calendar class="h-3.5 w-3.5" />
      </div>
      <span
        class="text-gray-600 text-sm group-hover:text-gray-800 transition-colors"
      >
        Joined {{ formatTimeAgo(user?.date_joined) }}
      </span>
    </div>

    <!-- Email (if allowed to show) -->
    <div
      v-if="user?.email && (currentUser?.user?.id === user?.id || user?.show_email)"
      class="flex items-center gap-1.5 group"
    >
      <div
        class="p-1 rounded-md text-amber-500 group-hover:bg-amber-50 transition-colors"
      >
        <Mail class="h-3.5 w-3.5" />
      </div>
      <span
        class="text-gray-600 text-sm font-medium truncate group-hover:text-gray-800 transition-colors"
      >
        {{ user?.email }}
      </span>
    </div>

    <!-- Phone (if allowed to show) -->
    <div
      v-if="user?.phone && (currentUser?.user?.id === user?.id || user?.show_phone)"
      class="flex items-center gap-1.5 group"
    >
      <div
        class="p-1 rounded-md text-rose-500 group-hover:bg-rose-50 transition-colors"
      >
        <Phone class="h-3.5 w-3.5" />
      </div>
      <span
        class="text-gray-600 text-sm font-medium truncate group-hover:text-gray-800 transition-colors"
      >
        {{ user?.phone }}
      </span>
    </div>
  </div>
</template>

<script setup>
import { MapPin, Briefcase, Calendar, Mail, Phone } from "lucide-vue-next";

const props = defineProps({
  user: {
    type: Object,
    required: true
  },
  currentUser: {
    type: Object,
    default: null
  }
});

// Format the location based on available city and state info
const formatLocation = (user) => {
  if (user?.city && user?.state) {
    return `${user.city}, ${user.state}`;
  } else if (user?.city) {
    return user.city;
  } else if (user?.state) {
    return user.state;
  }
  return '';
};

// Format time ago (can be received from parent via emit or defined here)
const formatTimeAgo = (dateString) => {
  if (!dateString) return '';
  
  const date = new Date(dateString);
  const now = new Date();
  const seconds = Math.floor((now - date) / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  const months = Math.floor(days / 30);
  const years = Math.floor(days / 365);

  if (years > 0) {
    return years === 1 ? '1 year ago' : `${years} years ago`;
  } else if (months > 0) {
    return months === 1 ? '1 month ago' : `${months} months ago`;
  } else if (days > 0) {
    return days === 1 ? '1 day ago' : `${days} days ago`;
  } else if (hours > 0) {
    return hours === 1 ? '1 hour ago' : `${hours} hours ago`;
  } else if (minutes > 0) {
    return minutes === 1 ? '1 minute ago' : `${minutes} minutes ago`;
  } else {
    return 'Just now';
  }
};
</script>
