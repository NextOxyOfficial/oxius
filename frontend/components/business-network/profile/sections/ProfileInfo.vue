<template>
  <!-- User Info -->
  <div class="flex-1">
    <!-- Desktop Header (Hidden on Mobile) -->
    <div
      class="hidden sm:flex sm:flex-row sm:items-start sm:justify-between"
    >
      <div>
        <div class="flex items-center flex-wrap gap-1.5">
          <h1 class="text-xl font-semibold">{{ user?.name }}</h1>
          <!-- Verified badge -->
          <div class="relative inline-flex tooltip-container">
            <UIcon
              v-if="user?.kyc"
              name="i-mdi-check-decagram"
              class="w-4 h-4 text-blue-600 animate-pulse-subtle"
              data-tooltip="Verified"
            />
          </div>

          <!-- Pro badge -->
          <span
            v-if="user?.is_pro"
            class="px-1.5 py-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-xs font-medium shadow-sm"
          >
            <div class="flex items-center gap-1">
              <UIcon name="i-heroicons-shield-check" class="size-3" />
              <span class="text-2xs">Pro</span>
            </div>
          </span>

          <!-- Top contributor badge -->
          <span
            v-if="user?.is_topcontributor"
            class="px-1.5 py-0.5 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full text-xs font-medium shadow-sm"
          >
            <div class="flex items-center gap-1">
              <Trophy class="size-3" />
              <span class="text-2xs">Top Contributor</span>
            </div>
          </span>
        </div>
        <p class="text-sm font-medium text-gray-600 mb-0.5">
          {{ user?.profession }}
        </p>
      </div>

      <!-- Action buttons (Desktop) -->
      <div class="hidden sm:flex gap-2">                    
        <!-- QR Code Button with enhanced styling -->
        <button
          @click="$emit('open-qr-modal')"
          class="px-3 py-1.5 rounded-full text-xs font-medium flex items-center gap-1.5 border border-gray-200 text-gray-800 hover:bg-gray-50 transition-all relative overflow-hidden group"
          title="View QR Code"
        >
          <span class="absolute inset-0 bg-gradient-to-r from-blue-50 to-indigo-50 opacity-0 group-hover:opacity-100 transition-opacity"></span>
          <UIcon name="i-heroicons-qr-code" class="w-4 h-4 relative z-10" />
          <span class="relative z-10">QR Code</span>
        </button>
        
        <button
          v-if="user?.id !== currentUser?.user?.id && currentUser"
          :class="[
            'px-3 py-1.5 rounded-full text-xs font-medium flex items-center gap-1.5 transition-all duration-300 relative overflow-hidden group/follow px-4 min-w-[90px] text-center',
            isFollowing
              ? 'border border-gray-200 hover:bg-gray-50 hover:shadow-sm text-gray-800'
              : 'bg-gradient-to-r from-blue-500 via-indigo-500 to-blue-600 text-white'
          ]"
          :disabled="followLoading"
          @click="$emit('toggle-follow')"
        >
          <span class="relative z-10 flex items-center justify-center gap-1.5">
            <div
              v-if="followLoading"
              class="h-3 w-3 border-2 border-t-transparent border-white rounded-full animate-spin"
            ></div>

            <template v-else-if="isFollowing">
              <Check class="h-3 w-3 animate-scaleIn" />
              Following
            </template>

            <template v-else>
              <UserPlus class="h-3 w-3 animate-scaleIn" />
              Follow
            </template>
          </span>
          <span 
            class="absolute inset-0 bg-gradient-to-r from-indigo-600 via-blue-600 to-indigo-700 opacity-0 group-hover/follow:opacity-100 transition-opacity duration-300"
            v-if="!isFollowing"
          ></span>
        </button>
      </div>
    </div>

    <!-- User Stats (Desktop) -->
    <div
      class="hidden sm:flex sm:flex-col items-start mt-3 mb-3 gap-1 border-b border-gray-100 pb-3"
    >
      <div class="flex items-center gap-3 text-sm mb-2">
        <div class="flex items-center hover:scale-105 transition-transform cursor-pointer">
          <span class="font-semibold">{{ user?.post_count || 0 }}</span>
          <span class="text-gray-600 ml-1.5">Posts</span>
        </div>
        <div
          @click="$emit('open-followers-modal', 'followers')"
          class="flex items-center hover:scale-105 transition-transform cursor-pointer"
        >
          <span class="font-semibold">{{ user?.followers_count || 0 }}</span>
          <span class="text-gray-600 ml-1.5">Followers</span>
        </div>
        <div
          @click="$emit('open-followers-modal', 'following')"
          class="flex items-center hover:scale-105 transition-transform cursor-pointer"
        >
          <span class="font-semibold">{{ user?.following_count || 0 }}</span>
          <span class="text-gray-600 ml-1.5">Following</span>
        </div>
      </div>
      <div
        v-if="currentUser?.user?.id === user?.id"
        class="flex items-center space-x-2"
      >
        <div
          class="flex items-center hover:scale-105 transition-transform cursor-pointer gap-1"
        >
          <UIcon name="i-mdi-diamond" class="text-pink-500 w-4 h-4" />
          <span class="font-semibold">{{ user?.diamond_balance }}</span>
          <span>Diamonds</span>
        </div>
        <button
          @click="$emit('show-diamond-modal')"
          class="text-xs bg-gradient-to-r from-pink-500 to-purple-500 text-white rounded-full px-4 py-1.5 hover:from-pink-600 hover:to-purple-600 flex items-center gap-1.5 transition-all shadow-sm hover:shadow"
        >
          <UIcon name="i-heroicons-plus" class="w-3 h-3" />
          <span>Top Up</span>
        </button>
      </div>
    </div>

    <!-- Bio -->
    <div
      class="mt-3 sm:mt-0 border-t sm:border-t-0 pt-3 sm:pt-0 border-gray-100"
    >
      <p
        v-if="user?.about"
        class="text-sm font-medium text-gray-600 mb-3 leading-relaxed"
      >
        {{ user?.about }}
      </p>
      <p v-else class="text-sm text-gray-600 italic mb-3">
        No bio provided
      </p>
    </div>

    <ProfileContactInfo :user="user" :currentUser="currentUser" />
    <ProfileSocialLinks :user="user" />
  </div>
</template>

<script setup>
import { Trophy, Check, UserPlus, MapPin, Briefcase, Calendar, Mail, Phone, LinkIcon } from "lucide-vue-next";
import ProfileContactInfo from './ProfileContactInfo.vue';
import ProfileSocialLinks from './ProfileSocialLinks.vue';

const props = defineProps({
  user: {
    type: Object,
    required: true
  },
  currentUser: {
    type: Object,
    default: null
  },
  isFollowing: {
    type: Boolean,
    default: false
  },
  followLoading: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits([
  'open-qr-modal',
  'toggle-follow',
  'open-followers-modal',
  'show-diamond-modal',
  'format-time-ago'
]);
</script>
